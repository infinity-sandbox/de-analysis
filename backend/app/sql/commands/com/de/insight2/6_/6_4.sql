-- Analyze engagement decay as email pressure increases
WITH segment_daily_pressure AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.sending_date,
        COUNT(*) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date 
                      RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW) as emails_last_7_days,
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
      AND ec.delivered > 100  -- Ensure reasonable sample size
)
SELECT 
    emails_last_7_days,
    COUNT(*) as observation_count,
    AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(click_rate) * 100 as avg_click_rate_pct,
    AVG(unsubscription_rate) * 100 as avg_unsub_rate_pct,
    -- Identify breakpoints where engagement drops sharply
    CASE 
        WHEN emails_last_7_days >= 10 AND AVG(trackable_open_rate) * 100 < 10 THEN 'BREAKPOINT: Engagement collapses'
        WHEN emails_last_7_days >= 7 AND AVG(trackable_open_rate) * 100 < 15 THEN 'BREAKPOINT: High frequency damage'
        WHEN emails_last_7_days >= 5 AND AVG(trackable_open_rate) * 100 < 20 THEN 'WARNING: Engagement declining'
        WHEN emails_last_7_days >= 3 AND AVG(trackable_open_rate) * 100 >= 25 THEN 'SAFE: High tolerance'
        ELSE 'NORMAL'
    END as decay_analysis,
    -- Determine safe frequency ranges
    CASE 
        WHEN emails_last_7_days >= 10 AND AVG(trackable_open_rate) * 100 < 10 THEN 'MAX SAFE: 2 emails/week'
        WHEN emails_last_7_days >= 7 AND AVG(trackable_open_rate) * 100 < 15 THEN 'MAX SAFE: 3 emails/week'
        WHEN emails_last_7_days >= 5 AND AVG(trackable_open_rate) * 100 < 20 THEN 'MAX SAFE: 4 emails/week'
        WHEN emails_last_7_days >= 3 AND AVG(trackable_open_rate) * 100 >= 25 THEN 'MAX SAFE: 7+ emails/week'
        WHEN emails_last_7_days = 1 AND AVG(trackable_open_rate) * 100 >= 30 THEN 'COULD TEST: Higher frequency'
        ELSE 'NEEDS MORE DATA'
    END as safe_frequency_range
FROM segment_daily_pressure
GROUP BY emails_last_7_days
HAVING COUNT(*) >= 10
ORDER BY emails_last_7_days;