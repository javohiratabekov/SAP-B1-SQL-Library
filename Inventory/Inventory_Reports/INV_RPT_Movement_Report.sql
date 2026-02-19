-- INV_RPT_Movement_Report.sql
-- Description: Inventory movement report — opening balance, production, sales, returns, and closing balance
--              Uses correlated subqueries. For better performance on large datasets use INV_RPT_Movement_Report_CTE.sql
-- Filtered for: BabyBoo UltraSoft items (1-6) — modify IN clause to change item filter
-- Parameters: [%1] Start Date, [%2] End Date, [%3] Warehouse Code (use '%' for all warehouses)
-- Tables: OITM (Items), OITB (Item Groups), OITW (Item Warehouse), OIGN/IGN1 (Goods Receipt),
--         OINV/INV1 (A/R Invoice), ODLN/DLN1 (Delivery), ORIN/RIN1 (A/R Credit Memo)

SELECT 
    T0."ItemCode"                           AS "Код товара",
    T0."ItemName"                           AS "Наименование",
    T1."ItmsGrpNam"                         AS "Группа товаров",
    
    /* ===== Норма (Standard/Norm) - можно настроить под ваши требования ===== */
    CAST(T0."MinLevel" AS INT)             AS "Норма",
    
    /* ===== Начальный остаток (Opening Balance) ===== */
    CAST(
        IFNULL(T0."OnHand", 0) - 
        IFNULL((SELECT SUM(T3."Quantity") 
                FROM IGN1 T3 
                INNER JOIN OIGN T4 ON T3."DocEntry" = T4."DocEntry"
                WHERE T3."ItemCode" = T0."ItemCode" 
                  AND T4."DocDate" >= [%1]
                  AND T4."DocDate" <= [%2]
                  AND T3."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T5."Quantity") 
                FROM INV1 T5 
                INNER JOIN OINV T6 ON T5."DocEntry" = T6."DocEntry"
                WHERE T5."ItemCode" = T0."ItemCode" 
                  AND T6."DocDate" >= [%1]
                  AND T6."DocDate" <= [%2]
                  AND T5."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T7."Quantity") 
                FROM DLN1 T7 
                INNER JOIN ODLN T8 ON T7."DocEntry" = T8."DocEntry"
                WHERE T7."ItemCode" = T0."ItemCode" 
                  AND T8."DocDate" >= [%1]
                  AND T8."DocDate" <= [%2]
                  AND T7."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T9."Quantity") 
                FROM RIN1 T9 
                INNER JOIN ORIN T10 ON T9."DocEntry" = T10."DocEntry"
                WHERE T9."ItemCode" = T0."ItemCode" 
                  AND T10."DocDate" >= [%1]
                  AND T10."DocDate" <= [%2]
                  AND T9."WhsCode" LIKE [%3]), 0)
    AS INT)                                 AS "Нач.Ост.УП",
    
    /* ===== Произведено (Production/Goods Receipt) ===== */
    CAST(IFNULL((
        SELECT SUM(T11."Quantity") 
        FROM IGN1 T11
        INNER JOIN OIGN T12 ON T11."DocEntry" = T12."DocEntry"
        WHERE T11."ItemCode" = T0."ItemCode" 
          AND T12."DocDate" >= [%1]
          AND T12."DocDate" <= [%2]
          AND T11."WhsCode" LIKE [%3]
    ), 0) AS INT)                           AS "Произведено(Умк)",
    
    /* ===== Реализация (Sales - Invoices + Deliveries) ===== */
    CAST(IFNULL((
        SELECT SUM(T13."Quantity") 
        FROM INV1 T13
        INNER JOIN OINV T14 ON T13."DocEntry" = T14."DocEntry"
        WHERE T13."ItemCode" = T0."ItemCode" 
          AND T14."DocDate" >= [%1]
          AND T14."DocDate" <= [%2]
          AND T13."WhsCode" LIKE [%3]
    ), 0) + IFNULL((
        SELECT SUM(T15."Quantity") 
        FROM DLN1 T15
        INNER JOIN ODLN T16 ON T15."DocEntry" = T16."DocEntry"
        WHERE T15."ItemCode" = T0."ItemCode" 
          AND T16."DocDate" >= [%1]
          AND T16."DocDate" <= [%2]
          AND T15."WhsCode" LIKE [%3]
    ), 0) AS INT)                           AS "Реализация",
    
    /* ===== Возврат (Returns - A/R Credit Memos) ===== */
    CAST(IFNULL((
        SELECT SUM(T17."Quantity") 
        FROM RIN1 T17
        INNER JOIN ORIN T18 ON T17."DocEntry" = T18."DocEntry"
        WHERE T17."ItemCode" = T0."ItemCode" 
          AND T18."DocDate" >= [%1]
          AND T18."DocDate" <= [%2]
          AND T17."WhsCode" LIKE [%3]
    ), 0) AS INT)                           AS "возврат",
    
    /* ===== Текущий остаток (Current Balance) ===== */
    CAST(IFNULL((
        SELECT SUM(T19."OnHand") 
        FROM OITW T19
        WHERE T19."ItemCode" = T0."ItemCode"
          AND T19."WhsCode" LIKE [%3]
    ), 0) AS INT)                           AS "Текущий остаток",
    
    /* ===== Факт (Expected Balance based on movements) ===== */
    CAST(
        IFNULL(T0."OnHand", 0) - 
        IFNULL((SELECT SUM(T3."Quantity") 
                FROM IGN1 T3 
                INNER JOIN OIGN T4 ON T3."DocEntry" = T4."DocEntry"
                WHERE T3."ItemCode" = T0."ItemCode" 
                  AND T4."DocDate" >= [%1]
                  AND T4."DocDate" <= [%2]
                  AND T3."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T5."Quantity") 
                FROM INV1 T5 
                INNER JOIN OINV T6 ON T5."DocEntry" = T6."DocEntry"
                WHERE T5."ItemCode" = T0."ItemCode" 
                  AND T6."DocDate" >= [%1]
                  AND T6."DocDate" <= [%2]
                  AND T5."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T7."Quantity") 
                FROM DLN1 T7 
                INNER JOIN ODLN T8 ON T7."DocEntry" = T8."DocEntry"
                WHERE T7."ItemCode" = T0."ItemCode" 
                  AND T8."DocDate" >= [%1]
                  AND T8."DocDate" <= [%2]
                  AND T7."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T9."Quantity") 
                FROM RIN1 T9 
                INNER JOIN ORIN T10 ON T9."DocEntry" = T10."DocEntry"
                WHERE T9."ItemCode" = T0."ItemCode" 
                  AND T10."DocDate" >= [%1]
                  AND T10."DocDate" <= [%2]
                  AND T9."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T11."Quantity") 
                FROM IGN1 T11
                INNER JOIN OIGN T12 ON T11."DocEntry" = T12."DocEntry"
                WHERE T11."ItemCode" = T0."ItemCode" 
                  AND T12."DocDate" >= [%1]
                  AND T12."DocDate" <= [%2]
                  AND T11."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T13."Quantity") 
                FROM INV1 T13
                INNER JOIN OINV T14 ON T13."DocEntry" = T14."DocEntry"
                WHERE T13."ItemCode" = T0."ItemCode" 
                  AND T14."DocDate" >= [%1]
                  AND T14."DocDate" <= [%2]
                  AND T13."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T15."Quantity") 
                FROM DLN1 T15
                INNER JOIN ODLN T16 ON T15."DocEntry" = T16."DocEntry"
                WHERE T15."ItemCode" = T0."ItemCode" 
                  AND T16."DocDate" >= [%1]
                  AND T16."DocDate" <= [%2]
                  AND T15."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T17."Quantity") 
                FROM RIN1 T17
                INNER JOIN ORIN T18 ON T17."DocEntry" = T18."DocEntry"
                WHERE T17."ItemCode" = T0."ItemCode" 
                  AND T18."DocDate" >= [%1]
                  AND T18."DocDate" <= [%2]
                  AND T17."WhsCode" LIKE [%3]), 0)
    AS INT)                                 AS "fakt",
    
    /* ===== Разница (Difference between Current and Expected) ===== */
    CAST(IFNULL((
        SELECT SUM(T19."OnHand") 
        FROM OITW T19
        WHERE T19."ItemCode" = T0."ItemCode"
          AND T19."WhsCode" LIKE [%3]
    ), 0) - (
        IFNULL(T0."OnHand", 0) - 
        IFNULL((SELECT SUM(T3."Quantity") 
                FROM IGN1 T3 
                INNER JOIN OIGN T4 ON T3."DocEntry" = T4."DocEntry"
                WHERE T3."ItemCode" = T0."ItemCode" 
                  AND T4."DocDate" >= [%1]
                  AND T4."DocDate" <= [%2]
                  AND T3."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T5."Quantity") 
                FROM INV1 T5 
                INNER JOIN OINV T6 ON T5."DocEntry" = T6."DocEntry"
                WHERE T5."ItemCode" = T0."ItemCode" 
                  AND T6."DocDate" >= [%1]
                  AND T6."DocDate" <= [%2]
                  AND T5."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T7."Quantity") 
                FROM DLN1 T7 
                INNER JOIN ODLN T8 ON T7."DocEntry" = T8."DocEntry"
                WHERE T7."ItemCode" = T0."ItemCode" 
                  AND T8."DocDate" >= [%1]
                  AND T8."DocDate" <= [%2]
                  AND T7."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T9."Quantity") 
                FROM RIN1 T9 
                INNER JOIN ORIN T10 ON T9."DocEntry" = T10."DocEntry"
                WHERE T9."ItemCode" = T0."ItemCode" 
                  AND T10."DocDate" >= [%1]
                  AND T10."DocDate" <= [%2]
                  AND T9."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T11."Quantity") 
                FROM IGN1 T11
                INNER JOIN OIGN T12 ON T11."DocEntry" = T12."DocEntry"
                WHERE T11."ItemCode" = T0."ItemCode" 
                  AND T12."DocDate" >= [%1]
                  AND T12."DocDate" <= [%2]
                  AND T11."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T13."Quantity") 
                FROM INV1 T13
                INNER JOIN OINV T14 ON T13."DocEntry" = T14."DocEntry"
                WHERE T13."ItemCode" = T0."ItemCode" 
                  AND T14."DocDate" >= [%1]
                  AND T14."DocDate" <= [%2]
                  AND T13."WhsCode" LIKE [%3]), 0) -
        IFNULL((SELECT SUM(T15."Quantity") 
                FROM DLN1 T15
                INNER JOIN ODLN T16 ON T15."DocEntry" = T16."DocEntry"
                WHERE T15."ItemCode" = T0."ItemCode" 
                  AND T16."DocDate" >= [%1]
                  AND T16."DocDate" <= [%2]
                  AND T15."WhsCode" LIKE [%3]), 0) +
        IFNULL((SELECT SUM(T17."Quantity") 
                FROM RIN1 T17
                INNER JOIN ORIN T18 ON T17."DocEntry" = T18."DocEntry"
                WHERE T17."ItemCode" = T0."ItemCode" 
                  AND T18."DocDate" >= [%1]
                  AND T18."DocDate" <= [%2]
                  AND T17."WhsCode" LIKE [%3]), 0)
    ) AS INT)                               AS "Разница"

