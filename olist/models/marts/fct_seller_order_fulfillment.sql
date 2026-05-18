with order_items as (
  select * 
  from {{ ref('stg_order_items') }}
),

orders as (
  select * from {{ ref('stg_orders') }}
),

final as (
    select
      oi.order_id,
      oi.seller_id,
      oi.shipping_limit_date,
      o.order_delivered_carrier_date,
      case when o.order_delivered_carrier_date <= oi.shipping_limit_date then 1 else 0 end as is_seller_handoff_on_time
from order_items oi
join orders o on oi.order_id = o.order_id
where o.order_delivered_carrier_date is not null
  and oi.shipping_limit_date is not null
)

select * from final

/*
-- verify
SELECT
    COUNT(*) AS row_count,
    ROUND(AVG(is_seller_handoff_on_time)::numeric, 3) AS seller_on_time_rate
FROM dev_marts.fct_seller_order_fulfillment;
*/