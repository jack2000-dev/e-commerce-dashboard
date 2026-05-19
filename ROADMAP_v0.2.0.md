# Roadmap — v0.2.0: Cloud Migration

**Goal.** Move the Olist Logistics Operations Intelligence Dashboard off the
laptop and onto cloud infrastructure: **AWS RDS Postgres** as the warehouse,
**AWS Secrets Manager** for credentials, and **Metabase Cloud** for the
dashboard. The codebase stays the same; what changes is *where it runs* and
*how secrets, networking, and permissions are managed*. A secondary motivation
for v0.2.0 is hands-on AWS practice — RDS, VPC + security groups, IAM, and
Secrets Manager are the building blocks named most often in DE job postings.

**Success looks like.** A teammate (or a hiring manager) opens a public
Metabase Cloud link, sees a live dashboard, and the data behind it was built
by `dbt build` running against an AWS RDS database — credentials pulled from
Secrets Manager, not anything on the learner's MacBook.

---

## Why v0.2.0

The v0.1 build proved the pipeline works end-to-end. But everything depends on:

- a local Postgres process (`localhost:5432`),
- a connection string hard-coded in the repo,
- a Metabase container running in dev/H2 mode that can't be shared,
- the dbt run being kicked off by hand.

That is fine for a workshop, but it cannot be demoed in an interview, can't be
shared with stakeholders, and has no story for secrets, scheduling, or
permissions. v0.2.0 fixes those gaps and uses AWS-native services so the
project doubles as an AWS learning project.

---

## Out Of Scope For v0.2.0

Park these for v0.3+ so this version stays small enough to finish:

- Adding `order_reviews` or new marts.
- Switching the warehouse from Postgres to BigQuery / Snowflake / Redshift.
- Streaming or true real-time updates (simulated batches are still the model).
- Multi-environment promotion (`dev` → `prod` separate databases).
- HashiCorp Vault. AWS Secrets Manager covers the secrets story for v0.2.0;
  Vault is interesting for multi-cloud or on-prem, neither of which applies.
- CI/CD for dbt with GitHub Actions. (Stretch goal — see Milestone 6.)
- Private-subnet RDS with VPN / bastion / NAT Gateway. v0.2.0 uses a publicly
  accessible RDS instance with IP allowlist; the fully-private setup is a
  good v0.3 learning exercise.

---

## Decisions To Make Before Starting

These are the open questions to answer first; each one shapes a milestone.

1. **Managed Postgres provider.** Options worth comparing:
   - **AWS RDS Postgres** — primary choice. Closest to "production at a real
     company" and the best resume signal for DE roles. Costs real money
     (~$13–15/mo for `db.t4g.micro` + storage; free for 12 months on a
     fresh AWS account); more surface area to learn (VPC, security groups,
     IAM, parameter groups). v0.2.0 leans into that surface area on purpose.
   - **Neon** *(alternative / fallback)* — generous free tier, branching,
     fastest to set up. Use this if RDS setup stalls for more than a day or
     if AWS billing becomes a concern. The rest of the milestones still work
     — just swap the host and skip the AWS-specific deliverables.
   - **Supabase / Render / Railway / Fly.io Postgres** — viable but no
     specific advantage over Neon for this project. Skip unless there's a
     personal reason.

   *Decision:* **AWS RDS** is the primary path. Neon stays as the documented
   fallback so a budget or time-pressure pivot is one decision, not a
   redesign.

2. **Metabase Cloud plan.** Metabase Cloud Starter is the relevant tier. There
   is no free Metabase Cloud — confirm pricing on metabase.com before
   committing. If cost is a blocker, the fallback is self-hosted Metabase on
   AWS (small EC2 / ECS Fargate) or on Fly.io / Render, with Postgres as the
   Metabase app DB (no more H2).

3. **Where does `pgloader` run?** It needs the SQLite file. Options:
   - One-time load from the learner's laptop to cloud Postgres (simplest,
     fine for a historical dataset).
   - Containerize `pgloader` and run it from a small EC2 instance with the
     SQLite file pulled from S3 (more AWS learning; v0.2.0 stretch).

   *Recommendation:* one-time load from the laptop for v0.2.0. Make the
   SQLite-in-S3 + EC2 load a Milestone 2 stretch goal.

