# Sakura → Power BI: Full Access Flow (End to End)

**Purpose:** A single, information-dense reference that traces every step from a user clicking **Submit** in Sakura to them seeing rows in a Power BI report. Covers every pipeline, table, view, and handoff in the chain.

**Audience:** Programme team members who need to understand the full picture — not just the Sakura UI, but how approval data physically travels to Power BI.

---

## Quick mental model (one line each layer)

| # | Layer | What happens |
|---|-------|-------------|
| 1 | **Sakura UI** | User fills a form (OLS = which report; RLS = which data scope) and submits |
| 2 | **Approval chain** | Line Manager → OLS Approver → RLS Approver; both must complete |
| 3 | **Sakura DB** | Approved records appear in `PermissionHeaders` (`ApprovalStatus = 2`) and domain detail tables |
| 4 | **Share views** | SQL views (`Share*.RLS`, `Share*.OLS`) expose only approved rows; read-only for downstream |
| 5 | **Fabric integration pipeline** | Pulls Share view data into `LH_CENTRAL_SILVER` (central lakehouse) |
| 6 | **Domain Silver** | Shortcuts route data into per-domain silver lakehouse |
| 7 | **Domain Gold warehouse** | Runs 5-step processing: profiles → user map → hierarchy expansion → DimSecurity → FactSecurity |
| 8 | **Facts stamped** | Every fact row gets a `SecurityId` column derived from the Gold tables |
| 9 | **Power BI semantic model** | 3-table filter chain: user email → profile → allowed security IDs → allowed fact rows |

---

## Part 1 — What the user does in Sakura

### 1.1 Two things in one request

When a user requests access to a report they are actually asking for **two separate things**:

| Layer | Question it answers | Sakura term |
|-------|---------------------|-------------|
| **OLS (Object-Level Security)** | *Can I open this report/audience at all?* | `PermissionType = 0` |
| **RLS (Row-Level Security)** | *When I open the report, which rows of data can I see?* | `PermissionType = 1` |

From the user's perspective it is one form. In the database Sakura creates **two separate `PermissionHeader` records** — one for OLS, one for RLS — each with its own approval chain.

### 1.2 What the user selects (RLS dimensions by domain)

The user must define their **data scope** (RLS dimensions). What that scope looks like depends on the domain/workspace:

| Domain | Workspace code | Dimensions user selects | RLS detail table |
|--------|---------------|-------------------------|-----------------|
| Growth Insights | GI | Entity → Client → MSS → Service Line | `RLSPermissionGIDetails` |
| Finance / DFI | DFI (ShareFUM) | Entity → Country → Client → MSS → Profit Center | `RLSPermissionFUMDetails` |
| CDI | CDI | Entity → Client → Service Line | `RLSPermissionCDIDetails` |
| Workforce Intelligence | WFI | Entity → People Aggregator | `RLSPermissionWFIDetails` |
| EMEA | EMEA | Entity → SL / Country / Client / CC / MSS depending on security type | `RLSPermissionEMEADetails` |
| AMER | AMER | Entity → SL / Client / CC / PC / MSS / PA depending on security type | `RLSPermissionAMERDetails` |

Dimensions come in two parts: a **Key** (which exact reference row, e.g. `EMEA`) and a **Hierarchy** (what level it is at, e.g. `Region`, `Cluster`, `Market`).

### 1.3 Security model and security type

Beneath the workspace sits a **Security Model** (`WorkspaceSecurityModels`) — a named package of rules for that workspace (e.g. `GI-Default`, `DFI-Default`). Within a model, the user picks a **Security Type** (a List-of-Values entry, e.g. `FUM`, `GI`, `EMEA-Orga`, `AMER-CLIENT`). The security type determines which dimensions appear in the form and which RLS detail table row shape is used.

---

## Part 2 — The approval chain

Every request follows a **fixed sequence**; the next step cannot begin until the previous one completes:

```
Submitted
    │
    ▼
Pending Line Manager (LM)
    │  LM confirms business justification
    ▼
Pending OLS Approver
    │  Approves access to the report/audience artifact
    ▼
Pending RLS Approver
    │  Approves the data scope (entity, client, etc.)
    ▼
Approved  ← access becomes active
```

Negative paths at any step: **Rejected** (by approver), **Cancelled** (by requester), **Revoked** (after approval, by authorized revoker).

