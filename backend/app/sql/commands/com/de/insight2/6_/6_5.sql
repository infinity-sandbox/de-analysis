-- Analyze engagement by campaign type (inferred from name)
WITH campaign_types AS (
    SELECT 
        campaign_id,
        campaign_name,
        trackable_open_rate,
        click_rate,
        unsubscription_rate,
        delivered_rate,
        CASE 
            WHEN LOWER(campaign_name) LIKE '%batch%' THEN 'Batched Send'
            WHEN LOWER(campaign_name) LIKE '%daily%' THEN 'Daily Send'
            WHEN LOWER(campaign_name) LIKE '%trigger%' THEN 'Triggered'
            WHEN LOWER(campaign_name) LIKE '%welcome%' THEN 'Welcome'
            WHEN LOWER(campaign_name) LIKE '%re-engagement%' THEN 'Re-engagement'
            ELSE 'Standard Campaign'
        END AS campaign_type
    FROM records.email_campaigns
)
SELECT 
    campaign_type,
    COUNT(*) AS total_campaigns,
    AVG(trackable_open_rate) * 100 AS avg_open_rate_pct,
    AVG(click_rate) * 100 AS avg_click_rate_pct,
    AVG(unsubscription_rate) * 100 AS avg_unsub_rate_pct,
    AVG(delivered_rate) * 100 AS avg_delivery_rate_pct,
    -- Performance impact assessment
    CASE 
        WHEN AVG(trackable_open_rate) * 100 >= 25 THEN 'HIGH PERFORMANCE'
        WHEN AVG(trackable_open_rate) * 100 >= 18 THEN 'GOOD PERFORMANCE'
        WHEN AVG(trackable_open_rate) * 100 >= 12 THEN 'AVERAGE PERFORMANCE'
        ELSE 'LOW PERFORMANCE'
    END AS performance_category,
    -- Recommendations
    CASE 
        WHEN campaign_type = 'Re-engagement' AND AVG(trackable_open_rate) * 100 < 15 THEN 'Improve re-engagement strategy'
        WHEN campaign_type = 'Batched Send' AND AVG(unsubscription_rate) * 100 > 0.3 THEN 'Reduce batch size or improve targeting'
        WHEN campaign_type = 'Triggered' AND AVG(click_rate) * 100 < 2 THEN 'Optimize trigger conditions'
        ELSE 'Continue current approach'
    END AS recommendation
FROM campaign_types
GROUP BY campaign_type
ORDER BY avg_open_rate_pct DESC;