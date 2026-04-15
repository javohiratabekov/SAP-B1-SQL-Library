# New SAP B1 Query Request Template

Copy this template and fill it before generating SQL.

## 1. Business Context
- Request title:
- SAP B1 module:
- Business user/team:
- Primary goal:

## 2. Data Scope
- Date field to use (DocDate / RefDate / TaxDate / custom UDF):
- Date range:
- Company/branch filter:
- BP filter:
- Item filter:
- Warehouse filter:
- Currency requirement (LC / FC / both):

## 3. Output Definition
- Required columns:
- Grouping level:
- Sort order:
- Need running balance? (yes/no):
- Need totals/subtotals? (yes/no):

## 4. Technical Constraints
- Must exclude canceled documents? (yes/no):
- Include UDF fields? (list):
- Expected row volume:
- Performance requirement:

## 5. SAP B1 Parameters (Query Manager)
- [%0]:
- [%1]:
- [%2]:
- [%3]:

## 6. Validation Rules
- What existing SAP report should match totals?
- Sample known record to verify:
- Edge cases to test:

## 7. Target File
- Folder path in repository:
- File name (naming convention):
