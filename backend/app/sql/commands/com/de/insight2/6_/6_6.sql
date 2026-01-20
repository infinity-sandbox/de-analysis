-- Analyze how one campaign affects next-day performance
WITH campaign_sequence AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.campaign_id,
        ec.sending_date,
        ec.trackable_open_rate as open_rate_today,
        ec.click_rate as click_rate_today,
        LEAD(ec.trackable_open_rate) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date) as open_rate_next_day,
        LEAD(ec.click_rate) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date) as click_rate_next_day,
        -- Check if next day has campaign
        LEAD(ec.campaign_id) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date) as next_day_campaign
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
    segment_id,
    segment_name,
    COUNT(*) as sequence_pairs,
    AVG(open_rate_today) * 100 as avg_open_rate_today_pct,
    AVG(open_rate_next_day) * 100 as avg_open_rate_next_day_pct,
    AVG(click_rate_today) * 100 as avg_click_rate_today_pct,
    AVG(click_rate_next_day) * 100 as avg_click_rate_next_day_pct,
    -- Calculate performance drop
    (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 as open_rate_drop_pct,
    (AVG(click_rate_today) - AVG(click_rate_next_day)) * 100 as click_rate_drop_pct,
    -- Impact analysis
    CASE 
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 > 5 THEN 'SIGNIFICANT NEGATIVE IMPACT'
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 > 2 THEN 'MODERATE NEGATIVE IMPACT'
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 < 0 THEN 'POSITIVE OR NEUTRAL IMPACT'
        ELSE 'MINIMAL IMPACT'
    END as next_day_impact,
    -- Recovery email need assessment
    CASE 
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 > 5 THEN 'URGENT: Need high-engagement recovery email'
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 > 2 THEN 'RECOMMENDED: Schedule re-engagement campaign'
        WHEN (AVG(open_rate_today) - AVG(open_rate_next_day)) * 100 < 0 THEN 'NO NEED: Performance stable or improving'
        ELSE 'MONITOR: Consider occasional re-engagement'
    END as recovery_email_recommendation
FROM campaign_sequence
WHERE next_day_campaign IS NOT NULL
GROUP BY segment_id, segment_name
HAVING COUNT(*) >= 5
ORDER BY open_rate_drop_pct DESC;