# RLS Approver Resolution — End-to-End Examples by Workspace

This document gives **concrete examples** for how RLS approvers are resolved for each workspace, using the **Script_Populate** data so the flow is easy to follow. **Traversal applies only to the Organisation/Entity dimension**; all other dimensions stay fixed (see [APPROVER_FINDING_FLOW.md](APPROVER_FINDING_FLOW.md)).

**Data source:** `Script_Populate/0-Global Script.sql` (workspaces, permission requests, LM from `refv.Employees`), `Script_Populate/1-AMER Script.sql`, `1-CDI Script.sql`, `1-GI Script.sql`, `1-WFI Script.sql`, `1-DFI Script.sql` (RLS*Approvers and RLS*Permission*Details).

We start with **AMER** (most accurate and documented data), then CDI, GI, WFI, DFI.

---

## 1. AMER (start here — most accurate data)

**Script_Populate:** `0-Global Script.sql` (workspace AMERClient&GrowthPROD / AMERPresentationPROD), `1-AMER Script.sql`  
**Table:** `RLSAMERApprovers` (108 rows after insert)  
**Security model:** AMER-Default  
**Security types:** AMER-ORGA, AMER-Client (and PA, CC, MSS, PC in script)  
**Dimensions:** EntityKey, EntityHierarchy, SLKey, SLHierarchy, ClientKey, ClientHierarchy, plus PC, CC, PA, MSS

### 1.1 Sample config from Script_Populate (1-AMER Script.sql)

| EntityKey    | EntityHierarchy | SLKey   | ClientKey   | Approvers              |
|-------------|-----------------|---------|-------------|------------------------|
| Canada      | Market          | Overall | (empty)     | Desiree.Benson@dentsu.com |
| USA         | Market          | CRTV    | (empty)     | Desiree.Benson@dentsu.com |
| North America | Cluster       | CXM     | (empty)     | Desiree.Benson@dentsu.com |
| Americas    | Region          | Overall | (empty)     | Desiree.Benson@dentsu.com |
| Americas    | Region          | FIN     | All Clients | Desiree.Benson@dentsu.com |
| LATAM       | Cluster         | Overall | All Clients | Desiree.Benson@dentsu.com (AMER-Client) |

### 1.2 End-to-end flow (AMER)

**Example A — Exact match (Market)**  
- **Request:** Workspace AMER, SecurityType **AMER-ORGA**, EntityKey **Canada**, EntityHierarchy **Market**, SLKey **Overall**, Client empty.  
- **Lookup:** `RLSAMERApprovers` where SecurityModelId = AMER-Default, SecurityTypeLoVId = AMER-ORGA, EntityKey = Canada, EntityHierarchy = Market, SLKey = Overall, ClientKey NULL/empty.  
- **Result:** **Exact match** → Approvers = `Desiree.Benson@dentsu.com`.

**Example B — No match at Market, traverse Entity only (same SL/Client)**  
- **Request:** Workspace AMER, SecurityType **AMER-ORGA**, EntityKey **Vancouver** (hypothetical market), EntityHierarchy **Market**, SLKey **Overall**, Client empty.  
- **Lookup:** No row for Vancouver at Market.  
- **Traversal (Entity only):** Keep SLKey=Overall, ClientKey=empty. Try next Entity level: **Cluster** (e.g. North America for Canada/Vancouver).  
- **Lookup:** RLSAMERApprovers with EntityKey = **North America**, EntityHierarchy = **Cluster**, SLKey = Overall, Client empty.  
- **Result:** **Match at Cluster** → Approvers = `Desiree.Benson@dentsu.com`.

