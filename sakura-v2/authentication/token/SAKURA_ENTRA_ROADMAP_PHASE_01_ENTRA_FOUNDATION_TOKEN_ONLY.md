# Phase 1 — Entra foundation (Token-only)

**Goal:** So that the frontend can redirect users to Entra, get a token, and the backend can validate it with correct audience/issuer.

**Do not start Phase 2 until the [Check before moving to Phase 2](#check-before-moving-to-phase-2) section is complete.**

*This phase is the same as the User-table variant; only the link to Phase 2 and the approach name differ.*

---

## Step 1.1 — Create or identify the App Registration (per environment)

| Where | Azure Portal → Microsoft Entra ID → App registrations |
|-------|--------------------------------------------------------|
| What | **New registration** (or use existing e.g. for UAT). One app per environment is recommended (Dev, UAT, Prod) for isolation. |
| Name | e.g. `Sakura-SPA-Dev`, `Sakura-SPA-UAT`, `Sakura-SPA-Prod` (or `azeuw1dweb01sakura` for UAT if that’s your convention). |
| Supported account types | “Accounts in this organizational directory only” (single tenant). |
| Redirect URI | Leave empty for now; set in Step 1.2. |

**Environments:** Repeat for Dev (optional if using JWT-only in dev), UAT, Prod.

---

## Step 1.2 — Add SPA redirect URIs and enable PKCE

| Where | Same App registration → **Authentication** |
|-------|---------------------------------------------|
| What | 1. **Add a platform** → **Single-page application**.  
|      | 2. **Redirect URIs:**  
|      | - **Dev:** `http://localhost:4200`, `http://localhost:4200/`  
|      | - **UAT:** `https://<your-uat-static-web-app-url>` (e.g. from your Static Web App)  
|      | - **Prod:** `https://<your-prod-url>`  
|      | 3. **Implicit grant and hybrid flows:** leave **unchecked** (Authorization code + PKCE only).  
|      | 4. **Save**. |

**Environments:** Configure only the URIs that apply to this app (one app per env = that env’s URI only; one app for all = add all).

---

## Step 1.3 — API permissions

| Where | Same App registration → **API permissions** |
|-------|--------------------------------------------|
| What | **Add a permission** → **Microsoft Graph** → **Delegated:**  
|      | - `openid`  
|      | - `profile`  
|      | - `User.Read`  
|      | **Grant admin consent** (if your policy requires it). |

---

## Step 1.4 — Token configuration (optional claims)

| Where | Same App registration → **Token configuration** |
|-------|-------------------------------------------------|
| What | **oid** is in the token by default. **Add optional claim** → **ID token** (and **Access token** if frontend sends access token to backend):  
|      | - `email`  
|      | - `preferred_username`  
|      | So the backend has **oid** (stable; for SupportUsers/PlatformAdmins and RefreshToken) and **email** (for workspace/approver matching and display). |

---

## Step 1.5 — Expose optional API scope (if backend validates custom audience)

| Where | Same App registration → **Expose an API** |
|-------|-------------------------------------------|
| What | If backend expects audience `api://<this-app-client-id>/access_as_user`:  
|      | **Add a scope:** `access_as_user`, “Admins and users”.  
|      | **Application ID URI:** default `api://<client-id>` is fine.  
| Frontend | Request scope `api://<client-id>/access_as_user` in MSAL so the access token has this audience. |

**Environments:** Same pattern per app; only client ID changes.

---

## Step 1.6 — (Optional) Entra group for Support

**Token-only approach uses DB for Support.** Use DB table `SupportUsers(EntraObjectId)` so all role data is in one place (Phase 2/4).

---

## Step 1.7 — (Optional) Entra App roles for Platform Administrator

**Token-only approach uses DB for Platform Admin.** Use DB table `PlatformAdmins(EntraObjectId)` (Phase 2/4).

---

## Step 1.8 — Assign the app to users or groups (who can sign in)

| Where | Microsoft Entra ID → **Enterprise applications** → your app → **Users and groups** |
|-------|----------------------------------------------------------------------------------------|
| What | **Add user/group:** Either “Everyone” in the tenant or specific groups/users. |

---

## Check before moving to Phase 2

Do **not** start Phase 2 until every item below is done.

- [ ] At least one App Registration exists (e.g. for UAT).
- [ ] SPA platform is added; redirect URIs are set and **match frontend origin(s) exactly** (including trailing slash or not).
- [ ] API permissions: openid, profile, User.Read; admin consent granted if required.
- [ ] Token configuration: **oid** is available (default); optional claims email, preferred_username added if needed.
- [ ] (If using custom audience) API scope `access_as_user` exposed and frontend will request it.
- [ ] Users/groups assigned to the app so test users can sign in.
- [ ] **Verification:** A test user can open the frontend (or token endpoint), sign in, and receive a valid token containing **oid** and email.

When all are checked, proceed to [Phase 2 — Backend: token only (no User table)](SAKURA_ENTRA_ROADMAP_PHASE_02_BACKEND_TOKEN_ONLY.md).
