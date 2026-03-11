# Supplier & Stakeholder Industry Hierarchy — What, Why, How & Pipeline

**Purpose**: Single reference for the Industry Hierarchy (GICS + custom) and related mappings/overrides: what each piece is, why it exists, how it works, and a detailed pipeline view (where data comes from, which layer, how it flows, how it is consumed).

---

# Part 1 — What, Why, How (Each Component)

---

## 1. Industry Hierarchy (GICS + Custom)

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | A single master of industry classification with four levels (GICS 1–4: Sector → Industry Group → Industry → Sub-Industry), plus custom/manual nodes. Each node has **Source** (Semarchy or Manual), **Level**, and **Parent–Child** relationship. | Procurement needs one agreed industry structure for spend classification. GICS alone is not granular enough; teams were using ad‑hoc hierarchies. A single master avoids duplication and inconsistency. | A **new Ronin page** shows a grid filtered by **Level (GICS)**. **Parent** = value from the level above; **Child** = value at selected level. **Source** = Semarchy (read-only) or Manual (editable). Users add manual nodes at any level; "Short cut to add to Hierarchy" adds new nodes. Only **Manual** rows are editable. |
| **Why** | To unify GICS (from Semarchy) and procurement’s custom levels in one place, so reporting and mapping use the same hierarchy. | So procurement doesn’t revert to external tools and so override logic (stakeholder → vendor → invoice) has one reference hierarchy. | Semarchy data is imported into the hierarchy table; manual entries are stored with Source = Manual. Parent–child is enforced so roll-ups and dropdowns stay consistent. |
| **How** | Data: **Synapse_Staging.IndustryHierarchy** (and downstream **synapse.IndustryHierarchyEnhancements** / **V_IndustryHierarchyEnhancements**). UI: level dropdown + Parent/Child/Source grid; drill-through for selection. | — | Stored procedure loads staging → enhancement table; view exposes the hierarchy for Ronin UI and reporting. |

---

## 2. Dentsu Stakeholder → Industry (Stakeholder Mapping)

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | Each **Dentsu Stakeholder** has a **default industry** (from Client Master) and an optional **Override GICS**. The effective value is **Stakeholder Industry** = Override if set, else default from Client Master. | Stakeholders are the logical “who” for industry; client-level GICS needs to be available at stakeholder level for vendor/client mapping and reporting. | **Stakeholder map** page: columns **Dentsu Stakeholder Name**, **Override GICS**, **Industry from CM**, **Stakeholder Industry**, **Industry level**. User can drill through GICS (Sub-Industry → … → Sector) to set override. |
| **Why** | So vendor and client mapping can start from “stakeholder’s industry” when no override exists, and so procurement can correct misclassification at stakeholder level. | Default from Client Master keeps alignment with MDM; override allows exceptions without changing source systems. | Default comes from Client Master feed (Semarchy); override is stored in Ronin and applied in reporting logic. |
| **How** | **Modify** existing “Stakeholder map” view: add **Override GICS** and derive **Stakeholder Industry** (override else default). Data likely in enhancement/stakeholder tables; override column may be new or repurposed. | — | UI reads from enhancement views; save writes override to Ronin DB; reporting uses “override else default” when resolving stakeholder industry. |

---

## 3. Client → Industry (Client Mapping & Override)

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | Each **client** has a **default industry** from Client Master (Semarchy) and an optional **Override GICS**. Scenarios cover: mastered vs not mastered; has CMIndustry / source industry or not; manual map at Level 4, 3, 2, or 1; or no manual map but stakeholder mapped. | Clients need correct industry for procurement reporting. Some clients are not in Client Master or have wrong/missing industry; override fixes that in Ronin. | **Clients to map** page: **ClientDesc**, **MCId**, **Dentsu Stakeholder**, **MapSource**, **Source System**, **Override GICS**, **CMIndustry**, **Source Industry**, **Stakeholder Industry**. Override chosen via same GICS drill-through. |
| **Why** | To support all eight scenarios (mastered/not, with/without source industry, manual map at any level or none) without blocking on Client Master fixes. | Delivers “default from Semarchy + override in Ronin” quickly so procurement can classify correctly. | Default from Client Master feed; override stored in Ronin; reporting uses override when present. |
| **How** | **Modify** existing “Clients to map” view: add/expose **Override GICS** and ensure **MapSource** (System vs User) is clear. Data in client enhancement / mapping tables. | — | Same pattern as stakeholder: read from views, write override to Ronin, apply in reporting. |

