# Project Score

## Learner Summary

- Target role: Analytics Engineer / Technical Data Analyst
- Difficulty: Intermediate, balanced path
- Project: Olist Logistics Operations Intelligence Dashboard
- Tech stack: uv, Python, Postgres.app, pgloader, dbt-core, dbt-postgres, Metabase, OrbStack, pytest
- Submission date: 2026-05-19

## Final Score

Overall score: 74 / 100

| Category | Weight | Score | Notes |
| --- | ---: | ---: | --- |
| Correctness | 20 | 16 | All models build and produce correct metrics. Minor: fulfillment days formula fixed mid-build. Dashboard tiles reflect real data. |
| Reproducibility | 15 | 10 | dbt build is fully reproducible. pgloader requires manual /tmp copy workaround due to space in path. No README with setup steps yet. |
| SQL and data logic | 15 | 12 | Grain understood and enforced. Correct filters on delivered orders. Fan-out risk identified and avoided. COUNT DISTINCT still a gap. |
| Python or pipeline quality | 15 | 9 | pytest load verification written and passing. Batch simulation script not completed. pandas/Python methods still shaky. |
| Testing and validation | 15 | 13 | 35 dbt tests passing. not_null, unique, accepted_values, custom nonnegative tests all present. Custom test explanation could be sharper. |
| Documentation | 10 | 7 | source_profile.md complete. interview_notes.md written. No final README with end-to-end setup steps. |
| Interview readiness | 10 | 7 | Strong domain narrative. Medallion architecture named correctly. Grain explanation needs practice. "real-time" vs "near-real-time" still slipping. |

## Progression

- Before assessment baseline: SQL missing GROUP BY and DATE_TRUNC. Python wrong on drop_duplicates/to_csv. DQ categories only. Fact table concept unanswered.
- After assessment result: DATE_TRUNC and GROUP BY now used correctly. dbt tests written with specific assertions. Fact/dim model described with some grain awareness. COUNT DISTINCT still missed.
- Biggest improvement: SQL date functions, dbt testing, and end-to-end AE workflow understanding.
- Remaining gap: COUNT DISTINCT, near-real-time framing, Python pipeline depth, batch simulation script.

## Strengths

- Strong domain understanding from day one — business questions were clear and drove modeling decisions.
- Picked up dbt conventions quickly — CTE structure, ref(), source(), schema.yml all used correctly.
- Good debugging instinct — identified fan-out risk, fixed DATE_PART precision bug, caught schema issues.
- Honest self-reflection — accurately identified "overview thinking" as the real weak spot.
- Medallion architecture understood and applied correctly.

## Improvements

- Complete `scripts/simulate_batch.py` — batch loading is the project's key differentiator and is unfinished.
- Write a final `README.md` with end-to-end setup steps (clone → load → dbt build → Metabase).
- Fix pgloader path issue — either move the project to a path without spaces or document the /tmp workaround.
- Practice COUNT DISTINCT — comes up in every analytics interview.
- Sharpen custom test explanations — always state what specific bad data the test would catch.

## Interview Feedback

- Can explain the problem: Yes — business questions are clear and specific.
- Can explain the architecture: Yes — medallion architecture, SQLite → Postgres → dbt → Metabase flow is solid.
- Can explain data logic: Mostly — grain definition needs one more practice pass. Metric filters (delivered only, null guards) are understood.
- Can explain tests: Partially — lists tests correctly but explanations are thin on what bugs they catch.
- Can explain tradeoffs: Partially — customer_id limitation documented. Near-real-time simulation still framed as "real-time."
- Can discuss next steps: Yes — v0.2 cloud migration and order_reviews addition are strong answers.

## Next Learning Plan

1. **COUNT DISTINCT and window functions** — practice 5 SQL problems involving DISTINCT counts, RANK(), and ROW_NUMBER(). These appear in every AE interview.
2. **Complete simulate_batch.py** — write a Python script that accepts `--batch-date`, loads orders up to that date, and triggers `dbt run`. Add a pytest test for it.
3. **Write the project README** — a clean setup guide (prerequisites, clone, load, dbt build, open Metabase) makes this portfolio-ready and is required for any real job submission.

## Final Verdict

**Portfolio draft ready.**

The core project works end to end: data is loaded, modeled, tested, and visualized. The architecture is explainable. With a completed batch simulation script and a final README, this becomes interview-practice ready.
