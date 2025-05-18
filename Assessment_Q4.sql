WITH customer_tenure AS (
    SELECT
        id AS customer_id,
        CONCAT(first_name, ' ', last_name) AS name,
        -- Tenure in months (at least 1 to avoid zero division)
        GREATEST(
          DATEDIFF(CURDATE(), created_on) / 30.0,
          1
        ) AS tenure_months
    FROM users_customuser
),

transaction_metrics AS (
    SELECT
        owner_id AS customer_id,
        COUNT(*) AS total_transactions,
        -- Convert kobo to NGN, then apply 0.1% profit rate
        AVG(confirmed_amount) / 100.0 * 0.001  AS avg_profit_per_transaction
    FROM savings_savingsaccount
    GROUP BY owner_id
)

SELECT
    ct.customer_id,
    ct.name,
    ROUND(ct.tenure_months) AS tenure_months,
    tm.total_transactions,
    -- CLV = (total_txns / tenure_months) * 12 * avg_profit_per_txn
    ROUND(
      (tm.total_transactions / ct.tenure_months) * 12
      * tm.avg_profit_per_transaction,
      2
    ) AS estimated_clv
FROM customer_tenure ct
JOIN transaction_metrics tm
  ON ct.customer_id = tm.customer_id
ORDER BY estimated_clv DESC;
