# Goods Issue (Manual)

SAP B1: **Inventory → Goods Issue**

Manual stock decrease not linked to a sales document — samples, scrapping, production component issues.

## Key Tables
- `OIGE` — Goods Issue Header
- `IGE1` — Goods Issue Lines

> Production issues also use OIGE/IGE1 with `DocType = 60`

## Naming Prefix
`INV_GI_` — e.g., `INV_GI_Issued_To_Production.sql`
