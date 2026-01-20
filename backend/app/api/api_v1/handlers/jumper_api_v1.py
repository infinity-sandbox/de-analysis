from pathlib import Path
import asyncpg
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Header, Query
from typing import List, Dict, Any, Optional
from asyncpg import Pool
from datetime import datetime, timedelta
from app.services.auth_service import AuthDatabaseService
from app.models.insight_model import (
    EngagementSummary, TimePattern, OpportunityArea, 
    TrendPoint, AdvancedInsight, DashboardSummary, UserData, ScatterPoint
)
from pathlib import Path
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import os
import io
import zipfile
import jwt
import pandas as pd
from fastapi.responses import FileResponse, StreamingResponse


from app.sql.main import SqlQuery
from app.core.config import logger_settings, Settings
logger = logger_settings.get_logger(__name__)

dashboard_router = APIRouter()

async def get_db_pool() -> Pool:
    return await AuthDatabaseService.get_pool()

# ===================== EXISTING ENDPOINTS =====================

@dashboard_router.get("/dashboard-summary", response_model=DashboardSummary)
async def get_dashboard_summary(pool: Pool = Depends(get_db_pool)):
    """Enhanced dashboard summary with advanced metrics"""
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/dashboard_summary", 
        schema="records"
    )
    
    async with pool.acquire() as conn:
        result = await conn.fetchrow(query)
    
    return dict(result) if result else {}

@dashboard_router.get("/advanced-insights", response_model=List[AdvancedInsight])
async def get_advanced_insights(pool: Pool = Depends(get_db_pool)):
    """Get advanced insights with surprise patterns"""
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/surprise_patterns",
        schema="records"
    )
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    
    insights = []
    for row in results:
        insights.append({
            "insight_type": row["insight_type"],
            "title": row["title"],
            "description": row["description"],
            "metric": float(row["metric_value"]),
            "trend": row["trend"],
            "impact": row["impact"],
            "recommendation": generate_recommendation(row["insight_type"], row["metric_value"])
        })
    
    return insights

@dashboard_router.get("/engagement-heatmap")
async def get_engagement_heatmap(
    period: str = Query("last_year", description="Time period for analysis"),
    pool: Pool = Depends(get_db_pool)
):
    """Enhanced heatmap data with engagement intensity"""
    start_date = parse_period(period)
    
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/engagement_heatmap",
        schema="records",
        start_date=start_date.strftime("%Y-%m-%d %H:%M:%S")
    )
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    
    # Transform to heatmap format
    heatmap_data = {}
    for row in results:
        hour = int(row["hour_of_day"])
        day = int(row["day_of_week"])
        if hour not in heatmap_data:
            heatmap_data[hour] = {}
        heatmap_data[hour][day] = {
            "engagement_count": row["engagement_count"],
            "intensity": float(row["engagement_intensity"]),
            "types": {
                "views": row["views"],
                "likes": row["likes"],
                "comments": row["comments"],
                "shares": row["shares"]
            }
        }
    
    return heatmap_data

@dashboard_router.get("/content-performance")
async def get_content_performance(
    min_content_length: int = Query(500, description="Minimum content length"),
    pool: Pool = Depends(get_db_pool)
):
    """Analyze content performance based on various factors"""
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/content_performance",
        schema="records",
        min_content_length=min_content_length
    )
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    
    return [dict(row) for row in results]

# ===================== NEW ENDPOINTS =====================

@dashboard_router.get("/top-engagements", response_model=List[EngagementSummary])
async def get_top_engagements(
    period: str = Query("last_year", description="Time period for analysis"),
    limit: int = Query(10, description="Number of results to return"),
    pool: Pool = Depends(get_db_pool)
):
    logger.info("Endpoint /top-engagements called")
    logger.info(f"Parameters - period: {period}")
    """Top authors and categories by engagement"""
    start_date = parse_period(period)
    logger.info(f"Fetching top engagements since {start_date} with limit {limit}")
    
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/top_engagements",
        schema="records",
        start_date=start_date.strftime("%Y-%m-%d %H:%M:%S")
    )
    
    logger.info(f"Original query: {query}")
    
    # Remove the LIMIT from the query and apply it here for flexibility
    query = query.replace("LIMIT 20", f"LIMIT {limit}")
    logger.info(f"remove limit from query : {query}")
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    logger.info(f"Fetched {len(results)} records")
    logger.debug(f"Records: {results}")
    return [dict(row) for row in results]