---

## 4. Vendor → Industry (Vendor Mapping & Override)

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | Each **vendor** has a **default** industry (from client mapping if vendor is also client, or from **Stakeholder Industry** if stakeholder is mapped) and an optional **Override**. Effective value is **Supplier Industry** = Override if set, else default. **Level** and **Sector** describe the chosen industry. | Vendors are the main entity for procurement spend; they need one “supplier industry” per vendor, with ability to override when default is wrong. | **Vendor to map** page: **Vendor Code/Name**, **Stakeholder Industry**, **Override**, **Supplier Industry**, **Level**, **Sector**. Five scenarios: (1) vendor also client + industry from client; (2) only stakeholder mapped; (3) user override; (4) manual to GICS; (5) manual to other industry. Drill-through + “Short cut to add to Hierarchy.” |
| **Why** | So procurement reporting can classify spend by vendor industry, with a single place to correct defaults. | Large vendor list and slow load are existing issues; requirement is to add override without making the screen slower (e.g. 3–5 sec load). | Default resolved from client/stakeholder mapping; override stored in Ronin; vendor enhancement table(s) hold Override and derived Supplier Industry. |
| **How** | **Modify** existing “Vendor to map” view: add **Override** and **Supplier Industry** (and Level/Sector if not already there). Data in vendor enhancement tables. | — | Same as stakeholder/client: read from views, write override, reporting uses override else default. |

---

## 5. Invoice-Level Override

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | A **new table and page** to assign a GICS (or custom) industry to a **specific invoice**, so one supplier can have different industries for different invoices. Fields: **Dentsu Stakeholder**, **Supplier**, **Invoice Number**, **Entity**, **GIC1/2/3/4** (select at any level, not only lowest). | Some spend is classified correctly only at invoice level (e.g. same vendor, different services). Override at vendor level would be wrong for other invoices. | **New** “Vendor Invoice” page: same context as vendor mapping plus **Invoice No.**, **Entity**, **GIC1/2/3/4** dropdown. Row-by-row add; validation on invoice number (exact mechanism TBD). |
| **Why** | To allow “override at invoice level” so reporting can use the most granular correct classification when it exists. | Requirement 5.5 and 5.6: invoice-level override table and reporting rule “use invoice override if exists, else default.” | New **Industry Override** table keyed by supplier + invoice + entity (and possibly market/cluster/region); Created By / Timestamp for audit. |
| **How** | New table (e.g. **InvoiceIndustryOverride** or similar) in Ronin DB; new page in Ronin UI; reporting joins to this table first when resolving industry for an invoice. | — | Pipeline: Ronin UI writes to this table; no external feed. Reporting reads this table first, then falls back to vendor default then stakeholder default. |

---

## 6. Reporting Logic (How Industry Is Consumed)

| | **What** | **Why** | **How** |
|---|----------|---------|--------|
| **What** | A single rule for “which industry to use” in procurement reports: (1) If **invoice-level override** exists for that invoice → use it. (2) Else use **vendor default** (Supplier Industry, which already applies override else stakeholder/client default). | So every spend line has one consistent industry for reporting and so overrides are respected in order: invoice > vendor > stakeholder/client. | Implemented in the **reporting view or semantic model**: resolve industry by joining to invoice override first, then to vendor enhancement (Supplier Industry), then to stakeholder/client default as fallback. |
| **Why** | To avoid conflicting logic across reports and to make override behaviour predictable. | Requirement 5.6 and objective 4: “Use override Industry if available else default industry.” | Same logic in one place (view or DAX/query); all procurement reports use that definition. |
| **How** | Consumption: Power BI / semantic model and any Ronin reports that show industry. Data comes from enhancement views + override table, not directly from staging. | — | See Part 2 pipeline: reporting layer reads from **synapse** (and possibly **dbo**/views), not from staging. |

---

## 7. Summary of “Modify” vs “New”

