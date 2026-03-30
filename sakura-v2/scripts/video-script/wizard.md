# Sakura — Request Wizard (Guided & Advanced): Video Script + Production Timing

This pack is written for **end-to-end screen recording** with no live help. It matches the current Sakura V2 UI: **Request access (Guided)** (`/request-form`) and **Request access (Advanced)** (`/request-form-scope`, also reachable as `/request-access-advanced`).

**Terms (say once in the intro):**

- **OLS (object-level security)** — permission to see a **report** or **app audience** in the workspace.
- **RLS (row-level security)** — which **rows** of data you see (entity, client, service line, etc.), after you already have (or do not need) object access.

---

## Part 1 — Before you record

1. Use a **test account** with a known line manager in directory data.
2. Pick **two workspaces** in rehearsal: one where you have **no** existing RLS and one where you **do** (for “reuse existing RLS”).
3. In Guided mode, pick a report that is **not** a greyed-out **AUR** (“not linked to an app audience”).
4. Close extra browser tabs; zoom browser to **100%**; hide bookmarks bar if it steals vertical space.
5. **Microphone:** script is written for ~130–150 words/minute. Adjust pauses if you speak faster.

**On-screen text labels to use verbatim when pointing:**

- Dashboard cards: **Request access (Guided)** / **Request access (Advanced)**
- Guided step names: **What are you requesting?** → **Request details** → **RLS** → **Approver detection** → **Summarization** (progress bar text) / **Request summary** (page heading on step 5)
- Advanced step names: **Access scope selection** → **Request details** → **RLS** → **Approver detection** → **Review & Submit** (progress) / **Request summary** (heading)

---

## Part 2 — Master narration script (read in order)

### Segment 0 — Cold open (optional, 20–30 s)

“Hi, I’m walking through **Sakura**’s two ways to request access: the **Guided** wizard, which starts from a catalogue of reports and audiences, and the **Advanced** wizard, where you pick the workspace and object directly. I’ll show what each screen is for, what to do, what **not** to do, and a few real paths — including **RLS only**, when you already have report access and just need row-level filters.”

### Segment 1 — Open the wizards from the Dashboard (~45 s)

“After you sign in, you land on the **Dashboard**. At the top you’ll see two large cards.

“**Request access (Guided)** — subtitle says it’s a step-by-step wizard via the **report catalogue**. Use this if you’re new or you’re browsing for a report or audience by name.

“**Request access (Advanced)** — subtitle says **direct workspace and object selection**. Use this if you already know the workspace, app, audience, or report.

“What **not** to do: don’t assume both paths are identical — Advanced skips the catalogue and uses **tabs**: Workspace, App, Audience, Report.”

**[ACTION]** Scroll slightly so both cards are visible; hover each card without clicking yet.

### Segment 2 — Guided wizard: Step 1 “What are you requesting?” (~2 min)

“Open **Request access (Guided)**. The breadcrumb reads **Dashboard → Request access (Guided)**. You’ll see **Step 1 of 5** and a horizontal step tracker.

“First you choose **intent**:

“**Report or app audience access** — the normal path: you need OLS for a report or audience, and you may add or reuse RLS.

“**RLS only** — use this when you **already** have access to the reports you need and you only want to change **row-level** security in a workspace. The approval path is shorter: line manager, then RLS data owner — **no OLS step**.

“Turn **Show tips** on if you want short hints under the cards.

“**RLS only** path on this step: after you select it, choose the **workspace** from the dropdown. You **must** pick a workspace before **Next**.

“**Report or audience** path: use the three filters — **All workspaces**, **All apps**, **All types** — to narrow the list. Search with the search bar if you know a keyword.

“Below that you’ll see **Reports** in a grid. Each card shows **SAR** or **AUR** — standalone report versus audience-type report — and the workspace name. If an **AUR** card is **greyed out** and says it’s **not linked to an app audience**, **do not** select it — the wizard can’t use it for a normal request.

“Further down, **App audiences** are cards with an **Audience** badge. Choosing an audience means OLS through that audience, not one specific report.

“Pagination appears if there are many results — use the page controls to browse.

“What **not** to do: don’t click **Next** without selecting either a **report card**, an **audience card**, or — for RLS-only — a **workspace**. The red banner explains what’s missing.”

**[ACTION]** Demonstrate: toggle tips; filter once; select one valid SAR or audience; or show RLS-only + workspace.

### Segment 3 — Guided: Step 2 “Request details” (~1 min 30 s)

“**Step 2 — Request details**. The page reminds you what you picked — report, audience, or RLS-only workspace summary.

“**Who is this request for?** — **Me**, or **Another user**. If another user, type their **email** and press **Enter** or leave the field to trigger **line manager** resolution for that person.

“**Justification** is required — explain the business reason clearly; approvers read this first.

“What **not** to do: don’t leave justification empty; don’t use a wrong email format for **Another user**.”

**[ACTION]** Select **Me**, type 1–2 sentences in justification.

### Segment 4 — Guided: Step 3 “RLS” (~3 min — longest; split in two takes if needed)

