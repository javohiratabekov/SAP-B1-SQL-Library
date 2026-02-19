# Purchase Requests

SAP B1: **Purchasing A/P → Purchase Request**

Internal request to procure items or services. Starting point of the purchasing cycle.

## Key Tables
- `OPRQ` — Purchase Request Header
- `PRQ1` — Purchase Request Lines

## Document Flow
`Purchase Request → Purchase Quotation → Purchase Order → GRPO → A/P Invoice`

## Naming Prefix
`PUR_PRQ_` — e.g., `PUR_PRQ_Open_Requests.sql`
