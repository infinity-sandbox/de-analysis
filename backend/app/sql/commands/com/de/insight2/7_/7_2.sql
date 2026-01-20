-- Analyze how quickly users stop engaging
WITH segment_engagement_trends AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.sending_date,
        ec.trackable_open_rate * 100 as open_rate_pct,
        ec.click_rate * 100 as click_rate_pct,
        ec.unsubscription_rate * 100 as unsub_rate_pct,
        CASE 
            WHEN s.segment_name LIKE '%recent%' OR s.segment_name LIKE '%new%' THEN 'New Users'
            WHEN s.segment_name LIKE '%inactive%' OR s.segment_name LIKE '%not opened%' THEN 'Inactive Users'
            WHEN s.segment_name LIKE '%active%' OR s.segment_name LIKE '%clicked%' THEN 'Active Users'
            ELSE 'Other'
        END as user_lifecycle_stage
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
    JOIN records.segments s ON seg.value::integer = s.segment_id
    WHERE seg.value ~ '^\d+$'
)
SELECT 
    user_lifecycle_stage,
    COUNT(DISTINCT segment_id) as segments_in_stage,
    AVG(open_rate_pct) as avg_open_rate_pct,
    AVG(click_rate_pct) as avg_click_rate_pct,
    AVG(unsub_rate_pct) as avg_unsub_rate_pct,
    -- Decay patterns
    CASE 
        WHEN user_lifecycle_stage = 'New Users' AND AVG(open_rate_pct) > 25 THEN 'High initial engagement'
        WHEN user_lifecycle_stage = 'Active Users' AND AVG(open_rate_pct) > 20 THEN 'Sustained engagement'
        WHEN user_lifecycle_stage = 'Inactive Users' AND AVG(open_rate_pct) < 10 THEN 'Significant decay'
        WHEN user_lifecycle_stage = 'Other' AND AVG(open_rate_pct) < 15 THEN 'General decay'
        ELSE 'Moderate engagement'
    END as decay_analysis,
    -- When to suppress
    CASE 
        WHEN user_lifecycle_stage = 'Inactive Users' AND AVG(open_rate_pct) < 5 THEN 'SUPPRESS: No engagement'
        WHEN user_lifecycle_stage = 'Other' AND AVG(open_rate_pct) < 10 AND AVG(unsub_rate_pct) > 0.5 THEN 'SUPPRESS: High unsub rate'
        WHEN user_lifecycle_stage = 'Active Users' AND AVG(open_rate_pct) < 15 THEN 'COOLDOWN: Reduce frequency'
        ELSE 'MAINTAIN: Acceptable engagement'
    END as suppression_recommendation
FROM segment_engagement_trends
WHERE user_lifecycle_stage != 'Other'
GROUP BY user_lifecycle_stage
ORDER BY avg_open_rate_pct DESC;