4. **Where does `dbt build` run?**
   - From the laptop pointed at RDS (simplest; works for v0.2.0).
   - From a scheduled GitHub Actions job pulling credentials from Secrets
     Manager via OIDC (Milestone 6 stretch).
   - From AWS-side compute (Lambda is awkward for dbt; ECS / Fargate is
     cleaner). Park this for v0.3.

   *Recommendation:* laptop-first; GitHub Actions in Milestone 6 if time
   allows.

Write down the chosen answers in `docs/v0.2.0-decisions.md` before starting
Milestone 1. The rest of the roadmap assumes **AWS RDS + Metabase Cloud**;
the Neon path is called out where it differs.

---

## Milestones

### Milestone 1 — Provision AWS RDS Postgres

**Goal.** An RDS Postgres database exists in your AWS account, you can
connect to it from your laptop over the public internet (allowlisted to
your IP), and `raw`, `staging`, `marts` schemas are created. Along the way,
you should be able to *explain* what each AWS resource does.

**Learning targets** (the *why* of each step, for interviews)
- **VPC** — RDS lives inside a VPC; what is a VPC and why does that matter?
- **Subnets (public vs. private)** — for v0.2.0 use a public subnet so
  Metabase Cloud can reach RDS; understand the tradeoff vs. private.
- **Security groups** — they're stateful firewalls. The RDS SG should allow
  inbound 5432 from *only* your laptop's IP and the Metabase Cloud IP range.
- **IAM** — the AWS user / role you use to run the AWS CLI vs. the Postgres
  user that dbt connects as. They are not the same.
- **Parameter groups** — where Postgres-level settings live in RDS.

**Deliverables**
- [ ] AWS account in place with billing alerts configured (budget alarm at
      $5 and $20 — do this *before* provisioning anything).
- [ ] IAM user (not the root user) for daily work, with programmatic access
      configured in `~/.aws/credentials` under a named profile (e.g. `olist`).
- [ ] A VPC for the project (the default VPC is fine for v0.2.0; document
      the choice).
- [ ] A security group `olist-rds-sg` with inbound rule: TCP 5432 from your
      laptop's current IP (`/32`).
- [ ] RDS Postgres instance:
   - Engine: Postgres 15 or 16
   - Instance class: `db.t4g.micro` (free-tier eligible if account is < 12
     months old; otherwise ~$13–15/mo)
   - Storage: 20 GB gp3, storage autoscaling enabled
   - Multi-AZ: **off** (cost) — note this as a v0.3 production consideration
   - Public accessibility: **on** (for v0.2.0)
   - Backup retention: 7 days
   - Initial database name: `olist`
- [ ] `psql "postgresql://...:5432/olist?sslmode=require"` from the laptop
      connects successfully.
- [ ] `CREATE SCHEMA raw; CREATE SCHEMA staging; CREATE SCHEMA marts;` run.
- [ ] `docs/v0.2.0-decisions.md` written, recording: region chosen, VPC id,
      security group id, RDS endpoint, why each one was chosen.

**Notes**
- Pick a region close to you (e.g. `ap-southeast-1` Singapore, `us-east-1`
  Virginia) — every other AWS resource will live there.
- `sslmode=require` is mandatory for RDS over the public internet. Both
  pgloader and dbt need this in their connection URLs.
- Never put the master password on the command line; create the instance
  via the console first, then immediately rotate the password through the
  console and save the new one to Secrets Manager in Milestone 3.

**Neon alternative path** *(if you pivot off AWS)*
- Skip the VPC / security group / IAM deliverables.
- Sign up for Neon, create a project named `olist`, save both the pooled
  and direct connection strings.
- For Neon: use the pooled connection string for dbt; use the direct
  connection string for `pgloader` (pgloader doesn't like PgBouncer-style
  poolers for COPY-heavy loads).
- The rest of the roadmap works unchanged; Secrets Manager (Milestone 3)
  becomes "`.env` only" on the Neon path.

