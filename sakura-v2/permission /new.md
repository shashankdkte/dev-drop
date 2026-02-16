# Permission Request & Approval — Step-by-Step Roadmap

Production-ready, end-to-end implementation for: **(1)** creating permission requests without the wizard (tabular), **(2)** full approval flow (LM → OLS → RLS), **(3)** Approver Role (APR) capabilities.  

**This roadmap lists only work that is not yet done.** It is based on a code audit of DB, Backend, and Frontend.

**References:** [PERMISSION_REQUEST_TABULAR_AND_APPROVAL_CHANGES.md](PERMISSION_REQUEST_TABULAR_AND_APPROVAL_CHANGES.md), [PERMISSION_STATUS_REFERENCE.md](PERMISSION_STATUS_REFERENCE.md), [Capabilities-Per-Role.md](../Capablities/Capabilities-Per-Role.md).

---

## What already exists (do not redo)

| Layer | What exists |
|-------|-------------|
| **DB** | `dbo.PermissionRequests`, `dbo.PermissionHeaders`, `dbo.OLSPermissions`, `dbo.RLSPermissions`, RLS detail tables; `romv.PermissionRequests` and `romv.PermissionHeaders` views (read-only). System-versioning (history) on base tables. |
| **Backend** | `WorkspaceRequestController`: GET `/api/permissions`, GET `/api/permissions/{id}`, GET `/api/workspaces/{workspaceId}/permissions`. `WorkspaceRequestService`: GetRequestsAsync, GetRequestsByWorkspaceAsync, GetRequestDetailsAsync. Entities `PermissionRequest`, `PermissionHeader` mapped to **views** (romv). `PermissionRequestsResponse`, `PermissionHeadersResponse`. Auth: `GET /api/Auth/me` returns email (from token). |
| **Frontend** | `PermissionRequestsListComponent`: list, workspace filter, search, OLS/RLS/Request status filters, sort, pagination, open details modal. `PermissionHeadersModalComponent`: read-only request header + OLS/RLS items table. `PermissionRequestService`: getHeaders(workspaceId?), getRequestDetails(permissionRequestId). `PermissionRequestListItem`, `PermissionHeaderItem` models. `permission-status.constants.ts`: status labels and badge classes. Routes: `wso-console/permission-requests`, data-entry permission-requests (SQL script generator). `backend-endpoints.config.ts`: GET permissions endpoints; placeholder entries for `/approvals/:requestId/approve|reject|revoke` (not implemented in BE). |

**Gap summary:** No write path: no entities for base tables, no POST create, no approve/reject/revoke API, no “pending for me” / “previously given”, no tabular create UI that calls API, no approve/reject buttons in modal, no chain status/history/existing rights/delegates/email deep link.

---

## Phase A — Create request (tabular) and single-step approval

### Step 1 — DB: Expose RequestCode and LMApprover for list (optional but recommended)

**Current:** `romv.PermissionRequests` does not expose `RequestCode`, `LMApprover`, or `RequestReason`. List and responses today only have RequestId, WorkspaceId, RequestedBy, RequestedFor, RequestStatus, OLSStatus, RLSStatus.

**To do:**
- [ ] Alter view `romv.PermissionRequests`: add `PR.RequestCode`, `PR.LMApprover` (and optionally `PR.RequestReason`, `PR.CreatedAt`) to the SELECT and GROUP BY where needed.
- [ ] No new tables in this step.

---

### Step 2 — Backend: Writable entities and DbContext for base tables

**Current:** EF maps only to views; `ApplyReferenceViewsReadonlyRules()` sets romv entities to Unchanged on save. No way to insert/update `dbo.PermissionRequests` or `dbo.PermissionHeaders`.

