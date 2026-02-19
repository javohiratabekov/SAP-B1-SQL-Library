-- FIN_AR_Customer_Reconciliation.sql
-- Description: Customer reconciliation statement (Акт сверки) — journal transactions
--              with running balance split by currency (USD / UZS)
-- Parameters: [%0] Customer Name (LIKE filter), [%1] Start Date, [%2] End Date
-- Tables: JDT1 (Journal Entry Lines), OCRD (Business Partners)

SELECT 
    T0."RefDate"                        AS "Дата регистрации",
    CASE T0."TransType"
        WHEN -1  THEN 'Ручная проводка №'              || IFNULL(T0."Ref1", '')
        WHEN -2  THEN 'Начальный остаток №'             || IFNULL(T0."Ref1", '')
        WHEN 13  THEN 'Счёт-фактура (продажа) №'        || IFNULL(T0."Ref1", '')
        WHEN 14  THEN 'Возврат денег клиенту №'         || IFNULL(T0."Ref1", '')
        WHEN 15  THEN 'Накладная на отгрузку №'         || IFNULL(T0."Ref1", '')
        WHEN 16  THEN 'Возврат товара от клиента №'     || IFNULL(T0."Ref1", '')
        WHEN 17  THEN 'Заказ от клиента №'              || IFNULL(T0."Ref1", '')
        WHEN 18  THEN 'Счёт от поставщика №'            || IFNULL(T0."Ref1", '')
        WHEN 19  THEN 'Скидка от поставщика №'          || IFNULL(T0."Ref1", '')
        WHEN 20  THEN 'Приход товара на склад №'        || IFNULL(T0."Ref1", '')
        WHEN 21  THEN 'Возврат товара поставщику №'     || IFNULL(T0."Ref1", '')
        WHEN 22  THEN 'Заказ поставщику №'              || IFNULL(T0."Ref1", '')
        WHEN 23  THEN 'Предложение клиенту №'           || IFNULL(T0."Ref1", '')
        WHEN 24  THEN 'Оплата от клиента №'             || IFNULL(T0."Ref1", '')
        WHEN 25  THEN 'Депозит №'                       || IFNULL(T0."Ref1", '')
        WHEN 28  THEN 'Исправление проводки №'          || IFNULL(T0."Ref1", '')
        WHEN 30  THEN 'Ручная проводка №'               || IFNULL(T0."Ref1", '')
        WHEN 46  THEN 'Оплата поставщику №'             || IFNULL(T0."Ref1", '')
        WHEN 59  THEN 'Поступление средств №'           || IFNULL(T0."Ref1", '')
        WHEN 67  THEN 'Корректировка склада №'          || IFNULL(T0."Ref1", '')
        WHEN 69  THEN 'Оплата аренды №'                 || IFNULL(T0."Ref1", '')
        WHEN 76  THEN 'Корректировка №'                 || IFNULL(T0."Ref1", '')
        WHEN 202 THEN 'Производство №'                  || IFNULL(T0."Ref1", '')
        WHEN 203 THEN 'Счёт (резерв) №'                 || IFNULL(T0."Ref1", '')
        ELSE CAST(T0."TransType" AS VARCHAR(10)) || ' №' || IFNULL(T0."Ref1", '')
    END AS "Документ",
    /* ===== Расход / Приход ===== */
    CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
         THEN T0."FCDebit"
         ELSE T0."Debit"
    END                                 AS "Расход",
    CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
         THEN T0."FCCredit"
         ELSE T0."Credit"
    END                                 AS "Приход",
    /* ===== Running balance per currency ===== */
    SUM(
        CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
             THEN T0."FCDebit"  - T0."FCCredit"
             ELSE T0."Debit"    - T0."Credit"
        END
    ) OVER (
        PARTITION BY T1."CardCode",
                     CASE WHEN IFNULL(T0."FCCurrency", '') = 'UZS'
                          THEN 'UZS' ELSE 'USD' END
        ORDER BY T0."RefDate", T0."TransId", T0."Line_ID"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                   AS "Баланс",
    /* ===== Валюта ===== */
    CASE 
        WHEN IFNULL(T0."FCCurrency", '') = '' THEN 'USD'
        ELSE T0."FCCurrency" 
    END                                 AS "Валюта",
    T0."LineMemo"                       AS "Описание",
    T0."Ref1"                           AS "Номер Документа"
FROM "JDT1" T0
INNER JOIN "OCRD" T1 
    ON T0."ShortName" = T1."CardCode"
WHERE 
    T1."CardName" LIKE '%' || [%0] || '%'
    AND T0."RefDate" >= [%1]
    AND T0."RefDate" <= [%2]
    AND T1."CardType" = 'C'
    /* Filter 1: remove completely empty technical lines */
    AND NOT (
        T0."Debit"   = 0 AND T0."Credit"   = 0 AND
        T0."FCDebit" = 0 AND T0."FCCredit" = 0
    )
    /* Filter 2: remove FX rate difference lines
       (customer lines with no FC amounts whose counter entry is 9540 or 9620) */
    AND NOT (
        IFNULL(T0."FCCurrency", '') = ''
        AND T0."FCDebit"  = 0
        AND T0."FCCredit" = 0
        AND EXISTS (
            SELECT 1 FROM "JDT1" T2
            WHERE T2."TransId" = T0."TransId"
              AND T2."Account" IN ('9540', '9620')
              AND (
                  (T2."Debit"  = T0."Credit" AND T0."Credit" > 0)
                  OR
                  (T2."Credit" = T0."Debit"  AND T0."Debit"  > 0)
              )
        )
    )
ORDER BY 
    T0."RefDate",
    T0."TransId",
    T0."Line_ID";
