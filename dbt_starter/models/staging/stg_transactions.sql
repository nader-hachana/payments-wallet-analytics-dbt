-- Staging model for transactions.
-- Two data-quality issues found in the raw source, handled explicitly:
--   1. Exact duplicate rows (373 of them), might be an ingestion replay
--      (e.g. a webhook fired twice), not two distinct payment attempts. We dedupe
--      to one row per transaction_id.
--   2. wallet_id does not always resolve to raw_wallets (743 rows). The data
--      dictionary confirms this is expected ("not guaranteed to resolve"). We do
--      NOT drop these because that would silently understate revenue so we flag them
--      instead with has_valid_wallet, so downstream models can decide how to
--      treat them per-analysis rather than losing the transaction.

with source as (

    select * from {{ source('raw', 'raw_transactions') }}

),

deduplicated as (

    -- Keep one row per transaction_id. The duplicate records in this dataset are
    -- exact copies (confirmed during exploration), so DISTINCT would produce the
    -- same result. I used row_number() instead because it makes the intent clearer
    -- and provides a more flexible approach if future data contains near-duplicates.
    select
        *,
        row_number() over (
            partition by transaction_id, wallet_id, merchant_id, amount_cents,
                         status, payment_method, created_at
            order by created_at
        ) as _dedup_rank
    from source

),

renamed as (

    select
        transaction_id,
        wallet_id,
        merchant_id,
        cast(amount_cents as integer)      as amount_cents,
        amount_cents / 100.0               as amount_eur,
        currency,
        status,
        nullif(decline_reason, '')         as decline_reason,
        payment_method,
        cast(created_at as timestamp)      as created_at
    from deduplicated
    where _dedup_rank = 1

),

flagged as (

    -- Referencing stg_wallets (not the raw source) here on purpose because staging
    -- models should only ever look "sideways" at other staging models via
    -- ref() and never reach past them into a different raw source to keep the
    -- dependency graph honest
    select
        renamed.*,
        wallets.wallet_id is not null as has_valid_wallet
    from renamed
    left join {{ ref('stg_wallets') }} as wallets
        on renamed.wallet_id = wallets.wallet_id

)

select * from flagged
