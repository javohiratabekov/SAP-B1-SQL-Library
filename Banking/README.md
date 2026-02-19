# Banking Queries

## Purpose
SQL queries for bank transactions, reconciliations, statements, and cash management.

## Query Types
- Bank reconciliation reports
- Cash flow analysis
- Bank statement matching
- Outstanding checks
- Deposits in transit
- Bank balance tracking

## Available Queries

### `FIN_BNK_Cash_Turnover.sql`
Cash turnover report — incoming payments (ORCT) and outgoing payments (OVPM) combined via UNION ALL.
- Parameters: `[%0]` Start Date, `[%1]` End Date

## Future File Names
- `FIN_BNK_Reconciliation_Report.sql`
- `FIN_BNK_Outstanding_Checks.sql`
- `FIN_BNK_Cash_Flow_Daily.sql`
- `FIN_BNK_Deposits_In_Transit.sql`
- `FIN_BNK_Balance_By_Account.sql`

## SAP B1 Tables
Common tables used:
- `OBNK` - Banks
- `DSC1` - Bank Accounts
- `OBOE` - External Reconciliations
- `ORCT` - Incoming Payments
- `OVPM` - Outgoing Payments
