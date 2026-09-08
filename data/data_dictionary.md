# Data Dictionary

Three raw extracts, as they land from our ingestion layer (think "Fivetran-style"
raw tables). They are **not cleaned** — treat them the way you would treat real
source data.

All amounts are in **cents**, currency is **EUR**. All timestamps are UTC,
format `YYYY-MM-DD HH:MM:SS`. Empty string = NULL.

---

## `raw_transactions.csv`
One row per payment attempt (in principle).

| column           | type      | notes |
|------------------|-----------|-------|
| `transaction_id` | string    | Intended to be unique. |
| `wallet_id`      | string    | FK → `raw_wallets.wallet_id`. Not guaranteed to resolve. |
| `merchant_id`    | string    | FK → `raw_merchants.merchant_id`. |
| `amount_cents`   | integer   | Transaction amount in cents. |
| `currency`       | string    | Always `EUR` in this dataset. |
| `status`         | string    | One of `authorized`, `declined`, `refunded`, `reversed`. |
| `decline_reason` | string    | Populated for (most) declined attempts, else NULL. |
| `payment_method` | string    | `sdd` (SEPA Direct Debit) or `card`. |
| `created_at`     | timestamp | When the attempt was made. |

## `raw_wallets.csv`
One row per wallet (a user's payment instrument).

| column              | type      | notes |
|---------------------|-----------|-------|
| `wallet_id`         | string    | Primary key. |
| `member_id`         | string    | The person behind the wallet. May be NULL. |
| `country`           | string    | ISO country code. |
| `onboarding_method` | string    | `sdd` or `card`. |
| `marketing_channel` | string    | Acquisition channel; may be NULL. |
| `status`            | string    | `active`, `blocked`, or `churned`. |
| `created_at`        | timestamp | Wallet creation time. |

## `raw_merchants.csv`
One row per merchant.

| column          | type      | notes |
|-----------------|-----------|-------|
| `merchant_id`   | string    | Primary key. |
| `merchant_name` | string    | Display name. |
| `mcc`           | string    | Merchant Category Code. |
| `segment`       | string    | grocery, retail, restaurant, fuel, electronics, pharmacy, giftcard. |
| `country`       | string    | ISO country code. |
| `onboarded_at`  | timestamp | When the merchant went live. |

---

**Business definitions you may assume:**
- *Net revenue* = authorized transaction value **minus** refunds and reversals.
- A wallet is *activated* if it has at least one **authorized** transaction
  within **30 days** of its `created_at`.
- Declined attempts carry no revenue.
