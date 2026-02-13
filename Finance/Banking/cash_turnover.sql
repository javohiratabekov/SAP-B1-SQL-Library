-- Cash Turnover Report
-- Description: Shows all incoming and outgoing cash payments
-- Parameters: [%0] Start Date, [%1] End Date

SELECT
    'Приход' AS "Тип операции",
    T0."DocEntry" AS "№ документа",
    T0."DocDate" AS "Дата",
    T0."CardName" AS "Контрагент",
    T0."CashSum" AS "Сумма",
    T0."DocCurr" AS "Валюта"
FROM ORCT T0
WHERE 
    T0."Canceled" = 'N'
    AND T0."DocDate" BETWEEN TO_DATE('[%0]') AND TO_DATE('[%1]')

UNION ALL

SELECT
    'Расход' AS "Тип операции",
    T0."DocEntry" AS "№ документа",
    T0."DocDate" AS "Дата",
    T0."CardName" AS "Контрагент",
    T0."CashSum" AS "Сумма",
    T0."DocCurr" AS "Валюта"
FROM OVPM T0
WHERE 
    T0."Canceled" = 'N'
    AND T0."DocDate" BETWEEN TO_DATE('[%0]') AND TO_DATE('[%1]')

ORDER BY "Дата";
