-- Daily usage of each segment
SELECT 
    seg.value::integer as segment_id,
    s.segment_name,
    ec.sending_date,
    COUNT(DISTINCT ec.campaign_id) as campaigns_that_day,
    STRING_AGG(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1), ', ') as clients_that_day
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
GROUP BY seg.value::integer, s.segment_name, ec.sending_date
ORDER BY ec.sending_date DESC, campaigns_that_day DESC;