# Video 3 – My Requests and Request Details

**Frontend-verified:** Every label, button, and message below matches the current app. Do not say anything that is not in this script or the checklist.

---

## 1. Introduction (≈15 s)

- "In this video we'll see where to find the requests you've created and how to open the full details of any request—including OLS, RLS, and the approval chain."

---

## 2. Opening My Requests (≈20 s)

- "In the left sidebar, click **My requests**."
- "The page loads your requests. While loading you'll see *Loading your requests...* If something goes wrong, an error message appears instead."
- "This page shows all permission requests where you are the requester or where you were requested for—depending on how the app is configured for your tenant."

---

## 3. Tabs and toolbar (≈45 s)

- "At the top you have three tabs: **All**, **OLS requests**, and **RLS requests**. Use them to filter by type: all requests, only OLS, or only RLS."
- "Next is the toolbar. The search box has the placeholder *Search name, code, workspace, status…*. Type here to filter the list."
- "The filter button toggles an expanded filter row. When filters are active, a badge shows the number of active filters. The tooltip says *Filters*."
- "**Rows** lets you choose how many rows per page: 10, 20, 50, or 100."
- "The **Export** button exports the selected requests. It's disabled when no rows are selected. The label shows an download icon and the word **Export**."
- "On the right you see the results count: *X result* or *X results*."

---

## 4. Filters (≈35 s)

- "When you open the filter row, the header says **Filters**. If any filter is set, a **Clear all** link appears."
- "**Status**: dropdown with placeholder *All statuses*. Options include *Pending*, *Approved*, *Rejected*, *Revoked*, *Cancelled*."
- "**Type**: placeholder *All types*. Options include *App (APP)*, *Audience (AUR)*, *Standalone report (SAR)*."
- "**Workspace**: placeholder *All workspaces*—shown when more than one workspace exists."
- "When you're on the OLS tab or All tab, you may see **OLS filters** with **Item type** (*All types*, *Report*, *Audience*) and **Item name** (*All items*)."
- "When you're on the RLS tab or All tab, you may see **RLS dimension filters** with one dropdown per dimension—placeholder *All*."

---

## 5. The requests table (≈50 s)

- "The table has a checkbox column so you can select rows for export."
- "**Name**: the request code or name. You can click the column header to sort; a sort indicator appears. Some requests may show an urgent indicator."
- "**Type**: badges **OLS** and **RLS**—one or both—or a dash if neither."
- "**Workspace**: workspace name."
- "**Requested for**: the person the access was requested for."
- "**OLS / RLS detail**: a short summary—for OLS, something like *Report: [name]* or *Audience: [name]*; for RLS, dimension pills with key and value. If there's nothing, a dash."
- "**Status**: approval stages with icons and labels—for example Line manager, OLS Approver, RLS Approver—and their status (e.g. Pending, Approved)."
- "**Requested**: the date, with a calendar icon."
- "**Actions**: a **View details** button. Click it to open the full request detail page."
- "If the list is empty, you'll see *No requests match your filters* when search or filters are applied, or *No requests found* otherwise."
- "Below the table, pagination shows *X–Y of Z* and buttons to go first, previous, page numbers, next, last."

---

## 6. Request detail page – header and breadcrumb (≈30 s)

- "On the detail page, the breadcrumb at the top has **My requests** as a link, then the request code as the current page."
- "The page title is the request code. Next to it is a status badge: **Pending**, **Approved**, **Rejected**, **Revoked**, or **Cancelled**."
- "Below that you see **Request ID:** with the ID, the workspace name, *Submitted* with the date, **Requested for:** and **Requested by:** with the emails."
- "On the right: **Cancel request**—only when you are the requester and the request is still Pending—and **Back**, which returns to My requests."
- "If the detail fails to load, you'll see an error message and a **Back to My Requests** button."

---

## 7. Request detail – OLS section (≈20 s)

- "If the request has OLS, a card titled **Object-level security** appears with an OLS icon in the header."
- "It shows **Type**: *Report* or *Audience*, and **Report name** or **Audience name** (the item name)."

---

## 8. Request detail – RLS section (≈25 s)

