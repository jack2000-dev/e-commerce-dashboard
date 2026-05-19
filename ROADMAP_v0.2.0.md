# Roadmap — v0.2.0: Cloud Migration

**Goal.** Move the Olist Logistics Operations Intelligence Dashboard off the
laptop and onto cloud infrastructure: a managed Postgres service for the
warehouse and Metabase Cloud for the dashboard. The codebase stays the same;
what changes is *where it runs* and *how secrets, configuration, and the load
schedule are managed*.

**Success looks like.** A teammate (or a hiring manager) opens a public
Metabase Cloud link, sees a live dashboard, and the data behind it was built
by `dbt build` running against a managed Postgres database — not anything on
the learner's MacBook.

---

## Why v0.2.0

The v0.1 build proved the pipeline works end-to-end. But everything depends on:

- a local Postgres process (`localhost:5432`),
- a connection string hard-coded in the repo,
- a Metabase container running in dev/H2 mode that can't be shared,
- the dbt run being kicked off by hand.

That is fine for a workshop, but it cannot be demoed in an interview, can't be
shared with stakeholders, and has no story for secrets, scheduling, or
permissions. v0.2.0 fixes those gaps without rebuilding the data model.

---

## Out Of Scope For v0.2.0

Park these for v0.3+ so this version stays small enough to finish:

- Adding `order_reviews` or new marts.
- Switching the warehouse from Postgres to BigQuery / Snowflake / Redshift.
- Streaming or true real-time updates (simulated batches are still the model).
- Multi-environment promotion (`dev` → `prod` separate databases).
- HashiCorp Vault. (Noted in the interview talking points, but managed-service
  secrets + a `.env` pattern are enough for v0.2.0. Revisit in v0.3.)
- CI/CD for dbt with GitHub Actions. (Stretch goal — see Milestone 6.)

---

## Decisions To Make Before Starting

These are the open questions to answer first; each one shapes a milestone.

1. **Managed Postgres provider.** Options worth comparing:
   - **Neon** — generous free tier, branching, fastest to set up; great for a
     portfolio project.
   - **Supabase** — free tier with dashboard + auth bundled in; overkill if
     only Postgres is needed but works fine.
   - **AWS RDS Postgres** — closest to "production at a real company"; costs
     money even at the smallest size, more setup, IAM and VPC concepts to
     learn. Best signal for an interview.
   - **Render / Railway / Fly.io Postgres** — quick, cheap, less learning.

   *Recommendation for portfolio signal:* start on Neon to ship fast, then
   redo Milestone 1 on RDS in v0.3 if AWS is a target stack.

2. **Metabase Cloud plan.** Metabase Cloud Starter is the relevant tier. There
   is no free Metabase Cloud — confirm pricing on metabase.com before
   committing. If cost is a blocker, the fallback is self-hosted Metabase on
   Fly.io or Render with Postgres as the app DB (no more H2).

3. **Where does `pgloader` run?** It needs the SQLite file. Options:
   - One-time load from the learner's laptop to the cloud Postgres (simplest,
     fine for a historical dataset).
   - Containerize `pgloader` and run it from a cloud VM (only worth it once
     the dataset refreshes).

   *Recommendation:* one-time load from the laptop for v0.2.0.

4. **Where does `dbt build` run?**
   - From the laptop pointed at cloud Postgres (simplest; works for v0.2.0).
   - From a scheduled job (GitHub Actions cron, or a small Fly machine).

   *Recommendation:* laptop-first, scheduled run in Milestone 6 only if time
   allows.

Write down the chosen answers in `docs/v0.2.0-decisions.md` before starting
Milestone 1. The rest of the roadmap assumes Neon + Metabase Cloud unless
noted; swap names as needed.

---

## Milestones

### Milestone 1 — Provision Cloud Postgres

**Goal.** A managed Postgres database exists, you can connect to it from your
laptop, and `raw`, `staging`, `marts` schemas are created.

**Deliverables**
- [ ] Account created on the chosen provider (e.g. Neon).
- [ ] A project / database named `olist` provisioned.
- [ ] A user / role created with privileges to create schemas and tables.
- [ ] Connection string saved in a local `.env` file (see Milestone 3).
- [ ] `psql` (or DataGrip) connects successfully from the laptop.
- [ ] `CREATE SCHEMA raw; CREATE SCHEMA staging; CREATE SCHEMA marts;` run.
- [ ] SSL / `sslmode=require` confirmed working — managed services usually
      require it; pgloader and dbt both need this in their connection URLs.

