# Stock Transfer

SAP B1: **Inventory → Inventory Transfers**

Move stock between warehouses or bin locations within the same company.

## Key Tables
- `OWTR` — Stock Transfer Header (TransType = 162)
- `WTR1` — Stock Transfer Lines

## Naming Prefix
`INV_TRF_` — e.g., `INV_TRF_Transfer_History.sql`, `INV_TRF_Pending_Transfers.sql`
