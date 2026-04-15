# Inventory Reports Queries

## Purpose
Comprehensive inventory reporting, analytics, and KPI tracking.

## Available Queries

### 1. `INV_RPT_Movement_Report_CTE.sql` *(recommended)*
Inventory movement report using CTEs for optimal performance:
- Opening balance, production receipts, sales, returns, closing balance
- Flexible item name filter via parameter
- Parameters: `[%0]` Item Name (LIKE), `[%1]` Start Date, `[%2]` End Date, `[%3]` Warehouse Code

### 2. `INV_RPT_Movement_Report.sql`
Same report using correlated subqueries. Hardcoded for BabyBoo UltraSoft items.
Use this as reference; prefer the CTE version for performance.
- Parameters: `[%1]` Start Date, `[%2]` End Date, `[%3]` Warehouse Code

### 3. `INV_RPT_Stock_Aging_By_Warehouse.sql`
Slow-moving stock aging by warehouse using last inventory movement date:
- Returns only items with current stock (`OnHand > 0`)
- Calculates days stayed in warehouse as of selected date
- Classifies stock into configurable aging periods
- Parameters:
  - `[%0]` Warehouse Code filter (`%` for all warehouses)

## Query Types
- Inventory movement tracking
- Opening / closing balance analysis
- Production vs. sales comparison
- Return tracking
- Stock variance analysis
- Inventory turnover analysis
- ABC analysis
- Stock aging reports
- Dead stock analysis

## SAP B1 Tables
- `OITM` - Items Master Data
- `OITB` - Item Groups
- `OITW` - Item Warehouse Info
- `OIGN/IGN1` - Goods Receipt (production/incoming)
- `OINV/INV1` - A/R Invoice
- `ODLN/DLN1` - Delivery
- `ORIN/RIN1` - A/R Credit Memo (returns)
