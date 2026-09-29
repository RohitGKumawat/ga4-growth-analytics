with sessions as (
    select * from {{ ref('fct_sessions') }}
)

select
    first_touch_medium,
    date_trunc(session_date, isoweek) as session_week,
    count(*) as sessions,
    count(distinct user_pseudo_id) as users,
    countif(is_engaged) as engaged_sessions,
    countif(has_purchase) as converting_sessions,
    sum(transactions) as transactions,
    sum(revenue_usd) as revenue_usd,
    safe_divide(countif(is_engaged), count(*)) as engagement_rate,
    safe_divide(countif(has_purchase), count(*)) as conversion_rate,
    safe_divide(sum(revenue_usd), countif(has_purchase)) as revenue_per_converting_session
from sessions
group by session_week, first_touch_medium
