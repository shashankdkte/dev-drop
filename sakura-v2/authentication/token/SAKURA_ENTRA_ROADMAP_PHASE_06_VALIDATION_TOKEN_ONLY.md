# Phase 6 — Validation and go-live (Token-only)

**Goal:** Smoke tests, email-change test (run script then verify), and a final “nothing missed” checklist so auth works flawlessly before go-live.

**Prerequisite:** Phase 5 complete ([Gate 5 → 6](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md#gate-5--6-after-phase-5)).

**Do not consider go-live complete until the [Check before go-live](#check-before-go-live) section is done.**

---

## Step 6.1 — Smoke tests per environment

Run these in **each** environment (at least UAT and Prod).

| Test | Expected (token-only) | Done |
|------|------------------------|------|
| Unauthenticated GET /api/workspaces | 401 (or redirect to login if challenge) | ☐ |
| Login (Entra or JWT) then GET /api/auth/me | 200; body has entraObjectId, email (from token), name, isSupport, isPlatformAdmin | ☐ |
| GET /api/workspaces with valid token | 200; list only workspaces where **token email** is in Owner/TechOwner/Approver (or all if Support) | ☐ |
| Support user GET /api/workspaces | 200; full list (user’s oid in SupportUsers) | ☐ |
| Non-admin POST create workspace | 403 if PlatformAdmins enforced | ☐ |
| Frontend: after login, workspace list loads | No hardcoded forUser; list matches backend | ☐ |
| Frontend: create/delete object | createdBy/deletedBy = current user email (from token / auth/me) | ☐ |
| **Email change:** run script (old email → new email), then re-login with new email | Workspace list and approvals still correct; no User table to update | ☐ |

---

## Step 6.2 — Quick “nothing missed” checklist (token-only)

- [ ] Entra redirect URIs match frontend origins **exactly** (including trailing slash or not).
- [ ] Backend **AzureAd.ClientId** = SPA client ID (or audience) for that env.
- [ ] **UseAuthentication()** is called before **UseAuthorization()**.
- [ ] **No User table**; identity from **token only** (oid + email from claims).
- [ ] **ICurrentUserService** exposes **EntraObjectId** (oid), **Email (from token)**, Name (from token).
- [ ] No **forUser** sent from frontend; backend uses ICurrentUserService only.
- [ ] **Support** and **Platform Admin** in DB tables (SupportUsers, PlatformAdmins); keyed by **EntraObjectId** (oid) only.
- [ ] All env files have correct apiUrl, clientId, redirectUri for that env.
- [ ] **Email-change script** exists and is documented; run when a user’s email changes in Entra (updates Workspaces, approvers, CreatedBy, etc.).
- [ ] **Session:** No server-side session store; frontend holds access token and sends it on every request; optional refresh and logout revoke (see SAKURA_AUTH_FLOW_REFERENCE.md).

---

## Step 6.3 — Go-live readiness

| Item | Done |
|------|------|
| Smoke tests (6.1) passed in target environment(s) | ☐ |
| “Nothing missed” checklist (6.2) complete | ☐ |
| Email-change test: script run + re-login verified (optional but recommended) | ☐ |
| Rollback plan documented (e.g. revert config, feature flags) | ☐ |
| Support/Platform Admin list for Prod agreed and populated (by oid) | ☐ |

---

## Check before go-live

Do **not** consider go-live complete until every item below is done.

- [ ] All Phase 6 smoke tests (6.1) pass in the environment(s) you are releasing to.
- [ ] The “nothing missed” checklist (6.2) is fully ticked.
- [ ] Email-change test: run the script (old email → new email), re-login with new email, confirm workspace list and approvals are still correct.
- [ ] Go-live readiness (6.3) is satisfied (rollback plan, Support/Admin list for Prod).

When all are checked, auth is ready for go-live. For ongoing reference, use [SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md](SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md) and [SAKURA_AUTH_FLOW_REFERENCE.md](SAKURA_AUTH_FLOW_REFERENCE.md).