| Type | Page / Area | What changes |
|------|-------------|--------------|
| **Modify** | Clients to map | Map clients to stakeholder and industry; add **Override GICS**; show default vs override if required. |
| **Modify** | Vendor to map | Map vendors to stakeholder; add **Override** and **Supplier Industry**; fast search/filter. |
| **Modify** | Stakeholder map | Map stakeholder to industry; add **Override GICS** and **Stakeholder Industry** logic. |
| **New** | Industry Hierarchy | New page: GICS + custom hierarchy; add/edit manual nodes; Parent/Child/Source grid; drill-through. |
| **New** | Vendor Invoice | New page + table: invoice-level override (Supplier, Invoice No., Entity, GIC1/2/3/4). |

---

# Part 2 — Pipeline: What We Are Trying to Achieve, How, Which Layer, Where Data Comes From, Where It Goes, How It Is Consumed

---

## 2.1 What We Are Trying to Achieve (Pipeline Perspective)

- **Industry hierarchy**  
  - One authoritative GICS + custom hierarchy in Ronin.  
  - Source of truth for dropdowns and roll-ups; Semarchy = read-only, Manual = editable in Ronin.

- **Stakeholder / Client / Vendor industry**  
  - Default industry from Client Master (Semarchy) where available.  
  - Override stored in Ronin and applied in this order: **Stakeholder → Client/Vendor mapping → Supplier Industry.**

- **Invoice-level override**  
  - Per-invoice industry override stored in Ronin; no external feed.

- **Reporting**  
  - Single resolution order: **Invoice override → Vendor (Supplier Industry) → default (stakeholder/client).**  
  - All procurement reports consume this resolved industry.

---

## 2.2 How We Are Trying to Achieve It (High-Level Flow)

1. **Hierarchy master**  
   - Semarchy (and/or CPS) → ETL → **Staging** → **Stored procedure** → **Enhancement table** → **View**.  
   - Ronin UI reads from the view; manual adds/edits write back to Ronin DB (tables that feed the same view or a dedicated override/hierarchy table).

2. **Stakeholder / Client / Vendor**  
   - Default: from Client Master feed (already in Ronin or coming via existing pipelines).  
   - Override: Ronin UI writes to **enhancement** or **operational** tables; no separate “industry” ETL from external source for overrides.

3. **Invoice override**  
   - Ronin UI only; new table; no external pipeline.

4. **Reporting**  
   - Views (and/or semantic model) join enhancement tables + invoice override table and apply the resolution rule.

---

## 2.3 Layers and Where Each Piece Lives

Ronin’s existing pattern:

- **Staging** (`Core_Staging`, `Synapse_Staging`): landing from external systems; temporary; not for reporting.
- **Core**: master data truth (e.g. Client, Account, Entity).
- **Synapse (enhancement)**: enhanced/dimensional data (e.g. client/vendor/stakeholder enhancements).
- **dbo**: operational tables (transactions, mappings).
- **Views**: curated reporting views (e.g. `synapse.V_IndustryHierarchyEnhancements`).

For Industry Hierarchy and related mappings:

| Component | Staging | Core | Synapse (enhancement) | dbo / other | Views |
|-----------|---------|------|------------------------|-------------|-------|
| **Industry hierarchy master** | `Synapse_Staging.IndustryHierarchy` (landing from Semarchy/ETL) | — | `synapse.IndustryHierarchyEnhancements` (after sp_Load_*) | Manual adds may be in dbo/mdm or in a table that merges with enhancement | `synapse.V_IndustryHierarchyEnhancements` |
| **Stakeholder override** | — | — | Stakeholder enhancement table(s) (override column) | — | View(s) exposing Stakeholder Industry |
| **Client override** | — | — | Client enhancement table(s) (Override GICS column) | — | View(s) exposing client industry |
| **Vendor override** | — | — | Vendor enhancement table(s) (Override, Supplier Industry) | — | View(s) exposing Supplier Industry |
| **Invoice-level override** | — | — | — | New table (e.g. dbo or Synapse) | View joining invoice + override |

So:

- **Staging** = where **external** industry hierarchy data lands (e.g. Semarchy).  
- **Enhancement** = where the **master hierarchy** and **default/override** industry for stakeholder/client/vendor live.  
- **dbo (or similar)** = where **invoice-level override** and possibly **manual hierarchy** rows live.  
- **Views** = what reporting and Ronin UI use.

---

## 2.4 Where Is It Coming From? (Sources)

