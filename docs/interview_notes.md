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
4. Transform staging into marts which will be the data that answer the business questions and will be use on Metabase for near-real-time dashboard (I use historical dataset for scaffolding this project)
5. Testing on dbt: I added dbt tests for uniqueness, nulls, accepted values, and custom nonnegative duration checks to protect dashboard trust. (schema.yml)
6. I set up metabase via docker container mangaed via orbstack for best local performance. Then connect the data and visualize them

# Q&A
- Why SQLite → Postgres instead of querying SQLite directly
  - SQLite is a file-based database with no concurrent access, no schema enforcement, and limited SQL features. Postgres supports multiple connections, proper data types, schemas, and is the standard for production analytics workloads. Metabase also connects natively to Postgres.
- Why raw schema is never overwritten
  - Because I use a Medallion architecture where I have data in 3 seperate stage. Raw, Staging, and Marts. Raw will serve as a single original source of truth in case we want to do more analysis in the future.
- How staging differs from marts
  - Staging is cleaning and preparing the data. Where marts serve more as a finished data that more ready to use and more specify depends on the purpose of use.
- What are the schema limitation
  - `customer_id` is order-scoped, not person-scoped. Repeat buyers get a new `customer_id` per order, so repeat purchase rate analysis is not possible with this schema.
- What you'd improve in v0.2
  - Cloud migration: In v0.2.0 I will make this to be more production ready where the postgres and Metabase hosting will be moved on cloud. I'm expecting to use AWS for postgres and Metabase hosting (or maybe Metabase cloud). On AWS I'll also implement Vault for more secure production use. I'd also add `order_reviews` to the mart models to correlate fulfillment performance with customer satisfaction scores.