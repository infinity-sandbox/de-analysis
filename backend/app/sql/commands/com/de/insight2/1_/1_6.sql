-- Identify most aggressive clients
SELECT 
    COUNT(*) as total_campaigns,
    COUNT(DISTINCT sending_date) as active_days,
    SUM(sent) as total_sent_volume,
    AVG(sent) as avg_campaign_size,
    SPLIT_PART(campaign_name, ' - ', 1) AS client,
    -- Aggressiveness score
    ROUND(COUNT(*)::decimal / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', sending_date)), 0), 2) as avg_campaigns_per_month,
    -- Aggressiveness classification
    CASE 
        WHEN COUNT(*) / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', sending_date)), 0) >= 15 THEN 'VERY AGGRESSIVE'
        WHEN COUNT(*) / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', sending_date)), 0) >= 10 THEN 'AGGRESSIVE'
        WHEN COUNT(*) / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', sending_date)), 0) >= 5 THEN 'MODERATE'
        WHEN COUNT(*) / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', sending_date)), 0) >= 1 THEN 'CONSERVATIVE'
        ELSE 'RARE SENDER'
    END as sending_aggressiveness,
    -- Engagement metrics
    AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
    AVG(click_rate) * 100 as avg_click_rate_pct,
    SUM(daily_revenue) as total_revenue_generated,
    -- Revenue efficiency
    CASE 
        WHEN SUM(sent) > 0 
        THEN ROUND((SUM(daily_revenue) / SUM(sent))::numeric, 4)
        ELSE 0 
    END as revenue_per_email
FROM records.email_campaigns
GROUP BY SPLIT_PART(campaign_name, ' - ', 1)
HAVING COUNT(*) >= 3  -- Only clients with at least 3 campaigns
ORDER BY avg_campaigns_per_month DESC;