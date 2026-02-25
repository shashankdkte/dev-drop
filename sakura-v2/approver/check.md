# Approver Resolution — Robustness: False Positives, False Negatives, and Test Examples

**Purpose:** Will the approval-find logic in `logic_fin_Appro.md` work **100% of the time** at the backend/DB level (no false approvers, no missed approvers)?  
**Short answer:** **No** — not unless the backend implements traversal correctly, handles multi-match priority, and uses the right OLS path. This doc lists **when** it can fail and gives **concrete examples** (using Script_Populate data) so you can test robustness.

---

## 1. Definitions

| Term | Meaning | Risk |
|------|--------|------|
| **False positive** | System returns an approver who should **not** approve this request | Wrong person gets approval task |
| **False negative** | System returns **no** approver (or wrong one) when a **valid** approver exists | Request stuck, or wrong approver used |

---

## 2. RLS — When It Can Fail

### 2.1 FALSE NEGATIVE: Backend skips Entity traversal

**Logic doc:** Organisation hierarchy = Market → Cluster → Region → Global. Must try each level until a row matches.

**If backend only does one exact lookup** (e.g. only Market) and does **not** retry at Cluster/Region/Global:

- **Example (Script_Populate 1-AMER):**
  - Request: AMER-ORGA, **Argentina**, **Market**, SL=Overall, Client=empty.
  - DB has: Argentina/Market/Overall (Desiree.Benson@dentsu.com) → **exact match**, OK.
  - Request: AMER-ORGA, **Vancouver**, **Market**, SL=Overall (Vancouver not in 1-AMER as Market).
  - DB has: North America/Cluster/Overall (Desiree.Benson@dentsu.com).
  - **Backend does only Market lookup** → no row → returns **null**.
  - **Correct behaviour:** Try Cluster (e.g. North America) → match → return Desiree.Benson@dentsu.com.
  - **Result:** **False negative** — real approver exists but system says “no approver”.

**How to test:** Use `Test_Approver_Resolution_At_DB.sql` section 5 “Traversal simulation”: run the same RLS lookup with EntityKey/EntityHierarchy = (Canada, Market), then (North America, Cluster), then (Americas, Region). Backend must do these in order and stop at first hit.

---

### 2.2 FALSE NEGATIVE: Wrong SecurityModelId / SecurityTypeLoVId

**Logic doc:** Step 1 filter by SecurityModelId and SecurityTypeLoVId. If backend sends the wrong Id (e.g. from wrong workspace or wrong LoV), no rows match.

- **Example (1-AMER):**
  - Request is for **AMER** workspace but backend sends SecurityTypeLoVId for **CDI** (or wrong SecurityModelId).
  - RLSAMERApprovers has only AMER-Default + AMER-ORGA/AMER-Client rows → filter removes all.
  - **Result:** **False negative** — approver exists for AMER, but null returned.

**How to test:** In `Test_Approver_Resolution_At_DB.sql` section 3a, temporarily use a SecurityModelCode or LoVValue that does not exist in RLSAMERApprovers; expect no row. Then fix to correct workspace/LoV and confirm one row.

---

### 2.3 FALSE POSITIVE / FALSE NEGATIVE: Multiple matching rows (client-specific vs wildcard)

**Logic doc:** “Your logic does NOT prioritize client-specific over wildcard.” So when both a row with ClientKey=Nike and a row with ClientKey=NULL match, “first valid row” wins. If backend uses `TOP (1)` with **no ORDER BY**, which row is returned is non-deterministic.

- **Example (concept from logic_fin_Appro.md CASE 5; you can add similar rows to 1-AMER):**
  - DB rows:
    - LATAM/Cluster, SL=Overall, **ClientKey=NULL** (wildcard), Approvers = general@dentsu.com
    - LATAM/Cluster, SL=Overall, **ClientKey=Nike**, Approvers = nike.approver@dentsu.com
  - Request: LATAM/Cluster, SL=Overall, **Client=Nike**.
  - Both rows pass strict match. If backend returns **general@dentsu.com** → **False negative** (correct approver is nike.approver@dentsu.com). If backend returns **nike.approver@dentsu.com** → correct.
  - If you *intend* “client-specific overrides wildcard” but do not implement it, you can get either a false negative (wrong person) or inconsistent behaviour.

**How to test:** Insert two RLSAMERApprovers rows with same Entity/SL, one ClientKey=NULL and one ClientKey='Nike'. Run resolution for request Client=Nike multiple times; if backend has no deterministic “prefer non-NULL ClientKey” rule, you may see different approvers. Add ORDER BY (e.g. prefer non-NULL ClientKey) and retest.

---

### 2.4 FALSE NEGATIVE: SL strict match — request uses value not in DB

**Logic doc:** Non-Organisation dimensions (e.g. SL) require strict match; no hierarchy. If request has SL not present in any row, no match.

- **Example (1-AMER):**
  - Request: Canada, Market, **SL=NEW_SL**, Client=empty.
  - DB: Canada/Market has only SL in (Overall, CRTV, CXM, MED, FUNC). No NEW_SL.
  - **Result:** No row → null. This is **correct** (no false positive). But if the *intended* behaviour was “treat NEW_SL as Overall” and the backend does not implement that, you get **false negative** (user expects an approver). So “100%” depends on whether “unknown SL = no approver” is desired.

**How to test:** In `Test_Approver_Resolution_At_DB.sql` 3a, set SLKey to a value not in 1-AMER (e.g. 'NEW_SL'). Expect no row. Document that unknown dimension values → no RLS approver unless you add explicit fallback rules.

