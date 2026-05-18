with orders as (
  select * from {{ ref('stg_orders') }}
),

final as (
    select
      order_id,
      customer_id,
      order_status,
      order_purchase_timestamp,
      order_approved_at,
      order_delivered_carrier_date,
      order_delivered_customer_date,
      order_estimated_delivery_date,
      -- 86400 seconds = 1 day (EPOCH converts the interval to total seconds)
      extract(epoch from (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0 as fulfillment_days, 
      extract(epoch from (order_delivered_carrier_date - order_approved_at) / 86400.0) as approval_to_carrier_days,
      case when order_delivered_customer_date <= order_estimated_delivery_date then 1 else 0 end as is_delivered_on_time
    from orders
    where order_status = 'delivered'
    and order_delivered_customer_date is not null
)

select * from final