# DataAnalytics-Assessment

This repository contains my detailed solutions to the o the SQL Proficiency Assessment focused on transactional and customer data. The questions cover business scenarios such as customer segmentation, account activity tracking, and identify customers for cross-selling opportunity. This README outlines my approach for each question and reflects my problem-solving logic. It also highlights key challenges I encountered while writing the queries.

## Data Dictionary

### users_customuser: : customer demographic and contact information
- **id**: primary key for customer  
- first_name, last_name…  

### savings_savingsaccount:  records of deposit transactions
- **owner_id** → users_customuser.id  
- **confirmed_amount** (in kobo), transaction_date…  

### plans_plan: records of plans created by customers
- **owner_id**, **is_regular_savings**, **is_a_fund**, start_date…  

### withdrawals_withdrawal: records of withdrawal transactions
- **owner_id**, **amount_withdrawn**, **transaction_date**, **plan_id**…

## Assessment Hints

- `owner_id` is a foreign key to `users_customuser.id`  
- `plan_id` is a foreign key to `plans_plan.id`  
- For savings plans, filter where `is_regular_savings = 1`  
- For investment plans, filter where `is_a_fund = 1`  
- Use `confirmed_amount` for inflows; `amount_withdrawn` for outflows  
- All amount fields are stored in kobo (100 kobo = 1 NGN)

---

## Table of Contents

1. [Question 1: High-Value Customers with Multiple Products](#question-1-high-value-customers-with-multiple-products)
2. [Question 2: Transaction Frequency Segmentation](#question-2-transaction-frequency-segmentation)
3. [Question 3: Account Inactivity Alert](#question-3-account-inactivity-alert)
4. [Question 4: Customer Lifetime Value (CLV) Estimation](#question-4-customer-lifetime-value-clv-estimation)
5. [Challenges Encountered](#challenges-encountered)

---

## Question 1: High-Value Customers with Multiple Products

**Objective**: Identify customers who own both a savings and an investment plan, and Sort them by the total value of confirmed deposits.

**Approach**:

* Aggregated product types per customer using conditional sums to count how many savings (`is_regular_savings = 1`) and investment (`is_a_fund = 1`) plans they had.
* Filtered to retain only customers with at least one of each product type.
* Computed the total value of confirmed transactions (converted from kobo to naira) grouped by customer.
* Joined the results with the customer table to display names and sorted by total deposit value.

**Business Relevance**:
This query helps the business identify financially engaged customers with at least one funded savings plan AND one funded investment plan. ideal candidates for cross-selling opportunity.

[SQL Solution Script](./Assessment_Q1.sql)

---

## Question 2: Transaction Frequency Segmentation

**Objective**: Determine transaction frequency per customer, group customers into usage segments, and count the number in each group.

**Approach**:

* Calculated each customer’s transaction span by subtracting the first transaction date from the last.
* Divided total transactions by active months (approximated by `DATEDIFF/30.0`) to get average monthly frequency.
* Used `GREATEST(..., 1)` to ensure the denominator never drops to zero, this make sure it never divide by zero or a very small number, so the results don’t become too large or misleading.
* Segmented customers into `Low`, `Medium`, and `High` bands using a `CASE` statement.
* Aggregated and sorted the segment counts for summary reporting.

**Business Relevance**:
Segmentation like this helps track engagement such as frequent vs. occasional users and can inform strategies for upselling or retention.

[SQL Solution Script](./Assessment_Q2.sql)

---

## Question 3: Account Inactivity Alert

**Objective**: Identify funded plans that have not received a deposit in the last 12 months.

**Approach**:

* Retrieved the most recent deposit per plan using aggregation.
* Joined with the plans table and filtered to include only active, non-archived, and funded plans.
* Used `CURDATE()` to dynamically compare against a 12-month interval (`CURDATE() - INTERVAL 365 DAY`).
* Classified plans into "Savings" or "Investment" using conditional logic.
* Sorted results by inactivity duration to highlight dormant plans.

**Business Relevance**:
This type of query supports customer reactivation strategies and helps maintain account health metrics.

[SQL Solution Script](./Assessment_Q3.sql)

---

## Question 4: Customer Lifetime Value (CLV) Estimation

**Objective**: Estimate customer lifetime value using tenure and average transaction profit.

**Approach**:

* Calculated customer tenure in months as `DATEDIFF(CURDATE(), created_on)/30.0`.
* Used `GREATEST(..., 1)` to prevent zero-month tenure from skewing the calculation.
* Computed average transaction value and applied a profit margin (e.g., 0.1%) to estimate per-transaction profit.
* Applied the formula:

  `(transactions_per_month) * 12 * avg_profit_per_transaction`

  This estimates annualized profit from each customer.
* Final results were rounded and sorted to show highest CLV customers first.

**Business Relevance**:
CLV is crucial for understanding customer profitability and making informed marketing and retention investments.

[SQL Solution Script](./Assessment_Q4.sql)

---

## Challenges Encountered

### 1. Handling Division by Zero in Time-Based Metrics

When calculating metrics such as tenure and activity span (used in CLV or transaction frequency), customers with minimal or same-day activity could result in division by zero. To address this, I used:

```sql
GREATEST(DATEDIFF(...)/30.0, 1)
```

This enforced a lower bound of one month for meaningful averaging.

### 2. Time Logic with `CURDATE()`

Using `CURDATE()` enabled dynamic, date-relative logic for detecting inactive accounts and calculating tenure. Example usage:

```sql
WHERE last_deposit_date < CURDATE() - INTERVAL 365 DAY
```
### 3. Rewrinting Joins into CTEs for Better Performance and Clarity

Initially, I built my queries using deeply nested joins with `WHERE` filters applied directly. This approach resulted in long compilation times and made the logic hard to follow. As the queries got more complex, especially with multiple joins, it became difficult to read and tune. The database optimizer also struggled to produce efficient execution and keeps disconnecting to the mySQL server. To solve this, I rewrite each query into well-named CTEs that isolate logical steps one at a time, such as plan counting, deposit summation, and customer filtering. This made the queries easier to manage and more aligned with the business logic and process.
This change really helped me in a few ways. First, it improved performance because breaking the query into smaller, clear steps allowed the optimizer to create better execution plans, which made everything run faster. It also made the code easier to understand and maintain, since each CTE works like its own block that follows the business process. for example, starting with identifying plans, then calculating totals, and finally applying the rules. Lastly, it became easier to update or add new things later, like more filters or calculations, without needing to rewrite the whole query.

This ensures queries remain future-proof