FROM OITM T0
LEFT JOIN OITB T1 ON T0."ItmsGrpCod" = T1."ItmsGrpCod"

WHERE 
    -- Filter for specific BabyBoo UltraSoft items (case-insensitive)
    T0."ItemName" IN (
        'BabyBoo UltraSoft 1',
        'BabyBoo UltraSoft 2',
        'BabyBoo UltraSoft 3',
        'BabyBoo UltraSoft 4',
        'Babyboo UltraSoft 5',
        'Babyboo UltraSoft 6'
    )
    -- Only show items with activity in the period or current inventory
    AND (
        T0."OnHand" <> 0
        OR EXISTS (
            SELECT 1 FROM IGN1 T3 
            INNER JOIN OIGN T4 ON T3."DocEntry" = T4."DocEntry"
            WHERE T3."ItemCode" = T0."ItemCode" 
              AND T4."DocDate" >= [%1]
              AND T4."DocDate" <= [%2]
              AND T3."WhsCode" LIKE [%3]
        )
        OR EXISTS (
            SELECT 1 FROM INV1 T5 
            INNER JOIN OINV T6 ON T5."DocEntry" = T6."DocEntry"
            WHERE T5."ItemCode" = T0."ItemCode" 
              AND T6."DocDate" >= [%1]
              AND T6."DocDate" <= [%2]
              AND T5."WhsCode" LIKE [%3]
        )
        OR EXISTS (
            SELECT 1 FROM DLN1 T7 
            INNER JOIN ODLN T8 ON T7."DocEntry" = T8."DocEntry"
            WHERE T7."ItemCode" = T0."ItemCode" 
              AND T8."DocDate" >= [%1]
              AND T8."DocDate" <= [%2]
              AND T7."WhsCode" LIKE [%3]
        )
        OR EXISTS (
            SELECT 1 FROM RIN1 T9 
            INNER JOIN ORIN T10 ON T9."DocEntry" = T10."DocEntry"
            WHERE T9."ItemCode" = T0."ItemCode" 
              AND T10."DocDate" >= [%1]
              AND T10."DocDate" <= [%2]
              AND T9."WhsCode" LIKE [%3]
        )
    )