**Example C — Match at Region (Americas)**  
- **Request:** EntityKey **Mexico**, EntityHierarchy **Market**, SLKey **FIN**, ClientKey **All Clients**.  
- **Lookup:** No row for Mexico / Market / FIN / All Clients.  
- **Traversal:** Keep SLKey=FIN, ClientKey=All Clients. Try Cluster (e.g. North America) → no row. Try **Region (Americas)**.  
- **Lookup:** EntityKey = **Americas**, EntityHierarchy = **Region**, SLKey = FIN, ClientKey = All Clients.  
- **Result:** **Match** → Approvers = `Desiree.Benson@dentsu.com`.

**Example D — NOT FOUND (no Entity row at any level)**  
- **Request:** EntityKey **UnknownMarket**, EntityHierarchy **Market**, SLKey **Overall**.  
- **Lookup:** No match at Market, Cluster, Region, or Global for that combination (SL/Client fixed).  
- **Result:** **NOT FOUND**.

### 1.3 Text flow (AMER)

```
Request: AMER, AMER-ORGA, Canada, Market, Overall, (no Client)
  → RLSAMERApprovers: match SecurityModelId, SecurityTypeLoVId, EntityKey=Canada, EntityHierarchy=Market, SLKey=Overall, ClientKey NULL
  → Exact match? YES
  → Return Approvers: Desiree.Benson@dentsu.com

Request: AMER, AMER-ORGA, Vancouver, Market, Overall, (no Client)
  → RLSAMERApprovers: no row for Vancouver/Market/Overall
  → Entity in request? YES → Keep SL=Overall, Client fixed. Traverse Entity: Market→Cluster→Region→Global
  → Try North America (Cluster), same SL/Client → Match
  → Return Approvers: Desiree.Benson@dentsu.com
```

---

## 2. CDI

**Script_Populate:** `0-Global Script.sql`, `1-CDI Script.sql`  
**Table:** `RLSCDIApprovers` (4 rows in script)  
**Security model:** CDI-Default  
**Security type:** CDI  
**Dimensions:** EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy (script uses Entity, Client, SL only for approvers)

### 2.1 Sample config (1-CDI Script.sql)

| EntityKey | EntityHierarchy | ClientKey   | ClientHierarchy | SLKey   | Approvers |
|-----------|-----------------|-------------|-----------------|---------|-----------|
| Global    | Global          | All Clients | All Clients     | Overall | ben.bartl@dentsu.com; stephen.byrne@dentsu.com; nitin.menon@dentsu.com |
| Americas  | Region          | All Clients | All Clients     | Overall | desiree.benson@dentsu.com |
| EMEA      | Region          | All Clients | All Clients     | Overall | gianluca.gualtieri@dentsu.com |
| APAC      | Region          | All Clients | All Clients     | Overall | dennis.yip@dentsu.com |

### 2.2 End-to-end flow (CDI)

**Example A — Exact match (Region)**  
- **Request:** Workspace CDI, SecurityType **CDI**, EntityKey **EMEA**, EntityHierarchy **Region**, ClientKey **All Clients**, SLKey **Overall**.  
- **Lookup:** RLSCDIApprovers, full key match.  
- **Result:** **Exact match** → Approvers = `gianluca.gualtieri@dentsu.com`.

**Example B — No match at Market, traverse Entity only**  
- **Request:** EntityKey **Spain**, EntityHierarchy **Market**, ClientKey **All Clients**, SLKey **Overall**.  
- **Lookup:** No row for Spain/Market.  
- **Traversal:** Keep Client=All Clients, SL=Overall. Try **Cluster** (e.g. Iberia) → no row in script. Try **Region (EMEA)**.  
- **Result:** **Match** at EMEA/Region → Approvers = `gianluca.gualtieri@dentsu.com`.

**Example C — Global fallback**  
- **Request:** EntityKey **Japan**, EntityHierarchy **Market**, ClientKey **All Clients**, SLKey **Overall**.  
- **Lookup:** No Japan, no APAC cluster in approvers. Traverse to **Global**.  
- **Result:** **Match** at Global/Global → Approvers = `ben.bartl@dentsu.com; stephen.byrne@dentsu.com; nitin.menon@dentsu.com`.

