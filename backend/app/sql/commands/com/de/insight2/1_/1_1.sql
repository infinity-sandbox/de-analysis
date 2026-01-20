-- Daily campaigns sent per client
SELECT 
    SPLIT_PART(campaign_name, ' - ', 1) as client,
    sending_date,
    COUNT(*) as campaigns_per_day,
    SUM(sent) as total_sent_per_day,
    AVG(sent) as avg_campaign_size,
    -- Client frequency pattern
    CASE 
        WHEN COUNT(*) >= 3 THEN 'High Daily Frequency'
        WHEN COUNT(*) = 2 THEN 'Medium Daily Frequency'
        WHEN COUNT(*) = 1 THEN 'Normal Daily Frequency'
        ELSE 'No Campaigns'
    END as daily_frequency_pattern
FROM records.email_campaigns
GROUP BY SPLIT_PART(campaign_name, ' - ', 1), sending_date
ORDER BY sending_date DESC, campaigns_per_day DESC;