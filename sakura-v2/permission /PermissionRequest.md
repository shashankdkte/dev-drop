# Permission Request — Testing Cheat Sheet

A single-page reference for testers. Covers every request variant (OLS-only, RLS-only, OLS+RLS), every role, every allowed/blocked action, and all final states.

---

## 1. Status values (quick lookup)

### Request status (the top-level `RequestStatus`)

| # | Label | Meaning |
|--:|-------|---------|
| 0 | **Pending LM** | Waiting for Line Manager |
| 1 | **Pending OLS** | LM approved; waiting for OLS approver |
| 2 | **Pending RLS** | OLS done (or absent); waiting for RLS approver |
| 3 | **Approved** | Fully approved — access granted |
| 4 | **Rejected** | Rejected by someone in the chain — final |
| 5 | **Revoked** | Was approved, then revoked — final |
| 6 | **Cancelled** | Withdrawn by requester while pending — final |

### Header (per-permission) approval status (`ApprovalStatus`)

| # | Label | Meaning |
|--:|-------|---------|
| 0 | **Not started** | Header exists but LM hasn't approved yet |
| 1 | **Pending** | Awaiting this approver's action |
| 2 | **Approved** | Approved |
| 3 | **Rejected** | Rejected |
| 4 | **Revoked** | Revoked |
| 5 | **Cancelled** | Cancelled |

### Permission type

| # | Label |
|--:|-------|
| 0 | OLS (Object-Level Security) |
| 1 | RLS (Row-Level Security) |

---

## 2. The three request variants

A request can have **one or both** permission types:

| Variant | Headers created | Approval order |
|---------|----------------|----------------|
| **OLS-only** | 1 OLS header (NotStarted) | LM → OLS → Approved |
| **RLS-only** | 1 RLS header (NotStarted) | LM → RLS → Approved |
| **OLS + RLS** | 1 OLS header + 1 RLS header (both NotStarted) | LM → OLS → RLS → Approved |

---

## 3. Lifecycle maps per variant

### 3A. OLS-only

```
Request created
  RequestStatus = 0 (PendingLM)
  OLS header    = 0 (NotStarted)

LM APPROVE ──►  RequestStatus = 1 (PendingOLS)
                OLS header    = 1 (Pending)

  OLS APPROVE ──► RequestStatus = 3 (Approved)
                  OLS header    = 2 (Approved)    ← FINAL (access granted)

  OLS REJECT  ──► RequestStatus = 4 (Rejected)
                  OLS header    = 3 (Rejected)    ← FINAL

LM REJECT  ──►  RequestStatus = 4 (Rejected)
                OLS header    = 3 (Rejected)      ← FINAL

REQUESTER CANCEL (any pending state)
                RequestStatus = 6 (Cancelled)
                OLS header    = 5 (Cancelled)     ← FINAL

REVOKE (any active state: RequestStatus 0–3):
  OLS APPROVER REVOKES ──► OLS header = 4 (Revoked)
                           RequestStatus = 5 (Revoked)   ← FINAL
```

---

### 3B. RLS-only

```
Request created
  RequestStatus = 0 (PendingLM)
  RLS header    = 0 (NotStarted)

LM APPROVE ──►  RequestStatus = 2 (PendingRLS)   ← skips OLS because there is none
                RLS header    = 1 (Pending)

  RLS APPROVE ──► RequestStatus = 3 (Approved)
                  RLS header    = 2 (Approved)    ← FINAL (access granted)

  RLS REJECT  ──► RequestStatus = 4 (Rejected)
                  RLS header    = 3 (Rejected)    ← FINAL

LM REJECT  ──►  RequestStatus = 4 (Rejected)
                RLS header    = 3 (Rejected)      ← FINAL

REQUESTER CANCEL (any pending state)
                RequestStatus = 6 (Cancelled)
                RLS header    = 5 (Cancelled)     ← FINAL

REVOKE (any active state: RequestStatus 0–3):
  RLS APPROVER REVOKES ──► RLS header = 4 (Revoked)
                           RequestStatus = 5 (Revoked)   ← FINAL
```

---

### 3C. OLS + RLS (both)

