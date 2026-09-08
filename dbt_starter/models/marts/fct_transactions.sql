-- Fact table: one row per transaction (grain matches stg_transactions).
-- Enriches transactions with the merchant's segment so revenue-by-segment
-- analysis doesn't need to re-join merchants every time.
--
-- Deliberately keeps ALL transactions, including the ~1% with an unresolvable
-- wallet_id (has_valid_wallet = false), those are still real authorized/
-- declined/refunded/reversed events with real revenue impact. Dropping them
-- here would silently understate revenue. Anyone doing wallet-level analysis
-- should filter on has_valid_wallet explicitly, which is why the flag is kept
-- visible on the fact rather than hidden.

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

merchants as (

    select * from {{ ref('stg_merchants') }}

),

final as (

    select
        transactions.transaction_id,
        transactions.wallet_id,
        transactions.has_valid_wallet,
        transactions.merchant_id,
        merchants.segment           as merchant_segment,
        merchants.country           as merchant_country,
        transactions.amount_cents,
        transactions.amount_eur,
        transactions.status,
        transactions.decline_reason,
        transactions.payment_method,
        transactions.created_at,
        date_trunc('month', transactions.created_at) as transaction_month
    from transactions
    left join merchants
        on transactions.merchant_id = merchants.merchant_id

)

select * from final
