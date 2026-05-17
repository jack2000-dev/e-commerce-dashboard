SELECT order_id, COUNT(*) AS payment_rows
FROM raw.order_payments
GROUP BY order_id
ORDER BY payment_rows DESC
LIMIT 10;

-- Row count and distinct payment types
SELECT payment_type, COUNT(*) AS n
FROM raw.order_payments
GROUP BY payment_type
ORDER BY n DESC;

-- Does payment_value have nulls or negatives?
SELECT
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_values,
    COUNT(*) FILTER (WHERE payment_value < 0)     AS negative_values
FROM raw.order_payments;
