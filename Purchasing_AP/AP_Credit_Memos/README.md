# A/P Credit Memos

SAP B1: **Purchasing A/P → A/P Credit Memo**

Issued when goods are returned to vendors or vendor invoices are corrected downward.

## Key Tables
- `ORPC` — A/P Credit Memo Header (TransType = 19)
- `RPC1` — A/P Credit Memo Lines

## Document Flow
`A/P Invoice (OPCH) → A/P Credit Memo (ORPC)`

## Naming Prefix
`PUR_CRM_` — e.g., `PUR_CRM_Vendor_Returns.sql`
