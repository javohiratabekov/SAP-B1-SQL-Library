# Sales - A/R

SAP B1 Module: **Sales — Accounts Receivable**

Covers the full outbound sales cycle from quotation through invoice and credit memo.

## Sub-Modules

| Folder | SAP B1 Document | Header Table | Lines Table | TransType |
|---|---|---|---|---|
| `Quotations/` | Sales Quotation | `OQUT` | `QUT1` | 23 |
| `Sales_Orders/` | Sales Order | `ORDR` | `RDR1` | 17 |
| `Deliveries/` | Delivery Note | `ODLN` | `DLN1` | 15 |
| `AR_Invoices/` | A/R Invoice | `OINV` | `INV1` | 13 |
| `AR_Credit_Memos/` | A/R Credit Memo | `ORIN` | `RIN1` | 14 |
| `AR_Down_Payments/` | A/R Down Payment Invoice | `ODPI` | `DPI1` | — |
| `Returns/` | A/R Return | `ORDN` | `RDN1` | 16 |
| `Sales_Reports/` | Analytical reports | — | — | — |

## Document Flow
`Quotation → Sales Order → Delivery → A/R Invoice → A/R Credit Memo`

## Naming Prefix
`SAL_` — e.g., `SAL_Sales_By_Customer.sql`, `SAL_Open_Orders.sql`
