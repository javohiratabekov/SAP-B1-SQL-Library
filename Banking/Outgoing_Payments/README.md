# Outgoing Payments

SAP B1: **Banking → Outgoing Payments**

Records payments made to vendors, applied against open A/P Invoices.

## Key Tables
- `OVPM` — Outgoing Payment Header
- `VPM1` — Invoice links (applied invoices)
- `VPM2` — G/L account lines

## Naming Prefix
`BNK_OUT_` — e.g., `BNK_OUT_Payment_Run.sql`, `BNK_OUT_Vendor_Payment_History.sql`
