SELECT
    {entity_id} AS entity_id,
    {entity_name} AS entity_name,
    COUNT(DISTINCT p.post_id) AS post_count,
    COALESCE(CAST(COUNT(e.engagement_id) AS float) / NULLIF(COUNT(DISTINCT p.post_id),0), 0) AS engagements_per_post
FROM {schema}.posts p
JOIN {schema}.authors a ON p.author_id = a.author_id
LEFT JOIN {schema}.engagements e ON p.post_id = e.post_id
WHERE p.publish_timestamp >= '{start_date}'
GROUP BY {group_field}
ORDER BY post_count DESC;