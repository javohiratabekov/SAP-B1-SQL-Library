# Business Partners

SAP B1 Module: **Business Partners**

Central master data for all external parties: customers, vendors, and leads/prospects. All stored in `OCRD` differentiated by `CardType`.

## Sub-Modules

| Folder | CardType | Description |
|---|---|---|
| `Customers/` | `'C'` | Customer accounts, credit limits, reconciliation |
| `Vendors/` | `'S'` | Supplier/vendor accounts |
| `Leads/` | `'L'` | Sales prospects (not yet customers) |

## Key Tables
- `OCRD` — Business Partner master (`CardType`: C/S/L)
- `OCPR` — Contact persons
- `CRD1` — Bill-To / Ship-To addresses
- `CRD7` — Bank accounts
- `OCRG` — BP Groups

## Naming Prefix
`BP_` — e.g., `BP_Customer_Credit_Status.sql`, `BP_Vendor_Open_Balance.sql`