ORDER BY 
    T0."ItemName";

/* 
===== USAGE EXAMPLES =====

-- BabyBoo UltraSoft items for a specific period, all warehouses:
Parameters: [%1] = '2024-01-01', [%2] = '2024-01-31', [%3] = '%'

-- BabyBoo UltraSoft items for January 2024, specific warehouse (e.g., FG1):
Parameters: [%1] = '2024-01-01', [%2] = '2024-01-31', [%3] = 'FG1'

-- BabyBoo UltraSoft items for entire year 2024, all warehouses:
Parameters: [%1] = '2024-01-01', [%2] = '2024-12-31', [%3] = '%'

===== NOTES =====
1. Query is filtered for specific BabyBoo UltraSoft items (1-6) - modify IN clause to add/remove items
2. "Норма" uses MinLevel from OITM - adjust if you have a different standard/norm field
3. "Произведено" includes all Goods Receipts (OIGN) - you may want to filter by specific document types
4. "Реализация" includes both A/R Invoices (OINV) and Deliveries (ODLN)
5. "возврат" shows A/R Credit Memos (ORIN)
6. "fakt" shows the calculated expected balance based on movements
7. "Разница" shows the difference between actual and expected balance
8. Adjust warehouse filters in parameter [%3] as needed

===== MAIN SAP B1 TABLES USED =====
- OITM: Items Master Data
- OITB: Item Groups
- OITW: Item Warehouse Info
- OIGN/IGN1: Goods Receipt (Production/Incoming)
- OINV/INV1: A/R Invoice
- ODLN/DLN1: Delivery
- ORIN/RIN1: A/R Credit Memo (Returns)
*/
