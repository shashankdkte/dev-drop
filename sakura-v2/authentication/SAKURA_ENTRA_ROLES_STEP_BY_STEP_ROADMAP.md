# Sakura — Entra Auth & Roles: Step-by-Step Roadmap

This document is a **zero-assumption, step-by-step roadmap** so that authentication with Microsoft Entra ID works flawlessly and each user has correct permissions. Every step states **which portal or system** to use, **what to change**, **for which environment**, and **why** in terms of **accurate**, **performant**, **scalable**, and **consistent** behaviour.

---

## Part A — Definitions and Principles

### A.1 Definitions (so we use the same language)

| Term | Definition |
|------|------------|
| **Entra ID** | Microsoft Entra ID (formerly Azure AD). The identity provider: holds users, groups, and app registrations. |
| **App Registration** | In Entra: the “application” that represents your SPA (or API). Has a Client ID, redirect URIs, and optional app roles. |
| **Enterprise Application** | The “instance” of an App Registration in your tenant; used for **Assign users and groups** and optional SSO. |
| **Token** | JWT issued by Entra after login. Contains claims (e.g. `sub`, `preferred_username`, `email`, `roles`, `groups`). |
| **Current user** | The identity the backend trusts for the request: always derived from the validated Bearer token, never from client-supplied parameters. |
| **Workspace Owner / Tech Owner / Approver** | Stored in **Sakura DB** in `Workspaces.WorkspaceOwner`, `WorkspaceTechOwner`, `WorkspaceApprover` (CSV emails). Defines who can manage that workspace and who sees it in the list. |
| **Support** | A user who can see **all** workspaces and assist any tenant. Maintained in **Entra** (e.g. group `Sakura_Support`) or backend config. |
| **Platform Administrator (ADM)** | Can create workspaces, change application settings, see event logs. Maintained in **Entra** (e.g. app role) or config. |
| **Requester (REQ)** | Any authenticated user; can create and view their own requests. No separate store. |
| **Approver (APR)** | User appears in DB as RLS/OLS/report approver for a workspace. Maintained in **Sakura DB** (approver tables and WorkspaceApprover). |

### A.2 Four principles and how they drive the steps

| Principle | Meaning | How we apply it |
|-----------|--------|------------------|
| **Accurate** | Identity and permissions reflect reality; no wrong access. | Backend **never** trusts client-supplied identity; we derive user from the validated token. Roles come from a single source (Entra or DB) per role type. |
| **Performant** | No unnecessary latency or load. | Validate token once per request; use claims in token (e.g. groups, roles) instead of extra API calls where possible; cache current user in request scope. |
| **Scalable** | Adding users/workspaces/environments doesn’t require re-architecting. | Use Entra **groups** for Support/Admin so we add users to groups, not hardcode UPNs. Workspace-level data stays in DB. One pattern for Dev vs UAT vs Prod. |
| **Consistent** | Same rules everywhere; same behaviour across envs. | One auth pipeline (token → ICurrentUserService → authorization). Same role semantics in all environments; only configuration (URLs, client IDs) changes per env. |

---

## Part B — Roadmap Overview

| Phase | Goal | Main outcome |
|-------|------|--------------|
| **1** | Entra foundation | App registration(s), redirect URIs, token claims; users can sign in and get a valid token. |
| **2** | Backend: trust the token | ICurrentUserService, validation on every request, no trust of client `forUser`. |
| **3** | Frontend: use token only | No hardcoded `forUser`; call `/auth/me`; use current user for workspaces and audit fields. |
| **4** | Roles and assignment | Support and (optional) Platform Admin in Entra; workspace/approver data in DB; backend enforces. |
| **5** | Per-environment checklist | Dev, UAT, Prod each configured correctly. |
| **6** | Validation and go-live | Smoke tests and checklist so auth works flawlessly. |

---

## Phase 1 — Entra foundation (Azure Portal)

**Goal:** So that the frontend can redirect users to Entra, get a token, and the backend can validate it with correct audience/issuer.

---

