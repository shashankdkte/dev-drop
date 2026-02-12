# Phase 2 — Backend: token only (no User table)

**Goal:** Backend validates the Bearer token and uses **oid** + **email from the token** for all authorization. No User table; no oid→User resolution. SupportUsers and PlatformAdmins are keyed by **EntraObjectId (oid)**. No trust of client-supplied `forUser`. The backend is **stateless** (no server-side session store).

**Prerequisite:** Phase 1 complete ([Gate 1 → 2](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md#gate-1--2-after-phase-1)).

**Do not start Phase 3 until the [Check before moving to Phase 3](#check-before-moving-to-phase-3) section is complete.**

---

## Step 2.1 — Ensure authentication middleware runs

| Where | Code: e.g. `Program.cs` or `Startup.cs` (where pipeline is configured). |
|-------|-----------------------------------------------------------------------|
| What | Ensure **UseAuthentication()** is called **before** **UseAuthorization()**.  
|      | `app.UseAuthentication();`  
|      | `app.UseAuthorization();` |
| Why | Without this, the Bearer token is never validated and `HttpContext.User` is not set. |

---

## Step 2.2 — Configure AzureAd in appsettings (per environment)

| Where | Backend: `appsettings.json` and/or `appsettings.{Environment}.json`, or Key Vault. |
|-------|-------------------------------------------------------------------------------------|
| What | When **AppSettings:EnableAzureAuth** is true, **AzureAd** section must be valid:  
|      | - `Instance`: `https://login.microsoftonline.com/`  
|      | - `TenantId`: your Entra tenant ID (same as frontend authority)  
|      | - `ClientId`: the **SPA** App Registration’s Client ID  
|      | - Optional: `Audience`: e.g. `api://<client-id>/access_as_user` if using custom scope |
| **Environments** | Dev: `EnableAzureAuth: false`; use **Jwt** section. UAT/Prod: `EnableAzureAuth: true`; **AzureAd** with that env’s tenant and SPA client ID. |

---

## Step 2.3 — Add SupportUsers and PlatformAdmins tables (no User table)

| Where | Sakura DB. |
|-------|-------------|
| What | Create **dbo.SupportUsers** with column **EntraObjectId** (NVARCHAR(255), unique or not — one row per support user). Insert rows with the **oid** of users who should see all workspaces.  
|      | Create **dbo.PlatformAdmins** with column **EntraObjectId** (NVARCHAR(255)). Insert rows with the **oid** of platform admins.  
| Note | **No User table.** RefreshToken.UserId (NVARCHAR) stores **oid**; no change needed. |

---

## Step 2.4 — Add ICurrentUserService (oid + email from token only)

| Where | Backend: new interface and implementation. |
|-------|--------------------------------------------|
| What | **Interface:**  
|      | `string? EntraObjectId { get; }`  // oid from token  
|      | `string? Email { get; }`  // **from token** (email or preferred_username claim)  
|      | `string? Name { get; }`  // from token (name or preferred_username)  
|      | **Implementation:** Read **oid**, **email** (or preferred_username), **name** from `HttpContext.User` claims only. **No DB lookup** for identity.  
|      | **Dev JWT:** If no oid, use a claim you set (e.g. email) and return that as EntraObjectId for dev.  
|      | Register as **Scoped**. |

---

## Step 2.5 — Implement GET /api/Auth/me

| Where | Backend: `AuthController` or `MeController`. |
|-------|---------------------------------------------|
| What | **GET /api/Auth/me** (or your route):  
|      | - Requires authenticated user (Bearer).  
|      | Read from **ICurrentUserService**: EntraObjectId (oid), **Email (from token)**, Name.  
|      | Check DB: isSupport = current user’s **EntraObjectId** exists in **SupportUsers**; isPlatformAdmin = **EntraObjectId** exists in **PlatformAdmins**.  
|      | Return JSON: `{ userId: entraObjectId, entraObjectId, email, name, isSupport?, isPlatformAdmin? }` so frontend can use `userId` as stable id (oid string). |

---

## Step 2.6 — Remove trust of client forUser for workspaces

| Where | Backend: `WorkspaceController` and any service that returns workspace list. |
|-------|----------------------------------------------------------------------------|
| What | 1. **Do not** take `forUser` from query string for normal users.  
|      | 2. Get **current user email** from **ICurrentUserService.Email** (from **token**).  
|      | 3. If current user’s **EntraObjectId** is in **SupportUsers**, call GetAnyWorkspacesAsync() and return all workspaces.  
|      | 4. Otherwise call GetWorkspacesForUserAsync(currentUserEmail, includeDeleted) and return that list.  
|      | 5. Optionally keep `forUser` **only for Support** (e.g. “act as” for troubleshooting); validate caller is in SupportUsers before using it. |

---

## Step 2.7 — Define and check “Support” in backend (DB, by oid)

| Where | Sakura DB: table `dbo.SupportUsers`. Backend: check in workspace list logic. |
|-------|--------------------------------------------------------------------------------|
| What | **SupportUsers** has column **EntraObjectId** (oid). Insert rows for support users (use their Entra oid).  
|      | In workspace list: if **ICurrentUserService.EntraObjectId** is in **SupportUsers** → return all workspaces; else → filter by **ICurrentUserService.Email** (from token). |

---

## Step 2.8 — Enforce Platform Administrator for sensitive actions (DB, by oid)

| Where | Sakura DB: table `dbo.PlatformAdmins`. Backend: check before create workspace, app settings, event logs. |
|-------|----------------------------------------------------------------------------------------------------------|
| What | **PlatformAdmins** has column **EntraObjectId** (oid). Insert rows for platform admins.  
|      | Before sensitive actions: if **ICurrentUserService.EntraObjectId** is in **PlatformAdmins** → allow; else → 403. |

---

## Step 2.9 — RefreshToken and login (optional)

| Where | Backend: auth/login and refresh flow. |
|-------|-------------------------------------|
| What | When issuing a refresh token, store **EntraObjectId (oid)** in **RefreshToken.UserId** (already NVARCHAR). No User table to link to. |

---

## Check before moving to Phase 3

Do **not** start Phase 3 until every item below is done.

- [ ] **UseAuthentication()** is called before **UseAuthorization()**.
- [ ] **No User table**; identity comes from **token only** (oid + email).
- [ ] **dbo.SupportUsers** and **dbo.PlatformAdmins** exist with **EntraObjectId** (oid); at least one test row each if you need to test Support/Admin.
- [ ] **ICurrentUserService** exposes **EntraObjectId**, **Email (from token)**, Name; registered Scoped; no DB lookup for identity.
- [ ] **GET /api/Auth/me** returns entraObjectId, email, name, isSupport, isPlatformAdmin (token + SupportUsers/PlatformAdmins by oid).
- [ ] Workspace list uses **ICurrentUserService** only; no trust of `forUser` for normal users; email from token for matching; Support gets all workspaces via SupportUsers (EntraObjectId).
- [ ] Platform Admin actions (create workspace, app settings, event logs) check **PlatformAdmins** (EntraObjectId) and return 403 if not in table.
- [ ] **Verification:** With a valid Bearer token, GET /api/Auth/me returns 200 and correct identity; GET /api/workspaces returns list filtered by token email (or all for Support).

When all are checked, proceed to [Phase 3 — Frontend: token only](SAKURA_ENTRA_ROADMAP_PHASE_03_FRONTEND_TOKEN_ONLY.md).
