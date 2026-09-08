-- Q2: For each monthly signup cohort, what share of wallets activated
-- (>=1 authorized transaction within 30 days of creation)? Improving or declining?
--
-- Activation logic itself lives in dim_wallets (is_activated), computed once
-- there rather than here, so this stays a simple aggregation.
--
-- Note on the most recent cohort(s): a wallet created late in the observed
-- window hasn't necessarily had its full 30 days to activate yet if "today"
-- in this dataset is close to its signup date. We flag this explicitly rather
-- than silently reporting a misleadingly low rate for the newest cohort(s).

with cohorts as (

    select
        signup_cohort_month,
        count(*)                                    as wallets_signed_up,
        sum(case when is_activated then 1 else 0 end) as wallets_activated,
        max(created_at)                              as latest_signup_in_cohort
    from {{ ref('dim_wallets') }}
    group by 1

),

with_flag as (

    select
        *,
        round(100.0 * wallets_activated / wallets_signed_up, 1) as activation_rate_pct,
        (select max(created_at) from {{ ref('fct_transactions') }}) as data_max_date
    from cohorts

)

select
    signup_cohort_month,
    wallets_signed_up,
    wallets_activated,
    activation_rate_pct,
    (data_max_date - latest_signup_in_cohort) < interval '30 days' as cohort_still_maturing
from with_flag
order by signup_cohort_month
