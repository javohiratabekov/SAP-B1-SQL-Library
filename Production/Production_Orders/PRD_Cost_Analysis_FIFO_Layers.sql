-- PRD_Cost_Analysis_FIFO_Layers.sql
-- Description: Advanced production cost report with full FIFO inventory layer breakdown,
--              cost variance percentage, and efficiency metrics
-- Costing Methods: Raw Materials = AVECO, Finished Goods = FIFO
-- Currency: Local = UZS, FC = Transaction Currency
-- Tables: OWOR, OIGE/IGE1, OIGN/IGN1, OITM, OITL, ITL1

SELECT
    -- ===== Production Order =====
    W."DocNum"                      AS "ProdOrder",
    W."ItemCode"                    AS "FG_Code",
    W."ProdName"                    AS "FG_Name",
    W."PostDate"                    AS "ProdDate",
    W."Status"                      AS "Status",
    W."PlannedQty"                  AS "Planned_Qty",
    
    -- ===== Raw Materials Issued (AVECO) =====
    I."DocNum"                      AS "Issue_Doc",
    I."DocDate"                     AS "Issue_Date",
    L."LineNum"                     AS "Issue_Line",
    L."ItemCode"                    AS "RM_Code",
    L."Dscription"                  AS "RM_Name",
    L."Quantity"                    AS "RM_Qty",
    
    -- Raw Material Costs (Local Currency - UZS)
    L."StockPrice"                  AS "RM_UnitCost_UZS",
    L."LineTotal"                   AS "RM_TotalCost_UZS",
    
    -- Raw Material Costs (Foreign Currency)
    L."Currency"                    AS "RM_Currency",
    L."Rate"                        AS "RM_Rate",
    CASE 
        WHEN L."Rate" IS NOT NULL AND L."Rate" <> 0 
        THEN L."StockPrice" / L."Rate"
        ELSE NULL 
    END                             AS "RM_UnitCost_FC",
    CASE 
        WHEN L."Rate" IS NOT NULL AND L."Rate" <> 0 
        THEN L."LineTotal" / L."Rate"
        ELSE NULL 
    END                             AS "RM_TotalCost_FC",
    
    -- ===== Finished Goods Received (FIFO) =====
    R."DocNum"                      AS "Receipt_Doc",
    R."DocDate"                     AS "Receipt_Date",
    RL."LineNum"                    AS "Receipt_Line",
    RL."ItemCode"                   AS "FG_Received_Code",
    RL."Dscription"                 AS "FG_Received_Name",
    RL."Quantity"                   AS "FG_Qty",
    
    -- Finished Goods Costs (Local Currency - UZS)
    RL."StockPrice"                 AS "FG_UnitCost_UZS",
    RL."LineTotal"                  AS "FG_TotalCost_UZS",
    
    -- Finished Goods Costs (Foreign Currency)
    RL."Currency"                   AS "FG_Currency",
    RL."Rate"                       AS "FG_Rate",
    CASE 
        WHEN RL."Rate" IS NOT NULL AND RL."Rate" <> 0 
        THEN RL."StockPrice" / RL."Rate"
        ELSE NULL 
    END                             AS "FG_UnitCost_FC",
    CASE 
        WHEN RL."Rate" IS NOT NULL AND RL."Rate" <> 0 
        THEN RL."LineTotal" / RL."Rate"
        ELSE NULL 
    END                             AS "FG_TotalCost_FC",
    
    -- ===== Inventory Layer Information (FIFO Details) =====
    TL."DocType"                    AS "Trans_Type",
    TL."DocDate"                    AS "Layer_Date",
    TL."Quantity"                   AS "Layer_Qty",
    
    -- Layer Costs
    CL."TransValue"                 AS "Layer_TransValue_UZS",
    CL."Price"                      AS "Layer_UnitPrice_UZS",
    
    -- ===== Cost Analysis =====
    -- Total costs aggregated
    ROUND(I."DocTotal", 2)          AS "Total_RM_Issue_UZS",
    ROUND(I."DocTotalFC", 2)        AS "Total_RM_Issue_FC",
    ROUND(R."DocTotal", 2)          AS "Total_FG_Receipt_UZS",
    ROUND(R."DocTotalFC", 2)        AS "Total_FG_Receipt_FC",
    
    -- Cost Variance (FG Cost vs RM Cost)
    ROUND(IFNULL(RL."LineTotal", 0) - IFNULL(L."LineTotal", 0), 2) 
                                    AS "Line_Variance_UZS",
    
    -- Efficiency Metrics
    CASE 
        WHEN L."LineTotal" IS NOT NULL AND L."LineTotal" <> 0 
        THEN ROUND((IFNULL(RL."LineTotal", 0) / L."LineTotal" - 1) * 100, 2)
        ELSE NULL 
    END                             AS "Cost_Variance_Pct",
    
    -- ===== Additional Item Details =====
    RM."InvntryUom"                 AS "RM_UOM",
    RM."AvgPrice"                   AS "RM_AvgPrice_Current",
    RM."EvalSystem"                 AS "RM_CostingMethod",
    
    FG."InvntryUom"                 AS "FG_UOM",
    FG."AvgPrice"                   AS "FG_AvgPrice_Current",
    FG."EvalSystem"                 AS "FG_CostingMethod"

