-- INV_RPT_Movement_Report_CTE.sql
-- Description: Inventory movement report — opening balance, production, sales, returns, and closing balance
--              Uses CTEs for better performance. Preferred version over INV_RPT_Movement_Report.sql
-- Parameters: [%0] Item Name (LIKE filter), [%1] Start Date, [%2] End Date, [%3] Warehouse Code (use '%' for all)
-- Tables: OITM (Items), OITB (Item Groups), OITW (Item Warehouse), OIGN/IGN1 (Goods Receipt),
--         OINV/INV1 (A/R Invoice), ODLN/DLN1 (Delivery), ORIN/RIN1 (A/R Credit Memo)

WITH 
-- Goods Receipt (Production/Incoming)
GoodsReceipt AS (
    SELECT 
        T1."ItemCode",
        SUM(T1."Quantity") AS "Quantity"
    FROM OIGN T0
    INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE 
        T0."DocDate" >= [%1]
        AND T0."DocDate" <= [%2]
        AND T1."WhsCode" LIKE [%3]
    GROUP BY T1."ItemCode"
),
-- Sales Invoices
SalesInvoices AS (
    SELECT 
        T1."ItemCode",
        SUM(T1."Quantity") AS "Quantity"
    FROM OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE 
        T0."DocDate" >= [%1]
        AND T0."DocDate" <= [%2]
        AND T1."WhsCode" LIKE [%3]
    GROUP BY T1."ItemCode"
),
-- Deliveries
SalesDeliveries AS (
    SELECT 
        T1."ItemCode",
        SUM(T1."Quantity") AS "Quantity"
    FROM ODLN T0
    INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE 
        T0."DocDate" >= [%1]
        AND T0."DocDate" <= [%2]
        AND T1."WhsCode" LIKE [%3]
    GROUP BY T1."ItemCode"
),
-- Returns (A/R Credit Memos)
Returns AS (
    SELECT 
        T1."ItemCode",
        SUM(T1."Quantity") AS "Quantity"
    FROM ORIN T0
    INNER JOIN RIN1 T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE 
        T0."DocDate" >= [%1]
        AND T0."DocDate" <= [%2]
        AND T1."WhsCode" LIKE [%3]
    GROUP BY T1."ItemCode"
),
-- Current Warehouse Stock
CurrentStock AS (
    SELECT 
        "ItemCode",
        SUM("OnHand") AS "OnHand"
    FROM OITW
    WHERE "WhsCode" LIKE [%3]
    GROUP BY "ItemCode"
)

SELECT 
    T0."ItemCode"                                   AS "Код товара",
    T0."ItemName"                                   AS "Наименование",
    T1."ItmsGrpNam"                                 AS "Группа товаров",
    
    /* ===== Норма (Standard/Norm) ===== */
    CAST(T0."MinLevel" AS INT)                      AS "Норма",
    
    /* ===== Начальный остаток (Opening Balance) ===== */
    CAST(
        IFNULL(CS."OnHand", 0) - 
        IFNULL(GR."Quantity", 0) +
        IFNULL(SI."Quantity", 0) +
        IFNULL(SD."Quantity", 0) -
        IFNULL(RT."Quantity", 0)
    AS INT)                                         AS "Нач.Ост.УП",
    
    /* ===== Произведено (Production/Goods Receipt) ===== */
    CAST(IFNULL(GR."Quantity", 0) AS INT)          AS "Произведено(Умк)",
    
    /* ===== Реализация (Sales - Invoices + Deliveries) ===== */
    CAST(
        IFNULL(SI."Quantity", 0) + 
        IFNULL(SD."Quantity", 0)
    AS INT)                                         AS "Реализация",
    
    /* ===== Возврат (Returns) ===== */
    CAST(IFNULL(RT."Quantity", 0) AS INT)          AS "возврат",
    
    /* ===== Текущий остаток (Current Balance) ===== */
    CAST(IFNULL(CS."OnHand", 0) AS INT)            AS "Текущий остаток",
    
    /* ===== Факт (Expected Balance - Opening + Production - Sales + Returns) ===== */
    CAST(
        IFNULL(CS."OnHand", 0) - 
        IFNULL(GR."Quantity", 0) +
        IFNULL(SI."Quantity", 0) +
        IFNULL(SD."Quantity", 0) -
        IFNULL(RT."Quantity", 0) +
        IFNULL(GR."Quantity", 0) -
        IFNULL(SI."Quantity", 0) -
        IFNULL(SD."Quantity", 0) +
        IFNULL(RT."Quantity", 0)
    AS INT)                                         AS "fakt",
    
    /* ===== Разница (Difference) ===== */
    CAST(0 AS INT)                                  AS "Разница"

FROM OITM T0
LEFT JOIN OITB T1 ON T0."ItmsGrpCod" = T1."ItmsGrpCod"
LEFT JOIN GoodsReceipt GR ON T0."ItemCode" = GR."ItemCode"
LEFT JOIN SalesInvoices SI ON T0."ItemCode" = SI."ItemCode"
LEFT JOIN SalesDeliveries SD ON T0."ItemCode" = SD."ItemCode"
LEFT JOIN Returns RT ON T0."ItemCode" = RT."ItemCode"
LEFT JOIN CurrentStock CS ON T0."ItemCode" = CS."ItemCode"

WHERE 
    T0."ItemName" LIKE '%' || [%0] || '%'
    -- Only show items with activity in the period or current inventory
    AND (
        IFNULL(CS."OnHand", 0) <> 0
        OR GR."Quantity" IS NOT NULL
        OR SI."Quantity" IS NOT NULL
        OR SD."Quantity" IS NOT NULL
        OR RT."Quantity" IS NOT NULL
    )

ORDER BY 
    T0."ItemName";

/* 
===== USAGE EXAMPLES =====

-- All items for a specific period, all warehouses:
Parameters: [%0] = '', [%1] = '2024-01-01', [%2] = '2024-01-31', [%3] = '%'

-- Specific item name filter (e.g., BabyBoo):
Parameters: [%0] = 'BabyBoo', [%1] = '2024-01-01', [%2] = '2024-01-31', [%3] = '%'

-- Specific warehouse only:
Parameters: [%0] = '', [%1] = '2024-01-01', [%2] = '2024-01-31', [%3] = 'FG1'

===== PERFORMANCE NOTES =====
This optimized version:
1. Uses CTEs to aggregate data once instead of multiple subqueries
2. Performs better with large datasets
3. More readable and maintainable
4. Results should match the non-optimized version

===== CUSTOMIZATION =====
If you need to:
- Add more document types (e.g., Purchase Orders): Add another CTE
- Filter by item group: Add WHERE clause with T0."ItmsGrpCod" IN (...)
- Include inactive items: Remove the activity filter in main WHERE clause
- Add totals row: Use UNION with aggregate SUM() queries
*/
