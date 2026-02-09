# Sakura_DB — Expert-Level End-to-End Reference

This document gives a **complete, detailed, expert-level** understanding of the Sakura database project: every schema, how each object connects to the whole architecture, how data is populated from ADF (Fabric and Ronin), post-deployment scripts (why they exist and who they affect), and how the database affects the whole Sakura project (Backend, Frontend, ETL).

---

## 1. High-Level Architecture: Schemas and Roles

The Sakura database is organized by **schema** and **purpose**:

| Schema | Purpose | Populated by | Consumed by |
|--------|---------|--------------|-------------|
| **mgmt** | ETL configuration, execution history, deployment/event logging | Post-deploy scripts; ADF at runtime | ADF pipelines; ops/monitoring |
| **stage** | Staging tables for incoming ETL data (one table per ref entity) | ADF Copy activity | stage.spLoad* merge procedures |
| **ref** | Canonical reference data (brands, employees, regions, etc.) | stage.spLoad* procedures | Backend API, refv views, dbo RLS/OLS |
| **refv** | Views over ref (filtered, e.g. hide deleted, IsCurrent) | — | Backend API (preferred over raw ref) |
| **dbo** | Application data: workspaces, permissions, settings, emails, LoVs | App + post-deploy scripts | Backend API, Frontend, Share views |
| **history** | System-versioned history for ref/mgmt tables | SQL Server automatically | Auditing, reporting |
| **Share*** (ShareAMER, ShareEMEA, …) | Domain-specific RLS/OLS views for external consumers | — | External tools (e.g. Fabric, BI) |
| **romv** | Read-only model views (PermissionRequests, PermissionHeaders) | — | Reporting / integration |
| **auto** | Automation objects (e.g. OLS group memberships) | — | Automations |

**Data flow in one sentence:**  
**Fabric or Ronin → ADF → stage tables → stage.spLoad* → ref tables → refv views / dbo → Backend API → Frontend.**

---

## 2. End-to-End Data Flow: How Data Moves Into Sakura

### 2.1 Two Source Streams

There are **exactly two** ETL streams:

| Stream | ADF pipeline name | Source | Destination in Sakura |
|--------|-------------------|--------|------------------------|
| **Central / Fabric** | `P_REF_CENTRAL_IMPORT` | Fabric (e.g. BL_DIM dimensions: DimBrand, DimEmployee, DimCostCenter, …) | stage → ref (8 entities) |
| **Ronin** | `P_REF_RONIN_IMPORT` | Ronin DB (e.g. mdm.Regions, mdm.Markets, Synapse views) | stage → ref (8 entities) |

- **Fabric** provides BPC/Central dimensions (brands, segments, cost centers, employees, entities, master service sets, profit centers, service lines).
- **Ronin** provides MDM/process data (business units, regions, client programs, markets, clusters, countries, Dentsu stakeholders, people aggregators).

### 2.2 Per-Transfer Flow (One Row in mgmt.DataTransferSettings)

For **each active row** in `mgmt.DataTransferSettings` where `PipelineName` matches the running ADF pipeline:

1. **ADF Lookup**  
   Reads `mgmt.DataTransferSettings` filtered by `PipelineName` (e.g. `P_REF_CENTRAL_IMPORT` or `P_REF_RONIN_IMPORT`). Gets `SourceQuery`, `DestinationSchemaName`, `DestinationTableName`, `MergeSPName`, `ExecutionOrder`.

2. **Copy**  
   ADF runs the **SourceQuery** (e.g. against Fabric/Ronin) and copies the result set into the **stage** table: `stage.[DestinationTableName]` (e.g. `stage.BPCBrands`).  
   - Stage tables have a common pattern: business columns plus `PipelineRunAt`, `PipelineInfo`, `PipelineRunId`.  
   - SourceQuery is defined in post-deploy seed data (e.g. `mgmt_DataTransferSettings_Default.sql`): Fabric queries use `BL_DIM.*`, Ronin queries use `mdm.*` or `Synapse.*`.

3. **Merge**  
   ADF executes the **MergeSPName** (e.g. `stage.spLoadBPCBrands`).  
   - The merge SP: **inserts** new rows from stage into **ref**, **updates** existing ref rows when data changed, **resurrects** (clears `DeletedAt`) if a row reappears in stage, and **soft-deletes** (sets `DeletedAt`) ref rows that are no longer in stage.  
   - So: **stage is the “current snapshot” from source; ref is the persisted, versioned, soft-delete-aware table.**