```
Request created
  RequestStatus = 0 (PendingLM)
  OLS header    = 0 (NotStarted)
  RLS header    = 0 (NotStarted)

LM APPROVE ──►  RequestStatus = 1 (PendingOLS)   ← OLS goes first
                OLS header    = 1 (Pending)
                RLS header    = 0 (NotStarted)     ← still waiting

  OLS APPROVE ──► RequestStatus = 2 (PendingRLS)
                  OLS header    = 2 (Approved)
                  RLS header    = 1 (Pending)       ← now active

    RLS APPROVE ──► RequestStatus = 3 (Approved)
                    OLS header    = 2 (Approved)
                    RLS header    = 2 (Approved)    ← FINAL (access granted)

    RLS REJECT  ──► RequestStatus = 4 (Rejected)
                    OLS header    = 2 (Approved)    ← already approved, stays
                    RLS header    = 3 (Rejected)    ← FINAL

  OLS REJECT  ──► RequestStatus = 4 (Rejected)
                  OLS header    = 3 (Rejected)
                  RLS header    = 3 (Rejected)      ← both marked rejected, FINAL

LM REJECT  ──►  RequestStatus = 4 (Rejected)
                OLS header    = 3 (Rejected)
                RLS header    = 3 (Rejected)        ← both marked rejected, FINAL

REQUESTER CANCEL (any pending state)
                RequestStatus = 6 (Cancelled)
                OLS header    = 5 (Cancelled)
                RLS header    = 5 (Cancelled)       ← FINAL

REVOKE (any active state: RequestStatus 0–3):
  REVOKE OLS  ──► OLS header = 4 (Revoked)
                  RequestStatus stays until ALL non-final headers are revoked
  REVOKE RLS  ──► RLS header = 4 (Revoked)
                  Now ALL headers final ──► RequestStatus = 5 (Revoked)  ← FINAL

  Note: Once RequestStatus = 5, both headers are Revoked.
  Revoking only one OLS or RLS header during a pending state is valid;
  the request becomes Revoked (5) when all remaining headers are also in a final state.
```

---

## 4. Allowed actions table (by role × state)

Legend: ✅ allowed | ❌ blocked | — not applicable to this role

### Requester

| Request Status | Action | Result | Backend validation |
|---------------|--------|--------|--------------------|
| 0 PendingLM | **Cancel** | → Cancelled (6) | ✅ allowed |
| 1 PendingOLS | **Cancel** | → Cancelled (6) | ✅ allowed |
| 2 PendingRLS | **Cancel** | → Cancelled (6) | ✅ allowed |
| 3 Approved | Cancel | ❌ blocked | "Cannot cancel finalized request" |
| 4 Rejected | Cancel | ❌ blocked | "Cannot cancel finalized request" |
| 5 Revoked | Cancel | ❌ blocked | "Cannot cancel finalized request" |
| 6 Cancelled | Cancel | ❌ blocked | "Cannot cancel finalized request" |

---

### Line Manager

| Request Status | Action | Result | Backend validation |
|---------------|--------|--------|--------------------|
| 0 PendingLM | **Approve LM** | → PendingOLS (1) or PendingRLS (2) | ✅ allowed |
| 0 PendingLM | **Reject LM** | → Rejected (4), all headers → Rejected | ✅ allowed |
| 1 PendingOLS | Approve LM | ❌ blocked | "Request is not in LM approval stage" |
| 1 PendingOLS | Reject LM | ❌ blocked | "Request is not in LM approval stage" |
| 2 PendingRLS | Approve LM | ❌ blocked | "Request is not in LM approval stage" |
| 2 PendingRLS | Reject LM | ❌ blocked | "Request is not in LM approval stage" |
| 3/4/5/6 | Any | ❌ blocked | "Request is not in LM approval stage" |

---

### OLS Approver

| Request Status | OLS Header Status | Action | Result | Backend validation |
|---------------|-------------------|--------|--------|--------------------|
| 1 PendingOLS | 1 Pending | **Approve OLS** | OLS→Approved, next: PendingRLS (2) or Approved (3) | ✅ allowed |
| 1 PendingOLS | 1 Pending | **Reject OLS** | OLS→Rejected, Request→Rejected (4) | ✅ allowed |
| 0 PendingLM | 0 NotStarted | **Revoke OLS** | OLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 1 PendingOLS | 1 Pending | **Revoke OLS** | OLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 2 PendingRLS | 2 Approved | **Revoke OLS** | OLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 3 Approved | 2 Approved | **Revoke OLS** | OLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 0 PendingLM | 0 NotStarted | Approve OLS | ❌ blocked | `ValidateStage` fails — not this stage |
| 2 PendingRLS | 2 Approved | Approve / Reject OLS | ❌ blocked | `ValidateStage` fails — not this stage |
| 3 Approved | 2 Approved | Approve / Reject OLS | ❌ blocked | `ValidateStage` fails — not pending |
| 4/5/6 | 3/4/5 | Any | ❌ blocked | Stage validation or status guard |

---

### RLS Approver

