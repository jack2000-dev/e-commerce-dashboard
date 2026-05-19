# Lecture Notes
# Olist Analytics Engineering Workshop

Reference for concepts learned during the project build.

---

## 1. SQL Foundations

### DATE_TRUNC
Truncates a timestamp to a time unit. Returns a timestamp, not a string.

```sql
date_trunc('day', order_purchase_timestamp)   -- 2017-10-02 00:00:00
date_trunc('month', order_purchase_timestamp) -- 2017-10-01 00:00:00
```

Use when grouping time series data into days, weeks, or months.

### GROUP BY
Required whenever you use an aggregate function (COUNT, SUM, AVG, MAX, MIN).
The GROUP BY column must be every non-aggregated column in your SELECT.

```sql
select
    date_trunc('day', order_ts) as order_day,
    count(*) as order_count        -- aggregate
from orders
group by 1                         -- group by the first SELECT column
order by 1;
```

`GROUP BY 1` is shorthand for "group by the first column." Common in analytics SQL.

### COUNT vs COUNT DISTINCT
- `count(*)` — counts all rows including duplicates.
- `count(user_id)` — counts non-null values of user_id.
- `count(distinct user_id)` — counts unique users. **Use this for "how many users" questions.**

```sql
-- Wrong for "daily active users"
count(user_id) as daily_active_users

-- Correct
count(distinct user_id) as daily_active_users
```

### FILTER clause
Count different subsets in one query without multiple JOINs.

```sql
select
    date_trunc('day', order_purchase_timestamp) as order_day,
    count(*) filter (where order_purchase_timestamp is not null) as purchased,
    count(*) filter (where order_delivered_carrier_date is not null) as shipped,
    count(*) filter (where order_delivered_customer_date is not null) as delivered
from orders
group by 1;
```

### EXTRACT / EPOCH for durations
`DATE_PART('day', interval)` returns the integer day component only — misses hours.
Use EPOCH for fractional days:

```sql
extract(epoch from (end_ts - start_ts)) / 86400.0 as duration_days
-- 86400 seconds = 1 day
```

### COALESCE
Returns the first non-null value from a list. Use for null fallbacks.

```sql
coalesce(product_category_name_english, 'uncategorized')
```

### Grain Check
Verify that your assumed primary key is actually unique.
Returns zero rows if grain is valid.

```sql
select order_id, count(*) as n
from orders
group by order_id
having count(*) > 1;  -- zero rows = grain is valid
```

### Fan-out (Row Explosion)
When you JOIN a one-side table to a many-side table, rows multiply.

```
orders (1 row per order) JOIN order_items (3 rows per order)
= 3 result rows per order
```

This inflates COUNT results. Fix:
- Use COUNT DISTINCT on the one-side key.
- Aggregate the many-side table before joining.
- Be explicit about which grain your query is at.

---

## 2. Data Profiling

Profiling = observing data before modeling. Read-only. Never change raw data.

**Run before writing any models. Always.**

Standard profiling checklist per table:

| Check | Query shape |
|---|---|
| Row count | `SELECT COUNT(*)` |
| Grain verification | `GROUP BY pk HAVING COUNT(*) > 1` |
| Null check | `COUNT(*) FILTER (WHERE col IS NULL)` |
| Categorical values | `GROUP BY col ORDER BY count DESC` |
| Fan-out check | JOIN and compare `COUNT(DISTINCT key)` vs `COUNT(key)` |

**Key findings from Olist profiling:**
- `order_id` is unique in `orders` — grain confirmed.
- `order_items` grain is `order_id + order_item_id` — one order has many items.
- `order_payments` has up to 29 rows per order — always aggregate before joining.
- `customer_id` is order-scoped — repeat buyers get a new ID per order.
- 8 delivered orders have null `order_delivered_customer_date` — data anomaly.
- 610 products have null `product_category_name`.
- All timestamp columns stored as `text` after pgloader import — must cast in staging.

---

## 3. Medallion Architecture

Three layers: raw → staging → marts.

```
SQLite source
     ↓ pgloader
raw schema (Postgres)       ← immutable, never touch
     ↓ dbt staging models
staging schema              ← rename, cast, filter null PKs
     ↓ dbt mart models
marts schema                ← business logic, metrics, joins
     ↓
Metabase dashboard
```

