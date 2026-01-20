-- Analyze list growth vs decay over time
WITH monthly_list_metrics AS (
    SELECT 
        EXTRACT(YEAR FROM sending_date) as year,
        EXTRACT(MONTH FROM sending_date) as month,
        -- Estimate active list size (max sent in month)
        MAX(sent) as estimated_active_list_size,
        -- Campaign volume
        COUNT(DISTINCT campaign_id) as total_campaigns,
        SUM(sent) as total_emails_sent,
        -- Engagement metrics
        AVG(trackable_open_rate) * 100 as avg_open_rate_pct,
        AVG(unsubscription_rate) * 100 as avg_unsub_rate_pct,
        -- New user indicators
        SUM(CASE 
            WHEN audience_segment_a LIKE '%recent%' OR audience_segment_b LIKE '%recent%' 
            THEN sent ELSE 0 
        END) as estimated_new_users
    FROM records.email_campaigns
    GROUP BY year, month
)
SELECT 
    year,
    month,
    estimated_active_list_size,
    estimated_new_users,
    total_campaigns,
    avg_open_rate_pct,
    avg_unsub_rate_pct,
    -- Month-over-month growth
    estimated_active_list_size - LAG(estimated_active_list_size) OVER (ORDER BY year, month) as list_growth,
    -- Calculate net growth (new users - estimated churn)
    estimated_new_users - (estimated_active_list_size * (avg_unsub_rate_pct/100)) as net_growth_estimate,
    -- List health assessment
    CASE 
        WHEN estimated_active_list_size - LAG(estimated_active_list_size) OVER (ORDER BY year, month) > 0 
        AND avg_open_rate_pct > 15 THEN 'HEALTHY GROWTH'
        WHEN estimated_active_list_size - LAG(estimated_active_list_size) OVER (ORDER BY year, month) < 0 
        THEN 'LIST DECLINE'
        WHEN avg_open_rate_pct < 10 THEN 'ENGAGEMENT DECLINE'
        WHEN avg_unsub_rate_pct > 0.5 THEN 'HIGH CHURN'
        ELSE 'STABLE'
    END as list_health,
    -- Action required
    CASE 
        WHEN estimated_active_list_size - LAG(estimated_active_list_size) OVER (ORDER BY year, month) < -1000 
        THEN 'INVESTIGATE SIGNIFICANT LIST LOSS'
        WHEN avg_open_rate_pct < 10 THEN 'IMPLEMENT RE-ENGAGEMENT CAMPAIGN'
        WHEN avg_unsub_rate_pct > 0.5 THEN 'REVIEW FREQUENCY AND CONTENT'
        WHEN estimated_new_users < (estimated_active_list_size * 0.02) THEN 'INCREASE ACQUISITION EFFORTS'
        ELSE 'MONITOR'
    END as required_action
FROM monthly_list_metrics
ORDER BY year DESC, month DESC;