“**Step 3 — Row-Level Security**. At the top, **How your request will be routed** lists what will happen after submit — read it once; it changes based on report type and RLS choices.

“If you picked an **AUR** report, you may see a banner while the app **links** that report to an audience — wait for it. If mapping is missing, you’ll see a **warning** — you can still continue in some cases, but admins may need to fix data.

“If you **already have RLS** in this workspace, you’ll see **Existing RLS found** and a table **Your current applicable RLS settings**, with a **Refresh** control if you need to reload.

“Then the key question: **Would you like to reuse your existing RLS?**

“**Yes, reuse existing RLS** — fastest: no new RLS approval if your existing row access is enough.

“**No, I’ll define new RLS** — opens **Define new RLS configuration**: pick **Security model** and **Security type (role)**, then fill **dimensions** (varies by workspace — dropdowns or tree picks like service line or MSS). Some fields allow typing a custom value where enabled.

“If there is **no** RLS schema for the workspace code, you’ll see a message that the workspace isn’t mapped — pick a supported workspace or scope.

“Special case — **RLS-only request** from Step 1: you **must** either reuse existing RLS or define **valid new** RLS; you can’t skip this.

“Special case — **normal OLS path** with **no** existing RLS: you **may** press **Next** without defining new RLS if you only need **report/audience access** right now — the helper text explains that. If you **do** open new RLS, you must complete required dimensions before **Next** unlocks.

“What **not** to do: don’t mash **Next** while a spinner says **Loading**; don’t ignore the red validation banner — it tells you whether to **reuse** or **define** RLS.”

**[ACTION]** Show reuse vs define; optionally show RLS-only blocked until dimensions are valid.

### Segment 5 — Guided: Step 4 “Approver detection” (~2 min)

“**Step 4 — Approver detection**. A spinner runs while Sakura resolves approvers.

“You’ll see numbered cards:

“**1 — Line Manager** — always. If missing, the **Request recipient** panel lets you fix **Me vs Another user** and **Resolve line manager** without going back to Step 2.

“**2 — OLS Approver** — when your request includes object-level access (typical for a report path). If the line manager wasn’t resolved yet, it says preview hasn’t run.

“**3 — RLS Approver** — only when you **defined new RLS**. If you **reused** existing RLS, you’ll see **RLS (existing access)** instead — no new RLS approver resolution.

“If **No RLS approver found**, you can **Escalate to Workspace Owner** or **Adjust dimension filters** to go back to Step 3.

“What **not** to do: don’t continue with a red **Line Manager** card — fix recipient first.”

**[ACTION]** Let spinner finish; point at each card; optionally show “Change recipient”.

### Segment 6 — Guided: Step 5 “Request summary” + submit (~1 min)

“**Step 5** — heading **Request summary**. Left column: report, audience if any, workspace, type, who the request is for, justification, **RLS configuration** badge and dimension lines when available. Right column: **Approval workflow** steps, expected timeline **2–5 business days**, email notifications note.

“Check the **declaration** checkbox — you cannot submit without it.

“**Submit Request** — wait for success.

“What **not** to do: don’t submit without reading the summary; don’t forget the declaration.”

**[ACTION]** Tick declaration; click **Submit Request** (use test env).

### Segment 7 — Guided: Step 6 success (~45 s)

“You’ll see **Request successfully submitted**, a **reference** code, **What happens next?** steps, and buttons: **Go to dashboard**, **View all requests**, **Go to request**, **New request**.

“What to do: copy or note the **reference**; open **My requests** if you want to track status.”

**[ACTION]** Point at reference; click **View all requests** or **Go to dashboard**.

### Segment 8 — Advanced wizard: entry and Step 1 (~2 min 30 s)

“Back on the **Dashboard**, open **Request access (Advanced)**. Breadcrumb: **Request access (Advanced)**. Same five-step idea but Step 1 is **Access scope selection**.

“At the top, choose **What kind of access do you need?**

“**Report / audience access** — OLS plus optional RLS; you’ll pick workspace then an **audience** or **report** under the tabs.

“**RLS filters only** — same idea as Guided **RLS only**: **no new report access**; workspace plus RLS in later steps.

“**Tabs**: **Workspace** — search and click a workspace card. **App** — optional filter by workspace; pick an app card. **Audience** — pick an audience; hint text explains if you should pick an app first. **Report** — search and pick a report; **AUR** rows that aren’t linked stay **disabled** like in Guided.

“After you select a workspace, the footer hint tells you whether to press **Next** (RLS-only) or to pick audience/report.

“What **not** to do: don’t stay on the wrong tab and wonder why **Next** is disabled — read the hint under the tabs.”

**[ACTION]** Toggle RLS-only vs report path; select workspace; select audience or report.

### Segment 9 — Advanced: Steps 2–6 (delta from Guided) (~2 min)

“**Step 2 — Request details** matches Guided plus **Selected access scope** as a clear list, **Requested by** (read-only — always you), and **Line manager approver** resolved from the **requested-for** email when you choose **Another user**.

“**Steps 3–6** behave like Guided: RLS reuse vs define, approver detection, **Request summary**, declaration, submit, success.