| Request Status | RLS Header Status | Action | Result | Backend validation |
|---------------|-------------------|--------|--------|--------------------|
| 2 PendingRLS | 1 Pending | **Approve RLS** | RLS→Approved, Request→Approved (3) | ✅ allowed |
| 2 PendingRLS | 1 Pending | **Reject RLS** | RLS→Rejected, Request→Rejected (4) | ✅ allowed |
| 0 PendingLM | 0 NotStarted | **Revoke RLS** | RLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 1 PendingOLS | 0 NotStarted | **Revoke RLS** | RLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 2 PendingRLS | 1 Pending | **Revoke RLS** | RLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 3 Approved | 2 Approved | **Revoke RLS** | RLS→Revoked; Request→Revoked (5) if all headers final | ✅ allowed |
| 0 PendingLM | 0 NotStarted | Approve RLS | ❌ blocked | `ValidateStage` fails — not this stage |
| 1 PendingOLS | 0 NotStarted | Approve RLS | ❌ blocked | `ValidateStage` fails — not this stage |
| 3 Approved | 2 Approved | Approve / Reject RLS | ❌ blocked | `ValidateStage` fails — not pending |
| 4/5/6 | 3/4/5 | Any | ❌ blocked | Stage validation or status guard |

---

## 5. API endpoints reference

All endpoints: `POST https://localhost:7238/api/PermissionRequest/{id}/{action}`

