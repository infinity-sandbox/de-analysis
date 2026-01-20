-- 3. Segment volume changes over time (monthly)
SELECT 
    seg.segment_id,
    seg.segment_name,
    DATE_TRUNC('month', ec.sending_date) as month,
    COUNT(DISTINCT ec.campaign_id) as campaigns_per_month,
    SUM(ec.sent) as total_sent_monthly,
    AVG(ec.sent) as avg_sent_per_campaign,
    LAG(SUM(ec.sent)) OVER (PARTITION BY seg.segment_id ORDER BY DATE_TRUNC('month', ec.sending_date)) as prev_month_total
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
LEFT JOIN records.segments seg ON COALESCE(seg_a.segment_id, seg_b.segment_id) = seg.segment_id
WHERE seg.segment_id IS NOT NULL
GROUP BY seg.segment_id, seg.segment_name, DATE_TRUNC('month', ec.sending_date)
ORDER BY seg.segment_id, month DESC;