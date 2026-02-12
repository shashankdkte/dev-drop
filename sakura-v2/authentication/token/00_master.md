# Sakura — Entra Auth & Roles: Master Roadmap (Token-only, no User table)

**Purpose:** One place to see what is **present**, what you **must create**, what you **must set up**, all **phases**, and **checkpoints** before moving to the next phase.

**Approach:** **Token-only (no User table)** — Identity from token only: **oid** (stable) + **email** (current at request time). **All role data in Sakura DB** (SupportUsers, PlatformAdmins, Workspaces CSV, RLS/OLS approvers). **Email change** is handled by a **separate script** (run when a user’s email changes in Entra); no User table to update. No server-side session store; session = token-based and stateless.

---

## Contents

| § | What it covers |
|---|----------------|
| 1 | **What is present** (infra, DB, code, docs) |
| 2 | **What we have to create** (DB, backend, frontend, email-change script) |
| 3 | **What we have to set up** (Entra, config, env) |
| 4 | **All phases** (overview + links to phase docs) |
| 5 | **Phase gates** (check before moving to next phase) |
| 6 | **Related docs** |

---

## 1. What is present

### 1.1 Azure / Infrastructure (from template)

| Item | Status | Notes |
|------|--------|--------|
| **App Service (Backend)** | Present | `azeuw1dweb01sakura` — .NET 8, Linux, System-assigned identity |
| **App Service (API)** | Present | `DentsuSakuraApi20251129221455` (shared plan) |
| **Static Web App (Frontend)** | Present | `azeuw1dswasakura` — branch `dev`, private endpoint |
| **Server farm** | Present | `azeuw1dasp01sakura` (Basic B2) |
| **Private endpoints / DNS** | Present | For Static Web App |

*Source: `template/template.json`.*

### 1.2 Database (Sakura DB)

| Item | Status | Notes |
|------|--------|--------|
| **dbo.RefreshToken** | Present | Id, Token, **UserId** (NVARCHAR) — store **oid** here; no User table. |
| **dbo.UserRoles** | Present | Role definitions; no user–role assignment table needed for this approach |
| **dbo.Workspaces** | Present | WorkspaceOwner, WorkspaceTechOwner, WorkspaceApprover (CSV emails) |
| **dbo.PermissionRequests, PermissionHeaders** | Present | CreatedBy, WorkspaceId, etc. |
| **dbo.WorkspaceSecurityModels, RLS*Approvers** | Present | Security models and approver lists |
| **dbo.User** | **Not used** | This roadmap does **not** use a User table. |
| **dbo.SupportUsers** | **Not present** | Create — EntraObjectId (oid) only. |
| **dbo.PlatformAdmins** | **Not present** | Create — EntraObjectId (oid) only. |

### 1.3 Documentation

| Doc | Purpose |
|-----|---------|
| **SAKURA_AUTH_FLOW_REFERENCE.md** | Entra vs DB, tables, endpoints, token verification, first-login flow, per user type, session/expiry/logout |
| **SAKURA_ENTRA_ROLES_STEP_BY_STEP_ROADMAP.md** | Full step-by-step roadmap (with User table variant) |

### 1.4 Code (assumed from roadmap)

- Backend: auth pipeline, appsettings (AzureAd / Jwt), possibly `ICurrentUserService` and `/auth/me` in progress.
- Frontend: environment files, MSAL/JWT login, possibly still using `forUser` in some places.

---

## 2. What we have to create

### 2.1 Database

| To create | Purpose |
|-----------|---------|
| **dbo.SupportUsers** | Column **EntraObjectId** (NVARCHAR(255), oid). If current user’s oid here → return all workspaces. |
| **dbo.PlatformAdmins** | Column **EntraObjectId** (NVARCHAR(255), oid). If current user’s oid here → allow create workspace, app settings, event logs. |

**Note:** No User table. **RefreshToken.UserId** continues to store **oid** (string); no FK to User.

### 2.2 Backend

| To create / implement | Purpose |
|------------------------|---------|
| **ICurrentUserService** | Expose **EntraObjectId** (oid), **Email** (from token), **Name** (from token). No DB lookup for identity; read claims only. Scoped; no trust of client `forUser`. |
| **GET /api/Auth/me** | Return current user (entraObjectId, email, name, isSupport, isPlatformAdmin) from token + SupportUsers/PlatformAdmins (by oid). |
| **Workspace list logic** | Use ICurrentUserService only: if Support (oid in SupportUsers) → all workspaces; else GetWorkspacesForUserAsync(**currentUserEmail from token**). Remove trust of query `forUser` for normal users. |
| **Support check** | If EntraObjectId in SupportUsers → allow all workspaces. |
| **Platform Admin check** | If EntraObjectId in PlatformAdmins → allow create workspace, app settings, event logs; else 403. |