@dashboard_router.get("/engagement-trend", response_model=List[dict])
async def get_engagement_trend(
    entity_type: str = Query(..., description="Type of entity: author, category, or post"),
    author_name: Optional[str] = Query(None, description="Author name (backend resolves ID)"),
    post_title: Optional[str] = Query(None, description="Post title (backend resolves ID)"),
    category_name: Optional[str] = Query(None, description="Category name"),
    days: int = Query(365, description="Number of days to analyze"),
    pool: Pool = Depends(get_db_pool)
):
    """Engagement trends over time for author, post, or category"""

    # Resolve entity condition
    async with pool.acquire() as conn:
        if entity_type == "author" and author_name:
            # Look up author_id by name
            author_row = await conn.fetchrow(
                "SELECT author_id FROM records.authors WHERE name = $1", author_name
            )
            if not author_row:
                raise HTTPException(status_code=404, detail=f"Author '{author_name}' not found")
            entity_condition = f"p.author_id = {author_row['author_id']}"

        elif entity_type == "post" and post_title:
            # Look up post_id by title
            post_row = await conn.fetchrow(
                "SELECT post_id FROM records.posts WHERE title = $1", post_title
            )
            if not post_row:
                raise HTTPException(status_code=404, detail=f"Post '{post_title}' not found")
            entity_condition = f"p.post_id = {post_row['post_id']}"

        elif entity_type == "category" and category_name:
            entity_condition = f"p.category = '{category_name.replace('\'','\'\'')}'"

        else:
            raise HTTPException(status_code=400, detail="Invalid entity parameters")

    # Read SQL template
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/engagement_trend",
        schema="records",
        entity_condition=entity_condition
    )
    
    # Adjust query interval
    query = query.replace("INTERVAL '365 days'", f"INTERVAL '{days} days'")

    # Fetch results
    async with pool.acquire() as conn:
        results = await conn.fetch(query)

    # Convert dates
    trend_data = []
    for row in results:
        trend_point = dict(row)
        if isinstance(trend_point['engagement_date'], str):
            trend_point['engagement_date'] = datetime.fromisoformat(
                trend_point['engagement_date'].replace('Z', '+00:00')
            )
        trend_data.append(trend_point)

    # Filter out rows with zero engagements
    trend_data = [r for r in trend_data if r["total_engagements"] > 0]

    return trend_data

