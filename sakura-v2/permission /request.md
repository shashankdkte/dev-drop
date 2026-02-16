# Permission Request (Tabular) and Approval Flow — Change List

This document lists **DB**, **Backend**, and **Frontend** changes required for:

1. **Creating permission requests without the wizard (tabular way)** — allow users to create permission requests from a table/grid and submit via API instead of the step-by-step wizard or SQL script generation.
2. **Completing the approval flow** — implement **end-to-end approval for each and every permission request** (OLS or RLS): LM → OLS → RLS chain, with approver lists per workspace and per type (LM, OLS, RLS).
3. **Approver Role (APR)** — all Approver capabilities (CAP-APR-1 through CAP-APR-8) are in scope so approvers can view pending/history, act on requests, see details and chain status, view requester’s existing rights, use email deep links, and manage delegates.

**Important:** Readonly views (`romv.PermissionRequests`, `romv.PermissionHeaders`) are **not affected**. All creates and updates target the **actual base tables** (`dbo.PermissionRequests`, `dbo.PermissionHeaders`, etc.). The views remain read-only for listing and details.

The current codebase has:
- **Read-only** permission request APIs (list, list by workspace, get details); EF maps to **views** `romv.PermissionRequests` and `romv.PermissionHeaders`, and `ApplyReferenceViewsReadonlyRules()` prevents any write to `romv` entities.
- **No API** to create a permission request or to perform approve/reject/revoke on a header.
- **Data entry** generates **SQL INSERT** for `dbo.PermissionRequests` only (no headers, no OLS/RLS children); it is for bulk seeding, not for the live request/approval workflow.
- **Details modal** is read-only; no approve/reject buttons.

Status reference: [PERMISSION_STATUS_REFERENCE.md](PERMISSION_STATUS_REFERENCE.md).  
Workflow reference: [03-requester-role.md](FDD/03-requester-role.md) (wizard), approval flow LM → OLS → RLS.  
Approver capabilities: [Capabilities-Per-Role.md](Capablities/Capabilities-Per-Role.md) (CAP-APR-*).

---

## Approver Role (APR) — capability map and end-to-end approval

**Goal:** Every permission request (OLS only, RLS only, or both) goes through a full approval chain. Approvers see the right lists, act at the right step, and have the UX described by the Approver Role capabilities.

**Approval chain per request:**  
**LM (Line Manager)** → **OLS (Object-Level Security)** → **RLS (Row-Level Security)**.  
- A request may have only OLS, only RLS, or both; the chain advances by type (e.g. LM approves request → OLS header pending → OLS approver acts → RLS header pending → RLS approver acts → Approved).

