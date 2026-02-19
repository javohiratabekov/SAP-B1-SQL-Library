# Quotations (Sales Offers)

SAP B1: **Sales A/R → Sales Quotation**

Pre-sales pricing documents sent to customers. No G/L posting — purely commercial.

## Key Tables
- `OQUT` — Quotation Header
- `QUT1` — Quotation Lines

## Document Flow
`Quotation (OQUT) → Sales Order (ORDR) → Delivery (ODLN) → A/R Invoice (OINV)`

## Naming Prefix
`SAL_QUO_` — e.g., `SAL_QUO_Open_Quotations.sql`, `SAL_QUO_Conversion_Rate.sql`
