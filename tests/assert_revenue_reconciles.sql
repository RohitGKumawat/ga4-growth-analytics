-- The channel mart must account for the same revenue as the sessions fact table.
with fct as (
    select sum(revenue_usd) as revenue from {{ ref('fct_sessions') }}
),

mart as (
    select sum(revenue_usd) as revenue from {{ ref('mart_channel_performance') }}
)

select
    fct.revenue as fct_revenue,
    mart.revenue as mart_revenue
from fct
cross join mart
where abs(fct.revenue - mart.revenue) > 0.01