| Capability | Description | Delivered by (DB / Backend / Frontend) |
|------------|-------------|----------------------------------------|
| **CAP-APR-1** | Everything a requester can do | Same as Requester: create request (wizard/tabular), view my requests, etc. No extra change; ensure APR users have requester UX. |
| **CAP-APR-2** | View list of approvals **awaiting their approval**, per WS, per type (OLS, RLS, LM) | **Backend:** `GET /api/permissions?pendingFor=me` (and optional `workspaceId`, `type=LM|OLS|RLS`). Filter: LMApprover + RequestStatus=PendingLM, or current user in header Approvers + ApprovalStatus=Pending. **Frontend:** Approver list view with filters by workspace and type (LM/OLS/RLS); show only “pending for me”. **DB:** Support filtering by LMApprover, Approvers (and optionally delegate — see CAP-APR-8). |
| **CAP-APR-3** | View list of approvals **previously given**, per WS, per type (OLS, RLS, LM) | **Backend:** Same list endpoint with filter e.g. `approvedBy=me` or `actedBy=me`: requests/headers where ApprovedBy/RejectedBy/RevokedBy = current user (or delegate). **Frontend:** “History” or “Previously approved” tab/list with same WS and type filters. **DB:** Existing columns ApprovedBy, RejectedBy, RevokedBy (and history tables if needed for full history). |
| **CAP-APR-4** | Approve/reject **single/multiple** requests at once, with reason if necessary | **Backend:** Single: existing `POST .../headers/{headerId}/approve` and `/reject` (with note). **Batch:** `POST /api/permissions/actions/batch` with body `{ actions: [{ permissionRequestId, headerId, action: "approve"|"reject", note? }] }`; backend runs in transaction, returns per-item success/failure. **Frontend:** Per-request Approve/Reject in details modal; multi-select in list + “Approve selected” / “Reject selected” calling batch API with mandatory reason for reject. **DB:** No change; same PermissionHeaders updates. |
| **CAP-APR-5** | View details of a request, **history** of the request, and **current approval state (Chain Status)** | **Backend:** `GET /api/permissions/{id}` returns request + headers (already exists). Extend with: (a) **Chain status** — derived from RequestStatus + OLSStatus + RLSStatus (e.g. “Pending OLS”, “Pending RLS”, “Approved”); (b) **History** — from `history.PermissionRequests` / `history.PermissionHeaders` or audit fields (CreatedAt, ApprovedAt, RejectedAt, etc.). Optional: `GET /api/permissions/{id}/history`. **Frontend:** Details modal shows headers, OLS/RLS info, and a **chain status** (e.g. LM ✓ → OLS pending → RLS not started); add **History** section (timeline or table). **DB:** System-versioned history tables already exist; optional view for “request history” if needed. |
| **CAP-APR-6** | View **Existing Rights** of the user who created the request, within the selected Workspace | **Backend:** New endpoint e.g. `GET /api/workspaces/{workspaceId}/users/{email}/existing-rights` or `GET /api/permissions/requester-rights?workspaceId=&requestedFor=` returning current OLS/RLS grants for that user in that workspace (from PermissionRequests/PermissionHeaders + OLSPermissions/RLSPermissions and details). **Frontend:** In request details modal, “View requester’s existing rights” link/section that calls this API and shows OLS/RLS summary. **DB:** Read from existing permission tables/views; possibly a dedicated view for “user’s current access per workspace”. |
| **CAP-APR-7** | Click on **email** and land in Sakura for approvals | **Backend:** Support deep-link URL e.g. `/approvals?requestId=123` or `/approvals?pendingFor=me`. Optional: query param for requestId so the app opens the right request/details. **Frontend:** Route that accepts `requestId` (and optionally `pendingFor=me`); email template uses URL like `{baseUrl}/approvals?requestId={requestId}`. User clicks → lands on approval list or directly on that request’s details. **DB:** None. |
| **CAP-APR-8** | Define **forward-looking, time-restricted Delegates** for themselves | **Backend:** New entity and API: e.g. `ApproverDelegate` (ApproverEmail, DelegateEmail, ValidFrom, ValidTo, WorkspaceId?, PermissionType? LM|OLS|RLS). `POST/GET/DELETE /api/approvers/me/delegates`. When resolving “can this user approve?” check approver list **or** active delegate. **Frontend:** “My delegates” screen: add/edit/remove delegates with date range (and optional workspace/type scope). **DB:** New table e.g. `dbo.ApproverDelegates` (ApproverEmail, DelegateEmail, ValidFrom, ValidTo, WorkspaceId nullable, PermissionType nullable, audit). |

Implementing the changes in sections 1–4 below delivers the above so that **every permission request (OLS or RLS) has end-to-end approval** with the full Approver Role in place.

---

## 1. Database changes

### 1.1 Base approval flow — no new tables required

Existing tables are sufficient for request creation and LM/OLS/RLS approval:

