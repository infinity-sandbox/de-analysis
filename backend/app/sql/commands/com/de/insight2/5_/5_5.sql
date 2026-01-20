-- Simple analysis of segment overlap and exposure
WITH segment_usage AS (
    SELECT DISTINCT
        ec.campaign_id,
        ec.sending_date,
        SPLIT_PART(ec.campaign_name, ' - ', 1) as client,
        seg.value::integer as segment_id,
        s.segment_name
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
)
SELECT 
    su.segment_id,
    su.segment_name,
    COUNT(DISTINCT su.campaign_id) as total_campaigns,
    COUNT(DISTINCT su.sending_date) as active_days,
    COUNT(DISTINCT su.client) as unique_clients,
    -- Overlap metrics
    AVG(daily_campaigns.daily_count) as avg_campaigns_per_day,
    MAX(daily_campaigns.daily_count) as max_campaigns_per_day,
    -- Days with multiple exposures
    COUNT(DISTINCT CASE 
        WHEN daily_campaigns.daily_count > 1 THEN su.sending_date 
    END) as days_with_overlap,
    -- Exposure risk rating
    CASE 
        WHEN AVG(daily_campaigns.daily_count) > 2 THEN 'HIGH EXPOSURE RISK'
        WHEN AVG(daily_campaigns.daily_count) > 1.2 THEN 'MEDIUM EXPOSURE RISK'
        WHEN COUNT(DISTINCT su.client) > 1 THEN 'CROSS-CLIENT EXPOSURE'
        ELSE 'LOW EXPOSURE RISK'
    END as exposure_risk,
    -- Simple recommendation
    CASE 
        WHEN AVG(daily_campaigns.daily_count) > 2 THEN 'Implement daily frequency cap of 1'
        WHEN AVG(daily_campaigns.daily_count) > 1.2 THEN 'Add exclusion for same-day sends'
        WHEN COUNT(DISTINCT su.client) > 1 THEN 'Coordinate cross-client scheduling'
        ELSE 'Current practices acceptable'
    END as recommendation
FROM segment_usage su
JOIN (
    SELECT 
        sending_date,
        segment_id,
        COUNT(DISTINCT campaign_id) as daily_count
    FROM segment_usage
    GROUP BY sending_date, segment_id
) daily_campaigns ON su.sending_date = daily_campaigns.sending_date 
                  AND su.segment_id = daily_campaigns.segment_id
GROUP BY su.segment_id, su.segment_name
ORDER BY avg_campaigns_per_day DESC;