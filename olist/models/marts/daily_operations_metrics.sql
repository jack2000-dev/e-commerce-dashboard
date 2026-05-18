with orders as (
  select * 
  from {{ ref('stg_orders') }}
),

final as (
    select
      date_trunc('day', order_purchase_timestamp) as order_day,
      count(*) filter (where order_purchase_timestamp is not null) as purchased_orders,
      count(*) filter (where order_delivered_carrier_date is not null) as shipped_day,
      count(*) filter (where order_delivered_customer_date is not null) as delivered_day
    from orders
    group by 1
)

select * from final

/*
-- verify
SELECT *
FROM dev_marts.daily_operations_metrics
ORDER BY order_day DESC
LIMIT 5;
*/