-- Top authors/categories by engagement over a recent period
WITH engagement_weights AS (
    SELECT 
        'view' as type, 1 as weight
    UNION SELECT 'like', 2
    UNION SELECT 'comment', 3
    UNION SELECT 'share', 5
)
SELECT
    a.author_id,
    a.name AS author_name,
    a.author_category,
    p.category AS post_category,
    COUNT(e.engagement_id) AS total_engagements,
    COUNT(e.engagement_id) FILTER (WHERE e.type = 'view') AS total_views,
    COUNT(e.engagement_id) FILTER (WHERE e.type = 'like') AS total_likes,
    COUNT(e.engagement_id) FILTER (WHERE e.type = 'comment') AS total_comments,
    COUNT(e.engagement_id) FILTER (WHERE e.type = 'share') AS total_shares,
    -- Weighted engagement score (shares and comments are more valuable)
    COALESCE(SUM(ew.weight), 0) AS engagement_score,
    -- Engagement rate per post
    ROUND(COUNT(e.engagement_id) * 100.0 / NULLIF(COUNT(DISTINCT p.post_id), 0), 2) AS engagement_rate
FROM {schema}.authors a
JOIN {schema}.posts p ON p.author_id = a.author_id
LEFT JOIN {schema}.engagements e ON e.post_id = p.post_id
LEFT JOIN engagement_weights ew ON ew.type = e.type
WHERE p.publish_timestamp >= '{start_date}'
GROUP BY a.author_id, a.name, a.author_category, p.category
ORDER BY engagement_score DESC, total_engagements DESC
LIMIT 20;


