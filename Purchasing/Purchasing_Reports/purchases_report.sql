-- Purchases Report
-- Description: Lists all purchase documents with items and quantities
-- Parameters: [%0] Start Date, [%1] End Date

SELECT
    T0."DocEntry",
    T0."DocDate",
    T1."ItemCode",
    T1."Dscription" AS "ItemName",
    T1."Quantity",
    T1."unitMsr" AS "UOM"
FROM OPCH T0
INNER JOIN PCH1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE
    T0."CANCELED" = 'N'
    AND T0."DocDate" BETWEEN '[%0]' AND '[%1]'
ORDER BY T0."DocDate";
