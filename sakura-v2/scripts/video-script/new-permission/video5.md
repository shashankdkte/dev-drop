# Video 5 – Request States and Wrap-up

**Frontend-verified:** Every label and place mentioned below exists in the app. Do not say anything that is not in this script or the checklist.

---

## 1. Introduction (≈15 s)

- "In this final video we'll summarise the request states you see in Sakura and how they fit into the end-to-end workflow. We'll also recap what we've covered in this series."

---

## 2. Where you see request state (≈25 s)

- "Request state appears in several places. In **My requests**, the **Status** column shows the current state for each request, and the **Status** filter uses the same values. On the **request detail** page, the status badge next to the request code shows the same state. In **My approvals**, the **Pending** tab shows requests that are still in progress, and the **History** tab shows completed ones—with outcome badges **Approved**, **Rejected**, or **Revoked**. The **Outcome** filter on History uses **Pending**, **Approved**, **Rejected**, **Revoked**, and **Cancelled**."

---

## 3. The request states (≈45 s)

- "**Pending** — The request is in progress. It is waiting for one or more approvals. In the system this can be **Pending LM** (waiting for Line Manager), **Pending OLS** (waiting for OLS Approver), or **Pending RLS** (waiting for RLS Approver). When you create a request, the success modal says *Status: Pending LM*. In **My requests** and on the request detail page you'll see **Pending** until the request reaches a final state."
- "**Approved** — All required approvers have approved. Access is granted according to the OLS and RLS you requested."
- "**Rejected** — An approver has rejected the request. The requester would need to submit a new request if access is still required."
- "**Revoked** — Access that was previously granted has been revoked by an approver. An approver can revoke from **My approvals** (Pending or History) when the request is in a revocable state."
- "**Cancelled** — The requester has cancelled the request before it was fully approved. They can do this from the request detail page with **Cancel request** when the request is still Pending."

---

## 4. Flow from creation to final state (≈40 s)

- "Here's how a request moves through the system. **Create** — The requester goes to **New permission request** in the sidebar, fills the form, and submits. The request is created and appears with *Status: Pending LM*."
- "**Line Manager** — The Line Manager sees it in **My approvals** under **Line Manager** (or **All**). They can **Approve** or **Reject**. If they reject, the request goes to **Rejected** and stops. If they approve, the request moves to the next stage—**Pending OLS** or **Pending RLS** depending on type."
- "**OLS Approver / RLS Approver** — For OLS-only requests, the OLS Approver acts next. For RLS-only, the RLS Approver. For combined requests, OLS Approver first, then RLS Approver. Each can **Approve**, **Reject**, or **Revoke** (when allowed). Reject or Revoke leads to **Rejected** or **Revoked**. When all required stages approve, the request becomes **Approved**."
- "**Requester** — The requester can watch progress in **My requests** and open the request detail to see the **Approval chain**. They can **Cancel request** while the request is still Pending."

---

## 5. Simple workflow diagram (say aloud) (≈20 s)

- "You can think of it as: **New permission request** → submit → **Pending LM** → Line Manager approves → **Pending OLS** or **Pending RLS** (or both in sequence for combined) → OLS/RLS approvers approve → **Approved**. At any stage, Reject → **Rejected**; Revoke → **Revoked**; Requester cancels → **Cancelled**. Only **Approved** means access is granted."

---

## 6. Governance recap (≈25 s)

- "This workflow gives you **controlled** access—every request goes through defined approvers. It's **auditable**—you can see who requested what, who approved or rejected, and when. And it's **governed**—Line Manager first, then OLS or RLS approvers, with no bypass. Requesters use **New permission request**; they track requests in **My requests** and open **View details** for the full picture. Approvers use **My approvals** with **Pending** and **History**, filter by **Line Manager**, **OLS Approver**, or **RLS Approver**, and use **Approve**, **Reject**, or **Revoke** as appropriate."

---

## 7. Series recap and close (≈20 s)

- "In this series we covered: creating a permission request from **New permission request**; OLS-only, RLS-only, and combined requests; **My requests** and request details; **My approvals** and the approval flow; and the request states—Pending, Approved, Rejected, Revoked, and Cancelled. For more detail on any step, rewatch the corresponding video. Thank you for watching."

---

## Frontend checklist – do NOT say if not in the UI

| Where | Say this (exact) | Do NOT say |
|-------|------------------|------------|
| My requests | **Status** column, **Status** filter | — |
| Status / Outcome options | **Pending**, **Approved**, **Rejected**, **Revoked**, **Cancelled** | — |
| Request detail | Status badge (Pending, Approved, Rejected, Revoked, Cancelled) | — |
| My approvals | **Pending** tab, **History** tab, outcome badge **Approved** / **Rejected** / **Revoked**, **Outcome** filter | — |
| Success modal (create) | *Status: Pending LM* | — |
| Internal / technical | **Pending LM**, **Pending OLS**, **Pending RLS** (from constants; OK to mention as “in the system” or “under the hood”) | Don’t promise these exact labels in every screen—detail page shows “Pending” for any in-progress state |
| Cancel | **Cancel request** (on request detail when Pending) | — |
| Sidebar / pages | **New permission request**, **My requests**, **My approvals** | — |
| Approval roles | **Line Manager**, **OLS Approver**, **RLS Approver** | — |
| Actions | **Approve**, **Reject**, **Revoke** | — |

**Note:** The app uses a single **Pending** label in the request detail and My requests for any in-progress request. The granular labels **Pending LM**, **Pending OLS**, **Pending RLS** are used internally and in the create success modal; you may refer to them when explaining the flow.
