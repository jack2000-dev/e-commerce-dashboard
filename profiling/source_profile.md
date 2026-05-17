# Source Profile

Profiled against: `raw` schema in Postgres (`olist` database)
Purpose: Document data shape, quality issues, and modeling decisions before writing dbt models.

---

## Table: orders

- **Grain:** one row per `order_id` (verified — 0 duplicates)
- **Row count:** 99,441

### Status distribution
| status | count |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

### Null timestamps
| column | null count | notes |
|---|---|---|
| order_purchase_timestamp | 0 | clean |
| order_approved_at | 160 | small, guard in models |
| order_delivered_carrier_date | 1,783 | expected for non-delivered orders |
| order_delivered_customer_date | 2,965 | expected for non-delivered + 8 anomalous delivered rows |
| order_estimated_delivery_date | 0 | clean |

### Modeling decisions
- Fulfillment time filter: `order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL`
- Backlog filter: `order_status IN ('created', 'approved', 'invoiced', 'processing', 'shipped')`
- Exclude from all metrics: `canceled`, `unavailable`
- 8 delivered orders have null `order_delivered_customer_date` — data quality anomaly, excluded by null filter

### Join risk
- Joining to `order_items` on `order_id` multiplies rows (fan-out): 98,666 distinct orders → 112,650 rows

---

## Table: order_items

- **Grain:** one row per `order_id + order_item_id` (verified — 0 duplicates)
- **Row count:** TBD
- **Null columns:** TBD
- **Modeling decisions:** TBD
- **Join risk:** joining to `orders` on `order_id` only will fan out order rows

---

## Table: order_payments

- **Grain:** one row per `order_id + payment_sequential` (verified — max 29 rows per order)
- **Null columns:** payment_value — 0 nulls, 0 negatives (clean)
- **Payment types:** credit_card (76,795), boleto (19,784), voucher (5,775), debit_card (1,529), not_defined (3)
- **Modeling decisions:** aggregate to order grain with SUM(payment_value) before joining to orders
- **Join risk:** direct join to orders fans out — always aggregate first


---

## Table: customers

- **Grain:** one row per customer_id (verified — 0 duplicates)
- **Row count:** 99,441
- **Null columns:** 0 nulls on key columns
- **Known quirk:** customer_id is order-scoped, not person-scoped. Repeat buyers
  get a new customer_id per order. Cannot use this table to analyze repeat purchase behavior.
- **Join:** joins 1-to-1 with orders on customer_id — no fan-out risk

---

## Table: sellers

- **Grain:** TBD
- **Row count:** TBD
- **Null columns:** TBD
- **Modeling decisions:** TBD

---

## Table: products

- **Grain:** TBD
- **Row count:** TBD
- **Null columns:** TBD
- **Modeling decisions:** TBD

---

## Table: product_category_name_translation

- **Grain:** TBD
- **Row count:** TBD
- **Notes:** lookup table for category name translations

---

## Known Cross-Table Risks

| Risk | Tables involved | Impact |
|---|---|---|
| Fan-out on order_id join | orders + order_items | inflated order counts |
| Multiple payments per order | orders + order_payments | inflated revenue if not aggregated first |
| TBD | | |
