Yes — for **CE (`SAMURAI_CE`)**, the change was: **each audience gets an explicit allowed RLS security-type list**, and when the workspace flag is ON, the request wizard only shows those types (and the API rejects others).

---

### 1. DB changes

| Piece | What |
|--------|------|
| `dbo.Workspaces.AudienceSecurityTypeFilterEnabled` | BIT flag (default `0`). CE turn-on script: `07_enable_ce_audience_security_type_filter.sql` |
| `dbo.AppAudienceSecurityTypeMap` | New table: `AppAudienceId` + `SecurityTypeLoVId` (unique), temporal history |
| `romv.AppAudienceSecurityTypeMap` | Read view for the map |
| Seed `10_seed_ce_audience_security_types.sql` | Inserts **27** rows for app `CE-INSIGHTS` (types must already sit on `EMEA-Default`) |
| Verify `11_verify_ce_ols_seed.sql` | Expects filter ON + 27 map rows |

**CE audience → type rules (seed):**

| Audiences | Allowed types |
|-----------|----------------|
| `CE-GENERAL`, `CE-EXEC` | All model types: `EMEA-ORGA`, `EMEA-CLIENT`, `EMEA-CC`, `EMEA-COUNTRY`, `EMEA-MSS` (explicit rows, not “empty = all”) |
| `CE-CXM-CLIENT-LEAD`, `CE-MEDIA-CLIENT-LEAD` | `EMEA-CLIENT` only |
| `CE-COMM-FINANCE`, `CE-OPS`, `CE-FACILITIES`, `CE-TECH`, `CE-CENTRAL-MGMT` | `EMEA-ORGA` only |
| `CE-CREATIVE-LEAD`, `CE-CXM-LEAD`, `CE-MEDIA-LEAD`, `CE-AMPLIFI` | `EMEA-ORGA` + `EMEA-CLIENT` |

---

### 2. Backend endpoints

| Method | Route | Who / purpose |
|--------|--------|----------------|
| `GET` | `/api/workspaces/{id}/audience-security-types` | WSO read — list all maps in workspace |
| `GET` | `/api/workspaces/{id}/appaudiences/{audienceId}/securitytypes` | Any authenticated user — wizard filter (empty = no filter) |
| `PUT` | `/api/workspaces/{id}/appaudiences/{audienceId}/securitytypes` | WSO write — replace all allowed types for an audience |
| `PATCH` | `/api/workspaces/{id}/audienceSecurityTypeFilter` | Toggle workspace flag |

**Create-request validation** (`PermissionRequestService`): if flag is ON → security model required → type must be on model → (for report requests) model on report → if audience has map rows, type must be in that list. Empty map = no audience filter.

---

### 3. Frontend (code + behavior)

**Shared logic**

- `report-app-audience-security-type-filter.util.ts` — apply filter only when flag ON **and** audience has mapped type IDs; intersect options; sole-type auto-select; constrain EMEA inferred type to allowed codes.
- `ce-audience-security-type-expectations.ts` — E2E/unit contract matching the SQL seed.

**WSO admin**

- Workspace settings: enable/disable `AudienceSecurityTypeFilterEnabled`.
- Audience list: show “allowed security types”; edit dialog → `setAudienceSecurityTypes` PUT.

**Request UX** (wizard confirm RLS, request-form, request-form-scope, request-form-mini, permission-requests-entry)

- Load maps for selected audience.
- Narrow security-type dropdown to allowed IDs.
- EMEA path: hide client when audience is org-only; infer/constrain type (`EMEA-ORGA` / `EMEA-CLIENT`) from allowed list.

**API client**

- `workspace-report-domain.service.ts`: `listAudienceSecurityTypes`, `getAudienceSecurityTypes`, `setAudienceSecurityTypes`.
- Workspace DTO includes `audienceSecurityTypeFilterEnabled`.

---

### End-to-end flow (simple)

1. Flag ON for `SAMURAI_CE` + seed maps (27 rows).  
2. User picks report + audience in wizard.  
3. FE loads allowed types for that audience and filters the type picker (and EMEA client visibility).  
4. On submit, BE re-checks model + audience map and rejects a type that isn’t allowed.

If you want, I can next walk one Patrick CE case (e.g. Central Management vs CXM Leadership) step-by-step through wizard clicks.
