# Sakura — Request Wizard: Video script & production notes (Guided + Advanced)

End-to-end recording guide. UI routes: **Request access (Guided)** → `/request-form`; **Request access (Advanced)** → `/request-form-scope` (also `/request-access-advanced`).

**Quick terms (say once early):**

- **OLS** — permission to see a **report** or **app audience**.
- **RLS** — which **data rows** you see (dimensions such as entity, client, service line).

---

## What we’ve covered so far

Use this as your **series intro** (about 30–45 seconds):

“We’ve already walked through the **WSO Console** for workspace admins, then **New Permission Request**, **My Requests**, and **My Approvals**. Today we focus on the **Request Wizard** — how end users raise access requests in a **structured**, step-by-step way.”

---

## Today’s topic: Request Wizard

The Request Wizard helps users raise access requests in a structured way. Sakura offers **two modes**; both end with the same kind of **RLS**, **approver detection**, **summary**, and **success** screens — only **Step 1** (and part of Step 2 in Advanced) is different.

### Two modes available

| | **Guided mode** | **Advanced mode** |
|---|----------------|-------------------|
| **Opens from** | Dashboard → **Request access (Guided)** | Dashboard → **Request access (Advanced)** |
| **Best for** | New users, browsing, not sure of exact IDs | You already know workspace / app / audience / report |
| **Step 1** | Catalogue: reports + app audiences + filters | **Tabs:** Workspace, App, Audience, Report — direct picks |
| **Later steps** | Request details → RLS → Approvers → Summary → Success | Same flow (labels on progress bar differ slightly) |

---

## Dashboard overview

After signing in, you land on the **Dashboard**. At the top, two main options:

**Request access (Guided)**  
Subtitle: step-by-step wizard via **report catalogue**.  
→ Use when **browsing** or **unsure** which report or audience fits.

**Request access (Advanced)**  
Subtitle: **direct workspace and object selection**.  
→ Use when you **already know** the exact requirement.

**Say:** “If you’re new, start with **Guided**. If you live in a specific workspace and know the app or report name, **Advanced** is often faster.”

**[ACTION]** Hover each card; optionally point at subtitles.

---

## Guided mode walkthrough

**On-screen step tracker (Steps 1–5)** — the bar at the top uses these titles:

1. **What are you requesting?** *(we’ll call this “scope & intent” in narration)*  
2. **Request details**  
3. **RLS**  
4. **Approver detection**  
5. **Summarization** *(the page heading on step 5 is **Request summary**)*  

Then **Step 6** is the **success** screen (no stepper).

Each step must be satisfied before **Next** unlocks (except special cases called out in Step 3).

---

### Step navigation (Guided)

**Say:** “At the top you see **Step X of 5** and a horizontal tracker from step 1 through 5. **Back** and **Cancel** are always available until you submit — **Cancel** returns you toward the dashboard.”

---

### Step 1 — Scope & intent *(screen: “What are you requesting?”)*

#### Choose request intent

**Report or app audience access** *(OLS + optional RLS)*  

- Used when requesting **report** or **app audience** access.  
- Includes **object-level security (OLS)**.  
- **RLS** can be:  
  - **Reused** → behaves like **OLS-focused** request (no new RLS approval).  
  - **New** → **OLS + new RLS** (line manager → OLS approver → RLS approver when applicable).

**RLS only** *(row-level security only)*  

- When the user **already has** report access and is only changing **RLS**.  
- **Shorter approval flow:** Line Manager → **RLS data owner** (no OLS approver step).  

👉 **For RLS-only on this step:** you only need to select the **workspace** from the dropdown (required before **Next**). The catalogue is hidden.

**Show tips** — optional toggle; explains approval path in one line under the cards.

#### Report / audience selection *(when “Report or app audience” is selected)*

**Filters**

- **All workspaces**  
- **All apps**  
- **All types**  

**Search bar** — quick lookup by keyword.

**Report cards show**

- **SAR** — standalone report  
- **AUR** — audience-based report  
- **Workspace** name  

⚠️ If an **AUR** card is **greyed out** (“not linked to an app audience”), **do not** select it — it cannot be used for a normal request path.

**App audiences**

- Grouped access; badge **Audience**.  
- Selecting one means OLS **via that audience**, not a single named report on the card.

**Pagination**

- Use **« ‹ page › »** if the list is long.

**[ACTION]** Demonstrate one filter + one valid SAR or audience; optionally show greyed AUR without clicking.

