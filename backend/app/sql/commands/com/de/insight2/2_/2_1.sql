-- Count how often each segment is used
SELECT 
    seg.value::integer as segment_id,
    s.segment_name,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns_used,
    COUNT(DISTINCT ec.sending_date) as days_used,
    COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) as months_used,
    COUNT(DISTINCT DATE_TRUNC('week', ec.sending_date)) as weeks_used
FROM records.email_campaigns ec
CROSS JOIN LATERAL (
    SELECT value
    FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
    WHERE ec.audience_segment_a_ids IS NOT NULL 
      AND ec.audience_segment_a_ids != '[]'::jsonb
    UNION ALL
    SELECT value
    FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
    WHERE ec.audience_segment_b_ids IS NOT NULL 
      AND ec.audience_segment_b_ids != '[]'::jsonb
) seg
JOIN records.segments s ON seg.value::integer = s.segment_id
WHERE seg.value ~ '^\d+$'
GROUP BY seg.value::integer, s.segment_name
ORDER BY total_campaigns_used DESC;