### Step 1.1 — Create or identify the App Registration (per environment)

| Where | Azure Portal → Microsoft Entra ID → App registrations |
|-------|--------------------------------------------------------|
| What | **New registration** (or use existing e.g. for UAT). One app per environment is recommended (Dev, UAT, Prod) for isolation. |
| Name | e.g. `Sakura-SPA-Dev`, `Sakura-SPA-UAT`, `Sakura-SPA-Prod` (or `azeuw1dweb01sakura` for UAT if that’s your convention). |
| Supported account types | “Accounts in this organizational directory only” (single tenant). |
| Redirect URI | Leave empty for now; we set it in the next step. |

**Why (Accurate / Performant / Scalable / Consistent)**  
- **Accurate:** Each environment has its own client ID and redirect URI so tokens and redirects can’t be mixed.  
- **Scalable:** Adding a new environment = new app registration, same steps.  
- **Consistent:** Same structure in Dev, UAT, Prod.

**Environments:** Repeat for Dev (optional if you use JWT-only in dev), UAT, Prod.

---

### Step 1.2 — Add SPA redirect URIs and enable PKCE

| Where | Same App registration → **Authentication** |
|-------|---------------------------------------------|
| What | 1. Platform: **Add a platform** → **Single-page application**.  
|      | 2. Redirect URIs:  
|      | - **Dev:** `http://localhost:4200`, `http://localhost:4200/`  
|      | - **UAT:** `https://<your-uat-static-web-app-url>` (e.g. `https://lemon-wave-07fa68003.2.azurestaticapps.net`)  
|      | - **Prod:** `https://<your-prod-url>` (e.g. `https://sakura.dentsu.com`)  
|      | 3. Under **Implicit grant and hybrid flows**: leave **unchecked** (we use Authorization code + PKCE only).  
|      | 4. **Save**. |

**Why**  
- **Accurate:** Redirect URI must match exactly what the frontend uses; wrong URI = auth failure.  
- **Performant / Consistent:** PKCE is the standard for SPAs; no implicit flow.

**Environments:** Configure only the URIs that apply to this app (e.g. one app for UAT = UAT URI only; if one app for all, add all three URIs).

---

### Step 1.3 — API permissions

| Where | Same App registration → **API permissions** |
|-------|--------------------------------------------|
| What | **Add a permission** → **Microsoft Graph** → **Delegated**:  
|      | - `openid`  
|      | - `profile`  
|      | - `User.Read`  
|      | (Optional) **APIs my organization uses** → your backend API if you expose a custom scope (e.g. `api://<backend-client-id>/access_as_user`). For validating the token with audience = SPA client ID, Graph is enough.  
|      | **Grant admin consent** (if your policy requires it). |

**Why**  
- **Accurate:** `openid` and `profile` give a standard ID token/access token with `sub`, `preferred_username`, etc.  
- **Consistent:** Same minimal set everywhere.

---

### Step 1.4 — Token configuration (optional claims)

| Where | Same App registration → **Token configuration** |
|-------|-------------------------------------------------|
| What | **Add optional claim** → **ID token** (and **Access token** if frontend sends access token to backend):  
|      | - `email`  
|      | - `preferred_username`  
|      | So the backend can read the user’s email/UPN from the token without extra calls. |

**Why**  
- **Accurate:** Backend gets the same identity Entra used.  
- **Performant:** No need to call Graph API to resolve user; claim is in the token.  
- **Consistent:** One way to get “current user email” in every request.

---

### Step 1.5 — Expose optional API scope (if backend validates tokens with custom audience)

| Where | Same App registration → **Expose an API** |
|-------|-------------------------------------------|
| What | If you want the backend to accept tokens with audience `api://<this-app-client-id>/access_as_user`:  
|      | **Add a scope**: `access_as_user`, “Admins and users”.  
|      | **Application ID URI**: default `api://<client-id>` is fine.  
| Frontend | Then request scope `api://<client-id>/access_as_user` in MSAL so the access token has this audience. |

