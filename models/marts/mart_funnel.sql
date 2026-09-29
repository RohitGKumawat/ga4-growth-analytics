-- Closed funnel: a session only counts at a step if it also hit every earlier step.
with sessions as (
    select * from {{ ref('fct_sessions') }}
),

steps as (
    select
        device_category,
        first_touch_medium,
        date_trunc(session_date, isoweek) as session_week,
        count(*) as sessions,
        countif(has_view_item) as viewed_item,
        countif(has_view_item and has_add_to_cart) as added_to_cart,
        countif(has_view_item and has_add_to_cart and has_begin_checkout) as began_checkout,
        countif(has_view_item and has_add_to_cart and has_begin_checkout and has_purchase) as purchased
    from sessions
    group by session_week, device_category, first_touch_medium
)

select
    steps.*,
    safe_divide(steps.added_to_cart, steps.viewed_item) as view_to_cart_rate,
    safe_divide(steps.began_checkout, steps.added_to_cart) as cart_to_checkout_rate,
    safe_divide(steps.purchased, steps.began_checkout) as checkout_to_purchase_rate
from steps
