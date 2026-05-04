# Domain RLS filter rules — business alignment matrix

**Purpose:** Single reference for **per-domain** behaviour on permission request / RLS assignment filters (organisation cascade, client, MSS, practice/service line, PC, CC, PA). Use this to keep product, engineering, and domain owners aligned.

**Status:** Living document. Items marked **Agreed**, **Target**, **Open (discussion)**, or **Validate with domains** should be confirmed in domain workshops and then updated here.

**Technical cross-reference (implementation, not source of truth for business):**

- `FE/application/src/app/domains/data-entry/data/permission-request-workspace-rls.config.ts` — default dimensions and entity hierarchy option lists per workspace type.
- `Docs/DOMAIN_SECURITY_MODEL_TYPE_AND_DIMENSIONS.md` — security type → dimension visibility.
- **Workspace aliases:** In code and DB, **CGI** (Client & Growth Insights) is often normalised to **`GI`**. **FDI** → **DFI**. **WFI_PROD** / **WFIPROD** → **WFI**.

---

## 1. Canonical domain list (this document)

| Domain code | Common name | Notes |
|-------------|-------------|--------|
| **DFI** | Dentsu Finance Insights | Security type **FUM** in app/config. |
| **EMEA** | Europe, Middle East & Africa | Includes regional Samurai-style workspaces that resolve to EMEA (e.g. custom workspace codes mapped via domain LoV). |
| **GI** / **CGI** | Growth / Client & Growth Insights | Same product bucket; use **GI** in code. |
| **WFI** | Workforce Information | Entity + People Aggregator path. |
| **AMER** | Americas | Security types drive which extra dimensions appear. |
| **CDI** | Client Data Insights | Tabular path: Entity + Client + Service line (types in DB may list more; UI visibility follows product rules). |

---

## 2. Organisation hierarchy and **BPC entity** filter

### 2.1 Intended cascade (when user drills organisation)

Geographic / org drill order (parent → child):

**Region → Cluster → Market → BPC entity → Entity**

For **DFI (FUM)** there is an additional **Country** path when organisation level is **Country** (stored as **N/A** in the entity hierarchy list — “geo” scope without a specific org node). See `FUM_DFI_ORGANIZATION_GEO_HELP` in config.

### 2.2 Rule: BPC entity as **parent** filter when level is **Entity**

**Target behaviour:** When **organisation level** is **Entity**, the **BPC entity** dimension acts as a **parent filter** (narrows which entities appear / are valid). Domains that need this must expose **BPCEntity** in the organisation level list and wire cascade logic accordingly.

| Domain | BPC entity in org level list (today in config) | Business decision on **BPC-as-parent when level = Entity** |
|--------|-----------------------------------------------|-------------------------------------------------------------|
| **DFI** | Yes (`ENTITY_HIERARCHY_OPTIONS` + **N/A**) | **Required** — implement / keep aligned. |
| **EMEA** | Yes | **Required** — implement / keep aligned. |
| **GI (CGI)** | **No** — BPC entity option stripped (`ENTITY_HIERARCHY_OPTIONS_GI`) | **Do not want** — **strong** business position: do **not** introduce BPC entity level for CGI. |
| **CDI** | Yes | **No discussion to date** — confirm with CDI whether parent BPC filter at Entity level is needed or neutral. |
| **AMER** | Yes | **Open — discussion** — decide with AMER owners. |
| **WFI** | Yes | **Open — discussion** — decide with WFI owners (workforce scope may differ). |

---

## 3. EMEA — Samurai / regional workspace **auto-lock** rules

These are **business UX rules** for specific EMEA entry points (workspace or branding may differ from code `EMEA`); behaviour should lock higher levels so users cannot pick outside the allowed geography.

| Entry / brand | Auto-selected scope | User must not change |
|---------------|---------------------|------------------------|
| **Samurai CE** (Central Europe) | **Cluster = Central Europe** only | No free **region** selection (only that cluster context). |
| **Samurai EMEA** | **Region = EMEA** | Auto **EMEA** region; **no** selection of other regions. |
| **Samurai Fr** (France) | **Cluster = France** | France cluster fixed; **no** other cluster/region selection. |

**Product note:** Custom workspace codes (e.g. historical **SAMURAICE**-style codes) already resolve to **EMEA** RLS config via domain LoV; auto-lock is an additional **constraint layer** per workspace/tenant configuration.

---

