-- Engagement trends for author, post, or category over time
WITH date_series AS (
    SELECT generate_series(
        DATE_TRUNC('day', NOW() - INTERVAL '365 days'),
        DATE_TRUNC('day', NOW()),
        '1 day'::interval
    ) AS date
)
SELECT 
    ds.date AS engagement_date,
    a.name AS author_name,
    p.category AS category_name,
    p.title AS post_title,
    COALESCE(COUNT(e.engagement_id) FILTER (WHERE e.type = 'view'), 0) AS views,
    COALESCE(COUNT(e.engagement_id) FILTER (WHERE e.type = 'like'), 0) AS likes,
    COALESCE(COUNT(e.engagement_id) FILTER (WHERE e.type = 'comment'), 0) AS comments,
    COALESCE(COUNT(e.engagement_id) FILTER (WHERE e.type = 'share'), 0) AS shares,
    COALESCE(COUNT(e.engagement_id), 0) AS total_engagements
FROM date_series ds
LEFT JOIN {schema}.engagements e 
    ON DATE_TRUNC('day', e.engaged_timestamp) = ds.date
LEFT JOIN {schema}.posts p 
    ON p.post_id = e.post_id
LEFT JOIN {schema}.authors a
    ON a.author_id = p.author_id
WHERE 
    {entity_condition}
GROUP BY ds.date, a.name, p.category, p.title
HAVING COALESCE(COUNT(e.engagement_id), 0) > 0
ORDER BY ds.date ASC;