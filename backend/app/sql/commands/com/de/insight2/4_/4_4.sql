-- Estimate emails per user in each segment
WITH segment_volume AS (
    SELECT 
        s.segment_id,
        s.segment_name,
        SUM(ec.sent) as total_sent_last_30_days,
        COUNT(DISTINCT ec.campaign_id) as campaigns_last_30_days,
        COUNT(DISTINCT ec.sending_date) as days_active_last_30_days
    FROM records.email_campaigns ec
    LEFT JOIN LATERAL (
        SELECT value::integer as segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
        WHERE ec.audience_segment_a_ids IS NOT NULL 
          AND ec.audience_segment_a_ids != '[]'::jsonb
    ) seg_a ON TRUE
    LEFT JOIN LATERAL (
        SELECT value::integer as segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
    ) seg_b ON TRUE
    LEFT JOIN records.segments s ON COALESCE(seg_a.segment_id, seg_b.segment_id) = s.segment_id
    WHERE s.segment_id IS NOT NULL
      AND ec.sending_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY s.segment_id, s.segment_name
),
segment_size_estimate AS (
    -- Estimate segment size (max sent when segment used alone)
    SELECT 
        s.segment_id,
        MAX(ec.sent) as estimated_segment_size
    FROM records.email_campaigns ec
    LEFT JOIN LATERAL (
        SELECT value::integer as segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
        WHERE ec.audience_segment_a_ids IS NOT NULL 
          AND ec.audience_segment_a_ids != '[]'::jsonb
    ) seg_a ON TRUE
    LEFT JOIN LATERAL (
        SELECT value::integer as segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
        WHERE ec.audience_segment_b_ids IS NOT NULL 
          AND ec.audience_segment_b_ids != '[]'::jsonb
    ) seg_b ON TRUE
    LEFT JOIN records.segments s ON COALESCE(seg_a.segment_id, seg_b.segment_id) = s.segment_id
    WHERE s.segment_id IS NOT NULL
      AND (ec.audience_segment_b IS NULL OR ec.audience_segment_b = '')
    GROUP BY s.segment_id
)
SELECT 
    sv.segment_id,
    sv.segment_name,
    sv.total_sent_last_30_days,
    sv.campaigns_last_30_days,
    sv.days_active_last_30_days,
    sse.estimated_segment_size,
    -- Calculate emails per user
    CASE 
        WHEN sse.estimated_segment_size > 0 
        THEN sv.total_sent_last_30_days::decimal / sse.estimated_segment_size
        ELSE 0 
    END as estimated_emails_per_user_30_days,
    -- User pressure classification
    CASE 
        WHEN sse.estimated_segment_size > 0 
        AND sv.total_sent_last_30_days::decimal / sse.estimated_segment_size > 10 
        THEN 'CRITICAL - Over 10 emails per user'
        WHEN sse.estimated_segment_size > 0 
        AND sv.total_sent_last_30_days::decimal / sse.estimated_segment_size > 5 
        THEN 'HIGH - Over 5 emails per user'
        WHEN sse.estimated_segment_size > 0 
        AND sv.total_sent_last_30_days::decimal / sse.estimated_segment_size > 2 
        THEN 'MEDIUM - Over 2 emails per user'
        WHEN sse.estimated_segment_size > 0 
        AND sv.total_sent_last_30_days::decimal / sse.estimated_segment_size > 0 
        THEN 'LOW'
        ELSE 'NO DATA'
    END as user_pressure_level
FROM segment_volume sv
LEFT JOIN segment_size_estimate sse ON sv.segment_id = sse.segment_id
ORDER BY estimated_emails_per_user_30_days DESC;