### 2.3 Text flow (CDI)

```
Request: CDI, CDI, EMEA, Region, All Clients, Overall
  → RLSCDIApprovers: match model, type, Entity=EMEA, EntityHierarchy=Region, Client=All Clients, SL=Overall
  → Exact match? YES
  → Return Approvers: gianluca.gualtieri@dentsu.com

Request: CDI, CDI, Spain, Market, All Clients, Overall
  → No row for Spain/Market → Traverse Entity only (Client, SL fixed)
  → Try Cluster → Try Region (EMEA) → Match
  → Return Approvers: gianluca.gualtieri@dentsu.com
```

---

## 3. GI (Client & Growth Insights)

**Script_Populate:** `1-GI Script.sql`  
**Table:** `RLSGIApprovers` (40 rows)  
**Security model:** GI-Default  
**Security type:** GI  
**Dimensions:** EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, MSSKey, MSSHierarchy, SLKey, SLHierarchy

### 3.1 Sample config (1-GI Script.sql)

| EntityKey   | EntityHierarchy | ClientKey   | MSSKey | SLKey   | Approvers |
|-------------|-----------------|-------------|--------|---------|-----------|
| Australia   | Market          | All Clients | Overall| Overall | thao.tran@dentsu.com; Stevie.Dobbs@dentsu.com |
| UK          | Market          | All Clients | Overall| Overall | angela.ricaurte@dentsu.com; Jason.mcnamee@dentsu.com |
| Spain       | Market          | All Clients | Overall| Overall | silvia.friero@dentsu.com; jose.taborda@dentsu.com |
| Italy       | Market          | All Clients | Overall| Overall | marianna.modica@dentsu.com; gianluca.gualtieri@dentsu.com |
| Singapore   | Market          | All Clients | Overall| Overall | hannui.kang@dentsu.com; sarang.sorte@dentsu.com |

### 3.2 End-to-end flow (GI)

**Example A — Exact match (Market)**  
- **Request:** Workspace GI (CGI), SecurityType **GI**, EntityKey **UK**, EntityHierarchy **Market**, ClientKey **All Clients**, MSSKey **Overall**, SLKey **Overall**.  
- **Result:** **Exact match** → Approvers = `angela.ricaurte@dentsu.com; Jason.mcnamee@dentsu.com`.

**Example B — Traverse Entity only**  
- **Request:** EntityKey **London** (hypothetical market), EntityHierarchy **Market**, Client/MSS/SL = All Clients, Overall, Overall.  
- **Lookup:** No London. Traverse Entity: try **Cluster** then **Region**. UK is Market; if no Cluster row, need Region (e.g. EMEA) — script has Markets only for GI.  
- **Result:** Depends on actual rows; if no higher level for UK, **NOT FOUND** until a Cluster/Region/Global row exists for that combination.

### 3.3 Text flow (GI)

```
Request: GI, GI, UK, Market, All Clients, Overall, Overall
  → RLSGIApprovers: match model, type, Entity=UK, EntityHierarchy=Market, Client, MSS, SL
  → Exact match? YES
  → Return Approvers: angela.ricaurte@dentsu.com; Jason.mcnamee@dentsu.com
```

---

## 4. WFI (Workforce Intelligence)

**Script_Populate:** `1-WFI Script.sql`  
**Table:** `RLSWFIApprovers` (126 rows)  
**Security model:** WFI-Default  
**Security type:** WFI  
**Dimensions:** EntityKey, EntityHierarchy, PAKey, PAHierarchy only

### 4.1 Sample config (1-WFI Script.sql)

