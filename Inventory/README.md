# Inventory

SAP B1 Module: **Inventory**

Manages all stock-related operations including item master data, warehouse stock levels, goods movements, valuation, and price lists.

## Sub-Modules

| Folder | SAP B1 Feature | Key Tables |
|---|---|---|
| `Items/` | Item Master Data | `OITM`, `OITB` |
| `Warehouses/` | Stock levels by warehouse | `OITW`, `OWHS` |
| `Goods_Receipt/` | Manual Goods Receipt | `OIGN`, `IGN1` |
| `Goods_Issue/` | Manual Goods Issue | `OIGE`, `IGE1` |
| `Stock_Transfer/` | Warehouse-to-Warehouse Transfer | `OWTR`, `WTR1` |
| `Inventory_Counting/` | Physical count & adjustment | `OITC`, `ITC1` |
| `Price_Lists/` | Price lists and special prices | `OPLN`, `PL01` |
| `Valuation/` | FIFO / Avg cost valuation | `OITL`, `ITL1`, `OIVL` |
| `Inventory_Reports/` | Movement, stock analysis reports | — |

## Naming Prefix
`INV_` — e.g., `INV_Stock_By_Warehouse.sql`, `INV_Valuation_FIFO_Stock_Cost.sql`
