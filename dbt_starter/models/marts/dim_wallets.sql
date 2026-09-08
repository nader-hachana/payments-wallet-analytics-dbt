-- Dimension table: one row per wallet (grain matches stg_wallets).
-- Adds two derived attributes needed for the onboarding/cohort analysis:
--   - signup_cohort_month: the calendar month the wallet was created in.
--   - is_activated: per the business definition in the data dictionary, true
--     if the wallet has at least one AUTHORIZED transaction within 30 days of
--     creation.
--
-- Activation logic: we only need the wallet's EARLIEST authorized transaction.
-- If that one falls outside the 30-day window then no later authorized transaction
-- could fall inside it either, so comparing just the minimum timestamp is
-- simpler than a windowed exists-check per transaction.

with wallets as (

    select * from {{ ref('stg_wallets') }}

),

first_authorized_transaction as (

    select
        wallet_id,
        min(created_at) as first_authorized_at
    from {{ ref('stg_transactions') }}
    where status = 'authorized'
    group by wallet_id

),

final as (

    select
        wallets.wallet_id,
        wallets.member_id,
        wallets.country,
        wallets.onboarding_method,
        wallets.marketing_channel,
        wallets.status,
        wallets.created_at,
        date_trunc('month', wallets.created_at) as signup_cohort_month,
        first_authorized.first_authorized_at,
        coalesce(
            first_authorized.first_authorized_at <= wallets.created_at + interval '30 days',
            false
        ) as is_activated
    from wallets
    left join first_authorized_transaction as first_authorized
        on wallets.wallet_id = first_authorized.wallet_id

)

select * from final
