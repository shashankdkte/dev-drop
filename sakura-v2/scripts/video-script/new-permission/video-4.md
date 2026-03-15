# Video 4 – Approval Workflow (for Approvers)

**Frontend-verified:** Every label, button, and message below matches the current app. Do not say anything that is not in this script or the checklist.

---

## 1. Introduction (≈20 s)

- "This video is for approvers. We'll see how to open **My approvals**, switch between pending and history, filter by your role—Line Manager, OLS Approver, or RLS Approver—and how to Approve, Reject, or Revoke a request."
- "The approval order is always: Line Manager first, then OLS or RLS—or both for combined requests. You can only act when it's your turn."

---

## 2. Opening My Approvals (≈15 s)

- "In the left sidebar, click **My approvals**."
- "The page title is **My approvals** and the description is *Review and approve pending access requests*."
- "At the top there is a **Refresh** button. While the page is loading you'll see *Loading your pending approvals...*"

---

## 3. Status tabs: Pending and History (≈30 s)

- "The first control is two large tabs: **Pending** and **History**."
- "**Pending** shows requests that are still in progress—waiting for one or more approvals. Each tab shows a count of items."
- "**History** shows requests that are no longer pending—Approved, Rejected, Revoked, or Cancelled. You can still revoke from History when the request is revocable."
- "Switch between them to see what needs your action versus what you've already dealt with."

---

## 4. Role tabs and toolbar (≈40 s)

- "Below the status tabs, the toolbar has role filters: **All**, **Line Manager**, **OLS Approver**, **RLS Approver**. Each shows a count. A coloured dot identifies each role."
- "**All** shows every request assigned to you across all roles. **Line Manager**, **OLS Approver**, and **RLS Approver** filter to the requests where you act in that role."
- "On the right: a search box with placeholder *Search code, name, workspace, role…*; a **Filters** button with a badge when any filter is active; **Rows** (10, 20, 50, 100); and the results count: *X result* or *X results*."

---

## 5. Filters (≈25 s)

- "When you open the filter row, the header says **Filters** and **Clear all** appears when something is set."
- "On the **History** tab you get **Outcome** with placeholder *All outcomes*. Options include *Pending*, *Approved*, *Rejected*, *Revoked*, *Cancelled*."
- "**Workspace** has placeholder *All workspaces* when more than one workspace exists."
- "**OLS filters** can include **Item name** (*All items*) and **Item type** (*All types*, *Report*, *Audience*)."
- "**RLS dimension filters** appear when relevant, with one dropdown per dimension and placeholder *All*."

---

## 6. Empty state (≈15 s)

- "When there are no items, you'll see **No pending approvals** on the Pending tab or **No history yet** on the History tab."
- "The text below says: *You don't have any pending approval requests at the moment* for Pending, or *Requests you have approved, rejected, or revoked will appear here* for History."
- "If you've used search, it says *No approvals match your search for \"…\"* with your search term."

---

## 7. Approval cards – what you see (≈50 s)

- "Each request appears as a card. At the top: a role badge—**Line Manager**, **OLS Approver**, or **RLS Approver**—then the request code, **ID:** and the request ID, and on the History tab an outcome badge: **Approved**, **Rejected**, or **Revoked**. On the right, the request date."
- "In the card body: **Requested for**, **Requested by**, **Workspace**. Then, if the request has OLS or RLS, chips showing the type—*Report* or *Audience* and the item name for OLS, or *RLS* and a summary of dimensions for RLS."
- "At the bottom: **View details**—to open the full request—and on the right either your action buttons or a waiting message."
- "When it's **your turn**, you see **Reject** and **Approve**. Click **Approve** to approve, **Reject** to reject. If the request is revocable—for example already approved at your stage or a later stage—you also see **Revoke**."
- "When it's **not your turn**, you see a waiting banner: *Waiting for Line Manager approval*, *Waiting for OLS Approver*, or *Waiting for previous approval*. No action is required from you yet."
- "On the **History** tab, for completed items you see the outcome label (e.g. **Approved**, **Rejected**, **Revoked**) and, when revocable, a **Revoke** button."

---

## 8. Approval flow (≈25 s)

- "**Line Manager** is always the first approver. Until the Line Manager approves, OLS and RLS approvers cannot act—they see *Waiting for Line Manager approval*."
- "After Line Manager approves: for an OLS-only request, the **OLS Approver** can Approve or Reject; for an RLS-only request, the **RLS Approver** can act; for a combined request, **OLS Approver** acts next, then **RLS Approver**."
- "You only see **Approve** and **Reject** when the request is at your stage. You can **Revoke** when the request is in a revocable state—for example after you or a later approver has approved."