- **dbo.PermissionRequests** — request-level (RequestCode, RequestedFor, RequestedBy, LMApprover, RequestStatus, RequestReason, WorkspaceId, audit, system-versioning).
- **dbo.PermissionHeaders** — one or two rows per request (PermissionType 0=OLS, 1=RLS); ApprovalStatus, Approvers, ApprovedBy/At/Note, RejectedBy/At/Note, RevokedBy/At/Note, audit.
- **dbo.OLSPermissions** — one row per OLS header (PermissionHeaderId, OLSItemType, OLSItemId).
- **dbo.RLSPermissions** — one row per RLS header (PermissionHeaderId, SecurityModelId, SecurityTypeLoVId).
- **dbo.RLSPermission*Details** (AMER, EMEA, CDI, GI, FUM, WFI) — dimension details per RLS permission.

**CAP-APR-8 (Delegates):** To support approver delegates (forward-looking, time-restricted), add a new table, e.g. **dbo.ApproverDelegates** (ApproverEmail, DelegateEmail, ValidFrom, ValidTo, WorkspaceId nullable, PermissionType nullable [LM/OLS/RLS], CreatedAt, CreatedBy, UpdatedAt, UpdatedBy). Backend then resolves “current user can approve” as: user is in Approvers/LMApprover **or** user is an active delegate for that approver in that scope.

### 1.2 Optional: RequestCode generation

- **Current:** RequestCode is application-supplied (e.g. from scripts: `REQCD10001`). Unique constraint: `UK_PermissionRequests_RequestCode`.
- **Option A (recommended for tabular):** Backend generates RequestCode (e.g. sequence or `REQ{WorkspaceCode}{Sequence}`). Then:
  - Add a **sequence or small helper table** per workspace for the numeric part, e.g. `dbo.PermissionRequestSequences (WorkspaceId, NextValue)` or use `IDENTITY` + a computed/formatted column if acceptable.
  - Or generate in app: `SELECT MAX(CAST(SUBSTRING(RequestCode, LEN(Prefix)+1, 100) AS INT)) FROM dbo.PermissionRequests WHERE WorkspaceId = @w AND RequestCode LIKE @prefix + '%'` then `Prefix + (NextNum+1)` (with concurrency handling).
- **Option B:** Keep RequestCode user-entered in the tabular UI; validate uniqueness in backend and return 409 if duplicate.
- **No DB change required for Option B.** For Option A, add a table or sequence object and, if needed, a stored procedure or backend logic to reserve the next value within a transaction.

### 1.3 Indexes (optional, for approval workload)

- **dbo.PermissionHeaders:** Index on `(PermissionRequestId, PermissionType)` (likely already covered by unique constraint).
- **Approver lookups:** If “pending for me” is filtered by approver email in `Approvers` (comma-separated), consider:
  - Persisted computed column or index that supports `WHERE Approvers LIKE '%' + @email + '%'` (or normalize to an Approver junction table later for proper indexing).
- **Status filtering:** Index on `(RequestStatus, WorkspaceId)` and on `(ApprovalStatus, PermissionType)` on PermissionHeaders if approval list queries become heavy.

### 1.4 RLS / security (enterprise)

- RLS policies (if used) on `dbo.PermissionRequests` / `dbo.PermissionHeaders` so that:
  - Requesters see only their requests (e.g. `RequestedBy = current_user_email()` or `CreatedBy = ...`).
  - Approvers see only requests where they are in `Approvers` or where their role (LM/OLS/RLS) is current.
- Ensure any new stored procedures or sequences respect the same security context.

### 1.5 Summary table

| Change | Type | Purpose |
|--------|------|--------|
| RequestCode generation | Optional: new sequence/table or app logic | Auto-generate unique RequestCode for tabular create |
| Indexes on PermissionRequests / PermissionHeaders | Optional | Performance for approval and “my requests” lists |
| RLS / security on permission tables | Optional but recommended | Row-level security for multi-tenant/approver filtering |

---

## 2. Backend changes

### 2.1 Entities for writable tables (required)

