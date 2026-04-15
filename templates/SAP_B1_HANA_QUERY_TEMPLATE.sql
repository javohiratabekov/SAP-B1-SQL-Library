-- TEMPLATE: SAP B1 HANA Query
-- Purpose: Replace this template with business-specific logic.
-- Module:  <MODULE_NAME>
-- Parameters:
--   [%0] Start Date
--   [%1] End Date
--   [%2] Optional Filter (use % for all)
-- Tables: <TABLE_1>, <TABLE_2>, <TABLE_3>

WITH BaseData AS (
    SELECT
        T0."DocEntry"              AS "DocEntry",
        T0."DocNum"                AS "DocumentNumber",
        T0."DocDate"               AS "DocumentDate",
        T0."CardCode"              AS "BPCode",
        T0."CardName"              AS "BPName",
        T1."ItemCode"              AS "ItemCode",
        T1."Dscription"            AS "ItemDescription",
        T1."Quantity"              AS "Quantity",
        T1."LineTotal"             AS "LineTotalLC"
    FROM "<HEADER_TABLE>" T0
    INNER JOIN "<LINE_TABLE>" T1
        ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."CANCELED" = 'N'
      AND T0."DocDate" BETWEEN '[%0]' AND '[%1]'
      AND IFNULL(T0."CardCode", '') LIKE '[%2]'
),
Aggregated AS (
    SELECT
        B."DocumentDate",
        B."BPCode",
        B."BPName",
        SUM(B."Quantity")          AS "TotalQuantity",
        SUM(B."LineTotalLC")       AS "TotalAmountLC"
    FROM BaseData B
    GROUP BY
        B."DocumentDate",
        B."BPCode",
        B."BPName"
)
SELECT
    A."DocumentDate"               AS "Date",
    A."BPCode"                     AS "BP Code",
    A."BPName"                     AS "BP Name",
    A."TotalQuantity"              AS "Quantity",
    A."TotalAmountLC"              AS "Amount LC"
FROM Aggregated A
ORDER BY
    A."DocumentDate",
    A."BPCode";
