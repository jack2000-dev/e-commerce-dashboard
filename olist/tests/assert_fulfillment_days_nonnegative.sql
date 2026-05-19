select order_id
from {{ ref('fct_order_fulfillment') }}
where fulfillment_days < 0