---

### Step 2 — Request details *(Guided)*

**Say:** “Step 2 shows a **summary card** of what you picked — report, audience, or RLS-only workspace.”

**Fields**

- **Who is this request for?**  
  - **Me (myself)**  
  - **Another user** → enter **email** → blur field or press **Enter** to help resolve **line manager** for that person.  
- **Justification** *(required)* — clear business reason; **1–2 sentences** minimum in practice.

**[ACTION]** Me + short justification, or Another user + valid email.

---

### Step 3 — RLS information *(screen title: “Row-Level Security”)*

**Say:** “Always read **How your request will be routed** at the top — it updates when you change RLS choices.”

**AUR reports:** you may see **loading** or **warning** while the app links the report to an audience — wait; if mapping is missing, a yellow warning explains next steps.

**If you already have RLS** in this workspace:

- **Existing RLS found** + table **Your current applicable RLS settings**  
- **Refresh** button if you need to reload from the server  

**Key options**

- **Yes, reuse existing RLS** — fastest; **no new RLS approval**.  
- **No, I’ll define new RLS** → **Define new RLS configuration**:  
  - **Security model** *  
  - **Security type (role)** *  
  - **Dimensions** — dropdowns or **trees** (e.g. service line, MSS); some allow **custom** values.  

**Important behaviour**

- **RLS-only request (from Step 1):** you **must** reuse or complete **new** RLS — you cannot skip.  
- **Normal OLS path** with **no** existing RLS: you **may** go **Next** **without** defining new RLS if you only need object access **for now** — on-screen helper text says so. If you **open** the new RLS form, fill required fields before **Next**.

**[ACTION]** Show reuse vs define; wait out any spinner before clicking **Next**.

---

### Step 4 — Approver detection *(Guided)*

**Say:** “The system **auto-detects** approvers. Wait for the spinner to finish.”

**You’ll see (typical)**

1. **Line Manager** — always. If missing → **Request recipient** panel: fix **Me / Another user**, then **Resolve line manager** (no need to go back to Step 2).  
2. **OLS Approver** — when the request includes report/audience OLS.  
3. **RLS Approver** — **only if** you **defined new RLS**. If you **reused** RLS → card **RLS (existing access)** instead.  

**If issues occur**

- **No RLS approver found:** **Adjust dimension filters** (back to Step 3) **or** **Escalate to Workspace Owner** (modal).  
- **No OLS approver:** fix scope / data **or** use **Back**; escalation may apply depending on process.  

⚠️ Ensure **line manager** shows a resolved value before trusting OLS/RLS preview.

**[ACTION]** Let spinner complete; point at cards; optional: open **Change recipient**.

---

### Step 5 — Summary & submit *(heading: “Request summary”)*

**Review**

- Report / audience / workspace / type  
- **Request for** (me vs other + email)  
- **Business justification**  
- **RLS configuration** (badge + dimension lines when available)  
- **Approval workflow** — **very important**; read every step before submitting  

**Final steps**

- Tick **declaration** checkbox *(required)*  
- **Submit Request**  

**[ACTION]** Scroll once through both columns; tick declaration; submit in test env.

---

### Step 6 — Success screen *(Guided)*

**Shows**

- **Request successfully submitted**  
- **Reference** code (copy or note it)  
- **What happens next?**  

**Navigation**

- **Go to dashboard**  
- **View all requests**  
- **Go to request** *(if ID returned)*  
- **New request**  

👉 **Best practice:** save the reference; track in **My Requests**.

---

## Demo cases — Guided mode

### Demo case 1: OLS-focused request *(reuse RLS or skip new RLS)*

1. Step 1: select a **report** (valid SAR or linked AUR).  
2. Step 2: **Me** + justification.  
3. Step 3: **Yes, reuse existing RLS** *(if you have RLS)* **or** **Next** without opening new RLS if allowed.  
4. Step 4: confirm **Line Manager** + **OLS**; RLS card only if new RLS or reuse messaging.  
5. Step 5: verify **approval workflow** → submit.  

### Demo case 2: OLS + new RLS

1. Step 1: select an **app audience** *(or report)*.  
2. Step 2: user + justification.  
3. Step 3: **No, I’ll define new RLS** → security model, type, dimensions.  
4. Step 4: **Line Manager** + **OLS Approver** + **RLS Approver** — all should resolve.  
5. If not: **adjust dimensions** or escalate.  
6. Step 5: workflow should read **Line Manager → OLS → RLS** → submit.  

