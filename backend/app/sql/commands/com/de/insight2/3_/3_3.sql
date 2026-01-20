-- 2. Segment proportion of total list
WITH total_volumes AS (
    SELECT 
        SUM(sent) as total_sent_all_campaigns,
        MAX(sent) as max_campaign_size
    FROM records.email_campaigns
),
segment_stats AS (
    SELECT 
        seg.segment_id,
        seg.segment_name,
        SUM(ec.sent) as total_sent_to_segment,
        COUNT(DISTINCT ec.campaign_id) as campaign_count
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
)
SELECT 
    s.segment_id,
    s.segment_name,
    s.total_sent_to_segment,
    s.campaign_count,
    t.total_sent_all_campaigns,
    -- Calculate percentage of total
    ROUND((s.total_sent_to_segment::decimal / t.total_sent_all_campaigns * 100)::numeric, 2) as percent_of_total,
    -- Estimate relative size
    ROUND((s.total_sent_to_segment::decimal / s.campaign_count)::numeric, 0) as estimated_avg_size
FROM segment_stats s, total_volumes t
ORDER BY percent_of_total DESC;