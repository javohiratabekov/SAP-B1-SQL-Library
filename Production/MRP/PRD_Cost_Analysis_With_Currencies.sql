-- PRD_Cost_Analysis_With_Currencies.sql
-- Description: Production order cost report — raw materials (AVECO) vs finished goods (FIFO)
--              with Local Currency (UZS) and Foreign Currency amounts, including cost variance
-- Costing Methods: Raw Materials = AVECO, Finished Goods = FIFO
-- Tables: OWOR (Production Orders), OIGE/IGE1 (Goods Issue), OIGN/IGN1 (Goods Receipt),
--         OITM (Items), OCRY (Currencies)

SELECT
    -- ===== Production Order Information =====
    W."DocNum"                      AS "ProductionOrderNo",
    W."ItemCode"                    AS "FinishedGoodCode",
    W."ProdName"                    AS "FinishedGoodName",
    W."PostDate"                    AS "ProductionOrderDate",
    W."Status"                      AS "Status",
    
    -- ===== Raw Materials Issue Information =====
    I."DocNum"                      AS "IssueDocNo",
    I."DocDate"                     AS "IssueDate",
    
    L."ItemCode"                    AS "RawMaterialCode",
    L."Dscription"                  AS "RawMaterialName",
    RM."InvntryUom"                 AS "RawMaterialUOM",
    
    -- ===== Raw Materials Quantities & Costs (AVECO) =====
    L."Quantity"                    AS "QuantityIssued",
    L."StockPrice"                  AS "RawMaterial_UnitCost_LC",
    L."LineTotal"                   AS "RawMaterial_LineCost_LC",
    
    -- Raw Materials Foreign Currency
    L."Currency"                    AS "RawMaterial_Currency",
    L."StockPrice" / NULLIF(L."Rate", 0) AS "RawMaterial_UnitCost_FC",
    L."LineTotal" / NULLIF(L."Rate", 0)  AS "RawMaterial_LineCost_FC",
    L."Rate"                        AS "RawMaterial_ExchangeRate",
    
    -- ===== Total Issue Document Costs =====
    I."DocTotal"                    AS "TotalIssueDocCost_LC",
    I."DocTotalFC"                  AS "TotalIssueDocCost_FC",
    I."DocCur"                      AS "IssueDoc_Currency",
    I."DocRate"                     AS "IssueDoc_ExchangeRate",
    
    -- ===== Finished Goods Receipt Information (FIFO) =====
    R."DocNum"                      AS "ReceiptDocNo",
    R."DocDate"                     AS "ReceiptDate",
    
    RL."ItemCode"                   AS "FinishedGood_Received_Code",
    RL."Dscription"                 AS "FinishedGood_Received_Name",
    FG."InvntryUom"                 AS "FinishedGood_UOM",
    
    -- ===== Finished Goods Quantities & Costs (FIFO) =====
    RL."Quantity"                   AS "QuantityReceived",
    RL."StockPrice"                 AS "FinishedGood_UnitCost_LC",
    RL."LineTotal"                  AS "FinishedGood_LineCost_LC",
    
    -- Finished Goods Foreign Currency
    RL."Currency"                   AS "FinishedGood_Currency",
    RL."StockPrice" / NULLIF(RL."Rate", 0) AS "FinishedGood_UnitCost_FC",
    RL."LineTotal" / NULLIF(RL."Rate", 0)  AS "FinishedGood_LineCost_FC",
    RL."Rate"                       AS "FinishedGood_ExchangeRate",
    
    -- ===== Total Receipt Document Costs =====
    R."DocTotal"                    AS "TotalReceiptDocCost_LC",
    R."DocTotalFC"                  AS "TotalReceiptDocCost_FC",
    R."DocCur"                      AS "ReceiptDoc_Currency",
    R."DocRate"                     AS "ReceiptDoc_ExchangeRate",
    
    -- ===== Item Master Data =====
    RM."InvntryUom"                 AS "RawMaterial_UOM",
    RM."EvalSystem"                 AS "RawMaterial_CostingMethod",
    FG."InvntryUom"                 AS "FinishedGood_UOM",
    FG."EvalSystem"                 AS "FinishedGood_CostingMethod",
    
    -- ===== Cost Calculation Summary =====
    -- Variance between Finished Goods value and Raw Materials consumed
    IFNULL(RL."LineTotal", 0) - IFNULL(L."LineTotal", 0) AS "Cost_Variance_LC",
    IFNULL(RL."LineTotal" / NULLIF(RL."Rate", 0), 0) - 
    IFNULL(L."LineTotal" / NULLIF(L."Rate", 0), 0)       AS "Cost_Variance_FC"