**OLS and RLS approvers are different people** configured per workspace. The RLS approver is resolved from an approver matrix keyed on security model + security type + dimension combination.

**Nothing flows downstream until `ApprovalStatus = 2` on both headers.**

---

## Part 3 — What Sakura stores in the database

### 3.1 Core permission tables

```
PermissionRequests          ← one row per submitted request
    │
    ├── PermissionHeaders (OLS)   PermissionType = 0
    │       │
    │       └── OLSPermissions    OLSItemType: 0 = SAR report, 1 = Audience
    │
    └── PermissionHeaders (RLS)   PermissionType = 1
            │
            └── RLSPermissions
                    │
                    └── RLSPermission{Domain}Details   (one row per scope combination)
                        e.g. RLSPermissionGIDetails
                             RLSPermissionFUMDetails
                             RLSPermissionEMEADetails
                             etc.
```

`ApprovalStatus` on each `PermissionHeader`:

| Value | Meaning |
|-------|---------|
| 0 | Pending LM |
| 1 | Pending OLS Approver |
| 2 | **Approved** ← downstream picks this up |
| 3 | Pending RLS Approver |
| 4 | Rejected |
| 5 | Revoked |

### 3.2 Approved records are fully self-contained

Every approved RLS record in the detail table stores the complete scope: keys, hierarchies, security type, who requested, who approved, when. Nothing is deleted or changed after approval (revoke creates a new status row).

---

## Part 4 — Share views: the handoff interface from Sakura to Fabric

Sakura does **not push** data anywhere. It exposes read-only SQL views. Fabric **pulls** from them.

### 4.1 Share RLS views (one per domain)

Each view joins approved RLS headers + domain detail table. Only rows where `ApprovalStatus = 2` appear.

| View | Domain | Source detail table | Key RLS dimensions |
|------|--------|--------------------|--------------------|
| `ShareGI.RLS` | Growth Insights | `RLSPermissionGIDetails` | Entity, Client, MSS, ServiceLine |
| `ShareFUM.RLS` | Finance (DFI) | `RLSPermissionFUMDetails` | Entity, Country, Client, MSS, ProfitCenter |
| `ShareCDI.RLS` | CDI | `RLSPermissionCDIDetails` | Entity, Client, ServiceLine |
| `ShareWFI.RLS` | Workforce | `RLSPermissionWFIDetails` | Entity, PeopleAggregator |
| `ShareEMEA.RLS` | EMEA | `RLSPermissionEMEADetails` | Entity, SL, Client, CC, Country, MSS |
| `ShareAMER.RLS` | AMER | `RLSPermissionAMERDetails` | Entity, SL, Client, CC, PC, MSS, PA |

Every view exposes these standard audit columns in addition to the dimension keys:
`RequestedBy`, `RequestedFor`, `RequestDate`, `ApprovedBy`, `ApprovalDate`, `SecurityType`

Example — how `ShareGI.RLS` is built (simplified):

```sql
SELECT
    d.EntityKey, d.EntityHierarchy,
    d.ClientKey, d.ClientHierarchy,
    d.MSSKey,    d.MSSHierarchy,
    d.SLKey,     d.SLHierarchy,
    l.LoVValue AS SecurityType,
    pr.RequestedFor,  pr.RequestedBy,
    ph.ApprovedBy,    ph.ApprovedAt AS ApprovalDate
FROM dbo.RLSPermissionGIDetails d
JOIN dbo.RLSPermissions r   ON r.Id = d.RLSPermissionsId
JOIN dbo.PermissionHeaders ph
    ON ph.Id = r.PermissionHeaderId
   AND ph.PermissionType = 1    -- RLS only
   AND ph.ApprovalStatus = 2    -- Approved only
JOIN dbo.PermissionRequests pr  ON pr.Id = ph.PermissionRequestId
LEFT JOIN dbo.LoVs l            ON l.Id = r.SecurityTypeLoVId;
```

The EMEA and FUM views follow the same pattern with their respective detail tables.

### 4.2 Share OLS views (report / audience access)

Parallel views exist for OLS (approved = which reports/audiences the user can open):

`ShareGI.OLS`, `ShareFUM.OLS`, `ShareCDI.OLS`, `ShareWFI.OLS`, `ShareEMEA.OLS`, `ShareAMER.OLS`