| EntityKey       | EntityHierarchy | PAKey                    | PAHierarchy     | Approvers                          |
|-----------------|-----------------|--------------------------|-----------------|------------------------------------|
| Global          | Global          | BX                       | Business Areas  | lee.mann@dentsu.com; georgia.hall@dentsu.com |
| Global          | Global          | Finance                  | Business Functions | lee.mann@dentsu.com; georgia.hall@dentsu.com |
| EMEA            | Region          | CXM                      | Business Areas  | lee.mann@dentsu.com; georgia.hall@dentsu.com |
| Global & Central| Region          | Media                    | Business Areas  | lee.mann@dentsu.com; georgia.hall@dentsu.com |

### 4.2 End-to-end flow (WFI)

**Example A — Exact match (Global)**  
- **Request:** Workspace WFI_PROD, SecurityType **WFI**, EntityKey **Global**, EntityHierarchy **Global**, PAKey **Finance**, PAHierarchy **Business Functions**.  
- **Result:** **Exact match** → Approvers = `lee.mann@dentsu.com; georgia.hall@dentsu.com`.

**Example B — Traverse Entity only (PA fixed)**  
- **Request:** EntityKey **France**, EntityHierarchy **Market**, PAKey **Finance**, PAHierarchy **Business Functions**.  
- **Lookup:** No France/Market/Finance. Keep **PA fixed**. Traverse Entity: Market → Cluster → Region → Global.  
- **Result:** If no France/Cluster, try **EMEA (Region)** or **Global** with same PA → e.g. match at Global → Approvers = `lee.mann@dentsu.com; georgia.hall@dentsu.com`.

### 4.3 Text flow (WFI)

```
Request: WFI, WFI, Global, Global, Finance, Business Functions
  → RLSWFIApprovers: match model, type, Entity=Global, EntityHierarchy=Global, PAKey=Finance, PAHierarchy=Business Functions
  → Exact match? YES
  → Return Approvers: lee.mann@dentsu.com; georgia.hall@dentsu.com

Request: WFI, WFI, France, Market, Finance, Business Functions
  → No row for France/Market → Traverse Entity only (PA fixed)
  → Try Cluster → Try Region (EMEA) or Global with same PA → Return first match
```

---

## 5. DFI (FUM — Finance)

**Script_Populate:** `1-DFI Script.sql`  
**Table:** `RLSFUMApprovers` (97 rows)  
**Security model:** DFI-Default  
**Security type:** FUM  
**Dimensions:** EntityKey, EntityHierarchy, CountryKey, CountryHierarchy, ClientKey, ClientHierarchy, MSSKey, MSSHierarchy, ProfitCenterKey (PCKey), ProfitCenterHierarchy (PCHierarchy)

### 5.1 Sample config (1-DFI Script.sql)

| EntityKey    | EntityHierarchy | ClientKey   | MSSKey | ProfitCenterKey | Approvers |
|--------------|----------------|-------------|--------|-----------------|-----------|
| Global       | Global         | All Clients | Overall| BR_TOTAL        | Terry.Newell@dentsu.com; Kate.Rudwick@dentsu.com |
| UK&I         | Cluster        | All Clients | Overall| BR_TOTAL        | nick.storey@dentsu.com; James.Sallows@dentsu.com |
| France       | Cluster        | All Clients | Overall| BR_TOTAL        | Frederic.Labey@dentsu.com |
| Canada       | Market         | All Clients | Overall| BR_TOTAL        | patrick.renard@dentsu.com |
| Iberia       | Cluster        | All Clients | Overall| BR_TOTAL        | Ignacio.Compains@dentsu.com; Daniel.Rodriguez@dentsu.com |

### 5.2 End-to-end flow (DFI/FUM)

**Example A — Exact match (Market)**  
- **Request:** Workspace DFI, SecurityType **FUM**, EntityKey **Canada**, EntityHierarchy **Market**, ClientKey **All Clients**, MSSKey **Overall**, ProfitCenterKey **BR_TOTAL**, ProfitCenterHierarchy **BPCBrand**.  
- **Result:** **Exact match** → Approvers = `patrick.renard@dentsu.com`.