| Data | Source system / origin | How it reaches Ronin |
|------|------------------------|----------------------|
| **GICS hierarchy (standard)** | Semarchy (e.g. `[Global_MDM].[PrimaryIndustries]`) or CPS | Existing or new ETL pipeline → **Synapse_Staging** (e.g. `IndustryHierarchy`) |
| **Client Master industry** | Salesforce, CPS, Semarchy | Already in Ronin via existing Client Master / UMS-type pipelines; used as “default” industry for client/stakeholder |
| **Manual hierarchy nodes** | User entry in Ronin | Ronin UI → Ronin DB (no external pipeline) |
| **Stakeholder / Client / Vendor overrides** | User entry in Ronin | Ronin UI → enhancement (or dbo) tables |
| **Invoice-level override** | User entry in Ronin | Ronin UI → new override table |

So:

- **From pipeline**: only the **standard GICS hierarchy** (and any Client Master industry already fed by existing pipelines).  
- **Not from pipeline**: manual hierarchy, all overrides (stakeholder, client, vendor, invoice).

---

## 2.5 Pipeline: Where Data Goes Through (Step-by-Step)

### A. Industry hierarchy (GICS from Semarchy)

```
Source (Semarchy / CPS)
  → ETL (e.g. ADF / gapteq data transfer)
  → Synapse_Staging.IndustryHierarchy
  → Stored procedure (e.g. sp_Load_IndustryHierarchy or similar)
  → synapse.IndustryHierarchyEnhancements
  → synapse.V_IndustryHierarchyEnhancements (view)
```

- **Staging** holds raw rows (e.g. DentsuStakeholderCode, DentsuStakeholderDesc, GICS01–GICS04 or equivalent).  
- **Procedure** does transform/merge and possibly combines with **manual** hierarchy rows (if manual is stored in another table and merged into the same enhancement table or view).  
- **View** is what Ronin UI and reporting use for hierarchy dropdowns and parent–child display.

### B. Manual hierarchy additions (Ronin)

```
User adds/edits in Ronin UI
  → Ronin app writes to Ronin DB
  → Target: table that either (1) feeds the same Synapse enhancement table, or (2) is combined in the view with synapse.IndustryHierarchyEnhancements
  → Same view: synapse.V_IndustryHierarchyEnhancements
```

So “pipeline” for manual = **Ronin UI → DB → view**; no ADF/staging step.

### C. Stakeholder / Client / Vendor default and override

- **Default**: Already in Ronin from Client Master / Semarchy pipelines (existing flows into Core or Synapse). No new pipeline needed for “source” of default; only we **use** that data as default.  
- **Override**: Ronin UI → **enhancement** (or dbo) tables; no external pipeline.  
- **Vendor “Supplier Industry”**: Resolved in view or in app: override if present, else default from client/stakeholder mapping.

So for overrides, “pipeline” is **Ronin UI → Ronin DB → views**.

### D. Invoice-level override

```
User adds row in Ronin (Vendor Invoice page)
  → Ronin app writes to new table (e.g. InvoiceIndustryOverride)
  → Reporting view joins: fact/transaction table + InvoiceIndustryOverride (by supplier, invoice, entity)
  → If row exists → use override GICS; else use vendor Supplier Industry
```

No external pipeline; only **Ronin UI → new table → reporting view**.

### E. Fabric (if Ronin DB is mirrored/synced to Fabric)

If the **Fabric database** is fed **from** Ronin (e.g. Synapse → Fabric):

- **Source**: Ronin DB (e.g. `synapse.IndustryHierarchyEnhancements`, `synapse.V_IndustryHierarchyEnhancements`, and other enhancement/override tables/views).  
- **Flow**: Extract from Ronin (e.g. ADF or Fabric pipeline) → Fabric database (mirror or subset of tables/views).  
- **Consumption**: Reports in Fabric / Power BI that use Fabric as source would then get hierarchy and overrides from Fabric, not directly from Ronin.  

So “Fabric pipeline” = **Ronin (views/tables) → ADF/Fabric pipeline → Fabric DB → Fabric/Power BI reports**.  
If instead Fabric is the **source** of GICS and we load **into** Ronin, then the direction is reversed for that part only (Fabric → Ronin staging → procedure → enhancement → view).