**Why**  
- **Accurate:** Backend validates that the token was issued for your API, not just for Graph.  
- **Consistent:** Same pattern as in your existing env files that reference `api://.../access_as_user`.

**Environments:** Same Application ID URI pattern per app (Dev/UAT/Prod); only client ID changes.

---

### Step 1.6 — Create Security Group for Support (Entra)

| Where | Microsoft Entra ID → **Groups** → **New group** |
|-------|-----------------------------------------------|
| What | **Group type:** Security.  
|      | **Name:** e.g. `Sakura_Support`.  
|      | **Members:** Add the support user(s), e.g. `sakurahelp@dentsu.com`. |
| Why | **Scalable:** Add/remove support users by group membership; no code or config change. **Consistent:** One place to define “who is Support”. |

---

### Step 1.7 — (Optional) App roles for Platform Administrator

| Where | App registration → **App roles** → **Create app role** |
|-------|--------------------------------------------------------|
| What | **Display name:** e.g. `Sakura.Administrator`. **Value:** e.g. `Sakura.Administrator`. **Allowed members:** Users/Groups. **Save**. |
| Where | **Enterprise application** (same app) → **Users and groups** → **Add user/group** → assign the role to a user or to a group (e.g. `Sakura_Admins`). |
| Why | **Accurate:** Backend can read `roles` claim and allow create-workspace / app-settings only for this role. **Scalable:** Manage admins in Entra. |

---

### Step 1.8 — Assign the app to users or groups (who can sign in)

| Where | Microsoft Entra ID → **Enterprise applications** → select your app (e.g. `azeuw1dweb01sakura`) → **Users and groups** |
|-------|--------------------------------------------------------------------------------------------------------------------------|
| What | **Add user/group**: Either assign “Everyone” in the tenant (if all employees may use Sakura) or specific groups/users. |
| Why | **Accurate:** Only assigned users can get a token for the app. **Consistent:** Same assignment model in each env. |

---

## Phase 2 — Backend: trust the token

**Goal:** Backend validates the Bearer token on every request and derives the current user from it; no trust of client-supplied `forUser`.

---

### Step 2.1 — Ensure authentication middleware runs

| Where | Code: `AccessControlConfiguration.cs` (or wherever `ConfigureAccessControl(IApplicationBuilder)` is). |
|-------|------------------------------------------------------------------------------------------------------|
| What | Ensure **UseAuthentication()** is called **before** **UseAuthorization()**. Example:  
|      | `app.UseAuthentication();`  
|      | `app.UseAuthorization();`  
|      | *(In this repo it was previously commented out; it is now enabled so Bearer tokens are validated.)* |
| Why | **Accurate:** Without this, the Bearer token is never validated and `HttpContext.User` is not set. **Consistent:** Every request goes through the same pipeline. |

---

### Step 2.2 — Configure AzureAd in appsettings (per environment)

| Where | Backend: `appsettings.json` and/or `appsettings.{Environment}.json`, or Key Vault. |
|-------|-------------------------------------------------------------------------------------|
| What | When **AppSettings:EnableAzureAuth** is true, the **AzureAd** section must be valid:  
|      | - `Instance`: `https://login.microsoftonline.com/`  
|      | - `TenantId`: your Entra tenant ID (same as in frontend authority)  
|      | - `ClientId`: the **SPA** App Registration’s Client ID (so the backend validates tokens issued for that client)  
|      | - Optional: `Audience`: if you use a custom scope, e.g. `api://<client-id>/access_as_user` |
| Why | **Accurate:** Valid issuer and audience so only your tenant and your app’s tokens are accepted. **Consistent:** Same section name and shape in all envs; only values differ. |

**Environments:**  
- **Dev (JWT):** `EnableAzureAuth: false`; use **Jwt** section.  
- **UAT / Prod:** `EnableAzureAuth: true`; **AzureAd** with that env’s tenant and SPA client ID.

---

### Step 2.3 — Add ICurrentUserService

