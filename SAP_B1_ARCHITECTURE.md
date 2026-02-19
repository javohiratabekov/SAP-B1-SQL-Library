# SAP Business One — Complete Architecture Reference
> **Role:** SAP B1 Query Manager · Analytics · Report Manager · Consultant  
> **Database:** SAP HANA SQL  
> **Version scope:** SAP B1 9.x – 10.x (HANA edition)

---

## Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Database Architecture — SAP HANA](#2-database-architecture--sap-hana)
3. [Module Architecture](#3-module-architecture)
4. [Document Flow & Posting Engine](#4-document-flow--posting-engine)
5. [Master Data Architecture](#5-master-data-architecture)
6. [Complete Table Reference by Module](#6-complete-table-reference-by-module)
7. [Transaction Type Codes (TransType)](#7-transaction-type-codes-transtype)
8. [Journal Entry Architecture (GL Posting)](#8-journal-entry-architecture-gl-posting)
9. [Inventory & Costing Architecture](#9-inventory--costing-architecture)
10. [Query Manager — Architecture & Best Practices](#10-query-manager--architecture--best-practices)
11. [Report Manager — Crystal Reports Integration](#11-report-manager--crystal-reports-integration)
12. [Analytics & Dashboard Architecture](#12-analytics--dashboard-architecture)
13. [Currency & Exchange Rate Architecture](#13-currency--exchange-rate-architecture)
14. [User-Defined Fields (UDF) & User-Defined Tables (UDT)](#14-user-defined-fields-udf--user-defined-tables-udt)
15. [Integration Framework (DI API & Service Layer)](#15-integration-framework-di-api--service-layer)
16. [Key Field Reference — Critical Fields per Table](#16-key-field-reference--critical-fields-per-table)
17. [JOIN Patterns & Query Templates](#17-join-patterns--query-templates)
18. [Performance Optimization for Queries](#18-performance-optimization-for-queries)

---

## 1. System Architecture Overview

### 1.1 Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION TIER                            │
│                                                                     │
│   SAP B1 Client (Windows)     │   SAP B1 Web Client (Browser)      │
│   SAP B1 Mobile App           │   Third-Party Add-ons (SDK)        │
└────────────────────────────────────────────────────────────────────-┘
                                │
                    ┌───────────▼───────────┐
                    │    APPLICATION TIER    │
                    │                        │
                    │  SAP B1 Server Tools   │
                    │  DI Server (COM/WS)    │
                    │  Service Layer (REST)  │
                    │  Integration FW        │
                    │  License Server        │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │      DATABASE TIER      │
                    │                        │
                    │    SAP HANA Database   │
                    │   (In-Memory Engine)   │
                    │                        │
                    └────────────────────────┘
```

### 1.2 SAP B1 Server Components

| Component | Purpose |
|---|---|
| **SLD (System Landscape Directory)** | Manages company databases, licenses |
| **DI Server** | COM/WS-based API for document creation |
| **Service Layer** | RESTful OData API (B1 9.3+) |
| **Integration Framework** | B2B/B2C integrations via scenarios |
| **License Server** | Concurrent user license management |
| **Backup Service** | Scheduled database backup agent |
| **Job Service** | Recurring postings, alerts, approvals |
| **Mailer Service** | Email notifications and alerts |

### 1.3 Company Database Structure

Each SAP B1 company = one SAP HANA schema/database containing:
- ~600+ business tables (OITM, OINV, OCRD, etc.)
- ~200+ system/configuration tables
- Views, procedures, and sequences
- UDF extensions and UDT custom tables

---

## 2. Database Architecture — SAP HANA

### 2.1 SAP HANA vs SQL Server (Key Differences)

| Feature | SAP HANA | MS SQL Server |
|---|---|---|
| Storage | In-memory columnar | Disk-based row store |
| String delimiter | Double quotes `"FieldName"` | Square brackets `[FieldName]` |
| NULL handling | `IFNULL()` | `ISNULL()` |
| String concat | `\|\|` operator | `+` operator |
| Top N rows | `LIMIT n` | `TOP n` |
| Date functions | `TO_DATE()`, `YEAR()` | `CONVERT()`, `YEAR()` |
| Case sensitivity | Case-sensitive by default | Case-insensitive |
| Temp tables | `#TEMP` not supported → use CTEs | Full temp table support |

### 2.2 HANA SQL Key Functions

```sql
-- Date functions
YEAR(T0."DocDate")                    -- Extract year
MONTH(T0."DocDate")                   -- Extract month  
DAY(T0."DocDate")                     -- Extract day
TO_DATE('2024-01-01')                 -- String to date
ADD_MONTHS(NOW(), -3)                 -- Date arithmetic
DAYS_BETWEEN(T0."DocDate", NOW())     -- Days difference
LAST_DAY(T0."DocDate")               -- Last day of month

-- String functions
SUBSTRING(T0."CardCode", 1, 3)        -- Substring
UPPER(T0."CardName")                  -- Uppercase
TRIM(T0."Dscription")                 -- Trim spaces
REPLACE(T0."CardName", 'LLC', '')     -- Replace
LENGTH(T0."ItemCode")                 -- String length
LPAD(T0."DocNum", 8, '0')            -- Left pad

-- NULL handling
IFNULL(T0."Dscription", 'No Desc')   -- Null fallback
NULLIF(T0."Quantity", 0)              -- Returns NULL if equal
COALESCE(T0."FCDebit", T0."Debit", 0) -- First non-null

-- Numeric
ROUND(T0."LineTotal", 2)              -- Round to 2 decimals
ABS(T0."Quantity")                    -- Absolute value
CEILING(T0."Quantity")               -- Ceil
FLOOR(T0."Quantity")                 -- Floor
CAST(T0."DocNum" AS NVARCHAR)        -- Type conversion

-- Window functions
ROW_NUMBER() OVER (PARTITION BY T0."CardCode" ORDER BY T0."DocDate")
SUM(T0."Debit") OVER (ORDER BY T0."TransId" ROWS UNBOUNDED PRECEDING)
RANK() OVER (ORDER BY SUM(T0."LineTotal") DESC)
LAG(T0."DocTotal", 1) OVER (PARTITION BY T0."CardCode" ORDER BY T0."DocDate")
```

### 2.3 SAP HANA Data Types in B1

| HANA Type | Description | Common Usage |
|---|---|---|
| `NVARCHAR(n)` | Unicode string | Names, codes, descriptions |
| `INTEGER` | 32-bit integer | Quantities, DocEntry, line numbers |
| `NUMERIC(n,m)` | Decimal | Amounts, prices, rates |
| `DATE` | Date only | DocDate, TaxDate |
| `TIMESTAMP` | Date + time | CreateDate + CreateTime |
| `TINYINT` | 0–255 | Status flags |
| `SMALLINT` | Small integer | Type codes |

---

## 3. Module Architecture

### 3.1 SAP B1 Module Map

```
SAP Business One
│
├── Finance (FI)
│   ├── General Ledger          → Chart of Accounts, Journal Entries
│   ├── Accounts Receivable     → Customer invoices, receipts
│   ├── Accounts Payable        → Vendor invoices, payments
│   ├── Banking                 → Bank reconciliation, statements
│   ├── Financial Reports       → P&L, Balance Sheet, Cash Flow
│   └── Budget                  → Budget definitions and tracking
│
├── Sales (SD)
│   ├── Quotations (Offers)     → OQUT / QUT1
│   ├── Sales Orders            → ORDR / RDR1
│   ├── Deliveries              → ODLN / DLN1
│   ├── A/R Invoices            → OINV / INV1
│   ├── A/R Credit Memos        → ORIN / RIN1
│   └── A/R Down Payments       → ODPI / DPI1
│
├── Purchasing (MM)
│   ├── Purchase Requests       → OPRQ / PRQ1
│   ├── Purchase Quotations     → OPQT / PQT1
│   ├── Purchase Orders         → OPOR / POR1
│   ├── GR PO (GRPO)            → OPDN / PDN1
│   ├── A/P Invoices            → OPCH / PCH1
│   ├── A/P Credit Memos        → ORPC / RPC1
│   └── A/P Down Payments       → ODPO / DPO1
│
├── Inventory (WM)
│   ├── Items Master            → OITM
│   ├── Warehouses              → OWHS
│   ├── Goods Receipt           → OIGN / IGN1
│   ├── Goods Issue             → OIGE / IGE1
│   ├── Stock Transfer          → OWTR / WTR1
│   ├── Inventory Counting      → OITC / ITC1
│   └── Price Lists             → OPLN / PL01
│
├── Production (PP)
│   ├── Bills of Materials      → OITM (BOM flag) / ITT1
│   ├── Production Orders       → OWOR / WOR1
│   ├── Goods Receipt (Prod)    → OIGN (type 59)
│   └── Goods Issue (Prod)      → OIGE (type 60)
│
├── MRP
│   ├── MRP Wizard              → OMRP
│   ├── Recommendations         → OMRS
│   └── Order Recommendations   → OMRO
│
├── Business Partners (BP)
│   ├── Customers               → OCRD (CardType='C')
│   ├── Vendors                 → OCRD (CardType='S')
│   └── Leads                   → OCRD (CardType='L')
│
├── Banking
│   ├── Incoming Payments       → ORCT / RCT2
│   ├── Outgoing Payments       → OVPM / VPM2
│   ├── Bank Reconciliation     → OBNK
│   └── Checks                  → OCHQ
│
├── HR
│   ├── Employees               → OHEM
│   ├── Departments             → OUDP
│   └── Branches                → OBPL
│
├── Service
│   ├── Service Contracts       → OSCN
│   ├── Service Calls           → OSCL
│   └── Equipment Cards         → OSER
│
└── Administration
    ├── System Settings         → OADM
    ├── Users                   → OUSR
    ├── Approval Process        → OATP
    ├── Alerts                  → OAMD
    └── Authorizations          → OUSR / OUTB
```

---

## 4. Document Flow & Posting Engine

### 4.1 Sales Document Flow

```
Quotation (OQUT)
    │ Copy To
    ▼
Sales Order (ORDR)  ──── Blanket Agreement (OBFA)
    │ Copy To
    ▼
Delivery (ODLN) ─────────────────────────────────┐
    │ Copy To                                      │
    ▼                                              │
A/R Invoice (OINV) ◄─── Copy To ─── Reserve Invoice │
    │ Copy To                                      │
    ▼                                              │
A/R Credit Memo (ORIN) ◄─────── Return (ORDN) ◄──┘
    │
    ▼
Incoming Payment (ORCT) ─── Applied to Invoice
```

### 4.2 Purchasing Document Flow

```
Purchase Request (OPRQ)
    │ Copy To
    ▼
Purchase Quotation (OPQT)
    │ Copy To
    ▼
Purchase Order (OPOR)
    │ Copy To
    ▼
Goods Receipt PO (OPDN) ─────────────────────────┐
    │ Copy To                                      │
    ▼                                              │
A/P Invoice (OPCH) ◄─────────────────────────────┘
    │ Copy To
    ▼
A/P Credit Memo (ORPC) ◄─── Goods Return (ORPD)
    │
    ▼
Outgoing Payment (OVPM) ─── Applied to Invoice
```

### 4.3 Inventory Document Flow

```
Goods Receipt (OIGN)  ←── Stock IN  (manual, production)
Goods Issue   (OIGE)  ←── Stock OUT (manual, production)
Stock Transfer (OWTR) ←── Warehouse to Warehouse
Inventory Counting (OITC) ←── Physical count & adjustment
```

### 4.4 Document Status Codes

```sql
-- DocStatus field in all marketing documents
'O' = Open
'C' = Closed
'P' = Partially closed (orders with partial delivery)

-- Canceled field
'N' = Not canceled (active document)
'Y' = Canceled

-- Always filter canceled docs:
WHERE T0."CANCELED" = 'N'
-- or in newer B1 versions:
WHERE T0."Canceled" = 'N'
```

### 4.5 Base Document Relationships

```sql
-- Find all documents copied FROM a specific order
SELECT 
    T0."DocEntry"   AS "InvoiceEntry",
    T0."DocNum"     AS "InvoiceNum",
    T0."CardCode",
    T1."BaseEntry"  AS "OrderEntry",
    T1."BaseType"   AS "OrderType",  -- 17 = Sales Order
    T1."BaseLine"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T1."BaseType" = 17  -- Copied from Sales Order
  AND T1."BaseEntry" = [%0]
```

---

## 5. Master Data Architecture

### 5.1 Business Partners (OCRD)

```
OCRD — Central BP table (Customers + Vendors + Leads)
│
├── CardType = 'C'  → Customers
├── CardType = 'S'  → Vendors (Suppliers)
└── CardType = 'L'  → Leads
│
├── OCPR  ← Contact persons
├── CRD1  ← Addresses (Bill-To, Ship-To)
├── CRD7  ← Bank accounts
├── OBAS  ← Balance (open items)
└── RCT2 / VPM2 ← Payment applications
```

**Key OCRD Fields:**

| Field | Type | Description |
|---|---|---|
| `CardCode` | NVARCHAR(15) | Unique BP code (primary key) |
| `CardName` | NVARCHAR(100) | Full name |
| `CardType` | CHAR(1) | C=Customer, S=Supplier, L=Lead |
| `CreditLine` | NUMERIC | Credit limit |
| `Balance` | NUMERIC | Current open balance (LC) |
| `BalancFC` | NUMERIC | Balance in foreign currency |
| `SlpCode` | INTEGER | Sales employee code → OSLP |
| `GroupCode` | SMALLINT | BP group → OCRG |
| `Currency` | NVARCHAR(3) | Default BP currency |
| `VatIdUnCmp` | NVARCHAR(32) | VAT/Tax ID |
| `validFor` | CHAR(1) | Y=Active, N=Inactive |
| `Frozen` | CHAR(1) | Y=Frozen (blocked) |

### 5.2 Items Master Data (OITM)

```
OITM — Central item table
│
├── InvntItem = 'Y'  → Stock item (tracked in warehouse)
├── InvntItem = 'N'  → Non-stock item (service, labor)
│
├── OITW  ← Stock by warehouse (OnHand, Committed, Ordered)
├── OITL  ← Inventory transaction layers (FIFO/Serial/Batch)
├── ITL1  ← Layer cost details
├── OITB  ← Item groups
├── OPLN/PL01  ← Price lists
├── OSBQ  ← Serial/Batch numbers
└── IBT1  ← Batch transactions
```

**Key OITM Fields:**

| Field | Type | Description |
|---|---|---|
| `ItemCode` | NVARCHAR(50) | Item code (primary key) |
| `ItemName` | NVARCHAR(200) | Description |
| `ItmsGrpCod` | SMALLINT | Item group → OITB |
| `InvntItem` | CHAR(1) | Y=Stock, N=Non-stock |
| `EvalSystem` | CHAR(1) | A=AVECO, F=FIFO, S=Std, B=Serial |
| `AvgPrice` | NUMERIC | Moving average / standard cost |
| `LastPurPrc` | NUMERIC | Last purchase price |
| `InvntryUom` | NVARCHAR(20) | Inventory unit of measure |
| `SalUnitMsr` | NVARCHAR(20) | Sales UoM |
| `PurUnitMsr` | NVARCHAR(20) | Purchase UoM |
| `validFor` | CHAR(1) | Y=Active, N=Inactive |
| `OnHand` | NUMERIC | Total stock (all warehouses) |
| `IsCommited` | NUMERIC | Committed quantity |
| `OnOrder` | NUMERIC | On order quantity |
| `VatGourpSa` | NVARCHAR(8) | Sales tax group |
| `WTLiable` | CHAR(1) | Withholding tax liable |

### 5.3 Chart of Accounts (OACT)

```
OACT — G/L Account master
│
├── Postable = 'N' → Title/Header account (no posting)
├── Postable = 'Y' → Active G/L account
│
├── AccType = 'A' → Assets
├── AccType = 'L' → Liabilities
├── AccType = 'O' → Owners Equity
├── AccType = 'I' → Income
└── AccType = 'E' → Expenditure
```

**Key OACT Fields:**

| Field | Description |
|---|---|
| `AcctCode` | Account code (primary key) |
| `AcctName` | Account name |
| `Postable` | Y=Postable, N=Title |
| `AccType` | Account type (A/L/O/I/E) |
| `CurrTotal` | Current balance LC |
| `FcTotal` | Current balance FC |
| `ExtTotal` | Balance in system currency |
| `GroupMask` | Account group hierarchy |
| `LocManual` | Managed by reconciliation |

---

## 6. Complete Table Reference by Module

### 6.1 Finance Tables

| Table | Name | Type |
|---|---|---|
| `OACT` | G/L Accounts (Chart of Accounts) | Master |
| `OJDT` | Journal Entry Header | Transaction |
| `JDT1` | Journal Entry Lines | Transaction |
| `OFPR` | Fiscal Periods | Config |
| `OCRC` | Currency Codes | Config |
| `ORTT` | Exchange Rates | Config |
| `OBGT` | Budget Header | Transaction |
| `BGT1` | Budget Lines | Transaction |
| `OBNK` | Bank Statement Header | Transaction |
| `BNK1` | Bank Statement Lines | Transaction |
| `OBTF` | Bank Transfer | Transaction |

### 6.2 Sales Tables

| Table | Name | Notes |
|---|---|---|
| `OQUT` | Quotation Header | |
| `QUT1` | Quotation Lines | |
| `ORDR` | Sales Order Header | |
| `RDR1` | Sales Order Lines | |
| `ODLN` | Delivery Header | |
| `DLN1` | Delivery Lines | |
| `OINV` | A/R Invoice Header | Most used |
| `INV1` | A/R Invoice Lines | Most used |
| `ORIN` | A/R Credit Memo Header | |
| `RIN1` | A/R Credit Memo Lines | |
| `ORDN` | A/R Return Header | |
| `RDN1` | A/R Return Lines | |
| `ODPI` | A/R Down Payment Header | |
| `DPI1` | A/R Down Payment Lines | |
| `OSLP` | Sales Employees | Master |
| `OTER` | Sales Territories | Master |

### 6.3 Purchasing Tables

| Table | Name | Notes |
|---|---|---|
| `OPRQ` | Purchase Request Header | |
| `PRQ1` | Purchase Request Lines | |
| `OPQT` | Purchase Quotation Header | |
| `PQT1` | Purchase Quotation Lines | |
| `OPOR` | Purchase Order Header | |
| `POR1` | Purchase Order Lines | |
| `OPDN` | Goods Receipt PO Header | GRPO |
| `PDN1` | Goods Receipt PO Lines | |
| `OPCH` | A/P Invoice Header | Most used |
| `PCH1` | A/P Invoice Lines | Most used |
| `ORPC` | A/P Credit Memo Header | |
| `RPC1` | A/P Credit Memo Lines | |
| `ORPD` | A/P Return Header | |
| `RPD1` | A/P Return Lines | |
| `ODPO` | A/P Down Payment Header | |
| `DPO1` | A/P Down Payment Lines | |

### 6.4 Inventory Tables

| Table | Name | Notes |
|---|---|---|
| `OITM` | Items Master Data | Central master |
| `OITB` | Item Groups | Master |
| `OITW` | Item Warehouse Info | Stock levels |
| `OWHS` | Warehouses | Master |
| `OBIN` | Bin Locations | Master (WMS) |
| `OITL` | Inventory Transaction Layers | FIFO/Serial/Batch |
| `ITL1` | Layer Cost Details | Costing |
| `OIGN` | Goods Receipt Header | |
| `IGN1` | Goods Receipt Lines | |
| `OIGE` | Goods Issue Header | |
| `IGE1` | Goods Issue Lines | |
| `OWTR` | Stock Transfer Header | |
| `WTR1` | Stock Transfer Lines | |
| `OITC` | Inventory Counting Header | |
| `ITC1` | Inventory Counting Lines | |
| `OPLN` | Price Lists | Master |
| `PL01` | Price List Lines (items) | |
| `OSRN` | Serial Numbers Master | |
| `OBTN` | Batch Numbers Master | |
| `IBT1` | Batch Transactions | |
| `OIVL` | Inventory Valuation Ledger | Costing audit |

### 6.5 Production Tables

| Table | Name | Notes |
|---|---|---|
| `OWOR` | Production Order Header | |
| `WOR1` | Production Order Components | BOM lines |
| `WOR3` | Production Order Operations | Routing |
| `OBOM` | BOM Header (Assembly) | |
| `BOM1` | BOM Components | |
| `OACT` | G/L Accounts | Used for WIP |
| `OIGE` | Goods Issue (to prod) | DocType=60 |
| `OIGN` | Goods Receipt (from prod) | DocType=59 |

**Production Order Status (OWOR.Status):**

| Value | Meaning |
|---|---|
| `R` | Released |
| `L` | Planned |
| `C` | Closed |
| `X` | Cancelled |

### 6.6 Banking / Payment Tables

| Table | Name | Notes |
|---|---|---|
| `ORCT` | Incoming Payment Header | Customer receipts |
| `RCT1` | Incoming Payment — Invoice Links | |
| `RCT2` | Incoming Payment — GL Lines | |
| `OVPM` | Outgoing Payment Header | Vendor payments |
| `VPM1` | Outgoing Payment — Invoice Links | |
| `VPM2` | Outgoing Payment — GL Lines | |
| `OCHQ` | Checks | |
| `OCRG` | Credit Card Groups | |

### 6.7 Business Partner Tables

| Table | Name |
|---|---|
| `OCRD` | Business Partners (Master) |
| `OCPR` | Contact Persons |
| `CRD1` | BP Addresses |
| `CRD7` | BP Bank Accounts |
| `OCRG` | BP Groups |
| `OITF` | Industry Types |
| `OSHP` | Shipping Types |
| `OPYM` | Payment Methods |
| `OCTG` | Payment Terms |

### 6.8 HR Tables

| Table | Name |
|---|---|
| `OHEM` | Employees |
| `OUDP` | Departments |
| `OBPS` | Employee Positions |
| `OBPL` | Branches |
| `OHDN` | Employee Absences |

### 6.9 System / Config Tables

| Table | Name |
|---|---|
| `OADM` | Company Details / Settings |
| `OUSR` | Users |
| `OUTB` | Authorization Objects |
| `OSLP` | Sales Employees |
| `OHEM` | Employees |
| `OMRC` | Resources (machines/labor) |
| `OCRN` | Currencies |
| `ORTT` | Exchange Rates Table |
| `OFPR` | Fiscal Periods |
| `ONWQ` | Number Series |

---

## 7. Transaction Type Codes (TransType)

Used in `JDT1."TransType"`, `OITL."DocType"`, and document identification.

| Code | Document Type | Header Table | Lines Table |
|---|---|---|---|
| `-1` | Manual Journal Entry | `OJDT` | `JDT1` |
| `-2` | Opening Balance | `OJDT` | `JDT1` |
| `13` | A/R Invoice | `OINV` | `INV1` |
| `14` | A/R Credit Memo | `ORIN` | `RIN1` |
| `15` | Delivery | `ODLN` | `DLN1` |
| `16` | A/R Return | `ORDN` | `RDN1` |
| `17` | Sales Order | `ORDR` | `RDR1` |
| `18` | A/P Invoice | `OPCH` | `PCH1` |
| `19` | A/P Credit Memo | `ORPC` | `RPC1` |
| `20` | Goods Receipt PO | `OPDN` | `PDN1` |
| `21` | A/P Return | `ORPD` | `RPD1` |
| `22` | Purchase Order | `OPOR` | `POR1` |
| `23` | Quotation | `OQUT` | `QUT1` |
| `24` | Incoming Payment | `ORCT` | `RCT2` |
| `25` | Deposit | | |
| `28` | Journal Voucher | `OJDT` | `JDT1` |
| `30` | Manual Journal | `OJDT` | `JDT1` |
| `46` | Outgoing Payment | `OVPM` | `VPM2` |
| `59` | Goods Receipt (Production) | `OIGN` | `IGN1` |
| `60` | Goods Issue (Production) | `OIGE` | `IGE1` |
| `67` | Inventory Adjustment | `OIBT` / `OITC` | |
| `69` | Landed Costs | `OILC` | `ILC1` |
| `76` | Correction Invoice | `OCIV` | `CIV1` |
| `162` | Stock Transfer | `OWTR` | `WTR1` |
| `202` | Production Order | `OWOR` | `WOR1` |
| `203` | Reserve Invoice | `OINV` | `INV1` |

```sql
-- Universal document lookup from journal entry
SELECT
    T0."TransId",
    T0."RefDate",
    CASE T0."TransType"
        WHEN 13  THEN 'A/R Invoice'
        WHEN 14  THEN 'A/R Credit Memo'
        WHEN 15  THEN 'Delivery'
        WHEN 18  THEN 'A/P Invoice'
        WHEN 19  THEN 'A/P Credit Memo'
        WHEN 20  THEN 'Goods Receipt PO'
        WHEN 24  THEN 'Incoming Payment'
        WHEN 46  THEN 'Outgoing Payment'
        WHEN 59  THEN 'Goods Receipt (Production)'
        WHEN 60  THEN 'Goods Issue (Production)'
        WHEN 202 THEN 'Production Order'
        ELSE 'Other (' || CAST(T0."TransType" AS NVARCHAR) || ')'
    END AS "DocumentType",
    T0."Ref1" AS "DocumentNumber",
    T0."Memo"
FROM OJDT T0
WHERE T0."RefDate" BETWEEN [%0] AND [%1]
ORDER BY T0."RefDate", T0."TransId";
```

---

## 8. Journal Entry Architecture (GL Posting)

### 8.1 Double-Entry Structure

```
OJDT (Journal Entry Header)
│   TransId     — Unique transaction ID
│   RefDate     — Posting date
│   TaxDate     — Tax/document date
│   Memo        — Memo/description
│   TransType   — Source document type
│   Ref1        — Document number reference
│   CreatedBy   — User who created it
│
└── JDT1 (Journal Entry Lines) — one row per debit/credit
        TransId     — Links to OJDT
        Line_ID     — Line number
        Account     — G/L account code
        ShortName   — BP CardCode (if applicable)
        Debit       — Debit amount (LC)
        Credit      — Credit amount (LC)
        FCDebit     — Debit (foreign currency)
        FCCredit    — Credit (foreign currency)
        FCCurrency  — Foreign currency code
        SYSDebit    — System currency debit
        SYSCredit   — System currency credit
        Ref1        — Reference 1
        Ref2        — Reference 2
        LineMemo    — Line description
        TransType   — Same as header
        RefDate     — Posting date (denormalized from header)
```

### 8.2 How SAP B1 Posts Documents

Every financial document automatically creates a journal entry:

```
A/R Invoice Posted
    └── OJDT record created (TransType = 13)
         ├── JDT1 line: DEBIT  → Customer account (CardCode)
         └── JDT1 line: CREDIT → Revenue account
                               → VAT account (if applicable)
```

### 8.3 Running Balance Query Pattern

```sql
-- Running balance using window function
SELECT
    T0."RefDate",
    T0."Debit",
    T0."Credit",
    SUM(T0."Debit" - T0."Credit") OVER (
        PARTITION BY T0."ShortName"
        ORDER BY T0."RefDate", T0."TransId", T0."Line_ID"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "RunningBalance"
FROM JDT1 T0
WHERE T0."ShortName" = [%0]
ORDER BY T0."RefDate", T0."TransId";
```

---

## 9. Inventory & Costing Architecture

### 9.1 Costing Methods

| Method | Code | How it works |
|---|---|---|
| **Moving Average (AVECO)** | `A` | Cost recalculated on each receipt. `OITM.AvgPrice` updated automatically |
| **FIFO** | `F` | Cost layers tracked in `OITL`/`ITL1`. Oldest cost consumed first |
| **Standard Cost** | `S` | Fixed cost set manually. Variances posted to variance account |
| **Serial/Batch** | `B` | Cost tracked per serial number or batch |

### 9.2 FIFO Layer Architecture

```
OITL (Inventory Transaction Layers)
│   LogEntry    — Primary key (links to ITL1)
│   ItemCode    — Item code
│   DocType     — Transaction type (see codes above)
│   DocEntry    — Document internal ID
│   DocLine     — Document line number
│   DocDate     — Transaction date
│   Quantity    — Quantity moved (+IN / -OUT)
│   LocCode     — Warehouse code
│
└── ITL1 (Layer Cost Details)
        LogEntry    — Links to OITL
        ItemCode    — Item code
        TransValue  — Cost value (USD)
        Price       — Unit price

-- FIFO Current Stock Valuation
SELECT
    TL."ItemCode",
    TL."LocCode"                AS "Warehouse",
    SUM(TL."Quantity")          AS "CurrentQty",
    SUM(TC."TransValue")        AS "CurrentValue_USD",
    CASE WHEN SUM(TL."Quantity") <> 0
         THEN SUM(TC."TransValue") / SUM(TL."Quantity")
         ELSE 0
    END                         AS "FIFO_UnitCost"
FROM OITL TL
INNER JOIN ITL1 TC ON TC."LogEntry" = TL."LogEntry"
                   AND TC."ItemCode" = TL."ItemCode"
GROUP BY TL."ItemCode", TL."LocCode"
HAVING SUM(TL."Quantity") > 0;
```

### 9.3 Stock Level Fields (OITW)

```
OITW — Item Warehouse
│   ItemCode    — Item code
│   WhsCode     — Warehouse code
│   OnHand      — Current stock quantity
│   IsCommited  — Committed (on Sales Orders/Production)
│   OnOrder     — On order (Purchase Orders)
│   StockValue  — Current stock value (FIFO/Avg)
│
│   Available = OnHand - IsCommited
│   Total Available = OnHand - IsCommited + OnOrder
```

### 9.4 Stock Movement Table Mapping

| Movement Type | IN table | OUT table | DocType |
|---|---|---|---|
| Purchase (GRPO) | `OPDN/PDN1` | — | 20 |
| Purchase (A/P Invoice) | `OPCH/PCH1` | — | 18 |
| Sale (Delivery) | — | `ODLN/DLN1` | 15 |
| Sale (A/R Invoice) | — | `OINV/INV1` | 13 |
| Production Receipt | `OIGN/IGN1` | — | 59 |
| Production Issue | — | `OIGE/IGE1` | 60 |
| Manual GR | `OIGN/IGN1` | — | 59 |
| Manual GI | — | `OIGE/IGE1` | 60 |
| Transfer | `OWTR/WTR1` | `OWTR/WTR1` | 162 |

---

## 10. Query Manager — Architecture & Best Practices

### 10.1 Query Manager Overview

SAP B1 Query Manager is a built-in SQL query tool accessible from:
`Tools → Queries → Query Manager`

Queries are stored in table `OUQR` (User Query header) and `UQR1` (query text).

### 10.2 Query Categories

| Category | Purpose |
|---|---|
| **General** | Saved in Query Manager for reuse |
| **System** | SAP-delivered system queries |
| **User** | User-created and saved queries |

### 10.3 Parameter Syntax in Query Manager

```sql
-- Parameters use [%0], [%1], [%2], ... syntax
-- SAP B1 prompts user with dialog before running

-- Date parameter
WHERE T0."DocDate" BETWEEN '[%0]' AND '[%1]'
-- or without quotes (HANA auto-converts):
WHERE T0."DocDate" BETWEEN [%0] AND [%1]

-- Text LIKE parameter (wildcard search)
WHERE T0."CardName" LIKE '%' || '[%0]' || '%'

-- Exact match parameter
WHERE T0."WhsCode" = '[%0]'

-- Optional parameter with % for All
WHERE T0."WhsCode" LIKE IFNULL('[%0]', '%')

-- Numeric parameter
WHERE T0."DocTotal" > [%0]

-- Multi-select (use IN with manual comma-separated)
WHERE T0."ItemCode" IN ('[%0]')
```

### 10.4 Column Alias Best Practices

```sql
-- Always use descriptive aliases
-- For Russian SAP UI:
SELECT
    T0."DocNum"     AS "Номер документа",
    T0."DocDate"    AS "Дата",
    T0."CardCode"   AS "Код клиента",
    T0."CardName"   AS "Наименование",
    T0."DocTotal"   AS "Сумма документа"

-- For English SAP UI:
SELECT
    T0."DocNum"     AS "Document Number",
    T0."DocDate"    AS "Date",
    T0."CardCode"   AS "BP Code",
    T0."CardName"   AS "BP Name",
    T0."DocTotal"   AS "Document Total"
```

### 10.5 Query Manager Limitations

- Maximum query result: ~65,000 rows (UI limitation)
- No stored procedures execution
- No DDL (CREATE/DROP/ALTER)
- No multi-statement batches
- Parameters are positional (`[%0]`, `[%1]`, etc.), max 9 parameters
- Cannot use temp tables (use CTEs instead)
- Query text stored in `OUQR.QString`

### 10.6 Saving Queries Programmatically

```sql
-- View all saved user queries
SELECT
    T0."QNum"       AS "QueryID",
    T0."QName"      AS "QueryName",
    T0."QString"    AS "QueryText",
    T0."ExpType"    AS "QueryType",  -- 0=Report, 1=Alert, 2=Wizard
    T0."IntrnalKey" AS "InternalID"
FROM OUQR T0
ORDER BY T0."QName";
```

### 10.7 Alerts from Queries

Alerts run saved queries on a schedule and notify users:
`Administration → Alerts Management → New Alert → Query-Based`

---

## 11. Report Manager — Crystal Reports Integration

### 11.1 Report Architecture

```
SAP B1 Report Manager
│
├── Built-in Reports (SAP-delivered, .rpt files)
│   ├── Financial Reports   (P&L, Balance Sheet, Trial Balance)
│   ├── Inventory Reports   (Stock Status, Valuation)
│   ├── Sales Reports       (Sales Analysis)
│   └── Purchasing Reports  (Purchase Analysis)
│
├── User-Defined Reports (Custom Crystal Reports)
│   ├── Connected to SAP B1 HANA database directly
│   ├── Stored in: Administration → Setup → Reports
│   └── Accessible via: Reports → [Module] → Custom Reports
│
└── Print Layouts (PLD)
    ├── Used for printing documents (invoices, POs, etc.)
    └── Stored in ORCV / RCV1
```

### 11.2 Crystal Reports Connection to HANA

```
Crystal Reports Designer
    └── Database → Set Datasource Location
         └── HANA ODBC connection
              ├── Server: [HANA server hostname]
              ├── Port:   30015 (default HANA SQL port)
              └── Schema: [Company database name]

-- Key Crystal Reports settings:
-- Database Driver: SAP HANA ODBC
-- Record Selection Formula: equivalent to SQL WHERE
-- Grouping: equivalent to GROUP BY
-- Running Totals: equivalent to window functions
```

### 11.3 Report Parameters in Crystal Reports

```
Crystal Parameter → SAP B1 Prompt dialog
    {?StartDate}  → Date range start
    {?EndDate}    → Date range end
    {?CardCode}   → BP filter
    {?WhsCode}    → Warehouse filter

-- In SQL Command (Crystal):
SELECT * FROM OINV T0
WHERE T0."DocDate" BETWEEN {?StartDate} AND {?EndDate}
  AND T0."CardCode" LIKE '%' || {?CardCode} || '%'
```

### 11.4 Key Report Types

| Report | Module | Tables Used |
|---|---|---|
| Trial Balance | Finance | `OACT`, `JDT1` |
| P&L Statement | Finance | `OACT`, `JDT1`, `OFPR` |
| Balance Sheet | Finance | `OACT`, `JDT1` |
| Cash Flow | Finance | `JDT1`, `ORCT`, `OVPM` |
| AR Aging | Finance | `OINV`, `OCRD` |
| AP Aging | Finance | `OPCH`, `OCRD` |
| Inventory Valuation | Inventory | `OITM`, `OITW`, `OITL`, `ITL1` |
| Stock Status | Inventory | `OITM`, `OITW` |
| Sales Analysis | Sales | `OINV`, `INV1`, `OITM`, `OCRD` |
| Purchase Analysis | Purchasing | `OPCH`, `PCH1`, `OITM`, `OCRD` |
| Customer Statement | Finance/Sales | `JDT1`, `OCRD` |
| Vendor Statement | Finance/Purch | `JDT1`, `OCRD` |

---

## 12. Analytics & Dashboard Architecture

### 12.1 SAP B1 Analytics Options

```
SAP B1 Analytics Stack
│
├── Built-in Dashboard (Cockpit)
│   ├── Drag-and-drop widgets
│   ├── Powered by saved User Queries
│   └── Pervasive Analytics (embedded charts)
│
├── SAP B1 Analytics Powered by HANA
│   ├── Pre-built HANA calculation views
│   ├── Semantic layer on top of B1 tables
│   └── Consumed by Excel, Lumira, PowerBI
│
├── SAP Lumira Discovery
│   ├── Self-service BI tool
│   └── Connects to HANA views
│
├── Power BI / Excel (External)
│   ├── Direct HANA ODBC connection
│   ├── Custom SQL queries as data source
│   └── Refreshable reports
│
└── Crystal Reports (Pixel-perfect)
    ├── Formatted printed reports
    └── Stored in Report Manager
```

### 12.2 Pervasive Analytics Widgets

SAP B1 10.x Pervasive Analytics widgets use:
- **Queries** stored in Query Manager
- **KPI** targets defined in Pervasive Analytics Designer
- **Chart types**: Bar, Line, Pie, Gauge, List

```sql
-- Example: Dashboard KPI — Monthly Sales Total
SELECT
    YEAR(T0."DocDate")     AS "Year",
    MONTH(T0."DocDate")    AS "Month",
    SUM(T0."DocTotal")     AS "TotalSales_USD",
    COUNT(T0."DocEntry")   AS "InvoiceCount",
    COUNT(DISTINCT T0."CardCode") AS "UniqueCustomers"
FROM OINV T0
WHERE T0."CANCELED" = 'N'
  AND T0."DocDate" >= ADD_MONTHS(CURRENT_DATE, -12)
GROUP BY YEAR(T0."DocDate"), MONTH(T0."DocDate")
ORDER BY 1, 2;
```

### 12.3 Key Analytics Queries

**Top 10 Customers by Revenue:**
```sql
SELECT TOP 10
    T0."CardCode",
    T0."CardName",
    SUM(T1."LineTotal") AS "Revenue_USD"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T0."CANCELED" = 'N'
  AND T0."DocDate" BETWEEN [%0] AND [%1]
GROUP BY T0."CardCode", T0."CardName"
ORDER BY SUM(T1."LineTotal") DESC;
```

**Monthly Sales vs Previous Year:**
```sql
SELECT
    MONTH(T0."DocDate")                        AS "Month",
    SUM(CASE WHEN YEAR(T0."DocDate") = YEAR(CURRENT_DATE)
             THEN T0."DocTotal" ELSE 0 END)    AS "CurrentYear",
    SUM(CASE WHEN YEAR(T0."DocDate") = YEAR(CURRENT_DATE) - 1
             THEN T0."DocTotal" ELSE 0 END)    AS "PreviousYear"
FROM OINV T0
WHERE T0."CANCELED" = 'N'
  AND YEAR(T0."DocDate") BETWEEN YEAR(CURRENT_DATE) - 1
                               AND YEAR(CURRENT_DATE)
GROUP BY MONTH(T0."DocDate")
ORDER BY 1;
```

**Inventory ABC Analysis:**
```sql
SELECT
    T0."ItemCode",
    T0."ItemName",
    SUM(T1."LineTotal")   AS "Revenue",
    SUM(T1."Quantity")    AS "QtySold",
    ROUND(
        SUM(T1."LineTotal") * 100 /
        SUM(SUM(T1."LineTotal")) OVER (),
    2)                    AS "RevenueShare_Pct",
    CASE
        WHEN SUM(SUM(T1."LineTotal")) OVER (
             ORDER BY SUM(T1."LineTotal") DESC
             ROWS UNBOUNDED PRECEDING
        ) / SUM(SUM(T1."LineTotal")) OVER () <= 0.8 THEN 'A'
        WHEN SUM(SUM(T1."LineTotal")) OVER (
             ORDER BY SUM(T1."LineTotal") DESC
             ROWS UNBOUNDED PRECEDING
        ) / SUM(SUM(T1."LineTotal")) OVER () <= 0.95 THEN 'B'
        ELSE 'C'
    END                   AS "ABCClass"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T0."CANCELED" = 'N'
  AND T0."DocDate" BETWEEN [%0] AND [%1]
GROUP BY T0."ItemCode", T0."ItemName"
ORDER BY SUM(T1."LineTotal") DESC;
```

---

## 13. Currency & Exchange Rate Architecture

### 13.1 Currency Concepts in SAP B1

```
System Currency (LC - Local Currency)
    └── Defined in: Administration → System Initialization → Company Details
    └── Cannot be changed after go-live
    └── Examples: USD, EUR, UZS

Foreign Currency (FC)
    └── Any currency other than LC
    └── Maintained in: Administration → Setup → Financials → Currencies

Multi-Currency Handling:
    ├── FC fields: FCDebit, FCCredit, FCCurrency (in JDT1)
    ├── LC fields: Debit, Credit (always in system currency)
    └── Formula: LC Amount = FC Amount × Exchange Rate
```

### 13.2 Exchange Rate Tables

```sql
-- ORTT — Exchange Rates
-- One row per currency per date

SELECT
    T0."Currency",
    T0."RateDate",
    T0."Rate"
FROM ORTT T0
WHERE T0."Currency" = 'UZS'
ORDER BY T0."RateDate" DESC;

-- Get latest rate for conversion
SELECT "Rate"
FROM ORTT
WHERE "Currency" = 'UZS'
ORDER BY "RateDate" DESC
LIMIT 1;

-- Convert LC to FC
SELECT
    T0."DocTotal"                           AS "Total_USD",
    T0."DocTotal" * R."Rate"               AS "Total_UZS"
FROM OINV T0
CROSS JOIN (
    SELECT "Rate" FROM ORTT
    WHERE "Currency" = 'UZS'
    ORDER BY "RateDate" DESC LIMIT 1
) R
WHERE T0."CANCELED" = 'N';
```

### 13.3 Multi-Currency Query Pattern

```sql
-- Handle both USD and FC (UZS) in same query
SELECT
    CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
         THEN T0."FCDebit"
         ELSE T0."Debit"
    END AS "Debit",
    CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
         THEN T0."FCCredit"
         ELSE T0."Credit"
    END AS "Credit",
    CASE WHEN IFNULL(T0."FCCurrency", '') = ''
         THEN 'USD'
         ELSE T0."FCCurrency"
    END AS "Currency"
FROM JDT1 T0
```

---

## 14. User-Defined Fields (UDF) & User-Defined Tables (UDT)

### 14.1 UDF Architecture

User-Defined Fields extend standard SAP B1 tables without customization.

```
Administration → Tools → Customization Tools → User-Defined Fields
│
├── Form type (table to extend)
│   ├── OCRD → Business Partner Master
│   ├── OINV/INV1 → Invoice Header/Lines
│   └── OITM → Items Master
│
└── Field definition:
    ├── Name: Field code (up to 8 chars)
    ├── Description: Display label
    ├── Type: Alpha / Numeric / Date / Amount / Quantity / Rate
    └── Structure: Regular / Table (linked values)
```

**UDF Naming convention:**
```sql
-- UDFs are stored with "U_" prefix
SELECT
    T0."U_TaxRegNum"    AS "Tax Registration",
    T0."U_Region"       AS "Region",
    T0."U_CustType"     AS "Customer Type"
FROM OCRD T0
WHERE T0."U_CustType" = 'Retail';
```

### 14.2 UDT Architecture

User-Defined Tables are completely custom tables:

```
Administration → Tools → Customization Tools → User-Defined Tables

Table naming: "@TableName" (always prefixed with @)

Example:
    @PRICE_TIERS    ← Custom price tier table
    @ROUTES         ← Custom delivery routes
    @PROMO          ← Promotions table

-- Querying UDT:
SELECT
    T0."Code",
    T0."Name",
    T0."U_MinQty",
    T0."U_Discount"
FROM "@PRICE_TIERS" T0
WHERE T0."U_ItemGrp" = [%0];
```

---

## 15. Integration Framework (DI API & Service Layer)

### 15.1 Integration Methods

```
SAP B1 Integration Options
│
├── DI API (Data Interface API)
│   ├── COM-based technology (.NET / VB)
│   ├── Requires SAP B1 client installation
│   ├── Full document creation & update
│   └── Use for: Add-ons, legacy integrations
│
├── Service Layer (REST/OData)
│   ├── RESTful API (HTTP/HTTPS)
│   ├── SAP B1 9.3+ required
│   ├── JSON request/response
│   └── Use for: Modern integrations, web apps, mobile
│
├── B1iF (Integration Framework)
│   ├── SAP middleware for B2B/B2C
│   ├── EDI, web services, e-commerce
│   └── Scenario-based (inbound/outbound)
│
└── Direct HANA Connection
    ├── Read-only SQL queries
    ├── ODBC/JDBC connection
    └── Use for: Reporting, analytics, BI tools
```

### 15.2 Service Layer Key Endpoints

```
Base URL: https://[server]:50000/b1s/v1/

-- Business Partners
GET    /BusinessPartners
POST   /BusinessPartners
PATCH  /BusinessPartners('C001')

-- Invoices
GET    /Invoices
POST   /Invoices
PATCH  /Invoices(1234)

-- Items
GET    /Items
POST   /Items

-- Stock Transactions
POST   /GoodsReceipts      ← Goods Receipt (OIGN)
POST   /GoodsIssues        ← Goods Issue (OIGE)
POST   /StockTransfers     ← Warehouse Transfer (OWTR)

-- Query via Service Layer
GET    /SQLQueries          ← Get saved queries
POST   /SQLQueries/run      ← Execute query
```

---

## 16. Key Field Reference — Critical Fields per Table

### 16.1 Universal Document Fields (All Marketing Documents)

| Field | Description | Values |
|---|---|---|
| `DocEntry` | Internal unique ID (PK) | Auto-number |
| `DocNum` | User-visible document number | Per series |
| `DocDate` | Document date | DATE |
| `TaxDate` | Tax/posting date | DATE |
| `DocDueDate` | Due date | DATE |
| `CardCode` | BP code | Links to OCRD |
| `CardName` | BP name (copy at time of posting) | Snapshot |
| `DocStatus` | O=Open, C=Closed | CHAR(1) |
| `CANCELED` | N=Active, Y=Canceled | CHAR(1) |
| `DocCur` | Document currency | NVARCHAR(3) |
| `DocRate` | Exchange rate at time of posting | NUMERIC |
| `DocTotal` | Total amount (LC) | NUMERIC |
| `DocTotalFC` | Total amount (FC) | NUMERIC |
| `Comments` | Header remarks | NVARCHAR |
| `SlpCode` | Sales employee | → OSLP |
| `TrnspCode` | Shipping method | → OSHP |
| `PayTermsGrp` | Payment terms | → OCTG |
| `NumAtCard` | BP reference number | NVARCHAR |
| `Series` | Document numbering series | → NNM1 |
| `CreateDate` | Creation date | DATE |
| `UserSign` | Created by user | → OUSR |

### 16.2 Universal Document Line Fields (All Marketing Lines)

| Field | Description |
|---|---|
| `DocEntry` | Links to header |
| `LineNum` | Line number (0-based) |
| `ItemCode` | Item code → OITM |
| `Dscription` | Line description (snapshot) |
| `Quantity` | Quantity |
| `Price` | Unit price (FC) |
| `PriceAfVAT` | Price including tax |
| `Currency` | Line currency |
| `Rate` | Exchange rate |
| `DiscPrcnt` | Discount % |
| `LineTotal` | Line total (LC) |
| `TotalFrgn` | Line total (FC) |
| `WhsCode` | Warehouse code → OWHS |
| `TaxCode` | Tax code |
| `VatPrcnt` | Tax % |
| `GrossBuyPr` | Item purchase price |
| `StockPrice` | Inventory cost |
| `BaseEntry` | Source document DocEntry |
| `BaseType` | Source document type |
| `BaseLine` | Source document line |

---

## 17. JOIN Patterns & Query Templates

### 17.1 Standard Document Query Template

```sql
-- Template: Any marketing document with lines
SELECT
    T0."DocNum"         AS "Doc Number",
    T0."DocDate"        AS "Date",
    T0."CardCode"       AS "BP Code",
    T0."CardName"       AS "BP Name",
    T1."ItemCode"       AS "Item Code",
    T1."Dscription"     AS "Description",
    T1."Quantity"       AS "Qty",
    T1."Price"          AS "Unit Price",
    T1."LineTotal"      AS "Line Total",
    T0."DocTotal"       AS "Doc Total"
FROM [HEADER_TABLE] T0          -- e.g., OINV, OPCH, ORDR
INNER JOIN [LINES_TABLE] T1
    ON T0."DocEntry" = T1."DocEntry"
WHERE T0."CANCELED" = 'N'
  AND T0."DocDate" BETWEEN [%0] AND [%1]
ORDER BY T0."DocDate", T0."DocNum", T1."LineNum";
```

### 17.2 BP + Document + Item JOIN

```sql
SELECT
    BP."CardCode",
    BP."CardName",
    BP."GroupCode",
    GRP."ItmsGrpNam"    AS "BP Group",
    T0."DocNum",
    T0."DocDate",
    ITM."ItemCode",
    ITM."ItemName",
    ITM."ItmsGrpCod",
    ITMG."ItmsGrpNam"   AS "Item Group",
    T1."Quantity",
    T1."LineTotal"
FROM OINV T0
INNER JOIN INV1 T1      ON T0."DocEntry" = T1."DocEntry"
INNER JOIN OCRD BP      ON T0."CardCode" = BP."CardCode"
INNER JOIN OCRG GRP     ON BP."GroupCode" = GRP."GroupCode"
INNER JOIN OITM ITM     ON T1."ItemCode" = ITM."ItemCode"
INNER JOIN OITB ITMG    ON ITM."ItmsGrpCod" = ITMG."ItmsGrpCod"
WHERE T0."CANCELED" = 'N'
  AND T0."DocDate" BETWEEN [%0] AND [%1];
```

### 17.3 AP Aging Report Template

```sql
SELECT
    T0."CardCode",
    T0."CardName",
    T0."DocNum",
    T0."DocDate",
    T0."DocDueDate",
    T0."DocTotal"                           AS "InvoiceTotal",
    T0."PaidToDate"                         AS "Paid",
    T0."DocTotal" - T0."PaidToDate"         AS "Outstanding",
    DAYS_BETWEEN(T0."DocDueDate", NOW())    AS "DaysOverdue",
    CASE
        WHEN DAYS_BETWEEN(T0."DocDueDate", NOW()) <= 0  THEN 'Not Due'
        WHEN DAYS_BETWEEN(T0."DocDueDate", NOW()) <= 30 THEN '1-30 Days'
        WHEN DAYS_BETWEEN(T0."DocDueDate", NOW()) <= 60 THEN '31-60 Days'
        WHEN DAYS_BETWEEN(T0."DocDueDate", NOW()) <= 90 THEN '61-90 Days'
        ELSE 'Over 90 Days'
    END                                     AS "AgingBucket"
FROM OPCH T0
WHERE T0."CANCELED" = 'N'
  AND T0."DocStatus" = 'O'
ORDER BY T0."CardCode", T0."DocDueDate";
```

### 17.4 Inventory Movement Report Template (CTE)

```sql
WITH Movements AS (
    -- Goods IN
    SELECT
        'IN'            AS "Direction",
        T0."DocDate",
        T0."DocNum",
        'GoodsReceipt'  AS "DocType",
        T1."ItemCode",
        T1."Quantity",
        T1."StockPrice" AS "UnitCost",
        T1."WhsCode"
    FROM OIGN T0
    INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."CANCELED" = 'N'

    UNION ALL

    -- Goods OUT
    SELECT
        'OUT'           AS "Direction",
        T0."DocDate",
        T0."DocNum",
        'GoodsIssue'    AS "DocType",
        T1."ItemCode",
        T1."Quantity" * -1,
        T1."StockPrice",
        T1."WhsCode"
    FROM OIGE T0
    INNER JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."CANCELED" = 'N'
)
SELECT
    M."DocDate",
    M."DocType",
    M."DocNum",
    M."ItemCode",
    ITM."ItemName",
    M."Direction",
    M."Quantity",
    M."UnitCost",
    ABS(M."Quantity") * M."UnitCost" AS "TotalValue",
    M."WhsCode"
FROM Movements M
INNER JOIN OITM ITM ON M."ItemCode" = ITM."ItemCode"
WHERE M."DocDate" BETWEEN [%0] AND [%1]
  AND M."ItemCode" LIKE '%' || '[%2]' || '%'
ORDER BY M."DocDate", M."DocType", M."DocNum";
```

### 17.5 Sales vs Purchase Comparison (PIVOT-style)

```sql
SELECT
    ITM."ItemCode",
    ITM."ItemName",
    SUM(CASE WHEN T0."TransType" = 13 THEN T1."Quantity" ELSE 0 END) AS "SoldQty",
    SUM(CASE WHEN T0."TransType" = 13 THEN T1."LineTotal" ELSE 0 END) AS "SalesValue",
    SUM(CASE WHEN T0."TransType" = 18 THEN T1."Quantity" ELSE 0 END) AS "PurchasedQty",
    SUM(CASE WHEN T0."TransType" = 18 THEN T1."LineTotal" ELSE 0 END) AS "PurchaseValue"
FROM OJDT T0
INNER JOIN JDT1 T1 ON T0."TransId" = T1."TransId"
INNER JOIN OITM ITM ON T1."ItemCode" = ITM."ItemCode"  -- Only if ItemCode exists in JDT1
WHERE T0."RefDate" BETWEEN [%0] AND [%1]
GROUP BY ITM."ItemCode", ITM."ItemName"
ORDER BY SUM(CASE WHEN T0."TransType" = 13 THEN T1."LineTotal" ELSE 0 END) DESC;
```

---

## 18. Performance Optimization for Queries

### 18.1 Key Optimization Rules

**1. Always filter on indexed fields:**
```sql
-- FAST: Filter on DocDate (indexed)
WHERE T0."DocDate" BETWEEN '2024-01-01' AND '2024-12-31'

-- SLOW: Filter with function on indexed field (prevents index use)
WHERE YEAR(T0."DocDate") = 2024  -- Avoid this
```

**2. Use CTEs instead of correlated subqueries:**
```sql
-- SLOW: Correlated subquery (runs once per row)
SELECT T0."ItemCode",
    (SELECT SUM(T1."Quantity") FROM INV1 T1
     WHERE T1."ItemCode" = T0."ItemCode") AS "SoldQty"
FROM OITM T0;

-- FAST: CTE with aggregation first
WITH SoldSummary AS (
    SELECT "ItemCode", SUM("Quantity") AS "SoldQty"
    FROM INV1
    GROUP BY "ItemCode"
)
SELECT T0."ItemCode", S."SoldQty"
FROM OITM T0
LEFT JOIN SoldSummary S ON S."ItemCode" = T0."ItemCode";
```

**3. Avoid SELECT \* in production queries:**
```sql
-- SLOW: Fetches all columns
SELECT * FROM OINV T0 INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry";

-- FAST: Fetch only needed columns
SELECT T0."DocNum", T0."DocDate", T1."ItemCode", T1."LineTotal"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry";
```

**4. Always filter `CANCELED = 'N'`:**
```sql
-- Include in WHERE clause for all document queries
WHERE T0."CANCELED" = 'N'
-- This dramatically reduces rows scanned
```

**5. Limit date ranges:**
```sql
-- Add date filter even when not strictly required
-- HANA stores data in columnar format — date filters are very effective
AND T0."DocDate" >= ADD_MONTHS(CURRENT_DATE, -24)  -- Last 2 years
```

**6. Use LIMIT for testing:**
```sql
-- Always test with LIMIT before running full query
SELECT * FROM OINV T0 LIMIT 100;
```

### 18.2 HANA-Specific Optimization

```sql
-- Use HANA native date functions (faster than CAST+CONVERT)
WHERE YEAR(T0."DocDate") = 2024         -- Month/Year extraction
WHERE T0."DocDate" >= '2024-01-01'      -- String comparison works with DATE type

-- HANA columnar advantage: aggregations on few columns
-- Prefer GROUP BY over DISTINCT for aggregation queries
SELECT "ItemCode", SUM("Quantity")
FROM INV1
GROUP BY "ItemCode"
-- vs
SELECT DISTINCT "ItemCode" FROM INV1  -- Less optimal for aggregation

-- Use INNER JOIN over LEFT JOIN when data integrity is guaranteed
-- HANA optimizes INNER JOINs better
```

### 18.3 Common Mistakes to Avoid

| Mistake | Problem | Fix |
|---|---|---|
| `SELECT *` | Fetches all 100+ columns | Specify needed columns only |
| No `CANCELED = 'N'` | Includes voided documents | Always add this filter |
| Correlated subqueries | O(n²) performance | Use CTEs or derived tables |
| `LIKE '%text%'` on large tables | Full scan | Add additional indexed filters |
| No date range filter | Scans all history | Always filter by date |
| Using functions on WHERE fields | Prevents index use | Filter on raw field values |
| `NOT IN (subquery)` with NULLs | Returns empty result | Use `NOT EXISTS` instead |

---

## Quick Reference Card

### Most Used Tables at a Glance

```
SALES:     OINV/INV1 (Invoice)  ORDR/RDR1 (Order)  ODLN/DLN1 (Delivery)
PURCHASE:  OPCH/PCH1 (Invoice)  OPOR/POR1 (Order)  OPDN/PDN1 (GRPO)
FINANCE:   OJDT/JDT1 (Journal)  ORCT/RCT2 (Payment IN)  OVPM/VPM2 (Payment OUT)
INVENTORY: OITM (Items)  OITW (Stock)  OITL/ITL1 (Layers)  OIGN/OIGE (GR/GI)
MASTER:    OCRD (BP)  OACT (GL)  OWHS (Warehouse)  OSLP (Sales Employee)
CONFIG:    ORTT (Exchange Rates)  OFPR (Fiscal Periods)  OCTG (Payment Terms)
```

### Document Status Quick Filter

```sql
-- All open, non-canceled documents:
WHERE T0."DocStatus" = 'O' AND T0."CANCELED" = 'N'

-- All posted documents (open + closed, not canceled):
WHERE T0."CANCELED" = 'N'

-- Canceled documents only:
WHERE T0."CANCELED" = 'Y'
```

### Parameter Template

```sql
-- Standard 3-parameter query template:
-- [%0] = Start Date
-- [%1] = End Date
-- [%2] = Filter (item/BP/warehouse — use % for all)
WHERE T0."DocDate" BETWEEN [%0] AND [%1]
  AND T0."CardCode" LIKE '%' || '[%2]' || '%'
  AND T0."CANCELED" = 'N'
```

---

*Document maintained as part of SAP-B1-SQL-Library*  
*Database: SAP HANA | ERP: SAP Business One 9.x – 10.x*  
*Last updated: 2026*