**Done when**: `psql "$DATABASE_URL" -c "\dn"` lists `raw`, `staging`,
`marts`, *and* you can explain on a whiteboard what the VPC, subnet, and
security group are doing.

---

### Milestone 2 — Load Olist Into Cloud Postgres

**Goal.** The SQLite source data is now in RDS `raw`, with the same row
counts as in v0.1.

**Deliverables**
- [ ] `scripts/load_olist.cloud.load` (new pgloader file) parameterized by
      environment variables for the target Postgres URL. Keep the original
      `scripts/load_olist.load` in place for local development.
- [ ] `pgloader scripts/load_olist.cloud.load` runs to completion against RDS.
- [ ] `tests/test_load.py` updated:
   - Read `POSTGRES_URL` from env (no more hard-coded `localhost`).
   - Same test runs against either target based on env.
- [ ] `uv run pytest tests/test_load.py` passes against RDS.

**Risks / things to watch**
- pgloader vs. RDS SSL: append `?sslmode=require` (or use `WITH ssl = true`
  in the pgloader load file) — RDS rejects plaintext connections.
- Olist load is ~150 MB. On `db.t4g.micro` with 20 GB storage this is fine,
  but watch the storage graph in the RDS console during the first load.
- The original load uses `include drop, create tables`. Confirm the master
  user has DROP privileges (it does by default on RDS), or remove
  `include drop` and load into a fresh schema.

**Stretch goal — AWS-native load path**
- [ ] Create an S3 bucket `olist-source-<your-suffix>`, upload
      `olist.sqlite` to it.
- [ ] Launch a small EC2 instance (or ECS Fargate task) in the same VPC as
      RDS, install `pgloader`, pull the SQLite file from S3 with the AWS
      CLI, run the load.
- [ ] Document the IAM role used for the EC2 instance (S3 read + RDS network
      access via the security group).

This stretch turns "I loaded data into RDS" into "I built an S3 → EC2 →
RDS data-loading flow inside my own VPC," which is a much stronger
interview story. Skip if time-constrained.

**Done when**: row counts in `raw.orders` and `raw.order_items` match the
SQLite source, and the pytest suite is green against RDS.

---

### Milestone 3 — Secrets Manager & Config Hygiene

**Goal.** No connection strings, passwords, or hostnames are committed.
RDS credentials live in AWS Secrets Manager. Local and cloud runs are
switched by environment, not by editing files.

**Learning targets**
- What Secrets Manager is and how it differs from SSM Parameter Store
  (rotation, JSON shape, pricing).
- How to retrieve a secret at runtime: `aws secretsmanager get-secret-value`
  from a shell, or `boto3` from Python.
- Why the dbt user, the Metabase user, and the AWS IAM user are three
  different identities with different scopes.

**Deliverables**
- [ ] Secret created in Secrets Manager: name `olist/rds/dbt-user`, JSON
      payload with `host`, `port`, `dbname`, `username`, `password`,
      `sslmode`.
- [ ] Secret created in Secrets Manager: name `olist/rds/metabase-readonly`
      (filled in during Milestone 5).
- [ ] `scripts/load_env.sh` (or a Python helper) that fetches the secret
      and exports the fields as env vars for the current shell:
      `eval "$(./scripts/load_env.sh)"`.
- [ ] `.env.example` at the repo root listing every variable the project
      needs locally (when *not* using Secrets Manager — for the Neon path
      or for quick local Postgres).
- [ ] `.env` confirmed in `.gitignore`.
- [ ] `tests/test_load.py` reads `POSTGRES_URL` (or component env vars)
      from `os.environ`. No hard-coded strings.
