# Milestones

Learner baseline: SQL filtering/SUM known, GROUP BY/DATE_TRUNC gaps, pandas surface-level,
DQ categories not specifics, fact table concept gap, strong domain understanding.

---

## Milestone 1: Environment and Data Load

### Goal

Get Postgres running locally, load all Olist SQLite tables into the `raw` schema,
write a pytest-covered load script.

### Deliverables

- `docker-compose.yml` with Postgres and Metabase services.
- `uv`-initialized Python project with dependencies pinned.
- `scripts/load_sqlite_to_postgres.py`:
  - Reads each Olist table from `data/raw/olist.sqlite`.
  - Loads into Postgres `raw` schema, one table per source table.
  - Accepts a `--batch-date` argument for simulated batch loading later.
- `tests/test_load.py` with at least two pytest assertions:
  - Raw table exists after load.
  - Row count in Postgres matches row count in SQLite.
- `data/raw/olist.sqlite` confirmed present.

### SQL Warm-Up (do this before the load script)

Run these queries directly against `olist.sqlite` using DuckDB CLI or DataGrip
to practice before writing dbt models:

```sql
-- 1. Count rows per table. No GROUP BY needed here, just warm up.
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

-- 2. Daily order count using DATE_TRUNC (Postgres syntax).
-- Practice: what does DATE_TRUNC('day', order_purchase_timestamp) return?
SELECT
    DATE_TRUNC('day', order_purchase_timestamp) AS order_day,
    COUNT(*) AS order_count
FROM orders
GROUP BY 1
ORDER BY 1;

-- 3. Verify orders grain. Should return zero if grain is truly one row per order_id.
SELECT order_id, COUNT(*) AS n
FROM orders
GROUP BY order_id
HAVING n > 1;

-- 4. Verify order_items grain (order_id + order_item_id).
SELECT order_id, order_item_id, COUNT(*) AS n
FROM order_items
GROUP BY 1, 2
HAVING n > 1;
```

### Review Questions

1. Why do we load raw data into Postgres instead of querying the SQLite file directly?
2. What does `--batch-date` enable later in the project?
3. What happens to the row count test if you run the load script twice?

---

## Milestone 2: Source Profiling

### Goal

Understand the Olist data before modeling it. Identify nulls, status values,
join risks, and date gaps. Write profiling notes you can reference in interviews.

### Deliverables

- `profiling/source_profile.md` with notes for each core table.
- SQL profiling queries saved in `profiling/queries/` (one file per table).
- Documented answers to all review questions.

### Required Profiling Queries

For each table, answer:

- How many rows?
- What is the grain (what column or combination is unique)?
- Which columns have nulls, and how many?
- For `orders`: what are the distinct `order_status` values and counts?
- For `orders`: which timestamp columns have nulls, and for which statuses?
- For `order_items`: does joining to `orders` on `order_id` multiply rows? By how much?
- For `order_payments`: does an order ever have more than one payment row?

### Review Questions

1. If you join `orders` to `order_items` on `order_id`, what happens to the row count?
   Why is that a problem for fulfillment-time metrics?
2. Which `order_status` values should be excluded from fulfillment-time calculations?
   Why?
3. Why should you never clean or overwrite the `raw` schema tables?

---

## Milestone 3: dbt Staging Models

### Goal

Build clean, typed, renamed staging models on top of raw tables. No business logic yet.
Staging = rename, cast, filter out clearly invalid rows.

### Deliverables

- dbt project initialized (`dbt init`) with `dbt-postgres` profile configured.
- Staging models in `models/staging/`:
  - `stg_orders.sql`
  - `stg_order_items.sql`
  - `stg_customers.sql`
  - `stg_sellers.sql`
  - `stg_products.sql`
  - `stg_order_payments.sql`
- `models/staging/schema.yml` with:
  - `not_null` test on every primary key column.
  - `unique` test on every primary key column.
  - `accepted_values` test on `order_status`.
- `dbt build` passes with zero test failures.

### Staging Rules

- Cast all timestamp columns to `TIMESTAMP` explicitly.
- Rename columns to snake_case if not already.
- Do not aggregate. Do not join tables. Do not filter on business logic.
- Do filter: remove rows where the primary key is null.

### Concept Check (answer before submitting)

What is the difference between a staging model and a mart model?
What belongs in staging versus what belongs in a fact table?

### Review Questions