**To do:**
- [ ] Add entity `PermissionRequestRow` (or similar) mapping to **table** `dbo.PermissionRequests`: Id, RequestCode, RequestedFor, RequestedBy, LMApprover, RequestStatus, RequestReason, WorkspaceId, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy. Map to table, not view.
- [ ] Add entity `PermissionHeaderRow` mapping to **table** `dbo.PermissionHeaders`: Id, PermissionRequestId, PermissionType, ApprovalStatus, Approvers, ApprovedBy, ApprovedAt, ApproveNote, RejectedBy, RejectedAt, RejectNote, RevokedBy, RevokedAt, RevokeNote, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy.
- [ ] Register both in `SakuraDbContext` as `.ToTable(...)` (dbo). Do **not** add them to the romv/ref/refv read-only check so SaveChanges can persist.
- [ ] Optionally add `OLSPermissionRow` and `RLSPermissionRow` for dbo.OLSPermissions and dbo.RLSPermissions if create flow will insert OLS/RLS rows in the same phase.

---

### Step 3 — Backend: Create permission request API

**Current:** No POST for permissions. No create in `IWorkspaceRequestService` / `WorkspaceRequestService`.

**To do:**
- [ ] Add DTOs: `CreatePermissionRequestRequest` (WorkspaceId, RequestedFor, RequestedBy, LMApprover, RequestReason; optional RequestCode; optional OLS/RLS payload if doing full create in one call).
- [ ] Add response DTO: e.g. `CreatePermissionRequestResponse` (Id, RequestCode, RequestStatus).
- [ ] Add `CreatePermissionRequestAsync(CreatePermissionRequestRequest request, string currentUserEmail)` to `IWorkspaceRequestService` and `WorkspaceRequestService`. Logic: resolve/generate RequestCode (or validate uniqueness); insert into `dbo.PermissionRequests` (RequestStatus = 0 PendingLM, CreatedBy/UpdatedBy = currentUserEmail); optionally insert one or two rows into `dbo.PermissionHeaders` (ApprovalStatus 0, Approvers from config or empty); if OLS/RLS payload provided, insert into OLSPermissions/RLSPermissions and RLS*Details. Commit and return created id and RequestCode.
- [ ] Add `POST /api/permissions` (or `POST /api/workspaces/{workspaceId}/permissions`) in `WorkspaceRequestController`; get current user email from `HttpContext.User` (same pattern as AuthController) or inject a small `ICurrentUserService` that reads from HttpContext).
- [ ] Validate: WorkspaceId exists; required fields non-empty; RequestCode unique if supplied. Return 400/409 as appropriate.
- [ ] Add FluentValidation validator for `CreatePermissionRequestRequest` if project uses it elsewhere.

---

### Step 4 — Backend: Approve / Reject / Revoke API (per header)

**Current:** No approve/reject/revoke endpoints. Frontend config has placeholders for `/approvals/:requestId/approve` etc. but backend does not implement them; approval is per **header**, not per request.

**To do:**
- [ ] Add request DTOs: `ApprovePermissionHeaderRequest` (optional Note), `RejectPermissionHeaderRequest` (required Note), `RevokePermissionHeaderRequest` (optional Note).
- [ ] Add methods to `IWorkspaceRequestService`: `ApproveHeaderAsync(int permissionRequestId, int headerId, string? note)`, `RejectHeaderAsync(...)`, `RevokeHeaderAsync(...)`.
- [ ] Implement in service: load request (from view or base) and header row(s); verify workflow (e.g. header is Pending; for OLS/RLS, previous step approved); verify caller is LM (when RequestStatus = PendingLM) or in header’s Approvers (when PendingOLS/PendingRLS); get current user email from HttpContext/ICurrentUserService; update `dbo.PermissionHeaders` (ApprovalStatus, ApprovedBy/At/Note or RejectedBy/At/Note or RevokedBy/At/Note, UpdatedAt/UpdatedBy); recompute `dbo.PermissionRequests.RequestStatus` from headers and update; commit.
- [ ] Add endpoints, e.g. `POST /api/permissions/requests/{permissionRequestId}/headers/{headerId}/approve`, same for reject and revoke, in `WorkspaceRequestController` (or a dedicated PermissionsController). Return 403 if caller not allowed, 400 if invalid state.
- [ ] Add endpoint mappings in frontend `backend-endpoints.config.ts` for these paths (replace or add to existing approval placeholders with the correct path that includes headerId).