- "If the request has RLS, a card titled **Row-level security** appears with an RLS icon."
- "A table lists the RLS dimensions—column headers depend on the workspace, for example Entity, Client, Service line, MSS, Profit center, Cost center, PA, Country. Each row is one dimension combination; values can be keys or resolved names."

---

## 9. Request detail – Combined and no access (≈15 s)

- "If the request has both OLS and RLS, you see both cards: **Object-level security** and **Row-level security**."
- "If the request has neither OLS nor RLS, a single card **Access details** appears with the message *No OLS or RLS permission details available.*"

---

## 10. Request detail – Approval chain (≈40 s)

- "On the right, the **Approval chain** card shows each approval stage in order."
- "Stages are **Line manager**, **OLS Approver**, and **RLS Approver**—only the ones that apply to this request. Each stage shows a status: **Approved**, **Rejected**, **Revoked**, **Cancelled**, **Pending**, or **Not started**."
- "When a stage does not apply because the request was rejected earlier—for example by the Line manager—the status is **Does not apply** and the note says *Does not apply — request was rejected by Line Manager.*"
- "For each stage you see the approver email(s), and if decided, *Approved on* or *Decided on* with the date. If there was a reject or revoke reason, it appears below the stage."

---

## 11. Cancel request (optional, ≈20 s)

- "If **Cancel request** is visible, you can click it to withdraw the request. A modal opens with the title **Cancel request**, explaining that the request will be withdrawn. You can enter an optional reason—placeholder *e.g. No longer needed...*—and then click **Cancel request** to confirm or **Back** to close the modal. After cancelling, a success toast appears: *Request [code] cancelled*."

---

## 12. Wrap and lead to Video 4 (≈10 s)

- "In the next video we'll look at **My approvals**—how approvers see and act on requests: Line Manager, OLS Approver, and RLS Approver."

---

## Frontend checklist – do NOT say if not in the UI

| Where | Say this (exact) | Do NOT say |
|-------|------------------|------------|
| Sidebar | **My requests** | My Requests (capital R) |
| Loading | *Loading your requests...* | — |
| Tabs | **All**, **OLS requests**, **RLS requests** | — |
| Search | *Search name, code, workspace, status…* | — |
| Toolbar | **Rows** (10/20/50/100), **Export**, *X result(s)* | — |
| Filters | **Filters**, **Clear all**, **Status**, **Type**, **Workspace** | — |
| Filter placeholders | *All statuses*, *All types*, *All workspaces*, *All items*, *All* | — |
| Filter options | *Pending*, *Approved*, *Rejected*, *Revoked*, *Cancelled*; *App (APP)*, *Audience (AUR)*, *Standalone report (SAR)*; *Report*, *Audience* | — |
| Filter sections | **OLS filters**, **Item type**, **Item name**; **RLS dimension filters** | — |
| Table columns | **Name**, **Type**, **Workspace**, **Requested for**, **OLS / RLS detail**, **Status**, **Requested**, **Actions** | — |
| Type badges | **OLS**, **RLS** | — |
| Actions | **View details** | View, Details |
| Empty state | *No requests match your filters*, *No requests found* | — |
| Pagination | *X–Y of Z*, « ‹ › » | — |
| Detail breadcrumb | **My requests**, then request code | — |
| Detail header | Request code, status badge, **Request ID:**, workspace, *Submitted*, **Requested for:**, **Requested by:** | — |
| Detail buttons | **Cancel request**, **Back**, **Back to My Requests** (on error) | — |
| Detail loading | *Loading request details…* | — |
| OLS card | **Object-level security**, **Type**, **Report name** / **Audience name** | Object Level Security (full form in script is fine) |
| RLS card | **Row-level security**, dimension table | — |
| No OLS/RLS | **Access details**, *No OLS or RLS permission details available.* | — |
| Approval chain | **Approval chain**, **Line manager**, **OLS Approver**, **RLS Approver** | Line Manager (capital M—app uses "Line manager") |
| Stage statuses | **Approved**, **Rejected**, **Revoked**, **Cancelled**, **Pending**, **Not started**, **Does not apply** | — |
| Does not apply note | *Does not apply — request was rejected by Line Manager.* | — |
| Cancel modal | **Cancel request**, **Back**, **Cancel request** (button), *e.g. No longer needed...* | — |
