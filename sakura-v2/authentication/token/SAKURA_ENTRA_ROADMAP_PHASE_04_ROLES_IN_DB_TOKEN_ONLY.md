# Phase 4 — Roles in DB + email-change script (Token-only, no User table)

**Goal:** One clear place per role type; **all role-based info in Sakura DB**. Identity = **oid + email from token**. **Email change** is handled by a **separate script** that updates all email-based columns (Workspaces, approvers, CreatedBy, etc.); no User table.

**Prerequisite:** Phase 3 complete ([Gate 3 → 4](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md#gate-3--4-after-phase-3)).

**Do not start Phase 5 until the [Check before moving to Phase 5](#check-before-moving-to-phase-5) section is complete.**

---

## Step 4.1 — Where each “role” is maintained (token-only summary)

| Role / Concept | Where (token-only) | Backend how |
|-----------------|--------------------|-------------|
| **Identity** | **Token only** (oid, email, name) | ICurrentUserService reads claims; no User table. |
| **Workspace Owner / Tech Owner** | **dbo.Workspaces** (WorkspaceOwner, WorkspaceTechOwner CSV emails) | GetWorkspacesForUserAsync(**email from token**). |
| **Workspace Approver** | **dbo.Workspaces.WorkspaceApprover** + RLS/OLS approver tables | Match by **email from token**. |
| **Support** | **dbo.SupportUsers** (EntraObjectId = oid) | If EntraObjectId in SupportUsers → return all workspaces. |
| **Platform Administrator** | **dbo.PlatformAdmins** (EntraObjectId = oid) | If EntraObjectId in PlatformAdmins → allow create workspace, app settings, event logs. |
| **Requester** | No store | Any authenticated user (has token). |
| **Approver (per workspace/report)** | **dbo** RLS/OLS approver tables | Backend matches by **email from token**. |

---

## Step 4.2 — Email change handling: separate script (no User table)

When a user’s email changes in Entra, the token will have **same oid**, **new email**. All DB columns that store **email** (for matching that user) must be updated so the user still sees their workspaces and approvals. There is **no User table** to update; you run a **separate script** (e.g. SQL or a small backend job) whenever an email change is reported.

### Inputs to the script

- **Old email** (the email that was previously in the token / stored in DB).
- **New email** (the user’s new email in Entra).

Optional: **oid** (Entra Object ID) if you want to double-check identity.

### Tables and columns the script must update

Run the script **when** a user’s email has changed in Entra. It should replace **old email** with **new email** in every place that stores the user’s email for matching or display. Below is the list to cover.

| Table | Columns to update (replace old email with new email) | Notes |
|-------|--------------------------------------------------------|--------|
| **dbo.Workspaces** | WorkspaceOwner, WorkspaceTechOwner, WorkspaceApprover | CSV columns; replace the old email string with new email in each cell that contains it. |
| **dbo.PermissionRequests** | CreatedBy, UpdatedBy, RequestedBy, RequestedFor, LMApprover (if these store the user’s email) | Replace old → new where applicable. |
| **dbo.PermissionHeaders** | CreatedBy, UpdatedBy, Approvers, ApprovedBy | Approvers may be CSV; replace old email with new in that list. |
| **dbo.RLS*Approvers** (e.g. RLSAMERApprovers, RLSCDIApprovers, …) | Approvers (CSV) | Replace old email with new in Approvers column. |
| **Other tables** | Any column that stores the user’s email for “who is owner/approver/requester” | Audit tables, report approvers, etc. — review schema and include in script. |

### Script behaviour (recommended)

1. **Safety:** Run in a transaction; validate row counts or affected rows; rollback if something looks wrong.
2. **Idempotency:** If the script is run twice with same old/new email, it should not duplicate or corrupt (e.g. only replace old email with new).
3. **Documentation:** Keep the script in source control (e.g. `Script_Populate` or `Sakura_DB/Scripts`) and document in this phase or in a dedicated `EMAIL_CHANGE_SCRIPT.md` that:
   - Lists all tables/columns updated.
   - Describes inputs (old email, new email, optional oid).
   - States who runs it (e.g. support/admin) and when (after Entra email change is confirmed).  
|      | See **[EMAIL_CHANGE_SCRIPT_TOKEN_ONLY.md](EMAIL_CHANGE_SCRIPT_TOKEN_ONLY.md)** for the full list of tables/columns and an example script pattern. |

### After the script runs

- User signs in again (or refreshes token); token now has **new email**.
- Backend matches workspace/approvals by **email from token** = new email.
- All updated columns now contain new email, so the user sees the same workspaces and approvals as before.

---

## Step 4.3 — (Optional) Token “groups” claim

Token-only approach uses DB for Support and Platform Admin (by oid), so you do **not** need the **groups** claim in the token.

---

## Step 4.4 — Populate and maintain role tables

| Table | Action |
|-------|--------|
| **SupportUsers** | Insert rows **EntraObjectId** = oid for users who should see all workspaces. Remove row when revoking Support. |
| **PlatformAdmins** | Insert rows **EntraObjectId** = oid for platform admins. Remove row when revoking Admin. |
| **Workspaces** | Keep using WorkspaceOwner, WorkspaceTechOwner, WorkspaceApprover (CSV emails). Backend matches using **email from token**. |
| **RLS/OLS approvers** | Keep approver columns (email). Backend matches by **email from token**. When email changes, run the **email-change script** to update these columns. |

---

## Check before moving to Phase 5

Do **not** start Phase 5 until every item below is done.

- [ ] **Support:** Only users in **SupportUsers** (by EntraObjectId) see all workspaces; everyone else sees only workspaces where **token email** is in Owner/TechOwner/Approver.
- [ ] **Platform Admin:** Only users in **PlatformAdmins** (by EntraObjectId) can create workspace, access app settings, and event logs; others get 403 on those actions.
- [ ] **Workspace Owner/TechOwner/Approver:** Matching uses **email from token**; Workspaces and RLS/OLS approver tables store email; when email changes, script updates them.
- [ ] **Email-change script** is created and documented: lists all tables/columns to update, inputs (old email, new email), and is run when a user’s email changes in Entra.
- [ ] **Verification:** Add/remove a user from SupportUsers or PlatformAdmins (by oid) and confirm workspace list and admin actions behave correctly. Optionally run email-change script in test (old email → new email) and confirm user still sees correct workspaces after re-login.

When all are checked, proceed to [Phase 5 — Per-environment checklist (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_05_PER_ENVIRONMENT_TOKEN_ONLY.md).
