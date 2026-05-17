-- Profiling Template
-- Replace: {schema}, {table}, {primary_key}, {col1}, {col2} with real values

-- 1. Row count
SELECT COUNT(*) AS row_count
FROM raw.products;

-- 2. Grain check — returns 0 if grain is valid, >0 if duplicates exist
SELECT product_id, COUNT(*) AS n
FROM raw.products
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 10;

-- 3. Null check — add one line per column you want to check
SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS product_category_name
FROM raw.products;

-- 4. Distinct values for categorical columns (e.g. status)
SELECT product_category_name, COUNT(*) AS n
FROM raw.products
GROUP BY 1
ORDER BY n DESC;

-- 5. Fan-out check — verify join does not multiply rows
SELECT
    COUNT(DISTINCT a.product_id) AS distinct_keys,
    COUNT(a.product_id)          AS total_rows_after_join
FROM raw.products a
JOIN raw.order_items b ON a.product_id = b.product_id;