These expose: `RequestedFor`, `OLSItemType` (Audience or SAR report), the app/audience identifiers, and the **`OLSEntraGroupId`** (Entra group GUID for the audience).

### 4.3 Database access for Fabric

Fabric connects to the Sakura database using a dedicated SQL user: **`EDPReaderUser`** (login `EDPReader`).

It has `SELECT` on all Share schemas:

```sql
GRANT SELECT ON SCHEMA::ShareAMER TO [EDPReaderUser];
GRANT SELECT ON SCHEMA::ShareWFI  TO [EDPReaderUser];
GRANT SELECT ON SCHEMA::ShareGI   TO [EDPReaderUser];
GRANT SELECT ON SCHEMA::ShareFUM  TO [EDPReaderUser];
GRANT SELECT ON SCHEMA::ShareEMEA TO [EDPReaderUser];
GRANT SELECT ON SCHEMA::ShareCDI  TO [EDPReaderUser];
```

No other schemas are exposed. Fabric cannot read request data, approver configs, or any internal tables.

---

## Part 5 — Two separate paths after Share views: OLS vs RLS

This is the most important conceptual split. OLS and RLS take **completely different technical routes** after the Share views.

```
Approved OLS permission
    │
    ├── Managed app (OLSMode = 0, Audience item)
    │       └── Auto.OLSGroupMemberships view
    │               └── SakuraV2ADSync.ps1 (nightly)
    │                       └── Entra security group (AudienceEntraGroupUID)
    │                               └── Power BI workspace access (can user open the app?)
    │
    └── Not-Managed app or SAR report
            └── Share*.OLS view
                    └── App owner manually manages their Entra groups / workspace roles
                            └── Power BI access managed by app owner

Approved RLS permission
    └── Share*.RLS view  ← Fabric integration pipeline pulls this
            └── LH_CENTRAL_SILVER (Fabric lakehouse)
                    └── Domain Silver shortcut
                            └── Domain Gold warehouse — 5-step processing
                                    └── SecurityId stamped on facts
                                            └── Power BI 3-table filter chain
```

**Key rule:** Approving OLS does **not** automatically grant RLS. Approving RLS does **not** automatically grant OLS. A user typically needs both approved to both open a report **and** see data in it.

---

## Part 6 — OLS path: Entra group sync (SakuraV2ADSync.ps1)

For **Managed** app audiences:

1. Approved OLS rows appear in `Auto.OLSGroupMemberships` (a database view reading `OLSPermissions` + `AppAudiences`).
2. `SakuraV2ADSync.ps1` reads that view.
3. For each `(RequestedFor, EntraGroupUID)` pair, it diffs desired vs current Entra membership.
4. Adds missing users, removes users no longer in the desired state.
5. The user is now in the correct Entra security group → Power BI workspace access granted.

Schedule: **once daily** (proposed improvement to every 8 hours).

The script does **not** touch RLS-only users or SAR report groups.

---

## Part 7 — RLS path: Fabric integration pipeline → 5-step processing

This is where approved data scope (which entities, clients, etc.) becomes row-level filtering in Power BI.

### 7.1 Step 0 — Integration pipeline pulls Sakura Share views into Fabric

The **Fabric integration pipeline** (owned by EDP/domain data teams, not in this repo) connects to Sakura using `EDPReaderUser` and copies the Share RLS view data into **`LH_CENTRAL_SILVER`** (the central integration lakehouse).

All domain views land here:

```
LH_CENTRAL_SILVER
    ├── SHAREFUM_RLS    (Finance)
    ├── SHAREGI_RLS     (Growth Insights)
    ├── SHARECDI_RLS    (CDI)
    └── SHAREWFI_RLS    (Workforce)
```

From there, **Fabric shortcuts** (virtual pointers — no data copy) route each domain's table into the appropriate domain silver lakehouse.

### 7.2 Step 1 — LH_#Domain_SILVER: data + dimensions together

Each domain has its own silver lakehouse (e.g. `LH_FINANCE_SILVER`, `LH_GI_SILVER`).

Contents:
- The domain RLS source table (shortcut from central silver, e.g. `SHAREFUM_RLS`)
- Dimension tables used to expand hierarchy requests into leaf IDs:
  - `DIM_DimEntity` — full entity hierarchy (Global → Region → Cluster → Market → Entity)
  - `DIM_DimClient`, `DIM_DimMSS`, `DIM_DimServiceLine`, `DIM_DimProfitCenter`

