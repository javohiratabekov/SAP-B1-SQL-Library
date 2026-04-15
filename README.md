# SAP B1 SQL Library

## Overview
A professional collection of **SAP Business One (SAP B1) HANA SQL queries**, organized by SAP B1 module structure — mirroring the exact module layout of the SAP B1 main menu.

## Repository Structure

```
SAP-B1-SQL-Library/
│
├── Financials/                        ← SAP B1: Financials
│   ├── General_Ledger/                  Chart of Accounts, Journal Entries
│   ├── Accounts_Receivable/             Customer invoices, reconciliation
│   ├── Accounts_Payable/                Vendor invoices, aging
│   ├── Budget/                          Budget vs Actual
│   └── Financial_Reports/               P&L, Balance Sheet, Trial Balance
│
├── Sales_AR/                          ← SAP B1: Sales — A/R
│   ├── Quotations/                      OQUT / QUT1
│   ├── Sales_Orders/                    ORDR / RDR1
│   ├── Deliveries/                      ODLN / DLN1
│   ├── AR_Invoices/                     OINV / INV1
│   ├── AR_Credit_Memos/                 ORIN / RIN1
│   ├── AR_Down_Payments/                ODPI / DPI1
│   ├── Returns/                         ORDN / RDN1
│   └── Sales_Reports/                   Analytical reports
│
├── Purchasing_AP/                     ← SAP B1: Purchasing — A/P
│   ├── Purchase_Requests/               OPRQ / PRQ1
│   ├── Purchase_Quotations/             OPQT / PQT1
│   ├── Purchase_Orders/                 OPOR / POR1
│   ├── GRPO/                            OPDN / PDN1
│   ├── AP_Invoices/                     OPCH / PCH1
│   ├── AP_Credit_Memos/                 ORPC / RPC1
│   ├── AP_Down_Payments/                ODPO / DPO1
│   └── Purchasing_Reports/              Analytical reports
│
├── Business_Partners/                 ← SAP B1: Business Partners
│   ├── Customers/                       OCRD (CardType='C')
│   ├── Vendors/                         OCRD (CardType='S')
│   └── Leads/                           OCRD (CardType='L')
│
├── Banking/                           ← SAP B1: Banking
│   ├── Incoming_Payments/               ORCT / RCT2
│   ├── Outgoing_Payments/               OVPM / VPM2
│   ├── Bank_Reconciliation/             OBNK / BNK1
│   └── Checks/                          OCHQ
│
├── Inventory/                         ← SAP B1: Inventory
│   ├── Items/                           OITM, OITB
│   ├── Warehouses/                      OITW, OWHS
│   ├── Goods_Receipt/                   OIGN / IGN1
│   ├── Goods_Issue/                     OIGE / IGE1
│   ├── Stock_Transfer/                  OWTR / WTR1
│   ├── Inventory_Counting/              OITC / ITC1
│   ├── Price_Lists/                     OPLN / PL01
│   ├── Valuation/                       OITL / ITL1 (FIFO, AVECO)
│   └── Inventory_Reports/               Movement, stock analysis
│
├── Production/                        ← SAP B1: Production
│   ├── Bills_of_Materials/              OITM (BOM), ITT1
│   ├── Production_Orders/               OWOR / WOR1
│   └── Goods_Issues_Receipts/           OIGE (type 60) / OIGN (type 59)
│
├── MRP/                               ← SAP B1: MRP
│   └── (MRP Wizard, recommendations)    OMRP, OMRS
│
├── Service/                           ← SAP B1: Service
│   ├── Service_Contracts/               OSCN / SCN1
│   ├── Service_Calls/                   OSCL / SCL1
│   └── Equipment_Cards/                 OSER
│
├── Human_Resources/                   ← SAP B1: Human Resources
│   ├── Employees/                       OHEM
│   ├── Departments/                     OUDP
│   └── Branches/                        OBPL
│
├── Reports/                           ← Cross-module analytics
│   └── Dashboard_Analytics/             KPI queries, cockpit widgets
│
├── Administration/                    ← SAP B1: Administration
│   ├── Users/                           OUSR
│   ├── Approvals/                       OATP, OWDD
│   └── Alerts/                          OAMD
│
├── SAP_B1_ARCHITECTURE.md             ← Complete SAP B1 architecture reference
└── README.md
```

