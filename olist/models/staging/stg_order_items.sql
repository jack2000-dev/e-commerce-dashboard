WITH source AS (
    SELECT * FROM {{ source('raw', 'order_items') }}
),

renamed AS (
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date::timestamp  as shipping_limit_date,
        price::numeric                  as price, -- Use numeric for currency, real(float) will overload
        freight_value::numeric          as freight_value
    FROM source
    WHERE order_id IS NOT NULL
)

SELECT * FROM renamed