---

## 2.6 How It Will Be Consumed

| Consumer | What they use | Where it comes from (layer) |
|----------|----------------|-----------------------------|
| **Ronin UI – Industry Hierarchy page** | Full hierarchy (Parent/Child/Source by level) | `synapse.V_IndustryHierarchyEnhancements` (or equivalent view) |
| **Ronin UI – Stakeholder map** | Stakeholder list + Override GICS + Industry from CM + Stakeholder Industry | Enhancement views (stakeholder + client master + hierarchy view) |
| **Ronin UI – Clients to map** | Client list + Override GICS + CMIndustry + Source/Stakeholder industry | Enhancement views (client + hierarchy view) |
| **Ronin UI – Vendor to map** | Vendor list + Stakeholder Industry + Override + Supplier Industry + Level/Sector | Enhancement views (vendor + hierarchy view) |
| **Ronin UI – Vendor Invoice (invoice override)** | Override table (Supplier, Invoice, Entity, GIC1–4) | New override table + hierarchy view for dropdowns |
| **Procurement reports (Power BI / semantic model)** | Resolved industry per transaction/invoice | Reporting view that implements: invoice override → Supplier Industry → default (stakeholder/client) |
| **Fabric / external reports** | Same resolved industry if Fabric is fed from Ronin | Fabric tables/views that were loaded from Ronin views/tables |

So:

- **UI** consumes **views** (and writes to **tables**) in Ronin.  
- **Reporting** consumes a **view** (or semantic model built on that view) that implements the override rule.  
- **Fabric** consumes **Ronin views/tables** via the Fabric ingestion pipeline, if applicable.

---

## 2.7 One-Page Pipeline Picture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ SOURCES                                                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│ Semarchy / CPS (GICS)  ──► ETL ──► Synapse_Staging.IndustryHierarchy             │
│ Client Master (industry)  already in Ronin (existing pipelines)                  │
│ Manual hierarchy / overrides  ──► Ronin UI ──► Ronin DB (no ETL)                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ RONIN DB LAYERS                                                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│ Staging:     Synapse_Staging.IndustryHierarchy                                   │
│             (only for Semarchy-sourced hierarchy)                                │
│                        │                                                         │
│                        ▼ sp_Load_*                                               │
│ Enhancement: synapse.IndustryHierarchyEnhancements                                │
│              + stakeholder/client/vendor enhancement tables (override columns)   │
│                        │                                                         │
│ Operational: New table: InvoiceIndustryOverride (or similar)                     │
│                        │                                                         │
│                        ▼                                                         │
│ Views:       synapse.V_IndustryHierarchyEnhancements  (hierarchy for UI/report)  │
│              + views exposing Stakeholder/Client/Vendor industry + override      │
│              + reporting view: resolved industry (invoice → vendor → default)   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ CONSUMPTION                                                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│ Ronin UI:   Industry Hierarchy page, Stakeholder map, Clients to map,            │
│             Vendor to map, Vendor Invoice page  (read from views; write to tables)│
│ Reporting:  Power BI / semantic model  (resolved industry from view)             │
│ Fabric:     If applicable: pipeline Ronin → Fabric DB → Fabric/PBI reports       │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2.8 Checklist for Implementation (Pipeline-Related)

- [ ] **Naming**: Confirm naming for staging table, enhancement table, view, and procedure (e.g. `IndustryHierarchy`, `IndustryHierarchyEnhancements`, `V_IndustryHierarchyEnhancements`, `sp_Load_IndustryHierarchy`).  
- [ ] **gapteq / ADF**: Add data transfer for Semarchy → `Synapse_Staging.IndustryHierarchy` (like other Synapse_Staging loads).  
- [ ] **Procedure**: Implement or extend stored procedure: staging → `synapse.IndustryHierarchyEnhancements`, and merge/combine with manual hierarchy if stored separately.  
- [ ] **View**: Expose `synapse.V_IndustryHierarchyEnhancements` for UI and reporting (parent–child by level, Source).  
- [ ] **Manual hierarchy**: Decide where manual rows are stored (same enhancement table vs separate table) and ensure view includes them with Source = Manual.  
- [ ] **Override columns**: Add Override GICS / Override / Supplier Industry to stakeholder, client, vendor enhancement tables; expose in views.  
- [ ] **Invoice override**: Create new table and view; wire reporting to “invoice override → vendor → default.”  
- [ ] **Fabric**: If Ronin feeds Fabric, add pipeline to copy required views/tables to Fabric and document direction (Ronin → Fabric).  
- [ ] **ADF02 / pipeline config**: Register new data object/transfer so the existing pipeline framework picks up the new hierarchy load without breaking existing jobs.