EF currently maps only to **views** (`romv.PermissionRequests`, `romv.PermissionHeaders`). Those views stay **read-only** and are never written to. To create or update requests and headers you add **new entities** that map to the **actual base tables** (`dbo.PermissionRequests`, `dbo.PermissionHeaders`, etc.).

- **Add entity:** `PermissionRequestRow` (or `PermissionRequestBase`) mapping to **dbo.PermissionRequests** with columns: Id, RequestCode, RequestedFor, RequestedBy, LMApprover, RequestStatus, RequestReason, WorkspaceId, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy. (ValidFrom/ValidTo if you map system-versioning; otherwise omit for inserts.)
- **Add entity:** `PermissionHeaderRow` (or `PermissionHeaderBase`) mapping to **dbo.PermissionHeaders** with: Id, PermissionRequestId, PermissionType, ApprovalStatus, Approvers, ApprovedBy, ApprovedAt, ApproveNote, RejectedBy, RejectedAt, RejectNote, RevokedBy, RevokedAt, RevokeNote, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy (and ValidFrom/ValidTo if needed).
- **Add entity:** `OLSPermissionRow` mapping to **dbo.OLSPermissions** (PermissionHeaderId, OLSItemType, OLSItemId, audit).
- **Add entity:** `RLSPermissionRow` mapping to **dbo.RLSPermissions** (PermissionHeaderId, SecurityModelId, SecurityTypeLoVId, audit).
- Map these in **SakuraDbContext** to **tables** (not views), and do **not** include them in the romv/ref/refv read-only rule so that SaveChanges can persist them.

This keeps the existing view-based entities for **read** (list/detail) and uses the new entities only for **create/update**.

### 2.2 Request DTOs and API (create request — tabular)

- **Request DTO:** e.g. `CreatePermissionRequestRequest` with: WorkspaceId, RequestedFor, RequestedBy, LMApprover, RequestReason, and either:
  - **Option 1 (minimal tabular):** Only request-level fields; backend creates one PermissionRequest and optionally one or two PermissionHeaders (OLS/RLS) with default ApprovalStatus = 0 (Not started), Approvers from workspace/approver resolution (or empty), and no OLS/RLS child rows until a later “edit” or “define OLS/RLS” step.
  - **Option 2 (tabular with OLS/RLS in one call):** Same plus OLS payload (e.g. reportId or audienceId, OLSItemType) and/or RLS payload (SecurityModelId, SecurityTypeLoVId, dimension keys for the correct RLSPermission*Details table). Backend creates PermissionRequest, PermissionHeaders, OLSPermissions or RLSPermissions, and RLS*Details in one transaction.
- **Response DTO:** Return created request (e.g. Id, RequestCode, RequestStatus) and optionally header ids.
- **Endpoint:** `POST /api/permissions` or `POST /api/workspaces/{workspaceId}/permissions` with body `CreatePermissionRequestRequest`. Authorization: only authenticated users (and optionally restrict to workspace requester/approver roles).
- **Service:** New method e.g. `CreatePermissionRequestAsync(CreatePermissionRequestRequest, currentUserEmail)`. Logic:
  1. Resolve RequestCode (generate or validate uniqueness).
  2. Open transaction (UnitOfWork/DbContext).
  3. Insert **dbo.PermissionRequests** (using PermissionRequestRow entity): RequestStatus = 0 (PendingLM), CreatedBy/UpdatedBy = currentUserEmail, timestamps.
  4. If OLS/RLS payload present: insert **dbo.PermissionHeaders** (PermissionRequestId, PermissionType, ApprovalStatus = 0 or 1, Approvers from workspace config or approver service), then insert OLSPermissions or RLSPermissions and RLS*Details as needed.
  5. If no OLS/RLS in payload: optionally insert one or two placeholder headers (e.g. OLS and RLS both “Not started”) so the request appears in the list and can be completed later.
  6. Commit; return created id and RequestCode.