The entity hierarchy here comes from **Ronin/RCOE** — it defines which entities roll up to which cluster, market, region.

### 7.3 Step 2 — WH_#Domain_GOLD: 5-step security table processing

This is the core transformation. Each domain gold warehouse processes the approved Sakura data into 5 security tables. Processing runs as a scheduled pipeline (FUM/GI: every 4 hours; CDI: once daily).

---

#### Security Table 1: DimSecurityProfile — deduplicate access combinations

**Problem it solves:** 100 users might all request "Americas Region, All Clients, All MSS." Instead of creating 100 identical security setups, create **one profile** and assign all 100 users to it.

**How built:**
- Read all rows from the Sakura Share RLS view.
- Group by the unique combination of access dimensions.
- Assign a stable `SecurityProfileID` via `MERGE` (not truncate+reload — the ID must be stable across every pipeline run because it is used as a foreign key everywhere).

**Key columns:**

| Column | What it holds |
|--------|--------------|
| `SecurityProfileID` | Stable surrogate key for this unique access combination |
| `SecurityProfileMapKey` | Human-readable string of the full combination, e.g. `Americas|Region|All Clients|All MSS|BR_TOT_BCC|BPCBrand` |
| `EntityKey`, `EntityHierarchy` | Requested entity scope |
| `ClientKey`, `ClientHierarchy` | Requested client scope |
| `MSSKey`, `ProfitCenterKey`, etc. | Other dimension scopes |
| `GlobalAccess` | Flag: non-zero = broad/global access |
| `SourceSystem` | Always `SAKURAV2` |

> **Only this table uses MERGE.** All others use truncate+reload.

---

#### Security Table 2: DimAdAccountSecurityProfileMapping — user email to profile

**Problem it solves:** The profile (Table 1) is a set of access rules. This table says *which people* have those rules.

**How built:**
- For each user email in the Share RLS source, look up which profile they belong to (from Table 1).
- One user can appear multiple times if they have multiple approved requests mapping to different profiles.

**Key columns:**

| Column | What it holds |
|--------|--------------|
| `EmailAddress` | User's AD email (matches Power BI login) |
| `SecurityProfileID` | Which profile this user belongs to |

**Example:**
```
alice@dentsu.com   → SecurityProfileID: 880000001
bob@dentsu.com     → SecurityProfileID: 880000001
carol@dentsu.com   → SecurityProfileID: 660000001
```
Alice and Bob requested identical access → same profile → they see identical data.

---

#### Security Table 3: Request Tables — expand hierarchy to leaf entity IDs

**Problem it solves:** A user requested "Americas Region" but fact tables contain individual entity IDs (e.g. `US001`, `BR045`), not a "region" column. This step translates the hierarchy-level request into the actual leaf IDs.

**How built:**
- Using `DIM_DimEntity` (entity hierarchy from Ronin/RCOE), expand "Americas Region" to all ~243 entity IDs under Americas.
- Same logic applied to every dimension:

| Request table | Expands |
|--------------|---------|
| `EntityRequests` | Region/Cluster/Market → individual Entity IDs |
| `ClientRequests` | Client hierarchy → individual Client IDs |
| `ServiceLineRequests` | SL hierarchy → individual SL IDs |
| `MSSRequests` | MSS hierarchy → individual MSS IDs |
| `CountryRequests` | Country/Market → individual Country IDs |
| `ProfitCenterRequests` | PC hierarchy → individual Profit Center IDs |

**Important nuance:** If the request is at Region or Market level, ALL source systems (BPC + D365 etc.) for those entities are included. If the request is at Entity level, the user must have specified a source system — a BPC entity request only grants access to BPC-sourced data for that entity.

---

#### Security Table 4: DimSecurity — catalog of unique fact-level attribute combinations

**Problem it solves:** Fact tables don't have a "which user can see this row" column. They have attribute columns (entity ID, client ID, MSS ID, etc.). This table catalogs every unique combination of those attributes that actually appears in the facts and assigns each a `SecurityId`.

**Two-part build:**