**Notes**
- Pin the Postgres major version that matches what dbt-postgres tests against
  (Postgres 15 or 16 is safe at the time of writing).
- For Neon: enable a branch named `main` and use the pooled connection string
  for dbt; use the direct connection string for `pgloader` (pgloader doesn't
  like PgBouncer-style poolers for COPY-heavy loads).

**Done when**: `psql "$DATABASE_URL" -c "\dn"` lists `raw`, `staging`, `marts`.

---

### Milestone 2 — Load Olist Into Cloud Postgres

**Goal.** The SQLite source data is now in cloud Postgres `raw`, with the same
row counts as in v0.1.

**Deliverables**
- [ ] `scripts/load_olist.cloud.load` (new pgloader file) parameterized by
      environment variables for the target Postgres URL. Keep the original
      `scripts/load_olist.load` in place for local development.
- [ ] `pgloader scripts/load_olist.cloud.load` runs to completion against the
      cloud database.
- [ ] `tests/test_load.py` updated:
   - Read `POSTGRES_URL` from env (no more hard-coded `localhost`).
   - Add a `--cloud` marker or just rely on env so the same test works in
     both environments.
- [ ] `uv run pytest tests/test_load.py` passes against cloud Postgres.

**Risks / things to watch**
- pgloader vs. managed-Postgres SSL: may need `&sslmode=require` appended to
  the connection URL, or pgloader's `SET client_min_messages = 'warning'`.
- Egress / size limits on the free tier — the full Olist load is ~150 MB; fine
  for Neon's free tier but check before assuming.
- The original load uses `include drop, create tables`. Confirm the cloud user
  has DROP privileges, or remove `include drop` and load into a fresh schema.

**Done when**: row counts in cloud `raw.orders` and `raw.order_items` match
the SQLite source, and the pytest suite is green against cloud.

---

### Milestone 3 — Configuration & Secrets Hygiene

**Goal.** No connection strings, passwords, or hostnames are committed. Local
and cloud runs are switched by environment, not by editing files.

**Deliverables**
- [ ] `.env.example` at the repo root listing every variable the project
      needs (`POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`,
      `POSTGRES_PORT`, `POSTGRES_SSLMODE`, `DBT_TARGET`).
- [ ] `.env` added to `.gitignore` (verify — `.gitignore` already exists).
- [ ] `tests/test_load.py` reads `POSTGRES_URL` from env via `os.environ` (or
      `python-dotenv` if loading from a file).
- [ ] `scripts/load_olist.cloud.load` uses `${POSTGRES_URL}` (pgloader
      supports env-var substitution; verify with the local pgloader version).
- [ ] `olist/profiles.yml` template added (or `profiles.yml` instructions in
      the README) showing how to point dbt at either `local` or `cloud` via
      `DBT_TARGET`. Both targets read host / user / password / dbname from
      env vars — no plain-text secrets.
- [ ] `pyproject.toml` adds `python-dotenv` if `tests/test_load.py` loads
      from `.env`.
- [ ] `docs/interview_notes.md` gains a short "secrets handling" bullet
      explaining the env-var approach and *why* Vault is the next step but
      not part of v0.2.0.

**Done when**: a fresh clone with only a populated `.env` can run the tests
and `dbt build` against cloud, without editing any tracked file.

---

### Milestone 4 — Run dbt Against Cloud Postgres

**Goal.** All dbt models build, all tests pass, on cloud Postgres.

**Deliverables**
- [ ] Two dbt targets in `profiles.yml`: `local` and `cloud`. Both use the
      `olist` profile name.
- [ ] `cd olist && dbt build --target cloud` succeeds end-to-end.
- [ ] All 4 custom + generic test failures resolved if the cloud Postgres
      version surfaces differences (e.g. timestamp casting behavior).
- [ ] Confirm materializations land in `staging` and `marts` schemas exactly
      as configured in `dbt_project.yml`.