---

### Step 5 — Frontend: Tabular create and service wiring

**Current:** Data-entry permission-requests only generates SQL; no API create. `PermissionRequestService` has no create or approval methods.

**To do:**
- [ ] In `permission-request.model.ts`: add `CreatePermissionRequestRequest` and create response type (e.g. `{ id, requestCode, requestStatus }`).
- [ ] In `permission-request.service.ts`: add `createRequest(req: CreatePermissionRequestRequest): Observable<...>` calling POST create endpoint (use existing ApiService and endpoint config).
- [ ] Add `approveHeader(permissionRequestId: number, headerId: number, note?: string)`, `rejectHeader(..., note: string)`, `revokeHeader(..., note?: string)` calling the new backend endpoints. Map 403/400 to user-friendly messages.
- [ ] In `backend-endpoints.config.ts`: add `POST /permissions` (and if used, `/permissions/requests/:permissionRequestId/headers/:headerId/approve`, reject, revoke) with correct BE_Main paths.
- [ ] Build a **tabular create** UI: new route (e.g. `wso-console/permission-requests/create`) or a “New request (table)” action that opens a form/small grid: Workspace (dropdown from existing workspace list), RequestedFor, RequestedBy, LMApprover, RequestReason; optional RequestCode if backend allows. Submit calls `createRequest`; on success show message and navigate or refresh list; on error show validation/409 message.
- [ ] Ensure workspace dropdown reuses existing workspace loading (e.g. from WorkspaceDomainService or existing list).

---

### Step 6 — Frontend: Approve / Reject / Revoke in details modal

**Current:** `PermissionHeadersModalComponent` is read-only; no action buttons. Details already load headers with `id` (header Id).

**To do:**
- [ ] In `permission-headers-modal`: for each header with ApprovalStatus === 1 (Pending), show **Approve** and **Reject** buttons; for approved headers optionally show **Revoke**. Only show if the current user is allowed (prefer backend to return `canApprove`/`canReject` per header; if not, hide buttons for now or derive from workspace/approver list with same rules as backend).
- [ ] On Approve: optional note prompt; call `approveHeader(requestId, header.id, note)`; on success refresh details (and optionally notify parent to refresh list), show toast.
- [ ] On Reject: mandatory reason prompt; call `rejectHeader(...)`; same success handling.
- [ ] On Revoke: optional note; call `revokeHeader(...)`; same success handling.
- [ ] Disable buttons while request in flight; show 403 message if backend returns forbidden.

---

### Step 7 — Backend: “Pending for me” and “Previously given” (CAP-APR-2, CAP-APR-3)

**Current:** List endpoint returns all (or by workspace); no filter by current user as approver.

**To do:**
- [ ] Extend list API: e.g. `GET /api/permissions?pendingFor=me` and `GET /api/permissions?approvedBy=me` (or `actedBy=me`). Query params: optional `workspaceId`, optional `type=LM|OLS|RLS`.
- [ ] In service: get current user email; for `pendingFor=me` filter requests where (LMApprover = user and RequestStatus = 0) or (user in header Approvers and ApprovalStatus = 1 for that header). For `approvedBy=me` filter where ApprovedBy/RejectedBy/RevokedBy = user on any header. Use view for read; filter in memory or add a view/SP that accepts user email if volume is high.
- [ ] Return same list shape as existing GET so frontend can reuse list component.

---

### Step 8 — Frontend: Approver list views (pending / history)

**Current:** Single list with workspace filter and status filters; no “Pending for me” or “Previously given” tabs/filters.

