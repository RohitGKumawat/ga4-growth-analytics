with source as (
    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'
),

renamed as (
    select
        event_name,
        user_pseudo_id,
        -- obfuscated data uses NULL and '' as placeholders; normalise so joins and group-bys don't silently drop rows
        coalesce(nullif(device.category, ''), '(not set)') as device_category,
        coalesce(nullif(geo.country, ''), '(not set)') as country,
        coalesce(nullif(traffic_source.source, ''), '(not set)') as first_touch_source,
        coalesce(nullif(traffic_source.medium, ''), '(not set)') as first_touch_medium,
        ecommerce.transaction_id,
        ecommerce.purchase_revenue_in_usd as purchase_revenue_usd,
        parse_date('%Y%m%d', event_date) as event_date,
        timestamp_micros(event_timestamp) as event_ts,
        {{ ga4_param('ga_session_id', 'int') }} as ga_session_id,
        {{ ga4_param('ga_session_number', 'int') }} as ga_session_number,
        {{ ga4_param('page_location') }} as page_location,
        {{ ga4_param('engagement_time_msec', 'int') }} as engagement_time_msec,
        -- GA4 stores session_engaged inconsistently (string in some rows, int in others)
        (
            select coalesce(ep.value.string_value, cast(ep.value.int_value as string))
            from unnest(event_params) as ep
            where ep.key = 'session_engaged'
        ) as session_engaged
    from source
)

select
    renamed.*,
    concat(renamed.user_pseudo_id, '-', cast(renamed.ga_session_id as string)) as session_key
from renamed