# Video Script: Assign & Reassign RLS Approvers (Dimension-Based)

Use this outline to record a clear, practical video that covers both **assigning** and **reassigning** RLS approvers based on dimension checks, with a short theory section from the docs.

---

## Part 1 — Short theory (from docs)

**What to say (1–2 minutes):**

- **Row-Level Security (RLS) approvers** control who can approve permission requests for **specific security dimensions** (e.g. Organization + Service Line + Client).
- Each assignment is tied to a **dimension combination**: Security Model, Security Type, and then workspace-specific dimensions (e.g. for **CDI with “Client Data Insights”**: Organization level, Service Line, Client).
- The system matches approvers by **full dimension**: same EntityKey, EntityHierarchy, and any other required keys (e.g. Service Line, Client). If dimensions don’t match exactly (e.g. PA key/hierarchy), you can see a “dimension mismatch” — see `Docs\RLS_PA_DIMENSION_MISMATCH_WHY.md` for why a row might show empty `pakey`/`pahierarchy` (stale cache vs backend/DB).
- **Why this matters for the video:** Assign and reassign only affect the **exact dimension combination** you choose; the UI helps you build that combination and shows when existing approvers are found for it.

---

## Part 2 — Assigning an RLS approver (step-by-step)

**Goal:** Show how to assign approvers for a **new** dimension combination, and how dimension check + pre-population work.

1. **Open the Assign flow**
   - Go to WSO Console → Approver Assignments (or equivalent).
   - Either:
     - Click **“Assign RLS Approver”** (top) for a brand-new assignment, or  
     - Click **“Assign”** on a row that has **no approver yet** (same modal opens with dimension pre-filled).

2. **Select Security Model & Security Type**
   - **Security Model\***: e.g. “CDI-Default (CDI-Default)”.
   - **Security Type\***: e.g. “Client Data Insights”.
   - Mention: required dimensions depend on **workspace type** and **security type** (e.g. CDI + Client Data Insights → Organization, Service Line, Client).

3. **Build the dimension combination (dimension check)**
   - Point out the **help text** (e.g. red-bordered / info box):  
     *“For CDI workspace with security type 'Client Data Insights', please select: Organization (Market/Cluster/Region), Service Line, Client.”*
   - **Two ways to build dimensions:**
     - **Step-by-step wizard:** Check “Use Step-by-Step Wizard” and follow steps (Organization Level → Entity → Service Line → Client, etc.).
     - **Traditional form:** Fill Organization Level, then Entity/Market, Service Line, Client as shown.
   - Show **Dimensions info** (EntityKey / EntityHierarchy, etc.) updating as you select — this is the “dimension check” in the UI.

4. **When the dimension is ready**
   - Once all required fields are set, the UI runs a **dimension check** against existing RLS approvers:
     - If a match exists: **“X existing approver(s) found — pre-populated below”** and the **RLS Approver** field is filled.
     - If no match: **“No approver assigned yet for this dimension”** and the field stays empty.
   - Say: *“So we’re assigning (or reassigning in place) for this exact dimension combination; the system tells us if someone is already assigned.”*

5. **Enter approvers and submit**
   - **RLS Approver\***: Enter up to 10 emails (semicolon or comma). If existing approvers were pre-populated, you can edit (add/remove) — that’s effectively a reassignment in the Assign flow.
   - **Reason for Assignment (optional)**.
   - Click **Assign** (or equivalent). Confirm success message.

**Takeaway:** Assign = pick model + type + full dimension → dimension check shows existing approvers → enter or edit emails → save.

---

## Part 2b — Workspace examples (CDI, WFI, GI, AMER)

Use these when recording to show **one example per workspace** so viewers see how dimensions differ by type.

| Workspace | Security type (example) | Required dimensions | Example RLS assignment |
|-----------|--------------------------|---------------------|------------------------|
| **CDI** | Client Data Insights | Organization (Market/Cluster/Region), Service Line, Client | Model: CDI-Default → Type: Client Data Insights → Org: **Americas** (Region) → Service Line: **Overall** → Client: **All Clients** → Approvers: e.g. `user@dentsu.com` |
| **WFI** | (single type) | Organization level, People Aggregator type + People Aggregator | Model: WFI-Default → Org: **Global** → PA type: **Business Functions** → PA: **Business Operations** → Approvers: e.g. `lee.mann@dentsu.com` |
| **GI** | (single type) | Organization, Service Line, Client, Master Service Set (MSS) | Model: GI-Default → Org: **India** (Market) → SL: **Overall** → Client: **All Clients** → MSS: **Overall** (L0) → Approvers: e.g. `kartik.Iyer@dentsu.com` |
| **AMER** | Orga (or PA, Client, CC, MSS, PC) | Organization, Service Line (and others by type) | Model: AMER-Default → Type: Orga → Org: **LATAM** (Cluster) → Service Line: **CRTV** → Approvers: e.g. `Desiree.Benson@dentsu.com` |