- [ ] Run `dbt docs generate` once and confirm it works in the cloud target
      (do not host the docs yet — that's a Milestone 6 stretch).

**Risks / things to watch**
- Latency: every `dbt build` round-trips queries over the network. Expect the
  build time to grow from seconds to a couple of minutes. Acceptable.
- `current_date` in `daily_backlog_snapshot` — verify the cloud Postgres
  timezone matches what the model assumes (UTC is safest). Add a TODO note
  if there's drift.

**Done when**: `dbt build --target cloud` is green and the `marts` schema in
cloud Postgres has all 7 mart tables populated.

---

### Milestone 5 — Connect Metabase Cloud

**Goal.** A Metabase Cloud workspace exists, is connected to the cloud
Postgres `marts` schema, and the five dashboard sections from v0.1 are
rebuilt.

**Deliverables**
- [ ] Metabase Cloud account + workspace created.
- [ ] Database connection added: cloud Postgres, `marts` schema only (Metabase
      should never see `raw`).
- [ ] Create a **read-only Postgres role** for Metabase — `GRANT USAGE ON
      SCHEMA marts` and `GRANT SELECT ON ALL TABLES IN SCHEMA marts`. Do not
      reuse the dbt user.
- [ ] All five dashboard sections rebuilt:
   - Operations overview
   - Fulfillment performance
   - SLA monitoring
   - Backlog monitoring
   - Regional breakdown
- [ ] Dashboard URL captured (public link if comfortable; otherwise screenshot
      to `img/`).
- [ ] `docker-compose.yml` updated with a `# v0.1 local only` comment, or
      moved under `local/` — make it clear that the canonical dashboard is
      now Metabase Cloud.

**Done when**: clicking the Metabase Cloud link from a clean browser session
shows the dashboard with live numbers from cloud Postgres.

---

### Milestone 6 — Documentation, Demo, Polish *(stretch)*

**Goal.** Anyone can read the repo and reproduce the cloud setup; the project
is interview-ready.

**Deliverables**
- [ ] README updated:
   - Add a "Cloud (v0.2.0)" section under Setup that mirrors the local
     instructions but for cloud Postgres + Metabase Cloud.
   - Architecture diagram updated to show: SQLite → cloud Postgres → dbt
     (laptop or scheduled) → Metabase Cloud.
- [ ] `docs/interview_notes.md` updated with new v0.2.0 talking points:
   - Why managed Postgres over self-hosted.
   - Why Metabase Cloud over the H2 dev container.
   - How secrets are handled today and what Vault would add.
   - What broke or surprised you during the migration (real-world stuff —
     hiring managers love these).
- [ ] Tag the release: `git tag v0.2.0` and push.
- [ ] *Stretch:* GitHub Actions workflow that runs `dbt build --target cloud`
      on a cron schedule (e.g. nightly), reading Postgres credentials from
      GitHub Actions secrets. This is the "production" demo bonus.
- [ ] *Stretch:* host `dbt docs` via a free static host (Cloudflare Pages,
      GitHub Pages) and link from the README.

**Done when**: a recruiter reading the README understands the architecture in
under 60 seconds and can click through to a working dashboard.

---

## Risk Register

Things most likely to bite during the migration, with a one-line mitigation:

| Risk | Mitigation |
|---|---|
| Free-tier Postgres pauses on inactivity (Neon, Supabase) | Document the wake-up delay; or accept it for a portfolio project. |
| `pgloader` SSL or pooler incompatibility | Use the direct (non-pooled) connection URL for load; pooled for dbt. |
| Hard-coded `localhost` somewhere we forgot | Grep for `localhost` and `127.0.0.1` before tagging v0.2.0. |
| `current_date` / timezone drift between local and cloud Postgres | Standardize on UTC and document it. |
| Metabase Cloud cost surprises | Confirm pricing tier before connecting; have the self-hosted fallback ready. |
| Secrets leak into the repo | Pre-commit hook or `gitleaks` scan before tagging. |

---

## Definition Of Done For v0.2.0

The release ships when:

- [ ] Cloud Postgres holds the full Olist dataset, schemas `raw` / `staging` /
      `marts` populated.
- [ ] `dbt build --target cloud` is green.
- [ ] Metabase Cloud dashboard is live and matches the v0.1 sections.
- [ ] No connection strings, hostnames, or passwords are committed.
- [ ] README and interview notes reflect the cloud architecture.
- [ ] You can explain, in two minutes, what changed between v0.1 and v0.2,
      and what you would do next (v0.3 ideas: Vault, RDS, `order_reviews`,
      scheduled dbt runs, dev/prod environments).
