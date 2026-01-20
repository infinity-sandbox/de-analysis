-- Analyze if frequency aligns with engagement and revenue
WITH client_metrics AS (
    SELECT 
        SPLIT_PART(campaign_name, ' - ', 1) as client,
        COUNT(*) as total_campaigns,
        COUNT(DISTINCT sending_date) as active_days,
        SUM(sent) as total_sent,
        AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(click_rate) * 100 as avg_click_rate_pct,
        SUM(daily_revenue) as total_revenue,
        AVG(daily_revenue) as avg_revenue_per_campaign
    FROM records.email_campaigns
    GROUP BY SPLIT_PART(campaign_name, ' - ', 1)
)
SELECT 
    client,
    total_campaigns,
    active_days,
    total_sent,
    avg_open_rate_pct,
    avg_click_rate_pct,
    total_revenue,
    avg_revenue_per_campaign,
    -- Campaigns per day ratio
    ROUND(total_campaigns::decimal / NULLIF(active_days, 0), 2) as campaigns_per_day_ratio,
    -- Frequency effectiveness assessment
    CASE 
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) >= 2 
        AND avg_open_rate_pct < 15 THEN 'OVER-FREQUENT: High frequency, low engagement'
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) >= 2 
        AND avg_open_rate_pct >= 20 THEN 'OPTIMAL: High frequency, high engagement'
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) < 1 
        AND avg_open_rate_pct >= 25 THEN 'UNDER-FREQUENT: Could send more'
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) >= 1 
        AND avg_open_rate_pct >= 18 THEN 'BALANCED: Good frequency and engagement'
        ELSE 'NEEDS REVIEW'
    END as frequency_effectiveness,
    -- Revenue justification
    CASE 
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) >= 2 
        AND avg_revenue_per_campaign > 100 THEN 'JUSTIFIED: High frequency drives revenue'
        WHEN (total_campaigns::decimal / NULLIF(active_days, 0)) >= 2 
        AND avg_revenue_per_campaign < 50 THEN 'QUESTIONABLE: High frequency, low revenue'
        ELSE 'APPROPRIATE: Frequency matches revenue potential'
    END as revenue_justification
FROM client_metrics
WHERE total_campaigns >= 5
ORDER BY campaigns_per_day_ratio DESC;