4. **Log execution**  
   ADF builds a JSON payload with execution details (rows read/copied, duration, status, errors) and calls **`mgmt.spSetDataTransferExecution`** with that JSON and the `DataTransferSettingId`.  
   - **spSetDataTransferExecution** parses the JSON and **MERGE**s into `mgmt.DataTransferExecutions` (one row per transfer per pipeline run, updated on each run).  
   - It also calls **mgmt.AddToEventLog** to write a row to `mgmt.EventLogs` (DataTransferSuccess or DataTransferError).

So: **Fabric/Ronin → ADF Copy → stage → stage.spLoad* → ref**. Configuration and run history live in **mgmt**.

### 2.3 Which Tables Come From Fabric vs Ronin

**P_REF_CENTRAL_IMPORT (Fabric):**  
BPCBrands, BPCSegments, CostCenters, Employees, Entities, MasterServiceSets, ProfitCenters, ServiceLines.

**P_REF_RONIN_IMPORT (Ronin):**  
BusinessUnits, Regions, ClientPrograms, Markets, Clusters, Countries, DentsuStakeholders, PeopleAggregators.

Each has a **stage** table, a **ref** table, and a **stage.spLoad*** procedure. The **SourceQuery** in `mgmt.DataTransferSettings` defines the exact Fabric or Ronin query (e.g. `BL_DIM.DimBrand` for BPCBrands, `mdm.Regions` for Regions).

---

## 3. Object Map: How Every Part Connects

### 3.1 mgmt Schema (ETL Control Plane)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **DataTransferSettings** | Table | One row per ETL transfer: SourceQuery, DestinationSchemaName, DestinationTableName, MergeSPName, PipelineName, ExecutionOrder, IsActive. **ADF reads this** to know what to copy and which merge SP to run. | ADF Lookup; DataTransferExecutions (FK); history.DataTransferSettings |
| **DataTransferExecutions** | Table | One row per (ObjectSchemaName, ObjectTableName, PipelineName): last run id, status, rows read/copied, duration, errors. **ADF writes this** via spSetDataTransferExecution. | DataTransferSettings (FK); spSetDataTransferExecution; history.DataTransferExecutions |
| **spSetDataTransferExecution** | Stored procedure | Accepts JSON + DataTransferSettingId; parses JSON; MERGEs DataTransferExecutions; calls AddToEventLog. **ADF calls this** after each copy/merge (success or failure). | DataTransferExecutions; EventLogs; ADF “Set status” step |
| **AddToEventLog** | Stored procedure | Inserts one row into EventLogs (TableName, RecordId, EventName, EventDescription, EventTriggeredBy). | EventLogs; spSetDataTransferExecution |
| **EventLogs** | Table | Audit log for events (e.g. DataTransferSuccess, DataTransferError). | AddToEventLog |
| **PostDeploymentScriptsHistory** | Table | Tracks which post-deploy scripts have run (ScriptName, DatabaseName, ExecutionTime). **Prevents one-time scripts from running twice.** | Sakura.PostDeployment.sql (IF NOT EXISTS check) |
| **PreDeploymentScriptsHistory** | Table | Same idea for pre-deployment scripts. | Sakura.PreDeployment.sql |

**Who is affected:**  
- **ADF** needs SELECT on DataTransferSettings and EXECUTE on spSetDataTransferExecution; INSERT/UPDATE on DataTransferExecutions happens inside that proc.  
- **Post-deploy** script `Grant_Rights_To_Managed_User_Of_ADF.sql` grants EXECUTE on spSetDataTransferExecution (and ALTER/EXECUTE on schema stage) to the ADF managed identities (azeuw1dadfsakura, azeuw1tadfsakura, azeuw1padfsakura) so the pipeline can run and log.

---

### 3.2 stage Schema (Staging for ETL)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **stage.BPCBrands** … **stage.ServiceLines** (16 tables) | Table | One table per ref entity. Columns = business keys/attributes + PipelineRunAt, PipelineInfo, PipelineRunId. **ADF copies** from Fabric/Ronin into these; **stage.spLoad*** reads from these and merges into ref. | ADF Copy (destination); stage.spLoad* (source); ref.* (target of merge) |
| **stage.spLoadBPCBrands** … **stage.spLoadPeopleAggregators** (16 procedures) | Stored procedure | Merge logic: INSERT new from stage to ref, UPDATE changed, resurrect soft-deleted, soft-delete missing. **ADF executes** the one specified in DataTransferSettings.MergeSPName. | stage.* (source); ref.* (target); mgmt.DataTransferSettings (MergeSPName) |

