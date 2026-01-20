-- Assess which users might be receiving multiple emails daily
WITH daily_exposure AS (
    SELECT 
        ec.sending_date,
        seg.value::integer as segment_id,
        s.segment_name,
        COUNT(DISTINCT ec.campaign_id) as daily_exposures,
        SUM(ec.sent) as total_emails_sent,
        AVG(ec.delivered_rate) * 100 as avg_delivery_rate,
        AVG(ec.unsubscription_rate) * 100 as avg_unsub_rate
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
),
exposure_summary AS (
    SELECT 
        segment_id,
        segment_name,
        COUNT(DISTINCT sending_date) as days_with_multiple_exposures,
        AVG(daily_exposures) as avg_daily_exposures,
        MAX(daily_exposures) as max_daily_exposures,
        AVG(avg_delivery_rate) as avg_delivery_rate_pct,
        AVG(avg_unsub_rate) as avg_unsub_rate_pct
    FROM daily_exposure
    WHERE daily_exposures > 1
    GROUP BY segment_id, segment_name
)
SELECT 
    segment_id,
    segment_name,
    days_with_multiple_exposures,
    ROUND(avg_daily_exposures::numeric, 2) as avg_exposures_per_day,
    max_daily_exposures,
    ROUND(avg_delivery_rate_pct::numeric, 2) as avg_delivery_pct,
    ROUND(avg_unsub_rate_pct::numeric, 4) as avg_unsub_pct,
    -- Risk classification
    CASE 
        WHEN days_with_multiple_exposures >= 10 AND avg_delivery_rate_pct < 90 THEN 'CRITICAL RISK'
        WHEN days_with_multiple_exposures >= 5 AND avg_unsub_rate_pct > 0.2 THEN 'HIGH RISK'
        WHEN days_with_multiple_exposures >= 3 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END as deliverability_risk,
    -- Frequency cap recommendation
    CASE 
        WHEN max_daily_exposures >= 3 THEN 'Implement max 1 email per day'
        WHEN max_daily_exposures = 2 AND avg_unsub_rate_pct > 0.1 THEN 'Consider spacing emails 6+ hours apart'
        WHEN max_daily_exposures = 2 THEN 'Monitor for complaint increase'
        ELSE 'Current frequency acceptable'
    END as frequency_cap_recommendation
FROM exposure_summary
ORDER BY days_with_multiple_exposures DESC;