# Goods Issues & Receipts (Production)

SAP B1: Production-linked inventory movements.

Tracks the actual movement of raw materials (issues) and finished goods (receipts) tied to Production Orders.

## Transaction Types

| Direction | Document | Header | Lines | DocType |
|---|---|---|---|---|
| OUT → production | Goods Issue | `OIGE` | `IGE1` | `60` |
| IN ← production | Goods Receipt | `OIGN` | `IGN1` | `59` |

## Key Fields
- `OIGE.BaseEntry` / `OIGN.BaseEntry` → links to `OWOR.DocEntry`
- `IGE1.BaseType` = `202` (Production Order)

## Naming Prefix
`PRD_GI_` or `PRD_GR_` — e.g., `PRD_GI_Component_Issues.sql`
