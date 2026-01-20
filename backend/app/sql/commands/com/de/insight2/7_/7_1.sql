-- Estimate new registrations from recent registration segments
SELECT 
    EXTRACT(YEAR FROM sending_date) as year,
    EXTRACT(MONTH FROM sending_date) as month,
    COUNT(DISTINCT campaign_id) as campaigns_with_new_users,
    SUM(sent) as estimated_new_users_reached,
    AVG(sent) as avg_campaign_size_to_new_users,
    -- Calculate monthly registration estimate
    SUM(sent) / COUNT(DISTINCT campaign_id) as estimated_monthly_registrations
FROM records.email_campaigns ec
WHERE (
    audience_segment_a LIKE '%recent registration%' 
    OR audience_segment_a LIKE '%new registration%'
    OR audience_segment_b LIKE '%recent registration%'
    OR audience_segment_b LIKE '%new registration%'
    OR EXISTS (
        SELECT 1 
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids) seg
        WHERE seg IN ('150', '96', '97') -- Example new user segments from sample data
    )
    OR EXISTS (
        SELECT 1 
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids) seg
        WHERE seg IN ('150', '96', '97')
    )
)
GROUP BY year, month
ORDER BY year DESC, month DESC;