**What to show in the video:**

- **CDI:** After choosing Security Model + “Client Data Insights”, the help text says: *“please select: Organization (Market/Cluster/Region), Service Line, Client.”* Build e.g. Region = Americas, SL = Overall, Client = All Clients → dimension ready → enter approvers.
- **WFI:** Only Organization + People Aggregator. Choose Org level (e.g. Global), then **People Aggregator type** (Business Areas or Business Functions), then the specific **People Aggregator** (e.g. Business Operations). No Service Line or Client.
- **GI:** Four dimensions: Organization (e.g. Market = India), Service Line (e.g. Overall), Client (e.g. All Clients), **MSS** (e.g. Overall / L0). Show wizard or form filling all four.
- **AMER:** Security type changes required dimensions (Orga = Entity + Service Line; Client = Entity + SL + Client; CC = Entity + SL + Cost Center; etc.). Show one type (e.g. Orga): Cluster = LATAM, Service Line = CRTV → assign approvers.

**Tip:** Record one full Assign flow for CDI, then short clips for WFI, GI, and AMER showing only the dimension fields and one example combination each, so the video stays easy to follow.

---

## Part 3 — Reassigning an existing RLS approver

**Goal:** Show the dedicated Reassign flow when a dimension **already has** an approver.

1. **Open Reassign from the grid**
   - In the approver assignments table, find a row that **already has** an approver.
   - Click **“Reassign”** (not “Assign”).

2. **Reassign modal**
   - Title: **“Reassign RLS approver”**.
   - **Dimension is read-only**: Security model and all dimension fields (e.g. Organization, Service Line, Client) are shown but not editable — so you’re clearly changing approvers for **that** dimension only.
   - **RLS approver(s)** field is **pre-populated** with current approvers (up to 10).
   - Edit the list (add/remove emails), optionally add a reason, then submit **Reassign**.

3. **Optional: same result via Assign modal**
   - You can also open **“Assign RLS Approver”** and, by selecting the **same** Security Model, Security Type, and dimension combination, get the same dimension check and pre-populated approvers; editing and saving here also **reassigns** for that dimension. So: *“Reassign is the shortcut when you’re already on the row; Assign is when you start from scratch or from a row without an approver.”*

**Takeaway:** Reassign = same dimension, change who approves; the UI keeps dimensions fixed and only lets you change approvers.

---

## Part 4 — How this is helpful (summary)

- **Dimension check** avoids duplicate or conflicting assignments: you see exactly which dimension you’re editing and whether it already has approvers.
- **Pre-population** makes reassignment fast and reduces mistakes: open Reassign or build the same dimension in Assign and the current approvers appear.
- **Theory from docs** (RLS, dimensions, mismatch note) explains *why* we must match full dimensions and where empty PA/dimension issues can come from.

---

## Checklist before recording

- [ ] Workspace and Security Model selected so at least one of **CDI, WFI, GI, AMER** is available with a Security Type (e.g. CDI: “Client Data Insights”).
- [ ] One dimension combination **with** an existing approver (to show Reassign + pre-population).
- [ ] One dimension combination **without** an approver (to show “No approver assigned yet” and new assignment).
- [ ] Optional: prepare one example per workspace (CDI, WFI, GI, AMER) as in **Part 2b** above.
- [ ] Optional: have `Docs\RLS_PA_DIMENSION_MISMATCH_WHY.md` open to reference if you mention dimension mismatch.
- [ ] Optional: use `Docs\RLS_APPROVER_ASSIGN_REASSIGN_GUIDE.md` (diagrams + definitions) to introduce the flow before the demo.

---

## Doc references

- **Dimension mismatch (empty row PA):** `Docs\RLS_PA_DIMENSION_MISMATCH_WHY.md`
- **Quick reference (diagrams + definitions):** `Docs\RLS_APPROVER_ASSIGN_REASSIGN_GUIDE.md`
- **Approver assignment UI:** WSO Console → Approver Assignments; Assign modal and Reassign modal in `FE\...\wso-approver-assignments\`.
