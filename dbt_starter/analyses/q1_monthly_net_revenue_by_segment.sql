-- Q1: How has monthly net revenue developed over the year, by merchant segment?
-- Net revenue = authorized - refunds - reversals.
--
-- Note: refunds and reversals are recorded as their own transaction rows with
-- their own created_at, which may fall in a LATER month than the original
-- authorization that's why it's better to deliberately net them off in the month THEY occurred in,
-- not the month of the original purchase. I believe this matches how a finance team
-- would read a P&L (cash/accrual impact lands when the refund happens), and
-- avoids having to reconstruct original-transaction linkage that doesn't
-- exist in this data model (no parent_transaction_id).

select
    transaction_month,
    merchant_segment,
    round(sum(case when status = 'authorized' then amount_eur else 0 end), 2) as authorized_eur,
    round(sum(case when status = 'refunded'   then amount_eur else 0 end), 2) as refunded_eur,
    round(sum(case when status = 'reversed'   then amount_eur else 0 end), 2) as reversed_eur,
    round(
        sum(case when status = 'authorized' then amount_eur else 0 end)
            - sum(case when status = 'refunded' then amount_eur else 0 end)
            - sum(case when status = 'reversed' then amount_eur else 0 end),
        2
    ) as net_revenue_eur
from {{ ref('fct_transactions') }}
group by 1, 2
order by 1, 2