## 4. Client dropdown — **ultimate parent** only

**Agreed (all domains):** Client picker should list **ultimate parent clients** only, defined as clients that are either **mapped** as ultimate parent in reference data **or** meet an agreed threshold (stakeholder wording: **mapped or count > 2** — exact rule must be confirmed with data stewards and encoded in API/filter).

| Domain | Rule |
|--------|------|
| DFI, EMEA, GI, WFI, AMER, CDI | Same rule — **ultimate parent only** (no exception called out). |

---

## 5. Master Service Set (MSS)

| Topic | Owner / status |
|--------|----------------|
| **“Overall” appearing multiple times** | **Bug / UX** — confuses users; treat as **one** clear “all MSS” concept; recheck with **all** domains after fix. |
| **GI (CGI) — MSS list scope** | **Special requirement:** Show **only** MSS rows **applicable to CGI** (tenant/domain filter on reference or API). Other domains use standard MSS lists unless they add a row-level rule. |
| **Other MSS issues** | **Validate with domains** — any duplicate labels, wrong hierarchy defaults, or wrong combinations with entity/client. |

---

## 6. Profit center (PC)

**Status:** **Needs clarity from all domains** — confirm:

- When **All PCs** vs **BPC brand** vs **specific PC** is allowed per security type.
- Whether **client** is required together with PC (see AMER “Profit” path in `DOMAIN_SECURITY_MODEL_TYPE_AND_DIMENSIONS.md`).
- DFI/FUM PC behaviour vs finance reporting boundaries.

Document agreed outcomes in this section when workshops complete.

---

## 7. Practice / Service line

| Domain | Rule |
|--------|------|
| **GI (CGI)** | **Only** practices **inside “Total” practice** (total practice rollup) — no special cases called out for other rollup shapes. |
| **All other domains** | **No** additional special requirements stated beyond existing security-type visibility (CDI/AMER/EMEA service line, etc.). |

**Config note:** For GI, the UI label for service line is **“Practice”** (`slKey` / practice scope in `GI_DIMENSIONS`).

---

## 8. Cost center (CC)

**Action:** **Cross-check** with each domain that uses CC (**AMER**, **EMEA** on cost types, and any CDI flows that reference CC in DB) for:

- Valid hierarchy values (Business Unit, BPC Rollup, specific CC).
- Order of gates (entity + service line before CC where applicable).

Record exceptions in a table here after validation.

---

## 9. People Aggregator (PA)

**Action:** **Cross-check** with **WFI** and **AMER** (PA security type) for:

- Hierarchy options (**Business Areas** vs **Business Functions** vs **Overall** — see `WFI_DIMENSIONS` / AMER hidden PA options in config).
- Alignment between tabular permission request and WSO “Assign RLS approver” validation.

---

## 10. Quick matrix — dimension presence (tabular / default config)

High-level only; **security type** still narrows fields (see main RLS guide).

| Dimension | CDI | AMER | WFI | GI | DFI (FUM) | EMEA |
|-----------|-----|------|-----|-----|-----------|------|
| Organisation + level | Yes | Yes | Yes | Yes | Yes (+ **N/A** / Country path) | Yes |
| Country | No | No | No | No | Yes | Yes (type-dependent visibility) |
| Client | Yes | Yes* | No | Yes | Yes | Yes |
| MSS | —** | Yes* | No | Yes | Yes | Yes* |
| Practice / SL | Yes | Yes* | No | Yes (as **Practice**) | No | Yes* |
| PC | —** | Yes* | No | No | Yes | Yes* |
| CC | —** | Yes* | No | No | No | Yes* |
| PA | —** | Yes* | Yes | No | No | No |

\*Only when the selected **security type** requires that dimension (see `getRlsDimensionVisibilityFlags` / `DOMAIN_SECURITY_MODEL_TYPE_AND_DIMENSIONS.md`).

\**CDI config lists types including MSS/PC/CC in LoV defaults; current product note in docs: tabular CDI path may still show **Entity + Client + SL** only — confirm with CDI if types and UI must diverge.

---

## 11. Change log

| Date | Change |
|------|--------|
| 2026-05-04 | Initial matrix from domain workshop notes and alignment with Sakura FE config / domain docs. |

---

*Next step: domain owners to fill **§6 Profit center** and tick **§8 / §9** validation; product to close **§5** MSS “Overall” duplication and **§2.2** AMER/WFI/CDI decisions.*
