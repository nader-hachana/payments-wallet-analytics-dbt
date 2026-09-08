# Senior Data Analyst — Take-Home Challenge

Thanks for your interest in joining our Business Intelligence & Analytics team.
Rather than a long interview loop, we use one focused, realistic task so you can
show how you actually work.

**Timebox:** please spend **no more than 3–4 hours**. We designed it to be
completable in that window. If you run short on time, prioritise — a smaller,
well-reasoned submission beats a rushed, complete-but-messy one. Tell us in your
notes what you would have done with more time.

**Tools:** everything runs **locally and license-free** on **DuckDB + dbt**
(`dbt-duckdb`). You do not need any cloud warehouse or BI licence. Use whatever
you like for the visualisation (Python/notebook, Metabase, Evidence, even a
spreadsheet) — just include the output.

**AI assistants are allowed and encouraged** — we use them daily. We care that
you understand, can defend, and stand behind every line you submit. Shortlisted
candidates may be asked to walk us through their solution.

---

## The scenario

You've joined a mobile-payments company. Wallets belong to members and are used
to pay at merchants. You're handed three **raw, uncleaned** source extracts (see
`data/data_dictionary.md`). The COO has asked BI for a first read on **commercial
performance and onboarding health**, and separately, someone in Risk has a vague
feeling that "something looked off in September."

Your job: turn the raw data into a small, trustworthy analytics layer and answer
the questions below — the way you would for a real stakeholder.

---

## Setup (≈10 min)

```bash
python -m venv .venv && source .venv/bin/activate
pip install dbt-duckdb            # brings in dbt-core + duckdb
cd dbt_starter
cp profiles.yml.example profiles.yml      # points dbt at a local .duckdb file
dbt debug                                 # should pass
dbt seed  # (optional) or load the CSVs however you prefer — see README
dbt run && dbt test
```

A minimal dbt project is provided with the sources wired up and one example
staging model. Extend it — don't feel bound by it.

---

## Part 1 — Model the data (dbt)  ·  ~1.5h

Build a clean, layered dbt project on top of the raw sources:

1. **Staging models** that type-cast, rename, and lightly clean each source.
2. At least **two mart models** that serve the analysis in Part 2 (your choice of
   grain — e.g. a transactions fact, a daily/monthly aggregate, a wallet
   dimension). Design the grain deliberately and document it.
3. Add **dbt tests** (schema and/or data tests) that you consider important.
4. Add **model + column documentation**.

The raw data is not clean. Part of the job is deciding **what to fix, what to
drop, and what to merely flag** — and making those decisions explicit.

## Part 2 — Answer the questions (SQL)  ·  ~1h

Using your models, answer:

1. **Commercial:** How has **monthly net revenue** developed over the year, broken
   down by **merchant segment**? (Net revenue = authorized − refunds − reversals.)
2. **Onboarding:** For each **monthly signup cohort** of wallets, what share
   **activated** (≥1 authorized transaction within 30 days of creation)? Is
   activation improving or declining over the year?
3. **Open-ended / judgment:** Investigate the "something looked off in September"
   hint. Surface anything you think Risk should look at, and quantify it. There is
   no single right answer — we're interested in how you reason.

## Part 3 — Communicate  ·  ~1h

Write a **one-page** summary for a **non-technical stakeholder** (imagine the COO):

- The 3–4 findings that matter, in plain language.
- **At least one chart** that makes a point (not decoration).
- A short **"data caveats & assumptions"** section: what you cleaned, what you
  chose to flag rather than fix, and how confident you are.

---

## What to submit

A single zip or a Git repo containing:

- Your **dbt project** (`dbt run && dbt test` should succeed on our machine).
- The **SQL / models** answering Part 2 (in dbt or standalone — your call).
- Your **one-page write-up** (Markdown or PDF) and the **chart(s)**.
- A short **README** with: how to run it, key assumptions, and — honestly — what
  you'd improve with more time.

## How we evaluate (so you can focus)

We look at: correctness and SQL sophistication; dbt craftsmanship (layering,
grain, tests, docs, DRY); data-quality judgment (did you notice the traps, and
handle them sensibly?); analytical thinking (right metrics, sound cohort logic);
and communication (could the COO act on your write-up?). Senior signals: clearly
stated assumptions, sensible trade-offs under a time budget, and knowing what
you'd do next.

Good luck — we're looking forward to seeing how you think.
