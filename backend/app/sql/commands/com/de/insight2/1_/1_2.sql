-- Weekly campaigns sent per client
SELECT 
    SPLIT_PART(campaign_name, ' - ', 1) as client,
    EXTRACT(YEAR FROM sending_date) as year,
    EXTRACT(WEEK FROM sending_date) as week,
    COUNT(*) as campaigns_per_week,
    SUM(sent) as total_sent_per_week,
    AVG(sent) as avg_campaign_size,
    COUNT(DISTINCT sending_date) as active_days_per_week,
    -- Calculate campaigns per active day
    ROUND(COUNT(*)::decimal / NULLIF(COUNT(DISTINCT sending_date), 0), 2) as avg_campaigns_per_active_day,
    -- Weekly frequency classification
    CASE 
        WHEN COUNT(*) >= 10 THEN 'Very High Weekly Frequency'
        WHEN COUNT(*) >= 7 THEN 'High Weekly Frequency'
        WHEN COUNT(*) >= 4 THEN 'Medium Weekly Frequency'
        WHEN COUNT(*) >= 1 THEN 'Low Weekly Frequency'
        ELSE 'No Campaigns'
    END as weekly_frequency_category
FROM records.email_campaigns
GROUP BY SPLIT_PART(campaign_name, ' - ', 1), year, week
ORDER BY year DESC, week DESC, campaigns_per_week DESC;