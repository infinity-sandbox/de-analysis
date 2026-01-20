-- Classify segments based on usage patterns
WITH segment_usage_stats AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        COUNT(DISTINCT ec.campaign_id) as total_campaigns,
        COUNT(DISTINCT ec.sending_date) as total_days_used,
        COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) as months_active,
        COUNT(DISTINCT SPLIT_PART(ec.campaign_name, ' - ', 1)) as unique_clients,
        AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(ec.unsubscription_rate) * 100 as avg_unsub_rate_pct
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
)
SELECT 
    segment_id,
    segment_name,
    total_campaigns,
    total_days_used,
    months_active,
    unique_clients,
    avg_open_rate_pct,
    avg_unsub_rate_pct,
    -- Segment classification
    CASE 
        WHEN total_campaigns >= 20 THEN 'CORE SEGMENT: Heavily used'
        WHEN total_campaigns >= 10 THEN 'REGULAR SEGMENT: Frequently used'
        WHEN total_campaigns >= 5 THEN 'OCCASIONAL SEGMENT: Used sometimes'
        WHEN total_campaigns >= 1 THEN 'RARE SEGMENT: Rarely used'
        ELSE 'NEVER USED'
    END as usage_category,
    -- Fatigue risk assessment
    CASE 
        WHEN total_days_used >= 20 AND avg_open_rate_pct < 15 THEN 'HIGH FATIGUE RISK'
        WHEN total_days_used >= 15 AND avg_open_rate_pct < 20 THEN 'MEDIUM FATIGUE RISK'
        WHEN total_days_used >= 10 AND avg_unsub_rate_pct > 0.3 THEN 'MEDIUM FATIGUE RISK'
        WHEN total_days_used >= 5 THEN 'LOW FATIGUE RISK'
        ELSE 'MINIMAL FATIGUE RISK'
    END as fatigue_risk,
    -- Underutilization assessment
    CASE 
        WHEN total_campaigns < 3 AND avg_open_rate_pct > 25 THEN 'UNDERUTILIZED: High potential'
        WHEN total_campaigns < 5 AND avg_open_rate_pct > 20 THEN 'UNDERUTILIZED: Good potential'
        WHEN total_campaigns = 0 THEN 'NEVER TESTED'
        ELSE 'APPROPRIATELY UTILIZED'
    END as utilization_status,
    -- Usage intentionality
    CASE 
        WHEN unique_clients > 3 THEN 'STRATEGIC: Multiple clients find value'
        WHEN unique_clients = 1 AND total_campaigns > 15 THEN 'HABITUAL: Single client overusing'
        WHEN total_days_used / NULLIF(months_active, 0) > 15 THEN 'ROUTINE: Likely automated'
        WHEN total_days_used / NULLIF(months_active, 0) < 3 THEN 'INTENTIONAL: Targeted use'
        ELSE 'MIXED USE PATTERN'
    END as usage_intentionality
FROM segment_usage_stats
ORDER BY total_campaigns DESC;