1. **RLSSelects (helper config table):** Defines, per fact table, which columns are the security keys. Example for FUM:

   | Fact table | EntityColumn | ClientColumn | BrandColumn | MSSColumn |
   |------------|-------------|-------------|------------|----------|
   | `BI_Fact.FactPNL` | `EntityRLSMapKey` | `ClientRLSMapKey` | `BrandRLSMapKey` | `MSSRLSMapKey` |
   | `BI_Fact.FactPL` | same pattern | … | … | … |

2. **DimSecurity population:** For each participating fact table, select `DISTINCT` combinations of all security key columns, union all fact tables, assign `SecurityId` to each unique combination.

**Special note — composite EntityRLSMapKey for timesheets:**
Timesheet facts involve three entities (home entity of employee, destination entity, project entity). The `EntityRLSMapKey` for these rows is a **composite of all three** separated by `*`, e.g. `10001960*70000390*10001960`. The security check validates all three.

For P&L facts it is a single entity ID (the other slots are `-1`).

**Key columns:**

| Column | What it holds |
|--------|--------------|
| `SecurityId` | Surrogate key for this unique fact attribute combo |
| `EntityRLSMapKey` | Entity ID(s) from the fact (single or composite) |
| `ClientRLSMapKey` | Client ID |
| `BrandRLSMapKey` | Brand ID (FUM), `-1` = not applicable |
| `MSSRLSMapKey` | MSS ID, `N/A` = not applicable |
| `ProfitCenterRLSMapKey` | Profit center ID |
| `SecurityMapKey` | Full composite string key |
| `EntityId_P1/P2/P3` | Individual entity IDs broken out (timesheet use) |

---

#### Security Table 5: FactSecurity — the bridge table

**Problem it solves:** Connect "which rows in the data" (`SecurityId`) to "which user profile can see them" (`SecurityProfileId`).

**How built:**
- Join every `DimSecurity` row (a real fact combination) against the expanded Request Tables (Table 3).
- For each `DimSecurity` row, check: does its entity ID appear in `EntityRequests` for this profile? Does its client ID appear in `ClientRequests`? Etc.
- Where **all** conditions are satisfied → write one record: `SecurityId → SecurityProfileId`.

**Key columns:**

| Column | What it holds |
|--------|--------------|
| `SecurityId` | The fact combination that a profile can access |
| `SecurityProfileId` | The profile that can see this combination |

**Example:**
Profile `880000001` (Americas, All Clients) maps to hundreds of SecurityIds — every unique entity/client/MSS/brand combination that appears in facts and falls within Americas.

---

### 7.4 Step 3 — Facts get SecurityId stamped

Once `DimSecurity` is built, the data team stamps every fact row with a `SecurityId` column:

```sql
-- Example for FUM FactPNL
SELECT
    F.*,
    DS.SecurityId AS FUM_SecurityId
FROM BI_Fact.FactPNL AS F
LEFT JOIN FUM_SECURITY.DimSecurityNodeSakuraV2 AS DS
    ON F.EntityRLSMapKey = DS.EntityRLSMapKey
   AND F.ClientRLSMapKey = DS.ClientRLSMapKey
   AND F.BrandRLSMapKey  = DS.BrandRLSMapKey
   AND F.MSSRLSMapKey    = DS.MSSRLSMapKey
```

If a fact row's attribute combination is in `DimSecurity` → it gets a `SecurityId`.
If no user has ever requested access to that combination → `SecurityId = NULL` → row is invisible to all scoped users (only workspace admins with Contributor role bypass RLS and see everything).

For facts shared between domains (e.g. `FactOpportunity` shared between FUM and GI), the fact gets **both** `FUM_SecurityId` and `GI_SecurityId` columns. The active report determines which one is used.

All enriched facts from all domains are unioned in **`WS_CENTRAL_SHARE`** — the sharing/consumption layer.

---

## Part 8 — Power BI: the 3-table filter chain

When a user opens a Power BI report, this filter chain fires automatically:

```
Step 1: Identify logged-in user
        Power BI knows the user's email from their Entra login.

Step 2: Filter ADAccountSecurityProfile
        "Give me all SecurityProfileIDs for email = alice@dentsu.com"
        Returns: SecurityProfileID = 880000001
                 (and any others if Alice has multiple approved access scopes)

Step 3: Filter FactSecurity
        "Give me all SecurityIds where SecurityProfileID IN (880000001)"
        Returns: 126230, 644413, 74070, 292332, 308195, ... (hundreds of IDs)

Step 4: Filter DimSecurity
        "Give me all attribute combos where SecurityId IN (above set)"
        Returns: the attribute combinations Alice is allowed to see

Step 5: Filter Fact table
        "Give me all fact rows where FUM_SecurityId IN (allowed SecurityIds)"
        Result: Alice only sees rows for Americas entities, all clients
```

Visually in the Power BI semantic model:

```
┌──────────────────────────────────┐
│ ADAccountSecurityProfileMapping  │
│  EmailAddress = "alice@dentsu.com│
│  SecurityProfileID = 880000001   │
└────────────────┬─────────────────┘
                 │ 1 → many
                 ▼
┌──────────────────────────────────┐
│ FactSecurity                     │
│  SecurityProfileID = 880000001   │──► filters to allowed SecurityIds
│  SecurityId = 126230, 644413 … │
└────────────────┬─────────────────┘
                 │ many → 1
                 ▼
┌──────────────────────────────────┐
│ DimSecurity                      │
│  SecurityId = 126230 …           │──► which attribute combos
└────────────────┬─────────────────┘
                 │ 1 → many
                 ▼
┌──────────────────────────────────┐
│ BI_Fact.FactPNL                  │
│  FUM_SecurityId = 126230 …       │──► only matching rows visible
└──────────────────────────────────┘
```

**Access override:** If someone is given **Contributor** (or higher) role directly on the Power BI workspace, RLS is **bypassed entirely**. Only **Viewer-level** users are subject to RLS filtering.

---

## Part 9 — Full pipeline inventory

### Pipelines into Sakura (reference data, NOT approved requests)

These keep Sakura's dimension tables fresh so the request form shows valid choices:

| Pipeline | Runs on | Source | What it loads into Sakura |
|----------|---------|--------|--------------------------|
| `P_REF_CENTRAL_IMPORT` | `azeuw1dadfsakura` | Fabric `LH_CENTRAL_GOLD` (`BL_DIM.*`) | `ref.Entities`, `ref.CostCenters`, `ref.ServiceLines`, `ref.MasterServiceSets`, `ref.Employees`, `ref.ProfitCenters`, `ref.BPCBrands`, `ref.BPCSegments` |
| `P_REF_RONIN_IMPORT` | `azeuw1dadfsakura` | Ronin `Backbone` MDM (`mdm.*`) | `ref.Markets`, `ref.Clusters`, `ref.Regions`, `ref.Countries`, `ref.BusinessUnits`, `ref.DentsuStakeholders`, `ref.ClientPrograms`, `ref.PeopleAggregators` |
| `P_ALL_SAKURA_D_Automation` | `azeuw1npsenadf02` | Synapse/Sensei (`DB_Synapse_Sensei`) | V1: `Staging.Entity`, `Staging.CostCenter`, `Staging.Client`, `Staging.ServiceLine`, `Staging.MasterServiceSet` |

These pipelines have **nothing to do with approved requests** — they load reference/dimension data only.

### Pipelines out of Sakura (approved access data)

| Pipeline | Owner | Runs every | What it does |
|----------|-------|-----------|--------------|
| **Fabric integration pipeline** (unnamed here) | EDP / domain data teams | On schedule (varies) | Reads `Share*.RLS` + `Share*.OLS` views via `EDPReaderUser`; lands data in `LH_CENTRAL_SILVER` |
| **FUM RLS processing pipeline** | Finance data team | Every **4 hours** | Runs 5-step Gold processing; produces FUM security tables; stamps `FactPNL`, `FactPL` etc. |
| **GI RLS processing pipeline** | GI data team | Every **4 hours** | Runs 5-step Gold processing for GI; stamps `FactOpportunity`, `FactCPS`, `FactGL` |
| **CDI RLS processing pipeline** | CDI data team | **Once daily** | Same 5-step pattern for CDI facts |
| **WFI RLS processing pipeline** | WFI data team | Per WFI schedule | Same pattern for WFI facts |
| **AD sync — `SakuraV2ADSync.ps1`** | Vishal Chandanshive's team | **Once daily** | Reads `Auto.OLSGroupMemberships`; syncs Managed OLS users into Entra audience groups |

