# Payments Wallet Analytics (dbt + DuckDB)

A small analytics layer over synthetic mobile-wallet payment data, raw
transaction/wallet/merchant extracts turned into a clean, tested dbt project,
then used to answer three real analytical questions for a non-technical
stakeholder.

Runs entirely locally, DuckDB as the warehouse, no cloud, no license.

## Key findings

- **Net revenue grew roughly 60x over the year** (€25,334 in January to
  €1,529,520 in December), broadly across every merchant segment, not just
  one or two.
- **Onboarding activation improved steadily**, from 49.5% of new wallets
  activating within 30 days in January to 88.9% in November.
- **A September gift-card spike is worth a second look**: 5 wallets with
  otherwise ordinary activity suddenly made 131 transactions in under two
  weeks, 100% success rate, spread across 23 merchants, accounting for 38%
  of that month's entire Gift Card revenue growth. Full reasoning and the
  fraud-pattern hypothesis in `writeup/SUMMARY.md`.

Full write-up, charts, and data caveats: [`writeup/SUMMARY.md`](writeup/SUMMARY.md).
Original problem statement: [`CHALLENGE.md`](CHALLENGE.md).
How to run everything, key assumptions, and what I'd do next: [`writeup/NOTES.md`](writeup/NOTES.md).

## Quick start

```bash
python -m venv .venv && source .venv/bin/activate
pip install dbt-duckdb pandas matplotlib

cd dbt_starter
cp profiles.yml.example profiles.yml
dbt seed          # loads the three raw CSVs (320 merchants, 6,000 wallets, 75,149 transactions)
dbt run           # builds staging + mart models
dbt test          # 26 tests: 25 pass, 1 expected warning, see writeup/NOTES.md
```

## Project layout

```
CHALLENGE.md            the original problem statement
data/                    the three raw CSVs + data dictionary
dbt_starter/
  models/
    staging/             stg_transactions, stg_wallets, stg_merchants
    marts/               fct_transactions (grain: 1 row/transaction)
                         dim_wallets (grain: 1 row/wallet)
  analyses/               q1, q2, q3, the three analytical questions as SQL
  seeds/                  same raw CSVs, loaded via dbt seed
writeup/
  SUMMARY.md              one-page findings write-up for a non-technical stakeholder
  NOTES.md                how to run everything, assumptions, what I'd do next
  generate_charts.py      regenerates both PNGs from the dbt-built database
  *.png                   the two charts referenced in the write-up
```
