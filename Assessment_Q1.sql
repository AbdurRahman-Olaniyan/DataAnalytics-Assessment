/*
This query find customers who own at least one savings plan and one investment plan, then sort them by their total confirmed deposit value.
*/
WITH plan_counts AS (
    SELECT
        owner_id,
        -- Count of savings plans where is_regular_savings = 1
        SUM(CASE WHEN is_regular_savings = 1 THEN 1 ELSE 0 END) AS savings_count,
        -- Count of investment plans where is_a_fund = 1
        SUM(CASE WHEN is_a_fund = 1 THEN 1 ELSE 0 END)   AS investment_count
    FROM plans_plan
    GROUP BY owner_id
),
savings_amount AS (
    SELECT
        owner_id,
        -- Sum confirmed deposits, converting from kobo to NGN to 2 dp.
        ROUND(SUM(confirmed_amount) / 100, 2) AS total_deposits
    FROM savings_savingsaccount
    GROUP BY owner_id
)
 -- this query below join the 2 CTE to get customer id (owner_id), name, number of savings and invesment plan that are at least greater than 1    
SELECT
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    p.savings_count AS savings_count,
    p.investment_count AS investment_count,
    s.total_deposits AS total_deposits
FROM plan_counts p
JOIN savings_amount s
  ON p.owner_id = s.owner_id
JOIN users_customuser u
  ON u.id = p.owner_id
-- only users with savings plan AND investment plan greathen or equal to 1
WHERE p.savings_count >= 1
  AND p.investment_count >= 1
ORDER BY s.total_deposits DESC;
