/*
Estimate customer CLV = (transc/tenure)*12*avg_profit, where profit = 0.1% of transaction value.
the query below get costumer tenure in months and ensure minimum of 1 month to avoid division errors
*/
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

/*
the query below get the costumers total transactions, and evaluate the average transaction value by converting to naira 
and calculate profit_per_transaction that is 0.1% of the transaction value 
*/
transaction_metrics AS (
    SELECT
        owner_id AS customer_id,
        COUNT(*) AS total_transactions,
        -- Convert kobo to NGN, then apply 0.1% profit rate
        AVG(confirmed_amount) / 100.0 * 0.001  AS avg_profit_per_transaction
    FROM savings_savingsaccount
    GROUP BY owner_id
)

/*
This query below get all the content from previous CTEs and outputs costumers name, tenure months, 
Estimated Customer Livetime Value
*/
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