@dashboard_router.get("/authors")
async def get_authors(pool: Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT author_id, name FROM records.authors ORDER BY name;")
    return [{"author_id": r["author_id"], "name": r["name"]} for r in rows]


@dashboard_router.get("/posts")
async def get_posts(pool: Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT post_id, title FROM records.posts ORDER BY post_id;")
    return [{"post_id": r["post_id"], "title": r["title"]} for r in rows]


@dashboard_router.get("/categories")
async def get_categories(pool: Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT DISTINCT category FROM records.posts WHERE category IS NOT NULL;")
    return [r["category"] for r in rows]

@dashboard_router.get("/opportunity-areas", response_model=List[OpportunityArea])
async def get_opportunity_areas(
    min_posts: int = Query(2, description="Minimum posts to consider"),
    pool: Pool = Depends(get_db_pool)
):
    """Identify high-volume, low-engagement opportunities"""
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/opportunity_areas",
        schema="records"
    )
    
    # Adjust the threshold in the query
    query = query.replace("post_count >= 2", f"post_count >= {min_posts}")
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    
    return [dict(row) for row in results]

@dashboard_router.get("/advanced-patterns")
async def get_advanced_patterns(pool: Pool = Depends(get_db_pool)):
    """Get advanced behavioral and content patterns"""
    try:
        query = await SqlQuery.read_sql_full(
            "com/jumper/insight/advanced_patterns",
            schema="records"
        )
        
        async with pool.acquire() as conn:
            results = await conn.fetch(query)
        
        patterns = {}
        for row in results:
            insight_type = row["insight_type"]
            insights_data = row["insights"]
            
            # Parse the JSON data if it's a string
            if isinstance(insights_data, str):
                import json
                insights_data = json.loads(insights_data)
            
            patterns[insight_type] = insights_data
        
        return patterns
        
    except Exception as e:
        logger.error(f"Error in advanced patterns endpoint: {e}")
        # Return default structure if there's an error
        return {
            "user_behavior": {
                "avg_diversity_score": 0,
                "high_diversity_users": 0,
                "total_analyzed_users": 0
            },
            "content_optimization": {
                "best_media_type": None,
                "promotion_effectiveness": 0,
                "optimal_tag_count": 0
            }
        }

@dashboard_router.get("/user")
async def get_current_user():
    """Get current user data"""
    return {"email": "a", "username": "admin"}

# ===================== HELPER FUNCTIONS =====================

def parse_period(period: str) -> datetime:
    periods = {
        "last_7_days": timedelta(days=7),
        "last_30_days": timedelta(days=30),
        "last_3_months": timedelta(days=90),
        "last_year": timedelta(days=365)
    }
    return datetime.utcnow() - periods.get(period, timedelta(days=365))

def generate_recommendation(insight_type: str, metric: float) -> str:
    recommendations = {
        "user_behavior": "Create personalized content recommendations for high-diversity users",
        "content_success": "Optimize content tagging strategy and media inclusion",
        "author_growth": "Implement author mentoring program for consistent posting"
    }
    return recommendations.get(insight_type, "Analyze patterns for specific recommendations")
    

# ---------------------------
# Scatter Plot: Volume vs Engagement per Post
# ---------------------------
@dashboard_router.get("/scatter-performance", response_model=List[ScatterPoint])
async def scatter_performance(
    period: str = Query("last_year", description="Time period for analysis"),
    entity_type: str = Query("author", description="Group by 'author' or 'category'"),
    pool: Pool = Depends(get_db_pool)
):
    """
    Returns scatter plot data: post_count vs engagement_per_post.
    Helps spot under/over-performing authors or categories.
    """
    start_date = parse_period(period)

    if entity_type == "author":
        group_field = "a.author_id, a.name"
        entity_id = "a.author_id"
        entity_name = "a.name"
    else:
        group_field = "a.author_category"
        entity_id = "a.author_category"
        entity_name = "a.author_category"
    
    query = await SqlQuery.read_sql_full(
            "com/jumper/insight/scatter_performance",
            schema="records",
            start_date=start_date.strftime("%Y-%m-%d %H:%M:%S"),
            entity_id=entity_id,
            entity_name=entity_name,
            group_field=group_field
        )

    async with pool.acquire() as conn:
        rows = await conn.fetch(query)

    return [
        ScatterPoint(
            entity_type=entity_type,
            entity_id=str(row["entity_id"]),
            entity_name=row["entity_name"],
            post_count=row["post_count"],
            engagements_per_post=float(row["engagements_per_post"])
        )
        for row in rows
    ]

@dashboard_router.get("/engagement-trend-author-category")
async def get_engagement_trend_author_category(
    days: int = Query(365, description="Number of days to analyze"),
    pool: Pool = Depends(get_db_pool)
):
    """
    Engagement trends over time grouped by author and category
    """
    query = await SqlQuery.read_sql_full(
        "com/jumper/insight/engagement_trend_author_category",
        schema="records"
    )
    query = query.replace("INTERVAL '365 days'", f"INTERVAL '{days} days'")
    
    async with pool.acquire() as conn:
        results = await conn.fetch(query)
    
    trend_data = []
    for row in results:
        trend_point = dict(row)
        if isinstance(trend_point['engagement_date'], str):
            trend_point['engagement_date'] = datetime.fromisoformat(
                trend_point['engagement_date'].replace('Z', '+00:00')
            )
        trend_data.append(trend_point)
    
    return trend_data

@dashboard_router.get("/download-data")
async def download_data(pool: Pool = Depends(get_db_pool)):
    """Download all database tables as CSV and Excel inside a zip file"""

    # Create in-memory zip file
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        
        async with pool.acquire() as conn:
            TABLES = ["authors", "engagements", "post_metadata", "posts", "users"]
            for table in TABLES:
                # Fetch data
                rows = await conn.fetch(f"SELECT * FROM records.{table}")
                df = pd.DataFrame([dict(r) for r in rows])

                # Handle empty tables
                if df.empty:
                    continue

                # Save CSV
                csv_bytes = df.to_csv(index=False).encode("utf-8")
                zf.writestr(f"csv/{table}.csv", csv_bytes)

                # Save Excel
                excel_buffer = io.BytesIO()
                with pd.ExcelWriter(excel_buffer, engine="openpyxl") as writer:
                    df.to_excel(writer, index=False, sheet_name=table)
                zf.writestr(f"excel/{table}.xlsx", excel_buffer.getvalue())

    zip_buffer.seek(0)
    return StreamingResponse(
        zip_buffer,
        media_type="application/x-zip-compressed",
        headers={"Content-Disposition": "attachment; filename=data.zip"}
    )
    
@dashboard_router.get("/download-report")
async def download_report():
    """
    Endpoint to download the stored PowerPoint report.
    Can be accessed directly from browser or curl.
    """
    '''Absolute path to data folder (safe in Docker)
        Root-based report path'''
    
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    REPORT_DIR = os.path.abspath(os.path.join(BASE_DIR, "../../../../", "reports"))
    REPORT_PATH = os.path.join(REPORT_DIR, "report.pptx")

    if not os.path.exists(REPORT_PATH):
        raise HTTPException(status_code=404, detail="Report file not found")

    # FileResponse streams the file with proper headers
    return FileResponse(
        path=str(REPORT_PATH),
        media_type="application/vnd.openxmlformats-officedocument.presentationml.presentation",
        filename="report.pptx",
        headers={
            "Content-Disposition": f"attachment; filename=report.pptx"
        }
    )