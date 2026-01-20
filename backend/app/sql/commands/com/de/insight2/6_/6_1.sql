-- Engagement metrics by client
SELECT 
    SPLIT_PART(campaign_name, ' - ', 1) as client,
    COUNT(*) as total_campaigns,
    AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(click_rate) * 100 as avg_click_rate_pct,
    AVG(unsubscription_rate) * 100 as avg_unsub_rate_pct,
    -- Revenue metrics
    SUM(daily_revenue) as total_revenue,
    AVG(daily_revenue) as avg_revenue_per_campaign,
    -- Frequency metrics
    COUNT(DISTINCT sending_date) / COUNT(DISTINCT DATE_TRUNC('month', sending_date)) as avg_campaigns_per_month,
    -- Engagement classification
    CASE 
        WHEN AVG(trackable_open_rate) >= 0.2 THEN 'High Engagement'
        WHEN AVG(trackable_open_rate) >= 0.15 THEN 'Medium Engagement'
        WHEN AVG(trackable_open_rate) >= 0.1 THEN 'Low Engagement'
        ELSE 'Poor Engagement'
    END as engagement_level
FROM records.email_campaigns
GROUP BY SPLIT_PART(campaign_name, ' - ', 1)
ORDER BY avg_open_rate_pct DESC;