### Demo case 3: RLS-only

1. Step 1: **RLS only** + **workspace**.  
2. Step 2: user + justification *(RLS-only summary card)*.  
3. Step 3: **reuse** or **define** RLS *(required)*.  
4. Step 4: **Line Manager** + **RLS Approver** *(no OLS card)*.  
5. Step 5: verify summary and **approval flow** → submit.  

---

## Advanced mode walkthrough

**Same five numbered steps + success** — behaviour matches Guided from **Request details** onward. Differences are **Step 1** and **extra fields on Step 2**.

**On-screen progress labels**

1. **Access scope selection**  
2. **Request details**  
3. **RLS**  
4. **Approver detection**  
5. **Review & Submit** *(step 5 heading is still **Request summary**)*  

---

### Step navigation (Advanced)

**Say:** “Advanced uses the same **Next / Back** pattern. Step 1 is about **tabs** and **direct selection**, not the catalogue.”

---

### Step 1 — Access scope selection *(Advanced only)*

#### What kind of access do you need? *(two buttons at top)*

**Report / audience access**  

- **OLS** plus optional **RLS**.  
- Subtext: pick audience or report **after** workspace.  

**RLS filters only**  

- Same idea as Guided **RLS only**: **no new report access**; workspace + RLS later.  

#### Tabs *(horizontal)*

| Tab | Purpose |
|-----|--------|
| **Workspace** | Search + click a **workspace card** *(required)* |
| **App** | Pick an **app**; optional **filter by workspace** dropdown |
| **Audience** | Pick an **audience**; hints if you should pick an app first |
| **Report** | Search + pick a **report**; **AUR** unlinked = **disabled**, same rule as Guided |

**After workspace is selected**, read the **hint** under the tabs:

- **RLS filters only** → “Press **Next**” when workspace is enough.  
- **Report / audience** → select **audience** or **report** before **Next**.  

👉 **Do not** ignore the hint — if **Next** is greyed out, you’re missing workspace, audience, or report depending on mode.

**[ACTION]** Show: Workspace tab pick → Audience tab pick → **Next**. Repeat segment with **RLS filters only** + workspace only.

---

### Step 2 — Request details *(Advanced)*

**Same as Guided, plus:**

- **Selected access scope** — readable list (workspace, app, audience, report as applicable).  
- **Requested by** — **read-only**, always the **signed-in user**.  
- **Line manager approver** — fills when **Another user** email is valid *(blur or Enter)*.  

**Say:** “Don’t confuse **Who is this request for?** with **Requested by**. **Requested by** is always you; the other field is who **gets** the access.”

**[ACTION]** Show **Requested by**; toggle Another user and resolve LM.

---

### Steps 3–6 *(Advanced)*

**Same screens and rules as Guided:**  

- Step 3: routing banner, reuse vs define, dimensions, spinners.  
- Step 4: approver cards, **Request recipient** panel, escalation / adjust filters.  
- Step 5: **Request summary**, declaration, **Submit Request**.  
- Step 6: success, reference, navigation buttons.  

**Deep link (optional to mention):** opening Advanced with `?rlsOnly=1` or `?mode=rls-only` can pre-focus **RLS filters only** *(if your environment uses dashboard links)*.

---

## Demo cases — Advanced mode

### Demo case 1: Quick path via workspace + report

1. Step 1: **Report / audience access** → **Workspace** tab → pick workspace → **Report** tab → pick valid report.  
2. Steps 2–6: same as Guided case 1.  

### Demo case 2: Workspace → app → audience + new RLS

1. Step 1: **Report / audience access** → workspace → **App** → **Audience** → select audience.  
2. Step 2: fill details + LM if needed.  
3. Step 3: **Define new RLS** + dimensions.  
4. Step 4: LM + OLS + RLS approvers.  
5. Step 5: verify **Line Manager → OLS → RLS** → submit.  

### Demo case 3: RLS filters only

1. Step 1: **RLS filters only** → workspace → **Next**.  
2. Steps 2–6: align with Guided **RLS-only** demo *(no OLS approver card)*.  

---

## Read-aloud script — compact (full episode ~12–18 min)

Use after the outline above; pause where **[PAUSE]** appears.

**Intro:** *(series recap)* “We’ve covered the WSO Console, New Permission Request, My Requests, and My Approvals. Today — the **Request Wizard**.”  

