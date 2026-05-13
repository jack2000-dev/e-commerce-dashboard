# Before Assessment

Answer these before starting the project. The AI mentor should review your
answers, identify gaps, and tune the project difficulty.

## 1. SQL

Given a table named `orders`:

| column | type |
| --- | --- |
| order_id | integer |
| customer_id | integer |
| order_ts | timestamp |
| order_status | text |
| revenue | numeric |

Write a query that returns daily completed revenue and completed order count.

## 2. SQL Debugging

This query is returning duplicate customer rows. Explain why that might happen
and how you would investigate it.

```sql
select
  c.customer_id,
  c.email,
  o.order_id,
  o.revenue
from customers c
left join orders o
  on c.customer_id = o.customer_id;
```

## 3. Python

Write Python pseudocode or real code to:

- Load a CSV file.
- Check for missing required columns.
- Remove duplicate rows.
- Save a cleaned output file.

## 4. Data Quality

Name five data quality checks you would add to a pipeline that processes orders.

## 5. Role-Specific Question

Choose one:

- Data engineer: How would you make a daily ingestion pipeline reliable?
- Analytics engineer: What makes a good fact table?
- Technical data analyst: How would you validate that a metric is trustworthy?

## 6. Explanation

Explain one data project you have built or would like to build. Include:

- Problem
- Input data
- Transformation logic
- Output
- How you would test it
- How you would explain it to an interviewer

