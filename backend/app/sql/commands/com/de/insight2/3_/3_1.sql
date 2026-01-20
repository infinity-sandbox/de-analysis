-- Detect unexpected volume drops/spikes and logic changes
WITH segment_monthly_volume AS (
    SELECT 
        seg.segment_id,
        s.segment_name,
        EXTRACT(YEAR FROM ec.sending_date) AS year,
        EXTRACT(MONTH FROM ec.sending_date) AS month,
        -- Get sent volume for campaigns where segment used alone
        AVG(CASE 
            WHEN NOT EXISTS (
                SELECT 1 
                FROM (
                    SELECT value::integer AS other_segment_id
                    FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
                    WHERE ec.audience_segment_a_ids IS NOT NULL 
                      AND ec.audience_segment_a_ids != '[]'::jsonb
                      AND value ~ '^\d+$'
                    UNION ALL
                    SELECT value::integer AS other_segment_id
                    FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
                    WHERE ec.audience_segment_b_ids IS NOT NULL 
                      AND ec.audience_segment_b_ids != '[]'::jsonb
                      AND value ~ '^\d+$'
                ) all_segments
                WHERE other_segment_id != seg.segment_id
            ) THEN ec.sent
        END) AS avg_size_alone,
        COUNT(CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM (
                    SELECT value::integer AS other_segment_id
                    FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
                    WHERE ec.audience_segment_a_ids IS NOT NULL 
                      AND ec.audience_segment_a_ids != '[]'::jsonb
                      AND value ~ '^\d+$'
                    UNION ALL
                    SELECT value::integer AS other_segment_id
                    FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
                    WHERE ec.audience_segment_b_ids IS NOT NULL 
                      AND ec.audience_segment_b_ids != '[]'::jsonb
                      AND value ~ '^\d+$'
                ) all_segments
                WHERE other_segment_id != seg.segment_id
            ) THEN 1 
        END) AS campaigns_alone_count
    FROM records.email_campaigns ec
    CROSS JOIN LATERAL (
        SELECT value::integer AS segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_a_ids)
        WHERE ec.audience_segment_a_ids IS NOT NULL 
          AND ec.audience_segment_a_ids != '[]'::jsonb
          AND value ~ '^\d+$'
        UNION ALL
        SELECT value::integer AS segment_id
        FROM jsonb_array_elements_text(ec.audience_segment_b_ids)
        WHERE ec.audience_segment_b_ids IS NOT NULL 
          AND ec.audience_segment_b_ids != '[]'::jsonb
          AND value ~ '^\d+$'
    ) seg
    JOIN records.segments s ON seg.segment_id = s.segment_id
    GROUP BY seg.segment_id, s.segment_name, year, month
),
volume_changes AS (
    SELECT 
        segment_id,
        segment_name,
        year,
        month,
        avg_size_alone,
        campaigns_alone_count,
        LAG(avg_size_alone) OVER (PARTITION BY segment_id ORDER BY year, month) AS prev_avg_size,
        LAG(campaigns_alone_count) OVER (PARTITION BY segment_id ORDER BY year, month) AS prev_campaigns_count,
        -- Calculate 3-month moving average for trend
        AVG(avg_size_alone) OVER (
            PARTITION BY segment_id 
            ORDER BY year, month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3month
    FROM segment_monthly_volume
)
SELECT 
    segment_id,
    segment_name,
    year,
    month,
    ROUND(avg_size_alone) AS current_volume,
    ROUND(prev_avg_size) AS previous_volume,
    ROUND(moving_avg_3month) AS trend_volume,
    campaigns_alone_count,
    -- Detect significant changes (>25%)
    CASE 
        WHEN prev_avg_size > 0 
        AND ABS(avg_size_alone - prev_avg_size) / prev_avg_size > 0.25 
        AND campaigns_alone_count >= 2 
        AND prev_campaigns_count >= 2
        THEN 'SIGNIFICANT_CHANGE_DETECTED'
        WHEN prev_avg_size > 0 
        AND ABS(avg_size_alone - moving_avg_3month) / moving_avg_3month > 0.3
        THEN 'DEVIATION_FROM_TREND'
        ELSE 'STABLE'
    END AS change_status,
    -- Change details
    CASE 
        WHEN prev_avg_size > 0 
        THEN ROUND((avg_size_alone - prev_avg_size) / prev_avg_size * 100, 2)
        ELSE NULL
    END AS percent_change,
    -- Alert for investigation
    CASE 
        WHEN prev_avg_size > 0 
        AND avg_size_alone < prev_avg_size * 0.7 
        AND campaigns_alone_count >= 2
        THEN 'INVESTIGATE: Possible segment logic change or decay'
        WHEN prev_avg_size > 0 
        AND avg_size_alone > prev_avg_size * 1.5 
        AND campaigns_alone_count >= 2
        THEN 'INVESTIGATE: Unexpected growth or list addition'
        WHEN campaigns_alone_count = 0 AND prev_campaigns_count > 0
        THEN 'ALERT: Segment no longer used alone'
        ELSE 'No action required'
    END AS investigation_required
FROM volume_changes
WHERE avg_size_alone IS NOT NULL
ORDER BY 
    CASE 
        WHEN prev_avg_size > 0 
        AND ABS(avg_size_alone - prev_avg_size) / prev_avg_size > 0.25 
        THEN 1 
        ELSE 2 
    END,
    segment_id, 
    year DESC, 
    month DESC;