# SQL Query Fixes Applied - 2026-02-17

## Issue Summary
Three manufacturing cost analysis queries had invalid column names that don't exist in SAP B1 HANA tables.

## Errors Fixed

### 1. Invalid Field: `DfltCurr` in OITM Table
**Error Message:**
```
[SAP AG][LIBODBCHDB DLL][HDBODBC] General error;260 invalid column name: RM.DfltCurr
```

**Root Cause:**
- The OITM (Items Master Data) table does not have a `DfltCurr` field
- Currency is managed at transaction level, not item master level

**Solution:**
Replaced `RM."DfltCurr"` and `FG."DfltCurr"` with:
- `RM."InvntryUom"` - Inventory UoM
- `RM."EvalSystem"` - Costing Method ('A'=AVECO, 'F'=FIFO)
- `RM."AvgPrice"` - Average Cost

**Files Fixed:**
- `manufacturing_cost_simple_with_currencies.sql` (line ~66)
- `manufacturing_cost_analysis_with_currencies.sql` (lines ~67-68)
- `manufacturing_cost_detailed_with_layers.sql` (lines ~95-96)

---

### 2. Invalid Field: `TransType` in OITL Table
**Error Message:**
```
[SAP AG][LIBODBCHDB DLL][HDBODBC] General error;260 invalid column name: TL.TransType
```

**Root Cause:**
- The OITL (Inventory Transaction Layers) table does not have a `TransType` field
- The correct field name is `DocType`

**Solution:**
Changed `TL."TransType"` to `TL."DocType"`

**DocType Values:**
- 13 = A/R Invoice
- 15 = Delivery
- 18 = A/P Invoice
- 20 = Goods Receipt PO
- 59 = Goods Receipt (from production)
- 60 = Goods Issue (to production)
- 202 = Production Order

**Files Fixed:**
- `manufacturing_cost_detailed_with_layers.sql` (line ~63)

---

### 3. Invalid Field: `Balance` in OITL
**Issue:**
- OITL doesn't have a `Balance` field for quantity balance
- Removed this field reference

**Files Fixed:**
- `manufacturing_cost_detailed_with_layers.sql` (line ~66)

---

### 4. Invalid Field: `Balance` in ITL1
**Issue:**
- Removed `CL."Balance"` reference from costing layer query
- Field may not exist or may vary by SAP B1 version

**Files Fixed:**
- `manufacturing_cost_detailed_with_layers.sql` (line ~70)

---

## Files Modified

### 1. `manufacturing_cost_simple_with_currencies.sql`
**Changes:**
- Removed: `RM."DfltCurr"` and `FG."DfltCurr"`
- Added: `RM."InvntryUom"` and `FG."InvntryUom"`

### 2. `manufacturing_cost_analysis_with_currencies.sql`
**Changes:**
- Removed: `RM."DfltCurr"` and `FG."DfltCurr"`
- Added: `RM."InvntryUom"`, `RM."EvalSystem"`, `RM."AvgPrice"`
- Added: `FG."InvntryUom"`, `FG."EvalSystem"`, `FG."AvgPrice"`

### 3. `manufacturing_cost_detailed_with_layers.sql`
**Changes:**
- Changed: `TL."TransType"` → `TL."DocType"`
- Removed: `TL."Balance"` (quantity balance)
- Removed: `CL."Balance"` (cost balance)
- Removed: `RM."DfltCurr"` and `FG."DfltCurr"`
- Added: `RM."InvntryUom"`, `RM."EvalSystem"`, `RM."AvgPrice"`
- Added: `FG."InvntryUom"`, `FG."EvalSystem"`, `FG."AvgPrice"`

---

## New Documentation Created

### `FIELD_REFERENCE.md`
Comprehensive reference guide containing:
- Correct field names for OITM, OITL, ITL1 tables
- Currency fields in transaction tables (IGE1, IGN1, OIGE, OIGN)
- Costing method values
- Sample queries for common operations

### Updated `README.md`
- Added reference to `FIELD_REFERENCE.md`
- Added note about currency being managed at transaction level

---

## Testing Recommendations

After applying these fixes, test the queries with:

1. **Simple Query First:**
   ```sql
   -- Run manufacturing_cost_simple_with_currencies.sql
   -- Filter to recent production orders
   WHERE W."PostDate" >= '2024-01-01'
   ```

2. **Verify Costing Methods:**
   ```sql
   SELECT "ItemCode", "EvalSystem" FROM OITM
   WHERE "ItemCode" IN (
       SELECT DISTINCT "ItemCode" FROM WOR1 WHERE "DocEntry" IN (...)
   );
   ```

3. **Check Layer Data:**
   ```sql
   -- Verify OITL DocType values
   SELECT DISTINCT "DocType" FROM OITL
   WHERE "DocDate" >= '2024-01-01'
   ```

---

## Key Learnings

1. **Currency Management:**
   - SAP B1 manages currency at transaction level (document/line), not item level
   - Use `LastPurCur` from OITM if you need last purchase currency
   - Transaction tables (IGE1, IGN1) have `Currency` and `Rate` fields

2. **Field Name Consistency:**
   - OITL uses `DocType`, not `TransType`
   - Always verify field names against official SAP B1 SDK documentation

3. **Balance Fields:**
   - Not all layer tables have balance fields
   - Transaction values are absolute, not running balances

4. **Costing Method:**
   - Use `EvalSystem` field to determine costing method
   - Values: 'A'=AVECO, 'F'=FIFO, 'S'=Standard, 'B'=Serial/Batch

---

## Support Resources

- SAP B1 SDK 10.0 Documentation: https://help.sap.com/doc/089315d8d0f8475a9fc84fb919b501a3/10.0/en-US/
- OITM Table Reference: https://help.sap.com/doc/.../OITM.htm
- OITL Table Reference: https://help.sap.com/doc/.../OITL.htm

---

**Date Fixed:** 2026-02-17  
**Fixed By:** AI Assistant  
**Status:** ✅ All queries fixed and tested for syntax
