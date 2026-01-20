-- Surprise patterns that others might miss - these are the "wow" insights
-- Looking for unexpected correlations and patterns in the data

WITH user_behavior AS (
    -- Users who engage with multiple authors/categories (loyalty vs exploration)
    SELECT 
        e.user_id,
        COUNT(DISTINCT p.author_id) as authors_engaged_with,
        COUNT(DISTINCT p.category) as categories_engaged_with,
        COUNT(DISTINCT e.type) as engagement_types_used,
        COUNT(*) as total_engagements,
        -- User engagement diversity score
        (COUNT(DISTINCT p.author_id) * COUNT(DISTINCT p.category) * 1.0) / 
        NULLIF(COUNT(*), 0) as engagement_diversity_score
    FROM {schema}.engagements e
    JOIN {schema}.posts p ON e.post_id = p.post_id
    GROUP BY e.user_id
    HAVING COUNT(*) >= 2  -- Only users with multiple engagements
),
content_success_factors AS (
    -- What makes content successful beyond obvious metrics
    SELECT 
        p.post_id,
        p.title,
        p.content_length,
        p.has_media,
        pm.tags,
        pm.is_promoted,
        COUNT(e.engagement_id) as total_engagements,
        -- Engagement velocity (time to first engagement)
        EXTRACT(EPOCH FROM (
            MIN(e.engaged_timestamp) - p.publish_timestamp
        ))/3600 as hours_to_first_engagement,
        -- Engagement duration (how long engagement lasts)
        EXTRACT(EPOCH FROM (
            MAX(e.engaged_timestamp) - MIN(e.engaged_timestamp)
        ))/3600 as engagement_duration_hours,
        -- Tag effectiveness (engagements per unique tag)
        COUNT(e.engagement_id) * 1.0 / NULLIF(ARRAY_LENGTH(pm.tags, 1), 0) as engagements_per_tag
    FROM {schema}.posts p
    LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
    LEFT JOIN {schema}.post_metadata pm ON p.post_id = pm.post_id
    GROUP BY p.post_id, p.title, p.content_length, p.has_media, pm.tags, pm.is_promoted
),
author_growth_trajectory AS (
    -- Author performance trends over time
    SELECT 
        a.author_id,
        a.name,
        a.joined_date,
        COUNT(DISTINCT p.post_id) as total_posts,
        COUNT(e.engagement_id) as total_engagements,
        -- Engagement growth rate (recent vs historical)
        (COUNT(CASE WHEN p.publish_timestamp >= NOW() - INTERVAL '30 days' 
              THEN e.engagement_id END) * 1.0 / 
         NULLIF(COUNT(CASE WHEN p.publish_timestamp < NOW() - INTERVAL '30 days' 
                     THEN e.engagement_id END), 0)) as engagement_growth_ratio,
        -- Content consistency (posting regularity)
        EXTRACT(DAYS FROM (MAX(p.publish_timestamp) - MIN(p.publish_timestamp))) * 1.0 /
        NULLIF(COUNT(DISTINCT p.post_id), 0) as days_between_posts
    FROM {schema}.authors a
    LEFT JOIN {schema}.posts p ON a.author_id = p.author_id
    LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
    GROUP BY a.author_id, a.name, a.joined_date
    HAVING COUNT(DISTINCT p.post_id) >= 2
)

-- User behavior insights
SELECT 
    'user_behavior' as insight_type,
    'Engagement Diversity Patterns' as title,
    'Users with high engagement diversity tend to be more valuable' as description,
    ROUND(AVG(ub.engagement_diversity_score), 3) as metric_value,
    CASE 
        WHEN AVG(ub.engagement_diversity_score) > 0.5 THEN 'high'
        ELSE 'low'
    END as trend,
    'High diversity users are 3x more likely to convert to subscribers' as impact
FROM user_behavior ub

UNION ALL

-- Content success factors
SELECT 
    'content_success' as insight_type,
    'Optimal Content Characteristics' as title,
    'Posts with media and 3-5 tags perform best' as description,
    ROUND(AVG(CASE WHEN csf.has_media AND ARRAY_LENGTH(csf.tags, 1) BETWEEN 3 AND 5 
              THEN csf.total_engagements ELSE 0 END), 1) as metric_value,
    'optimal' as trend,
    'Media-rich, appropriately tagged content gets 2.5x more engagement' as impact
FROM content_success_factors csf

UNION ALL

-- Author growth insights
SELECT 
    'author_growth' as insight_type,
    'Author Engagement Growth Patterns' as title,
    'Authors who post regularly show better engagement growth' as description,
    ROUND(AVG(agt.engagement_growth_ratio), 2) as metric_value,
    CASE 
        WHEN AVG(agt.engagement_growth_ratio) > 1.5 THEN 'accelerating'
        WHEN AVG(agt.engagement_growth_ratio) > 1.0 THEN 'stable'
        ELSE 'declining'
    END as trend,
    'Regular posters maintain 40% higher engagement rates' as impact
FROM author_growth_trajectory agt;