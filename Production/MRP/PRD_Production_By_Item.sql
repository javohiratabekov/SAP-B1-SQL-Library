-- PRD_Production_By_Item.sql
-- Description: Shows production quantities grouped by date and item
-- Parameters: [%0] Start Date, [%1] End Date
-- Tables: OIGN (Goods Receipt), IGN1 (Goods Receipt Lines)

SELECT
    T0."DocDate" AS "Date",
    T1."ItemCode",
    T1."Dscription" AS "ItemName",
    SUM(T1."Quantity") AS "Total Quantity",
    T1."unitMsr" AS "UOM"
FROM OIGN T0
INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE
    T0."CANCELED" = 'N'
    AND T1."BaseType" = 202
    AND T0."DocDate" BETWEEN TO_DATE('[%0]') AND TO_DATE('[%1]')
GROUP BY
    T0."DocDate",
    T1."ItemCode",
    T1."Dscription",
    T1."unitMsr"
ORDER BY
    T0."DocDate",
    "Total Quantity" DESC;
