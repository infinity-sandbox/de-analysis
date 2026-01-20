-- Monthly emails sent per segment
SELECT 
    s.segment_id,
    s.segment_name,
    EXTRACT(YEAR FROM ec.sending_date) as year,
    EXTRACT(MONTH FROM ec.sending_date) as month,
    SUM(ec.sent) as total_sent_monthly,
    COUNT(DISTINCT ec.campaign_id) as campaigns_per_month,
    COUNT(DISTINCT ec.sending_date) as days_active_per_month,
    -- Calculate average daily volume
    SUM(ec.sent) / COUNT(DISTINCT ec.sending_date) as avg_sent_per_day
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
ORDER BY year DESC, month DESC, total_sent_monthly DESC;