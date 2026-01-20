-- Estimate realistic usable list size
WITH monthly_active_estimation AS (
    SELECT 
        EXTRACT(YEAR FROM sending_date) as year,
        EXTRACT(MONTH FROM sending_date) as month,
        -- Different estimation methods
        MAX(sent) as max_campaign_size,
        AVG(sent) as avg_campaign_size,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sent) as p75_campaign_size,
        -- High engagement campaigns only
        AVG(CASE WHEN trackable_open_rate > 0.15 THEN sent END) as avg_engaged_campaign_size,
        -- New vs existing users
        SUM(CASE 
            WHEN audience_segment_a LIKE '%new%' OR audience_segment_b LIKE '%new%' 
            THEN sent ELSE 0 
        END) as new_user_volume
    FROM records.email_campaigns
    GROUP BY year, month
)
SELECT 
    year,
    month,
    max_campaign_size as estimated_total_list,
    avg_engaged_campaign_size as estimated_engaged_list,
    new_user_volume,
    -- Calculate usable list (engaged + new)
    COALESCE(avg_engaged_campaign_size, 0) + COALESCE(new_user_volume, 0) as estimated_usable_list,
    -- List utilization percentage
    CASE 
        WHEN max_campaign_size > 0 
        THEN ((COALESCE(avg_engaged_campaign_size, 0) + COALESCE(new_user_volume, 0)) / max_campaign_size * 100)
        ELSE 0 
    END as list_utilization_pct,
    -- Reality check
    CASE 
        WHEN max_campaign_size > 50000 THEN 'Large list (>50K)'
        WHEN max_campaign_size > 20000 THEN 'Medium list (20-50K)'
        WHEN max_campaign_size > 5000 THEN 'Small list (5-20K)'
        ELSE 'Very small list (<5K)'
    END as list_size_category,
    -- Growth/decline trend
    max_campaign_size - LAG(max_campaign_size) OVER (ORDER BY year, month) as monthly_growth,
    -- Action required
    CASE 
        WHEN ((COALESCE(avg_engaged_campaign_size, 0) + COALESCE(new_user_volume, 0)) / max_campaign_size * 100) < 50 
        THEN 'Focus on re-engagement: Over 50% list inactive'
        WHEN new_user_volume < (max_campaign_size * 0.05) 
        THEN 'Increase acquisition: New users <5% of list'
        WHEN max_campaign_size - LAG(max_campaign_size) OVER (ORDER BY year, month) < -1000 
        THEN 'Investigate list decline'
        ELSE 'List health acceptable'
    END as list_management_action
FROM monthly_active_estimation
ORDER BY year DESC, month DESC;