| Where | Backend: new interface and implementation. |
|-------|-------------------------------------------|
| What | 1. **Interface** (e.g. in Application or Domain):  
|      | `string? UserId { get; }`  
|      | `string? Email { get; }`  // or PreferredUsername  
|      | `string? Name { get; }`  
|      | `IReadOnlyList<string> Roles { get; }`  // from token or empty  
|      | 2. **Implementation** (e.g. in Api or Infrastructure): reads from `IHttpContextAccessor.HttpContext.User` (ClaimsPrincipal).  
|      | - **Entra token:** `UserId` = `sub`, `Email` = `preferred_username` or `email`, `Name` = `name`, `Roles` = `roles` claim (if present).  
|      | - **Dev JWT:** map your existing claims (e.g. `email`, `role`).  
|      | 3. Register as **Scoped** so one instance per request. |
| Why | **Accurate:** Single source of truth for “who is this request” from the validated token. **Performant:** No DB or HTTP call; just claims. **Consistent:** Same API for Entra and JWT. |

---

### Step 2.4 — Implement /auth/me

| Where | Backend: `AuthController` or dedicated `MeController`. |
|-------|--------------------------------------------------------|
| What | **GET /api/Auth/me** (or your route):  
|      | - Requires authenticated user (Bearer).  
|      | - Read from **ICurrentUserService** (UserId, Email, Name, Roles).  
|      | - Optionally enrich from DB (e.g. workspace list, “platform admin” flag).  
|      | - Return JSON: `{ userId, email, name, role, workspaceId?, workspaceName?, approverLevel? }` so the frontend matches its existing `AuthUser` shape. |
| Why | **Accurate:** Frontend gets the same identity the backend will use for authorization. **Performant:** One call after login. **Consistent:** Same response shape in all envs. |

---

### Step 2.5 — Remove trust of client forUser for workspaces

| Where | Backend: `WorkspaceController` (and any service that uses “current user” for workspace list). |
|-------|----------------------------------------------------------------------------------------------|
| What | 1. **Do not** take `forUser` from the query string for normal users.  
|      | 2. Get current user email from **ICurrentUserService.Email**.  
|      | 3. If current user is **Support** (see Step 2.6), call `GetAnyWorkspacesAsync()` (or equivalent) and return all workspaces.  
|      | 4. Otherwise call `GetWorkspacesForUserAsync(currentUserEmail, includeDeleted)` and return that list.  
|      | 5. Optionally keep `forUser` as an optional parameter **only** for Support users (e.g. “act as” for troubleshooting), and validate that the caller is Support before using it. |
| Why | **Accurate:** Users cannot see workspaces they are not Owner/TechOwner/Approver for. **Consistent:** Same logic in every environment. |

---

### Step 2.6 — Define and check “Support” in backend

| Where | Backend: config or small service. |
|-------|---------------------------------|
| What | **Option A:** App setting, e.g. `AppSettings:SupportUserEmails` = `sakurahelp@dentsu.com` (or comma-separated list).  
|      | **Option B:** Entra group: in token configuration (Step 1.4), enable **groups** claim; in backend, check `groups` claim contains the Object ID of `Sakura_Support` (or use “Groups overage” and Microsoft Graph if many groups).  
|      | In workspace list logic: if current user is in Support list/group → return all workspaces; else → filter by DB. |
| Why | **Accurate:** Only designated support accounts see all workspaces. **Scalable:** Adding support = add to group or config. **Consistent:** One definition of Support. |

---

### Step 2.7 — (Optional) Enforce Platform Administrator for sensitive actions

| Where | Backend: controllers or handlers for “create workspace”, “application settings”, “event logs”. |
|-------|----------------------------------------------------------------------------------------------|
| What | After authentication, check `ICurrentUserService.Roles` contains the Entra app role (e.g. `Sakura.Administrator`). If not, return 403. |
| Why | **Accurate:** Only admins can perform those actions. **Consistent:** Same role claim used everywhere. |

---

## Phase 3 — Frontend: use token only

**Goal:** Frontend never sends a fake `forUser`; it sends only the Bearer token; workspace list and audit fields use the current user from the backend.

