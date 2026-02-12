# Sakura — Using One App Registration for All Three Environments

**Purpose:** Use the existing **Sakura** App Registration (and its Enterprise Application) for **Dev**, **UAT**, and **Prod** so you maintain a single Client ID and tenant. This doc tells you what to configure in Entra and in your app for each environment.

---

## 1. Overview

| Item | Value |
|------|--------|
| **App Registration name** | Sakura |
| **Application (client) ID** | `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` |
| **Directory (tenant) ID** | `6e8992ec-76d5-4ea5-8eae-b0c5e558749a` |
| **Authority** | `https://login.microsoftonline.com/6e8992ec-76d5-4ea5-8eae-b0c5e558749a` |

**Same for all three envs:** Client ID, Tenant ID, Authority, API scope (`api://e73f4528-2ceb-40e3-8e4a-d72287adb4c5/access_as_user`).

**Different per env:** Frontend origin (redirect URI), backend API URL. So you add **three redirect URIs** in Entra and set **apiUrl** and **redirectUri** per environment in your frontend (and backend URL per env in appsettings if needed).

---

## 2. Environment URLs (from your codebase)

| Environment | Frontend (Static Web App / origin) | Redirect URI / Post-logout | Backend API |
|-------------|-------------------------------------|-----------------------------|-------------|
| **Dev** | `https://orange-sand-03a59b103.3.azurestaticapps.net` | Same as origin | `https://azeuw1dweb01sakura.azurewebsites.net` |
| **UAT** | `https://lemon-wave-07fa68003.2.azurestaticapps.net` | Same as origin | `https://azeuw1tweb01sakura.azurewebsites.net` |
| **Prod** | `https://sakura.dentsu.com` | Same as origin | `https://api.sakura.dentsu.com` |

If your actual Dev/UAT URLs differ (e.g. after a new deployment), use the **exact** URL the browser shows and add that in Entra and in the env file.

---

## 3. What to do in Azure Portal (Entra)

### 3.1 Add redirect URIs for all three environments

1. Go to **Microsoft Entra ID** → **App registrations** → **Sakura**.
2. Open **Authentication** (or **Authentication (Preview)**).
3. Under **Platform configurations**, find **Single-page application** (or add platform → Single-page application if you only have Web).
4. Add these **Redirect URIs** (one per environment). Entra matches exactly, so no trailing slash unless your app sends it:

   | Environment | Redirect URI to add |
   |-------------|---------------------|
   | Dev | `https://orange-sand-03a59b103.3.azurestaticapps.net` |
   | UAT | `https://lemon-wave-07fa68003.2.azurestaticapps.net` |
   | Prod | `https://sakura.dentsu.com` |

5. If your app uses a path for redirect (e.g. `/auth-callback`), add that too (e.g. `https://orange-sand-03a59b103.3.azurestaticapps.net/auth-callback`). Otherwise the origin alone is enough.
6. **Save**.

**Optional:** Add the same URLs **with** a trailing slash if you see redirect issues (e.g. `https://orange-sand-03a59b103.3.azurestaticapps.net/`).

### 3.2 Use SPA (Authorization code + PKCE), not implicit grant

- For the Sakura SPA, use **Single-page application** redirect URIs only.
- Do **not** rely on **Web** with implicit grant for the Sakura frontend. If the portal shows “implicit grant enabled” and “migrate URIs for MSAL.js 2.0”, ensure the three URLs above are under **SPA** and that your app uses **authorization code + PKCE** (MSAL 2.x default).

### 3.3 Assign users (Enterprise Application)

- Go to **Enterprise applications** → **Sakura** → **Users and groups**.
- **Assign users and groups** so the right people can sign in. Same assignment applies to all three envs (same app). Use Conditional Access or different groups if you need to restrict by environment.

### 3.4 Certificate or secret

- If the portal shows “A certificate or secret is expiring soon”, create a new one under **Certificates & secrets** and update any app that uses it (e.g. backend or daemon). Frontend SPA uses PKCE and does not need a client secret for user sign-in.

---

## 4. Frontend configuration per environment

Use the **same** Client ID, Authority, and scopes in all env files. Change only **apiUrl**, **redirectUri**, and **postLogoutRedirectUri** (and **enableAzureAuth** if you keep JWT for local dev).

### 4.1 Values that stay the same (all envs)

```ts
azureAd: {
  clientId: 'e73f4528-2ceb-40e3-8e4a-d72287adb4c5',
  authority: 'https://login.microsoftonline.com/6e8992ec-76d5-4ea5-8eae-b0c5e558749a',
  scopes: [
    'api://e73f4528-2ceb-40e3-8e4a-d72287adb4c5/access_as_user'
  ]
}
```

### 4.2 Values that change per environment

