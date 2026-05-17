-- Profiling Template
-- Replace: {schema}, {table}, {primary_key}, {col1}, {col2} with real values

-- 1. Row count
SELECT COUNT(*) AS row_count
FROM {schema}.{table};

-- 2. Grain check — returns 0 if grain is valid, >0 if duplicates exist
SELECT {primary_key}, COUNT(*) AS n
FROM {schema}.{table}
GROUP BY {primary_key}
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 10;

-- 3. Null check — add one line per column you want to check
SELECT
    COUNT(*) FILTER (WHERE {col1} IS NULL) AS {col1}_nulls,
    COUNT(*) FILTER (WHERE {col2} IS NULL) AS {col2}_nulls
FROM {schema}.{table};

-- 4. Distinct values for categorical columns (e.g. status)
SELECT {col1}, COUNT(*) AS n
FROM {schema}.{table}
GROUP BY {col1}
ORDER BY n DESC;

-- 5. Fan-out check — verify join does not multiply rows
-- Replace {other_table} and {join_key}
SELECT
    COUNT(DISTINCT a.{join_key}) AS distinct_keys,
    COUNT(a.{join_key})          AS total_rows_after_join
FROM {schema}.{table} a
JOIN {schema}.{other_table} b ON a.{join_key} = b.{join_key};
