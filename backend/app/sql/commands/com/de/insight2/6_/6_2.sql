-- Engagement metrics by segment
SELECT 
    s.segment_id,
    s.segment_name,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns,
    AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(ec.click_rate) * 100 as avg_click_rate_pct,
    AVG(ec.unsubscription_rate) * 100 as avg_unsub_rate_pct,
    AVG(ec.delivered_rate) * 100 as avg_delivery_rate_pct,
    -- Frequency metrics
    COUNT(DISTINCT ec.sending_date) / COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) as avg_days_active_per_month,
    -- Segment engagement classification
    CASE 
        WHEN AVG(ec.trackable_open_rate) >= 0.25 THEN 'High Engagement Segment'
        WHEN AVG(ec.trackable_open_rate) >= 0.15 THEN 'Medium Engagement Segment'
        WHEN AVG(ec.trackable_open_rate) >= 0.1 THEN 'Low Engagement Segment'
        ELSE 'Poor Engagement Segment'
    END as segment_engagement_level
FROM records.email_campaigns ec
CROSS JOIN LATERAL (
    SELECT value::integer as segment_id
    FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
    WHERE ec.audience_segment_a_ids IS NOT NULL 
      AND ec.audience_segment_a_ids != '[]'::jsonb
    UNION ALL
    SELECT value::integer as segment_id
    FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
    WHERE ec.audience_segment_b_ids IS NOT NULL 
      AND ec.audience_segment_b_ids != '[]'::jsonb
) seg
JOIN records.segments s ON seg.segment_id = s.segment_id
GROUP BY s.segment_id, s.segment_name
HAVING COUNT(DISTINCT ec.campaign_id) >= 3
ORDER BY avg_open_rate_pct DESC;