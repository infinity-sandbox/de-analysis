from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

class EngagementSummary(BaseModel):
    author_id: int
    author_name: str
    author_category: str
    post_category: str
    total_views: int
    total_likes: int
    total_comments: int
    total_shares: int
    engagement_score: float
    engagement_rate: float

class TimePattern(BaseModel):
    hour_of_day: int
    day_of_week: int
    engagement_count: int
    views: int
    likes: int
    comments: int
    shares: int
    
class ScatterPoint(BaseModel):
    entity_type: str   # "author" or "category"
    entity_id: str
    entity_name: str
    post_count: int
    engagements_per_post: float

# Fixed OpportunityArea model - matches SQL query structure
class OpportunityArea(BaseModel):
    analysis_type: str
    entity_id: Optional[int] = None
    entity_name: str
    category: str
    post_category: Optional[str] = None
    post_count: int
    total_engagements: int
    engagement_per_post: float
    engagements_per_user: Optional[float] = None
    opportunity_score: float

class TrendPoint(BaseModel):
    engagement_date: datetime
    views: int
    likes: int
    comments: int
    shares: int
    total_engagements: int

class AdvancedInsight(BaseModel):
    insight_type: str
    title: str
    description: str
    metric: float
    trend: str
    impact: str
    recommendation: str

class DashboardSummary(BaseModel):
    total_posts: int
    total_authors: int
    total_engagements: int
    total_views: int
    total_likes: int
    total_comments: int
    total_shares: int
    avg_engagement_rate: float
    top_performing_author: str
    best_time_to_post: str
    top_category: str

class UserData(BaseModel):
    email: str
    username: Optional[str] = None