---

## 9. Approve (≈25 s)

- "Click **Approve**. A modal opens with the title **Approve access request**."
- "The text says you are approving as **Line Manager**, **OLS Approver**, or **RLS Approver** for this request, and shows Request code, Requested for, Workspace, and What (OLS or RLS summary)."
- "A note says: *Approving will advance the request to the next stage or grant access if this is the final step.*"
- "Buttons: **Cancel** and **Approve access**. Click **Approve access** to confirm. A success toast appears: *Request [code] approved successfully*."

---

## 10. Reject (≈25 s)

- "Click **Reject**. A modal opens with the title **Reject access request**."
- "It explains that you are rejecting the request for the requested-for user and that the requester will be notified."
- "**Reason for rejection** is required—placeholder *Please provide a reason for rejecting this request...* and a default like *Request does not meet the access criteria.*"
- "A warning says: *This will reject the entire request and the requester will need to resubmit.*"
- "Buttons: **Cancel** and **Reject request**. If you leave the reason empty and click **Reject request**, you'll see *Please provide a reason for rejection*. After a successful reject, a toast: *Request [code] rejected*."

---

## 11. Revoke (≈25 s)

- "Click **Revoke**. A modal opens with the title **Revoke access request**."
- "It says you are revoking the request for the requested-for user and that this will roll back the request to a pending state or mark it as revoked."
- "**Reason for revocation** is required—placeholder *Please explain why you are revoking this request...* and a default like *Access no longer required.*"
- "A note says: *Revoking will roll back this approval. The requester will be notified.*"
- "Buttons: **Cancel** and **Revoke request**. If you don't enter a reason, you'll see *A revocation reason is required*."

---

## 12. View details and pagination (≈15 s)

- "**View details** on any card opens the full request in the same detail view we saw in Video 3—request code, status, OLS/RLS sections, and approval chain."
- "If there are more items than the page size, pagination at the bottom shows *X–Y of Z* and buttons to move between pages."

---

## 13. Wrap and lead to Video 5 (≈10 s)

- "In the next video we'll summarise the request states—Pending, Approved, Rejected, Cancelled, Revoked—and how they fit into the end-to-end workflow."

---

## Frontend checklist – do NOT say if not in the UI

| Where | Say this (exact) | Do NOT say |
|-------|------------------|------------|
| Sidebar | **My approvals** | Approvals, Approval |
| Page | **My approvals**, *Review and approve pending access requests* | — |
| Header | **Refresh** | — |
| Loading | *Loading your pending approvals...* | — |
| Status tabs | **Pending**, **History** (with counts) | — |
| Role tabs | **All**, **Line Manager**, **OLS Approver**, **RLS Approver** | — |
| Search | *Search code, name, workspace, role…* | — |
| Toolbar | **Filters**, **Rows**, *X result(s)* | — |
| Filter | **Filters**, **Clear all**, **Outcome** (*All outcomes*), **Workspace** (*All workspaces*) | — |
| Filter options (Outcome) | *Pending*, *Approved*, *Rejected*, *Revoked*, *Cancelled* | — |
| OLS/RLS filters | **OLS filters**, **Item name**, **Item type**; **RLS dimension filters** | — |
| Empty (Pending) | **No pending approvals**, *You don't have any pending approval requests at the moment* | — |
| Empty (History) | **No history yet**, *Requests you have approved, rejected, or revoked will appear here* | — |
| Empty (search) | *No approvals match your search for \"…\"* | — |
| Card | Role badge **Line Manager** / **OLS Approver** / **RLS Approver**, request code, **ID:**, outcome badge (**Approved** / **Rejected** / **Revoked**), **Requested for**, **Requested by**, **Workspace** | — |
| Card OLS/RLS | *Report* / *Audience* + name; *RLS* + summary | — |
| Card actions | **View details**, **Reject**, **Approve**, **Revoke** | — |
| Waiting banner | *Waiting for Line Manager approval*, *Waiting for OLS Approver*, *Waiting for previous approval* | — |
| Approve modal | **Approve access request**, **Cancel**, **Approve access** | Approve (button is "Approve access") |
| Reject modal | **Reject access request**, **Reason for rejection** (required), *Please provide a reason for rejecting this request...*, **Cancel**, **Reject request** | — |
| Revoke modal | **Revoke access request**, **Reason for revocation** (required), *Please explain why you are revoking this request...*, **Cancel**, **Revoke request** | — |
| Toasts | *Request [code] approved successfully*, *Request [code] rejected*, *Please provide a reason for rejection*, *A revocation reason is required* | — |
| Pagination | *X–Y of Z* | — |
