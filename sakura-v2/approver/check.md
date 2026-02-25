# OLS & RLS Approver Logic — Robustness Issues (False Positives / True Negatives)

This document cross-checks **Sakura_DB** schema and **new_logic/logic_fin_Appro.md** to flag issues that can cause **false positives** (wrong approvers returned) or **true negatives** (no approver when one exists). The logic file was **not** modified; this only points out gaps.

---

## 1. OLS — Issues

### 1.1 **CRITICAL: ReportDeliveryMethod value for SAR is wrong in the logic doc**

| Source | SAR value | AUR value |
|--------|-----------|-----------|
| **Sakura_DB** `dbo.WorkspaceReports` | **1** (comment: "1: SAR - Standalone Reports") | **0** (comment: "0: AUR - Audience Reports") |
| **logic_fin_Appro.md** | **0** (doc says "ReportDeliveryMethod = SAR (0)") | — |

**Impact:**  
If the backend implements the doc literally (SAR = 0), it will treat **AUR** reports as standalone and use `WorkspaceReports.Approvers` for them, and **SAR** reports as audience and look at App/Audience instead.

- **False positive:** Returning report-level approvers for an AUR report (where approvers should come from App/Audience).
- **True negative:** For a SAR report, not using `WorkspaceReports.Approvers` and falling back to Workspace or wrong source.

**Reference:**  
- `Sakura_DB/Dbo/Tables/WorkspaceReports.sql`: `ReportDeliveryMethod INT NOT NULL, /*0: AUR - Audience Reports, 1: SAR - Standalone Reports*/`
- All `Sakura_DB/Share/Views/OLS/*.OLS.sql`: `WR.ReportDeliveryMethod = 1 -- Standalone Report (SAR)`
- `Script_Populate/Test_Approver_Resolution_At_DB.sql`: "ReportDeliveryMethod = 1" for SAR.

**Recommendation:** In logic_fin_Appro.md (or backend), define: **SAR = 1**, **AUR = 0**, and use that consistently.

---

### 1.2 **“If present” for Approvers — NULL vs empty string**

The doc says: use WorkspaceApp / AppAudience / WorkspaceReport approvers “if present”, else fallback to `Workspace.WorkspaceApprover`.

**Schema:**

| Table / level | Column | Nullable | Meaning of “present” |
|---------------|--------|----------|------------------------|
| WorkspaceApps | Approvers | **NULL** | NULL = not present |
| WorkspaceReports | Approvers | **NULL** | NULL = not present |
| AppAudiences | Approvers | **NOT NULL** | Can be empty string `''` |
| Workspaces | WorkspaceApprover | **NOT NULL** | Fallback always has a value |

**Impact:**  
If “present” is implemented only as `IS NOT NULL`:

- **AppAudiences:** A row with `Approvers = ''` would be treated as “present” and return empty approvers → request might be sent to no one or misrouted → **effective true negative** (no valid approver) or wrong behaviour.
- **WorkspaceApps / WorkspaceReports:** NULL is correctly “not present”; empty string is not in schema comment but if ever allowed, same risk.

**Recommendation:** Define “present” as: `Approvers IS NOT NULL AND LTRIM(RTRIM(Approvers)) <> ''` (or equivalent). Document this in the logic so backend and DB tests align.

---

### 1.3 **OLS path ordering and fallback**

The doc order is: Case 1 AppBased → Case 2 AudienceBased → Case 3 Standalone Report → Final Fallback Workspace.

The **actual** decision flow depends on **request type** (Report vs Audience) and, for Report, on **ReportDeliveryMethod** (SAR vs AUR). If the backend does not branch on item type and delivery method first, it could:

- Use App approvers for a SAR report (wrong source).
- Use Report approvers for an AUR report (wrong source).

**Recommendation:** Document explicitly: for OLS item type = Report, first read `WorkspaceReports.ReportDeliveryMethod`; if **1 (SAR)** use `WorkspaceReports.Approvers`; if **0 (AUR)** resolve via App + Audience and ApprovalMode. For item type = Audience, use AppAudiences directly. This avoids false positives (wrong approvers) and true negatives (missing approvers).

---

## 2. RLS — Issues

### 2.1 **Multiple matching rows — non-deterministic choice (wrong approver)**

The doc (CASE 5) states: when both a client-specific row and a wildcard (NULL client) row match, “your logic does NOT prioritize client-specific over wildcard” and “first valid row encountered will be chosen.”

**DB test script:** Uses `SELECT TOP (1) ...` with **no ORDER BY** on RLS queries.

**Impact:**  
SQL Server can return any one of the matching rows. So:

- **False positive in a business sense:** Returning the wildcard approver when a more specific (e.g. client-specific) row exists and should be preferred. The approver is “valid” but not the intended one.
- **True negative:** Less likely from ordering alone, but if the “first” row is chosen by chance and that row has invalid/empty Approvers, you could miss the correct row.