- **Validation:** WorkspaceId exists; RequestedFor/RequestedBy/LMApprover non-empty; RequestCode unique if user-supplied; OLS/RLS references (report, audience, security model, security type, dimensions) valid.

### 2.3 Approval flow API (complete the flow)

- **Actions:** Approve, Reject, Revoke (and optionally Cancel) on a **PermissionHeader** (OLS or RLS) or on the whole request.
- **Request DTOs:** e.g. `ApprovePermissionHeaderRequest` (Note), `RejectPermissionHeaderRequest` (Reason/Note), `RevokePermissionHeaderRequest` (Note).
- **Endpoints (per header):**
  - `POST /api/permissions/requests/{permissionRequestId}/headers/{headerId}/approve`
  - `POST /api/permissions/requests/{permissionRequestId}/headers/{headerId}/reject`
  - `POST /api/permissions/requests/{permissionRequestId}/headers/{headerId}/revoke`
- **Or** a single action endpoint: `POST /api/permissions/requests/{permissionRequestId}/headers/{headerId}/action` with body `{ "action": "approve" | "reject" | "revoke", "note": "..." }`.
- **Authorization:** Caller must be the LM (for LM step), or in Approvers for that header (OLS/RLS). Backend must resolve current user (e.g. `ICurrentUserService.Email`) and check:
  - For RequestStatus = 0 (PendingLM): only LMApprover can approve/reject (and only on the request or on the first logical step).
  - For PendingOLS: only OLS header’s Approvers.
  - For PendingRLS: only RLS header’s Approvers.
- **Service methods:** e.g. `ApproveHeaderAsync(permissionRequestId, headerId, note)`, `RejectHeaderAsync(...)`, `RevokeHeaderAsync(...)`. Each method:
  1. Load PermissionRequest (from view or base table) and the PermissionHeader row(s) for that request.
  2. Verify workflow state (e.g. this header is in Pending; previous step already approved if applicable).
  3. Verify caller is allowed (LM vs OLS vs RLS approver).
  4. Update **dbo.PermissionHeaders** (PermissionHeaderRow): set ApprovalStatus (2=Approved, 3=Rejected, 4=Revoked), ApprovedBy/ApprovedAt/ApproveNote or RejectedBy/RejectedAt/RejectNote or RevokedBy/RevokedAt/RevokeNote, UpdatedAt/UpdatedBy.
  5. Recompute **dbo.PermissionRequests.RequestStatus** from the two headers (e.g. both approved → 3 Approved; any rejected → 4 Rejected; else PendingLM/PendingOLS/PendingRLS) and update **dbo.PermissionRequests**.
  6. Optional: emit event or call notification service (email to requester).
  7. Commit.
- **Idempotency / concurrency:** Use optimistic concurrency (e.g. ValidFrom/UpdatedAt or rowversion) if multiple approvers could act; otherwise at least check ApprovalStatus before applying the transition.

### 2.4 Get single request (by id) for edit/approval

- **Existing:** `GET /api/permissions/{permissionRequestId}` returns headers (from view). Ensure this returns the **header Id** (primary key of dbo.PermissionHeaders) so the frontend can call approve/reject by headerId. The current `PermissionHeadersResponse` and view expose `Id` and `PermissionRequestId` — verify they are returned and documented.

### 2.5 Optional: “My requests” and “Pending for me”

- **My requests:** `GET /api/permissions?createdBy=me` or filter by `RequestedBy` / `CreatedBy` = current user. May require extending the existing list endpoint with a query parameter and filtering in the service (view already has RequestedBy; if not, add to view or filter in app).
- **Pending for me:** `GET /api/permissions?pendingFor=me` — requests where current user is LMApprover and RequestStatus = 0, or where current user is in Approvers of a header that is Pending. This may require a new view or a stored procedure that joins and filters by current user email (or a backend filter that loads and filters in memory if volume is low).

### 2.6 Summary table (backend)