**Who is affected:**  
- **ADF** truncates/inserts into stage (needs ALTER on schema stage for truncate, or table-level permissions) and EXECUTE on each stage.spLoad*.  
- **ref** tables are the only consumers of stage data (via the merge SPs). The Backend and Frontend **never** read from stage; they read from **ref** or **refv**.

---

### 3.3 ref Schema (Canonical Reference Data)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **ref.BPCBrands** … **ref.ServiceLines** (16 tables) | Table | Canonical reference data. Same business columns as stage plus: Id (identity), DeletedAt, CreatedAt, UpdatedAt, PipelineStatus, PipelineInfo, PipelineRunId, and system-versioning (ValidFrom, ValidTo → history.*). | stage.spLoad* (populated by); refv.* (views); dbo RLS/OLS detail tables; Backend API |
| **refv.BPCBrands** … **refv.*** (views) | View | Thin views over ref: often filter deleted (e.g. fnsMarkIfDeleted), expose IsCurrent (e.g. fnsIsCurrent(DeletedAt)). **Backend prefers refv** for dropdowns and lists. | ref.* (source); Backend API |

**Who is affected:**  
- **Backend API** (Dentsu.SakuraApi): reads ref/refv for workspaces, security models, permissions, dropdowns (employees, regions, cost centers, profit centers, etc.). See `Documentation-Reference-Views.md` in the backend repo.  
- **Share** views (RLS/OLS) join dbo permission tables with ref/refv for hierarchy and display.  
- **Frontend** gets all reference data indirectly via the Backend API.

---

### 3.4 dbo Schema (Application Data)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **ApplicationSettings** | Table | Key-value app settings (BaseUrl, EnvironmentTag, email config, etc.). **Post-deploy** ApplicationSettings_Default.sql MERGEs default/overrides (uses SqlCmd vars AppBaseURL, AppEnvironment). | Backend (config); post-deploy ApplicationSettings_Default.sql |
| **LoVs** | Table | List-of-value metadata (Domain, SecurityType, ApplicationSetting_EmailingMode, etc.). **Post-deploy** LoV_* scripts seed defaults. | Backend/Frontend (dropdowns, security types); post-deploy LoV_*.sql |
| **Workspaces, WorkspaceApps, WorkspaceReports, WorkspaceSecurityModels, …** | Table | Core Sakura app entities (workspaces, apps, reports, security models, mappings). | Backend API; Share views |
| **PermissionRequests, PermissionHeaders, RLSPermissions, RLSPermission*Details, RLS*Approvers, …** | Table | Access requests and RLS/OLS permission details. | Backend API; Share*.*.RLS / Share*.*.OLS views |
| **ref** (logical) | — | RLS/OLS detail tables store **keys** (e.g. EntityKey, SLKey, ClientKey) that reference ref/refv data (ref.Entities, ref.ServiceLines, ref.DentsuStakeholders, etc.). | ref.* / refv.* |
| **EventLogs** (mgmt) | — | ETL events written by spSetDataTransferExecution. | — |
| **fnAppSettingValue, fnFindAppEmailQueue, MarkEmailAsSent, MarkEmailAsUnsent** | Function / SP | App helpers for settings and email state. | Backend / email jobs |

**Who is affected:**  
- **Post-deploy** scripts seed ApplicationSettings, LoVs, and (in Dev only) DevDataSeed (workspace/security model test data).  
- **Backend** reads/writes dbo for all Sakura business logic. **Frontend** talks only to the Backend API.

---

### 3.5 history Schema (Temporal History)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **history.DataTransferSettings** | Table | System-versioned history for mgmt.DataTransferSettings. | mgmt.DataTransferSettings (SYSTEM_VERSIONING) |
| **history.DataTransferExecutions** | Table | System-versioned history for mgmt.DataTransferExecutions. | mgmt.DataTransferExecutions |
| **history.BPCBrands** … (per ref table) | Table | System-versioned history for each ref table. | ref.* (SYSTEM_VERSIONING) |

**Who is affected:**  
- **Reporting/auditing** and troubleshooting; not used by ADF or the app at runtime.

---

### 3.6 Share Schemas (Domain RLS/OLS Views)

