-- Enhanced dashboard summary with the new data
WITH engagement_stats AS (
    SELECT 
        COUNT(DISTINCT p.post_id) AS total_posts,
        COUNT(DISTINCT a.author_id) AS total_authors,
        COUNT(DISTINCT e.engagement_id) AS total_engagements,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'view') AS total_views,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'like') AS total_likes,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'comment') AS total_comments,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'share') AS total_shares,
        -- Average engagement rate (engagements per post)
        ROUND(COUNT(e.engagement_id) * 100.0 / NULLIF(COUNT(DISTINCT p.post_id), 0), 2) AS avg_engagement_rate
    FROM {schema}.posts p
    JOIN {schema}.authors a ON a.author_id = p.author_id
    LEFT JOIN {schema}.engagements e ON e.post_id = p.post_id
),
author_performance AS (
    SELECT 
        a.name,
        COUNT(e.engagement_id) as author_engagements,
        ROW_NUMBER() OVER (ORDER BY COUNT(e.engagement_id) DESC) as rank
    FROM {schema}.authors a
    LEFT JOIN {schema}.posts p ON a.author_id = p.author_id
    LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
    GROUP BY a.author_id, a.name
    HAVING COUNT(e.engagement_id) > 0
),
time_analysis AS (
    SELECT 
        EXTRACT(HOUR FROM e.engaged_timestamp) as best_hour,
        COUNT(*) as engagement_count
    FROM {schema}.engagements e
    GROUP BY EXTRACT(HOUR FROM e.engaged_timestamp)
    ORDER BY engagement_count DESC
    LIMIT 1
),
category_performance AS (
    SELECT 
        p.category,
        COUNT(e.engagement_id) as engagements,
        ROW_NUMBER() OVER (ORDER BY COUNT(e.engagement_id) DESC) as rank
    FROM {schema}.posts p
    LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
    GROUP BY p.category
    HAVING COUNT(e.engagement_id) > 0
)
SELECT 
    es.*,
    COALESCE(ap.name, 'No data') as top_performing_author,
    COALESCE(ta.best_hour::text || ':00', 'No data') as best_time_to_post,
    (SELECT category FROM category_performance WHERE rank = 1 LIMIT 1) as top_category
FROM engagement_stats es
LEFT JOIN (SELECT name FROM author_performance WHERE rank = 1 LIMIT 1) ap ON true
LEFT JOIN (SELECT best_hour FROM time_analysis LIMIT 1) ta ON true;