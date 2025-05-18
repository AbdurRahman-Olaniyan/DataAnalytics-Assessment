-- find the date of its most recent deposit for each plan,
WITH last_deposit AS (
    SELECT
        plan_id,
        MAX(transaction_date) AS last_deposit_date
    FROM savings_savingsaccount
    GROUP BY plan_id
),

-- Flag inactive plans based on a 365-day threshold
 inactive_plans AS (
    SELECT
        p.id AS plan_id,
        p.owner_id AS owner_id,
        -- custom column for  plan type
        CASE
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund           = 1 THEN 'Investment'
            ELSE 'Other'
        END AS type,
        ls.last_deposit_date   AS last_transaction_date,
        -- Days since last deposit
        DATEDIFF(
            CURDATE(),
            ls.last_deposit_date
        ) AS inactivity_days
    FROM plans_plan p
    JOIN last_deposit ls
      ON p.id = ls.plan_id
    WHERE
      -- Only include active plans
      p.is_deleted  = 0
      AND p.is_archived = 0
      -- No deposits in the past 365 days
      AND ls.last_deposit_date < DATE_SUB(CURDATE(), INTERVAL 365 DAY)
)

-- Final output, ordered by longest inactivity
SELECT
    plan_id,
    owner_id,
    type,
    last_transaction_date,
    inactivity_days
FROM inactive_plans
ORDER BY inactivity_days DESC;
