-- Enhanced heatmap with engagement intensity
SELECT 
    EXTRACT(HOUR FROM e.engaged_timestamp) AS hour_of_day,
    EXTRACT(DOW FROM e.engaged_timestamp) AS day_of_week,
    COUNT(*) AS engagement_count,
    COUNT(DISTINCT e.user_id) AS unique_users,
    COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT e.user_id), 0) AS engagement_intensity,
    COUNT(*) FILTER (WHERE e.type = 'view') AS views,
    COUNT(*) FILTER (WHERE e.type = 'like') AS likes,
    COUNT(*) FILTER (WHERE e.type = 'comment') AS comments,
    COUNT(*) FILTER (WHERE e.type = 'share') AS shares
FROM {schema}.engagements e
WHERE e.engaged_timestamp >= '{start_date}'
GROUP BY hour_of_day, day_of_week
ORDER BY hour_of_day, day_of_week;