---

### Step 3.1 — Environment files: correct values per environment

| Where | Frontend: `environment.ts`, `environment.uat.ts`, `environment.production.ts` (and api-dev if used). |
|-------|-----------------------------------------------------------------------------------------------------|
| What | For **each** environment set:  
|      | - `apiUrl` = backend base URL for that env.  
|      | - `enableAzureAuth` = `true` for UAT/Prod, `false` for local dev (if using JWT).  
|      | - `azureAd.clientId` = App Registration **Client ID** for that env.  
|      | - `azureAd.authority` = `https://login.microsoftonline.com/<tenant-id>`.  
|      | - `azureAd.redirectUri` and `postLogoutRedirectUri` = **exact** frontend origin for that env (must match Entra redirect URIs).  
|      | - `azureAd.scopes` = `['User.Read','openid','profile']` or include `api://<client-id>/access_as_user` if backend expects that audience. |
| Why | **Accurate:** Wrong redirect URI = login fails; wrong client ID = wrong audience. **Consistent:** Same keys in every file; only values differ. |

**Environments:**  
- **Dev:** e.g. `http://localhost:4200`, client ID of Dev app (or shared).  
- **UAT:** UAT Static Web App URL, UAT app client ID.  
- **Prod:** Prod URL, Prod app client ID.

---

### Step 3.2 — After login: call /auth/me and store user

| Where | Frontend: login flow (e.g. `UiAzureLoginComponent` and `AuthService`). |
|-------|----------------------------------------------------------------------|
| What | 1. After MSAL redirect (or after JWT login), get the token and store it (already done).  
|      | 2. **Call GET /auth/me** with the Bearer token.  
|      | 3. Map response to `AuthUser` (userId, email, name, role, workspaceId, workspaceName, approverLevel) and store in **AuthService** (e.g. `setStoredUser`, `currentUserSubject.next`).  
|      | 4. So for the rest of the app, “current user” comes from this one source. |
| Why | **Accurate:** UI and API use the same identity the backend uses. **Performant:** One call per login. **Consistent:** Same flow for Azure and JWT. |

---

### Step 3.3 — Stop sending forUser for workspaces

| Where | Frontend: `workspace-domain.service.ts` (and any other place that calls `/workspaces`). |
|-------|---------------------------------------------------------------------------------------|
| What | Remove the hardcoded `forUser: 'sakurahelp@dentsu.com'` from **all** workspace API calls.  
|      | Call **GET /workspaces?includeDeleted=false** (or true) **without** a `forUser` parameter.  
|      | Backend will use the token to get the current user and return the correct list. |
| Why | **Accurate:** Users only get workspaces they are allowed to see. **Consistent:** No special dev override that leaks to prod. |

---

### Step 3.4 — Use current user for audit fields

| Where | Frontend: e.g. `wso-object-management.component.ts`, any place that sets `createdBy` / `deletedBy` / `updatedBy`. |
|-------|-------------------------------------------------------------------------------------------------------------------|
| What | Replace every `'current.user@dentsu.com'` or `'sakurahelp@dentsu.com'` with `this.authService.currentUserValue?.email ?? ''` (or from `getCurrentUser()`). |
| Why | **Accurate:** Audit trail reflects the real user. **Consistent:** One source for “current user” in the UI. |

---

### Step 3.5 — Route guards

| Where | Frontend: `app.routes.ts` and guard implementations. |
|-------|------------------------------------------------------|
| What | Ensure protected routes use **MsalGuard** when `enableAzureAuth` is true, and your existing **authGuard** (JWT) when false. Unauthenticated users redirect to `/login`. |
| Why | **Accurate:** No access to app without a valid session. **Consistent:** Same protection in all envs with the right guard per auth mode. |

---

## Phase 4 — Roles and user management (where what lives)

**Goal:** One clear place per role type; backend enforces using token + DB.

---

### Step 4.1 — Where each “role” is maintained (summary)

