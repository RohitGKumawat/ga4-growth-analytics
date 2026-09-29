# GA4 Growth Analytics (BigQuery + dbt)

![ci](https://github.com/RohitGKumawat/ga4-growth-analytics/actions/workflows/ci.yml/badge.svg)

This is a self-directed analytics engineering project built on Google's public GA4 ecommerce export (the
Google Merchandise Store demo data). It takes raw nested event data, turns it into tested dbt models in
BigQuery, and ends in three growth marts that answer a business question.

**Stack:** BigQuery · dbt Core 1.12 · SQL · sqlfluff · GitHub Actions · Looker Studio

**Data:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce`. It has 92 daily tables (1 Nov 2020 – 31 Jan 2021)
with 4,295,584 events. After modelling, that becomes **360,129 sessions** from **270,154 users**.

## The question

> An ecommerce store wants to know where it loses customers and which acquisition channels are worth investing in.
>
> 1. Where in the purchase journey do sessions drop off, and does it differ by device?
> 2. Which acquisition channels drive sessions that convert and generate revenue?
> 3. Do new users come back, and does that depend on how they first found the site?

Every model in the project serves one of these three questions.

## Key findings

**Headline numbers (Nov 2020 – Jan 2021):** 360,129 sessions · 88.9% engaged · 1.35% of sessions purchase ·
$362,165 revenue.

### 1. The biggest leak is product page → cart, and it's the same on every device

Closed funnel over all 360,129 sessions:

| Step | Sessions | Step conversion |
|---|---:|---:|
| Session | 360,129 | |
| Viewed an item | 77,020 | 21.4% |
| Added to cart | 15,173 | 19.7% of viewers |
| Began checkout | 5,959 | 39.3% of carts |
| Purchased | 2,848 | 47.8% of checkouts |

About 80% of sessions that view a product never add it to the cart. Once someone has a cart, roughly half of
the remaining steps convert. Device makes almost no difference. Session-to-purchase is 0.82% on mobile,
0.77% on desktop and 0.77% on tablet, and view-to-cart is 19.9%, 19.6% and 18.9%. **What to do:** investigate
the product page itself (price, stock, delivery information, the add-to-cart CTA) rather than a
mobile-specific UX fix.

### 2. Referral looks like the best channel, but almost half of it is the store referring itself

| First-touch medium | Sessions | Conversion rate | Revenue | Revenue / session |
|---|---:|---:|---:|---:|
| organic | 122,841 | 1.10% | $104,007 | $0.85 |
| referral | 63,524 | 1.66% | $83,521 | $1.31 |
| (none) — direct | 83,459 | 1.29% | $79,650 | $0.95 |
| (data deleted) | 22,629 | 3.12% | $50,461 | $2.23 |
| &lt;Other&gt; | 52,058 | 0.97% | $35,470 | $0.68 |
| cpc — paid search | 15,618 | 0.98% | $9,056 | $0.58 |

At face value, referral converts at 1.66% against 1.10% for organic and earns $1.31 per session against
$0.85. However, about 44% of referral users in the raw data come from `shop.googlemerchandisestore.com`,
which is the store's own domain. That is a self-referral, typically caused by a checkout or payment redirect,
so it inflates referral's conversion rate. **What to do:** add the store's own domain to GA4's unwanted
referrals list first, then re-rank channels. Paid search has the lowest revenue per session ($0.58). It
brings 4.3% of sessions but only 2.5% of revenue, so it's the first budget line to review. The
`(data deleted)` row has the highest conversion rate, but the dataset's obfuscation hides its source, so it
can't be acted on.

### 3. Few new users come back, acquisition channel doesn't change that, but timing does

- **Return rate:** 3.8% of new users return in their second week (week 1), 1.5% in week 2 and 0.9% in week 4.
  These rates are pooled across every cohort that has that much follow-up.
- **By channel:** week-1 retention is between 3.6% and 3.9% for every channel with more than 10,000 new
  users. So the channel that acquired a user doesn't predict whether they return.
- **By acquisition week:** cohorts that arrived between 2 and 30 November retain at 4.2–5.7% in week 1.
  December cohorts (7–28 Dec) retain at only 2.4–3.1%, and January cohorts recover to 3.2–4.0%. Holiday
  shoppers look like one-off gift buyers.

**What to do:** don't choose channels on retention. Instead, target users acquired in December with a
re-engagement campaign in January.

## How it's built

![Lineage](docs/lineage.png)

```
bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*   (raw, 92 daily tables)
        │
        ▼
stg_ga4__events              VIEW   one row per event; params flattened, placeholders cleaned
        │
        ▼
fct_sessions                 TABLE  one row per session: device, channel, engagement, funnel flags, revenue
        │
        ├──► mart_funnel               TABLE  weekly closed funnel by device and first-touch medium
        ├──► mart_channel_performance  TABLE  weekly sessions, engagement, conversion, revenue by medium
        └──► mart_cohort_retention     TABLE  weekly new-user retention by cohort week and medium