**To do:**
- [ ] Add to permission-requests-list (or a dedicated approver route): a scope selector or tabs: e.g. “All” | “Pending for me” | “Previously given”. When “Pending for me” selected, call GET with `pendingFor=me`; when “Previously given”, call with `approvedBy=me`. Optional: filter by type (LM/OLS/RLS) via query param.
- [ ] Reuse existing table, sort, pagination; only change data source and optional type filter.

---

## Phase B — Full Approver Role (APR)

### Step 9 — Backend: Chain status and request history (CAP-APR-5)

**Current:** GET details returns request + headers; no derived “chain status” or formal history payload.

**To do:**
- [ ] Extend GET `/api/permissions/{id}` response (or add a small DTO) with a **chain status** summary: e.g. LM approved/pending/rejected, OLS approved/pending/…, RLS … (derived from RequestStatus and header ApprovalStatus).
- [ ] Optional: add `GET /api/permissions/{id}/history` that reads from `history.PermissionRequests` and `history.PermissionHeaders` (or audit fields) and returns a timeline. If no separate endpoint, include a short “history” array in details response (e.g. last N events from audit columns).
- [ ] Frontend: in details modal, show **chain status** (e.g. “LM ✓ → OLS Pending → RLS Not started”) and a **History** section (timeline or table) from the new payload or endpoint.

---

### Step 10 — Backend + Frontend: Requester’s existing rights (CAP-APR-6)

**Current:** No API or UI to show a requester’s current OLS/RLS rights in a workspace.

**To do:**
- [ ] Backend: add `GET /api/workspaces/{workspaceId}/users/{email}/existing-rights` or `GET /api/permissions/requester-rights?workspaceId=&requestedFor=` returning current grants for that user in that workspace (query permission tables/views).
- [ ] Frontend: in request details modal, add “View requester’s existing rights” that calls this API and shows OLS/RLS summary (e.g. in a collapsible or second modal).

---

### Step 11 — Backend + Frontend: Batch approve/reject (CAP-APR-4)

**Current:** Only single-header approve/reject.

**To do:**
- [ ] Backend: add `POST /api/permissions/actions/batch` with body `{ actions: [{ permissionRequestId, headerId, action: "approve"|"reject", note? }] }`. Validate each item (caller allowed, state valid); apply in a transaction; return per-item success/failure.
- [ ] Frontend: in list, add multi-select (checkboxes) and “Approve selected” / “Reject selected” (with mandatory reason for reject). Call batch API; refresh list and show summary of successes/failures.

---

### Step 12 — Frontend: Email deep link (CAP-APR-7)

**Current:** No route that accepts a request id from an email link.

**To do:**
- [ ] Add route that supports query param, e.g. `wso-console/permission-requests?requestId=123` or `wso-console/approvals?requestId=123`. On load, if `requestId` is present, open the details modal for that request (or navigate to list and auto-open modal).
- [ ] Document URL shape for email template: `{appBaseUrl}/wso-console/permission-requests?requestId={requestId}` (or approvals route if you add one).

---

### Step 13 — DB + Backend + Frontend: Approver delegates (CAP-APR-8)

**Current:** No delegate table or API; approval check is only against LMApprover or header Approvers.

**To do:**
- [ ] **DB:** Create table e.g. `dbo.ApproverDelegates` (Id, ApproverEmail, DelegateEmail, ValidFrom, ValidTo, WorkspaceId nullable, PermissionType nullable [LM/OLS/RLS], CreatedAt, CreatedBy, UpdatedAt, UpdatedBy). Add index on (ApproverEmail, ValidFrom, ValidTo) for “active delegate” lookups.
- [ ] **Backend:** Add entity for `ApproverDelegates`; add CRUD API e.g. `GET/POST/DELETE /api/approvers/me/delegates`. When resolving “can user approve this request?”, treat user as allowed if they are the LM or in Approvers **or** they are an active delegate for that LM/approver in scope (WorkspaceId/PermissionType optional).
- [ ] **Frontend:** “My delegates” screen: list delegates, add (delegate email, ValidFrom, ValidTo, optional workspace/type), remove. Call the new delegates API.

