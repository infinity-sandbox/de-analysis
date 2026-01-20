-- Which clients use each segment
SELECT 
    seg.value::integer as segment_id,
    s.segment_name,
    SPLIT_PART(ec.campaign_name, ' - ', 1) as client,
    COUNT(DISTINCT ec.campaign_id) as campaigns_by_client,
    COUNT(DISTINCT ec.sending_date) as days_used_by_client,
    MIN(ec.sending_date) as first_used_by_client,
    MAX(ec.sending_date) as last_used_by_client
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
GROUP BY seg.value::integer, s.segment_name, SPLIT_PART(ec.campaign_name, ' - ', 1)
ORDER BY segment_id, campaigns_by_client DESC;