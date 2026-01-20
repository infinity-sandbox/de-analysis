-- Weekly usage of each segment
SELECT 
    seg.value::integer as segment_id,
    s.segment_name,
    EXTRACT(YEAR FROM ec.sending_date) as year,
    EXTRACT(WEEK FROM ec.sending_date) as week,
    COUNT(DISTINCT ec.campaign_id) as campaigns_this_week,
    COUNT(DISTINCT ec.sending_date) as days_used_this_week,
    STRING_AGG(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1), ', ') as clients_this_week
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
GROUP BY seg.value::integer, s.segment_name, year, week
ORDER BY year DESC, week DESC, campaigns_this_week DESC;