## Naming Convention

All SQL files follow: **`MODULE_SubModule_Description.sql`**

| Prefix | Module |
|---|---|
| `FIN_` | Financials |
| `SAL_` | Sales A/R |
| `PUR_` | Purchasing A/P |
| `BP_` | Business Partners |
| `BNK_` | Banking |
| `INV_` | Inventory |
| `PRD_` | Production |
| `MRP_` | MRP |
| `SRV_` | Service |
| `HR_` | Human Resources |
| `RPT_` / `DASH_` | Reports / Dashboard |
| `ADM_` | Administration |

### Examples
- `FIN_AR_Customer_Reconciliation.sql`
- `SAL_Sales_By_Item.sql`
- `PUR_Purchases_By_Item.sql`
- `INV_Stock_By_Warehouse.sql`
- `INV_Valuation_FIFO_Stock_Cost.sql`
- `PRD_Cost_Analysis_FIFO_Layers.sql`
- `BNK_Cash_Turnover.sql`

## Current SQL Queries

| File | Module | Description |
|---|---|---|
| `Financials/Accounts_Receivable/FIN_AR_Customer_Reconciliation.sql` | Finance | Customer reconciliation with running balance (USD/UZS) |
| `Banking/FIN_BNK_Cash_Turnover.sql` | Banking | Cash turnover — incoming vs outgoing payments |
| `Sales_AR/Sales_Reports/SAL_Sales_By_Item.sql` | Sales | Sales quantities by item and date |
| `Purchasing_AP/Purchasing_Reports/PUR_Purchases_By_Item.sql` | Purchasing | Purchase quantities by item from A/P Invoices |
| `Inventory/Warehouses/INV_Stock_By_Warehouse.sql` | Inventory | Current stock pivoted by warehouse |
| `Inventory/Inventory_Reports/INV_RPT_Movement_Report.sql` | Inventory | Inventory movement (correlated subquery version) |
| `Inventory/Inventory_Reports/INV_RPT_Movement_Report_CTE.sql` | Inventory | Inventory movement (CTE version — preferred) |
| `Inventory/Valuation/INV_Valuation_FIFO_Stock_Cost.sql` | Inventory | FIFO stock valuation in USD and UZS |
| `Production/Production_Orders/PRD_Production_By_Item.sql` | Production | Production quantities by finished good |
| `Production/Production_Orders/PRD_Cost_Analysis_With_Currencies.sql` | Production | Manufacturing cost analysis with currencies |
| `Production/Production_Orders/PRD_Cost_Analysis_FIFO_Layers.sql` | Production | Advanced FIFO layer cost breakdown per WO |

## Usage
1. Navigate to the SAP B1 module folder that matches your business question
2. Review the `README.md` in each folder for available queries and table references
3. Open the `.sql` file and use it in SAP B1 Query Manager or Crystal Reports

## Generate New Queries (Recommended Workflow)
If you want consistent, production-quality SAP B1 HANA SQL generation:

1. Fill `templates/NEW_QUERY_REQUEST_TEMPLATE.md`
2. Follow `QUERY_GENERATION_WORKFLOW.md`
3. Build from `templates/SAP_B1_HANA_QUERY_TEMPLATE.sql`
4. Save to the correct module folder using this repo naming convention
5. Update that module's `README.md` with query description and parameters

This process makes AI-generated and manually written SQL more consistent, testable, and reusable.

## Notes
- All queries are written for **SAP HANA SQL**
- Parameter syntax: `[%0]`, `[%1]`, `[%2]` (SAP B1 Query Manager format)
- Test in a **development/test environment** before production use
- See `SAP_B1_ARCHITECTURE.md` for complete table reference and architecture guide

---
**Database:** SAP HANA | **ERP:** SAP Business One 9.x – 10.x
