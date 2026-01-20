-- 5. Segment reachability analysis
SELECT 
    seg.segment_id,
    seg.segment_name,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns,
    AVG(ec.delivered_rate) * 100 as avg_delivery_rate_pct,
    AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(ec.click_rate) * 100 as avg_click_rate_pct,
    -- Reachability classification
    CASE 
        WHEN AVG(ec.delivered_rate) >= 0.95 THEN 'High Reach'
        WHEN AVG(ec.delivered_rate) >= 0.90 THEN 'Good Reach'
        WHEN AVG(ec.delivered_rate) >= 0.85 THEN 'Medium Reach'
        ELSE 'Low Reach'
    END as reachability,
    -- Estimated active percentage
    CASE 
        WHEN AVG(ec.delivered_rate) >= 0.95 AND AVG(ec.trackable_open_rate) >= 0.15 
        THEN 'Highly Active Segment'
        WHEN AVG(ec.delivered_rate) >= 0.90 AND AVG(ec.trackable_open_rate) >= 0.10
        THEN 'Active Segment'
        ELSE 'Requires Attention'
    END as segment_health
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
GROUP BY seg.segment_id, seg.segment_name
ORDER BY avg_delivery_rate_pct DESC;