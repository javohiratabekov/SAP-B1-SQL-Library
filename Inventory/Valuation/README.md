# Inventory Valuation Queries

## Purpose
SQL queries for inventory valuation, costing methods, and financial inventory reports.

## Query Types
- Inventory valuation by method
- Stock value analysis
- Slow-moving inventory value
- Obsolete stock valuation
- Cost layer analysis
- Inventory financial impact

## Available Queries

### `INV_Valuation_FIFO_Stock_Cost.sql`
Current FIFO stock valuation showing on-hand quantities with unit cost and total value in both USD and UZS.
- Filters: FIFO items only (`EvalSystem = 'F'`), stocked items, positive balances
- Cost priority: `OITW.StockValue` → `OITM.AvgPrice` → `OITM.LastPurPrc`
- UZS rate sourced from latest entry in `ORTT`

## Future File Names
- `INV_VAL_Current_Inventory_Value.sql`
- `INV_VAL_Slow_Moving_Inventory.sql`
- `INV_VAL_Obsolete_Stock_Report.sql`
- `INV_VAL_Cost_Layer_Analysis.sql`
- `INV_VAL_Inventory_Value_By_Warehouse.sql`

## SAP B1 Tables
Common tables used:
- `OITM` - Items Master Data
- `OITW` - Item Warehouse Info
- `OITL` - Item Transaction Lines (Cost Layers)
- `ITL1` - Item Cost Layers
