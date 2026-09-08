"""
generate_charts.py

Regenerates both charts used in writeup/SUMMARY.md, straight from the
dbt-built DuckDB database. Run this AFTER `dbt seed && dbt run`
so dev.duckdb actually exists.

Usage (works from anywhere, paths are resolved relative to this file,
not to whatever directory you happen to run it from):
    python writeup/generate_charts.py
    # or from inside writeup/:
    python generate_charts.py

Produces (always written to the same folder this script lives in,
i.e. writeup/, regardless of your current working directory):
    monthly_net_revenue_by_segment.png
    cohort_activation_trend.png
"""

from pathlib import Path

import duckdb
import pandas as pd
import matplotlib.pyplot as plt

# Resolve both paths relative to THIS FILE's location, not the current
# working directory which makes the script safe to run from anywhere.
SCRIPT_DIR = Path(__file__).resolve().parent
DB_PATH = SCRIPT_DIR.parent / "dbt_starter" / "dev.duckdb"
OUTPUT_DIR = SCRIPT_DIR


def chart_1_revenue_by_segment(con: duckdb.DuckDBPyConnection) -> None:
    """Stacked monthly net revenue by merchant segment, with the September
    gift-card anomaly (see analyses/q3_september_investigation.sql)
    annotated directly on the chart."""

    df = con.execute(
        """
        select
            transaction_month,
            merchant_segment,
            sum(case when status = 'authorized' then amount_eur else 0 end)
                - sum(case when status = 'refunded' then amount_eur else 0 end)
                - sum(case when status = 'reversed' then amount_eur else 0 end)
                as net_revenue_eur
        from fct_transactions
        group by 1, 2
        order by 1, 2
        """
    ).df()

    df["transaction_month"] = pd.to_datetime(df["transaction_month"])
    pivot = df.pivot(
        index="transaction_month", columns="merchant_segment", values="net_revenue_eur"
    ).fillna(0)

    # Giftcard is placed last so it's the top (most visible) band in the stack
    # because it'S the segment the September annotation points at.
    seg_order = [c for c in pivot.columns if c != "giftcard"] + ["giftcard"]
    pivot = pivot[seg_order]

    month_labels = [d.strftime("%b %Y") for d in pivot.index]
    pivot = pivot.reset_index(drop=True)  # avoids a pandas datetime/period plotting bug

    fig, ax = plt.subplots(figsize=(9, 5))
    colors = plt.cm.tab20.colors
    pivot.plot(
        kind="bar",
        stacked=True,
        ax=ax,
        width=0.75,
        color=[colors[i] for i in range(len(pivot.columns))],
    )

    ax.set_title("Monthly Net Revenue by Merchant Segment", fontsize=13, fontweight="bold", pad=12)
    ax.set_xlabel("")
    ax.set_ylabel("Net revenue (EUR)")
    ax.set_xticklabels(month_labels, rotation=45, ha="right")
    ax.legend(title="Segment", bbox_to_anchor=(1.02, 1), loc="upper left", fontsize=9)
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"{x/1000:,.0f}k"))

    sep_idx = month_labels.index("Sep 2025")
    sep_total = pivot.iloc[sep_idx].sum()
    ax.annotate(
        "Gift card revenue spike\n(38% traced to 5 wallets,\nsee Sept investigation)",
        xy=(sep_idx, sep_total),
        xytext=(sep_idx - 3.2, sep_total + 100_000),
        fontsize=8.5,
        ha="left",
        arrowprops=dict(arrowstyle="->", color="#333333", lw=1.2),
    )

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / "monthly_net_revenue_by_segment.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


def chart_2_activation_trend(con: duckdb.DuckDBPyConnection) -> None:
    """30-day activation rate by signup cohort, with the still-maturing
    December cohort called out explicitly rather than left to look like a
    real decline."""

    df = con.execute(
        """
        select
            signup_cohort_month,
            count(*) as wallets_signed_up,
            sum(case when is_activated then 1 else 0 end) as wallets_activated
        from dim_wallets
        group by 1
        order by 1
        """
    ).df()
    df["activation_rate_pct"] = 100.0 * df["wallets_activated"] / df["wallets_signed_up"]
    df["signup_cohort_month"] = pd.to_datetime(df["signup_cohort_month"])
    month_labels = [d.strftime("%b") for d in df["signup_cohort_month"]]

    fig, ax = plt.subplots(figsize=(6.5, 3))
    ax.plot(range(len(df)), df["activation_rate_pct"], marker="o", color="#2b6cb0", linewidth=2)

    # Highlight December distinctly since it hasn't had its full 30-day window yet.
    ax.plot(
        len(df) - 1,
        df["activation_rate_pct"].iloc[-1],
        marker="o",
        color="#e07b39",
        markersize=9,
        zorder=5,
    )
    ax.annotate(
        "Dec cohort still\nmaturing (<30 days\nof data)",
        xy=(len(df) - 1, df["activation_rate_pct"].iloc[-1]),
        xytext=(len(df) - 4.3, df["activation_rate_pct"].iloc[-1] - 18),
        fontsize=8,
        arrowprops=dict(arrowstyle="->", color="#666666", lw=1),
    )

    ax.set_title("30-Day Activation Rate by Signup Cohort", fontsize=12, fontweight="bold")
    ax.set_ylabel("Activation rate (%)")
    ax.set_xticks(range(len(df)))
    ax.set_xticklabels(month_labels)
    ax.set_ylim(40, 95)
    ax.grid(axis="y", alpha=0.3)
    for spine in ["top", "right"]:
        ax.spines[spine].set_visible(False)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / "cohort_activation_trend.png", dpi=150, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    if not DB_PATH.exists():
        raise FileNotFoundError(
            f"Couldn't find {DB_PATH}. Run `dbt seed && dbt run` inside "
            f"dbt_starter/ first, so dev.duckdb actually gets built."
        )
    con = duckdb.connect(str(DB_PATH))
    chart_1_revenue_by_segment(con)
    print(f"wrote {OUTPUT_DIR / 'monthly_net_revenue_by_segment.png'}")
    chart_2_activation_trend(con)
    print(f"wrote {OUTPUT_DIR / 'cohort_activation_trend.png'}")
    con.close()


if __name__ == "__main__":
    main()