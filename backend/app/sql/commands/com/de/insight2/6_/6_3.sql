-- Analyze how engagement changes with frequency
WITH segment_frequency AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.sending_date,
        COUNT(*) OVER (PARTITION BY seg.value::integer, DATE_TRUNC('week', ec.sending_date)) as campaigns_per_week,
        ec.trackable_open_rate,
        ec.click_rate,
        ec.unsubscription_rate
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
    campaigns_per_week,
    COUNT(*) as observation_count,
    AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(click_rate) * 100 as avg_click_rate_pct,
    AVG(unsubscription_rate) * 100 as avg_unsub_rate_pct,
    -- Engagement change from baseline (1 campaign/week)
    AVG(trackable_open_rate) * 100 - 
        FIRST_VALUE(AVG(trackable_open_rate) * 100) OVER (ORDER BY campaigns_per_week) as open_rate_change_from_baseline,
    -- Frequency impact analysis
    CASE 
        WHEN AVG(trackable_open_rate) * 100 < 10 THEN 'CRITICAL: Engagement too low'
        WHEN campaigns_per_week >= 5 AND AVG(trackable_open_rate) * 100 < 15 THEN 'HIGH FREQUENCY, LOW ENGAGEMENT'
        WHEN campaigns_per_week >= 3 AND AVG(trackable_open_rate) * 100 >= 20 THEN 'HIGH FREQUENCY, HIGH ENGAGEMENT'
        WHEN campaigns_per_week >= 2 AND AVG(trackable_open_rate) * 100 >= 15 THEN 'OPTIMAL FREQUENCY'
        ELSE 'NORMAL'
    END as frequency_impact,
    -- Safe frequency recommendation
    CASE 
        WHEN AVG(trackable_open_rate) * 100 < 10 AND campaigns_per_week > 2 THEN 'Reduce to 1 campaign/week'
        WHEN campaigns_per_week >= 5 AND AVG(trackable_open_rate) * 100 < 15 THEN 'Reduce to 2-3 campaigns/week'
        WHEN campaigns_per_week >= 3 AND AVG(trackable_open_rate) * 100 >= 20 THEN 'Safe to maintain current frequency'
        WHEN campaigns_per_week = 1 AND AVG(trackable_open_rate) * 100 >= 25 THEN 'Could test 2 campaigns/week'
        ELSE 'Monitor current frequency'
    END as frequency_recommendation
FROM segment_frequency
GROUP BY campaigns_per_week
HAVING COUNT(*) >= 5
ORDER BY campaigns_per_week;