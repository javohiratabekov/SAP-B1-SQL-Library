# Financials

SAP B1 Module: **Financials**

Covers all financial accounting: general ledger, accounts receivable, accounts payable, budget management, and financial reporting.

## Sub-Modules

| Folder | SAP B1 Feature | Key Tables |
|---|---|---|
| `General_Ledger/` | Chart of Accounts, Journal Entries | `OACT`, `OJDT`, `JDT1` |
| `Accounts_Receivable/` | Customer invoices, reconciliation | `OINV`, `INV1`, `JDT1` |
| `Accounts_Payable/` | Vendor invoices, aging | `OPCH`, `PCH1`, `JDT1` |
| `Budget/` | Budget definitions and tracking | `OBGT`, `BGT1` |
| `Financial_Reports/` | P&L, Balance Sheet, Trial Balance | `OACT`, `JDT1`, `OFPR` |

## Naming Prefix
`FIN_` — e.g., `FIN_GL_Trial_Balance.sql`, `FIN_AR_Aging_Report.sql`