FROM OWOR W

-- Raw Materials Issued (AVECO)
LEFT JOIN IGE1 L ON L."BaseEntry" = W."DocEntry" AND L."BaseType" = 202
LEFT JOIN OIGE I ON I."DocEntry" = L."DocEntry"
LEFT JOIN OITM RM ON RM."ItemCode" = L."ItemCode"

-- Finished Goods Received (FIFO)
LEFT JOIN IGN1 RL ON RL."BaseEntry" = W."DocEntry" AND RL."BaseType" = 202
LEFT JOIN OIGN R ON R."DocEntry" = RL."DocEntry"
LEFT JOIN OITM FG ON FG."ItemCode" = RL."ItemCode"

-- Inventory Transaction Layers (FIFO layer tracking)
LEFT JOIN OITL TL ON TL."DocEntry" = R."DocEntry" 
                  AND TL."DocType" = 59              -- 59 = Goods Receipt
                  AND TL."ItemCode" = RL."ItemCode"
                  AND TL."DocLine" = RL."LineNum"

-- Costing Layers (detailed FIFO costs)
LEFT JOIN ITL1 CL ON CL."LogEntry" = TL."LogEntry"

WHERE 
    W."Status" <> 'C'                                -- Exclude cancelled
    AND (L."DocEntry" IS NOT NULL OR RL."DocEntry" IS NOT NULL)

ORDER BY
    W."DocNum",
    I."DocDate",
    I."DocNum",
    L."LineNum",
    R."DocDate",
    R."DocNum",
    RL."LineNum",
    TL."DocDate";

/* 
===== ENHANCED FEATURES =====

1. FIFO LAYER TRACKING:
   - OITL: Inventory Transaction Layers (quantity tracking)
   - ITL1: Costing Layer Details (cost tracking)
   - Shows how FIFO layers are consumed and valued

2. COSTING BREAKDOWN:
   - Raw Materials: AVECO (Average cost from all purchases)
   - Finished Goods: FIFO (Cost flows from oldest layer first)
   - Layer balance shows remaining quantity at each cost

3. CURRENCY HANDLING:
   - All LC amounts in UZS (Local Currency)
   - FC amounts in original transaction currency
   - Exchange rates preserved from transaction date
   - NULL-safe calculations prevent division errors

4. VARIANCE ANALYSIS:
   - Line_Variance_UZS: Direct cost difference per line
   - Cost_Variance_Pct: Percentage variance for efficiency tracking
   - Helps identify production cost overruns or savings

5. TRANSACTION TYPES (TransType):
   - 59 = Goods Receipt from Production
   - 60 = Goods Issue to Production
   - 67 = Inventory Transfer
   - And others as per SAP B1 standards

===== ANALYSIS EXAMPLES =====

-- Find production orders with high cost variance:
HAVING ABS(Line_Variance_UZS) > 10000

-- Find orders where FG cost exceeds RM cost by >10%:
HAVING Cost_Variance_Pct > 10

-- Analyze specific finished goods:
WHERE W."ItemCode" IN ('FG001', 'FG002', 'FG003')

-- Analyze specific period:
WHERE W."PostDate" BETWEEN '2024-01-01' AND '2024-12-31'

-- Only completed orders with both issue and receipt:
WHERE W."Status" = 'L' 
  AND L."DocEntry" IS NOT NULL 
  AND RL."DocEntry" IS NOT NULL

===== COSTING METHOD VERIFICATION =====

To verify costing methods in SAP B1:
1. Go to Item Master Data (OITM)
2. Check field "EvalSystem":
   - 'A' = Moving Average (AVECO)
   - 'F' = FIFO
   - 'S' = Standard Cost

Query to check:
SELECT 
    "ItemCode", 
    "ItemName",
    "EvalSystem",
    CASE "EvalSystem"
        WHEN 'A' THEN 'AVECO'
        WHEN 'F' THEN 'FIFO'
        WHEN 'S' THEN 'Standard'
        ELSE 'Unknown'
    END AS "CostingMethod"
FROM OITM
WHERE "ItemCode" IN ('RM001', 'FG001');

===== KEY TABLES =====
- OWOR: Production Orders
- OIGE/IGE1: Goods Issue (materials to production)
- OIGN/IGN1: Goods Receipt (finished goods from production)
- OITM: Items Master
- OITL: Inventory Transaction Layers (quantity)
- ITL1: Inventory Transaction Layer Details (costing)
- OCLG: Costing Layers (alternative for layer history)
*/
