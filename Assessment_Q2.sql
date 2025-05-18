WITH transactions AS (
    SELECT
        owner_id AS customer_id,
        COUNT(*) AS total_transactions,
        MIN(transaction_date) AS first_transc_date,
        MAX(transaction_date) AS last_transc_date
    FROM savings_savingsaccount
    GROUP BY owner_id
),

frequency AS (
    SELECT
        t.customer_id,
        total_transactions,
        GREATEST(DATEDIFF(last_transc_date, first_transc_date) / 30.0, 1) AS active_months,
        -- Calculate average monthly transaction rate
        total_transactions / GREATEST(DATEDIFF(last_transc_date, first_transc_date) / 30.0, 1) AS avg_transc_per_month
    FROM transactions t
),

category AS (
    SELECT
        f.customer_id,
        f.avg_transc_per_month,
        CASE
            WHEN avg_transc_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transc_per_month >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM frequency f
)

SELECT
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transc_per_month), 2) AS avg_transactions_per_month
FROM category
GROUP BY frequency_category
ORDER BY
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        ELSE 3
    END;
