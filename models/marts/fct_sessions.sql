{{ config(cluster_by=['first_touch_medium', 'device_category']) }}

with events as (
    select *
    from {{ ref('stg_ga4__events') }}
    where ga_session_id is not null
)

select
    session_key,
    user_pseudo_id,
    min(event_date) as session_date,
    min(event_ts) as session_start_ts,
    max(ga_session_number) as session_number,
    array_agg(device_category ignore nulls order by event_ts limit 1)[safe_offset(0)] as device_category,
    array_agg(country ignore nulls order by event_ts limit 1)[safe_offset(0)] as country,
    any_value(first_touch_source) as first_touch_source,
    any_value(first_touch_medium) as first_touch_medium,
    countif(event_name = 'page_view') as page_views,
    logical_or(session_engaged = '1') as is_engaged,
    sum(coalesce(engagement_time_msec, 0)) / 1000 as engagement_time_sec,
    logical_or(event_name = 'view_item') as has_view_item,
    logical_or(event_name = 'add_to_cart') as has_add_to_cart,
    logical_or(event_name = 'begin_checkout') as has_begin_checkout,
    logical_or(event_name = 'purchase') as has_purchase,
    count(distinct if(event_name = 'purchase', transaction_id, null)) as transactions,
    sum(if(event_name = 'purchase', coalesce(purchase_revenue_usd, 0), 0)) as revenue_usd
from events
group by session_key, user_pseudo_id
