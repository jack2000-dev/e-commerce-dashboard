SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)           AS order_id_nulls,
    COUNT(*) FILTER (WHERE seller_id IS NULL)          AS seller_id_nulls,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS shipping_limit_nulls,
    COUNT(*) FILTER (WHERE price IS NULL)              AS price_nulls,
    COUNT(*) FILTER (WHERE freight_value IS NULL)      AS freight_nulls
FROM raw.order_items;
