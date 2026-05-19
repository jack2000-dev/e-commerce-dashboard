# Project Review

**Project:** Olist Logistics Operations Intelligence Dashboard
**Date:** 2026-05-19
**Verdict:** Portfolio draft ready

---

## What You Built

End-to-end analytics engineering project:

- Loaded Olist SQLite data into Postgres `raw` schema via pgloader
- Profiled all 9 core source tables before modeling
- Built 6 dbt staging models with explicit type casting and null filters
- Built 7 dbt mart models: 2 fact tables, 3 dimension tables, 2 aggregate models
- Added 35 dbt tests: not_null, unique, accepted_values, custom nonnegative checks
- Connected Metabase to mart tables and built a 5-tile operations dashboard

---

## Final Score: 74 / 100

| Category | Score / Max |
|---|---|
| Correctness | 16 / 20 |
| Reproducibility | 10 / 15 |
| SQL and data logic | 12 / 15 |
| Python / pipeline quality | 9 / 15 |
| Testing and validation | 13 / 15 |
| Documentation | 7 / 10 |
| Interview readiness | 7 / 10 |

---

## What Improved

| Skill | Before | After |
|---|---|---|
| SQL date functions | Missing | DATE_TRUNC used correctly |
| GROUP BY | Missing | Used correctly |
| DQ checks | Named categories only | Writing specific dbt assertions |
| AE modeling | Fact table concept unanswered | Grain understood, models built |
| Debugging | Unknown | Fixed fan-out, DATE_PART precision, schema issues independently |

---

## What's Still Weak

- **COUNT DISTINCT** — still writing `count(user_id)` instead of `count(distinct user_id)`. Comes up in every interview.
- **Near-real-time framing** — still saying "real-time" instead of "near-real-time simulated via batch loads."
- **Batch simulation script** — `simulate_batch.py` not completed. This is the project's key differentiator.
- **Python depth** — pandas methods still shaky. Load verification pytest works but needs more coverage.
- **Project README** — no end-to-end setup guide. Required for portfolio use.

---

## Three Things To Do Before Using This In An Interview

1. Write `scripts/simulate_batch.py` — load orders up to a `--batch-date`, trigger `dbt run`. Without this, the "live dashboard" claim is unverifiable.
2. Write `README.md` — prerequisites, load steps, dbt build, open Metabase. Anyone should be able to run this from scratch.
3. Practice the two-minute pitch out loud — focus on grain definition, near-real-time framing, and what each test catches.

---

## Talking Points You Can Use Right Now

- *"I profiled the source data before modeling and found that customer_id is order-scoped in Olist — you can't do repeat customer analysis with this schema."*
- *"I used medallion architecture: raw preserves the source, staging handles casting and renaming, marts contain business logic and metrics."*
- *"I added dbt tests for uniqueness, nulls, and accepted values — for example, if a new order_status appeared in production, the accepted_values test would fail and alert the team before bad data reached the dashboard."*
- *"Fulfillment time is only calculated for delivered orders with non-null timestamps — including canceled or in-progress orders would make the average meaningless."*
- *"The dataset is historical so I simulate near-real-time updates by loading orders in date-based batches and re-running dbt after each load."*

---

## Next Project / Skills To Practice

1. **COUNT DISTINCT and window functions** — 5 SQL practice problems minimum.
2. **Complete simulate_batch.py** — makes this project interview-ready.
3. **Cloud migration (v0.2)** — Postgres on RDS, Metabase Cloud, batch trigger via Lambda or Airflow.
