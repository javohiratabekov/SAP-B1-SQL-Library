# A/R Credit Memos

SAP B1: **Sales A/R → A/R Credit Memo**

Issued to reduce amounts owed by customers — for returned goods or corrected invoices.

## Key Tables
- `ORIN` — A/R Credit Memo Header (TransType = 14)
- `RIN1` — A/R Credit Memo Lines

## Document Flow
`A/R Invoice (OINV) → A/R Credit Memo (ORIN)`

## Naming Prefix
`SAL_CRM_` — e.g., `SAL_CRM_Credit_Memo_Summary.sql`