“**Deep link tip** for recordings: Advanced can open in RLS-only mode via URL query `rlsOnly=1` or `mode=rls-only` if your environment uses that link from **My access** or docs — useful for a second demo clip.”

### Segment 10 — Close (~30 s)

“That’s both wizards: **Guided** for catalogue browsing, **Advanced** for direct picks, plus **RLS-only** in both when you only need row-level changes. Use **Back** and **Cancel** anytime; **Cancel** returns toward the dashboard. Thanks for watching.”

---

## Part 3 — Production timing sheet

Use this as a **shot list**. Times are **suggested**: add 10–20% if you narrate slowly or repeat a sentence.

**Legend:** **Hold** = leave screen still while talking; **Action** = time budget for clicks/typing; **Total** ≈ cumulative from segment start.

### A — Guided wizard (single continuous demo: OLS + optional RLS)

| # | Screen / beat | Hold (talk) | Action (do) | Notes |
|---|----------------|------------|-------------|--------|
| A0 | Dashboard, two cards | 25 s | 5 s hover | Establish entry points |
| A1 | Guided Step 1, intent cards + tips | 35 s | 15 s | Pick **Report or audience** |
| A1b | Filters + search + one card select | 40 s | 25 s | Pick one SAR or audience |
| A2 | Step 2, Me + justification | 45 s | 35 s | Type ~25–40 words justification |
| A3 | Step 3, routing banner + reuse/new | 50 s | 40 s | Prefer **reuse** if available; else 2–3 dimensions |
| A4 | Step 4, spinner + approver cards | 40 s | 15 s | Wait real spinner; don’t cut |
| A5 | Step 5 summary + declaration | 35 s | 15 s | Scroll summary once |
| A6 | Submit + success + reference | 20 s | 25 s | Submit + pause on reference |
| | **Subtotal** | **~4m 50s** | **~2m 35s** | **~7–8 min** with transitions |

### B — Guided “RLS only” variant (record as second video or B-roll)

| # | Screen / beat | Hold | Action | Notes |
|---|----------------|------|--------|--------|
| B1 | Step 1: **RLS only** card + workspace dropdown | 40 s | 15 s | Explain shorter approval path |
| B2 | Step 2: RLS-only summary card | 25 s | 20 s | Me + justification |
| B3 | Step 3: must define or reuse RLS | 45 s | 45 s | Show **Next** disabled until valid |
| B4–B6 | Steps 4–6 as in A | — | — | OLS card absent or minimal |

**Rough total:** **5–6 min**

### C — Advanced wizard (report/audience path)

| # | Screen / beat | Hold | Action | Notes |
|---|----------------|------|--------|--------|
| C0 | Dashboard → Advanced | 15 s | 5 s | |
| C1 | Step 1: type toggle + tabs | 50 s | 40 s | Workspace → App → Audience **or** Report |
| C2 | Step 2: scope summary + LM field | 40 s | 35 s | Show **Requested by** read-only |
| C3–C6 | Align with Guided A3–A6 | | | Same RLS / approvers / summary |

**Rough total:** **7–9 min**

### D — Optional pickups (short inserts, 15–45 s each)

| Topic | Hold | Action |
|--------|------|--------|
| Greyed-out **AUR** + “not linked” | 20 s | 5 s |
| Step 4 **Request recipient** + **Resolve line manager** | 25 s | 20 s |
| **Escalate to Workspace Owner** modal (open + cancel) | 15 s | 10 s |
| Pagination on Guided catalogue | 15 s | 10 s |
| **Refresh** on existing RLS table | 15 s | 5 s |

---

## Part 4 — Quick “do / don’t” checklist (for the narrator)

**Do**

- Pick a **valid** report or audience before **Next** (Guided Step 1).
- Enter a **clear justification** (Step 2).
- On Step 3, either **reuse** RLS, **define** complete new RLS, or — only on the OLS path without existing RLS — skip new RLS if you truly only need object access.
- Resolve **line manager** before expecting OLS/RLS preview (Step 4).
- Read **Request summary** and tick the **declaration** before submit.

**Don’t**

- Don’t select **unmapped AUR** reports (greyed out).
- Don’t skip **workspace** on **RLS-only** (Guided Step 1).
- Don’t click **Next** during **loading** spinners on Step 3 or 4.
- Don’t submit without the **declaration** checkbox.
- Don’t confuse **Requested by** (Advanced, always you) with **Who is this request for?** (the beneficiary).

---

## Part 5 — Out of scope / honesty notes (avoid viewer confusion)

- Sidebar **Report catalogue** and **Delegation** may be marked **under development** in some environments — the Guided wizard still embeds a **catalogue-style** Step 1.
- A separate **New permission request** (**Data Entry**) route is a different, tabular flow — not covered in this script.
- Design docs sometimes mention a **Help me** button; the current wizard relies on **Show tips**, banners, and the sidebar **Need help?** card. If **Help me** appears in a future build, add a 20 s segment.

---

*Document generated to align with Sakura FE components `request-form` (Guided) and `request-form-scope` (Advanced) as of the repository state used to author this guide.*
