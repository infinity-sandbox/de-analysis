-- Check if segments are used alone or with others
WITH campaign_segment_counts AS (
    SELECT 
        ec.campaign_id,
        ec.sending_date,
        COUNT(DISTINCT seg.value::integer) as total_segments_in_campaign
    FROM records.email_campaigns ec
    CROSS JOIN LATERAL (
        SELECT value
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
        WHERE ec.audience_segment_a_ids IS NOT NULL 
          AND ec.audience_segment_a_ids != '[]'::jsonb
        UNION ALL
        SELECT value
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
        WHERE ec.audience_segment_b_ids IS NOT NULL 
          AND ec.audience_segment_b_ids != '[]'::jsonb
    ) seg
    WHERE seg.value ~ '^\d+$'
    GROUP BY ec.campaign_id, ec.sending_date
),
segment_usage_type AS (
    SELECT 
        seg.value::integer as segment_id,
        s.segment_name,
        ec.campaign_id,
        ec.sending_date,
        csc.total_segments_in_campaign
    FROM records.email_campaigns ec
    CROSS JOIN LATERAL (
        SELECT value
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
        WHERE ec.audience_segment_a_ids IS NOT NULL 
          AND ec.audience_segment_a_ids != '[]'::jsonb
        UNION ALL
        SELECT value
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
        WHERE ec.audience_segment_b_ids IS NOT NULL 
          AND ec.audience_segment_b_ids != '[]'::jsonb
    ) seg
    JOIN records.segments s ON seg.value::integer = s.segment_id
    JOIN campaign_segment_counts csc ON ec.campaign_id = csc.campaign_id
    WHERE seg.value ~ '^\d+$'
)
SELECT 
    segment_id,
    segment_name,
    COUNT(DISTINCT campaign_id) as total_campaigns,
    COUNT(DISTINCT CASE WHEN total_segments_in_campaign = 1 THEN campaign_id END) as campaigns_alone,
    COUNT(DISTINCT CASE WHEN total_segments_in_campaign > 1 THEN campaign_id END) as campaigns_combined,
    -- Percentage used alone
    ROUND(
        COUNT(DISTINCT CASE WHEN total_segments_in_campaign = 1 THEN campaign_id END)::decimal / 
        NULLIF(COUNT(DISTINCT campaign_id), 0) * 100, 
        2
    ) as percent_used_alone
FROM segment_usage_type
GROUP BY segment_id, segment_name
ORDER BY total_campaigns DESC;