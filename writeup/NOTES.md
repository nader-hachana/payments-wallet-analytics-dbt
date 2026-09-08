# Build Notes

How to run this project, key assumptions, and what I'd do with more time.

## How to run this

```bash
cd dbt_starter
python -m venv .venv && source .venv/bin/activate
pip install dbt-duckdb pandas matplotlib
cp profiles.yml.example profiles.yml
dbt seed          # loads the three raw CSVs
dbt run           # builds staging + mart models
dbt test          # runs 26 tests: 25 pass, 1 expected warning (see note below)
```

**Note on the warning:** one test of `relationships` check on `wallet_id`
is deliberately configured as `severity: warn`, not a hard failure. It flags
740 transactions whose `wallet_id` doesn't resolve to a known wallet, which is
expected per the data dictionary ("not guaranteed to resolve"), not a bug. It's
there so a *future* spike in that count would be visible, without failing the
build on the known, accepted baseline.

To reproduce the Part 2 SQL answers:

```bash
dbt compile --select q1_monthly_net_revenue_by_segment
dbt compile --select q2_cohort_activation_trend
dbt compile --select q3_september_investigation
```

Each `.sql` file lives in `dbt_starter/analyses/` and compiles with `ref()` resolved. I ran the compiled SQL directly against `dev.duckdb` (via the Python `duckdb` library) to get the result tables used in `writeup/SUMMARY.md`, dbt's `analyses/` folder compiles but doesn't execute automatically.

To reproduce the two charts in the write-up:

```bash
# after dbt seed && dbt run 
cd ../writeup
python generate_charts.py
```

This regenerates `monthly_net_revenue_by_segment.png` and `cohort_activation_trend.png` directly from the DuckDB tables dbt built, always into `writeup/` regardless of where you run it from. I used plain Python (`duckdb` + `pandas` + `matplotlib`) rather than a dashboarding tool since this was a one-time static write-up, not something that needed to stay live, for an ongoing report I'd reach for Metabase/Looker/Evidence instead.

## Project layout

```
dbt_starter/
  models/
    staging/       stg_transactions, stg_wallets, stg_merchants
    marts/          fct_transactions (grain: 1 row/transaction)
                     dim_wallets (grain: 1 row/wallet)
  analyses/         q1, q2, q3: the Part 2 SQL questions
writeup/
  SUMMARY.md            one-page write-up for the COO
  generate_charts.py    regenerates both PNGs from the dbt-built database
  *.png                 the two charts referenced in the write-up
```

## Key assumptions (see also the caveats section in SUMMARY.md)

- **373 exact duplicate transaction rows** in the raw data were treated as ingestion duplicates and removed in staging, not two real payment attempts.
- **743 transactions in the raw data (~1%) have a wallet_id that doesn't resolve** to a known wallet, 740 remain after deduplication (3 of the 373 removed duplicate rows were themselves copies of already-orphaned transactions). I kept these in revenue-facing models (dropping them would understate real revenue) but flag them with `has_valid_wallet`, and exclude them from anything wallet-level.
- **Net revenue nets refunds/reversals off in the month they occur**, not the month of the original transaction, the data has no link back to an original transaction (no parent_transaction_id).
- **Activation logic** (≥1 authorized transaction within 30 days of wallet creation) only needs each wallet's *earliest* authorized transaction, if that one falls outside 30 days, no later one could fall inside it either, so I compare a single `min(created_at)` instead of a per-transaction windowed check. Same answer, simpler SQL.
- **The September "burst detector"** (Q3) is a general rolling-11-day-window query across the whole year, not a query written around the 5 wallets I discovered, it surfaces both the September cluster and a structurally different December cluster, and the write-up explains why I read them differently (synchronized single-day start vs. staggered over a month that lines up with real holiday seasonality).

## What I'd do with more time

- Turn the Q3 burst-detector logic into a proper dbt model (maybe `mart_wallet_velocity_flags`) with its own tests, so Risk could run it continuously rather than as a one-off investigation.
- Dig into *why* 743 transactions have an orphaned wallet_id is it one integration, one date range, one payment method? I only quantified and flagged it, didn't root-cause it.
- Add a merchant and country level cut to the September investigation. I stopped once the wallet-level pattern was clear and well quantified, but didn't check whether specific merchants were disproportionately hit.
- Write a dbt test that would catch a *future* recurrence of the September pattern automatically (e.g. flagging any wallet whose rolling 11-day authorized count crosses a threshold), rather than leaving this as a manual, one-time investigation.
- I'd have liked to validate the "373 duplicates = ingestion issue" hypothesis against real source-system logs rather than inferring it purely from the data shape, I don't have access to that here, so I stated it as an assumption rather than a confirmed fact.