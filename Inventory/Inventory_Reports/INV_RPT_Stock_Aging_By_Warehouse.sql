SELECT
    T0."ItemCode"                                              AS "ItemCode",
    T1."ItemName"                                              AS "ItemName",
    T2."ItmsGrpNam"                                            AS "ItemGroup",
    T0."WhsCode"                                               AS "Warehouse",
    T0."OnHand"                                                AS "OnHandQty",
    ROUND(T0."OnHand" * IFNULL(T0."AvgPrice", 0), 2)          AS "StockValueLC",
    IFNULL(T3."LastMovementDate", T1."CreateDate")            AS "LastMovementDate",
    DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) AS "DaysInWarehouse",
    CASE
        WHEN DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) <= 30 THEN '01. 0-30 days'
        WHEN DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) <= 60 THEN '02. 31-60 days'
        WHEN DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) <= 90 THEN '03. 61-90 days'
        WHEN DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) <= 180 THEN '04. 91-180 days'
        ELSE '05. >180 days'
    END                                                        AS "AgingPeriod"
FROM OITW T0
INNER JOIN OITM T1
    ON T1."ItemCode" = T0."ItemCode"
LEFT JOIN OITB T2
    ON T2."ItmsGrpCod" = T1."ItmsGrpCod"
LEFT JOIN (
    SELECT
        N."ItemCode",
        N."Warehouse" AS "WhsCode",
        MAX(N."DocDate") AS "LastMovementDate"
    FROM OINM N
    GROUP BY
        N."ItemCode",
        N."Warehouse"
) T3
    ON T3."ItemCode" = T0."ItemCode"
   AND T3."WhsCode" = T0."WhsCode"
WHERE T0."OnHand" > 0
  AND T0."WhsCode" LIKE '[%0]'
ORDER BY
    DAYS_BETWEEN(IFNULL(T3."LastMovementDate", T1."CreateDate"), CURRENT_DATE) DESC,
    T0."WhsCode",
    T0."ItemCode";
