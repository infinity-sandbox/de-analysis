-- Identify segments that are potentially over-emailed
WITH monthly_stats AS (
    SELECT 
        s.segment_id,
        s.segment_name,
        EXTRACT(YEAR FROM ec.sending_date) as year,
        EXTRACT(MONTH FROM ec.sending_date) as month,
        SUM(ec.sent) as monthly_sent,
        COUNT(DISTINCT ec.campaign_id) as monthly_campaigns,
        COUNT(DISTINCT ec.sending_date) as active_days,
        AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(ec.unsubscription_rate) * 100 as avg_unsub_rate_pct
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
    GROUP BY s.segment_id, s.segment_name, year, month
)
SELECT 
    segment_id,
    segment_name,
    year,
    month,
    monthly_sent,
    monthly_campaigns,
    active_days,
    avg_open_rate_pct,
    avg_unsub_rate_pct,
    -- Flag potential over-emailing
    CASE 
        WHEN active_days >= 20 AND avg_open_rate_pct < 15 THEN 'OVER-EMAILED: High frequency, low engagement'
        WHEN monthly_campaigns >= 15 AND avg_unsub_rate_pct > 0.3 THEN 'OVER-EMAILED: High unsubscribe rate'
        WHEN active_days >= 15 THEN 'HIGH FREQUENCY'
        WHEN active_days >= 10 THEN 'MODERATE FREQUENCY'
        ELSE 'NORMAL'
    END as emailing_status,
    -- Recommendation
    CASE 
        WHEN active_days >= 20 AND avg_open_rate_pct < 15 THEN 'Reduce frequency by 50%'
        WHEN monthly_campaigns >= 15 AND avg_unsub_rate_pct > 0.3 THEN 'Implement cooldown period'
        WHEN active_days >= 15 AND avg_open_rate_pct < 20 THEN 'Reduce to 3 days per week'
        ELSE 'Maintain current frequency'
    END as recommendation
FROM monthly_stats
ORDER BY year DESC, month DESC, active_days DESC;