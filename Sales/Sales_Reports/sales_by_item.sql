-- Sales by Item per Date
-- Description: Shows sales quantities grouped by date and item
-- Parameters: [%0] Start Date, [%1] End Date

SELECT
    T0."DocDate" AS "Date",
    T1."ItemCode",
    T1."Dscription" AS "ItemName",
    SUM(T1."Quantity") AS "Total Quantity",
    T1."unitMsr" AS "UOM"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE
    T0."CANCELED" = 'N'
    AND T0."DocDate" BETWEEN TO_DATE('[%0]') AND TO_DATE('[%1]')
GROUP BY
    T0."DocDate",
    T1."ItemCode",
    T1."Dscription",
    T1."unitMsr"
ORDER BY
    T0."DocDate",
    "Total Quantity" DESC;
