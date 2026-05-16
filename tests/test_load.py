# Sqlite -> Postgres sanity check 

# connect to sqlite
# connect to postgres
# for each table:
#   count rows in sqlite
#   count rows in postgres
#   assert they match

import sqlite3
import psycopg2

SQLITE_PATH = "/tmp/olist.sqlite"
PG_CONN = "postgresql://jack2000@localhost:5432/olist"



def test_orders_row_count_matches():
  conn = sqlite3.connect(SQLITE_PATH)
  cur = conn.cursor()
  cur.execute("SELECT COUNT(*) FROM orders")
  sqlite_count = cur.fetchone()[0] # fetchone() returns one row, [0] gets the first column
  conn.close()

  conn = psycopg2.connect(PG_CONN)
  cur = conn.cursor()
  cur.execute("SELECT COUNT(*) FROM raw.orders")
  pg_count = cur.fetchone()[0] # fetchone() returns one row, [0] gets the first column
  conn.close()

  assert sqlite_count == pg_count

EXPECTED_TABLES = [
  "customers", "geolocation", "order_items", "order_payments", "order_reviews", "orders", "product_category_name_translation", "products", "sellers"
]

def test_raw_tables_exist():
    conn = psycopg2.connect(PG_CONN)
    cur = conn.cursor()
    cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'raw'")
    actual_tables = [row[0] for row in cur.fetchall()]
    conn.close()

    for table in EXPECTED_TABLES:
        assert table in actual_tables, f"Missing table: {table}"