| Area | Change | Purpose |
|------|--------|--------|
| Entities | PermissionRequestRow, PermissionHeaderRow, OLSPermissionRow, RLSPermissionRow mapped to dbo tables | Allow inserts/updates; keep existing view entities for read |
| DbContext | Register new entities as tables; exclude from romv read-only rule | Persist creates/updates |
| Create API | POST /api/permissions (or /api/workspaces/{id}/permissions), CreatePermissionRequestRequest, CreatePermissionRequestAsync | Tabular create without wizard |
| Approval API | POST approve/reject/revoke per header (or single action endpoint), with auth and status transition | Complete LM → OLS → RLS flow |
| Service | RequestCode generation or validation; status transition logic; approver resolution | Correct workflow and audit |
| Optional | My requests / Pending for me query params or endpoints | Requester and approver UX |

---

## 3. Frontend changes

### 3.1 Tabular creation (without wizard)

- **Place:** Either a new route/section (e.g. “Create request (table)” under WSO Console or Requests), or an additional mode in the existing permission-requests-list (e.g. “New request” that opens a table/form instead of the wizard).
- **UI:** Table or form with columns/fields: Workspace (dropdown), RequestedFor, RequestedBy, LMApprover, RequestReason; optionally RequestCode if not auto-generated. Optional columns for “OLS” and “RLS” (e.g. report/audience picker, security model/type/dimensions) if you support Option 2 in one shot.
- **Behavior:** User fills one or more rows (if multi-row), then “Submit” sends `POST /api/permissions` (or per workspace) for each row or a batch. Success: show created RequestCode/Id and link to the request; error: show validation or 409 for duplicate RequestCode.
- **Reuse:** Reuse workspace list, user/approver lookups (if any), and validation (email format, required fields) from the existing app. Reuse `PermissionRequestService` by extending it with `createRequest(request: CreatePermissionRequestRequest)` that calls the new POST endpoint.
- **Routing:** e.g. `/wso-console/permission-requests/create` or a tab “Create (table)” next to “List”. Do not remove the wizard; keep both entry points (wizard for guided, table for power users or bulk-like creation).

### 3.2 Permission request list enhancements

- **Columns:** Ensure list shows RequestCode (if not already), Workspace name, RequestedFor, RequestedBy, LMApprover, RequestStatus, OLSStatus, RLSStatus, and optionally CreatedAt. Link to details (existing modal or detail page).
- **Filters:** Already have status filters; add “Pending for me” if backend supports it (filter or dedicated endpoint).
- **Refresh:** After creating from tabular or after approval action, refresh the list or update the row in place.

### 3.3 Approval flow UI (complete in the right place)

- **Where:** The “right place” is where approvers work: either the **permission request list** (row action: Approve/Reject) or the **permission request details modal** (header-level Approve/Reject/Revoke). Prefer the **details modal** so the approver sees full context (OLS/RLS details, requester, notes) before acting.
- **Details modal (permission-headers-modal):**
  - For each header (OLS/RLS) with ApprovalStatus = Pending (1), show an **Approve** and **Reject** button (and optionally **Revoke** for already-approved).
  - Button visibility: only if the current user is allowed (LM for request in PendingLM, or in Approvers for that header). Backend can expose a flag per header, e.g. `canApprove` / `canReject`, or frontend derives from role/approver list (less secure; prefer backend to decide).
  - On Approve: open a small form or prompt for optional Note; submit `POST .../headers/{headerId}/approve` with body `{ note }`; on success close prompt, refresh details, show toast; update list if open.
  - On Reject: prompt for mandatory Reason; submit `POST .../headers/{headerId}/reject` with body `{ note }`; same success handling.
  - On Revoke: similar with note; call `POST .../headers/{headerId}/revoke`.
