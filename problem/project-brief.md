# Project Brief

## Project Name

Olist Logistics Operations Intelligence Dashboard

## Target Role

Primary target: Analytics Engineer

Secondary focus: Data Intelligence / Technical Data Analyst for a logistics
e-commerce company

## Difficulty

Intermediate, balanced path

## Scenario

You are working as a data intelligence analyst / analytics engineer at a
logistics e-commerce company. Operations leaders need a trusted internal
dashboard to monitor how orders move through the fulfillment process.

The business wants to answer:

- How many orders are purchased, shipped, and delivered each day?
- How long does fulfillment take?
- Are orders delivered before the estimated delivery date?
- Are sellers handing orders to carriers before their shipping deadline?
- How much operational backlog exists?
- Which customer or seller regions are associated with delays?

The source data is the Olist e-commerce SQLite database. The final dashboard
should be backed by Postgres and served through Metabase. Because the dataset is
historical, "live updates" will be simulated by loading orders into Postgres in
date-based batches.

## Learner Goal

Build an end-to-end analytics engineering project that can be discussed in a job
interview.

By the end, the learner should be able to explain:

- How raw SQLite source data was loaded into Postgres.
- How source tables were profiled before modeling.
- Why raw data should not be manually overwritten.
- How dbt staging and mart models were designed.
- How logistics metrics were defined from the available schema.
- How data quality checks protect dashboard trust.
- How Metabase connects to modeled Postgres tables.
- How simulated batch loading creates a near-real-time dashboard experience.
- What assumptions and limitations exist in the Olist schema.

## Data

- Source: Olist e-commerce dataset as a SQLite database from Kaggle.
- Raw load target: Postgres.
- Recommended raw schema: `raw`.
- Core tables:
  - `orders`
  - `order_items`
  - `customers`
  - `sellers`
  - `products`
  - `product_category_name_translation`
  - `order_payments`
- Optional enrichment tables:
  - `order_reviews`
  - `geolocation`
- Out of scope for v0.1:
  - `leads_qualified`
  - `leads_closed`

### Table Grain

- `orders`: one row per `order_id`.
- `order_items`: one row per `order_id + order_item_id`.
- `customers`: one row per `customer_id`.
- `sellers`: one row per `seller_id`.
- `products`: one row per `product_id`.
- `order_payments`: one row per payment event. An order can have multiple
  payment rows.

### Key Columns

- Order lifecycle:
  - `order_id`
  - `customer_id`
  - `order_status`
  - `order_purchase_timestamp`
  - `order_approved_at`
  - `order_delivered_carrier_date`
  - `order_delivered_customer_date`
  - `order_estimated_delivery_date`
- Seller and item lifecycle:
  - `order_id`
  - `order_item_id`
  - `product_id`
  - `seller_id`
  - `shipping_limit_date`
  - `price`
  - `freight_value`
- Geography:
  - `customer_state`
  - `customer_city`
  - `seller_state`
  - `seller_city`

### Known Messiness

- Some timestamp fields are missing depending on `order_status`.
- Open, canceled, and unavailable orders should not be treated the same as
  delivered orders.
- One order can have multiple order items.
- One order can involve multiple sellers.
- Joining `orders` to `order_items` can multiply order rows.
- Payment rows may not be one-to-one with orders.
- Date columns may need explicit casting after import.
- The dataset is historical, so real-time behavior must be simulated.

### Metric Definitions

- Daily purchased orders:
  - Count orders by `order_purchase_timestamp`.
- Daily shipped orders:
  - Count orders by `order_delivered_carrier_date`.
- Daily delivered orders:
  - Count orders by `order_delivered_customer_date`.
- Fulfillment time:
  - `order_delivered_customer_date - order_purchase_timestamp`.
  - Include delivered orders only.
- Approval-to-carrier handoff time:
  - `order_delivered_carrier_date - order_approved_at`.
  - Exclude rows with missing required timestamps.
- Delivery SLA:
  - Delivered on time if
    `order_delivered_customer_date <= order_estimated_delivery_date`.
  - Include delivered orders only.
- Seller handoff SLA:
  - Seller handoff on time if
    `order_delivered_carrier_date <= shipping_limit_date`.
  - Model at `order_id + seller_id` or `order_id + order_item_id` grain.
- Backlog:
  - Purchased orders that are not finished as of the current simulated batch
    date.
  - Include statuses such as `created`, `approved`, `invoiced`, `processing`,
    and `shipped`.
  - Exclude `delivered`, `canceled`, and `unavailable`.
- At-risk backlog:
  - Open orders where the current simulated batch date is later than
    `order_estimated_delivery_date`.

### Data Download / Setup Instructions

1. Download the Olist SQLite database from Kaggle.
2. Use DataGrip or a Python load script to import the SQLite tables into
   Postgres.
3. Preserve raw source data without manual cleaning.
4. Run source profiling queries in Postgres to verify table grain, row counts,
   statuses, missing timestamps, and join risks.
5. Build cleaned and modeled outputs with dbt.

## Tech Stack

- Environment: `uv`
- Python: Python 3.11+
- SQL engine: Postgres
- Modeling or transformation tool: dbt Core with `dbt-postgres`
- Dashboard: Metabase
- Testing:
  - dbt generic tests
  - dbt custom tests
  - pytest for Python load/update scripts
  - SQL validation queries
- Optional tools:
  - DataGrip for manual SQL exploration
  - sqlfluff for SQL style
  - Docker Compose for local Postgres and Metabase
  - Pandas for SQLite-to-Postgres loading or simulated batch loads

## Deliverables

- Working raw-data load from SQLite into Postgres.
- Simulated batch update workflow for near-real-time dashboard refreshes.
- Source profiling notes or SQL queries.
- dbt staging models:
  - `stg_orders`
  - `stg_order_items`
  - `stg_customers`
  - `stg_sellers`
  - `stg_products`
  - `stg_order_payments`
- dbt mart models:
  - `fct_order_fulfillment`
  - `fct_seller_order_fulfillment`
  - `dim_customers`
  - `dim_sellers`
  - `dim_products`
  - `daily_operations_metrics`
  - `daily_backlog_snapshot`
- Data quality checks for uniqueness, nulls, accepted values, valid timestamps,
  nonnegative durations, and referential integrity.
- Metabase dashboard with:
  - Operations overview
  - Shipment volume
  - Fulfillment performance
  - SLA monitoring
  - Backlog monitoring
- Final README.
- Interview explanation notes covering architecture, metric logic, assumptions,
  limitations, and next improvements.

## Definition Of Done

The project is complete when:

- The workflow runs from setup to output.
- Outputs are reproducible.
- Tests or validation checks pass.
- The learner can explain the architecture, logic, tradeoffs, and next steps.
- Raw source tables are loaded into Postgres.
- Source profiling has been completed and summarized.
- dbt models build successfully.
- The final mart tables have documented grain and metric definitions.
- Metabase reads from modeled tables, not directly from raw tables.
- The dashboard updates after a new simulated batch is loaded.
- The learner can explain why some metrics use delivered orders only and why
  backlog is handled separately from fulfillment-time and SLA metrics.
