with orders as (
  select * 
  from {{ ref('stg_orders') }}
),

final as (
    select
      order_id,
      order_status,
      (current_date > order_estimated_delivery_date) as is_at_risk
    from orders
    where order_status IN ('created', 'approved', 'invoiced', 'processing', 'shipped')
)

select * from final

/*
-- verify
SELECT 
    COUNT(*) AS total_backlog,
    SUM(CASE WHEN is_at_risk THEN 1 ELSE 0 END) AS at_risk_count
FROM dev_marts.daily_backlog_snapshot;
*/