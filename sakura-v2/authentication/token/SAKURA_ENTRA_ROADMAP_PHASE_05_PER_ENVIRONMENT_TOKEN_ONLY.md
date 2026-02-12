# Phase 5 — Per-environment checklist (Token-only)

**Goal:** Dev, UAT, and Prod (or your env set) each configured correctly: Entra, backend config, DB (SupportUsers, PlatformAdmins only; no User table), frontend env.

**Prerequisite:** Phase 4 complete ([Gate 4 → 5](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md#gate-4--5-after-phase-4)).

**Do not start Phase 6 until the [Check before moving to Phase 6](#check-before-moving-to-phase-6) section is complete.**

---

## Dev (local, JWT)

Use this as a literal checklist; tick when done.

| Step | Portal / Place | What (token-only) | Done |
|------|-----------------|-------------------|------|
| 1.1 | Entra | (Optional) App registration for Dev | ☐ |
| 1.2 | Entra | Redirect URI `http://localhost:4200` if using Entra in dev | ☐ |
| 2.1 | Backend | UseAuthentication() enabled | ☐ |
| 2.2 | Backend | EnableAzureAuth = false; Jwt section set | ☐ |
| 2.3 | DB | SupportUsers, PlatformAdmins tables exist (EntraObjectId); no User table | ☐ |
| 2.4–2.8 | Backend | ICurrentUserService from token (oid, email); /auth/me; workspace list from token email; Support/PlatformAdmin from DB by oid | ☐ |
| 3.1 | Frontend | environment: apiUrl, enableAzureAuth false, tokenKey (or JWT config) | ☐ |
| 3.2–3.5 | Frontend | /auth/me after login; no forUser; audit from currentUser; guards | ☐ |

---

## UAT (Entra)

| Step | Portal / Place | What (token-only) | Done |
|------|-----------------|-------------------|------|
| 1.1–1.5 | Entra | App registration UAT; SPA URIs; permissions; optional claims (email, preferred_username); oid in token; optional API scope | ☐ |
| 1.8 | Entra | Assign users/groups to app | ☐ |
| 2.1 | Backend | UseAuthentication() enabled | ☐ |
| 2.2 | Backend | EnableAzureAuth = true; AzureAd = UAT tenant + SPA client ID | ☐ |
| 2.3 | DB | SupportUsers, PlatformAdmins (EntraObjectId); same schema as Dev; no User table | ☐ |
| 2.4–2.8 | Backend | ICurrentUserService from token; /auth/me; workspace from token email; Support/ADM from DB by oid | ☐ |
| 3.1 | Frontend | environment.uat: apiUrl UAT, enableAzureAuth true, redirectUri = UAT SWA URL, clientId UAT | ☐ |
| 3.2–3.5 | Frontend | Same as Dev (/auth/me, no forUser, audit, guards) | ☐ |

---

## Production (Entra)

| Step | Portal / Place | What (token-only) | Done |
|------|-----------------|-------------------|------|
| 1.1–1.8 | Entra | Same as UAT but **Prod** app registration and **Prod** redirect URI | ☐ |
| 2.2 | Backend | EnableAzureAuth = true; AzureAd = **Prod** tenant + **Prod** SPA client ID | ☐ |
| 2.3 | DB | SupportUsers, PlatformAdmins (same schema as UAT); no User table | ☐ |
| 2.4–2.8 | Backend | Same code as UAT; config differs per env | ☐ |
| 3.1 | Frontend | environment.production: apiUrl **Prod**, redirectUri **Prod**, clientId **Prod** | ☐ |
| 3.2–3.5 | Frontend | Same as UAT | ☐ |

---

## Cross-cutting checks

- [ ] Entra redirect URIs **exactly** match frontend origins (including trailing slash or not) for each env.
- [ ] Backend **AzureAd.ClientId** (or Audience) = SPA client ID for **that** env.
- [ ] DB schema: SupportUsers, PlatformAdmins (EntraObjectId only); **no User table**; same across envs. Only data (which oids are Support/Admin) differs.
- [ ] No hardcoded env-specific values in code (e.g. no UAT URL in production build).
- [ ] **Email-change script** is documented and available (Phase 4); run when a user’s email changes in Entra.

---

## Check before moving to Phase 6

Do **not** start Phase 6 until every item below is done.

- [ ] **Dev:** Checklist above ticked for Dev (or N/A where you don’t use Entra in dev).
- [ ] **UAT:** Checklist above ticked for UAT (Entra app, backend config, DB, frontend env).
- [ ] **Prod:** Checklist above ticked for Prod (or marked “done at go-live”).
- [ ] Cross-cutting checks above are satisfied.
- [ ] **Verification:** You can run through login and workspace list in at least one environment (e.g. UAT) end-to-end without errors.

When all are checked, proceed to [Phase 6 — Validation (token-only)](SAKURA_ENTRA_ROADMAP_PHASE_06_VALIDATION_TOKEN_ONLY.md).
