-- Analyze segments that are targeted multiple times in a single day
WITH daily_segment_usage AS (
    SELECT 
        ec.sending_date,
        seg.value::integer as segment_id,
        COUNT(DISTINCT ec.campaign_id) as campaigns_per_day,
        STRING_AGG(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1), ', ') as clients_per_day
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
    GROUP BY ec.sending_date, seg.value::integer
)
SELECT 
    dsu.sending_date,
    s.segment_id,
    s.segment_name,
    dsu.campaigns_per_day,
    dsu.clients_per_day,
    -- Risk assessment
    CASE 
        WHEN dsu.campaigns_per_day >= 3 THEN 'HIGH RISK: Multiple exposures'
        WHEN dsu.campaigns_per_day = 2 THEN 'MEDIUM RISK: Double exposure'
        ELSE 'NORMAL'
    END as exposure_risk,
    -- Recommendation
    CASE 
        WHEN dsu.campaigns_per_day >= 3 THEN 'Implement daily frequency cap'
        WHEN dsu.campaigns_per_day = 2 THEN 'Consider time-spacing emails'
        ELSE 'OK'
    END as recommendation
FROM daily_segment_usage dsu
JOIN records.segments s ON dsu.segment_id = s.segment_id
WHERE dsu.campaigns_per_day > 1
ORDER BY dsu.sending_date DESC, dsu.campaigns_per_day DESC;