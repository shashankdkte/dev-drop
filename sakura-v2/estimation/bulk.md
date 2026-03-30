# Bulk permission request upload — work required

Structured view of **work packages** mapped to **business requirements**. **Primary actor:** **workspace admin** (or equivalent role) preparing requests on behalf of others — not the general end-user population. For **three delivery tracks** (upload + how LM/OLS/RLS are handled), see **§1c** below. For technical depth see [BULK_PERMISSION_REQUEST_UPLOAD_ROADMAP.md](./BULK_PERMISSION_REQUEST_UPLOAD_ROADMAP.md) (Phase **3b** = LM + existing bulk LM; Phase **3c** = auto-approval by composition + bulk OLS/RLS + workspace admin).

---

## 1. Business requirements (what “done” must satisfy)

| ID | Requirement |
|----|----------------|
| **BR-01** | **Workspace admins** can use a **standard Excel template** to prepare many permission requests (for their workspace scope, as defined by access rules). |
| **BR-02** | The system **validates the file (or batch) first** and reports errors **before** creating requests (no silent bad data). |
| **BR-03** | Validation covers **correct references** (e.g. workspace, client key, service line, catalog/security choices) consistent with how the live wizard works. |
| **BR-04** | Processing is in **batches of up to 20 rows**; the **next batch does not start** until the **workspace admin** explicitly continues. |
| **BR-05** | After each batch commit, the **workspace admin** sees **each row** as **created successfully** or **failed**, with a **clear reason** for failures. |
| **BR-06** | Created requests follow the **same lifecycle and rules** as requests raised through the existing single-request flow (approvals, notifications, audit). |
| **BR-07** | The organisation can **trace** bulk activity (who, when, session, link to created requests); stronger **database job history** is optional but plannable. |
| **BR-08** | The capability is **complete and correct for each workspace/domain** enabled in scope (not a one-size-fits-all that breaks in some regions). |
| **BR-09** | **Default governance:** Bulk-created requests follow the **same LM and approval workflow** as the wizard — **no hidden or undocumented auto-approval**. **Exception:** only where **BR-11** defines an **explicit, auditable policy** (e.g. auto-approve LM or another stage for eligible request shapes). |
| **BR-10** | **LM approval** for these requests is handled in the **same place** in the product as today’s LM workflow (same screens/queues, same rules). **Bulk LM approval already exists** in the product — **keep** it, **verify** it for bulk-uploaded requests, and ensure **per-request** audit (who / when). |

---

## 1b. Separate new requirement — Auto-approval by composition, bulk approval, workspace admin

*This block is **additive**. It does not replace BR-09/BR-10; it adds **new** scope to design, implement, and test.*

| ID | Requirement |
|----|----------------|
| **BR-11** | **New:** Support **policy-driven automatic approval** where the business allows it, **separately evaluated** for each request shape: **OLS-only**, **RLS-only**, and **OLS + RLS**. Each path must be **correctly classified** at create time; auto rules must be **configurable or documented**, **audited** (system or actor recorded per request/header), and must **not** silently bypass compliance. |
| **BR-12** | **New:** **Gap check + implementation:** Where auto-approval applies **or does not**, ensure **bulk approval** exists for every **approval stage** that can queue at volume for those shapes (e.g. bulk LM — **already present**; **bulk OLS approver** and/or **bulk RLS approver** as required by the workflow). Extend or add UI/API so **OLS-only**, **RLS-only**, and **OLS+RLS** rows can be cleared in bulk without forcing one-by-one actions when policy allows. |
| **BR-13** | **New:** **Workspace admin** (within **workspace scope** and existing **RBAC**) must be able to access the relevant **bulk approval** actions **where the product grants that role** — same permission checks as for single requests, not an uncontrolled bypass. UI and backend must enforce **who is responsible**; **per-request / per-header** audit remains mandatory. |

---

## 1c. Three delivery options (upload + how approvals happen)

Pick **one** primary track for v1, or phase them: **Track 1 → Track 2 → Track 3**.  
**Baseline** in all cases: bulk **validate/commit** from Excel (batches of 20), workspace-admin scoped, **full audit** on every real approval action (who / when / which request or header).

*Indicative effort assumes one product stream; adjust for number of workspaces and test depth.*

