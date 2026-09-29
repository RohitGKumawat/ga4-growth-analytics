-- Returns rows (= test failure) if any funnel step is larger than the step before it.
select *
from {{ ref('mart_funnel') }}
where
    added_to_cart > viewed_item
    or began_checkout > added_to_cart
    or purchased > began_checkout
