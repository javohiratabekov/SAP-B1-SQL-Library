# Purchasing - A/P

SAP B1 Module: **Purchasing — Accounts Payable**

Covers the full inbound purchasing cycle from purchase request through invoice and payment.

## Sub-Modules

| Folder | SAP B1 Document | Header Table | Lines Table | TransType |
|---|---|---|---|---|
| `Purchase_Requests/` | Purchase Request | `OPRQ` | `PRQ1` | — |
| `Purchase_Quotations/` | Purchase Quotation (RFQ) | `OPQT` | `PQT1` | — |
| `Purchase_Orders/` | Purchase Order | `OPOR` | `POR1` | 22 |
| `GRPO/` | Goods Receipt PO | `OPDN` | `PDN1` | 20 |
| `AP_Invoices/` | A/P Invoice | `OPCH` | `PCH1` | 18 |
| `AP_Credit_Memos/` | A/P Credit Memo | `ORPC` | `RPC1` | 19 |
| `AP_Down_Payments/` | A/P Down Payment Invoice | `ODPO` | `DPO1` | — |
| `Purchasing_Reports/` | Analytical reports | — | — | — |

## Document Flow
`Purchase Request → Purchase Quotation → Purchase Order → GRPO → A/P Invoice`

## Naming Prefix
`PUR_` — e.g., `PUR_Open_Purchase_Orders.sql`, `PUR_Vendor_Performance.sql`
