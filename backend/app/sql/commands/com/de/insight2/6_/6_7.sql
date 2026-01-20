-- Identify which segments tolerate higher frequency
WITH segment_engagement_trends AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.sending_date,
        COUNT(*) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date 
                      RANGE BETWEEN INTERVAL '14 days' PRECEDING AND CURRENT ROW) as emails_last_14_days,
        ec.trackable_open_rate,
        ec.click_rate,
        ec.unsubscription_rate,
        ec.delivered
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
      AND ec.delivered > 100
)
SELECT 
    segment_id,
    segment_name,
    COUNT(*) as total_observations,
    AVG(trackable_open_rate) * 100 as overall_open_rate_pct,
    -- High frequency performance (when receiving 5+ emails in 14 days)
    AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 as high_freq_open_rate_pct,
    -- Low frequency performance (when receiving 1-2 emails in 14 days)
    AVG(CASE WHEN emails_last_14_days <= 2 THEN trackable_open_rate END) * 100 as low_freq_open_rate_pct,
    -- Tolerance calculation
    CASE 
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 20 
        THEN 'HIGH TOLERANCE: Can handle frequent emails'
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 15 
        THEN 'MODERATE TOLERANCE: Limit to 3-4 emails/14 days'
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 10 
        THEN 'LOW TOLERANCE: Limit to 1-2 emails/14 days'
        ELSE 'VERY LOW TOLERANCE: Use sparingly'
    END as frequency_tolerance,
    -- Optimal frequency recommendation
    CASE 
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 20 
        THEN 'Safe to send 5-7 emails every 14 days'
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 15 
        THEN 'Optimal: 3-4 emails every 14 days'
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 >= 10 
        THEN 'Optimal: 1-2 emails every 14 days'
        ELSE 'Maximum: 1 email every 14 days'
    END as optimal_frequency,
    -- When recovery emails are needed
    CASE 
        WHEN AVG(unsubscription_rate) * 100 > 0.5 THEN 'IMMEDIATE: High unsubscribe rate'
        WHEN AVG(trackable_open_rate) * 100 < 15 AND COUNT(*) >= 10 THEN 'SOON: Engagement declining'
        WHEN AVG(CASE WHEN emails_last_14_days >= 5 THEN trackable_open_rate END) * 100 < 10 THEN 'AFTER HIGH-FREQUENCY BURSTS'
        ELSE 'AS NEEDED: Based on engagement monitoring'
    END as recovery_email_timing
FROM segment_engagement_trends
GROUP BY segment_id, segment_name
HAVING COUNT(*) >= 10
ORDER BY high_freq_open_rate_pct DESC;