| Env file | apiUrl | redirectUri | postLogoutRedirectUri | enableAzureAuth |
|----------|--------|-------------|------------------------|-----------------|
| **environment.ts** (local dev) | `https://azeuw1dweb01sakura.azurewebsites.net` | `http://localhost:4200` | `http://localhost:4200` | `false` or `true` |
| **environment.api-dev.ts** (Dev build) | Dev backend URL | `https://orange-sand-03a59b103.3.azurestaticapps.net` | Same | `true` |
| **environment.uat.ts** | `https://azeuw1tweb01sakura.azurewebsites.net` | `https://lemon-wave-07fa68003.2.azurestaticapps.net` | Same | `true` |
| **environment.production.ts** | `https://api.sakura.dentsu.com` | `https://sakura.dentsu.com` | `https://sakura.dentsu.com` | `true` |

Ensure **redirectUri** and **postLogoutRedirectUri** match **exactly** what you added in Entra (no trailing slash unless you added it in Entra).

### 4.3 If you have a dedicated Dev env file

If your pipeline uses a dedicated Dev config (e.g. for `orange-sand-03a59b103.3.azurestaticapps.net`), set:

- `apiUrl` = your Dev backend (e.g. `https://azeuw1dweb01sakura.azurewebsites.net`).
- `redirectUri` = `https://orange-sand-03a59b103.3.azurestaticapps.net`.
- `postLogoutRedirectUri` = same as redirectUri.
- `clientId`, `authority`, `scopes` = same as above.

---

## 5. Backend configuration

Each environment’s backend (Dev/UAT/Prod) should validate the token issued for the **same** Client ID:

- **AzureAd:ClientId** = `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` (same for all envs).
- **AzureAd:TenantId** = `6e8992ec-76d5-4ea5-8eae-b0c5e558749a`.
- **AzureAd:Audience** (if used) = `api://e73f4528-2ceb-40e3-8e4a-d72287adb4c5/access_as_user`.

Only backend base URL and any env-specific settings (e.g. CORS, app settings) differ per environment; the Entra app identity is shared.

---

## 6. Checklist: utilize one App Registration for all three envs

Use this to confirm everything is set.

### In Azure Portal (Entra)

- [ ] **App registrations** → **Sakura** → **Authentication**.
- [ ] **Single-page application** has these redirect URIs:
  - [ ] `https://orange-sand-03a59b103.3.azurestaticapps.net` (Dev)
  - [ ] `https://lemon-wave-07fa68003.2.azurestaticapps.net` (UAT)
  - [ ] `https://sakura.dentsu.com` (Prod)
- [ ] Optional: add `http://localhost:4200` for local dev if you use Entra there.
- [ ] **Save**.
- [ ] **Enterprise applications** → **Sakura** → **Users and groups**: users/groups assigned so people can sign in.
- [ ] If a certificate or secret is expiring, create a new one and rotate where it’s used.

### Frontend

- [ ] **environment.ts**: `clientId`, `authority`, `scopes` match the table in §4.1; `redirectUri`/`postLogoutRedirectUri` = `http://localhost:4200` for local.
- [ ] **environment.uat.ts**: `apiUrl` = UAT backend; `redirectUri`/`postLogoutRedirectUri` = `https://lemon-wave-07fa68003.2.azurestaticapps.net`.
- [ ] **environment.production.ts**: `apiUrl` = Prod backend; `redirectUri`/`postLogoutRedirectUri` = `https://sakura.dentsu.com`.
- [ ] Dev build (orange-sand URL): env file used by that build has `redirectUri` = `https://orange-sand-03a59b103.3.azurestaticapps.net` and correct Dev `apiUrl`.

### Backend

- [ ] Dev/UAT/Prod appsettings (or Key Vault) use **AzureAd:ClientId** = `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` and **AzureAd:TenantId** = `6e8992ec-76d5-4ea5-8eae-b0c5e558749a` (and same Audience if configured).

### Verify

- [ ] **Dev:** Open `https://orange-sand-03a59b103.3.azurestaticapps.net`, sign in with Entra → redirects back and loads app.
- [ ] **UAT:** Open `https://lemon-wave-07fa68003.2.azurestaticapps.net`, sign in → same.
- [ ] **Prod:** Open `https://sakura.dentsu.com`, sign in → same.

If any redirect fails, double-check that the URL in the browser (including trailing slash) exactly matches a redirect URI in the App Registration.

---

## 7. Related docs

| Doc | Use when |
|-----|----------|
| **SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md** | Full auth roadmap (token-only, no User table). |
| **SAKURA_ENTRA_ROADMAP_PHASE_01_ENTRA_FOUNDATION_TOKEN_ONLY.md** | Entra setup steps (permissions, token config, etc.). |

This doc focuses only on **using one App Registration for Dev, UAT, and Prod**; for end-to-end auth (backend, frontend, roles, validation), follow the phase docs.
