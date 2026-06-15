# Sakura → Power BI: Technology Mastery Guide

**Purpose:** A practical learning roadmap for anyone who wants to understand the full access flow end to end — from a user submitting a request in Sakura to seeing filtered data in Power BI.

**Companion doc:** [SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md](./SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md) (the step-by-step flow this guide maps skills to).

**Audience:** Developers, WSO leads, data engineers, architects, and programme team members at any starting level.

---

## One-sentence summary

To master the whole flow, you need **four layers**: application + SQL (Sakura), identity (Entra), data platform (Fabric/ADF), and analytics (Power BI RLS).

---

## The stack at a glance

```text
┌─────────────────────────────────────────────────────────────────┐
│  Layer 5 — Power BI          Semantic model, RLS filter chain   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4 — RLS processing    Fabric Gold: 5 security tables     │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3 — Data movement     ADF (in) + Fabric pipelines (out)  │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2 — Identity / OLS    Entra ID, Graph API, AD sync       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1 — Sakura app        SQL Server, .NET API, Angular      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1 — Sakura application (where requests start)

| Technology | Why you need it | Recommended depth |
|------------|-----------------|-------------------|
| **SQL Server** | Permissions, approvals, `Share*.RLS` / `Share*.OLS` views, domain detail tables | **Deep** — source of truth for approved access |
| **T-SQL** | Read views, trace approved rows, debug “why isn’t this user in Share view?” | **Deep** |
| **REST APIs (.NET 8 / ASP.NET Core)** | Submit, approve, revoke, approver resolution in backend | Medium |
| **Angular + TypeScript** | Request wizard, RLS dimensions, approval UI | Medium (if you work on the portal) |
| **Azure App Service + Static Web Apps** | Where Sakura backend and frontend are hosted | Light |

### What to master first (Layer 1)

- Sakura schema: `PermissionRequests`, `PermissionHeaders`, `OLSPermissions`, `RLSPermissions`, `RLSPermission*Details`
- Share schemas: `ShareGI`, `ShareFUM`, `ShareCDI`, `ShareWFI`, `ShareEMEA`, `ShareAMER`
- Approval status codes (`ApprovalStatus = 2` = approved and visible downstream)
- How OLS and RLS are **two separate permission headers** from one user request

### Repo starting points

| Topic | Location |
|-------|----------|
| Share RLS view definitions | `Sakura_DB/Share/Views/RLS/` |
| Share OLS view definitions | `Sakura_DB/Share/Views/OLS/` |
| EDP database reader user | `Sakura_DB/Security/Users/EDPReader.sql` |
| Bulk approve / request toolkit | `sql/toolkit/08_requests/` |
| RLS diagnose scripts | `sql/toolkit/14_diagnose/` |

---

## Layer 2 — Identity and OLS (can the user open the report?)

| Technology | Why you need it | Recommended depth |
|------------|-----------------|-------------------|
| **Microsoft Entra ID (Azure AD)** | Security groups, membership, nested groups | **Deep** |
| **Microsoft Graph API** | What `SakuraV2ADSync.ps1` uses to add/remove users | Medium |
| **PowerShell** | AD sync scripts and automation | Medium |
| **MSAL / OAuth2** | How users sign into Sakura | Light–Medium |

### What to master (Layer 2)

- **OLS** = which reports/audiences the user can open
- **Managed vs Not-Managed** apps (`OLSMode` on `WorkspaceApps`)
- **`Auto.OLSGroupMemberships`** view → desired Entra state for Managed audiences
- **`SakuraV2ADSync.ps1`** → reconciles Entra groups to that desired state
- **SAR (standalone reports)** and Not-Managed apps → `Share*.OLS` only; app owners manage access
- **RLS is not synced via AD** in V2 — do not confuse OLS group membership with row-level data access

### Repo starting points

| Topic | Location |
|-------|----------|
| V2 AD sync script | `BE_Main/SakuraV2ADSync.ps1` |
| OLS maintenance picture | `Docs/OLS_RLS_MAINTENANCE_PICTURE.md` |
| V1 vs V2 Entra flow | `Docs/SG_UN_SAKURA_RLS_OLS_V1_V2_FLOW.md` |
| Entra identities reference | `Docs/SAKURAV2_ENTRA_IDENTITIES_REFERENCE.md` |

---

## Layer 3 — Data movement (reference in, permissions out)

| Technology | Why you need it | Recommended depth |
|------------|-----------------|-------------------|
| **Azure Data Factory (ADF)** | `P_REF_CENTRAL_IMPORT`, `P_REF_RONIN_IMPORT` — reference data **into** Sakura | Medium |
| **Microsoft Fabric** | Lakehouses, warehouses, shortcuts, scheduled pipelines | **Deep** (for RLS path) |
| **Linked services / datasets** | How ADF connects to Sakura DB, Fabric SQL endpoint, Ronin | Medium |
| **Ronin / MDM SQL** | Clusters, markets, regions (`mdm.*`) | Medium |
| **UMS / `BL_DIM`** | Entities, cost centers, employees from Fabric central import | Medium |

### Critical distinction: two directions

| Direction | Pipelines | What moves |
|-----------|-----------|------------|
| **Into Sakura** | `P_REF_CENTRAL_IMPORT`, `P_REF_RONIN_IMPORT`, `P_ALL_SAKURA_D_Automation` (V1) | Reference dimensions → `ref.*` / `Staging.*` |
| **Out of Sakura** | Fabric integration + domain RLS pipelines (EDP-owned) | Approved access from `Share*.RLS` / `Share*.OLS` → Fabric |

These are **different systems, different owners, different schedules**. Mastering ADF alone does not explain how approved requests reach Power BI.

### What to master (Layer 3)

- ADF resource: **`azeuw1dadfsakura`** (Sakura ETL — reference data in)
- Settings table: **`mgmt.DataTransferSettings`** (which objects each pipeline loads)
- Fabric **`LH_CENTRAL_SILVER`** — first landing zone for Sakura Share RLS data
- Fabric **shortcuts** — virtual pointers from central silver to domain silver (no data copy)
- Ronin **`mdm.Clusters`**, **`mdm.Markets`** — geography used in Sakura request forms and EMEA cluster change work

### Repo starting points

| Topic | Location |
|-------|----------|
| Systems connectivity map | `Docs/SYSTEMS_AND_UMS_CONNECTIVITY.md` |
| ETL reference | `Docs/SAKURA_ETL_AND_SAKURA_DB_REFERENCE.md` |
| V1 Fabric migration (ADF clone pattern) | `Docs/SakuraV1_Fabric_Migration_Guide.md` |
| Pipeline artifacts | `PipelIneUMSFabric/` |
| Data transfer settings seed | `Sakura_DB/Scripts/Post Deployment/Data/mgmt_DataTransferSettings_Default.sql` |

---

## Layer 4 — RLS processing (which rows can the user see?)

| Technology | Why you need it | Recommended depth |
|------------|-----------------|-------------------|
| **SQL (Fabric warehouse T-SQL)** | 5 security tables in domain Gold warehouses | **Deep** |
| **Dimensional modeling** | Entity hierarchy: Global → Region → Cluster → Market → Entity | **Deep** |
| **ETL patterns** | MERGE vs truncate+reload; stable surrogate keys | Medium–Deep |
| **Fact table design** | How `FUM_SecurityId` / `GI_SecurityId` are stamped on facts | Medium |

### The 5 security tables (must know)

| # | Table | Role |
|---|-------|------|
| 1 | `DimSecurityProfile` | Deduplicate access combinations → stable `SecurityProfileID` (**MERGE**) |
| 2 | `DimAdAccountSecurityProfileMapping` | User email → `SecurityProfileID` |
| 3 | Request tables (`EntityRequests`, `ClientRequests`, …) | Expand hierarchy (e.g. Region → leaf entity IDs) |
| 4 | `DimSecurity` | Unique fact-level attribute combos → `SecurityId` |
| 5 | `FactSecurity` | Bridge: which `SecurityId` each profile can see |

### What to master (Layer 4)

- Why **DimSecurityProfile uses MERGE** (IDs must stay stable across pipeline runs)
- **Hierarchy expansion** — a “Americas Region” request becomes hundreds of entity IDs
- **RLSSelects** config — which fact columns are security keys per fact table
- **Composite EntityRLSMapKey** — timesheet facts use three entity IDs joined with `*`
- Domain-specific schemas: `FUM_SECURITY`, `GI_SECURITY`, `CDI_SECURITY`, etc.

### Repo starting points

| Topic | Location |
|-------|----------|
| Full RLS system documentation | `Docs/RLS_System_Documentation.md` |
| End-to-end access flow | `Docs/SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md` |
| Domain RLS columns per Share view | `Docs/SAKURA_ACCESS_MANAGEMENT_OLS_RLS_E2E.md` §6 |

---

## Layer 5 — Power BI (where access is enforced)

| Technology | Why you need it | Recommended depth |
|------------|-----------------|-------------------|
| **Power BI semantic models** | Tables, relationships, RLS roles | **Deep** |
| **Power BI RLS (DAX filters)** | 3-table filter chain at report open | **Deep** |
| **Power BI Service** | Workspaces, apps, audiences; Viewer vs Contributor | Medium |
| **DAX** | Filter expressions in the semantic model | Medium |

### The 3-table filter chain (must know)

When a user opens a report:

```text
User email (Entra login)
    → ADAccountSecurityProfileMapping  (email → SecurityProfileID)
    → FactSecurity                       (profile → allowed SecurityIds)
    → DimSecurity                        (SecurityId → attribute combo)
    → Fact table                         (#domain_SecurityId → visible rows)
```

### What to master (Layer 5)

- **Viewer** users are subject to RLS; **Contributor** (and above) **bypass RLS**
- OLS and RLS link by **user + workspace (domain)**, not by shared request ID
- Same user in a workspace: OLS decides *can open*; RLS decides *which rows*
- Refresh latency: semantic model must reflect latest Gold security tables after pipeline run

### Repo starting points

| Topic | Location |
|-------|----------|
| OLS vs RLS enforcement | `Docs/OLS_RLS_AND_DOWNSTREAM_ENFORCEMENT.md` |
| Demo / shared concepts | `Docs/DEMO_00_SHARED_CONCEPTS.md` |
| CGI end-to-end use cases | `Docs/CGI_Workspace_End_To_End_Use_Cases.md` |

---

## Recommended learning order

Study in this sequence so each layer builds on the previous:

```text
Week 1–2   SQL Server + Sakura DB + Share views
           → "What got approved? Where does it appear?"

Week 2     OLS vs RLS (concept + two technical paths)
           → "Report access vs row access"

Week 3     Microsoft Entra ID + group sync
           → "Can they open the app/report?"

Week 4–5   Microsoft Fabric (lakehouse → warehouse → pipelines)
           → "Where does Share data land and get processed?"

Week 5–6   RLS 5-table Gold model + hierarchy expansion
           → "How scope becomes SecurityIds on facts"

Week 6–7   Power BI semantic model + RLS filter chain
           → "What the user actually sees when they open a report"

Optional   ADF (reference data into Sakura)
           → "Why dropdowns show valid clusters/markets/entities"
```

---

## By role — what to go deep vs skim

| Role | Go deep on | Skim or delegate |
|------|------------|------------------|
| **Sakura / app developer** | SQL, .NET API, Angular, Share view definitions | Fabric Gold internals, DAX |
| **WSO / access operations** | Sakura UI, approval flow, Share view spot-check SQL | ADF pipeline JSON, DAX |
| **Data / EDP / Fabric engineer** | Fabric pipelines, 5 security tables, dimension hierarchies | Angular, MSAL |
| **Power BI report owner** | Power BI RLS, workspaces, Entra groups for their app | Sakura DB schema internals |
| **Architect / programme lead** | All layers at conceptual level + handoffs and ownership | Script-level Graph API |
| **DBA / Sakura admin** | SQL Server, Share schemas, `EDPReader`, bulk toolkit | Power BI semantic modeling |

---

## Minimum competency checklist

You understand the whole flow when you can answer these without looking up:

| # | Question | Expected answer (short) |
|---|----------|-------------------------|
| 1 | Where is an approved EMEA RLS row stored? | `RLSPermissionEMEADetails` → exposed in `ShareEMEA.RLS` |
| 2 | What approval status flows downstream? | `PermissionHeaders.ApprovalStatus = 2` |
| 3 | How does a Managed audience user get workspace access? | `Auto.OLSGroupMemberships` → `SakuraV2ADSync.ps1` → Entra audience group |
| 4 | Does approving OLS automatically grant RLS? | **No** — separate headers, separate paths |
| 5 | Where does Sakura RLS land first in Fabric? | `LH_CENTRAL_SILVER` |
| 6 | What links a user email to fact rows? | `DimAdAccountSecurityProfileMapping` + `FactSecurity` |
| 7 | What happens when Alice opens a Finance report? | Email → profile → SecurityIds → filtered `FactPNL` rows |
| 8 | Why can access take hours after approval? | AD sync (daily) + RLS pipeline (4h FUM/GI, daily CDI) |
| 9 | Which pipelines load reference data **into** Sakura? | `P_REF_CENTRAL_IMPORT`, `P_REF_RONIN_IMPORT` |
| 10 | Who reads approved data **out of** Sakura? | Fabric integration pipeline via `EDPReaderUser` |

---

## Technology → flow step map

| Flow step (from companion doc) | Primary technologies |
|--------------------------------|---------------------|
| User submits request | Angular, .NET API, SQL Server |
| Approval chain | Sakura backend, email queue, LoV/config |
| Approved rows in DB | T-SQL, `PermissionHeaders`, domain detail tables |
| Share views exposed | T-SQL views, `EDPReader` grants |
| OLS → workspace access | Entra ID, Graph API, PowerShell AD sync |
| RLS → Fabric ingest | Fabric pipelines, SQL endpoint, lakehouse |
| 5-table Gold processing | Fabric warehouse T-SQL, dimensional SQL |
| Facts stamped with SecurityId | Fabric ETL, fact table design |
| User sees filtered data | Power BI semantic model, DAX RLS |

---

## Pipeline inventory (technologies involved)

### Into Sakura (reference data — not approved requests)

| Pipeline | Platform | Key technology |
|----------|----------|----------------|
| `P_REF_CENTRAL_IMPORT` | ADF `azeuw1dadfsakura` | Fabric SQL endpoint (`LH_CENTRAL_GOLD_SQLEP`), Managed Identity |
| `P_REF_RONIN_IMPORT` | ADF `azeuw1dadfsakura` | Ronin `Backbone` SQL, `mdm.*` |
| `P_ALL_SAKURA_D_Automation` | ADF `azeuw1npsenadf02` | Synapse/Sensei (`DB_Synapse_Sensei`) — V1 only |

### Out of Sakura (approved access)

| Component | Platform | Key technology |
|-----------|----------|----------------|
| Share view read | Sakura SQL Server | T-SQL, `EDPReaderUser` |
| Integration ingest | Microsoft Fabric | Lakehouse (`LH_CENTRAL_SILVER`), copy pipeline |
| Domain processing | Microsoft Fabric | Warehouse (`WH_*_GOLD`), shortcuts, T-SQL |
| OLS Entra sync | Azure VM / automation | PowerShell, Microsoft Graph |
| Report enforcement | Power BI Service | Semantic model, DAX RLS |

---

## Timing expectations (technology-driven latency)

| Component | Technology | Typical schedule | Impact |
|-----------|------------|------------------|--------|
| OLS AD sync | PowerShell + Graph | Once daily | User can open workspace/app |
| FUM / GI RLS pipeline | Fabric scheduled job | Every 4 hours | Row filter updated in model |
| CDI RLS pipeline | Fabric scheduled job | Once daily | Row filter updated (CDI) |
| Power BI dataset refresh | Power BI Service | Per workspace schedule | User sees latest stamped facts |

**Worst case for brand-new user:** up to ~12 hours (daily AD sync + 4-hour RLS pipeline, if they miss both windows).

---

## V1 vs V2 — what technology to learn

| Aspect | V1 | V2 |
|--------|----|----|
| Primary enforcement | Entra groups only (`RDSecurityGroupPermission`) | Split: Entra (OLS) + Fabric Share views (RLS) |
| AD sync script | `SakuraADSync.ps1` | `SakuraV2ADSync.ps1` |
| RLS downstream | Group-driven (no separate 5-table pipeline in V1 design) | `Share*.RLS` → Fabric Gold → Power BI |
| Reference data pipeline | `P_ALL_SAKURA_D_Automation` (Sensei) | `P_REF_CENTRAL_IMPORT` + `P_REF_RONIN_IMPORT` |

If you work on **current programme work**, prioritize **V2** stack. Keep **V1** concepts if legacy groups or Synapse automation are still in scope.

---

## Related documentation index

| Document | Use when learning… |
|----------|-------------------|
| [SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md](./SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md) | The complete step-by-step flow |
| [OLS_RLS_AND_DOWNSTREAM_ENFORCEMENT.md](./OLS_RLS_AND_DOWNSTREAM_ENFORCEMENT.md) | Who enforces what; workspace linking |
| [RLS_System_Documentation.md](./RLS_System_Documentation.md) | 5 security tables, Fabric layers, schedules |
| [SYSTEMS_AND_UMS_CONNECTIVITY.md](./SYSTEMS_AND_UMS_CONNECTIVITY.md) | UMS, Ronin, ADF, Fabric platform map |
| [SAKURA_ACCESS_MANAGEMENT_OLS_RLS_E2E.md](./SAKURA_ACCESS_MANAGEMENT_OLS_RLS_E2E.md) | Domain dimensions, Share view columns |
| [SG_UN_SAKURA_RLS_OLS_V1_V2_FLOW.md](./SG_UN_SAKURA_RLS_OLS_V1_V2_FLOW.md) | Entra groups, V1 vs V2 split |
| [OLS_RLS_MAINTENANCE_PICTURE.md](./OLS_RLS_MAINTENANCE_PICTURE.md) | Managed vs Not-Managed OLS, sync risks |
| [SAKURA_ETL_AND_SAKURA_DB_REFERENCE.md](./SAKURA_ETL_AND_SAKURA_DB_REFERENCE.md) | ADF deployment, linked services |
| [EMEA_Cluster_Change_Roadmap.txt](./EMEA_Cluster_Change_Roadmap.txt) | Programme context: Ronin → ref reload → Share RLS → PBI |

---

## Suggested hands-on exercises (in this repo)

| Exercise | Skill practiced | Where |
|----------|-----------------|-------|
| Read `ShareEMEA.RLS` view definition | T-SQL, approval filter logic | `Sakura_DB/Share/Views/RLS/ShareEMEA.RLS.sql` |
| Trace one approved request in SQL | Sakura schema | `sql/toolkit/14_diagnose/` |
| Compare domain RLS columns | Domain differences | `Docs/SAKURA_ACCESS_MANAGEMENT_OLS_RLS_E2E.md` §6 |
| Walk the 5-table model on paper | Fabric RLS processing | `Docs/RLS_System_Documentation.md` §4 |
| Map ADF linked services | Data movement into Sakura | `PipelIneUMSFabric/` JSON files |
| Read OLS sync view logic | Entra automation | `Docs/OLS_RLS_MAINTENANCE_PICTURE.md` §3 |
| Follow Alice example end to end | Whole flow synthesis | `Docs/SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md` §14 |

---

## Glossary (technology terms)

| Term | Technology / product |
|------|---------------------|
| **ADF** | Azure Data Factory — orchestrates copy/merge into Sakura |
| **Fabric** | Microsoft Fabric — lakehouses, warehouses, pipelines for RLS processing |
| **Entra ID** | Microsoft identity platform (formerly Azure AD) |
| **Graph API** | Microsoft API for reading/writing Entra groups and users |
| **MSAL** | Microsoft Authentication Library — SPA login to Sakura |
| **UMS** | Unified Model — conformed dimensions in Fabric/Synapse (`BL_DIM`) |
| **Ronin** | Platform hosting Sakura DB and MDM (`mdm.*`) |
| **EDP** | Enterprise Data Platform — downstream Fabric/Power BI enforcement |
| **Share view** | Sakura SQL interface consumed by Fabric (`Share*.RLS`, `Share*.OLS`) |
| **Semantic model** | Power BI data model with RLS roles and relationships |
| **Shortcut** | Fabric virtual pointer between lakehouses (no physical copy) |
| **MERGE** | SQL upsert — used for stable `SecurityProfileID` in Gold |

---

*Last updated: June 2026. Align with [SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md](./SAKURA_TO_POWERBI_FULL_ACCESS_FLOW.md) when the flow or pipeline ownership changes.*