---

*Document version: 1.0 | Aligned with Ronin Mental Model and Senior Guide (staging → enhancement → views).*

---

# Simplest bullet points

## What / Why / How (one line each)

- **Industry Hierarchy**
  - What: One master of industry (GICS 1–4 + manual), with Parent, Child, Source (Semarchy or Manual).
  - Why: So procurement has one agreed structure; GICS alone wasn’t enough.
  - How: New Ronin page: pick level, see Parent/Child/Source; only Manual rows editable; "Short cut to add to Hierarchy."

- **Stakeholder → Industry**
  - What: Each stakeholder has default industry (from Client Master) + optional Override GICS; effective = override else default.
  - Why: So vendor/client mapping and reporting can use "stakeholder's industry."
  - How: Modify Stakeholder map page: add Override GICS; user drills through GICS to set it; reporting uses override else default.

- **Client → Industry**
  - What: Each client has default (Client Master) + optional Override GICS; many scenarios (mastered/not, manual at level 4/3/2/1).
  - Why: So clients have correct industry even when not in Client Master or wrong in source.
  - How: Modify Clients to map page: add Override GICS; same drill-through; reporting uses override when present.

- **Vendor → Industry**
  - What: Each vendor has default (from client or stakeholder) + optional Override; effective = Supplier Industry = override else default.
  - Why: So procurement can classify spend by vendor and fix wrong defaults.
  - How: Modify Vendor to map page: add Override and Supplier Industry; drill-through; fast search/filter (e.g. 3–5 sec load).

- **Invoice-level override**
  - What: New table + page: assign industry to a specific invoice (Supplier, Invoice No., Entity, GIC1–4) so one vendor can have many industries.
  - Why: Some spend is right only at invoice level.
  - How: New Ronin page writes to new table; no ETL; reporting checks this table first.

- **Reporting**
  - What: One rule: use invoice override if exists, else vendor Supplier Industry, else default (stakeholder/client).
  - Why: So every report uses the same industry and overrides are respected.
  - How: One view (or semantic model) that joins override table + vendor + default and applies this order.

## Modify vs New

- **Modify:** Clients to map (add Override GICS), Vendor to map (add Override, Supplier Industry), Stakeholder map (add Override GICS, Stakeholder Industry).
- **New:** Industry Hierarchy page (GICS + manual, Parent/Child/Source), Vendor Invoice page (invoice-level override table).

## Pipeline (simplest)

- **Where data comes from**
  - GICS hierarchy: Semarchy/CPS → ETL.
  - Client Master industry: already in Ronin (existing pipelines).
  - Manual hierarchy + all overrides: Ronin UI only (no ETL).

- **Where it goes**
  - Semarchy GICS: ETL → Synapse_Staging.IndustryHierarchy → sp_Load_* → synapse.IndustryHierarchyEnhancements → V_IndustryHierarchyEnhancements.
  - Manual hierarchy: Ronin UI → Ronin DB → same view (or table that feeds it).
  - Overrides (stakeholder/client/vendor): Ronin UI → enhancement tables.
  - Invoice override: Ronin UI → new table → reporting view.

- **Layers**
  - Staging = external data landing (Synapse_Staging.IndustryHierarchy).
  - Enhancement = hierarchy master + stakeholder/client/vendor overrides (synapse.*).
  - dbo (or similar) = invoice override table (+ maybe manual hierarchy).
  - Views = what UI and reporting read.

- **Who consumes**
  - Ronin UI: all five pages read from views, write to tables.
  - Reports: one view that resolves industry (invoice → vendor → default).
  - Fabric: if used, Ronin → pipeline → Fabric DB → Fabric/PBI.

## Order of resolution (reporting)

1. Invoice-level override (if row exists for that invoice).
2. Else Vendor Supplier Industry (override else default from client/stakeholder).
3. Else default from stakeholder/client mapping.
