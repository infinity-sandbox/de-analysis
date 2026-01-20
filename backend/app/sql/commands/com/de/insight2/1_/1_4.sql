-- Analyze consistency of sending patterns
WITH daily_client_stats AS (
    SELECT 
        SPLIT_PART(campaign_name, ' - ', 1) as client,
        sending_date,
        COUNT(*) as daily_campaigns,
        SUM(sent) as daily_sent
    FROM records.email_campaigns
    GROUP BY SPLIT_PART(campaign_name, ' - ', 1), sending_date
)
SELECT 
    client,
    COUNT(DISTINCT sending_date) as total_active_days,
    AVG(daily_campaigns) as avg_campaigns_per_day,
    STDDEV(daily_campaigns) as stddev_campaigns_per_day,
    AVG(daily_sent) as avg_sent_per_day,
    STDDEV(daily_sent) as stddev_sent_per_day,
    -- Consistency calculation (lower CV = more consistent)
    CASE 
        WHEN AVG(daily_campaigns) > 0 
        THEN ROUND((STDDEV(daily_campaigns) / AVG(daily_campaigns))::numeric, 2)
        ELSE 0 
    END as campaigns_consistency_index,
    -- Pattern classification
    CASE 
        WHEN STDDEV(daily_campaigns) = 0 THEN 'Perfectly Consistent'
        WHEN (STDDEV(daily_campaigns) / NULLIF(AVG(daily_campaigns), 0)) < 0.5 THEN 'Consistent Pattern'
        WHEN (STDDEV(daily_campaigns) / NULLIF(AVG(daily_campaigns), 0)) < 1.0 THEN 'Variable Pattern'
        ELSE 'Irregular Bursts'
    END as sending_pattern,
    -- Peak detection
    MAX(daily_campaigns) as max_campaigns_per_day,
    MIN(daily_campaigns) as min_campaigns_per_day
FROM daily_client_stats
GROUP BY client
ORDER BY avg_campaigns_per_day DESC;