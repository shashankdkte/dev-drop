# Approval Logic Robustness & CDI Test Examples

This document:
1. **Robustness** — Whether the logic in `logic_fin_Appro.md` can produce **false positives** or **true negatives** for OLS and RLS when used with **Sakura DB** (and backend).
2. **Issues** — Gaps and edge cases to fix or document.
3. **CDI realistic examples** — Concrete request + DB state + expected result so you can **test at DB level** and build **schema/populate scripts**. Start with CDI only; same pattern applies to other workspaces.

**Reference:** `logic_fin_Appro.md`, Sakura DB (`Workspaces`, `WorkspaceApps`, `AppAudiences`, `WorkspaceReports`, `RLSCDIApprovers`, etc.), `Script_Populate/Test_Approver_Resolution_At_DB.sql`, `Script_Populate/1-CDI Script.sql`.

---

## 1. Robustness: False Positives & True Negatives

### 1.1 Definitions (for this doc)

| Term | Meaning here |
|------|----------------|
| **False positive** | Resolver returns an approver when it **should not** (e.g. wrong person approved, or no approval should be required). |
| **True negative** | Resolver correctly returns **no approver** (null) when no valid config exists. |

### 1.2 OLS — Will it give false positives or true negatives?

**Summary:**  
- **False positives** are possible if: (1) “present” is not defined (empty string vs NULL), (2) Report vs App vs Audience path is chosen wrongly (e.g. ApprovalMode/ReportDeliveryMethod mismatch), or (3) Workspace fallback is used when a more specific empty approver was intended to mean “no OLS approver”.  
- **True negatives** are correct when no row exists for the requested Report/App/Audience or when approvers are explicitly empty and fallback is also empty.

| Scenario | Risk | Notes |
|----------|------|--------|
| **AppBased, WorkspaceApp.Approvers = NULL or ''** | False positive risk | Doc says “If present → use them.” Backend may treat NULL/empty as “not present” and fall back to Workspace.WorkspaceApprover. If product intent is “this app has no approver = no OLS,” then falling back to workspace is a **false positive** (wrong approver). |
| **AudienceBased, AppAudience.Approvers = NULL or ''** | Same | Same as above for audience. |
| **Standalone report, WorkspaceReports.Approvers = NULL or ''** | Same | Report has no approvers → fallback to Workspace. If intent is “no approver,” that’s a false positive. |
| **Wrong path (e.g. Report requested but backend uses App)** | False positive/negative | If request sends ReportId but backend uses ApprovalMode and looks at App first, it can return App approvers instead of Report (or vice versa). **True negative** if it returns null when it should have returned Report approvers. |
| **ReportDeliveryMethod value mismatch** | Doc error / FP/TN | Doc says “SAR (0)”; in Sakura DB **SAR = 1**, AUR = 0. Using 0 for “standalone” would pick the wrong reports → wrong approvers or null. |
| **Workspace.WorkspaceApprover NULL** | True negative | Correct: no OLS approver when nothing is configured. |

**Conclusion OLS:**  
- **True negatives:** Correct when no config exists and fallback is null.  
- **False positives:** Possible when NULL/empty “approvers” are treated as “not present” and fallback to Workspace is used, or when path (Report vs App vs Audience) or ReportDeliveryMethod is wrong.  
- **Fix:** Define “present” (e.g. `NULLIF(RTRIM(Approvers), '') IS NOT NULL`), align doc with DB (SAR = 1), and enforce path by ApprovalMode + ReportDeliveryMethod.

---

### 1.3 RLS — Will it give false positives or true negatives?

**Summary:**  
- **False positives** are possible when **multiple rows** match (e.g. client-specific + wildcard) and the resolver returns “first” row without deterministic ordering (e.g. client-specific should win but wildcard wins).  
- **True negatives** are correct when SecurityModel/SecurityType filter or strict match on non-Entity dimensions excludes all rows, or when Entity traversal is exhausted.

| Scenario | Risk | Notes |
|----------|------|--------|
| **Multiple rows match (client-specific + ClientKey NULL)** | False positive | Doc (CASE 5): “first valid row” wins; no priority for client-specific. If DB returns wildcard row first, approver can be wrong (**false positive**). |
| **TOP (1) without ORDER BY** | False positive | Test script uses `SELECT TOP (1)`; which row is returned is non-deterministic. Same as above. |
| **Entity traversal order wrong** | False positive | If backend tries Cluster before Market, or Global before Region, it can return a broader approver than intended. |
| **Strict match: request dimension NULL** | Ambiguity | Doc: “DB NULL = wildcard.” If **request** sends NULL for e.g. ClientKey, need to define: match only rows where ClientKey IS NULL, or also rows with any ClientKey. Usually “request NULL” means “any client” so only DB NULL (wildcard) rows match. |
| **SecurityModelId / SecurityTypeLoVId mismatch** | True negative | Correct: no approver when model/type don’t match. |
| **SL/Client mismatch (strict)** | True negative | Correct: no approver when no row matches. |
| **Entity not in hierarchy map** | True negative | e.g. request Spain/Market but parent map has no Spain → EMEA; if map is incomplete, traversal may miss valid parent and return null. |