**Example B — Traverse Entity only**  
- **Request:** EntityKey **Toronto** (hypothetical market), EntityHierarchy **Market**, same Client/MSS/PC.  
- **Lookup:** No Toronto. Keep **Country, Client, MSS, PC fixed**. Traverse Entity: Market → **Cluster (North America)** → Region → Global.  
- **Result:** If North America/Cluster row exists with same Client/MSS/PC → match there; else try Region/Global.

### 5.3 Text flow (DFI/FUM)

```
Request: DFI, FUM, Canada, Market, All Clients, Overall, BR_TOTAL, BPCBrand
  → RLSFUMApprovers: match model, type, Entity=Canada, EntityHierarchy=Market, Country, Client, MSS, PC
  → Exact match? YES
  → Return Approvers: patrick.renard@dentsu.com

Request: DFI, FUM, Toronto, Market, All Clients, Overall, BR_TOTAL, BPCBrand
  → No row for Toronto/Market → Traverse Entity only (Country, Client, MSS, PC fixed)
  → Try North America (Cluster) with same dimensions → Return first match or NOT FOUND
```

---

## 6. EMEA (no separate 1-EMEA script in Script_Populate)

EMEA workspace and security types (Orga, Country, Client, CC, MSS) are defined in the app config; RLS table is **RLSEMEAApprovers**. The **logic is the same** as above: exact match on SecurityModelId, SecurityTypeLoVId, and all dimension keys; if no match and Entity is in the model, **traverse Entity only** (Market → Cluster → Region → Global), keeping Country, Client, CC, MSS, SL fixed. No Script_Populate examples are shown here; use the same pattern as AMER/CDI with EMEA-specific dimension values.

---

## 7. Line manager (LM) — all workspaces

**Source:** `0-Global Script.sql` uses `refv.Employees` to set **LMApprover** when inserting PermissionRequests:

```sql
COALESCE(e.EmployeeParentEmail, r.RequestedFor) AS LMApprover
FROM #CTE_PermissionRequests r
LEFT JOIN ( SELECT EmployeeEmail, MIN(EmployeeParentEmail) AS EmployeeParentEmail
            FROM refv.Employees GROUP BY EmployeeEmail ) e
   ON e.EmployeeEmail = r.RequestedFor
```

- **RequestedFor** = employee email (e.g. Aaron.White@dentsu.com).  
- **LMApprover** = manager email from `refv.Employees.EmployeeParentEmail` when the employee exists; otherwise `RequestedFor` as fallback.

So for **any** workspace, LM resolution is: lookup **refv.Employees** by RequestedFor → use **EmployeeParentEmail**; if missing, use RequestedFor.

---

## 8. Summary

| Workspace | Table             | Security types (examples) | Traversal | Fixed dimensions when traversing     |
|-----------|-------------------|---------------------------|-----------|--------------------------------------|
| AMER      | RLSAMERApprovers  | AMER-ORGA, AMER-Client    | Entity only | SL, Client, PC, CC, PA, MSS          |
| CDI       | RLSCDIApprovers   | CDI                       | Entity only | Client, SL (and PA, CC, MSS, PC if in model) |
| GI        | RLSGIApprovers    | GI                        | Entity only | Client, MSS, SL                      |
| WFI       | RLSWFIApprovers   | WFI                       | Entity only | PA                                    |
| DFI       | RLSFUMApprovers   | FUM                       | Entity only | Country, Client, MSS, PC             |
| EMEA      | RLSEMEAApprovers  | Orga, Country, Client, CC, MSS | Entity only | Country, Client, CC, MSS, SL   |

**Rule:** Always **filter** by SecurityModelId + SecurityTypeLoVId + **all** dimension keys. If **no exact match** and the model has **Entity**, **traverse only Entity** (Market → Cluster → Region → Global) and **keep every other dimension unchanged**. Never traverse Client, PA, MSS, etc. (see APPROVER_FINDING_FLOW.md and FDD § Traversing The Approver Tree).
