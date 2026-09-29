with sessions as (
    select
        user_pseudo_id,
        session_date,
        session_number,
        first_touch_medium
    from {{ ref('fct_sessions') }}
),

-- Only users whose first-ever session is inside the data window.
-- Without this, people who first visited before Nov 2020 would pollute the cohorts.
new_users as (
    select
        user_pseudo_id,
        date_trunc(min(session_date), isoweek) as cohort_week,
        any_value(first_touch_medium) as first_touch_medium
    from sessions
    where session_number = 1
    group by user_pseudo_id
),

weekly_activity as (
    select distinct
        user_pseudo_id,
        date_trunc(session_date, isoweek) as activity_week
    from sessions
),

cohort_sizes as (
    select
        cohort_week,
        first_touch_medium,
        count(*) as cohort_users
    from new_users
    group by cohort_week, first_touch_medium
),

cohort_activity as (
    select
        new_users.cohort_week,
        new_users.first_touch_medium,
        div(date_diff(weekly_activity.activity_week, new_users.cohort_week, day), 7) as weeks_since_first_visit,
        count(distinct weekly_activity.user_pseudo_id) as active_users
    from new_users
    inner join weekly_activity
        on new_users.user_pseudo_id = weekly_activity.user_pseudo_id
    where weekly_activity.activity_week >= new_users.cohort_week
    group by new_users.cohort_week, new_users.first_touch_medium, weeks_since_first_visit
)

select
    cohort_activity.cohort_week,
    cohort_activity.first_touch_medium,
    cohort_sizes.cohort_users,
    cohort_activity.weeks_since_first_visit,
    cohort_activity.active_users,
    safe_divide(cohort_activity.active_users, cohort_sizes.cohort_users) as retention_rate
from cohort_activity
inner join cohort_sizes
    on
        cohort_activity.cohort_week = cohort_sizes.cohort_week
        and cohort_activity.first_touch_medium = cohort_sizes.first_touch_medium