**Conclusion RLS:**  
- **True negatives:** Correct when filter or strict match or traversal gives no row.  
- **False positives:** Possible when multiple rows match and ordering is not defined (client-specific vs wildcard), or when traversal order is wrong.  
- **Fix:** Define tie-breaker (e.g. prefer client-specific over wildcard via ORDER BY or explicit priority), and document traversal order (Market → Cluster → Region → Global) and entity parent map.

---

## 2. Issues to Fix or Document

| # | Issue | Where | Recommendation |
|---|--------|--------|----------------|
| 1 | **ReportDeliveryMethod:** Doc says “SAR (0)”; DB has **0 = AUR, 1 = SAR** (see `WorkspaceReports.sql`). | logic_fin_Appro.md | Change doc to “SAR (1)” and “AUR (0)”. Use 1 for standalone report OLS. |
| 2 | **“If present” for OLS** not defined (NULL vs empty string). | logic_fin_Appro.md, backend | Define: e.g. “present” = `Approvers IS NOT NULL AND RTRIM(Approvers) <> ''`. Use same rule in backend and in test SQL. |
| 3 | **OLS path order** (Report vs App vs Audience) depends on request type and ApprovalMode/ReportDeliveryMethod. | logic_fin_Appro.md | Document: when request has ReportId and report is SAR → Report first; when App and AppBased → App; when App and AudienceBased → Audience; then fallback Workspace. Align backend. |
| 4 | **RLS: client-specific vs wildcard** — “first row” is non-deterministic. | logic_fin_Appro.md, Test_Approver_Resolution_At_DB.sql | Add rule: when multiple rows match, prefer row with **more specific dimensions** (e.g. ClientKey NOT NULL over NULL). Implement with ORDER BY or equivalent. |
| 5 | **RLS: request Entity NULL** — Doc says “5↔ If not found → NULL / (any)”. | logic_fin_Appro.md | Clarify: if **request** has no Entity, should resolver try “NULL/any” row or return null? CDI test ReqId 10 has EntityKey NULL — document expected behaviour. |
| 6 | **CDI Entity parent map** — Traversal needs Market→Cluster→Region→Global. | Test_Approver_Resolution_CDI.sql (#CDIEntityParent) | Ensure map is complete for all Markets/Clusters used in requests (e.g. Spain→Iberia→EMEA, Iberia→EMEA, Americas→Global, EMEA→Global, APAC→Global). Missing entries cause wrong or null result. |

---

## 3. CDI: How It Works (Short)

- **Workspace:** CDI (`WorkspaceCode = 'CDI'`).
- **RLS:** One security type only (LoV Value = **CDI**). Table **RLSCDIApprovers**; SecurityModelCode **CDI-Default**.
- **Dimensions:** EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy. **Traversal only on Entity** (Market → Cluster → Region → Global); Client and SL are strict match (and NULL = wildcard).
- **OLS:** Report (by ReportCode), App (by AppCode), Audience (by AudienceCode). Fallback: Workspace.WorkspaceApprover.

Data used below is from **1-CDI Script.sql** (RLSCDIApprovers) and **0-Global Script.sql** (Workspaces, WorkspaceApps, AppAudiences, WorkspaceReports) so you can run scripts and compare.

---

## 4. CDI Realistic Examples (for DB Tests & Populate Scripts)

### 4.1 RLS — Exact match (Region)

**Request (as sent by user/backend):**

- Workspace: CDI  
- SecurityModelCode: CDI-Default, SecurityTypeLoVValue: CDI  
- EntityKey: **Americas**, EntityHierarchy: **Region**  
- ClientKey: **All Clients**, ClientHierarchy: **All Clients**  
- SLKey: **Overall**, SLHierarchy: **Default**

**DB state (1-CDI Script):**

- RLSCDIApprovers has row: Americas, Region, All Clients, All Clients, Overall, Default → Approvers = `desiree.benson@dentsu.com`

**Expected result:**  
Return **desiree.benson@dentsu.com**.

**SQL (single-level lookup):**

```sql
SELECT TOP (1) a.Approvers AS RLSApprovers
FROM dbo.RLSCDIApprovers a
INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
WHERE SM.SecurityModelCode = 'CDI-Default'
  AND (a.EntityKey       = N'Americas'   OR (a.EntityKey       IS NULL AND N'Americas'   IS NULL))
  AND (a.EntityHierarchy = N'Region'    OR (a.EntityHierarchy IS NULL AND N'Region'    IS NULL))
  AND (a.ClientKey       = N'All Clients' OR (a.ClientKey     IS NULL AND N'All Clients' IS NULL))
  AND (a.ClientHierarchy = N'All Clients' OR (a.ClientHierarchy IS NULL AND N'All Clients' IS NULL))
  AND (a.SLKey           = N'Overall'   OR (a.SLKey           IS NULL AND N'Overall'   IS NULL))
  AND (a.SLHierarchy     = N'Default'   OR (a.SLHierarchy     IS NULL AND N'Default'   IS NULL));
```

Use this as the first test: run 0-Global and 1-CDI, then run the query; expect one row with `desiree.benson@dentsu.com`.

---

### 4.2 RLS — No exact match; Entity traversal (Spain/Market → EMEA/Region)

**Request:**

- EntityKey: **Spain**, EntityHierarchy: **Market**  
- ClientKey: **All Clients**, ClientHierarchy: **All Clients**  
- SLKey: **Overall**, SLHierarchy: **Default**

**DB state:**

- No row for Spain/Market.  
- RLSCDIApprovers has: EMEA, Region, All Clients, All Clients, Overall, Default → `gianluca.gualtieri@dentsu.com`.

**Traversal (backend):**  
Try Spain/Market → not found. Use entity parent map: Spain/Market → parent EMEA/Region. Try EMEA/Region with same Client/SL → found.

**Expected result:**  
Return **gianluca.gualtieri@dentsu.com**.

**Populate / test:**  
- Ensure **#CDIEntityParent** (or backend equivalent) has: Spain, Market → EMEA, Region.  
- Run exact-match query for EMEA/Region/All Clients/All Clients/Overall/Default; expect `gianluca.gualtieri@dentsu.com`.  
- Backend must implement: for Spain/Market, after no exact match, look up parent and retry with EMEA/Region.

---

### 4.3 RLS — Global fallback

**Request:**

- EntityKey: **Global**, EntityHierarchy: **Global**  
- ClientKey: **All Clients**, ClientHierarchy: **All Clients**  
- SLKey: **Overall**, SLHierarchy: **Default**

**DB state:**

- RLSCDIApprovers: Global, Global, All Clients, All Clients, Overall, Default → `ben.bartl@dentsu.com;stephen.byrne@dentsu.com;nitin.menon@dentsu.com`

**Expected result:**  
Return that semicolon-separated list.

**SQL:** Same pattern as 4.1 with EntityKey = N'Global', EntityHierarchy = N'Global'.

---

### 4.4 RLS — True negative: SL mismatch

**Request:**

- EntityKey: **EMEA**, EntityHierarchy: **Region**  
- ClientKey: **All Clients**, ClientHierarchy: **All Clients**  
- SLKey: **TotalPA**, SLHierarchy: **Default**

**DB state (1-CDI):**

- Only “Overall” SL rows for EMEA/Region/All Clients. No **TotalPA** row.

**Expected result:**  
Return **null** (no RLS approver). Strict match: SL TotalPA ≠ Overall, no SL wildcard row.

**Test:** Run exact-match query for EMEA/Region/All Clients/All Clients/**TotalPA**/Default; expect 0 rows.

---

### 4.5 RLS — Request with Entity NULL (ReqId 10 style)

**Request:**

- EntityKey: **NULL**, EntityHierarchy: **NULL**  
- ClientKey: **All Clients**, ClientHierarchy: **All Clients**  
- SLKey: **Overall**, SLHierarchy: **Default**

**Doc:** “5↔ If not found → NULL / (any)”. So one option is: try row where EntityKey IS NULL and EntityHierarchy IS NULL (if such row exists).

**DB state (1-CDI):**  
No row with EntityKey NULL in RLSCDIApprovers (all rows have Entity + Hierarchy).

**Expected result (recommended):**  
Return **null** unless you add an explicit “Global catch-all” row with EntityKey/EntityHierarchy NULL. Document this in your schema/populate so tests are consistent.

---

### 4.6 OLS — By Report (CDI report, no report approvers → fallback)

**Request:**

- Workspace: CDI  
- Item type: Report  
- ReportCode: **e571df46-5941-4339-b843-a76b6dcbae33** (CDI Client Profitability Report)

**DB state (0-Global):**

- WorkspaceReports: ReportCode = that GUID, Approvers = NULL (or empty), ReportDeliveryMethod = 0 (AUR).  
- If your OLS path for “report” uses **ReportDeliveryMethod = 1 (SAR)** only, this report is **not** standalone → may not use report approvers at all; backend might use App/Audience or Workspace.

**Clarification:**  
- If “report OLS” is only for SAR (ReportDeliveryMethod = 1): then for this report (0) expect **no** report-level approver; fallback to Workspace or to linked App/Audience per your rules.  
- If “report OLS” is also used for AUR reports: then “present” rule applies; NULL/empty → fallback to Workspace.WorkspaceApprover.

**Expected result (for consistency):**  
Define in populate: either (a) set ReportDeliveryMethod = 1 and Approvers = NULL for this report and expect Workspace.WorkspaceApprover, or (b) keep 0 and document that report-level OLS is not used for AUR so approvers come from App/Audience/Workspace. Then add a second report with ReportDeliveryMethod = 1 and Approvers set, and test that that one returns report approvers.

---

### 4.7 OLS — By App (CDI app, AudienceBased)

**Request:**

- Workspace: CDI  
- AppCode: **CDIAPP**  
- ApprovalMode: **1 (AudienceBased)**  
- AudienceCode: **CDIAPP-CDI** (or the audience id/code used in 0-Global)

**DB state (0-Global):**

- WorkspaceApps: CDI, CDIAPP, ApprovalMode = 1, Approvers = `nitin.menon@dentsu.com; pareena.shah@dentsu.com; kevin.desilva@dentsu.com`.  
- AppAudiences: audience for CDIAPP with AudienceCode like CDIAPP-CDI, Approvers = (set in your seed).

**Doc:** AudienceBased → use AppAudience.Approvers if present.

**Expected result:**  
If AppAudiences has Approvers for that audience → return those; else if you fall back to app → return app approvers; else Workspace.WorkspaceApprover. Populate script should set AppAudiences.Approvers for this audience so you get a deterministic result (e.g. one email) and can assert in tests.

---

### 4.8 OLS — By App (AppBased)

**Request:**

- Workspace: CDI  
- AppCode: **CDIAPP**  
- ApprovalMode: **0 (AppBased)**

**DB state:**  
WorkspaceApps.Approvers = `nitin.menon@dentsu.com; pareena.shah@dentsu.com; kevin.desilva@dentsu.com`.

**Expected result:**  
Return that string (App approvers).

**SQL:** Same as in Test_Approver_Resolution_At_DB.sql section 2b, with WorkspaceId = (SELECT Id FROM dbo.Workspaces WHERE WorkspaceCode = 'CDI') and AppId from WorkspaceApps for CDIAPP.

---

## 5. Suggested Order to Test (CDI)

1. **RLS exact (4.1)** — One query, one row. Validates SecurityModel + SecurityType + dimension keys and RLSCDIApprovers data.  
2. **RLS Global (4.3)** — Same pattern, Global/Global.  
3. **RLS true negative (4.4)** — TotalPA for EMEA; expect 0 rows.  
4. **RLS traversal (4.2)** — Implement parent lookup (Spain → EMEA) and run exact match for EMEA/Region; or add a small script that does two steps (exact then parent).  
5. **RLS Entity NULL (4.5)** — Define and document behaviour; add a catch-all row in populate if you want a non-null result.  
6. **OLS App AppBased (4.8)** — One lookup by WorkspaceId + AppId.  
7. **OLS App AudienceBased (4.7)** — Populate audience approvers, then lookup by WorkspaceId + AppId + AudienceId (or AudienceCode).  
8. **OLS Report (4.6)** — Align ReportDeliveryMethod (0 vs 1) and “present” rule; then test one SAR report with approvers and one without (fallback).

From CDI you can replicate the same pattern for AMER, WFI, GI, DFI, EMEA (each with their own RLS table and entity map).

---

## 6. Summary Table (CDI)

| # | Type | Request (key bits) | Expected result | Use for |
|---|------|-------------------|------------------|--------|
| 4.1 | RLS | Americas/Region, All Clients, Overall | desiree.benson@dentsu.com | Exact match test |
| 4.2 | RLS | Spain/Market → traverse to EMEA/Region | gianluca.gualtieri@dentsu.com | Traversal test |
| 4.3 | RLS | Global/Global, All Clients, Overall | ben.bartl@...; stephen.byrne@...; nitin.menon@... | Global fallback |
| 4.4 | RLS | EMEA/Region, All Clients, **TotalPA** | null | True negative (SL mismatch) |
| 4.5 | RLS | Entity NULL, All Clients, Overall | null (or catch-all if you add row) | Edge case |
| 4.6 | OLS | Report (GUID), delivery method aligned | Report approvers or Workspace fallback | Report OLS |
| 4.7 | OLS | App CDIAPP, AudienceBased, audience CDIAPP-CDI | Audience approvers (if set) | Audience OLS |
| 4.8 | OLS | App CDIAPP, AppBased | nitin.menon@...; pareena.shah@...; kevin.desilva@... | App OLS |

Once these pass at DB level (and backend uses the same rules), you can extend populate scripts and tests to every other workspace using the same structure.
