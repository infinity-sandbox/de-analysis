-- 6. Combined summary for segment volume estimation
SELECT 
    seg.segment_id,
    seg.segment_name,
    seg.segment_folder,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns_used,
    COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) as active_months,
    SUM(ec.sent) as total_sent_volume,
    AVG(ec.sent) as avg_campaign_size,
    MAX(ec.sent) as max_campaign_size,
    -- Estimate segment size (when used alone)
    MAX(CASE 
        WHEN ec.audience_segment_a IS NOT NULL 
        AND (ec.audience_segment_b IS NULL OR ec.audience_segment_b = '')
        THEN ec.sent
        ELSE NULL
    END) as estimated_segment_size,
    -- Performance metrics
    AVG(ec.delivered_rate) * 100 as avg_delivery_pct,
    AVG(ec.trackable_open_rate) * 100 as avg_open_pct,
    -- Risk rating
    CASE 
        WHEN COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) >= 6 
        AND AVG(ec.trackable_open_rate) < 0.15 
        THEN 'High Risk - Potential Fatigue'
        WHEN COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) >= 3 
        AND AVG(ec.trackable_open_rate) < 0.20 
        THEN 'Medium Risk - Monitor Closely'
        ELSE 'Low Risk'
    END as risk_rating
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
GROUP BY seg.segment_id, seg.segment_name, seg.segment_folder
ORDER BY total_sent_volume DESC;