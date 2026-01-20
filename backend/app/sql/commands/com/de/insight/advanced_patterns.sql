-- Advanced patterns and surprise insights
WITH user_engagement_patterns AS (
    SELECT 
        e.user_id,
        COUNT(DISTINCT p.author_id) as authors_engaged,
        COUNT(DISTINCT p.category) as categories_engaged,
        COUNT(DISTINCT e.type) as engagement_types,
        COUNT(*) as total_engagements,
        ROUND((COUNT(DISTINCT p.author_id) * COUNT(DISTINCT p.category) * 1.0) / 
              NULLIF(COUNT(*), 0), 3) as diversity_score
    FROM records.engagements e
    JOIN records.posts p ON e.post_id = p.post_id
    GROUP BY e.user_id
    HAVING COUNT(*) >= 2
),
content_analysis AS (
    SELECT 
        p.has_media,
        pm.is_promoted,
        CASE 
            WHEN pm.tags IS NULL THEN 0
            ELSE array_length(pm.tags, 1)
        END as tag_count,
        COUNT(DISTINCT p.post_id) as post_count,
        ROUND(AVG(p.content_length), 0) as avg_content_length,
        ROUND(AVG(
            (SELECT COUNT(*) FROM records.engagements e2 WHERE e2.post_id = p.post_id)
        ), 2) as avg_engagements
    FROM records.posts p
    LEFT JOIN records.post_metadata pm ON p.post_id = pm.post_id
    GROUP BY p.has_media, pm.is_promoted, 
        CASE 
            WHEN pm.tags IS NULL THEN 0
            ELSE array_length(pm.tags, 1)
        END
),
best_media_type AS (
    SELECT has_media
    FROM content_analysis 
    ORDER BY avg_engagements DESC 
    LIMIT 1
),
promotion_effectiveness AS (
    SELECT ROUND(avg_engagements, 2) as effectiveness
    FROM content_analysis 
    WHERE is_promoted = true
    LIMIT 1
),
optimal_tag_count AS (
    SELECT tag_count
    FROM content_analysis 
    ORDER BY avg_engagements DESC 
    LIMIT 1
)
SELECT 
    'user_behavior' as insight_type,
    json_build_object(
        'avg_diversity_score', ROUND(AVG(diversity_score), 3),
        'high_diversity_users', COUNT(CASE WHEN diversity_score > 0.5 THEN 1 END),
        'total_analyzed_users', COUNT(*)
    ) as insights
FROM user_engagement_patterns

UNION ALL

SELECT 
    'content_optimization' as insight_type,
    json_build_object(
        'best_media_type', (SELECT has_media FROM best_media_type),
        'promotion_effectiveness', (SELECT effectiveness FROM promotion_effectiveness),
        'optimal_tag_count', (SELECT tag_count FROM optimal_tag_count)
    ) as insights;