### Track 1 — Upload, then **bulk LM** only; **OLS / RLS one-by-one** in the UI (with audit)

| | |
|--|--|
| **What it is** | After upload, line managers clear the LM step using **existing bulk LM approve**. **OLS approvers** and **RLS approvers** work through the **current single-request UI** only (open each request, approve/reject per header). Every action still writes **normal per-request / per-header** audit (event log, approver fields). |
| **Work** | Deliver **bulk upload** (template, validate API, commit API, FE batch wizard, correlation logging). **Regression-test** bulk LM on upload-created requests. **Document** that OLS/RLS stages are **not** bulk for this track — no new OLS/RLS bulk screens. Optional: export “pending OLS/RLS” list for ops. |
| **Estimation** | **~3–5 weeks** for baseline bulk upload (typical team) **+ ~2–5 days** QA/docs on LM + OLS/RLS manual path. *If §5 “core” line is larger (many domains, hardening), add that delta here.* |
| **Cons** | **Slow** when hundreds of rows need OLS/RLS: many clicks, higher **human error** risk, **approver fatigue**. Support tickets (“why can’t I bulk OLS?”). Still **strongest governance** at OLS/RLS because each request is consciously opened. |

---

### Track 2 — Upload, then **bulk LM** + **bulk OLS** + **bulk RLS** (with audit)

| | |
|--|--|
| **What it is** | Same upload as Track 1. After LM, **OLS** and **RLS** stages can also be cleared **in bulk** (multi-select + approve, or batch API that internally runs **per-request** approve with **per-header** audit — no anonymous “one blob” approval). **Existing bulk LM** stays; **build or extend** bulk flows for OLS and RLS approvers where missing. |
| **Work** | Everything in Track 1 **plus** gap analysis on current product, **FE** multi-select queues / detail actions, **BE** batch or looped approve endpoints, **RBAC** for workspace admin vs dedicated approvers, **tests** for OLS-only, RLS-only, OLS+RLS compositions. Ensure audit line items **per request** (and per header where applicable). |
| **Estimation** | Track 1 **+ ~2–5 weeks** (depends how much bulk OLS/RLS already exists vs net-new UI/API). |
| **Cons** | **Larger build and test** surface; **mistakes scale** if someone bulk-approves the wrong selection — needs **good UX** (filters, confirmation, preview counts). **More RBAC** scenarios to get wrong. Still safer than Track 3 if humans stay in the loop at each stage. |

---

### Track 3 — Upload, then **auto-approved everything** (with audit)

| | |
|--|--|
| **What it is** | After successful upload commit, the system **automatically** advances requests through **LM, OLS, and RLS** (as applicable per row: OLS-only, RLS-only, OLS+RLS) according to a **written policy** (config/feature flag/workspace rules). **Audit must not disappear:** each auto step should log **system/rule** (and optional **on-behalf-of** actor if policy says so), **timestamps**, and **request/header ids** so compliance can answer “why is this approved?” |
| **Work** | Baseline upload **plus** **policy design** (legal/ops), **workflow engine** or guarded transitions reusing the same state machine as manual approve, **idempotency** and **failure** handling (partial auto then stuck requests), **monitoring** and **kill-switch**, **acceptance tests** for all three compositions and domains. **No silent** auto — every transition auditable. |
| **Estimation** | Baseline **+ ~3–8 weeks** (wide range: simple “auto LM only for subset” vs full pipeline + edge cases). |
| **Cons** | **Highest risk:** wrong rule or bug **approves at scale**. **Harder to explain** to auditors without clear rule ids in the log. **Operational surprises** (notifications, downstream systems) if auto skips human review. Requires **strong governance** and often **staged rollout** (flag per workspace). |

---

### Quick comparison

| | Track 1 | Track 2 | Track 3 |
|--|--------|--------|--------|
| **Throughput after LM** | Low (manual OLS/RLS) | High | Highest |
| **Build size** | Smallest | Medium | Largest |
| **Governance / risk** | Lowest automation risk | Medium | Highest |
| **Audit** | Strong (all manual actions attributed) | Strong if per-request audit enforced | Strong only if **system/rule** + ids are logged well |

---

## 2. Work required (by requirement)