---

## Phase C — Production hardening (same flow, both wizard and tabular)

### Step 14 — RequestCode and list display

**Current:** RequestCode not in view or list; create API may require it or generate it.

**To do:**
- [ ] If backend generates RequestCode: implement generation (e.g. per-workspace sequence or max+1 with concurrency) and ensure created response returns it. If user-supplied: validate uniqueness and return 409 on duplicate.
- [ ] After Step 1 (view change), add RequestCode (and LMApprover) to `PermissionRequestsResponse` and to frontend list model and table columns.

---

### Step 15 — Validation, errors, and auth

**To do:**
- [ ] Backend: ensure all new endpoints use `[Authorize]` and return 401 when unauthenticated. Approval endpoints return 403 when caller is not LM/approver/delegate.
- [ ] Backend: validate state transitions (e.g. cannot approve already-approved header); return 400 with clear message.
- [ ] Frontend: handle 401 (redirect to login if needed), 403 (show “You are not allowed to approve this request”), 409 (duplicate RequestCode), 400 (show validation message). Disable submit/buttons while loading.

---

### Step 16 — Wizard submission path

**Current:** Wizard (Report Catalogue / Advanced) is described in FDD; if it already submits via an API, that API should be the same POST create from Step 3. If it does not yet submit, wire wizard “Finish” to call `createRequest` (or a richer create that includes OLS/RLS payload) so both wizard and tabular use one backend path.

**To do:**
- [ ] Confirm wizard submit endpoint: either call existing `POST /api/permissions` with full OLS/RLS payload or extend create API to accept wizard payload. No duplicate create logic.

---

## Checklist summary (only what’s missing)

| # | Layer | Task |
|---|--------|------|
| 1 | DB | Add RequestCode, LMApprover (optional: RequestReason, CreatedAt) to romv.PermissionRequests view |
| 2 | BE | Add PermissionRequestRow, PermissionHeaderRow (and optionally OLS/RLS row) entities → dbo tables; register in DbContext |
| 3 | BE | Create permission request API: DTOs, CreatePermissionRequestAsync, POST /api/permissions, current user from HttpContext |
| 4 | BE | Approve/Reject/Revoke per header: DTOs, service methods, POST .../headers/{id}/approve|reject|revoke, auth check |
| 5 | FE | createRequest, approveHeader, rejectHeader, revokeHeader in service; tabular create UI; endpoint config |
| 6 | FE | Approve/Reject/Revoke buttons in permission-headers-modal; note/reason; refresh on success |
| 7 | BE | List filters: pendingFor=me, approvedBy=me (optional workspaceId, type) |
| 8 | FE | “Pending for me” / “Previously given” (and optional type) in list/tabs |
| 9 | BE + FE | Chain status in details response; optional history endpoint; show in modal |
| 10 | BE + FE | Existing rights endpoint; “View requester’s existing rights” in modal |
| 11 | BE + FE | Batch approve/reject endpoint; multi-select and actions in list |
| 12 | FE | Route + query param for email deep link (requestId) |
| 13 | DB + BE + FE | ApproverDelegates table, CRUD API, “My delegates” UI; resolve delegate in approval check |
| 14 | BE + FE | RequestCode generation or validation; show RequestCode (and LMApprover) in list after view change |
| 15 | BE + FE | Auth and validation on all new endpoints; clear 401/403/400/409 handling in UI |
| 16 | FE (+ BE if needed) | Wizard submit uses same create API; no duplicate logic |

This roadmap is the minimal set of steps to deliver end-to-end permission request creation (tabular and, where applicable, wizard) and full approval flow (LM → OLS → RLS) with Approver Role support in a production-ready way.
