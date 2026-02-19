# Production

SAP B1 Module: **Production**

Covers manufacturing processes including Bills of Materials (BOM), production order execution, and goods movements tied to production.

## Sub-Modules

| Folder | SAP B1 Feature | Key Tables |
|---|---|---|
| `Bills_of_Materials/` | BOM definitions (multi-level) | `OITM` (TreeType), `ITT1` |
| `Production_Orders/` | Work Orders — cost & quantity tracking | `OWOR`, `WOR1`, `WOR3` |
| `Goods_Issues_Receipts/` | Component issues & FG receipts | `OIGE`/`IGE1`, `OIGN`/`IGN1` |

## Production Order Status (OWOR.Status)
- `'R'` = Released
- `'L'` = Planned
- `'C'` = Closed
- `'X'` = Cancelled

## Naming Prefix
`PRD_` — e.g., `PRD_Production_By_Item.sql`, `PRD_Cost_Analysis_FIFO_Layers.sql`