- **List row actions (optional):** If you want quick approve/reject without opening the modal, add a dropdown or icon on each row that is “pending for me” and call the same approve/reject API for the relevant header (e.g. the one that is Pending and for which the user is approver). This requires the list to expose which header id to act on or to have a single “current” step per request.
- **State and errors:** Disable buttons while request in flight; show validation errors (e.g. note required for reject); on 403, show “You are not allowed to approve this request.”

### 3.4 Request creation from wizard (unchanged)

- Keep the existing wizard (Report Catalogue and Advanced) as is. When the wizard submits, it should call the same `POST /api/permissions` (or a richer endpoint that accepts full OLS/RLS payload) so that both wizard and tabular create go through one backend flow. If the wizard currently does not call an API (e.g. not implemented yet), implementing the create API above will unblock both wizard and tabular.

### 3.5 Models and services (frontend)

- **Models:** Add `CreatePermissionRequestRequest` (and optional `ApprovePermissionHeaderRequest`, etc.) in `permission-request.model.ts` or a dedicated file. Add response type for create (e.g. `{ id, requestCode, requestStatus }`).
- **Service:** In `permission-request.service.ts`: add `createRequest(req: CreatePermissionRequestRequest): Observable<...>`, `approveHeader(permissionRequestId: number, headerId: number, note: string): Observable<...>`, `rejectHeader(permissionRequestId: number, headerId: number, note: string): Observable<...>`, `revokeHeader(permissionRequestId: number, headerId: number, note: string): Observable<...>`. Map to the new backend endpoints and error handling (409, 403, 400).
- **Backend config:** In `backend-endpoints.config.ts` (or equivalent), add the new POST routes so the API base URL and path params are correct.

### 3.6 Summary table (frontend)

| Area | Change | Purpose |
|------|--------|--------|
| Tabular create | New route or mode + form/table + submit to POST /api/permissions | Create request without wizard |
| List | RequestCode column; “Pending for me” filter if backend supports | Better list UX and approver focus |
| Details modal | Approve / Reject / Revoke buttons per header with note/reason; call new APIs; show only when user is allowed | Complete approval flow in the right place |
| Service & models | createRequest, approveHeader, rejectHeader, revokeHeader; DTOs | Wire UI to backend |
| Wizard | Use same create API when wizard submits (if not already) | Single backend path for all creation |

---

## 4. Implementation order (suggested)

**Phase A — End-to-end approval for every request (OLS or RLS)**  
1. **Backend:** Add PermissionRequestRow/PermissionHeaderRow (and OLS/RLS row entities), register in DbContext; implement CreatePermissionRequestAsync and POST create endpoint; RequestCode generation or validation.  
2. **Backend:** Implement approve/reject/revoke service methods and endpoints; authorization (LM vs OLS vs RLS approver).  
3. **Frontend:** Extend permission-request.service with create and approval calls; add DTOs.  
4. **Frontend:** Add tabular create UI (form or table) and wire to create API.  
5. **Frontend:** Add Approve/Reject/Revoke in permission-headers-modal; wire to approval APIs; optional list-row actions.  
6. **Backend + Frontend:** “Pending for me” / “Previously given” (CAP-APR-2, CAP-APR-3): list endpoints with filters by workspace and type (LM/OLS/RLS); approver list views with filters.  

**Phase B — Full Approver Role (APR)**  
7. **CAP-APR-5:** Request details + chain status + history (backend response or dedicated history endpoint; frontend chain status and history in details modal).  
8. **CAP-APR-6:** “Existing rights” of requester in workspace (backend endpoint; “View requester’s existing rights” in details modal).  
9. **CAP-APR-4 (batch):** Batch approve/reject endpoint and multi-select Approve/Reject in list.  
10. **CAP-APR-7:** Email deep link (URL in email template; frontend route with `requestId` query param).  
11. **CAP-APR-8:** Delegates table, API, and “My delegates” UI; backend resolution of approver-or-delegate when checking who can approve.  

This order delivers end-to-end approval for each and every permission request (OLS or RLS) and then layers in the full Approver Role capabilities.
