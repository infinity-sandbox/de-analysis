-- Model typical user lifespan and engagement decay
WITH user_lifecycle_segments AS (
    SELECT 
        s.segment_id,
        s.segment_name,
        s.segment_folder,
        -- Determine lifecycle stage from segment name
        CASE 
            WHEN s.segment_name ILIKE '%new%' OR s.segment_name ILIKE '%recent%' OR s.segment_name ILIKE '%registered%' THEN 'New (0-30 days)'
            WHEN s.segment_name ILIKE '%30 days%' OR s.segment_name ILIKE '%1 month%' THEN 'Active (1-3 months)'
            WHEN s.segment_name ILIKE '%3 month%' OR s.segment_name ILIKE '%90 days%' THEN 'Established (3-6 months)'
            WHEN s.segment_name ILIKE '%6 month%' OR s.segment_name ILIKE '%180 days%' THEN 'Mature (6-12 months)'
            WHEN s.segment_name ILIKE '%12 month%' OR s.segment_name ILIKE '%1 year%' THEN 'Long-term (>1 year)'
            WHEN s.segment_name ILIKE '%inactive%' OR s.segment_name ILIKE '%dormant%' THEN 'Inactive'
            ELSE 'Unknown'
        END as lifecycle_stage,
        AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(ec.click_rate) * 100 as avg_click_rate_pct,
        COUNT(DISTINCT ec.campaign_id) as times_used
    FROM records.segments s
    LEFT JOIN (
        SELECT ec.*, seg.value::integer as segment_id
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
        WHERE seg.value ~ '^\d+$'
    ) ec ON s.segment_id = ec.segment_id
    GROUP BY s.segment_id, s.segment_name, s.segment_folder
)
SELECT 
    lifecycle_stage,
    COUNT(DISTINCT segment_id) as segments_in_stage,
    AVG(avg_open_rate_pct) as avg_open_rate_pct,
    AVG(avg_click_rate_pct) as avg_click_rate_pct,
    SUM(times_used) as total_campaign_uses,
    -- Typical engagement decay pattern
    CASE 
        WHEN lifecycle_stage = 'New (0-30 days)' AND AVG(avg_open_rate_pct) > 25 THEN 'High initial engagement'
        WHEN lifecycle_stage = 'Active (1-3 months)' AND AVG(avg_open_rate_pct) > 20 THEN 'Good early retention'
        WHEN lifecycle_stage = 'Established (3-6 months)' AND AVG(avg_open_rate_pct) > 18 THEN 'Solid mid-term retention'
        WHEN lifecycle_stage = 'Mature (6-12 months)' AND AVG(avg_open_rate_pct) > 15 THEN 'Good long-term retention'
        WHEN lifecycle_stage = 'Long-term (>1 year)' AND AVG(avg_open_rate_pct) > 12 THEN 'Excellent retention'
        WHEN lifecycle_stage = 'Inactive' AND AVG(avg_open_rate_pct) < 10 THEN 'Expected low engagement'
        ELSE 'Review segmentation strategy'
    END as lifecycle_analysis,
    -- Commercial value by stage
    CASE 
        WHEN lifecycle_stage = 'New (0-30 days)' THEN 'High potential value'
        WHEN lifecycle_stage = 'Active (1-3 months)' THEN 'Prime monetization window'
        WHEN lifecycle_stage = 'Established (3-6 months)' THEN 'Stable revenue source'
        WHEN lifecycle_stage = 'Mature (6-12 months)' THEN 'Declining but valuable'
        WHEN lifecycle_stage = 'Long-term (>1 year)' THEN 'Low maintenance value'
        WHEN lifecycle_stage = 'Inactive' THEN 'Re-engagement or suppress'
        ELSE 'Unknown value'
    END as commercial_value_assessment
FROM user_lifecycle_segments
WHERE lifecycle_stage != 'Unknown'
GROUP BY lifecycle_stage
ORDER BY 
    CASE lifecycle_stage
        WHEN 'New (0-30 days)' THEN 1
        WHEN 'Active (1-3 months)' THEN 2
        WHEN 'Established (3-6 months)' THEN 3
        WHEN 'Mature (6-12 months)' THEN 4
        WHEN 'Long-term (>1 year)' THEN 5
        WHEN 'Inactive' THEN 6
        ELSE 7
    END;