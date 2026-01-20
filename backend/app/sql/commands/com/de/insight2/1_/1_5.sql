-- Identify peak sending days for each client
SELECT 
    client,
    sending_date,
    daily_campaigns,
    daily_sent,
    ROW_NUMBER() OVER (PARTITION BY client ORDER BY daily_campaigns DESC) as peak_rank
FROM (
    SELECT 
        SPLIT_PART(campaign_name, ' - ', 1) as client,
        sending_date,
        COUNT(*) as daily_campaigns,
        SUM(sent) as daily_sent
    FROM records.email_campaigns
    GROUP BY SPLIT_PART(campaign_name, ' - ', 1), sending_date
) daily_stats
WHERE daily_campaigns >= 2  -- Only show days with multiple campaigns
ORDER BY client, peak_rank;