| Object | Type | Purpose | Connected to |
|--------|------|---------|-------------|
| **ShareAMER.RLS**, **ShareEMEA.RLS**, **ShareFUM.RLS**, **ShareGI.RLS**, **ShareCDI.RLS**, **ShareWFI.RLS** | View | Domain-specific RLS view: joins dbo.RLSPermission*Details, PermissionHeaders, PermissionRequests, LoVs (SecurityType). Exposes hierarchy keys and approval info. | dbo.*; ref/refv (via detail tables) |
| **Share*.RLSSample** | View | Sample/template data for same domain. | Same |
| **Share*.OLS** | View | Domain-specific OLS (object-level security) views. | dbo.OLSPermissions; ref/refv as needed |

**Who is affected:**  
- **External consumers** (e.g. Fabric, BI tools) that need to see approved RLS/OLS permission data per domain. Backend may also use these for reporting.

---

### 3.7 romv, auto, Security (Users/Schemas)

- **romv**: Read-only model views (PermissionRequests, PermissionHeaders) for reporting.  
- **auto**: e.g. Auto.OLSGroupMemberships for automations.  
- **Security**: Schemas (stage, ref, mgmt, history, refv, Share*, romv, auto), and **users** (SakuraETLUser, azeuw1dadfsakura, azeuw1tadfsakura, azeuw1padfsakura, UG-GLO-BI-*, EMEAReader, AMERReader, …).  
- **SakuraETLUser** and ADF managed identities get EXECUTE on mgmt.spSetDataTransferExecution and (for ADF) ALTER/EXECUTE on schema stage via **Grant_Rights_To_Managed_User_Of_ADF.sql**.

---

## 4. Post-Deployment Scripts: What They Do and Who They Affect

Post-deployment runs from **Sakura.PostDeployment.sql** in a fixed order. Scripts referenced with **:r** are either run **every time** (Data/Default.sql, DevSeed/DevDataSeed.sql) or **once per database** (guarded by `mgmt.PostDeploymentScriptsHistory`).

### 4.1 Execution Order (Sakura.PostDeployment.sql)

1. **:r .\Data\Default.sql** — Runs **every** deploy. (File is currently empty; placeholder for global defaults.)
2. **:r .\Data\DevSeed\DevDataSeed.sql** — Runs every deploy; **inside** DevDataSeed.sql it checks `$(AppEnvironment) = 'DEV'` and only then runs WorkspaceSecurityModels, SecurityModelSecurityTypes, Employees seed. So **only DEV** gets dev seed data.
3. **Grant_Rights_To_Managed_User_Of_ADF.sql** (one-time) — Grants to ADF managed identity (DEV/UAT/PROD) EXECUTE on mgmt.spSetDataTransferExecution, ALTER on schema stage, EXECUTE on schema stage. **Affects:** ADF pipeline (must run so ETL can log and use stage).
4. **ApplicationSettings_Default.sql** (one-time) — MERGEs default application settings (BaseUrl, EnvironmentTag, email settings, etc.) using SqlCmd variables **AppBaseURL** and **AppEnvironment**. **Affects:** Backend and any process that reads dbo.ApplicationSettings.
5. **LoV_ApplicationSetting_EmailingMode_Default.sql** (one-time) — MERGEs LoVs for type ApplicationSetting_EmailingMode (Skip, Send, Pause). **Affects:** Backend/Frontend email behaviour and config.
6. **LoV_SecurityTypes_Default.sql** (one-time) — MERGEs SecurityType LoVs (FUM, GI, CDI, WFI, EMEA-*, AMER-*). **Affects:** Security model types and RLS/OLS domain configuration used by Backend and Share views.
7. **LoV_Domains_Default.sql** (one-time) — MERGEs Domain LoVs (DFI, GI, CDI, WFI, EMEA, AMER). **Affects:** Domain list used across app and Share.
8. **mgmt_DataTransferSettings_Default.sql** (one-time) — **DELETE**s all rows in mgmt.DataTransferSettings, then **INSERT**s the full set of transfer definitions (8 for Central/Fabric, 8 for Ronin) with SourceQuery, DestinationSchemaName, DestinationTableName, MergeSPName, PipelineName, ExecutionOrder. **Affects:** ADF pipelines; without these rows, ADF has nothing to run. **Important:** For existing DBs (e.g. UAT/Prod) you must not re-run this blindly (it wipes settings). For new transfers, add a **new** one-time script (e.g. mgmt_DataTransferSettings_Update_YYYYMMDD.sql) and register it in Sakura.PostDeployment.sql.

### 4.2 Why Post-Deployment Is Used