### Raw
- Exact copy of source data.
- Never update, delete, or clean.
- Recovery source if downstream models break.
- In production: replaces source system snapshots.

### Staging
- One model per source table.
- Rename columns to snake_case.
- Cast types explicitly (especially timestamps).
- Filter rows where PK is null.
- No joins between tables.
- No aggregations.
- No business logic.
- Materialized as **views** (no storage, runs SQL on query).

### Marts
- Business logic lives here.
- Joins, aggregations, metric calculations.
- Fact tables and dimension tables.
- Aggregate snapshots for dashboards.
- Materialized as **tables** (stored physically, fast for dashboards).

---

## 4. Dimensional Modeling

### Fact Table
Captures events or measurements at a specific grain.

- One row per event (e.g., one row per order, one row per order+seller).
- Has foreign keys to dimension tables.
- Has additive measures (revenue, duration, 0/1 flags).
- Grain must be declared and enforced.

Example: `fct_order_fulfillment`
- Grain: one row per `order_id`
- Filter: `order_status = 'delivered'` only
- Measures: `fulfillment_days`, `approval_to_carrier_days`, `is_delivered_on_time`

### Dimension Table
Describes the entities referenced by fact tables.

- One row per entity (customer, seller, product).
- Has descriptive attributes (name, city, state, category).
- Joined to fact tables on foreign keys.

Example: `dim_customers`
- Grain: one row per `customer_id`
- Attributes: `customer_city`, `customer_state`

### Grain Declaration
Always state the grain before building a fact table:
*"This fact table is at `order_id` grain — one row per delivered order."*

If grain is composite: *"This fact table is at `order_id + seller_id` grain."*

### Constellation Schema
Multiple fact tables sharing the same dimension tables.
Your project: `fct_order_fulfillment` and `fct_seller_order_fulfillment` both reference `dim_sellers`.

---

## 5. Metric Definitions

Always define metrics precisely before building them.

| Metric | Formula | Filter | Grain |
|---|---|---|---|
| Fulfillment days | `delivered_date - purchase_ts` in days | `status = 'delivered'` + both timestamps not null | order |
| Approval to carrier days | `carrier_date - approved_at` in days | both timestamps not null | order |
| On-time delivery | `delivered_date <= estimated_date` → 1/0 | `status = 'delivered'` | order |
| Seller handoff on time | `carrier_date <= shipping_limit_date` → 1/0 | both timestamps not null | order + seller |
| Backlog | open orders not finished | status IN (created, approved, invoiced, processing, shipped) | order |
| At-risk backlog | open orders past estimate | backlog + `current_date > estimated_delivery_date` | order |

**Why exclude canceled orders from fulfillment metrics:**
Canceled orders never completed fulfillment. Including them makes the average meaningless — you can't measure how long something took if it never finished.

---

## 6. dbt

### Key Commands
```bash
dbt debug          # test connection
dbt run            # build all models
dbt test           # run all tests
dbt build          # run + test together
dbt run --select model_name          # run one model
dbt run --select "staging.*"         # run all models in staging/
```

### ref() and source()
- `{{ source('raw', 'orders') }}` — reference a raw source table (declared in sources.yml).
- `{{ ref('stg_orders') }}` — reference another dbt model. Always use ref() between models.

dbt builds a DAG (dependency graph) from these references. It runs models in the correct order automatically.

### Materialization
- `view` — SQL runs fresh on every query. No storage. Use for staging.
- `table` — results stored physically. Faster for dashboards. Use for marts.

### Model Structure (staging)
```sql
with source as (
    select * from {{ source('raw', 'table_name') }}
),

renamed as (
    select
        col_id,
        col_name,
        col_ts::timestamp as col_ts   -- explicit cast
    from source
    where col_id is not null          -- filter null PK
)

select * from renamed
```

### Model Structure (mart)
```sql
with orders as (
    select * from {{ ref('stg_orders') }}
),

final as (
    select
        order_id,
        -- business logic here
    from orders
    where order_status = 'delivered'
)

select * from final
```

### schema.yml Tests
Declared in `models/staging/schema.yml` or `models/marts/schema.yml`.

```yaml
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - not_null
          - unique
      - name: order_status
        tests:
          - accepted_values:
              values: ['delivered', 'shipped', 'canceled']
```

