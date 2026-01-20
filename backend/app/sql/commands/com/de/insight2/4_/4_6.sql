-- Identify segments carrying high monetization load
SELECT 
    s.segment_id,
    s.segment_name,
    COUNT(DISTINCT ec.campaign_id) as total_campaigns,
    SUM(ec.sent) as total_sent_all_time,
    SUM(ec.daily_revenue) as total_revenue_generated,
    AVG(ec.daily_revenue) as avg_revenue_per_campaign,
    -- Revenue per email sent
    CASE 
        WHEN SUM(ec.sent) > 0 
        THEN SUM(ec.daily_revenue) / SUM(ec.sent)
        ELSE 0 
    END as revenue_per_email,
    -- Campaigns per month average
    COUNT(DISTINCT ec.campaign_id) / COUNT(DISTINCT DATE_TRUNC('month', ec.sending_date)) as avg_campaigns_per_month,
    -- Load classification
    CASE 
        WHEN COUNT(DISTINCT ec.campaign_id) >= 20 THEN 'HIGH LOAD: Primary monetization segment'
        WHEN COUNT(DISTINCT ec.campaign_id) >= 10 THEN 'MEDIUM LOAD: Secondary monetization'
        WHEN COUNT(DISTINCT ec.campaign_id) >= 5 THEN 'LOW LOAD: Occasional use'
        ELSE 'MINIMAL LOAD'
    END as monetization_load,
    -- Risk if segment becomes unavailable
    CASE 
        WHEN COUNT(DISTINCT ec.campaign_id) >= 20 
        AND SUM(ec.daily_revenue) / (SELECT SUM(daily_revenue) FROM records.email_campaigns) > 0.3
        THEN 'CRITICAL: Over-reliant on this segment'
        WHEN COUNT(DISTINCT ec.campaign_id) >= 10 
        AND SUM(ec.daily_revenue) / (SELECT SUM(daily_revenue) FROM records.email_campaigns) > 0.2
        THEN 'HIGH RISK: Heavy reliance'
        ELSE 'MANAGEABLE'
    END as dependency_risk
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
GROUP BY s.segment_id, s.segment_name
ORDER BY total_revenue_generated DESC;