| Req ID | Work required | Area | Outcome |
|--------|----------------|------|---------|
| **BR-01** | Define column layout per in-scope domain; produce **downloadable template(s)**; write **short admin guidance** (what each column means, examples). | Product + FE + Docs | Workspace admins know how to fill Excel correctly. |
| **BR-01** | **Upload** flow: **workspace admin** selects file; rows are **read** (browser or server — to be decided) into a structured payload. | FE (+ optional BE) | File becomes checkable data. |
| **BR-02** | **Backend: validate-only API** — accepts a batch (≤20 rows), returns **per-row pass/fail and messages**; **no** permission request records created on validate. | BE | Safe “check first” step. |
| **BR-02** | **Frontend:** show validation results in a **clear grid** (row number, error text); block “create” until business rules are met (per agreed failure policy). | FE | Workspace admin fixes Excel before commit. |
| **BR-03** | **Map** each spreadsheet row to the same internal shape the wizard uses; **reuse or align** validation with existing **single-request create** logic (duplicates, OLS/RLS, dimensions). | BE | Accuracy matches today’s product. |
| **BR-03** | **Resolve** identities and approvers (e.g. “requested for”, line manager) with agreed **timeouts** and **per-row errors** so batches do not hang silently. | BE | Reliable batch behaviour. |
| **BR-04** | **Enforce** maximum **20 rows** per validate/commit call; **UI** shows batch position (e.g. batch 2 of 5) and **manual “continue to next batch”**. | BE + FE | Controlled pacing; no auto-run of all rows. |
| **BR-05** | **Backend: commit API** — after re-check, **create** each valid row via the **existing create path**; return **per-row** success + request reference or error. | BE | Transparent outcomes. |
| **BR-05** | **Frontend:** results screen + optional **download** (e.g. CSV) of outcomes for the session/batch. | FE | Evidence for the workspace admin and support. |
| **BR-06** | No parallel “shadow” workflow: **commit** calls the same services as normal creation (notifications, audit events, statuses). | BE | Consistency with single requests. |
| **BR-09** | **Default:** bulk commit uses **existing** workflow state (no extra auto-LM) unless **BR-11** policy is enabled for that row’s composition. | BE | Matches wizard unless policy says otherwise. |
| **BR-09** | Document for workspace admins: **default** LM behaviour; **when** BR-11 auto-approval applies (OLS-only / RLS-only / OLS+RLS). | Product + Docs | Correct expectations. |
| **BR-10** | **LM UX:** bulk-created requests appear in the **same LM approval** experience as single-created requests. **Regression test** with existing **bulk LM approve**. | FE + QA | Parity with single create + existing bulk LM. |
| **BR-10** | **Audit:** bulk LM (existing feature) must remain **per-request** attribution; verify for uploads. | BE + QA | Accountability unchanged. |
| **BR-11** | **Design** auto-approval matrix: OLS-only, RLS-only, OLS+RLS — which stage auto-approves (LM vs OLS vs RLS), flags/config, audit record shape. | Product + BE | Clear, lawful automation. |
| **BR-11** | **Implement** policy engine or guarded paths so bulk commit + wizard both honour the same rules; **no** divergent logic. | BE | Consistency. |
| **BR-12** | **Inventory:** list bulk approve today (LM, OLS, RLS); identify gaps for **OLS-only**, **RLS-only**, **OLS+RLS** queues. | Product + BE + FE | Known gaps before build. |
| **BR-12** | **Build/extend** missing **bulk approval** (UI multi-select + API batch or looped single approves) with **per-request** event log / header updates. | BE + FE | Volume handling for all stages. |
| **BR-13** | **RBAC:** wire **workspace admin** (and other roles) to bulk approval entry points per **existing** permission model; add automated tests for **deny** outside scope. | BE + FE + QA | Admin can use bulk approve only when allowed. |
| **BR-13** | **UI labelling** so operators see **which role** acted and **which requests** were affected after a bulk action. | FE | Responsibility visible. |
| **BR-07** | **Always:** **session/correlation id** on bulk calls; **application logging** for validate/commit. | BE + Ops | Traceability in standard logs. |
| **BR-07** | **Optional:** database tables for **bulk job + row outcomes** (append-only) if the business needs **reportable upload history** without log mining. | BE + DBA | Stronger operational audit. |
| **BR-08** | **Test pack** per enabled domain (valid file, invalid keys, missing dimensions, duplicates); **sign-off** list by workspace. | QA + BE | Completeness per domain. |
| **—** | **Security and limits:** restrict bulk to **workspace admin** (or named role); enforce **workspace scope** on API; **rate/size limits**; **feature flag** per environment. | BE + IAM + DevOps | Safe rollout. |
| **—** | **Pilot + training:** pilot with selected **workspace admins** / one region first; feedback loop before full enablement. | Product + Change | Controlled adoption. |