- [ ] `olist/profiles.yml` template with two targets — `local` and `cloud`
      — both reading host / user / password / dbname from env vars (use
      dbt's `{{ env_var('...') }}` syntax). Profile selection driven by
      `DBT_TARGET`.
- [ ] `docs/interview_notes.md` gains a "secrets handling" bullet: env
      vars on the laptop, Secrets Manager as the source of truth, what
      rotation would look like, and what Vault would add (multi-cloud).

**Neon path note**: skip Secrets Manager. `.env` + `.env.example` is
enough; document that the Neon path explicitly trades off the AWS
learning to ship faster.

**Done when**: a fresh clone where you run `aws configure --profile olist`
and `eval "$(./scripts/load_env.sh)"` can then run the tests and
`dbt build` against RDS — no tracked file edits.

---

### Milestone 4 — Run dbt Against RDS

**Goal.** All dbt models build, all tests pass, on RDS.

**Deliverables**
- [ ] Two dbt targets in `profiles.yml`: `local` and `cloud`. Both use the
      `olist` profile name.
- [ ] `cd olist && dbt build --target cloud` succeeds end-to-end.
- [ ] Any custom or generic test failures resolved if RDS surfaces
      differences from local Postgres (timestamp casting, timezone, etc.).
- [ ] Confirm materializations land in `staging` and `marts` schemas
      exactly as configured in `dbt_project.yml`.
- [ ] Run `dbt docs generate` once and confirm it works in the cloud target
      (do not host the docs yet — that's a Milestone 6 stretch).

**Risks / things to watch**
- Latency: every `dbt build` round-trips queries over the public internet.
  Expect build time to grow from seconds to a couple of minutes. Acceptable.
- `current_date` in `daily_backlog_snapshot` — verify the RDS timezone
  (default UTC) matches what the model assumes. Add a model-level note if
  there's drift.
- RDS storage will grow during dbt builds (intermediate tables). Storage
  autoscaling should handle this; check the RDS console at least once.

**Done when**: `dbt build --target cloud` is green and the `marts` schema
in RDS has all 7 mart tables populated.

---

### Milestone 5 — Connect Metabase Cloud To RDS

**Goal.** A Metabase Cloud workspace exists, is connected to RDS via a
dedicated read-only Postgres user, and the five dashboard sections from
v0.1 are rebuilt.

**Networking note (this is the AWS-specific part)**
- Metabase Cloud connects to RDS over the public internet. Two ways to
  make this work:
  1. Find Metabase Cloud's outbound IP range in their docs, add those
     CIDRs to the `olist-rds-sg` security group on port 5432. *Preferred.*
  2. Temporarily open `0.0.0.0/0` on 5432 to confirm the connection works,
     then narrow to the Metabase ranges. **Do not leave wide open.**
- The Neon path doesn't have this concern — Neon is already on the public
  internet with its own access controls.

**Deliverables**
- [ ] Metabase Cloud account + workspace created.
- [ ] Postgres read-only role created on RDS:
      ```sql
      CREATE USER metabase_ro WITH PASSWORD '...';
      GRANT CONNECT ON DATABASE olist TO metabase_ro;
      GRANT USAGE ON SCHEMA marts TO metabase_ro;
      GRANT SELECT ON ALL TABLES IN SCHEMA marts TO metabase_ro;
      ALTER DEFAULT PRIVILEGES IN SCHEMA marts
          GRANT SELECT ON TABLES TO metabase_ro;
      ```
- [ ] `metabase_ro` credentials stored in Secrets Manager
      (`olist/rds/metabase-readonly`).
- [ ] Security group inbound rule added for Metabase Cloud IP ranges.
- [ ] Database connection added in Metabase Cloud, restricted to schema
      `marts` (Metabase never sees `raw` or `staging`).
- [ ] All five dashboard sections rebuilt:
   - Operations overview
   - Fulfillment performance
   - SLA monitoring
   - Backlog monitoring
   - Regional breakdown
- [ ] Dashboard URL captured (public link if comfortable; otherwise
      screenshot to `img/`).
- [ ] `docker-compose.yml` updated with a `# v0.1 local only` comment, or
      moved under `local/` — make it clear the canonical dashboard is now
      Metabase Cloud.

**Done when**: clicking the Metabase Cloud link from a clean browser
session shows the dashboard with live numbers from RDS.

---

### Milestone 6 — Documentation, Demo, Polish *(stretch)*

**Goal.** Anyone can read the repo and reproduce the cloud setup; the
project is interview-ready.

**Deliverables**
- [ ] README updated:
   - Add a "Cloud (v0.2.0)" section under Setup that mirrors the local
     instructions but for AWS RDS + Metabase Cloud.
   - Architecture diagram updated to show: SQLite → RDS (in your VPC) →
     dbt (laptop or scheduled, creds from Secrets Manager) → Metabase
     Cloud.
- [ ] `docs/interview_notes.md` updated with new v0.2.0 talking points:
   - Why RDS over self-hosted Postgres on EC2.
   - Why Metabase Cloud over the H2 dev container.
   - How Secrets Manager works and how rotation would be configured.
   - Why three different identities (AWS IAM, dbt Postgres user, Metabase
     read-only Postgres user).
   - What broke or surprised you during the migration — hiring managers
     love the real-world bits.
   - What you'd do next: private subnet + bastion, dbt on Fargate,
     dev/prod environments, `order_reviews` mart.
- [ ] Tag the release: `git tag v0.2.0` and push.
- [ ] *Stretch:* GitHub Actions workflow that runs `dbt build --target cloud`
      on a cron schedule (e.g. nightly). Use **GitHub OIDC → AWS IAM
      role** so the workflow can read Secrets Manager without storing
      long-lived AWS keys in GitHub. This is a strong portfolio piece.
- [ ] *Stretch:* host `dbt docs` via a free static host (Cloudflare Pages,
      GitHub Pages, or an S3 + CloudFront static site for more AWS
      practice) and link from the README.

**Done when**: a recruiter reading the README understands the architecture
in under 60 seconds and can click through to a working dashboard.

---

## Risk Register

Things most likely to bite during the migration, with a one-line mitigation:

| Risk | Mitigation |
|---|---|
| AWS billing surprise | Set $5 + $20 budget alarms *before* provisioning. Stop the RDS instance when not actively working on it (saves compute, storage still bills). |
| `db.t4g.micro` not free-tier-eligible (account > 12 months old) | Accept the ~$15/mo, or pivot to the Neon alternative path. |
| RDS publicly accessible = attack surface | Tight security group (only your IP + Metabase Cloud ranges). Strong master password. Rotate immediately after creation. |
| Metabase Cloud IP ranges change | Document where you got them; re-check before tagging v0.2.0. If unavailable, open `0.0.0.0/0` *only as a debug step*, never as the final state. |
| `pgloader` SSL incompatibility with RDS | Add `?sslmode=require` to the URL or `WITH ssl = true` in the pgloader file. |
| Hard-coded `localhost` somewhere we forgot | Grep for `localhost` and `127.0.0.1` before tagging v0.2.0. |
| Timezone drift (`current_date`) between local and RDS | RDS defaults to UTC; standardize and document. |
| Metabase Cloud cost surprises | Confirm pricing tier before connecting; have a self-hosted Metabase on EC2/Fargate fallback in mind. |
| Secrets leak into the repo | Pre-commit hook or `gitleaks` scan before tagging. Secrets Manager means the value is never typed into a file, which helps. |
| Free-tier Neon pauses on inactivity *(Neon path only)* | Document the wake-up delay; accept it for a portfolio project. |

---

## Definition Of Done For v0.2.0

The release ships when:

- [ ] RDS holds the full Olist dataset, schemas `raw` / `staging` / `marts`
      populated (or Neon if you pivoted; document which).
- [ ] `dbt build --target cloud` is green.
- [ ] Metabase Cloud dashboard is live and matches the v0.1 sections.
- [ ] Credentials live in AWS Secrets Manager (or `.env` on the Neon path).
- [ ] No connection strings, hostnames, or passwords are committed.
- [ ] README and interview notes reflect the cloud architecture.
- [ ] You can explain, in two minutes:
   - what changed between v0.1 and v0.2,
   - what each AWS resource (VPC, security group, RDS, Secrets Manager,
     IAM user) is doing and why,
   - what you would do next (v0.3 ideas: private-subnet RDS + bastion,
     dbt on ECS Fargate, GitHub Actions OIDC, `order_reviews` mart,
     dev/prod environments, Vault for multi-cloud).
