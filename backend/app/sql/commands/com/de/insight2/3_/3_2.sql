-- 1. Basic segment size estimation
SELECT 
    seg.segment_id,
    seg.segment_name,
    seg.segment_folder,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns,
    AVG(ec.sent) as avg_sent_per_campaign,
    MIN(ec.sent) as min_sent,
    MAX(ec.sent) as max_sent,
    -- Estimated size = max sent when segment used alone
    MAX(CASE 
        WHEN ec.audience_segment_b IS NULL OR ec.audience_segment_b = '' 
        THEN ec.sent 
        ELSE NULL 
    END) as estimated_size
FROM records.email_campaigns ec
LEFT JOIN LATERAL (
    SELECT 
        value::integer as segment_id,
        'A' as segment_type
    FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
    WHERE ec.audience_segment_a_ids IS NOT NULL 
      AND ec.audience_segment_a_ids != '[]'::jsonb
) seg_a ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        value::integer as segment_id,
        'B' as segment_type
    FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
    WHERE ec.audience_segment_b_ids IS NOT NULL 
      AND ec.audience_segment_b_ids != '[]'::jsonb
) seg_b ON TRUE
LEFT JOIN records.segments seg ON COALESCE(seg_a.segment_id, seg_b.segment_id) = seg.segment_id
WHERE seg.segment_id IS NOT NULL
GROUP BY seg.segment_id, seg.segment_name, seg.segment_folder
ORDER BY estimated_size DESC NULLS LAST;