1. Why cast timestamps explicitly in staging rather than relying on the raw type?
2. Why is `accepted_values` for `order_status` a useful test here?
3. A teammate adds a new `order_status = 'returned'` to production.
   Your `accepted_values` test fails. Is that a good thing or a bad thing?

---

## Milestone 4: dbt Mart Models and Data Quality

### Goal

Build mart models with business logic: fact tables, dimension tables, and
daily aggregate snapshots. Add specific data quality checks.

### Deliverables

- Mart models in `models/marts/`:
  - `fct_order_fulfillment.sql` — grain: one row per `order_id`.
  - `fct_seller_order_fulfillment.sql` — grain: one row per `order_id + seller_id`.
  - `dim_customers.sql`
  - `dim_sellers.sql`
  - `dim_products.sql`
  - `daily_operations_metrics.sql` — grain: one row per `order_day`.
  - `daily_backlog_snapshot.sql` — grain: one row per `order_id` for open orders.
- `models/marts/schema.yml` with:
  - `unique` + `not_null` on every fact table primary key.
  - Custom test: `fulfillment_days >= 0` on `fct_order_fulfillment`.
  - Custom test: `seller_handoff_days >= 0` on `fct_seller_order_fulfillment`.
- SQL validation query in `profiling/queries/validate_fct_order_fulfillment.sql`
  that reconciles total delivered order count from `stg_orders` against `fct_order_fulfillment`.
- `dbt build` passes with zero test failures.

### Metric Logic to Implement

| Metric | Formula | Grain | Filter |
|---|---|---|---|
| Fulfillment days | `order_delivered_customer_date - order_purchase_timestamp` | order | `order_status = 'delivered'` only |
| Approval-to-carrier days | `order_delivered_carrier_date - order_approved_at` | order | both timestamps not null |
| Delivered on time | `order_delivered_customer_date <= order_estimated_delivery_date` | order | `order_status = 'delivered'` only |
| Seller handoff on time | `order_delivered_carrier_date <= shipping_limit_date` | order + seller | both timestamps not null |
| Backlog | open orders not yet delivered or canceled | order | statuses: created, approved, invoiced, processing, shipped |
| At-risk backlog | open orders past estimated delivery | order | same as backlog + `batch_date > order_estimated_delivery_date` |

### Concept Check (answer before submitting)

What is the grain of `fct_order_fulfillment`? What makes a grain declaration meaningful?
Why is it wrong to include `canceled` orders in fulfillment-time averages?

### Review Questions

1. You aggregate `fct_order_fulfillment` to get average fulfillment time per day.
   The number looks wrong. What are three things you would check first?
2. Why is `daily_backlog_snapshot` modeled separately from `fct_order_fulfillment`?
3. Why do the nonnegative duration tests matter? What real data problem would trigger them?

---

## Milestone 5: Metabase Dashboard, Batch Simulation, and Interview Prep

### Goal

Connect Metabase to your mart tables. Build the operations dashboard.
Simulate a live-update by loading one extra batch of orders and refreshing.
Write interview-ready explanations.

### Deliverables

- Metabase running via Docker Compose, connected to Postgres.
- Dashboard: **Olist Operations Intelligence** with five sections:
  - Operations overview (daily purchased / shipped / delivered order counts).
  - Fulfillment performance (average fulfillment days over time).
  - SLA monitoring (on-time delivery %, seller handoff SLA %).
  - Backlog monitoring (total backlog count, at-risk backlog count).
  - Regional breakdown (delays by customer state or seller state).
- `scripts/simulate_batch.py`:
  - Accepts `--batch-date`.
  - Loads orders up to that date into Postgres.
  - Triggers `dbt run` after load.
- `README.md` with:
  - Setup steps from clone to running dashboard.
  - Architecture diagram or text description.
  - Known limitations.
- `docs/interview_notes.md` with talking points for:
  - Why SQLite → Postgres instead of querying SQLite directly.
  - Why raw schema is never overwritten.
  - How staging differs from marts.
  - How fact table grain was chosen.
  - How backlog is defined and why it is separate from fulfillment metrics.
  - What you would improve in v0.2.

### Review Questions (final)

1. Explain the full data flow in two minutes: from SQLite file to Metabase tile.
2. A stakeholder says the on-time delivery % looks too high. How do you investigate?
3. What would break if someone ran the load script twice on the same date?
4. What is one thing you would change about your dbt model design in hindsight?
