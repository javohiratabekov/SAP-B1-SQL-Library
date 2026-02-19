# Service

SAP B1 Module: **Service**

Manages post-sales service operations including service contracts, support calls/tickets, and equipment tracking.

## Sub-Modules

| Folder | SAP B1 Feature | Key Tables |
|---|---|---|
| `Service_Contracts/` | Service level agreements | `OSCN`, `SCN1` |
| `Service_Calls/` | Support tickets / service calls | `OSCL`, `SCL1`, `SCL2` |
| `Equipment_Cards/` | Customer equipment master | `OSER`, `OSRN` |

## Naming Prefix
`SRV_` — e.g., `SRV_Open_Service_Calls.sql`, `SRV_Contract_Expiry.sql`