```

**Staging (`stg_ga4__events`)**
- The model reads every daily table through the `events_*` wildcard and filters on `_table_suffix`.
  BigQuery only scans the dates in `start_date`/`end_date`, which are dbt vars, so development runs cover
  one week and cost very little.
- A `ga4_param()` macro pulls typed values out of the nested `event_params` array, so the extraction logic
  lives in one place.
- NULL and empty-string dimensions are normalised to `(not set)`, so joins and group-bys don't silently
  drop rows.
- It's materialised as a view, which uses no storage.

**Fact (`fct_sessions`)**
- The grain is one row per session. A session is `user_pseudo_id` + `ga_session_id`, because
  `ga_session_id` alone isn't unique across users.
- `logical_or` collapses each funnel event into a true/false flag per session.
- Device and country come from the session's first event, so a session can never be counted under two
  devices.
- The table is clustered on `first_touch_medium` and `device_category` rather than partitioned. The
  BigQuery sandbox expires partitions based on their own date, so 2020 partitions would disappear
  immediately.

**Marts**
- **Funnel:** the funnel is *closed*. A session only counts at a step if it also hit every earlier step.
- **Channels:** raw counts are stored next to rates, so rates can be recomputed correctly when rows are
  combined. Averaging rates across rows gives the wrong answer.
- **Cohorts:** only users whose first-ever session (`session_number = 1`) falls inside the data window
  enter a cohort (261,148 users). This stops someone who first visited in October from looking like a
  November newcomer.

## Data quality

Everything was profiled before modelling. The queries and results are in
[`notes/data_profile.md`](notes/data_profile.md).

| Check | Result | What I did |
|---|---|---|
| Events without `ga_session_id` | 0 of 4,295,584 | Nothing is lost when `fct_sessions` drops session-less events. |
| `session_engaged` value type (one day sampled) | String in 21,601 rows, integer in 2,582 | Staging reads both columns and coalesces them. |
| Channel placeholders | `<Other>` and `(data deleted)` from Google's obfuscation | Kept as their own groups rather than dropped, and called out in the findings. |
| Purchases with no view_item / add_to_cart | 150 and 2,000 of 4,848 purchasing sessions | This is why the funnel is closed. 2,848 sessions complete every tracked step. |
| Purchase events vs transaction IDs | 5,692 purchase events, 4,452 distinct IDs, 906 missing or `(not set)` | Revenue is **not yet deduplicated** by `transaction_id` (see Limitations). |
| Unexpected device values | Only desktop, mobile and tablet occur | The `accepted_values` warning never fires. |
| **Session reconciliation** | 26,331 sessions (1–7 Jan 2021) in both the raw export and `fct_sessions` | Exact match, so everything downstream rests on a verified session count. |

## Testing and CI

There are **8 data tests**, and all of them pass on the full three-month build.

| Test | Type | What it protects |
|---|---|---|
| `not_null` on `event_name` and `user_pseudo_id` | generic | Staging never emits events that can't be attributed. |
| `unique` + `not_null` on `session_key` | generic | The fact table's grain is exactly one row per session. |
| `accepted_values` on `device_category` (warn) | generic | Flags unexpected devices without blocking the build. |
| `assert_funnel_never_increases` | singular | Guards the closed-funnel logic: no step can be larger than the step before it. |
| `assert_retention_is_valid` | singular | Week 0 must be 100% and no rate can exceed 100%. This catches fan-out joins and week-arithmetic bugs. |
| `assert_revenue_reconciles` | singular | The channel mart accounts for the same revenue as `fct_sessions`, within $0.01. |

**CI:** GitHub Actions runs on every pull request and on every push to `main`.

- `sqlfluff lint .` checks the BigQuery dialect and lower-case keywords.
- `dbt parse` runs against a dummy profile, so CI needs no Google credentials.

CI doesn't execute the models against BigQuery. Every change was made on its own branch and merged through
a PR.

## Limitations

- **Obfuscated demo data.** Google deliberately obfuscates this dataset, so the findings are illustrative
  and don't describe the real store's performance.
- **Revenue isn't deduplicated.** Revenue is summed per purchase event. The raw data has more purchase
  events (5,692) than distinct transaction IDs (4,452), so revenue may be overstated. `transactions` is
  counted as distinct IDs per session.
- **First-touch attribution only.** `first_touch_medium` is the channel that first acquired the user, not
  the channel of each session. That fits the cohort analysis but is a simplification in the channel mart.
- **Right-censoring.** Later cohorts have less follow-up, so week-N retention is only compared across
  cohorts that have week N. The first cohort week (26 Oct) contains a single day (1 Nov), so it's partial.
- **Full rebuilds only.** The BigQuery sandbox has no DML (MERGE), so there are no incremental models.

## What I'd do next

- Deduplicate purchases by `transaction_id` in `fct_sessions`, and add a uniqueness test on transactions.
- Exclude self-referrals, add session-scoped source/medium, and compare the results with first-touch
  attribution.
- Build incremental models (MERGE with a lookback window for late events) on a billed project.
- Run `dbt build` in CI against a dev dataset with a service account, and add source freshness checks.
- Build an item-level product funnel from the `items` array, to find which products leak at view → cart.

## Run it yourself

Prerequisites: Python 3.12, a Google Cloud project (the free BigQuery sandbox is enough) and the
`gcloud` CLI.

```bash
git clone https://github.com/RohitGKumawat/ga4-growth-analytics.git
cd ga4-growth-analytics
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
gcloud auth application-default login
```

Create `~/.dbt/profiles.yml`. It lives outside the repo, so credentials are never committed. Your dataset
must be in `US`, because the public dataset is.

```yaml
ga4_growth:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: YOUR_PROJECT_ID
      dataset: ga4_growth
      location: US
      threads: 4
```

```bash
dbt debug                                                          # connection check
dbt build --vars "{start_date: '20210101', end_date: '20210107'}"  # cheap one-week build
dbt build                                                          # full Nov 2020 – Jan 2021 build
```
