select seller_id
from {{ ref('fct_seller_order_fulfillment') }}
where seller_handoff_days < -365