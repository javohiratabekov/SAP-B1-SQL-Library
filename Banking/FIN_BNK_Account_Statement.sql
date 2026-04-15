-- FIN_BNK_Account_Statement.sql
-- Description: GL account statement with opening balance, movements, period totals, and closing balance.
--              Movements respect U_OutgoingDate (OVPM custom field) when present; falls back to RefDate.
--              Opening / closing balances are also computed using the same date logic for full reconciliation.
-- Parameters:  [%0] Start Date, [%1] End Date, [%2] GL Account Code
-- Tables:      OJDT, JDT1, OACT, ORCT, OVPM

WITH StartSaldo AS (
    -- Sum all non-canceled movements on the account strictly before the period start.
    -- Joins both ORCT and OVPM to mirror the exact same cancel-exclusion logic as Movements.
    -- Without the ORCT join, canceled incoming payments inflate the balance:
    -- their original JE is counted but their reversal JE (Memo 'Отмен%') is excluded.
    SELECT
        COALESCE(SUM(J1."Debit" - J1."Credit"), 0) AS "StartSaldo"
    FROM "OJDT" J0
    INNER JOIN "JDT1" J1
           ON J0."TransId" = J1."TransId"
    LEFT  JOIN "ORCT" RC
           ON RC."TransId" = J0."TransId"
    LEFT  JOIN "OVPM" OV
           ON OV."TransId" = J0."TransId"
    WHERE COALESCE(OV."U_OutgoingDate", J0."RefDate") < '[%0]'
      AND J1."Account" = '[%2]'
      AND J0."Memo" NOT LIKE 'Отмен%'
      AND (
               (RC."TransId" IS NULL AND OV."TransId" IS NULL)
            OR RC."Canceled" = 'N'
            OR OV."Canceled" = 'N'
          )
),

EndSaldo AS (
    -- Same logic as StartSaldo, up to and including the period end date.
    SELECT
        COALESCE(SUM(J1."Debit" - J1."Credit"), 0) AS "EndSaldo"
    FROM "OJDT" J0
    INNER JOIN "JDT1" J1
           ON J0."TransId" = J1."TransId"
    LEFT  JOIN "ORCT" RC
           ON RC."TransId" = J0."TransId"
    LEFT  JOIN "OVPM" OV
           ON OV."TransId" = J0."TransId"
    WHERE COALESCE(OV."U_OutgoingDate", J0."RefDate") <= '[%1]'
      AND J1."Account" = '[%2]'
      AND J0."Memo" NOT LIKE 'Отмен%'
      AND (
               (RC."TransId" IS NULL AND OV."TransId" IS NULL)
            OR RC."Canceled" = 'N'
            OR OV."Canceled" = 'N'
          )
),

-- Pre-aggregate one counter-account name per TransId, excluding the reported account [%2].
-- HANA does not allow TOP or ORDER BY in correlated subqueries, so we resolve this
-- outside the Movements CTE. MIN() picks one name deterministically when multiple
-- counter-accounts exist (rare for simple bank entries).
CorrAccounts AS (
    SELECT
        JC."TransId",
        MIN(OA."AcctName") AS "AcctName"
    FROM "JDT1" JC
    INNER JOIN "OACT" OA ON OA."AcctCode" = JC."Account"
    WHERE JC."Account" <> '[%2]'
    GROUP BY JC."TransId"
),

Movements AS (
    SELECT
        T0."RefDate"                                                    AS "DateOp",
        COALESCE(OVPM."U_OutgoingDate", T0."RefDate")                  AS "FactDate",
        CASE WHEN T1."Debit"  > 0 THEN T1."Debit"  ELSE 0 END         AS "DebitAmt",
        CASE WHEN T1."Credit" > 0 THEN T1."Credit" ELSE 0 END         AS "CreditAmt",
        T1."Debit" - T1."Credit"                                       AS "Movement",
        COALESCE(ORCT."CardName", OVPM."CardName", T1."ShortName")     AS "BPAccount",
        CA."AcctName"                                                   AS "CorrAcctName",
        T0."Memo"                                                       AS "Note",
        COALESCE(ORCT."Comments", OVPM."Comments")                     AS "Comment",
        T0."TransId"                                                    AS "DocLink",
        T0."TransId"                                                    AS "TransId",
        T1."Line_ID"                                                    AS "LineId"
    FROM "OJDT" T0
    INNER JOIN "JDT1" T1
           ON T0."TransId" = T1."TransId"
    LEFT  JOIN CorrAccounts CA
           ON CA."TransId" = T0."TransId"
    LEFT  JOIN "ORCT" ORCT
           ON ORCT."TransId" = T0."TransId"
    LEFT  JOIN "OVPM" OVPM
           ON OVPM."TransId" = T0."TransId"
    WHERE (
               (OVPM."U_OutgoingDate" IS NOT NULL AND OVPM."U_OutgoingDate" BETWEEN '[%0]' AND '[%1]')
            OR (OVPM."U_OutgoingDate" IS NULL     AND T0."RefDate"          BETWEEN '[%0]' AND '[%1]')
          )
      AND T1."Account" = '[%2]'
      AND T0."Memo" NOT LIKE 'Отмен%'
      AND (
               (ORCT."TransId" IS NULL AND OVPM."TransId" IS NULL)
            OR ORCT."Canceled" = 'N'
            OR OVPM."Canceled" = 'N'
          )
),

