-- Compare frequency differences between clients
WITH client_daily_patterns AS (
    SELECT 
        SPLIT_PART(campaign_name, ' - ', 1) as client,
        sending_date,
        COUNT(*) as daily_campaigns
    FROM records.email_campaigns
    GROUP BY SPLIT_PART(campaign_name, ' - ', 1), sending_date
)
SELECT 
    client,
    AVG(daily_campaigns) as avg_daily_campaigns,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY daily_campaigns) as median_daily_campaigns,
    MAX(daily_campaigns) as max_daily_campaigns,
    -- Days with different frequency levels
    COUNT(CASE WHEN daily_campaigns >= 3 THEN 1 END) as days_with_high_frequency,
    COUNT(CASE WHEN daily_campaigns = 2 THEN 1 END) as days_with_medium_frequency,
    COUNT(CASE WHEN daily_campaigns = 1 THEN 1 END) as days_with_low_frequency,
    -- Compare to average across all clients
    AVG(daily_campaigns) - (SELECT AVG(daily_campaigns) FROM client_daily_patterns) as frequency_deviation_from_mean,
    -- Frequency comparison classification
    CASE 
        WHEN AVG(daily_campaigns) > (SELECT AVG(daily_campaigns) FROM client_daily_patterns) * 1.5 
        THEN 'Significantly Higher Frequency'
        WHEN AVG(daily_campaigns) < (SELECT AVG(daily_campaigns) FROM client_daily_patterns) * 0.5 
        THEN 'Significantly Lower Frequency'
        WHEN AVG(daily_campaigns) > (SELECT AVG(daily_campaigns) FROM client_daily_patterns) 
        THEN 'Above Average Frequency'
        WHEN AVG(daily_campaigns) < (SELECT AVG(daily_campaigns) FROM client_daily_patterns) 
        THEN 'Below Average Frequency'
        ELSE 'Average Frequency'
    END as frequency_comparison
FROM client_daily_patterns
GROUP BY client
ORDER BY avg_daily_campaigns DESC;