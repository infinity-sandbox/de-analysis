-- Identify authors/categories with high posting volume but low engagement per post
WITH author_engagement_stats AS (
    SELECT 
        a.author_id,
        a.name AS author_name,
        a.author_category,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(e.engagement_id) AS total_engagements,
        COUNT(DISTINCT e.user_id) AS unique_engagers,
        ROUND(COUNT(e.engagement_id) * 1.0 / NULLIF(COUNT(DISTINCT p.post_id), 0), 2) AS engagements_per_post,
        ROUND(COUNT(e.engagement_id) * 1.0 / NULLIF(COUNT(DISTINCT e.user_id), 0), 2) AS engagements_per_user
    FROM {schema}.authors a
    LEFT JOIN {schema}.posts p ON p.author_id = a.author_id
    LEFT JOIN {schema}.engagements e ON e.post_id = p.post_id
    GROUP BY a.author_id, a.name, a.author_category
    HAVING COUNT(DISTINCT p.post_id) > 0
),
category_engagement_stats AS (
    SELECT 
        p.category AS category_name,
        COUNT(DISTINCT p.post_id) AS post_count,
        COUNT(e.engagement_id) AS total_engagements,
        ROUND(COUNT(e.engagement_id) * 1.0 / NULLIF(COUNT(DISTINCT p.post_id), 0), 2) AS engagements_per_post,
        COUNT(DISTINCT a.author_id) AS unique_authors
    FROM {schema}.posts p
    LEFT JOIN {schema}.engagements e ON e.post_id = p.post_id
    LEFT JOIN {schema}.authors a ON p.author_id = a.author_id
    GROUP BY p.category
    HAVING COUNT(DISTINCT p.post_id) > 0
)
-- Author opportunities
SELECT 
    'author' as analysis_type,
    author_id as entity_id,
    author_name as entity_name,
    author_category as category,
    NULL as post_category,
    post_count,
    total_engagements,
    engagements_per_post as engagement_per_post,
    engagements_per_user,
    -- Opportunity score (lower is more opportunity)
    ROUND((engagements_per_post * 0.7 + engagements_per_user * 0.3), 2) as opportunity_score
FROM author_engagement_stats
WHERE post_count >= 2  -- Authors with multiple posts

UNION ALL

-- Category opportunities  
SELECT 
    'category' as analysis_type,
    NULL as entity_id,
    category_name as entity_name,
    category_name as category,
    category_name as post_category,
    post_count,
    total_engagements,
    engagements_per_post as engagement_per_post,
    NULL as engagements_per_user,
    engagements_per_post as opportunity_score
FROM category_engagement_stats
WHERE post_count >= 2  -- Categories with multiple posts

ORDER BY opportunity_score ASC, post_count DESC;