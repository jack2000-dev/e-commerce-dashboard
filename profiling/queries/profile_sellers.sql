-- Profiling Template
-- Replace: {schema}, {table}, {primary_key}, {col1}, {col2} with real values

-- 1. Row count
SELECT COUNT(*) AS row_count
FROM raw.sellers;

-- 2. Grain check — returns 0 if grain is valid, >0 if duplicates exist
SELECT seller_id, COUNT(*) AS n
FROM raw.sellers
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 10;

-- 3. Null check — add one line per column you want to check
SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS seller_zip_code_prefix_nulls,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS seller_city_nulls,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS seller_state_nulls
FROM raw.sellers;

-- 4. Distinct values for categorical columns (e.g. status)
SELECT seller_state, COUNT(*) AS n
FROM raw.sellers
GROUP BY 1
ORDER BY n DESC;

-- 5. Fan-out check — verify join does not multiply rows
SELECT
    COUNT(DISTINCT a.seller_id) AS distinct_keys,
    COUNT(a.seller_id)          AS total_rows_after_join
FROM raw.sellers a
JOIN raw.order_items b ON a.seller_id = b.seller_id;
