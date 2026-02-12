# Phase 3 — Frontend: use token only (Token-only)

**Goal:** Frontend never sends a fake `forUser`; it sends only the Bearer token; workspace list and audit fields use the current user from the backend. Session is held by the frontend (access token in storage); no server-side session.

**Prerequisite:** Phase 2 complete ([Gate 2 → 3](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md#gate-2--3-after-phase-2)).

**Do not start Phase 4 until the [Check before moving to Phase 4](#check-before-moving-to-phase-4) section is complete.**

*Frontend steps are the same as the User-table variant; backend returns `userId` as `entraObjectId` (string) in token-only approach.*

---

## Step 3.1 — Environment files: correct values per environment

| Where | Frontend: `environment.ts`, `environment.uat.ts`, `environment.production.ts`. |
|-------|-------------------------------------------------------------------------------|
| What | For **each** environment set:  
|      | - `apiUrl` = backend base URL for that env.  
|      | - `enableAzureAuth` = `true` for UAT/Prod, `false` for local dev (if using JWT).  
|      | - `azureAd.clientId` = App Registration **Client ID** for that env.  
|      | - `azureAd.authority` = `https://login.microsoftonline.com/<tenant-id>`.  
|      | - `azureAd.redirectUri` and `postLogoutRedirectUri` = **exact** frontend origin (must match Entra redirect URIs).  
|      | - `azureAd.scopes` = `['User.Read','openid','profile']` or include `api://<client-id>/access_as_user` if backend expects that audience. |
| **Environments** | Dev: localhost, dev client ID. UAT: UAT SWA URL, UAT client ID. Prod: Prod URL, Prod client ID. |

---

## Step 3.2 — After login: call /auth/me and store user

| Where | Frontend: login flow (e.g. component that handles MSAL redirect and `AuthService`). |
|-------|------------------------------------------------------------------------------------|
| What | 1. After MSAL redirect (or after JWT login), get the token and store it (already done).  
|      | 2. **Call GET /auth/me** with the Bearer token.  
|      | 3. Map response to `AuthUser` (userId = entraObjectId string, email, name, role, isSupport, isPlatformAdmin, etc.) and store in **AuthService** (e.g. `setStoredUser`, `currentUserSubject.next`).  
|      | 4. For the rest of the app, “current user” comes from this one source. |

---

## Step 3.3 — Stop sending forUser for workspaces

| Where | Frontend: workspace service (e.g. `workspace-domain.service.ts`) and any call to `/workspaces`. |
|-------|-----------------------------------------------------------------------------------------------|
| What | Remove hardcoded `forUser` (e.g. `forUser: 'sakurahelp@dentsu.com'`) from **all** workspace API calls.  
|      | Call **GET /workspaces?includeDeleted=false** (or true) **without** a `forUser` parameter.  
|      | Backend will use the token to get the current user and return the correct list. |

---

## Step 3.4 — Use current user for audit fields

| Where | Frontend: any place that sets `createdBy`, `updatedBy`, `deletedBy`. |
|-------|---------------------------------------------------------------------|
| What | Replace hardcoded emails (e.g. `'current.user@dentsu.com'`, `'sakurahelp@dentsu.com'`) with `this.authService.currentUserValue?.email ?? ''` (or from `getCurrentUser()`). |

---

## Step 3.5 — Route guards

| Where | Frontend: `app.routes.ts` and guard implementations. |
|-------|-----------------------------------------------------|
| What | Protected routes use **MsalGuard** when `enableAzureAuth` is true, and your **authGuard** (JWT) when false. Unauthenticated users redirect to `/login`. |

---

## Check before moving to Phase 4

Do **not** start Phase 4 until every item below is done.

- [ ] Each environment file has correct `apiUrl`, `enableAzureAuth`, `azureAd` (clientId, authority, redirectUri, postLogoutRedirectUri, scopes).
- [ ] After login, frontend **calls GET /auth/me** and stores the response in AuthService (userId/entraObjectId, email, name, isSupport, isPlatformAdmin).
- [ ] **No `forUser`** is sent on any workspace API call; backend derives current user from token.
- [ ] Audit fields (createdBy, updatedBy, deletedBy) use **current user from AuthService**, not hardcoded emails.
- [ ] Route guards: MsalGuard for Entra, authGuard for JWT; unauthenticated users go to login.
- [ ] **Verification:** Log in as a normal user → workspace list matches backend (only their workspaces); log in as Support → full list; createdBy/updatedBy show logged-in user’s email.

When all are checked, proceed to [Phase 4 — Roles in DB + email-change script (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_04_ROLES_IN_DB_TOKEN_ONLY.md).