FROM OWOR W

-- ===== Raw Materials Issued (AVECO Costing) =====
LEFT JOIN IGE1 L 
    ON L."BaseEntry" = W."DocEntry"
    AND L."BaseType" = 202          -- 202 = Production Order
LEFT JOIN OIGE I 
    ON I."DocEntry" = L."DocEntry"
LEFT JOIN OITM RM
    ON RM."ItemCode" = L."ItemCode"

-- ===== Finished Goods Received (FIFO Costing) =====
LEFT JOIN IGN1 RL
    ON RL."BaseEntry" = W."DocEntry"
    AND RL."BaseType" = 202         -- 202 = Production Order
LEFT JOIN OIGN R
    ON R."DocEntry" = RL."DocEntry"
LEFT JOIN OITM FG
    ON FG."ItemCode" = RL."ItemCode"

WHERE 
    W."Status" <> 'C'               -- Exclude cancelled orders (optional)
    AND (L."DocEntry" IS NOT NULL OR RL."DocEntry" IS NOT NULL)  -- Has either issue or receipt

ORDER BY
    W."DocNum",
    I."DocDate",
    I."DocNum",
    L."LineNum",
    R."DocDate",
    R."DocNum",
    RL."LineNum";

/* 
===== USAGE NOTES =====

1. COSTING METHODS:
   - Raw Materials: AVECO (Average Cost)
   - Finished Goods: FIFO (First In, First Out)
   - Ensure items are configured with correct costing methods in SAP B1

2. CURRENCY FIELDS:
   - LC (Local Currency) = UZS (Uzbekistan Som)
   - FC (Foreign Currency) = Original transaction currency
   - Exchange rates are stored at transaction time

3. COST VARIANCE:
   - Positive variance = Finished goods value > Raw materials consumed
   - Negative variance = Raw materials consumed > Finished goods value
   - Variance analysis helps identify production inefficiencies or cost allocation issues

4. FILTERING OPTIONS:
   - Add date range filter: AND W."PostDate" BETWEEN '2024-01-01' AND '2024-12-31'
   - Add specific items: AND W."ItemCode" IN ('FG001', 'FG002')
   - Add warehouse: AND L."WhsCode" = 'WH01'

5. NULL HANDLING:
   - LEFT JOINs ensure all production orders show even without issues/receipts
   - Use WHERE clause filter to show only orders with activity

6. EXCHANGE RATE CALCULATION:
   - FC Amount = LC Amount / Exchange Rate
   - Handles NULL rates with NULLIF to avoid division by zero

===== SAMPLE QUERIES =====

-- Get only completed production orders with both issues and receipts:
WHERE W."Status" = 'L' 
  AND L."DocEntry" IS NOT NULL 
  AND RL."DocEntry" IS NOT NULL

-- Get production orders for specific date range:
WHERE W."PostDate" BETWEEN '2024-01-01' AND '2024-12-31'

-- Get orders with significant cost variance (>10%):
HAVING ABS(Cost_Variance_LC) / NULLIF(RawMaterial_LineCost_LC, 0) > 0.10

===== KEY SAP B1 TABLES =====
- OWOR: Production Orders header
- OIGE/IGE1: Goods Issue header/lines (materials to production)
- OIGN/IGN1: Goods Receipt header/lines (production output)
- OITM: Items Master Data (currencies, UOM, costing method)
- OCRY: Currencies (for currency descriptions)

===== COSTING TABLE REFERENCES (Advanced) =====
For detailed layer costs, consider joining:
- OITL: Inventory Transaction Layers
- ITL1: Inventory Transaction Layer Details
- OCLG: Inventory Costing Layers (for FIFO layer details)
*/
