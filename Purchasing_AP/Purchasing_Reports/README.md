# Purchasing Reports Queries

## Purpose
Comprehensive purchasing analysis, vendor performance, and procurement KPIs.

## Query Types
- Spend analysis
- Vendor performance metrics
- Purchase price variance
- Procurement cycle time
- Supplier comparison reports
- Cost savings analysis

## Available Queries

### `PUR_Purchases_By_Item.sql`
Purchase quantities from AP Invoices grouped by date and item.
- Parameters: `[%0]` Start Date, `[%1]` End Date

## Future File Names
- `PUR_RPT_Monthly_Spend_Analysis.sql`
- `PUR_RPT_Vendor_Performance_Scorecard.sql`
- `PUR_RPT_Purchase_Price_Variance.sql`
- `PUR_RPT_Top_Vendors_By_Spend.sql`
- `PUR_RPT_Procurement_Cycle_Time.sql`

## SAP B1 Tables
Common tables used:
- `OPOR` - Purchase Order Header
- `POR1` - Purchase Order Rows
- `OPCH` - AP Invoice Header
- `PCH1` - AP Invoice Rows
- `OCRD` - Business Partners (Vendors)