> The integration and domain RLS pipelines live in Microsoft **Fabric** (not in the Sakura ADF instance `azeuw1dadfsakura`) and are maintained by the respective data teams — they are not stored in this repo.

---

## Part 10 — Timing: how long until a user sees data after approval

| User state | Wait for AD sync (OLS) | Wait for RLS pipeline | Total worst case |
|-----------|----------------------|----------------------|-----------------|
| Brand new user | Up to **8 hours** (daily AD sync) | Up to **4 hours** (FUM/GI pipeline) | Up to **12 hours** |
| User already in AD group (existing RLS user expanding scope) | None | Up to **4 hours** | Up to **4 hours** |
| CDI user | Up to **8 hours** | Up to **24 hours** (daily CDI pipeline) | Up to **32 hours** |
| Existing user, access unchanged | — | — | Immediate |

The two waits are **independent and may overlap** — the pipeline may run before or after AD sync.

---

## Part 11 — What V1 does differently

Sakura V1 (the older version, still running via `P_ALL_SAKURA_D_Automation`) uses a **single mechanism** for both OLS and RLS: **Entra group membership**.

```
V1 approved request
    │
    └── RDSecurityGroupPermission view (desired state)
            │
            └── SakuraADSync.ps1 (daily)
                    │
                    └── Entra security groups (#SG-UN-SAKURA-FIN, etc.)
                            │
                            └── Power BI workspace/report access
```

- **No separate Share RLS views** in V1.
- **No 5-table Gold processing** in V1.
- Both "can open the report" and "which rows" are encoded in group membership.
- The V1 script targets group GUIDs stored in `dbo.RDSecurityGroupPermission` (view built from approved requests where `ApprovalStatus = 1` and `RequestType IN (0, 2, 7)`).

V2 separates these two concerns cleanly: OLS → groups; RLS → Share views + Fabric processing.

---

## Part 12 — Why are there so many pipelines?

| Reason | Explanation |
|--------|-------------|
| **Direction** | Reference data flows *into* Sakura (ADF pipelines). Approved access flows *out of* Sakura (Fabric pipelines). Two separate directions, two separate systems. |
| **Scale of hierarchy expansion** | A single "Americas Region" request expands to ~243 entities. This is not a simple query — it requires joining against full dimension hierarchies and computing all possible fact-level combinations. That computation belongs in Fabric Gold, not in Sakura. |
| **Domain isolation** | Each domain (FUM, GI, CDI, WFI, EMEA, AMER) has different dimensions and different fact tables. Separate pipelines allow different schedules, separate failure isolation, and separate team ownership. |
| **Deduplication performance** | The profile-based design (DimSecurityProfile) means 10,000 approved requests may only produce 500 unique profiles. Without this deduplication, FactSecurity would be orders of magnitude larger and Power BI filtering would be far slower. |
| **Stability of surrogate keys** | `SecurityProfileID` and `SecurityId` are used as foreign keys in fact tables and the Power BI model. They must be stable across every pipeline run. MERGE on DimSecurityProfile ensures this. |

---

## Part 13 — Responsibilities (who owns what)

| Area | Owner |
|------|-------|
| Sakura request form, approval workflow, database | Sakura app team |
| `Share*.RLS` and `Share*.OLS` view definitions | Sakura app team (in `Sakura_DB/Share/Views/`) |
| `EDPReader` DB user access | Sakura DBA |
| Fabric integration pipeline (Sakura → `LH_CENTRAL_SILVER`) | EDP / integration team |
| FUM RLS pipeline bugs / processing | Finance data team |
| GI RLS pipeline bugs / processing | GI data team |
| CDI / WFI RLS pipeline bugs | Respective domain data teams |
| AD group sync (`SakuraV2ADSync.ps1`) | Vishal Chandanshive's team |
| Entity hierarchy maintenance (which entity rolls to which cluster) | RCOE via Ronin |
| Power BI workspace admin / Contributor overrides | Power BI workspace admins |

---

## Part 14 — End-to-end example (Alice, FUM Finance data)

**Setup:** Alice needs to see Americas P&L data in the Finance reports.

