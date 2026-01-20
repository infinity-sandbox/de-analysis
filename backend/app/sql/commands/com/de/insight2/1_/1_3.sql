-- Monthly campaigns sent per client
SELECT 
    SPLIT_PART(campaign_name, ' - ', 1) as client,
    EXTRACT(YEAR FROM sending_date) as year,
    EXTRACT(MONTH FROM sending_date) as month,
    COUNT(*) as campaigns_per_month,
    SUM(sent) as total_sent_per_month,
    AVG(sent) as avg_campaign_size,
    COUNT(DISTINCT sending_date) as active_days_per_month,
    -- Monthly frequency classification
    CASE 
        WHEN COUNT(*) >= 20 THEN 'Very Aggressive Sending'
        WHEN COUNT(*) >= 15 THEN 'Aggressive Sending'
        WHEN COUNT(*) >= 10 THEN 'Frequent Sending'
        WHEN COUNT(*) >= 5 THEN 'Moderate Sending'
        WHEN COUNT(*) >= 1 THEN 'Infrequent Sending'
        ELSE 'No Campaigns'
    END as monthly_frequency_category,
    -- Calculate campaigns per day average
    ROUND(COUNT(*)::decimal / NULLIF(COUNT(DISTINCT sending_date), 0), 2) as avg_campaigns_per_active_day
FROM records.email_campaigns
GROUP BY SPLIT_PART(campaign_name, ' - ', 1), year, month
ORDER BY year DESC, month DESC, campaigns_per_month DESC;