| Role / Concept | Where to maintain | Backend how |
|----------------|-------------------|-------------|
| **Workspace Owner / Tech Owner** | **Sakura DB:** `Workspaces.WorkspaceOwner`, `WorkspaceTechOwner` | Already: `GetWorkspacesForUserAsync(email)` filters by these. Use **ICurrentUserService.Email**. |
| **Workspace Approver** | **Sakura DB:** `Workspaces.WorkspaceApprover` + RLS/OLS approver tables | Same: user in these lists → sees workspace and approval queues. |
| **Support** | **Entra:** group `Sakura_Support` (or backend config list) | If current user in group/config → return all workspaces; else filter by DB. |
| **Platform Administrator** | **Entra:** App role e.g. `Sakura.Administrator` (optional) | If `roles` claim contains role → allow create workspace, app settings, etc. |
| **Requester** | No store | Any authenticated user. |
| **Approver (per workspace/report)** | **Sakura DB:** RLS approvers, OLS/report approvers | Backend checks DB when loading “my approvals” and when approving. |

**Why**  
- **Accurate:** One source per role type; no duplicate or conflicting definitions.  
- **Scalable:** Add users to Entra groups or DB rows; no code change.  
- **Consistent:** Same table/group structure in every environment (data differs, schema same).

---

### Step 4.2 — Ensure token contains groups (if using Entra group for Support)

| Where | Entra: App registration → **Token configuration** |
|-------|----------------------------------------------------|
| What | Add optional claim: **groups** (or use “Groups overage” and Graph if user has many groups).  
|      | In backend: read `groups` claim and compare to `Sakura_Support` group Object ID (stored in config). |
| Why | **Performant:** No extra Graph call if groups are in the token. **Accurate:** Backend sees same membership as Entra. |

---

## Phase 5 — Per-environment checklist

Use this as a literal checklist; tick when done for each environment.

### Dev (local, JWT)

| Step | Portal / Place | What | Done |
|------|----------------|------|------|
| 1.1 | Entra | (Optional) App registration for Dev | ☐ |
| 1.2 | Entra | Redirect URI `http://localhost:4200` | ☐ |
| 2.1 | Backend | UseAuthentication() enabled | ☐ |
| 2.2 | Backend | EnableAzureAuth = false; Jwt section set | ☐ |
| 2.3–2.4 | Backend | ICurrentUserService + /auth/me (JWT claims) | ☐ |
| 2.5–2.6 | Backend | Workspace list from ICurrentUserService; Support from config if needed | ☐ |
| 3.1 | Frontend | environment: apiUrl, enableAzureAuth false, tokenKey | ☐ |
| 3.2–3.5 | Frontend | /auth/me after login; no forUser; audit from currentUser; guards | ☐ |

### UAT (Entra)

| Step | Portal / Place | What | Done |
|------|----------------|------|------|
| 1.1–1.5 | Entra | App registration UAT; SPA URIs; permissions; optional claims; optional API scope | ☐ |
| 1.6–1.8 | Entra | Sakura_Support group; optional App role; assign users/groups to app | ☐ |
| 2.1 | Backend | UseAuthentication() enabled | ☐ |
| 2.2 | Backend | EnableAzureAuth = true; AzureAd = UAT tenant + SPA client ID | ☐ |
| 2.3–2.7 | Backend | ICurrentUserService (Entra claims); /auth/me; workspace from token; Support check; optional ADM check | ☐ |
| 3.1 | Frontend | environment.uat: apiUrl UAT, enableAzureAuth true, redirectUri = UAT SWA URL, clientId UAT | ☐ |
| 3.2–3.5 | Frontend | Same as Dev | ☐ |

### Production (Entra)

| Step | Portal / Place | What | Done |
|------|----------------|------|------|
| 1.1–1.8 | Entra | Same as UAT but Prod app registration and Prod redirect URI | ☐ |
| 2.2 | Backend | EnableAzureAuth = true; AzureAd = Prod tenant + SPA client ID | ☐ |
| 2.3–2.7 | Backend | Same as UAT (code same; config different) | ☐ |
| 3.1 | Frontend | environment.production: apiUrl Prod, redirectUri Prod, clientId Prod | ☐ |
| 3.2–3.5 | Frontend | Same as UAT | ☐ |

