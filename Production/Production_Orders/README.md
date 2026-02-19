# Production Orders

SAP B1: **Production → Production Orders**

Work Orders that drive the manufacturing process — tracking planned vs actual quantities and costs.

## Key Tables
- `OWOR` — Production Order Header
- `WOR1` — Component Lines (issued materials)
- `WOR3` — Operations / Routing lines

## Production Order Status (OWOR.Status)
| Code | Meaning |
|---|---|
| `'L'` | Planned |
| `'R'` | Released |
| `'C'` | Closed |
| `'X'` | Cancelled |

## Files in This Folder

| File | Description |
|---|---|
| `PRD_Production_By_Item.sql` | Production quantities by finished good and date |
| `PRD_Cost_Analysis_With_Currencies.sql` | Manufacturing cost analysis in USD and UZS |
| `PRD_Cost_Analysis_FIFO_Layers.sql` | Detailed FIFO layer cost breakdown per WO |

## Naming Prefix
`PRD_WO_` — e.g., `PRD_WO_Open_Work_Orders.sql`, `PRD_WO_Cost_Variance.sql`