| Action | Endpoint | Who sends it | Key body fields |
|--------|----------|--------------|-----------------|
| Approve LM | `/{id}/approvelm` | Line Manager | `UpdatedBy`, `ConcurrencyToken` |
| Reject LM | `/{id}/rejectlm` | Line Manager | `UpdatedBy`, `ConcurrencyToken`, `Reason` |
| Approve OLS | `/{id}/approve` | OLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionHeaderId`, `PermissionType: 0` |
| Reject OLS | `/{id}/reject` | OLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionHeaderId`, `PermissionType: 0`, `Reason` |
| Approve RLS | `/{id}/approve` | RLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionHeaderId`, `PermissionType: 1` |
| Reject RLS | `/{id}/reject` | RLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionHeaderId`, `PermissionType: 1`, `Reason` |
| Revoke OLS | `/{id}/revoke` | OLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionType: 0`, `Reason` |
| Revoke RLS | `/{id}/revoke` | RLS Approver | `UpdatedBy`, `ConcurrencyToken`, `PermissionType: 1`, `Reason` |
| Cancel | `/{id}/cancel` | Requester | `UpdatedBy`, `ConcurrencyToken`, `Reason` |

> **ConcurrencyToken rule:** always use the **root request's** `ConcurrencyToken` (from `GET /{id}` response), not the header's token. The backend validates against the root entity for every action.

---

## 6. Test scenarios checklist

### Test group A — OLS-only happy path (all approvals succeed)

| # | Step | Who | Expected request status | Expected OLS status |
|---|------|-----|------------------------|---------------------|
| A1 | Submit OLS-only request | Requester | 0 PendingLM | 0 NotStarted |
| A2 | LM approves | Line Manager | 1 PendingOLS | 1 Pending |
| A3 | OLS approves | OLS Approver | 3 Approved | 2 Approved |
| A4 | OLS approver revokes | OLS Approver | 5 Revoked | 4 Revoked |

---

### Test group B — RLS-only happy path

| # | Step | Who | Expected request status | Expected RLS status |
|---|------|-----|------------------------|---------------------|
| B1 | Submit RLS-only request | Requester | 0 PendingLM | 0 NotStarted |
| B2 | LM approves | Line Manager | 2 PendingRLS | 1 Pending |
| B3 | RLS approves | RLS Approver | 3 Approved | 2 Approved |
| B4 | RLS approver revokes | RLS Approver | 5 Revoked | 4 Revoked |

---

### Test group C — OLS+RLS happy path

| # | Step | Who | Expected request status | Expected OLS status | Expected RLS status |
|---|------|-----|------------------------|---------------------|---------------------|
| C1 | Submit OLS+RLS request | Requester | 0 PendingLM | 0 NotStarted | 0 NotStarted |
| C2 | LM approves | Line Manager | 1 PendingOLS | 1 Pending | 0 NotStarted |
| C3 | OLS approves | OLS Approver | 2 PendingRLS | 2 Approved | 1 Pending |
| C4 | RLS approves | RLS Approver | 3 Approved | 2 Approved | 2 Approved |
| C5 | OLS approver revokes | OLS Approver | 5 Revoked (all headers final) | 4 Revoked | 4 Revoked |

> **Note:** In OLS+RLS, once OLS is revoked the request goes Revoked (5) immediately because both headers are then in a final state (OLS=Revoked, RLS=NotStarted/still pending). If you want to test revoking mid-flow, revoke whichever header your role covers; the request reaches Revoked (5) when all headers are in a final state.

| C6 | (Alternative) RLS approver revokes first | RLS Approver | 5 Revoked | 0/1 NotStarted/Pending | 4 Revoked |

---

### Test group D — LM rejects

| # | Step | Who | Expected request status | Expected OLS/RLS status |
|---|------|-----|------------------------|------------------------|
| D1 | Submit any request | Requester | 0 PendingLM | 0 NotStarted |
| D2 | LM rejects | Line Manager | 4 Rejected | 3 Rejected (all headers) |
| D3 | Try LM approve again | Line Manager | ❌ 400 — "not in LM stage" | unchanged |

---

### Test group E — OLS rejects (OLS+RLS request)

| # | Step | Who | Expected request status | Expected OLS status | Expected RLS status |
|---|------|-----|------------------------|---------------------|---------------------|
| E1 | Submit OLS+RLS request | Requester | 0 PendingLM | 0 NotStarted | 0 NotStarted |
| E2 | LM approves | Line Manager | 1 PendingOLS | 1 Pending | 0 NotStarted |
| E3 | OLS rejects | OLS Approver | 4 Rejected | 3 Rejected | 3 Rejected |
| E4 | Try RLS approve | RLS Approver | ❌ 400 — stage validation fails | unchanged | unchanged |

---

### Test group F — RLS rejects (OLS+RLS request)

| # | Step | Who | Expected request status | Expected OLS status | Expected RLS status |
|---|------|-----|------------------------|---------------------|---------------------|
| F1 | Submit OLS+RLS request | Requester | 0 PendingLM | 0 NotStarted | 0 NotStarted |
| F2 | LM approves | Line Manager | 1 PendingOLS | 1 Pending | 0 NotStarted |
| F3 | OLS approves | OLS Approver | 2 PendingRLS | 2 Approved | 1 Pending |
| F4 | RLS rejects | RLS Approver | 4 Rejected | 2 Approved | 3 Rejected |
| F5 | Try OLS revoke (not Approved) | OLS Approver | ❌ 400 — "Only approved requests can be revoked" | unchanged | unchanged |

---

### Test group G — Requester cancels at each stage

| # | Cancel when | Expected request status | Expected header statuses |
|---|-------------|------------------------|--------------------------|
| G1 | PendingLM | 6 Cancelled | all → 5 Cancelled |
| G2 | PendingOLS | 6 Cancelled | all → 5 Cancelled |
| G3 | PendingRLS | 6 Cancelled | all → 5 Cancelled |
| G4 | Approved | ❌ 400 — "Cannot cancel finalized request" | unchanged |
| G5 | Rejected | ❌ 400 — "Cannot cancel finalized request" | unchanged |
| G6 | Revoked | ❌ 400 — "Cannot cancel finalized request" | unchanged |

---

### Test group H — Wrong-stage actions (expect 400 errors)

| # | Attempt | When | Expected error |
|---|---------|------|----------------|
| H1 | LM approve | Status = 1 PendingOLS | "Request is not in LM approval stage" |
| H2 | LM approve | Status = 3 Approved | "Request is not in LM approval stage" |
| H3 | OLS approve | Status = 0 PendingLM | Stage validation fails |
| H4 | OLS approve | Status = 2 PendingRLS | Stage validation fails |
| H5 | RLS approve | Status = 0 PendingLM | Stage validation fails |
| H6 | RLS approve | Status = 1 PendingOLS | Stage validation fails |
| H7 | Revoke OLS/RLS | Status = 4 Rejected | ❌ "Request cannot be revoked in its current state" |
| H8 | Revoke OLS/RLS | Status = 5 Revoked | ❌ "Request cannot be revoked in its current state" |
| H9 | Revoke OLS/RLS | Status = 6 Cancelled | ❌ "Request cannot be revoked in its current state" |
| H10 | Revoke with blank reason | Any active state | ❌ "Revoke reason is mandatory" |
| H11 | Revoke a header already Revoked/Rejected/Cancelled | Any | ❌ "This permission header is already in a final state" |

---

## 7. What each final status means at a glance

| Final status | Who caused it | Headers end up as | Can anything be done? |
|-------------|---------------|-------------------|-----------------------|
| **3 Approved** | All approvers approved | all → 2 Approved | Revoke (by OLS/RLS approver) |
| **4 Rejected** | LM, OLS, or RLS rejected | all → 3 Rejected | Nothing — submit a new request |
| **5 Revoked** | OLS/RLS approver revoked after approval | all → 4 Revoked | Nothing — submit a new request |
| **6 Cancelled** | Requester cancelled while pending | all → 5 Cancelled | Nothing — submit a new request |