**Modes:** “Two modes: **Guided** from the catalogue, **Advanced** by workspace and object. Same later steps.” **[PAUSE]**  

**Dashboard:** “From the Dashboard, **Request access (Guided)** for browsing, **Advanced** when you know exactly what you need.” **[PAUSE]**  

**Guided Step 1:** “Step one — what you need: **report or audience** with OLS, or **RLS only** with just a workspace. Filters, search, SAR and AUR cards; greyed AUR means don’t select. Audiences are grouped access. Pages at the bottom if needed.” **[PAUSE]**  

**Guided Step 2:** “Step two — who it’s for and why. Email for someone else. Justification is mandatory.” **[PAUSE]**  

**Guided Step 3:** “Step three — RLS. Read the routing summary. Reuse existing RLS for speed, or define model, role, and dimensions. RLS-only requests must complete RLS; OLS-only can sometimes skip new RLS.” **[PAUSE]**  

**Guided Step 4:** “Step four — approvers. Line manager always. OLS when you asked for object access. RLS approver only for **new** RLS. Fix recipient here if needed.” **[PAUSE]**  

**Guided Step 5–6:** “Step five — read the **approval workflow**, tick the declaration, submit. Step six — save your **reference** and track in **My Requests**.” **[PAUSE]**  

**Advanced:** “**Advanced** — Step one uses **Report / audience** versus **RLS filters only**, then **Workspace**, **App**, **Audience**, and **Report** tabs. Step two adds **Requested by** read-only. Everything after that matches **Guided**.” **[PAUSE]**  

**Close:** “Always confirm **line manager** and **approval workflow** before submit. Thanks for watching.”  

---

## Before you record

1. Test account with a resolvable **line manager**.  
2. One workspace **with** existing RLS and one **without** (for reuse vs define).  
3. Valid **SAR** or linked **AUR**; avoid greyed cards for the happy path.  
4. Browser **100%** zoom; clean toolbar.  
5. Advanced segment: rehearse **tab order** once so clicks look confident.  

---

## Production timing sheet

**Hold** = talk on static screen; **Action** = typing/clicks.

### Guided — full happy path (OLS + reuse or skip new RLS)

| Beat | Hold | Action |
|------|------|--------|
| Dashboard two cards | 25 s | 8 s |
| Step 1 intent + catalogue | 50 s | 30 s |
| Step 2 | 40 s | 30 s |
| Step 3 RLS | 55 s | 45 s |
| Step 4 approvers | 40 s | 20 s |
| Step 5–6 | 45 s | 35 s |
| **Rough total** | **~4m 15s** | **~2m 48s** | **~7–9 min** with transitions |

### Guided — RLS-only only

| Beat | Hold | Action |
|------|------|--------|
| Step 1 RLS only + workspace | 35 s | 15 s |
| Steps 2–6 | *(use row above from Step 2)* | |

**Rough total: 5–6 min**

### Advanced — workspace + audience + new RLS

| Beat | Hold | Action |
|------|------|--------|
| Dashboard → Advanced | 15 s | 5 s |
| Step 1 toggles + 3 tabs | 55 s | 50 s |
| Step 2 scope summary + LM | 45 s | 35 s |
| Steps 3–6 | same as Guided | same as Guided |

**Rough total: 8–10 min**

### Short pickups *(15–40 s each)*

| Topic | Hold | Action |
|--------|------|--------|
| Greyed AUR | 20 s | 5 s |
| Step 4 **Resolve line manager** | 25 s | 20 s |
| Escalation modal open/cancel | 15 s | 10 s |
| **Requested by** vs request for | 20 s | 10 s |

---

## Final notes

- **Always** verify **approval workflow** on the summary before **Submit**.  
- **Always** ensure **line manager** is resolved and **OLS/RLS** emails look correct.  
- Use **dimension changes** in Step 3 when RLS approver is missing.  
- Use **Escalate to Workspace Owner** when offered and process allows.  

**Honesty / scope**

- Sidebar **Report catalogue** may be **under development** in some builds; Guided Step 1 still behaves like a **mini-catalogue**.  
- **New permission request** under **Data Entry** is a **different** tabular flow — not this wizard.  
- Some design docs mention **Help me**; today’s UI uses **Show tips**, banners, and sidebar **Need help?**.  

---

*Aligned with `request-form.component` (Guided) and `request-form-scope.component` (Advanced).*
