-- Find which segments are used together in the same campaigns
WITH campaign_segments AS (
    SELECT DISTINCT
        ec.campaign_id,
        ec.sending_date,
        SPLIT_PART(ec.campaign_name, ' - ', 1) as client,
        seg.value::integer as segment_id
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
    WHERE seg.value ~ '^\d+$'
),
segment_combinations AS (
    SELECT 
        cs1.segment_id as segment_1,
        cs2.segment_id as segment_2,
        cs1.campaign_id,
        cs1.sending_date,
        cs1.client
    FROM campaign_segments cs1
    JOIN campaign_segments cs2 
      ON cs1.campaign_id = cs2.campaign_id
     AND cs1.segment_id < cs2.segment_id
)
SELECT 
    s1.segment_name as segment_1_name,
    s2.segment_name as segment_2_name,
    COUNT(DISTINCT sc.campaign_id) as campaigns_together,
    COUNT(DISTINCT sc.sending_date) as days_together,
    STRING_AGG(DISTINCT sc.client, ', ') as clients_using_both
FROM segment_combinations sc
JOIN records.segments s1 ON sc.segment_1 = s1.segment_id
JOIN records.segments s2 ON sc.segment_2 = s2.segment_id
GROUP BY s1.segment_name, s2.segment_name
HAVING COUNT(DISTINCT sc.campaign_id) > 0
ORDER BY campaigns_together DESC;