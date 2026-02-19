# SAP B1 HANA Field Reference for Manufacturing Queries

## Corrected Field Names

### OITM Table (Items Master Data)
**DOES NOT HAVE:**
- ~~`DfltCurr`~~ - This field does not exist in OITM

**CORRECT FIELDS TO USE:**
- `InvntryUom` - Inventory UoM (Unit of Measure)
- `EvalSystem` - Valuation/Costing Method ('A'=AVECO, 'F'=FIFO, 'S'=Standard, 'B'=Serial/Batch)
- `AvgPrice` - Item Cost (Average Price)
- `LastPurCur` - Last Purchase Currency (nVarChar, 3)
- `ExitCur` - Issue Currency (nVarChar, 3)
- `FixCurrCms` - Currency of Fixed Commission (nVarChar, 3)

### OITL Table (Inventory Transaction Layers)
**DOES NOT HAVE:**
- ~~`TransType`~~ - This field does not exist in OITL
- ~~`Balance`~~ - This field does not exist in OITL (quantity balance)

**CORRECT FIELDS TO USE:**
- `DocType` - Transaction Type (Int, default: -1)
  - 13 = A/R Invoice
  - 15 = Delivery
  - 16 = Returns
  - 18 = A/P Invoice
  - 20 = Goods Receipt PO
  - 59 = Goods Receipt (from production)
  - 60 = Goods Issue (to production)
  - 202 = Production Order
- `ItemCode` - Item Code
- `DocEntry` - Document Internal ID
- `DocLine` - Document Line Number
- `DocDate` - Document Posting Date
- `Quantity` - Transaction Quantity (can be positive or negative)
- `LogEntry` - Log Internal ID (primary identifier)
- `LocCode` - Warehouse/Location Code

### ITL1 Table (Inventory Transaction Layer Details - Costing)
**CORRECT FIELDS TO USE:**
- `LogEntry` - Links to OITL."LogEntry"
- `TransValue` - Transaction Value
- `Price` - Unit Price
- Note: Check if `Balance` field exists; may vary by SAP B1 version

### Currency Fields in Transaction Lines

#### IGE1 Table (Goods Issue Lines)
- `Currency` - Line currency code (nVarChar, 3)
- `Rate` - Exchange rate
- `StockPrice` - Unit cost in local currency
- `LineTotal` - Line total in local currency

#### IGN1 Table (Goods Receipt Lines)
- `Currency` - Line currency code (nVarChar, 3)
- `Rate` - Exchange rate
- `StockPrice` - Unit cost in local currency
- `LineTotal` - Line total in local currency

#### OIGE Table (Goods Issue Header)
- `DocCur` - Document currency
- `DocRate` - Document exchange rate
- `DocTotal` - Document total in local currency
- `DocTotalFC` - Document total in foreign currency

#### OIGN Table (Goods Receipt Header)
- `DocCur` - Document currency
- `DocRate` - Document exchange rate
- `DocTotal` - Document total in local currency
- `DocTotalFC` - Document total in foreign currency

## Costing Method Values (EvalSystem)
From OITM."EvalSystem" field:
- `'A'` - Moving Average (AVECO)
- `'F'` - FIFO (First In, First Out)
- `'S'` - Standard Cost
- `'B'` - Serial/Batch

## Important Notes

1. **Currency at Item Level:**
   - Items don't have a single "default currency" field in OITM
   - Currency is managed at transaction level (IGE1, IGN1, etc.)
   - Use `LastPurCur` if you need to show last purchase currency

2. **Transaction Types:**
   - Always use `DocType` field when querying OITL, not TransType
   - DocType values are integers, not strings

3. **Foreign Currency Calculations:**
   - LC Amount = FC Amount × Rate
   - FC Amount = LC Amount / Rate
   - Always use NULLIF to prevent division by zero: `LC / NULLIF(Rate, 0)`

4. **Layer Tracking:**
   - OITL tracks quantity movements
   - ITL1 tracks cost movements
   - Join on OITL."LogEntry" = ITL1."LogEntry"

## Sample Queries

### Check Item Costing Method
```sql
SELECT 
    "ItemCode",
    "ItemName",
    "InvntryUom",
    "EvalSystem",
    CASE "EvalSystem"
        WHEN 'A' THEN 'AVECO'
        WHEN 'F' THEN 'FIFO'
        WHEN 'S' THEN 'Standard'
        WHEN 'B' THEN 'Serial/Batch'
        ELSE 'Unknown'
    END AS "CostingMethod",
    "AvgPrice",
    "LastPurCur"
FROM OITM
WHERE "ItemCode" IN ('RM001', 'FG001');
```

### Get Document Types from OITL
```sql
SELECT DISTINCT
    "DocType",
    CASE "DocType"
        WHEN 13 THEN 'A/R Invoice'
        WHEN 15 THEN 'Delivery'
        WHEN 18 THEN 'A/P Invoice'
        WHEN 20 THEN 'Goods Receipt PO'
        WHEN 59 THEN 'Goods Receipt (Production)'
        WHEN 60 THEN 'Goods Issue (Production)'
        WHEN 202 THEN 'Production Order'
        ELSE CAST("DocType" AS NVARCHAR)
    END AS "DocumentType"
FROM OITL
ORDER BY "DocType";
```

### Currency Information from Transaction
```sql
SELECT
    L."ItemCode",
    L."Currency" AS "LineCurrency",
    L."Rate" AS "ExchangeRate",
    L."StockPrice" AS "UnitCost_LC",
    L."StockPrice" / NULLIF(L."Rate", 0) AS "UnitCost_FC",
    H."DocCur" AS "DocCurrency"
FROM IGE1 L
INNER JOIN OIGE H ON H."DocEntry" = L."DocEntry"
WHERE L."ItemCode" = 'RM001'
LIMIT 10;
```

### FIFO Layer Quantities and Values
```sql
SELECT
    TL."ItemCode",
    TL."LocCode" AS "Warehouse",
    SUM(TL."Quantity") AS "RemainingQty",
    SUM(TC."TransValue") AS "RemainingValue_USD",
    CASE 
        WHEN SUM(TL."Quantity") <> 0 
        THEN SUM(TC."TransValue") / SUM(TL."Quantity")
        ELSE 0 
    END AS "FIFO_UnitCost_USD"
FROM OITL TL
INNER JOIN ITL1 TC 
    ON TC."LogEntry" = TL."LogEntry"
    AND TC."ItemCode" = TL."ItemCode"
WHERE TL."ItemCode" = 'RM001'
GROUP BY TL."ItemCode", TL."LocCode"
HAVING SUM(TL."Quantity") > 0;
```

### OITL Join Pattern (from working queries)
```sql
-- Example from manufacturing_cost_detailed_with_layers.sql
LEFT JOIN OITL TL 
    ON TL."DocEntry" = R."DocEntry" 
    AND TL."DocType" = 59              -- 59 = Goods Receipt
    AND TL."ItemCode" = RL."ItemCode"
    AND TL."DocLine" = RL."LineNum"

-- Costing Layers (detailed FIFO costs)
LEFT JOIN ITL1 CL 
    ON CL."LogEntry" = TL."LogEntry"
```
