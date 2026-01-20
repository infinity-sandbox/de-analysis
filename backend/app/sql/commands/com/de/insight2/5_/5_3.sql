-- Find segments used by multiple clients on the same day
SELECT 
    ec.sending_date,
    seg.value::integer as segment_id,
    s.segment_name,
    COUNT(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1)) as unique_clients,
    STRING_AGG(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1), ', ') as client_list,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns
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
GROUP BY ec.sending_date, seg.value::integer, s.segment_name
HAVING COUNT(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1)) > 1
ORDER BY ec.sending_date DESC, unique_clients DESC;