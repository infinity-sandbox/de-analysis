-- Track how frequently same segment is used on consecutive days
WITH segment_daily_usage AS (
    SELECT DISTINCT
        seg.value::integer as segment_id,
        s.segment_name,
        ec.sending_date,
        LAG(ec.sending_date) OVER (PARTITION BY seg.value::integer ORDER BY ec.sending_date) as previous_use_date
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
    COUNT(DISTINCT sending_date) as total_days_used,
    COUNT(CASE WHEN sending_date - previous_use_date = 1 THEN 1 END) as consecutive_days_count,
    -- Calculate consecutive day percentage
    ROUND(
        COUNT(CASE WHEN sending_date - previous_use_date = 1 THEN 1 END)::decimal / 
        NULLIF(COUNT(DISTINCT sending_date), 0) * 100, 
        2
    ) as consecutive_day_percentage,
    -- Habit vs intentional usage
    CASE 
        WHEN COUNT(CASE WHEN sending_date - previous_use_date = 1 THEN 1 END) > 10 
        THEN 'HABITUAL USE: Likely automated/routine'
        WHEN COUNT(CASE WHEN sending_date - previous_use_date = 1 THEN 1 END) > 5 
        THEN 'FREQUENT USE: Regular but not daily'
        WHEN COUNT(CASE WHEN sending_date - previous_use_date = 1 THEN 1 END) > 0 
        THEN 'OCCASIONAL CONSECUTIVE USE: May be strategic'
        ELSE 'SPORADIC USE: Likely intentional targeting'
    END as usage_pattern
FROM segment_daily_usage
GROUP BY segment_id, segment_name
ORDER BY consecutive_days_count DESC;