# SAP B1 HANA Query Generation Workflow

This workflow helps you generate new SAP Business One HANA SQL queries with stable quality and predictable output.

## 1) Define the business question first

Write the request in plain business language before writing SQL.

Minimum definition:
- Module (Financials, Banking, Inventory, etc.)
- Business goal (what decision/report is needed)
- Date range and filters
- Required output columns
- Grouping level (document, BP, item, month, etc.)
- Sorting and totals rules

Use `templates/NEW_QUERY_REQUEST_TEMPLATE.md` as input format.

## 2) Map required SAP B1 tables

Before coding, identify:
- Header table(s)
- Line table(s)
- Master data table(s)
- Optional join tables (rates, dimensions, UDF sources)

If unsure, use:
- `SAP_B1_ARCHITECTURE.md` for module tables and join patterns
- Existing module SQL files for proven patterns

## 3) Start from the SQL template

Create the query from:
- `templates/SAP_B1_HANA_QUERY_TEMPLATE.sql`

This enforces:
- Standard header comments
- Parameter definitions (`[%0]`, `[%1]`, ...)
- `CANCELED = 'N'` style filters where relevant
- Explicit selected columns (no `SELECT *`)

## 4) Validate logic with checklist

Checklist before saving:
- Business filters are correct
- Canceled documents are excluded where needed
- Date column is correct (`DocDate`, `RefDate`, or custom field)
- Joins do not multiply rows unexpectedly
- Query aliases are business readable
- Optional filters support `%` for "all"

## 5) Save with naming convention

File naming:
- `{PREFIX}_{SubModule}_{Description}.sql`
- Examples: `FIN_AR_Aging_Detail.sql`, `INV_RPT_Stock_Movement.sql`

Prefix mapping is in `README.md`.

## 6) Add or update module README

When adding a query:
- Add short description
- Add parameters list
- Add key tables used

This keeps the library discoverable for future query generation.

## 7) Test in SAP B1 Query Manager

Test sequence:
1. Narrow date range + specific filter
2. Compare totals with SAP standard report
3. Expand to full date range
4. Validate edge cases (canceled docs, zero qty, null values)

## Fast prompt pattern for AI generation

Use this prompt shape when asking AI to create a new query:

"Create a SAP B1 HANA SQL query for module `{module}`.
Goal: `{goal}`.
Use tables: `{known_tables_or_guess}`.
Parameters: `{[%0] start date, [%1] end date, ...}`.
Required output columns: `{columns}`.
Rules: exclude canceled docs, use CTEs where helpful, no SELECT *, production-safe aliases.
Return one final SQL script with comments and no placeholders except SAP B1 parameters."
