-- Determine optimal suppression and cooldown rules
WITH segment_performance AS (
    SELECT 
        s.segment_id,
        s.segment_name,
        s.uses_engagement,
        s.uses_date_rule,
        COUNT(DISTINCT ec.campaign_id) as times_used,
        AVG(ec.trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(ec.click_rate) * 100 as avg_click_rate_pct,
        AVG(ec.unsubscription_rate) * 100 as avg_unsub_rate_pct,
        AVG(ec.delivered_rate) * 100 as avg_delivery_rate_pct
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
    GROUP BY s.segment_id, s.segment_name, s.uses_engagement, s.uses_date_rule
)
SELECT 
    segment_id,
    segment_name,
    uses_engagement,
    uses_date_rule,
    times_used,
    avg_open_rate_pct,
    avg_click_rate_pct,
    avg_unsub_rate_pct,
    avg_delivery_rate_pct,
    -- Current rule effectiveness
    CASE 
        WHEN uses_engagement = TRUE AND avg_open_rate_pct > 20 THEN 'Effective engagement rule'
        WHEN uses_engagement = TRUE AND avg_open_rate_pct < 15 THEN 'Ineffective engagement rule'
        WHEN uses_date_rule = TRUE AND avg_unsub_rate_pct < 0.3 THEN 'Effective date rule'
        WHEN uses_date_rule = TRUE AND avg_unsub_rate_pct > 0.5 THEN 'Ineffective date rule'
        WHEN uses_engagement = FALSE AND uses_date_rule = FALSE AND avg_open_rate_pct < 10 THEN 'Need engagement/date rules'
        ELSE 'Rules may need adjustment'
    END as current_rules_effectiveness,
    -- Suppression recommendation
    CASE 
        WHEN avg_open_rate_pct < 10 AND avg_unsub_rate_pct > 0.5 THEN 'IMMEDIATE SUPPRESSION'
        WHEN avg_open_rate_pct < 15 AND avg_unsub_rate_pct > 0.3 THEN 'SUPPRESS after 2 more campaigns'
        WHEN avg_delivery_rate_pct < 90 THEN 'COOLDOWN: Reduce frequency by 50%'
        WHEN avg_open_rate_pct < 20 AND times_used > 10 THEN 'COOLDOWN: Skip next 2 campaigns'
        ELSE 'No suppression needed'
    END as suppression_recommendation,
    -- Optimal rule adjustment
    CASE 
        WHEN uses_engagement = FALSE AND avg_open_rate_pct < 15 THEN 'Add: Not opened in 30 days rule'
        WHEN uses_date_rule = FALSE AND avg_unsub_rate_pct > 0.3 THEN 'Add: Registered more than 6 months ago rule'
        WHEN avg_open_rate_pct < 10 THEN 'Replace: Use more restrictive engagement filter'
        WHEN avg_delivery_rate_pct < 85 THEN 'Add: Bounce or complaint suppression'
        ELSE 'Current rules optimal'
    END as rule_optimization
FROM segment_performance
WHERE times_used >= 3
ORDER BY avg_open_rate_pct ASC;