**Recommendation:** Either:
- Define a deterministic order (e.g. prefer non-NULL dimension keys over NULL, with explicit ORDER BY), or
- Document that behaviour is intentionally “any matching row” and accept that client-specific vs wildcard is not guaranteed.

---

### 2.2 **Request dimension NULL not defined**

The doc defines **DB NULL = wildcard**. It does not define what happens when the **request** sends NULL (or missing) for a dimension (e.g. optional Client).

**Current test script pattern:**  
`(a.EntityKey = N'Canada' OR (a.EntityKey IS NULL AND N'Canada' IS NULL))`  
So if the request sends `EntityKey = NULL`, the literal `N'Canada'` is not NULL, and the condition effectively requires `EntityKey = 'Canada'`. A row with `EntityKey = NULL` (wildcard) would not match a request with NULL EntityKey unless the backend sends a concrete value or special handling exists.

**Impact:**  
If the UI/API sometimes sends NULL for optional dimensions:

- **True negative:** Valid wildcard rows (DB NULL) might not match, so no approver found when one exists.

**Recommendation:** Document how request NULL/missing dimensions are mapped: e.g. “request NULL means match only rows where that dimension is NULL (wildcard)” and implement the predicate accordingly (e.g. `(request_val IS NULL AND a.EntityKey IS NULL) OR (request_val IS NOT NULL AND (a.EntityKey = request_val OR a.EntityKey IS NULL))`). Align DB test script with that.

---

### 2.3 **Workspace-specific RLS tables and dimension sets**

Different workspaces use different RLS tables (e.g. RLSAMERApprovers, RLSCDIApprovers, RLSWFIApprovers, RLSGIApprovers, RLSFUMApprovers, RLSEMEAApprovers) and **different dimension columns** (AMER: Entity, SL, Client, PC, CC, PA, MSS; CDI: Entity, Client, SL; WFI: Entity, PA; etc.).

The logic doc is generic (Organisation + “all other dimensions”). If the backend:

- Uses the wrong table for a workspace, or
- Uses the wrong subset of dimensions for that model,

then:

- **True negative:** Correct approver row exists but is never queried.
- **False positive:** Wrong table returns a row that doesn’t really match the intended policy.

**Recommendation:** Keep a mapping (e.g. in docs or config): Workspace/SecurityModel → RLS table and list of dimension columns. Backend and Test_Approver_Resolution_At_DB.sql should both use this so behaviour is consistent and auditable.

---

### 2.4 **Organisation hierarchy order and traversal**

The doc defines order: Market → Cluster → Region → Global (most specific first). Traversal is done in the **backend**; the DB script only does single-level lookups.

If the backend implements a different order or skips a level:

- **False positive:** Could pick a broader-level approver when a more specific one exists.
- **True negative:** Could stop too early and return null when a broader level has a valid row.

**Recommendation:** Document the exact enum or ordinal for EntityHierarchy (e.g. Market=1, Cluster=2, Region=3, Global=4) and that traversal tries levels in that order until a row is found. Ensure backend and any DB-side tests that simulate traversal use the same order.

---

## 3. Summary table

| # | Area | Issue | Risk | Type |
|---|------|--------|------|------|
| 1.1 | OLS | SAR = 0 in doc vs SAR = 1 in DB | Wrong path (report vs app/audience) | FP / TN |
| 1.2 | OLS | “Present” not defined for NULL/empty Approvers | Empty approvers used or fallback skipped | TN / wrong behaviour |
| 1.3 | OLS | Path ordering vs item type + ReportDeliveryMethod | Wrong source of approvers | FP / TN |
| 2.1 | RLS | TOP (1) without ORDER BY, multiple matches | Wrong approver (e.g. wildcard over specific) | FP (business) |
| 2.2 | RLS | Request dimension NULL semantics undefined | Wildcard rows not matched | TN |
| 2.3 | RLS | Workspace → table/dimensions mapping | Wrong table or dimensions queried | TN / FP |
| 2.4 | RLS | Hierarchy order/traversal not aligned | Wrong or missing approver | FP / TN |

**Abbreviations:** FP = false positive (wrong approver or wrong path), TN = true negative (no approver when one exists).

---

## 4. References

- **Logic (unchanged):** `new_logic/logic_fin_Appro.md`
- **DB schema:** `Sakura_DB/Dbo/Tables/` — Workspaces.sql, WorkspaceApps.sql, WorkspaceReports.sql, AppAudiences.sql, RLSAMERApprovers.sql, RLSCDIApprovers.sql, etc.
- **DB test script:** `Script_Populate/Test_Approver_Resolution_At_DB.sql`
- **Authoritative SAR=1:** `Sakura_DB/Dbo/Tables/WorkspaceReports.sql`, `Sakura_DB/Share/Views/OLS/*.OLS.sql`, frontend `add-sar-form.component.ts` (e.g. `reportDeliveryMethod === 1` for SAR)
