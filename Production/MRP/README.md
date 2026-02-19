# MRP (Material Requirements Planning) Queries

## Purpose
SQL queries for production planning, MRP runs, material requirements, capacity planning, and manufacturing cost analysis.

## Query Types
- MRP recommendations
- Material shortages
- Production order requirements
- Bill of materials analysis
- Capacity planning data
- Supply vs demand analysis
- Manufacturing cost analysis (AVECO & FIFO)
- Production cost variance analysis

## Available Queries

### 1. `PRD_Production_By_Item.sql`
Basic production quantities by date and item.

### 2. `PRD_Cost_Analysis_With_Currencies.sql`
Comprehensive manufacturing cost report showing:
- Raw materials issued with AVECO costing
- Finished goods received with FIFO costing
- Local currency (UZS) and foreign currency amounts
- Cost variance analysis between RM and FG
- Exchange rates and currency conversions

**Key Features:**
- Tracks both goods issue (raw materials) and goods receipt (finished goods)
- Shows unit costs and line totals in UZS and FC
- Cost variance calculation (FG value vs RM consumed)
- Includes item currencies and exchange rates

### 3. `PRD_Cost_Analysis_FIFO_Layers.sql`
Advanced cost analysis with FIFO layer breakdown:
- Everything from the basic cost analysis query
- Detailed FIFO inventory layer tracking (OITL, ITL1)
- Layer-by-layer cost breakdown for finished goods
- Layer quantities and balances
- Transaction type tracking
- Enhanced efficiency metrics

**Key Features:**
- FIFO layer visibility (see how costs flow through layers)
- Layer balance tracking (remaining qty at each cost)
- Cost variance percentage calculation
- Current average prices for comparison
- Detailed transaction history

> **Note:** FIFO stock valuation report (inventory on-hand cost in USD/UZS) has been moved to `Inventory/Valuation/INV_Valuation_FIFO_Stock_Cost.sql`.

## Costing Methods

### Raw Materials: AVECO (Moving Average)
- Costs averaged across all purchases
- Cost automatically recalculated with each transaction
- Field in OITM: `EvalSystem = 'A'`

### Finished Goods: FIFO (First In, First Out)
- Oldest costs consumed first
- Tracked through inventory layers (OITL/ITL1)
- Field in OITM: `EvalSystem = 'F'`

## Currency Information
- **Local Currency (LC):** UZS (Uzbekistan Som)
- **Foreign Currency (FC):** Transaction currency (USD, EUR, etc.)
- Exchange rates stored at transaction time
- All reports show both LC and FC amounts

## SAP B1 Tables

### Core Production Tables
- `OWOR` - Production Order Header
- `WOR1` - Production Order Rows
- `OITT` - Bill of Materials Header
- `ITT1` - Bill of Materials Rows
- `OMRP` - MRP Recommendations

### Goods Movement Tables
- `OIGE/IGE1` - Goods Issue Header/Lines (materials to production)
- `OIGN/IGN1` - Goods Receipt Header/Lines (production output)

### Costing & Inventory Tables
- `OITM` - Items Master Data (costing methods, currencies)
- `OITL` - Inventory Transaction Layers (quantity tracking)
- `ITL1` - Inventory Transaction Layer Details (cost tracking)
- `OCLG` - Costing Layers (layer history)
- `OCRY` - Currencies Master

## Usage Examples

### Filter by Date Range
```sql
WHERE W."PostDate" BETWEEN '2024-01-01' AND '2024-12-31'
```

### Filter by Specific Items
```sql
WHERE W."ItemCode" IN ('FG001', 'FG002', 'FG003')
```

### Find High Cost Variance Orders
```sql
HAVING ABS(Line_Variance_UZS) > 10000
-- or percentage-based:
HAVING ABS(Cost_Variance_Pct) > 10
```

### Only Completed Orders with Activity
```sql
WHERE W."Status" = 'L' 
  AND L."DocEntry" IS NOT NULL 
  AND RL."DocEntry" IS NOT NULL
```

## Field Reference Guide

See `FIELD_REFERENCE.md` for detailed SAP B1 HANA field names and correct table references.

## Notes
1. Ensure items are configured with correct costing methods in SAP B1 Item Master Data
2. Exchange rates are captured at transaction time and cannot be recalculated
3. Cost variance helps identify production inefficiencies or cost allocation issues
4. FIFO layers show detailed cost flow for better cost analysis
5. All currency calculations are NULL-safe to prevent division errors
6. Currency is managed at transaction line level (IGE1/IGN1), not at item master level (OITM)
