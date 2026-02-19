# Goods Receipt (Manual)

SAP B1: **Inventory → Goods Receipt**

Manual stock increase not linked to a purchasing document — opening stock, production output, adjustments.

## Key Tables
- `OIGN` — Goods Receipt Header
- `IGN1` — Goods Receipt Lines

> Production receipts also use OIGN/IGN1 with `DocType = 59`

## Naming Prefix
`INV_GR_` — e.g., `INV_GR_Daily_Receipts.sql`
