WITH source AS (
  SELECT * 
  FROM {{ source('raw', 'orders') }}
),

renamed AS (
  SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp::timestamp        as order_purchase_timestamp,
        order_approved_at::timestamp               as order_approved_at,
        order_delivered_carrier_date::timestamp    as order_delivered_carrier_date,
        order_delivered_customer_date::timestamp   as order_delivered_customer_date,
        order_estimated_delivery_date::timestamp
    FROM source
    WHERE order_id IS NOT NULL
)

SELECT * FROM renamed