---

## 3. OLS — When It Can Fail

### 3.1 FALSE POSITIVE / FALSE NEGATIVE: Wrong ApprovalMode or delivery path

**Logic doc:** AppBased → WorkspaceApp.Approvers; AudienceBased → AppAudience.Approvers; Standalone report (SAR) → WorkspaceReport.Approvers; fallback → Workspace.WorkspaceApprover.

- If backend assumes **AppBased** but workspace is **AudienceBased**, it reads WorkspaceApp.Approvers and may return app-level approvers when audience-level approvers should be used (or vice versa).
- **Example:** Workspace has ApprovalMode = AudienceBased; request is for a specific audience. Backend uses App approvers → **False positive** (wrong approver list) or **False negative** (audience approvers not returned).

**How to test:** In `Test_Approver_Resolution_At_DB.sql` run both 2b (by App) and 2c (by Audience) for the same workspace/app with different ApprovalMode assumptions; compare results. Ensure backend reads ApprovalMode and ReportDeliveryMethod from DB and branches accordingly.

---

### 3.2 FALSE NEGATIVE: Empty/NULL Approvers not falling back

**Logic doc:** If no approvers on Report/App/Audience, fallback to Workspace.WorkspaceApprover.

- If backend treats empty string or NULL as “found” and does not fall back, it may return “no approver” when WorkspaceApprover should be used.
- **Example:** WorkspaceReport has Approvers = NULL. Backend returns “no OLS approver”. Workspace has WorkspaceApprover = owner@dentsu.com. **Correct:** return owner@dentsu.com. **Result if no fallback:** False negative.

**How to test:** Set a report’s Approvers to NULL; ensure workspace has WorkspaceApprover. Run OLS resolution; expect WorkspaceApprover. Same for App and Audience with NULL approvers.

---

## 4. LM — When It Can Fail

### 4.1 FALSE NEGATIVE: RequestedFor not in refv.Employees

- Employee not in HR feed or view → no row → no LM. So “no approver” is expected for that user. If policy says “every request must have LM”, that’s a process false negative (missing required approver).

### 4.2 FALSE POSITIVE / FALSE NEGATIVE: Wrong or stale ManagerMapKey

- If ref.Employees has wrong or outdated ManagerMapKey, backend returns wrong LM. **False positive** (wrong person as LM) or **False negative** (real LM not returned if manager was removed).

**How to test:** Use `Test_Approver_Resolution_At_DB.sql` section 1 with an email that does not exist in refv.Employees → expect no row. With an email that exists, confirm EmployeeParentEmail is the intended LM.

---

## 5. Summary Table — Will It Work 100%?

| Scenario | Can cause false positive? | Can cause false negative? | Mitigation (backend/DB) |
|----------|---------------------------|----------------------------|--------------------------|
| RLS: no Entity traversal | No | **Yes** | Implement Market→Cluster→Region→Global; stop at first match. |
| RLS: wrong SecurityModel/SecurityType | No | **Yes** | Resolve Ids from workspace + request; validate before lookup. |
| RLS: multiple matches (client vs wildcard) | **Yes** (wrong person) | **Yes** (right person not chosen) | Define priority (e.g. client-specific first); ORDER BY or equivalent. |
| RLS: unknown SL/dimension value | No | Depends on policy | Document: no match → null; or add explicit fallback rules. |
| OLS: wrong ApprovalMode/path | **Yes** | **Yes** | Read ApprovalMode and ReportDeliveryMethod; branch to correct table. |
| OLS: no fallback to WorkspaceApprover | No | **Yes** | If Report/App/Audience approvers empty/NULL → use WorkspaceApprover. |
| LM: user not in refv.Employees | No | **Yes** | Process: require LM or allow manual override. |
| LM: wrong manager in ref | **Yes** | **Yes** | Keep ref.Employees in sync with HR. |

---

## 6. Suggested Robustness Tests (Script_Populate)

Run these **after** 0-Global and 1-AMER (and other 1-* scripts) so data exists.

1. **RLS exact match (happy path)**  
   Request: AMER-ORGA, Canada, Market, Overall, Client=empty.  
   Expected: One row, Approvers = Desiree.Benson@dentsu.com (per 1-AMER).  
   Use `Test_Approver_Resolution_At_DB.sql` section 3a.

2. **RLS traversal (false negative if missing)**  
   Request: AMER-ORGA, **Argentina**, Market, Overall. Then same request but with Entity = North America, Cluster (simulating “second step” of traversal).  
   Expected: First lookup Argentina/Market → match; if you simulate “no Market row” and try Cluster, North America/Cluster/Overall should match.  
   Use section 5 “Traversal simulation” with different EntityKey/EntityHierarchy.

3. **RLS wrong SecurityType (false negative)**  
   Use 3a with LoVValue that does not exist in RLSAMERApprovers (e.g. wrong workspace type).  
   Expected: No row.

4. **RLS SL mismatch (no match)**  
   Use 3a with SLKey = 'NEW_SL' (not in 1-AMER).  
   Expected: No row.

5. **OLS by Report vs by App**  
   Run 2a (Report) and 2b (App) with same WorkspaceId and appropriate Ids; ensure backend uses the path that matches ApprovalMode and delivery (report vs app).

6. **LM missing user**  
   Use section 1 with RequestedFor = 'nonexistent@dentsu.com'.  
   Expected: No row.

These examples use Script_Populate only as **examples**; adjust SecurityModelCode, LoVValue, and entity/SL/client values to match your DB. Running them helps verify that the application does not produce false positives or false negatives in the cases above.