| Step | What happens | Where |
|------|-------------|-------|
| Alice submits request | OLS: Finance report audience. RLS: Entity=Americas, Hierarchy=Region, Client=All, MSS=All, Brand=BR_TOT_BCC, PC=All | Sakura UI |
| LM approves | Business justification confirmed | Sakura DB: both headers move to `PendingOLS` then `PendingRLS` |
| OLS approver approves | Access to Finance audience confirmed | Sakura DB: OLS header `ApprovalStatus = 2` |
| RLS approver approves | Data scope for Americas confirmed | Sakura DB: RLS header `ApprovalStatus = 2` |
| Alice appears in `ShareFUM.RLS` | View now returns a row with `EntityKey=Americas`, `EntityHierarchy=Region`, `RequestedFor=alice@dentsu.com` | Sakura DB |
| AD sync runs (next daily run) | Alice added to Finance audience Entra group → she can open the Finance workspace in Power BI | Entra / `SakuraV2ADSync.ps1` |
| FUM RLS pipeline runs (next 4h window) | `ShareFUM.RLS` is pulled into `LH_CENTRAL_SILVER` | Fabric |
| Silver shortcut created | Alice's row available in `LH_FINANCE_SILVER` | Fabric |
| Gold processing — Table 1 | Profile `880000001` already exists or is created: `Americas|Region|All Clients|All|BR_TOT_BCC` | `WH_FUM_GOLD` |
| Gold processing — Table 2 | `alice@dentsu.com → SecurityProfileID 880000001` | `WH_FUM_GOLD` |
| Gold processing — Table 3 | "Americas" expanded to ~243 entity IDs using `DIM_DimEntity` | `WH_FUM_GOLD` |
| Gold processing — Table 4 | All unique (Entity, Client, Brand, MSS, PC) combos in `FactPNL` are cataloged with `SecurityId` | `WH_FUM_GOLD` |
| Gold processing — Table 5 | Every SecurityId whose entity is in Americas (and client = All, etc.) is linked to profile `880000001` in `FactSecurity` | `WH_FUM_GOLD` |
| Facts stamped | Each `FactPNL` row gets `FUM_SecurityId` from `DimSecurity` join | `WS_CENTRAL_SHARE` |
| Alice opens the Finance report | Power BI: email=alice → profile 880000001 → FactSecurity → allowed SecurityIds → FactPNL rows → only Americas rows visible | Power BI |

Total time from approval to seeing data: **up to 12 hours** (whichever of AD sync or RLS pipeline runs last).

---

## Appendix: Glossary of key terms

| Term | Meaning |
|------|---------|
| **OLS** | Object-Level Security — controls which reports/audiences a user can open |
| **RLS** | Row-Level Security — controls which rows a user sees inside a report |
| **Share view** | Read-only SQL view in Sakura exposing only approved records; consumed by Fabric |
| **EDPReader** | SQL login Fabric uses to query Sakura Share views |
| **LH_CENTRAL_SILVER** | Fabric central lakehouse where Sakura Share view data first lands |
| **DimSecurityProfile** | Gold table: unique access combinations; uses MERGE for stable IDs |
| **DimAdAccountSecurityProfileMapping** | Gold table: user email → SecurityProfileID |
| **Request tables** | Gold tables: expand hierarchy requests (e.g. Region → 243 entity IDs) |
| **DimSecurity** | Gold table: unique attribute combinations present in actual facts |
| **FactSecurity** | Gold table: bridge — which SecurityId (fact combo) each SecurityProfileId can see |
| **SecurityId** | Surrogate key for a unique combination of fact-level attribute values |
| **SecurityProfileID** | Surrogate key for a unique combination of requested access dimensions |
| **RLSSelects** | Config table: defines which fact columns are security keys per fact table |
| **3-table filter chain** | Power BI mechanism: ADAccountSecurityProfile → FactSecurity → DimSecurity → Fact |
| **Managed OLS** | App audiences where Sakura automates Entra group membership via sync script |
| **Not-Managed OLS** | App audiences where app owners manage their own groups (Sakura only records approval) |
| **EDP** | Enterprise Data Platform — the Fabric/Power BI downstream system |
| **Fabric shortcut** | Virtual pointer in Fabric: makes data from one lakehouse appear in another without copying |
| **azeuw1dadfsakura** | ADF resource name: runs `P_REF_CENTRAL_IMPORT` and `P_REF_RONIN_IMPORT` (reference data INTO Sakura) |
| **RCOE** | Team owning the entity hierarchy in Ronin MDM |
