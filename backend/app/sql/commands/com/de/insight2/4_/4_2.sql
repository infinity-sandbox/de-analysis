-- Weekly emails sent per segment
SELECT 
    s.segment_id,
    s.segment_name,
    EXTRACT(YEAR FROM ec.sending_date) as year,
    EXTRACT(WEEK FROM ec.sending_date) as week,
    SUM(ec.sent) as total_sent_weekly,
    COUNT(DISTINCT ec.campaign_id) as campaigns_per_week,
    COUNT(DISTINCT ec.sending_date) as days_active_per_week,
    -- Calculate emails per day average
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
GROUP BY s.segment_id, s.segment_name, year, week
ORDER BY year DESC, week DESC, total_sent_weekly DESC;