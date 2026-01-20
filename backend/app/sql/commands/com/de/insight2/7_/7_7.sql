-- Simple comprehensive lifecycle analysis
SELECT 
    -- List size metrics
    MAX(sent) as estimated_total_list,
    AVG(sent) as avg_campaign_size,
    -- Engagement metrics
    AVG(trackable_open_rate) * 100 as overall_open_rate_pct,
    AVG(unsubscription_rate) * 100 as overall_unsub_rate_pct,
    -- Growth estimation
    COUNT(DISTINCT CASE 
        WHEN audience_segment_a LIKE '%new%' OR audience_segment_b LIKE '%new%' 
        THEN campaign_id 
    END) as campaigns_to_new_users,
    -- List health assessment
    CASE 
        WHEN AVG(trackable_open_rate) * 100 > 20 THEN 'HEALTHY: Good engagement'
        WHEN AVG(trackable_open_rate) * 100 > 15 THEN 'MODERATE: Acceptable engagement'
        WHEN AVG(trackable_open_rate) * 100 > 10 THEN 'WARNING: Low engagement'
        ELSE 'CRITICAL: Very low engagement'
    END as overall_health,
    -- Suppression rules needed
    CASE 
        WHEN AVG(unsubscription_rate) * 100 > 0.5 THEN 'YES: High unsubscribe rate'
        WHEN AVG(trackable_open_rate) * 100 < 15 THEN 'YES: Low engagement'
        WHEN COUNT(DISTINCT CASE 
            WHEN audience_segment_a LIKE '%inactive%' OR audience_segment_b LIKE '%inactive%' 
            THEN campaign_id 
        END) = 0 THEN 'YES: No inactive user suppression'
        ELSE 'NO: Current rules adequate'
    END as needs_better_suppression,
    -- Cooldown recommendations
    CASE 
        WHEN AVG(trackable_open_rate) * 100 < 15 THEN 'Implement 7-day cooldown after non-opens'
        WHEN AVG(unsubscription_rate) * 100 > 0.3 THEN 'Implement 14-day cooldown after unsubscribes'
        ELSE 'Current frequency acceptable'
    END as cooldown_recommendation
FROM records.email_campaigns;