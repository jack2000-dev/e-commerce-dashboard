# After Assessment

Answer these after completing the project.

## 1. SQL Transfer

Given a table named `events`:

| column | type |
| --- | --- |
| event_id | integer |
| user_id | integer |
| event_ts | timestamp |
| event_type | text |
| session_id | text |

Write a query that returns daily active users and event count.

Ans:
```sql
select 
  date_trunc('day' event_ts) as days,
  count(user_id) as daily_active_users,
  count(*) as event_count
from events
where event_type = 'Active'
group by 1
```

## 2. Data Modeling Or Analysis

Choose one:

- Design a simple fact and dimension model for the data in your project.
- Define three trustworthy metrics for your project and explain their caveats.

Ans: 
- My fact model are `fct_order_fulfillment` and `fct_seller_order_fulfillment` dimension model are `dim_customers`, `dim_products`, and `dim_sellers` 

## 3. Pipeline Or Workflow Reliability

Explain how your project handles or should handle:

- Missing data
- Duplicate data
- Bad schema changes
- Re-running the workflow

Ans:
- Missing data: use `is not null` keyword in SQL to filter out the missing data
  - Duplicate data: In SQL you can use `select distinct` or CTE to remove duplicate with delete keyword.
- Bad schema changes: Ensure data compatibility and follows workflow like expand -> migrate -> switch -> contract.
- Re-running the workflow: Easy with dbt where it contain all sources and schema for building the models to use again. By using dbt, this project is reproducible and easy to maintain as every organized and structured.
- Note: I would also perform data inspection to do quality checks on the data set first to see if the data usable or not.

## 4. Testing

List the tests or validation checks you added. For each one, explain what bug
it would catch.

- not_null: this will detect the missing data in the models
- unique: this will detect the duplication in the models
- accepted_value: this will filter out unwanted data. E.g., order_status column where it's a categorial data which have determined category. This will ensure the correctness of data
- custom nonnegative duration checks: this will protect dashboard trust

## 5. Interview Explanation

Explain your project as if an interviewer asked:

```text
Walk me through a data project you built. What problem did it solve, how did
it work, and what tradeoffs did you make?
```
Ans:
# Objective
I first start off by asking and questioning business needs. Start with the requirements of..
- How many orders are purchased, shipped, and delivered each day?
- How long does fulfillment take?
- Are orders delivered before the estimated delivery date?
- Are sellers handing orders to carriers before their shipping deadline?
- How much operational backlog exists?
- Which customer or seller regions are associated with delays?

# Process
1. I build a data pipeline starting from load the data from sqlite into my local postgres server database. 
2. Use madallion architecture to divide data into 3 stages which are raw/staging/marts. At the raw I just use pgloader from olist.sqlite into postgres.
3. Staging: I clean and prepare the data that needed for analysis and marts. Therefore, the table structure are 6 staging models and 7 marts models including 2 fact tables, 3 dimension tables, and 2 aggregate models (for dashboard)
4. Transform staging into marts which will be the data that answer the business questions and will be use on Metabase for near-real-time dashboard.
5. Testing on dbt: I added dbt tests for uniqueness, nulls, accepted values, and custom nonnegative duration checks to protect dashboard trust. (schema.yml)
6. I set up metabase via docker container mangaed via orbstack for best local performance. Then connect the data and visualize them

# Q&A
- Why SQLite → Postgres instead of querying SQLite directly
  - Postgres for more production work and scaleable database. It's a great opensource future-proof database.
- Why raw schema is never overwritten
  - Because I use a Medallion architecture where I have data in 3 seperate stage. Raw, Staging, and Marts. Raw will serve as a single original source of truth in case we want to do more analysis in the future.
- How staging differs from marts
  - Staging is cleaning and preparing the data. Where marts serve more as a finished data that more ready to use and more specify depends on the purpose of use.
- What you'd improve in v0.2
  - In v0.2.0 I will make this to be more production ready where the postgres and Metabase hosting will be moved on cloud. I'm expecting to use AWS for postgres and Metabase hosting (or maybe Metabase cloud). On AWS I'll also implement Vault for more secure production use.

## 6. Reflection

- What improved from your before assessment?
  - I understand more of the dbt workflow, syntax, and how it works on a basic level. Including medallion architecture where I can put it to use. I also debug a lot on my own. Know how to use AI as a assisted tutor. Testing and documentation also a great part of learning. How to use Metabase on a practical environment including Orbstack (Docker container).
- What is still weak?
  - The overview thinking, sometime I just got lost and don't know where to put which. I think I can improve this by focus more on planning and keeping things more organized so that I have my own blueprint of building things not just this project. Because once you get it more organize, you'll know what do to next and how to handle it without breaking the whole project
- What would you build next?
  - Olist Dashboard v0.2.0, Cloud-based version (Cloud migration) where I will host Postgres on server (potentially, AWS), including Metabase Clound. This will be a near-real-time data which will be a dynamic dashboard that can update based on the cloud data.

