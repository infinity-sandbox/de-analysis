-- Content performance analysis
WITH content_metrics AS (
    SELECT 
        p.post_id,
        p.title,
        p.content_length,
        p.has_media,
        p.category,
        pm.tags,
        pm.is_promoted,
        a.author_category,
        COUNT(e.engagement_id) AS total_engagements,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'view') AS views,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'like') AS likes,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'comment') AS comments,
        COUNT(e.engagement_id) FILTER (WHERE e.type = 'share') AS shares,
        -- Engagement rate (engagements per 1000 characters)
        (COUNT(e.engagement_id) * 1000.0 / NULLIF(p.content_length, 0)) AS engagement_rate,
        -- Quality engagement ratio
        (COUNT(e.engagement_id) FILTER (WHERE e.type IN ('comment', 'share')) * 1.0 /
         NULLIF(COUNT(e.engagement_id) FILTER (WHERE e.type = 'view'), 0)) AS quality_ratio
    FROM {schema}.posts p
    LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
    LEFT JOIN {schema}.post_metadata pm ON p.post_id = pm.post_id
    LEFT JOIN {schema}.authors a ON p.author_id = a.author_id
    WHERE p.content_length >= {min_content_length}
    GROUP BY p.post_id, p.title, p.content_length, p.has_media, p.category, 
             pm.tags, pm.is_promoted, a.author_category
)
SELECT 
    *,
    CASE 
        WHEN quality_ratio > 0.1 THEN 'high_quality'
        WHEN quality_ratio > 0.05 THEN 'medium_quality'
        ELSE 'low_quality'
    END as content_quality
FROM content_metrics
ORDER BY engagement_rate DESC;