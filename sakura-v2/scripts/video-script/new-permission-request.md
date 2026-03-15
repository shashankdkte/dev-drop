# Video Script – Permission Request and Approval Workflow

## Terminology (align with app)

- **Create request** in the script = **"New permission request"** in the **Sidebar**. This is the **only** way users create permission requests in the current app.
- Route: **Sidebar → "New permission request"** → `/data-entry` → Permission request form (`/data-entry/permission-requests`).

---

## Tech stack (for reference)

| Layer   | Technology |
|--------|------------|
| **Frontend** | Angular 20, PrimeNG 20, PrimeIcons, MSAL (Azure/Entra), standalone components |
| **Backend**  | .NET 8 (C#) – Dentsu.Sakura.Api, Application/Domain/Infrastructure/Shared |
| **Database** | SQL Server – `dbo.PermissionRequests`, `dbo.PermissionHeaders`, OLS/RLS tables, workspace RLS views (ShareCDI, ShareWFI, ShareGI, etc.) |

---

## How many videos? (Engaging + connect every dot)

Recommendation: **5 short videos** (about 4–7 minutes each). Each video has one clear goal and links to the next so users can connect each step.

| # | Video title | Content | Approx length | Connects to |
|---|-------------|---------|----------------|-------------|
| **1** | **Introduction and creating a permission request** | What the workflow is; **Sidebar → "New permission request"**; form overview (Workspace, Requested for, Requested by, LM approver, Request reason); Report/Audience; submit. Duplicate detection and **"Go to request"**. | 5–7 min | Video 2 (OLS/RLS) |
| **2** | **OLS, RLS, and combined requests** | **OLS-only**: Include OLS, OLS item type (Report vs Audience), Report or App+Audience, OLS values; submit. **RLS-only**: Include RLS, Security model/type, dimension values; submit. **Combined**: both sections in one form; submit. How OLS vs RLS affects object-level vs row-level access. | 5–6 min | Video 3 (My Requests) |
| **3** | **My Requests and request details** | **Sidebar → My requests**; grid (Request ID, resource, type, requested user, status, created date); tabs (All / OLS / RLS) and filters; click row → **request detail**. What appears for OLS vs RLS vs Combined (OLS selections, RLS dimensions, status, approvers, approval history). | 4–5 min | Video 4 (Approvals) |
| **4** | **Approval workflow (for approvers)** | **Sidebar → My approvals**; tabs **Pending** / **History**; role filters: **All**, **Line Manager**, **OLS Approver**, **RLS Approver**. Approval flow: LM always first; then OLS or RLS (or both for combined). Actions: Approve, Reject, Revoke. When each role can act. | 5–6 min | Video 5 (States) |
| **5** | **Request states and wrap-up** | Request states: **Pending** (LM / OLS / RLS), **Approved**, **Rejected**, **Cancelled**, **Revoked**. Simple workflow diagram from creation → My Requests → Approvals → final state. Governance recap. | 3–4 min | — |

**Total:** ~25–28 minutes of content, split into 5 focused videos so users can watch one at a time and still follow the full journey.

---

## Alternative: 3 longer videos

If you prefer fewer, longer episodes:

| # | Video | Content | Approx length |
|---|--------|---------|----------------|
| 1 | **Creating permission requests** | Intro + **"New permission request"** + OLS + RLS + Combined + duplicate detection. | 8–10 min |
| 2 | **My Requests and request details** | Grid, tabs, filters, detail view for OLS / RLS / Combined. | 4–5 min |
| 3 | **Approval workflow and request states** | My approvals, roles, flow (LM → OLS/RLS), actions, states diagram. | 7–8 min |

---

## Connecting every dot (storyline)

1. **Request creation** – Only via **Sidebar → "New permission request"** (no other entry point).
2. **After submit** – Duplicate check → success or “Go to request” to existing request.
3. **Requester** – Sees request in **My requests**; can open detail and see status and approval history.
4. **Approver** – Sees items in **My approvals** (Pending/History, by role); LM → OLS → RLS order for combined; Approve/Reject/Revoke.
5. **States** – Pending LM → Pending OLS → Pending RLS → Approved (or Rejected/Cancelled/Revoked at any stage).

Mention in each video where the current step fits (e.g. “Once submitted, you’ll see this request under **My requests**” or “As an approver, you’ll see it under **My approvals**”).

---

## App ↔ script alignment

- **Sidebar label:** Use **"New permission request"** (not “Create Request”) when showing the app.
- **Request types:** OLS, RLS, Combined – all created on the **same form** by toggling “Include OLS” / “Include RLS”.
- **Approval page:** Tabs **Pending** / **History**; role chips **All**, **Line Manager**, **OLS Approver**, **RLS Approver** (script’s “OLS Approval” = “OLS Approver”, “RLS Approval” = “RLS Approver”).
- **Request states (DB/UI):** 0 = Pending LM, 1 = Pending OLS, 2 = Pending RLS, 3 = Approved, 4 = Rejected, 5 = Revoked, 6 = Cancelled. Script’s “Pending” covers 0, 1, 2.

---

## Script sections mapped to videos

| Script section | Video(s) |
|----------------|----------|
| 1. Introduction | Video 1 |
| 2. Creating a new permission request | Video 1 → **[Video 1 full script: VIDEO_01_SCRIPT_FIRST_VIDEO.md](VIDEO_01_SCRIPT_FIRST_VIDEO.md)** (frontend-verified) |
| 3. OLS request | Video 2 |
| 4. RLS request | Video 2 |
| 5. Combined OLS + RLS request | Video 2 |
| 6. Duplicate request detection | Video 1 (or 2) |
| 7. My Requests section | Video 3 |
| 8. Viewing request details | Video 3 |
| 9. Approval process overview | Video 4 |
| 10. Approval categories | Video 4 |
| 11. Approval flow (OLS / RLS / Combined) | Video 4 |
| 12. Request states | Video 5 |
| 13. Conclusion | Video 5 |

This keeps the narrative consistent with the frontend (Angular, sidebar “New permission request”), backend (.NET API), and database (PermissionRequests, PermissionHeaders, OLS/RLS), and ensures users can connect each step from request creation to final state.
