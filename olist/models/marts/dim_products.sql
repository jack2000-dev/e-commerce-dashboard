with products as (
    select * from {{ ref('stg_products') }}
),

translations as (
    select * from {{ ref('stg_product_category_name_translation') }}
),

final as (
    select
        product_id,
        p.product_category_name,
        coalesce(t.product_category_name_english, 'uncategorized') as product_category_name_english,
        p.product_weight_g
    from products p
    left join translations t on p.product_category_name = t.product_category_name
)

select * from final
