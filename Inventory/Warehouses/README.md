# Warehouse Queries

## Purpose
SQL queries for warehouse operations, locations, and space management.

## Query Types
- Warehouse capacity analysis
- Bin location tracking
- Warehouse transfers
- Stock by location
- Warehouse efficiency metrics
- Multi-warehouse inventory

## Available Queries

### `INV_Stock_By_Warehouse.sql`
Current stock on-hand pivoted by warehouse (AND, CST, FG1, NMG, ProdWH, QNQ) with row totals.
- Filters: item groups 100 and 101, only non-zero stock
- Modify `WhsCode IN (...)` and `ItmsGrpCod IN (...)` to fit your setup

## Future File Names
- `INV_WH_Warehouse_Capacity_Report.sql`
- `INV_WH_Bin_Location_Status.sql`
- `INV_WH_Transfer_History.sql`
- `INV_WH_Warehouse_Utilization.sql`

## SAP B1 Tables
Common tables used:
- `OWHS` - Warehouses
- `OITW` - Item Warehouse Info
- `OBIN` - Bin Locations
- `OIBQ` - Item Quantity in Bin Location
