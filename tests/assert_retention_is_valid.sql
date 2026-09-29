-- Week 0 must be 100% (everyone is active in the week they arrive), and no rate can exceed 100%.
select *
from {{ ref('mart_cohort_retention') }}
where
    (weeks_since_first_visit = 0 and retention_rate != 1)
    or retention_rate > 1
