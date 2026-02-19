# Bills of Materials (BOM)

SAP B1: **Production → Bills of Materials**

Defines the component structure for manufactured or assembled items.

## Key Tables
- `OITM` — Item Master (`TreeType` field identifies BOM type)
- `ITT1` — BOM Components

## BOM Types (OITM.TreeType)
| Code | Type |
|---|---|
| `'N'` | No BOM |
| `'A'` | Assembly BOM |
| `'S'` | Sales BOM (kit — no production order needed) |
| `'T'` | Template BOM |
| `'P'` | Production BOM |

## Naming Prefix
`PRD_BOM_` — e.g., `PRD_BOM_Component_Usage.sql`, `PRD_BOM_Multi_Level_Explosion.sql`