- **One-time setup:** Seed mgmt.DataTransferSettings, ApplicationSettings, LoVs, and ADF permissions so the database is ready for ETL and the app.  
- **Environment-specific:** Grant_Rights and ApplicationSettings use **SqlCmd variables** (AppEnvironment, AppBaseURL) set at deploy time (e.g. by pipeline) so the same DACPAC works for Dev, UAT, Prod.  
- **Idempotent one-time:** PostDeploymentScriptsHistory ensures scripts like mgmt_DataTransferSettings_Default and Grant_Rights run only once per database, avoiding duplicate grants and wiping DataTransferSettings on every deploy.

### 4.3 Who Is Affected by Post-Deployment in the Whole Sakura Project

| Script | ETL (ADF) | Backend | Frontend | DB itself |
|--------|-----------|---------|----------|-----------|
| Grant_Rights_To_Managed_User_Of_ADF | Can run and log | — | — | Permissions |
| ApplicationSettings_Default | — | Reads BaseUrl, email config | — | dbo.ApplicationSettings |
| LoV_* | — | Reads LoVs for domains, security types | Gets via API | dbo.LoVs |
| mgmt_DataTransferSettings_Default | Reads transfer list | — | — | mgmt.DataTransferSettings |
| DevDataSeed | — | Test data in DEV | Test data in DEV | dbo workspaces, security models, etc. |

---

## 5. How the Whole Sakura Project Depends on Sakura_DB

- **ETL (ADF):**  
  - Reads **mgmt.DataTransferSettings** (by PipelineName).  
  - Writes to **stage** tables, runs **stage.spLoad***, calls **mgmt.spSetDataTransferExecution**.  
  - Depends on post-deploy: **DataTransferSettings** seed and **Grant_Rights** for the correct ADF identity.

- **Backend (Dentsu.SakuraApi):**  
  - Reads **ref** / **refv** for all reference data (employees, regions, cost centers, profit centers, entities, etc.).  
  - Reads/writes **dbo** (Workspaces, WorkspaceApps, security models, permissions, ApplicationSettings, LoVs).  
  - If ref tables are empty (ETL not run), dropdowns and security model behaviour break. If ApplicationSettings or LoVs are missing, config and domain/security-type behaviour break.

- **Frontend:**  
  - Calls Backend API only; no direct DB dependency.  
  - Indirectly depends on ref/dbo being populated and correct (via API responses).

- **Share / External (Fabric, BI):**  
  - Share*.RLS and Share*.OLS views join dbo permission tables and ref/refv.  
  - Depend on ref and dbo being populated and on LoVs (SecurityType, Domain) being seeded.

So: **Sakura_DB is the single source of truth for reference data and app configuration; ADF fills ref from Fabric and Ronin; Backend and Frontend consume ref and dbo; post-deployment scripts make the DB ready for ETL and the app.**

---

## 6. Quick Reference: Object Counts and Relationships

- **mgmt:** 2 tables (DataTransferSettings, DataTransferExecutions), 2 SPs (spSetDataTransferExecution, AddToEventLog), EventLogs, PostDeploymentScriptsHistory, PreDeploymentScriptsHistory.  
- **stage:** 16 tables, 16 spLoad* procedures (one per ref entity).  
- **ref:** 16 tables (same list as stage); **refv:** 20+ views over ref.  
- **dbo:** ApplicationSettings, LoVs, Workspaces, WorkspaceApps, WorkspaceReports, security model and permission tables, Emails, EmailTemplates, etc.  
- **history:** One history table per system-versioned ref and mgmt table.  
- **Share:** 6 domains × (RLS, RLSSample, OLS) = 18+ views.  
- **Post-deployment:** 1 always-run (Default.sql), 1 conditional (DevDataSeed), 6 one-time scripts (Grant_Rights, ApplicationSettings_Default, 3× LoV_*, mgmt_DataTransferSettings_Default).

---

## 7. Summary Diagram (Data Flow)

```
Fabric (BL_DIM.*)  ──┐
                    ├──► ADF (Lookup mgmt.DataTransferSettings)
Ronin (mdm.*, Synapse.*) ──┘         │
                                      ▼
                    ┌─────────────────────────────────────┐
                    │  For each row: Copy → stage.*        │
                    │  Then: EXEC stage.spLoad* → ref.*   │
                    │  Then: EXEC mgmt.spSetDataTransferExecution │
                    └─────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
   ref.* / refv.*              mgmt.DataTransferExecutions    mgmt.EventLogs
        │
        ▼
   Backend API → Frontend
   Share*.RLS/OLS → External
```

This document, together with **Docs/SAKURA_ETL_AND_SAKURA_DB_REFERENCE.md**, gives you a complete, expert-level understanding of Sakura_DB end to end.
