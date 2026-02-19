# Incoming Payments

SAP B1: **Banking → Incoming Payments**

Records money received from customers, applied against open A/R Invoices.

## Key Tables
- `ORCT` — Incoming Payment Header
- `RCT1` — Invoice links (applied invoices)
- `RCT2` — G/L account lines
- `RCT3` — Credit card lines

## Naming Prefix
`BNK_INC_` — e.g., `BNK_INC_Daily_Receipts.sql`, `BNK_INC_Unapplied_Payments.sql`
