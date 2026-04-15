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

### `FIN_BNK_Account_Statement.sql`
Full GL account statement: opening balance, dated movements with running balance, period totals, and closing balance.
Movements respect the `U_OutgoingDate` custom field on OVPM (actual cash date); falls back to `RefDate` when absent.
Opening/closing balances use the same date logic for full reconciliation.
- Parameters: `[%0]` Start Date, `[%1]` End Date, `[%2]` GL Account Code

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
