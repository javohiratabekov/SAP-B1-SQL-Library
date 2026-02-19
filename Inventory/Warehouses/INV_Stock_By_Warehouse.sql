-- INV_Stock_By_Warehouse.sql
-- Description: Current stock quantities pivoted by warehouse with row totals
-- Warehouses: AND, CST, FG1, NMG, ProdWH, QNQ (modify IN clause to add/change warehouses)
-- Item Groups: 100, 101 (modify ItmsGrpCod filter as needed)
-- Tables: OITM (Items), OITB (Item Groups), OITW (Item Warehouse)

SELECT 
    T0."ItemCode" AS "Код товара",
    T0."ItemName" AS "Название товара",
    T1."ItmsGrpNam" AS "Группа товаров",
    
    MAX(CASE WHEN T2."WhsCode" = 'AND' THEN T2."OnHand" ELSE 0 END) AS "AND",
    MAX(CASE WHEN T2."WhsCode" = 'CST' THEN T2."OnHand" ELSE 0 END) AS "CST",
    MAX(CASE WHEN T2."WhsCode" = 'FG1' THEN T2."OnHand" ELSE 0 END) AS "FG1",
    MAX(CASE WHEN T2."WhsCode" = 'NMG' THEN T2."OnHand" ELSE 0 END) AS "NMG",
    MAX(CASE WHEN T2."WhsCode" = 'ProdWH' THEN T2."OnHand" ELSE 0 END) AS "ProdWH",
    MAX(CASE WHEN T2."WhsCode" = 'QNQ' THEN T2."OnHand" ELSE 0 END) AS "QNQ",
    
    SUM(T2."OnHand") AS "Итого"
    
FROM OITM T0  
INNER JOIN OITB T1 
    ON T0."ItmsGrpCod" = T1."ItmsGrpCod" 
INNER JOIN OITW T2 
    ON T0."ItemCode" = T2."ItemCode" 

WHERE 
    T2."WhsCode" IN ('AND','CST','FG1','NMG','ProdWH','QNQ')
    AND T2."OnHand" <> 0 
    AND T0."ItmsGrpCod" IN ('100','101')  

GROUP BY 
    T0."ItemCode",
    T0."ItemName",
    T1."ItmsGrpNam"

ORDER BY 
    T0."ItemName";
