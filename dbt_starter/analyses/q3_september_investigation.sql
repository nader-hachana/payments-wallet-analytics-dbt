-- Q3: "Something looked off in September" — investigate and quantify.
--
-- Approach: rather than eyeballing September specifically, this detects
-- "burst" behaviour for EVERY wallet across the whole year, meaning any wallet with
-- an unusually dense cluster of transactions in a short window, all
-- succeeding, spread across many merchants. That pattern (high volume + 100%
-- success + many distinct merchants in a tight window) is a classic card
-- testing / fraud signature, distinct from ordinary organic repeat purchases.
--
-- Why not a flat monthly threshold (e.g. ">=15 tx in a calendar month")? The
-- business is growing all year (Dec authorized revenue is ~63x January's), so
-- a fixed monthly count increasingly catches ordinary customers in later
-- months. A rolling 11-day window is far more robust to that growth.
--
-- Restricted to has_valid_wallet transactions only: this is a per-WALLET
-- behavioural analysis, so a transaction whose wallet_id doesn't resolve to a
-- real wallet isn't analytically meaningful here (there's no real account for
-- Risk to act on), and could in principle create a false burst signal if
-- multiple unrelated orphaned rows happened to share a broken wallet_id.

with rolling as (

    select
        wallet_id,
        transaction_id,
        merchant_id,
        merchant_segment,
        status,
        amount_eur,
        created_at,
        count(*) over (
            partition by wallet_id
            order by created_at
            range between interval 11 days preceding and current row
        ) as rolling_tx_count_11d,
        sum(case when status = 'authorized' then 1 else 0 end) over (
            partition by wallet_id
            order by created_at
            range between interval 11 days preceding and current row
        ) as rolling_authorized_count_11d,
        count(distinct merchant_id) over (
            partition by wallet_id
            order by created_at
            range between interval 11 days preceding and current row
        ) as rolling_distinct_merchants_11d
    from {{ ref('fct_transactions') }}
    where has_valid_wallet

),

peak_per_wallet as (

    select
        wallet_id,
        created_at as window_end,
        created_at - interval 11 days as window_start,
        rolling_tx_count_11d,
        rolling_authorized_count_11d,
        rolling_distinct_merchants_11d,
        row_number() over (
            partition by wallet_id order by rolling_tx_count_11d desc
        ) as rn
    from rolling

),
-- One row per wallet: its single busiest 11-day window across the whole year.
flagged_bursts as (

    select
        wallet_id,
        window_start,
        window_end,
        rolling_tx_count_11d       as tx_count,
        rolling_distinct_merchants_11d as distinct_merchants,
        round(100.0 * rolling_authorized_count_11d / rolling_tx_count_11d, 1) as authorized_pct
    from peak_per_wallet
    where rn = 1
      and rolling_tx_count_11d >= 10                           -- unusually dense
      and rolling_authorized_count_11d = rolling_tx_count_11d  -- 100% authorized, zero declines
      and rolling_distinct_merchants_11d >= 5                  -- spread across many merchants, not one repeat merchant

)

select *
from flagged_bursts
order by window_start