Totals AS (
    SELECT
        SUM(M."DebitAmt")  AS "TotalDebit",
        SUM(M."CreditAmt") AS "TotalCredit"
    FROM Movements M
),

MovementsWithBalance AS (
    SELECT
        M."DateOp",
        M."FactDate",
        M."DebitAmt",
        M."CreditAmt",
        M."BPAccount",
        M."CorrAcctName",
        M."Note",
        M."Comment",
        M."DocLink",
        M."TransId",
        M."LineId",
        (SELECT S."StartSaldo" FROM StartSaldo S)
            + SUM(M."Movement") OVER (
                ORDER BY M."FactDate", M."TransId", M."LineId"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
              ) AS "BalanceAfter"
    FROM Movements M
),

RESULT AS (

    -- 1. Opening balance row
    SELECT
        1                                        AS "SortOrder",
        CAST('[%0]' AS DATE)                     AS "SortDate",
        TO_VARCHAR('[%0]', 'DD-MM-YYYY')         AS "CreatedDocumentDate",
        CAST(NULL AS DATE)                       AS "FactDate",
        CAST(0 AS DECIMAL(28,6))                 AS "DebitAmount",
        CAST(0 AS DECIMAL(28,6))                 AS "CreditAmount",
        S."StartSaldo"                           AS "BalanceAfterTransaction",
        '**Входящее сальдо**'                    AS "GLAccountPayment",
        ''                                       AS "CorrespondingAccountName",
        ''                                       AS "Note",
        ''                                       AS "Comment",
        0                                        AS "DocumentLink",
        0                                        AS "TransId"
    FROM StartSaldo S

    UNION ALL

    -- 2. Transaction rows
    SELECT
        2                                        AS "SortOrder",
        M."FactDate"                             AS "SortDate",   -- must match window ORDER BY in MovementsWithBalance
        TO_VARCHAR(M."DateOp", 'DD-MM-YYYY')     AS "CreatedDocumentDate",
        M."FactDate"                             AS "FactDate",
        M."DebitAmt"                             AS "DebitAmount",
        M."CreditAmt"                            AS "CreditAmount",
        M."BalanceAfter"                         AS "BalanceAfterTransaction",
        M."BPAccount"                            AS "GLAccountPayment",
        M."CorrAcctName"                         AS "CorrespondingAccountName",
        M."Note"                                 AS "Note",
        M."Comment"                              AS "Comment",
        M."DocLink"                              AS "DocumentLink",
        M."TransId"                              AS "TransId"
    FROM MovementsWithBalance M

    UNION ALL

    -- 3. Period totals row
    SELECT
        3                                        AS "SortOrder",
        CAST('[%1]' AS DATE)                     AS "SortDate",
        TO_VARCHAR('[%1]', 'DD-MM-YYYY')         AS "CreatedDocumentDate",
        CAST(NULL AS DATE)                       AS "FactDate",
        T."TotalDebit"                           AS "DebitAmount",
        T."TotalCredit"                          AS "CreditAmount",
        E."EndSaldo"                             AS "BalanceAfterTransaction",
        '**Итого за период**'                    AS "GLAccountPayment",
        ''                                       AS "CorrespondingAccountName",
        ''                                       AS "Note",
        ''                                       AS "Comment",
        9999                                     AS "DocumentLink",
        9999                                     AS "TransId"
    FROM EndSaldo E
    CROSS JOIN Totals T

    UNION ALL

    -- 4. Closing balance row
    SELECT
        4                                        AS "SortOrder",
        CAST('[%1]' AS DATE)                     AS "SortDate",
        TO_VARCHAR('[%1]', 'DD-MM-YYYY')         AS "CreatedDocumentDate",
        CAST(NULL AS DATE)                       AS "FactDate",
        CAST(0 AS DECIMAL(28,6))                 AS "DebitAmount",
        CAST(0 AS DECIMAL(28,6))                 AS "CreditAmount",
        E."EndSaldo"                             AS "BalanceAfterTransaction",
        '**Исходящее сальдо**'                   AS "GLAccountPayment",
        ''                                       AS "CorrespondingAccountName",
        ''                                       AS "Note",
        ''                                       AS "Comment",
        9999                                     AS "DocumentLink",
        9999                                     AS "TransId"
    FROM EndSaldo E
)

SELECT
    R."TransId",
    R."SortOrder",
    R."CreatedDocumentDate",
    TO_VARCHAR(R."FactDate", 'DD-MM-YYYY')   AS "FactDate",
    IFNULL(R."DebitAmount",  0)              AS "DebitAmount",
    IFNULL(R."CreditAmount", 0)              AS "CreditAmount",
    R."BalanceAfterTransaction",
    R."GLAccountPayment",
    R."CorrespondingAccountName",
    R."Note",
    R."Comment",
    R."DocumentLink"
FROM RESULT R
ORDER BY R."SortOrder", R."SortDate", R."TransId"
