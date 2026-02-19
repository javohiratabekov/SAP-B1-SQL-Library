# Budget

SAP B1: **Financials → Budget**

Defines and tracks financial budgets against actual G/L postings by account and period.

## Key Tables
- `OBGT` — Budget Header (scenario + fiscal year)
- `BGT1` — Budget Lines (account + period amounts)
- `OFPR` — Fiscal Periods
- `OACT` — G/L Accounts (for actual vs budget comparison)

## Common Queries
- Budget vs Actual by G/L account
- Budget utilization % per period
- Remaining budget per department

## Naming Prefix
`FIN_BGT_` — e.g., `FIN_BGT_Actual_Vs_Budget.sql`