### 2.3 Frontend

| To create / change | Purpose |
|--------------------|---------|
| **Call /auth/me after login** | Store backend identity (entraObjectId, email, name, isSupport, isPlatformAdmin) in AuthService. |
| **Remove forUser** | All workspace API calls without `forUser`; backend derives current user from token. |
| **Audit fields** | Use `authService.currentUserValue?.email` (or equivalent) for createdBy / updatedBy / deletedBy. |
| **Guards** | MsalGuard when Entra; authGuard when JWT. |

### 2.4 Email-change script

| To create | Purpose |
|-----------|---------|
| **Separate script** | Run when a user’s email changes in Entra. Input: **old email** and **new email** (or oid + new email). Script updates: Workspaces (WorkspaceOwner, WorkspaceTechOwner, WorkspaceApprover CSV), RLS/OLS approver columns, PermissionRequests/PermissionHeaders CreatedBy/UpdatedBy, and any other columns that store the user’s email. So after the script, the user (logging in with new email in token) still matches their workspaces and approvals. See [Phase 4 — Roles (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_04_ROLES_IN_DB_TOKEN_ONLY.md) and [EMAIL_CHANGE_SCRIPT_TOKEN_ONLY.md](EMAIL_CHANGE_SCRIPT_TOKEN_ONLY.md) for the full list of tables/columns and example script. |

---

## 3. What we have to set up

### 3.1 Entra ID (Azure Portal)

| What to set up | Where | Purpose |
|----------------|--------|---------|
| **App registration(s)** | Entra → App registrations | One per env (Dev, UAT, Prod) or one shared; SPA type. |
| **Redirect URIs** | App → Authentication → SPA | e.g. `http://localhost:4200`, UAT SWA URL, Prod URL. |
| **API permissions** | App → API permissions | openid, profile, User.Read (delegated). Admin consent if required. |
| **Token configuration** | App → Token configuration | Optional claims: email, preferred_username; **oid** is default. |
| **Expose API scope** (optional) | App → Expose an API | e.g. `access_as_user` if backend validates custom audience. |
| **Assign users/groups** | Enterprise application → Users and groups | Who can sign in. |

### 3.2 Backend configuration

| What to set up | Where | Purpose |
|----------------|--------|---------|
| **EnableAzureAuth** | appsettings | true for UAT/Prod; false for local dev (JWT). |
| **AzureAd** | appsettings | Instance, TenantId, **ClientId** (SPA app client ID), optional Audience. |
| **UseAuthentication()** | Startup / Program | Before UseAuthorization(); so Bearer token is validated. |

### 3.3 Frontend configuration

| What to set up | Where | Purpose |
|----------------|--------|---------|
| **apiUrl** | environment.*.ts | Backend base URL per env. |
| **enableAzureAuth** | environment.*.ts | true UAT/Prod; false dev. |
| **azureAd** | environment.*.ts | clientId, authority, redirectUri, postLogoutRedirectUri, scopes. |

---

## 4. All phases (overview)

Do phases **in order**. Do **not** start the next phase until the **phase gate** for the current phase is complete.

| Phase | Name | Goal | Detail doc |
|-------|------|------|------------|
| **1** | Entra foundation | App registration(s), redirect URIs, token claims (oid + email); users can sign in and get a valid token. | [Phase 1 — Entra foundation (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_01_ENTRA_FOUNDATION_TOKEN_ONLY.md) |
| **2** | Backend: token only (no User table) | ICurrentUserService (oid + email from **token**); no User table; /auth/me; workspace list from token; Support/PlatformAdmin from DB (keyed by oid). | [Phase 2 — Backend (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_02_BACKEND_TOKEN_ONLY.md) |
| **3** | Frontend: token only | No forUser; call /auth/me; use current user for workspaces and audit fields; correct guards. | [Phase 3 — Frontend (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_03_FRONTEND_TOKEN_ONLY.md) |
| **4** | Roles in DB + email-change script | All roles in DB (Support, Platform Admin, Workspaces CSV, RLS/OLS); **email change** = run **separate script** to update all email-based columns. | [Phase 4 — Roles + email script (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_04_ROLES_IN_DB_TOKEN_ONLY.md) |
| **5** | Per-environment checklist | Dev, UAT, Prod each configured (Entra, backend config, DB, frontend env). | [Phase 5 — Per environment (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_05_PER_ENVIRONMENT_TOKEN_ONLY.md) |
| **6** | Validation & go-live | Smoke tests, email-change test (run script then verify), final checklist. | [Phase 6 — Validation (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_06_VALIDATION_TOKEN_ONLY.md) |

---

## 5. Phase gates (check before moving to next phase)

Use these **before** starting the next phase. All items must be **Done** for that phase.

### Gate 1 → 2 (after Phase 1)

- [ ] At least one App Registration exists (e.g. UAT).
- [ ] SPA redirect URIs are set and match frontend origin(s).
- [ ] API permissions include openid, profile, User.Read; admin consent granted if required.
- [ ] Token contains **oid** (default) and email/preferred_username if configured.
- [ ] A test user can sign in and receive a token (e.g. via frontend or token endpoint).

### Gate 2 → 3 (after Phase 2)

- [ ] **No User table**; identity from **token only** (oid + email).
- [ ] **ICurrentUserService** exposes **EntraObjectId** (oid), **Email (from token)**, Name (from token).
- [ ] **GET /api/Auth/me** returns current user (entraObjectId, email, name, isSupport, isPlatformAdmin).
- [ ] Workspace list uses ICurrentUserService only (no trust of forUser for normal users); email from token for matching.
- [ ] **SupportUsers** and **PlatformAdmins** tables exist (keyed by EntraObjectId); backend checks them.

### Gate 3 → 4 (after Phase 3)

- [ ] Frontend calls **/auth/me** after login and stores user in AuthService.
- [ ] No **forUser** sent on workspace API calls.
- [ ] Audit fields (createdBy, etc.) use current user from AuthService.
- [ ] Route guards use MsalGuard (Entra) or authGuard (JWT) as appropriate.

### Gate 4 → 5 (after Phase 4)

- [ ] Support: only users in **SupportUsers** (by oid) see all workspaces.
- [ ] Platform Admin: only users in **PlatformAdmins** (by oid) can create workspace / access app settings / event logs.
- [ ] Workspace Owner/TechOwner/Approver: matching uses **email from token** (Workspaces CSV).
- [ ] **Email-change script** created and documented; when run (old email → new email), it updates all relevant tables/columns.

### Gate 5 → 6 (after Phase 5)

- [ ] Dev, UAT, Prod (or your env set) each have: Entra app (or shared), backend config, DB schema (SupportUsers, PlatformAdmins), frontend env.
- [ ] Checklist in Phase 5 doc is ticked for each environment.

### Gate 6 → Go-live (after Phase 6)

- [ ] All Phase 6 smoke tests pass (401 without token; 200 /auth/me; workspace list correct; Support gets all; non-admin gets 403 on admin actions).
- [ ] Email-change test: run script (old email → new email), then re-login with new email → workspace list and approvals still correct.
- [ ] “Nothing missed” checklist in Phase 6 is complete.

---

## 6. Related docs

| Doc | Use when |
|-----|----------|
| **SAKURA_AUTH_FLOW_REFERENCE.md** | Table definitions, endpoints, first-login flow, per user type, session/expiry/logout. |
| **SAKURA_ENTRA_ROADMAP_MASTER.md** | You want the **User table** variant (Approach 3) instead of token-only. |
| **Phase 1–6 _TOKEN_ONLY docs** | Executing a phase with the token-only (no User table) approach. |
| **EMAIL_CHANGE_SCRIPT_TOKEN_ONLY.md** | Tables/columns to update when a user’s email changes; example script and behaviour. |

---

## Quick reference: present vs create vs set up (token-only)

| Category | Present | Create | Set up |
|----------|---------|--------|--------|
| **Infra** | App Service, Static Web App, API (from template) | — | — |
| **DB** | RefreshToken (UserId = oid), UserRoles, Workspaces, RLS/OLS, Permission* | SupportUsers, PlatformAdmins (EntraObjectId only) | — |
| **Script** | — | **Email-change script** (update all email-based columns when user’s email changes) | — |
| **Entra** | — | — | App reg, redirect URIs, permissions, token config, assign users |
| **Backend** | (existing auth pipeline) | ICurrentUserService from token, /auth/me, workspace logic, Support/ADM checks (by oid) | UseAuthentication, appsettings AzureAd/Jwt |
| **Frontend** | (existing login/env) | /auth/me after login, remove forUser, audit from currentUser | environment.*.ts |

You can use this master doc as the single entry point for the **token-only (no User table)** approach; then work through each phase using the linked phase doc and its checkpoint before moving on.