---

## 3. Deliverables checklist

- [ ] Official Excel template(s) + **workspace-admin** instructions  
- [ ] Screen(s): upload → validate results → commit batch → outcomes → next batch (manual)  
- [ ] Validate API (no creates) + Commit API (creates via existing flow)  
- [ ] Per-row error and success reporting (UI + API contract)  
- [ ] **LM workflow:** default same as wizard; **BR-11** policy documented if auto-approval applies for OLS-only / RLS-only / OLS+RLS  
- [ ] **LM approval:** same LM area as today; **existing bulk LM approve** verified for bulk-uploaded requests; **per-request** audit  
- [ ] **§1b BR-12:** bulk approval **gap analysis** + delivery for missing OLS/RLS (or combined) bulk steps  
- [ ] **§1b BR-13:** **workspace admin** (scoped) can access bulk approval where RBAC allows; tests for deny outside scope  
- [ ] Correlation/session id and logging for bulk operations  
- [ ] Tests covering each **in-scope** domain  
- [ ] Feature flag and environment configuration  
- [ ] (Optional) Database job/row audit tables + reporting view  

---

## 4. Decisions needed before build (affects work scope)

| Topic | Why it matters |
|--------|----------------|
| **Which workspaces** are in v1 (all vs subset) | Drives template columns and test effort. |
| **If any row in a batch is invalid** — block whole batch vs partial commit | Drives UI messaging and API rules. |
| **Optional DB job history** | Extra build + migration if “yes”; logs-only if “not yet”. |
| **Excel parsed in browser vs on server** | Affects security, template versioning, and FE/BE split. |
| **Who may bulk LM-approve** | Only the assigned line manager vs delegated roles; must match existing permission model and audit rules. |
| **Bulk LM approve: new UI vs extend existing list** | LM bulk already exists — confirm no regression; scope any **new** bulk OLS/RLS UI. |
| **BR-11 auto-approval** | Exact stages (LM vs OLS vs RLS) and eligibility per **OLS-only / RLS-only / OLS+RLS**; legal/ops sign-off. |
| **Workspace admin vs approver roles** | Which bulk actions admins may perform vs dedicated approvers (must match Sakura RBAC). |

---

## 5. Effort summary (indicative)

| Scope | Indicative effort |
|--------|-------------------|
| **§1c Track 1** (upload + bulk LM + manual OLS/RLS) | See **§1c Track 1** row (~**3–5 weeks** baseline + **2–5 days** LM/QA). |
| **§1c Track 2** | Track 1 **+ ~2–5 weeks** (bulk OLS + bulk RLS). |
| **§1c Track 3** | Baseline upload **+ ~3–8 weeks** (full auto-approve pipeline + audit). |
| Core (template, validate + commit APIs, FE batch flow, logging, tests, flag) — *wide-band alternative if many domains / hardening* | ~**18–22** developer-weeks (see team norm; may overlap with “baseline” above). |
| Add optional **DB upload job** tables + server-side Excel | Add roughly **~1–2** weeks. |
| **§1b — BR-11–BR-13** (composition rules + gaps + admin RBAC) | Often **overlaps Track 2/3**; if done standalone add **~2–5** weeks. |
| Verify **existing bulk LM** for bulk-upload paths | **~2–5** days (QA + small fixes if any). |

*Figures are planning guides, not a fixed quote. Prefer **§1c** for stakeholder sizing.*

---

*See also: [BULK_PERMISSION_REQUEST_UPLOAD_ROADMAP.md](./BULK_PERMISSION_REQUEST_UPLOAD_ROADMAP.md)*