| Test | What it catches |
|---|---|
| `not_null` | Null values in a required column — broken joins, missing events |
| `unique` | Duplicate rows — grain violation, double-counting risk |
| `accepted_values` | Unexpected category values — new status added upstream without notice |

### Custom Tests
SQL files in `tests/`. Test passes if query returns **zero rows**.
Any rows returned = test failure.

```sql
-- tests/assert_fulfillment_days_nonnegative.sql
select order_id
from {{ ref('fct_order_fulfillment') }}
where fulfillment_days < 0
-- Zero rows = pass. Rows returned = delivered_date is before purchase_date = bad data.
```

---

## 7. Python and pytest

### pandas essentials
```python
import pandas as pd

df = pd.read_csv("file.csv")                          # load CSV
df.drop_duplicates()                                   # remove duplicate rows
df.to_csv("output.csv", index=False)                  # save CSV

# check for missing required columns
required = ["order_id", "customer_id"]
missing = [c for c in required if c not in df.columns]
if missing:
    raise ValueError(f"Missing columns: {missing}")
```

### psycopg2 — query Postgres from Python
```python
import psycopg2

conn = psycopg2.connect("postgresql://user@localhost:5432/dbname")
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM raw.orders")
count = cur.fetchone()[0]
conn.close()
```

### sqlite3 — query SQLite from Python
```python
import sqlite3

conn = sqlite3.connect("/path/to/file.sqlite")
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM orders")
count = cur.fetchone()[0]
conn.close()
```

### pytest basics
Any function starting with `test_` is picked up automatically.

```python
def test_row_counts_match():
    sqlite_count = ...   # query SQLite
    pg_count = ...       # query Postgres
    assert sqlite_count == pg_count
```

Run: `uv run pytest tests/ -v`

---

## 8. Data Quality Principles

**Categories vs specific checks:**

| Category | Specific check |
|---|---|
| Not null | `order_id IS NOT NULL` |
| Unique | `order_id` appears exactly once |
| Accepted values | `order_status IN ('delivered', 'shipped', ...)` |
| Referential integrity | Every `customer_id` in `orders` exists in `customers` |
| Nonnegative duration | `fulfillment_days >= 0` |
| Data freshness | Most recent `order_purchase_timestamp` within last N days |

Always state what bug each check catches, not just what it is.

---

## 9. Interview Talking Points

**Two-minute project pitch structure:**
1. Business problem and questions it answers.
2. Data source and how it was loaded.
3. Architecture (medallion: raw → staging → marts).
4. Key modeling decisions (grain, metric filters, dimension joins).
5. Testing and validation.
6. Dashboard and how it updates.
7. Limitations and what you'd improve.

**Common interview questions and answers:**

*Why use Postgres instead of querying SQLite directly?*
SQLite is a file-based DB with no concurrency, limited types, and no schema enforcement. Postgres supports multiple connections, proper types, schemas, and is standard for production analytics. Metabase connects natively to Postgres.

*Why never overwrite the raw schema?*
Raw is the source of truth. If a downstream model is wrong, you fix it in staging or marts — never in raw. Raw also enables full reload if anything breaks.

*What makes a good fact table?*
Clear grain declaration, foreign keys to dimensions, additive measures, correct filters for the metric being measured.

*Why is backlog modeled separately from fulfillment?*
Fulfillment time requires a completed delivery — you can only measure it for delivered orders. Backlog is open orders that haven't completed. They answer different questions and need different filters.

*What does your nonnegative duration test catch?*
It catches cases where `order_delivered_customer_date` is before `order_purchase_timestamp`. This would indicate corrupted source data — an impossible event in the real world.

---

## 10. Known Olist Schema Quirks

| Quirk | Impact |
|---|---|
| `customer_id` is order-scoped | Cannot analyze repeat purchase behavior |
| Timestamps stored as text after pgloader | Must cast in staging |
| Up to 29 payment rows per order | Always aggregate payments before joining to orders |
| 8 delivered orders with null `delivered_customer_date` | Excluded by null filter in fct_order_fulfillment |
| 610 products with null category | Handled with `coalesce(..., 'uncategorized')` in dim_products |
| Historical dataset only | `is_at_risk` flags all backlog as at-risk when `CURRENT_DATE` is used |
