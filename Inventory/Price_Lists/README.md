# Price Lists

SAP B1: **Inventory → Price Lists**

Defines item selling and purchasing prices for different customer groups, currencies, or quantity breaks.

## Key Tables
- `OPLN` — Price List Header (name, currency, base list, factor)
- `PL01` — Price List Lines (item prices per list)
- `SPP1` — Special prices by Business Partner

## Naming Prefix
`INV_PRC_` — e.g., `INV_PRC_Customer_Special_Prices.sql`, `INV_PRC_List_Comparison.sql`
