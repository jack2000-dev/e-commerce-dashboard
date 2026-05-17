-- Profiling Template
-- Replace: {schema}, {table}, {primary_key}, {col1}, {col2} with real values

-- 1. Row count
SELECT COUNT(*) AS row_count
FROM raw.customers;

-- 2. Grain check — returns 0 if grain is valid, >0 if duplicates exist
SELECT customer_id, COUNT(*) AS n
FROM raw.customers
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 10;

-- 3. Null check — add one line per column you want to check
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS customer_unique_id_nulls,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS customer_zip_code_prefix_nulls,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS customer_nulls,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS customer_state_nulls
FROM raw.customers;

-- 4. Distinct values for categorical columns (e.g. status)
SELECT customer_state, COUNT(*) AS n
FROM raw.customers
GROUP BY 1
ORDER BY n DESC;

-- 5. Fan-out check — verify join does not multiply rows
SELECT
    COUNT(DISTINCT a.customer_id) AS distinct_keys,
    COUNT(a.customer_id)          AS total_rows_after_join
FROM raw.customers a
JOIN raw.orders b ON a.customer_id = b.customer_id;
