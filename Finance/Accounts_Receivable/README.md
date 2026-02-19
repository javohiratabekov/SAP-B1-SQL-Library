# Accounts Receivable Queries

## Purpose
SQL queries for customer invoices, payments, aging reports, and receivables management.

## Query Types
- AR aging reports
- Customer invoice status
- Payment collections
- Outstanding balances
- Customer credit limits
- Payment application tracking

## Available Queries

### `FIN_AR_Customer_Reconciliation.sql`
Customer reconciliation statement (Акт сверки) — all journal transactions for a customer
with a running balance partitioned by currency (USD / UZS), filtering out FX rate-difference lines.
- Parameters: `[%0]` Customer Name (LIKE), `[%1]` Start Date, `[%2]` End Date

## Future File Names
- `FIN_AR_Aging_Report.sql`
- `FIN_AR_Outstanding_Invoices.sql`
- `FIN_AR_Customer_Balance.sql`
- `FIN_AR_Payment_History.sql`
- `FIN_AR_Overdue_Invoices.sql`

## SAP B1 Tables
Common tables used:
- `OINV` - AR Invoice Header
- `INV1` - AR Invoice Rows
- `ORCT` - Incoming Payments
- `RCT2` - Incoming Payments - Rows
- `OCRD` - Business Partners