---

## Phase 6 — Validation (auth works flawlessly)

### Step 6.1 — Smoke tests per environment

| Test | Expected |
|------|----------|
| Unauthenticated GET /api/workspaces | 401 (or redirect to login if you use challenge). |
| Login (Entra or JWT) then GET /api/auth/me | 200; body has email, name, role. |
| GET /api/workspaces with valid token | 200; list only workspaces where user is Owner/TechOwner/Approver (or all if Support). |
| Support user GET /api/workspaces | 200; full list. |
| Non-admin POST create workspace | 403 if you enforce ADM role; otherwise per your rules. |
| Frontend: after login, workspace list loads | No hardcoded forUser; list matches backend. |
| Frontend: create/delete object | createdBy/deletedBy = current user email. |

### Step 6.2 — Quick “nothing missed” checklist

- [ ] Entra redirect URIs match frontend origins exactly (including trailing slash or not).
- [ ] Backend AzureAd.ClientId = SPA client ID (or audience) for that env.
- [ ] UseAuthentication() is called before UseAuthorization().
- [ ] No `forUser` sent from frontend; backend uses ICurrentUserService only.
- [ ] Support defined in one place (group or config) and checked in one place in code.
- [ ] All env files have correct apiUrl, clientId, redirectUri for that env.

---

## Summary table: step → principle

| Step | Accurate | Performant | Scalable | Consistent |
|------|----------|------------|----------|------------|
| Entra app per env, correct redirect URIs | Right token, no wrong app | — | New env = new app | Same setup per env |
| Token optional claims (email, preferred_username) | Backend knows user from token | No extra Graph call | — | One way to get user |
| Support as Entra group | Only group members are Support | — | Add/remove in group | Single definition |
| ICurrentUserService from token | No client-supplied identity | Claims only, request-scoped | — | Same API JWT/Entra |
| No forUser from client; backend derives | Users see only their workspaces | — | — | Same logic all envs |
| /auth/me after login | UI and API same identity | One call per login | — | Same response shape |
| Roles: Entra for Support/ADM, DB for workspace/approver | One source per role type | — | Groups/DB rows scale | Same rules everywhere |

Following this roadmap in order gives you a configuration where Entra auth works end-to-end, each user has the correct permissions, and the system stays accurate, performant, scalable, and consistent.

---

## Appendix — One-page “order of operations”

Do these in order so nothing is missed:

1. **Entra (Azure Portal)**  
   - Create App Registration(s) per env → Authentication (SPA + redirect URIs) → API permissions (openid, profile, User.Read) → Token config (email, preferred_username; optional groups) → Create group `Sakura_Support` → Assign users/groups to app (and optional app role).

2. **Backend**  
   - Uncomment/enable `app.UseAuthentication()` before `UseAuthorization()`.  
   - Set appsettings: `EnableAzureAuth` + `AzureAd` (or Jwt for dev).  
   - Add `ICurrentUserService` (from `HttpContext.User`).  
   - Implement GET `/auth/me`.  
   - Workspace list: use `ICurrentUserService.Email`; if Support → all workspaces, else `GetWorkspacesForUserAsync(email)`.  
   - (Optional) Support from config or `groups` claim; (optional) Platform Admin from `roles` claim.

3. **Frontend**  
   - Set each environment file: `apiUrl`, `enableAzureAuth`, `azureAd` (clientId, authority, redirectUri, scopes).  
   - After login: call `/auth/me`, store in AuthService.  
   - Remove all `forUser` from workspace calls.  
   - Use `authService.currentUserValue?.email` for createdBy/deletedBy.  
   - Guards: MsalGuard (when Entra) or authGuard (when JWT).

4. **Validate**  
   - 401 when no token; 200 with correct list for normal user; all workspaces for Support; audit fields show current user.
