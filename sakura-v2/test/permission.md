# Permission Request UI — Complete Test Plan

A structured test plan for end-to-end UI testing of the Permission Request feature. Covers form creation, the wizard flow, approval actions, cancellations, revocations, and validation errors across all six workspaces.

---

## How to Read This Document

- **Who** = the role performing the action
- **Expected UI** = what the UI should show / what happens on screen
- **Expected state** = the resulting `RequestStatus` and per-header `ApprovalStatus`
- ✅ = action should succeed | ❌ = action should be blocked

---

## Quick Reference — Status Codes

### Request Status

| # | Label | Meaning |
|---|-------|---------|
| 0 | Pending LM | Waiting for Line Manager |
| 1 | Pending OLS | LM approved; waiting for OLS approver |
| 2 | Pending RLS | OLS done (or skipped); waiting for RLS approver |
| 3 | Approved | Fully approved — access granted |
| 4 | Rejected | Rejected at some step — final |
| 5 | Revoked | Access revoked after approval — final |
| 6 | Cancelled | Cancelled by requester while pending — final |

### Per-Header Approval Status

| # | Label |
|---|-------|
| 0 | Not started |
| 1 | Pending |
| 2 | Approved |
| 3 | Rejected |
| 4 | Revoked |
| 5 | Cancelled |

---

## Part 1 — Request Form Creation (Wizard)

### Section 1.1 — Entry Points

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| EP-01 | Open wizard from "New Request (Report Catalogue)" | Click Requests → New Request (Report Catalogue) | Report search page loads, search box visible |
| EP-02 | Open wizard from "New Request (Advanced)" | Click Requests → New Request (Advanced) | Workspace selector loads |
| EP-03 | Pre-loaded via reportTag URL parameter | Navigate to URL with `?reportTag=XXXX` | Wizard opens with the specified report pre-selected |
| EP-04 | "Help me" before workspace is known | Click "Help me" on first wizard step | Routes help request to GoTo/Sakura Support, no workspace shown |
| EP-05 | "Help me" after workspace is selected | Click "Help me" at a mid-wizard step where workspace is known | Routes help request to the Workspace Owner's email |

---

### Section 1.2 — Report Catalogue Flow (Guided Mode)

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| RC-01 | Search returns results | Type partial report name | Filtered results list shows; SAR/AUR type labelled for each result |
| RC-02 | No results found | Type a string with no matches | "No results found" message shown; no list |
| RC-03 | Select a SAR report with no existing access | Select a SAR report | System proceeds to OLS step (OLS approver resolved); Security Model step appears |
| RC-04 | Select a SAR report with existing OLS access | Select a SAR for which user already has access | Prompt: "You already have access. Do you want to change RLS only?" shown |
| RC-04a | — Confirm yes (RLS-only change) | Click "Yes" on the prompt | Wizard skips OLS; jumps to Security Model / RLS steps |
| RC-04b | — Confirm no (no change needed) | Click "No" | Wizard ends; no request created |
| RC-05 | Select an AUR report — multiple audiences | Select a report linked to multiple audiences | List of audiences is shown; user must pick one |
| RC-06 | Select an AUR report — single audience | Select a report linked to only one audience | Audience is auto-selected; wizard continues without user selection |
| RC-07 | Select an AUR audience with no existing access | Select audience | Wizard proceeds to OLS step |
| RC-08 | Select an AUR audience with existing access | Select audience the user already has | Prompt: "You already have access. Do you want to change RLS only?" |

---

### Section 1.3 — Advanced Mode Flow

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| ADV-01 | Select workspace | Open Advanced mode; choose a workspace | App/Audience picker and SAR picker appear |
| ADV-02 | Select App + Audience — no access | Pick Workspace App, select an audience | Wizard finds OLS approver and proceeds |
| ADV-03 | Select Standalone Report (SAR) — no access | Pick SAR option | Wizard finds OLS approver and proceeds |
| ADV-04 | Selected object — access exists | Pick an App/Audience or SAR the user already has | "Only RLS change?" prompt shown |
| ADV-05 | "Only RLS" = No | Click No | Wizard ends without submission |
| ADV-06 | "Only RLS" = Yes | Click Yes | Wizard skips OLS; goes to Security Model / RLS |

---

### Section 1.4 — On-Behalf-Of (Request For Another User)

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| OBO-01 | Request for self | When prompted, leave as "myself" | `RequestedFor` = `RequestedBy` = logged-in user |
| OBO-02 | Request for another user | Select "On behalf of another user"; enter valid email | `RequestedFor` = entered email; wizard continues for that user |
| OBO-03 | On-behalf user has existing access | Enter email of a user who already has access to the selected object | "Access already exists" prompt shown (same as if user had their own access) |
| OBO-04 | Invalid email for "requested for" | Enter a non-existent or malformed email | Validation error shown; cannot proceed |
| OBO-05 | LM auto-resolved for requested-for user | After entering the `RequestedFor` email | System calls Workday and pre-fills LM approver field; displayed to user |
| OBO-06 | LM not found in Workday | Enter an email for which Workday returns no manager | Error or warning shown; wizard cannot proceed without LM |

---

### Section 1.5 — Security Model Selection

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| SM-01 | Single Security Model available | Reach Security Model step on a workspace with one model | Model is auto-selected; step shows the single selection highlighted |
| SM-02 | Multiple Security Models | Reach Security Model step on a workspace with multiple models | List of models shown; user must pick one |
| SM-03 | User has existing RLS on a model | Select a model where user already has RLS access | Prompt: "Reuse existing RLS?" shown |
| SM-03a | Reuse existing RLS | Click "Yes, reuse" | Wizard skips to Summary; no new RLS dimensions selected |
| SM-03b | Define new RLS | Click "No, define new" | Wizard continues to Security Type selection |

---

### Section 1.6 — Domain-Specific RLS Wizard: GI (Growth Insights)

Two security types: **MSS** and **SL/PA**

#### GI — MSS Security Type

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| GI-MSS-01 | Select org level = Global | Pick "Global" for Organisation | Entity step is skipped; wizard jumps to Client |
| GI-MSS-02 | Select org level = Cluster; pick entity | Pick "Cluster"; select "DACH" | Entity DACH shown selected |
| GI-MSS-03 | Client = All Clients | Select "All Clients" | No specific client picker shown |
| GI-MSS-04 | Client = Specific Client | Select "Specific Client (Dentsu Stakeholder)"; pick a client | Client selector appears and shows specific client name |
| GI-MSS-05 | MSS = Overall (L0) | Select "Overall / L0" | SLKey = TOTALPA/L0 |
| GI-MSS-06 | MSS = specific (e.g. L1 CREATIVE) | Select L1 → "CREATIVE" | Service Line step follows |
| GI-MSS-07 | Service Line = TOTALPA | Select TOTALPA | SLKey = TOTALPA |
| GI-MSS-08 | Service Line = specific (e.g. CRTV) | Select specific SL | SLKey = the code (e.g. CRTV) |
| GI-MSS-09 | No RLS approver found for combination | Pick a rare combination with no approver configured | Wizard shows "No approver found" and cannot proceed to submit |

#### GI — SL/PA Security Type

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| GI-SL-01 | MSS step not shown | Select SL/PA as Security Type | Step 6 (MSS) is absent; flow goes Org → Entity → Client → Service Line |
| GI-SL-02 | All dimensions selected | Complete all steps with valid values | Summary page shows correct combination |

---

### Section 1.7 — Domain-Specific RLS Wizard: WFI (Workforce)

Single security type: People Aggregator (PA)

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| WFI-01 | Org = Global; PA = Overall | Select Global for org, Overall for PA | Entity step skipped; Summary shows Global/Overall |
| WFI-02 | Org = Cluster; PA = Overall | Cluster + DACH + Overall | Full three-step flow; summary correct |
| WFI-03 | Org = Cluster; PA = Business Area | Cluster + DACH + CXM (Business Areas) | PA shown as Business Area type |
| WFI-04 | Org = Market; PA = Business Function | Market + UK + Finance (Business Functions) | Most granular; PA type = Business Functions |
| WFI-05 | No entity selected when org is not Global/NA | Leave entity blank and try to proceed | Validation error: "Entity is required for this org level" |
| WFI-06 | No PA selected | Leave People Aggregator blank and try to proceed | Validation error: "People Aggregator is required" |

---

### Section 1.8 — Domain-Specific RLS Wizard: CDI

Single security type (CDI). Dimensions: Organisation, Client, SL.

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| CDI-01 | Global org, All Clients, All SL | Global + All Clients + TOTALPA | Broadest CDI access; no entity or specific client picker |
| CDI-02 | Market-level org + specific client + specific SL | Market + entity + specific client + specific SL | Most granular CDI access |
| CDI-03 | No approver found | Rare org/client/SL combination | Wizard terminates with "No approver found" message |

---

### Section 1.9 — Domain-Specific RLS Wizard: DFI / FUM

Dimensions: Organisation, Country, Client, MSS, ProfitCenter.

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| DFI-01 | All-access request | Global + All Countries + All Clients + Overall MSS + All Profit Centers | Maximum-scope summary shown |
| DFI-02 | Specific entity + specific country | Market + Germany + specific client | Step for country selection active |
| DFI-03 | No approver found | Unusual combination | Wizard terminates |

---

### Section 1.10 — Domain-Specific RLS Wizard: AMER

Security types: **Orga**, **Client**, **CC**, **PC**. Dimensions: Organisation, SL, Client, PC, CC, PA, MSS.

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| AMER-01 | Security type = Orga | Select Orga security type | Org + SL dimensions shown |
| AMER-02 | Security type = Client | Select Client | Org + Client dimensions shown |
| AMER-03 | Security type = CC (Cost Center) | Select CC | Org + CC dimensions shown |
| AMER-04 | Security type = PC (Profit Center) | Select PC | Org + PC dimensions shown |
| AMER-05 | CC/PC only at Legal Entity level | Select entity above Legal Entity for CC type | Warning: "CC/PC available at Legal Entity level only"; higher-level options greyed/removed |
| AMER-06 | No approver found | Rare dimension combo | Wizard terminates with message |

---

### Section 1.11 — Domain-Specific RLS Wizard: EMEA

Security types: **Orga-SL/PA**, **Client**, **CC**, **Country**, **Orga-MSS**. Dimensions: Organisation, SL, Client, CC, Country, MSS.

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| EMEA-01 | Security type = Orga-SL/PA | Select Orga-SL/PA | Org + SL dimensions |
| EMEA-02 | Security type = Client | Select Client | Org + Client dimensions |
| EMEA-03 | Security type = CC | Select CC | Org + CC; Legal Entity restriction applies |
| EMEA-04 | Security type = Country | Select Country | Country dimension shown |
| EMEA-05 | Security type = Orga-MSS | Select Orga-MSS | Org + MSS dimensions |
| EMEA-06 | CC at non-Legal-Entity org | Pick org level above Legal Entity with CC type | Same Legal Entity restriction applies |
| EMEA-07 | No approver found | Unusual combo | Wizard terminates |

---

### Section 1.12 — Approver Preview & Summary Screen

| # | Test | Steps | Expected UI |
|---|------|-------|-------------|
| SUM-01 | Summary shows OLS details | Complete OLS steps; reach summary | Report/Audience name, OLS Approver email shown |
| SUM-02 | Summary shows RLS details | Complete RLS steps; reach summary | Security Model, Security Type, all dimension selections shown |
| SUM-03 | Summary shows both OLS + RLS | Complete both; reach summary | Both sections rendered, each with their approver |
| SUM-04 | Summary shows existing access | User with pre-existing access reaching summary | "You already have this access" section visible |
| SUM-05 | LM approver shown | At summary | LM email (resolved from Workday) displayed |
| SUM-06 | Business reason displayed | Enter reason during wizard; view summary | Reason text shown in summary |
| SUM-07 | Submit button enabled | All required fields complete | "Submit" / "Finish" button is active |
| SUM-08 | Submit button disabled | Required field missing | "Submit" button greyed out |
| SUM-09 | Successful submission | Click Submit | Confirmation message shown; request created; email confirmation received |
| SUM-10 | Duplicate active request | Submit same OLS/RLS combo when a pending request already exists | System should warn or block duplicate; behaviour per implementation |

---

## Part 2 — Approval Flow Testing

### Section 2.1 — Line Manager (LM) Actions

| # | State before | Action | Who | Expected request status | Expected header status |
|---|-------------|--------|-----|------------------------|----------------------|
| LM-01 | OLS-only: Status=0 | Approve | LM | 1 (Pending OLS) | OLS → 1 (Pending) |
| LM-02 | RLS-only: Status=0 | Approve | LM | 2 (Pending RLS) | RLS → 1 (Pending) |
| LM-03 | OLS+RLS: Status=0 | Approve | LM | 1 (Pending OLS) | OLS → 1 (Pending); RLS stays 0 |
| LM-04 | Any: Status=0 | Reject (with reason) | LM | 4 (Rejected) | All headers → 3 (Rejected) |
| LM-05 | Status=0, reject | No reason entered | LM | ❌ Blocked — reason is mandatory | Unchanged |
| LM-06 | Status=1 | Try to Approve LM again | LM | ❌ 400 — "Request is not in LM approval stage" | Unchanged |
| LM-07 | Status=2 | Try to Approve LM | LM | ❌ 400 — "Request is not in LM approval stage" | Unchanged |
| LM-08 | Status=3 | Try to Approve LM | LM | ❌ 400 — "Request is not in LM approval stage" | Unchanged |
| LM-09 | Status=4/5/6 | Try to Approve or Reject LM | LM | ❌ 400 — final state | Unchanged |
| LM-10 | Status=0 (LM via email link) | Click Approve link in email | LM | Same as LM-01/02/03 | Correct transition |
| LM-11 | Status=0 (LM via email link) | Click Reject link in email; enter reason | LM | 4 (Rejected) | All → 3 |

---

### Section 2.2 — OLS Approver Actions

| # | State before | Action | Who | Expected result |
|---|-------------|--------|-----|-----------------|
| OLS-01 | OLS-only: Status=1, OLS=1 | Approve | OLS Approver | Status → 3 (Approved); OLS → 2 (Approved) |
| OLS-02 | OLS+RLS: Status=1, OLS=1 | Approve | OLS Approver | Status → 2 (Pending RLS); OLS → 2 (Approved); RLS → 1 (Pending) |
| OLS-03 | Status=1, OLS=1 | Reject (with reason) | OLS Approver | Status → 4 (Rejected); OLS → 3; if OLS+RLS → RLS → 3 too |
| OLS-04 | Status=1, reject | No reason entered | OLS Approver | ❌ Blocked — reason is mandatory |
| OLS-05 | Status=0, OLS=0 | Try to Approve OLS | OLS Approver | ❌ 400 — stage validation fails (not in OLS stage) |
| OLS-06 | Status=2, OLS=2 | Try to Approve OLS | OLS Approver | ❌ 400 — stage validation fails |
| OLS-07 | Status=3, OLS=2 | Try to Approve OLS | OLS Approver | ❌ 400 — header not in pending state |
| OLS-08 | Status=1, OLS=1 | Revoke (with reason) | OLS Approver | OLS → 4 (Revoked); if all headers final → Status → 5 (Revoked) |
| OLS-09 | Status=3 (approved), OLS=2 | Revoke (with reason) | OLS Approver | OLS → 4; triggers revokeAll → Status → 5 (Revoked) |
| OLS-10 | Status=4, OLS=3 | Try to Revoke | OLS Approver | ❌ 400 — "Request cannot be revoked in its current state" |
| OLS-11 | Status=5, OLS=4 | Try to Revoke | OLS Approver | ❌ 400 — already final |
| OLS-12 | Any active, revoke | No reason entered | OLS Approver | ❌ Blocked — revoke reason is mandatory |
| OLS-13 | OLS header already Revoked/Rejected/Cancelled | Try single-header revoke | OLS Approver | ❌ 400 — "This permission header is already in a final state" |

---

### Section 2.3 — RLS Approver Actions

| # | State before | Action | Who | Expected result |
|---|-------------|--------|-----|-----------------|
| RLS-01 | RLS-only: Status=2, RLS=1 | Approve | RLS Approver | Status → 3 (Approved); RLS → 2 (Approved) |
| RLS-02 | OLS+RLS: Status=2, RLS=1 | Approve | RLS Approver | Status → 3 (Approved); OLS stays 2; RLS → 2 |
| RLS-03 | Status=2, RLS=1 | Reject (with reason) | RLS Approver | Status → 4; RLS → 3; OLS → 3 (cascade) |
| RLS-04 | Status=2, reject | No reason | RLS Approver | ❌ Blocked — reason mandatory |
| RLS-05 | Status=0, RLS=0 | Try to Approve RLS | RLS Approver | ❌ 400 — not in RLS stage |
| RLS-06 | Status=1, RLS=0 | Try to Approve RLS | RLS Approver | ❌ 400 — not in RLS stage |
| RLS-07 | Status=3, RLS=2 | Try to Approve RLS | RLS Approver | ❌ 400 — not in pending state |
| RLS-08 | Status=2, RLS=1 | Revoke (with reason) | RLS Approver | RLS → 4; if all headers final → Status → 5 |
| RLS-09 | Status=3, RLS=2 | Revoke (with reason) | RLS Approver | Status → 5; all headers → 4 (via revokeAll) |
| RLS-10 | Status=4, RLS=3 | Try to Revoke | RLS Approver | ❌ 400 — cannot revoke final state |
| RLS-11 | Any active, revoke | No reason | RLS Approver | ❌ Blocked — mandatory |
| RLS-12 | Status=4 (after OLS rejection) | Try to Approve RLS | RLS Approver | ❌ 400 — stage validation fails |

---

### Section 2.4 — Requester Actions (Cancel)

| # | Cancel when | Expected result |
|---|-------------|-----------------|
| CAN-01 | Status=0 (Pending LM) | Status → 6 (Cancelled); all headers → 5 (Cancelled) |
| CAN-02 | Status=1 (Pending OLS) | Status → 6 (Cancelled); all headers → 5 (Cancelled) |
| CAN-03 | Status=2 (Pending RLS) | Status → 6 (Cancelled); all headers → 5 (Cancelled) |
| CAN-04 | Status=3 (Approved) | ❌ 400 — "Cannot cancel finalized request" |
| CAN-05 | Status=4 (Rejected) | ❌ 400 — "Cannot cancel finalized request" |
| CAN-06 | Status=5 (Revoked) | ❌ 400 — "Cannot cancel finalized request" |
| CAN-07 | Status=6 (already Cancelled) | ❌ 400 — "Cannot cancel finalized request" |
| CAN-08 | Cancel from My Requests page | Navigate to My Requests; click Cancel on a pending request | Confirmation prompt shown; on confirm → Status → 6 |

---

## Part 3 — Full End-to-End Scenarios (Happy Path)

### Scenario E2E-A: OLS-Only — Full Approval

| # | Step | Who | Request Status | OLS Status |
|---|------|-----|----------------|------------|
| A1 | Submit OLS-only request (SAR, any workspace) | Requester | 0 — Pending LM | 0 — Not started |
| A2 | LM receives email; approves | Line Manager | 1 — Pending OLS | 1 — Pending |
| A3 | OLS Approver receives email; approves | OLS Approver | 3 — Approved | 2 — Approved |
| A4 | Requester sees "Approved" in My Requests | Requester | 3 | 2 |
| A5 | OLS Approver revokes (with reason) | OLS Approver | 5 — Revoked | 4 — Revoked |

---

### Scenario E2E-B: RLS-Only — Full Approval

| # | Step | Who | Request Status | RLS Status |
|---|------|-----|----------------|------------|
| B1 | Submit RLS-only request (existing OLS access; RLS change only) | Requester | 0 — Pending LM | 0 — Not started |
| B2 | LM approves | Line Manager | 2 — Pending RLS | 1 — Pending |
| B3 | RLS Approver approves | RLS Approver | 3 — Approved | 2 — Approved |
| B4 | Requester sees Approved | Requester | 3 | 2 |
| B5 | RLS Approver revokes | RLS Approver | 5 — Revoked | 4 — Revoked |

---

### Scenario E2E-C: OLS+RLS — Full Approval + RevokeAll

| # | Step | Who | Request Status | OLS | RLS |
|---|------|-----|----------------|-----|-----|
| C1 | Submit OLS+RLS request | Requester | 0 — Pending LM | 0 | 0 |
| C2 | LM approves | LM | 1 — Pending OLS | 1 — Pending | 0 — Not started |
| C3 | OLS Approver approves | OLS Approver | 2 — Pending RLS | 2 — Approved | 1 — Pending |
| C4 | RLS Approver approves | RLS Approver | 3 — Approved | 2 | 2 |
| C5 | UI calls revokeAll (either approver, with reason) | OLS or RLS Approver | 5 — Revoked | 4 — Revoked | 4 — Revoked |

---

### Scenario E2E-D: LM Rejects

| # | Step | Who | Request Status | All Header Statuses |
|---|------|-----|----------------|---------------------|
| D1 | Submit any request | Requester | 0 — Pending LM | 0 — Not started |
| D2 | LM rejects (with mandatory reason) | LM | 4 — Rejected | all → 3 — Rejected |
| D3 | Requester sees reason in email / My Requests | Requester | 4 | 3 |
| D4 | LM tries to approve again | LM | ❌ 400 — "not in LM stage" | Unchanged |

---

### Scenario E2E-E: OLS Rejects (OLS+RLS Request)

| # | Step | Who | Request Status | OLS | RLS |
|---|------|-----|----------------|-----|-----|
| E1 | Submit OLS+RLS | Requester | 0 | 0 | 0 |
| E2 | LM approves | LM | 1 | 1 — Pending | 0 |
| E3 | OLS rejects (with reason) | OLS Approver | 4 — Rejected | 3 — Rejected | 3 — Rejected (cascade: "Rejected due to OLS rejection") |
| E4 | RLS Approver tries to approve | RLS Approver | ❌ 400 — stage validation fails | Unchanged | Unchanged |

---

### Scenario E2E-F: RLS Rejects (OLS+RLS Request)

| # | Step | Who | Request Status | OLS | RLS |
|---|------|-----|----------------|-----|-----|
| F1 | Submit OLS+RLS | Requester | 0 | 0 | 0 |
| F2 | LM approves | LM | 1 | 1 | 0 |
| F3 | OLS approves | OLS Approver | 2 — Pending RLS | 2 — Approved | 1 — Pending |
| F4 | RLS rejects (with reason) | RLS Approver | 4 — Rejected | 3 — Rejected (cascade) | 3 — Rejected |
| F5 | OLS Approver tries to revoke (request is Rejected) | OLS Approver | ❌ 400 — "cannot be revoked in current state" | Unchanged | Unchanged |

---

### Scenario E2E-G: Requester Cancels at Every Stage

| # | Cancel when (OLS+RLS request) | Who | Request Status | OLS | RLS |
|---|-------------------------------|-----|----------------|-----|-----|
| G1 | Status=0 (Pending LM) | Requester | 6 — Cancelled | 5 | 5 |
| G2 | Status=1 (Pending OLS) — after LM approved | Requester | 6 — Cancelled | 5 | 5 |
| G3 | Status=2 (Pending RLS) — after OLS approved | Requester | 6 — Cancelled | 5 | 5 |
| G4 | Status=3 (Approved) | Requester | ❌ 400 | Unchanged | Unchanged |
| G5 | Status=4 (Rejected) | Requester | ❌ 400 | Unchanged | Unchanged |
| G6 | Status=5 (Revoked) | Requester | ❌ 400 | Unchanged | Unchanged |

---

## Part 4 — Edge Cases & Special Conditions

### Section 4.1 — Approver Resolution Edge Cases

| # | Condition | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | RLS approver not found for dimension combo | Wizard terminates at "Approver Detection" step; no submission possible; message shown |
| EC-02 | OLS approver not found for report/audience | Wizard terminates; cannot proceed |
| EC-03 | LM not found in Workday for the requested-for user | LM email field blank or error shown; submission blocked |
| EC-04 | Approver configured with wildcard match ("All Clients") | Request routes to that approver; summary shows their name |
| EC-05 | Approver configured at higher org hierarchy (Region) | Score-based best-match traverses up from Market → Cluster → Region until match found |

---

### Section 4.2 — Approval Mode Variants

| # | Configuration | Expected Behaviour |
|---|--------------|-------------------|
| AM-01 | Approval Mode = AppBased | OLS Approver is defined at the App level; same approver for all audiences in the app |
| AM-02 | Approval Mode = AudienceBased | OLS Approver is defined per audience; different audiences can have different approvers |
| AM-03 | Report Delivery = SAR | OLS Approver defined on the Report itself (not on App or Audience) |
| AM-04 | Report Delivery = AUR | OLS Approver defined per App/Audience depending on Approval Mode |

---

### Section 4.3 — Delegation

| # | Condition | Expected Behaviour |
|---|-----------|-------------------|
| DEL-01 | Approver has an active delegate | Both the original approver and delegate appear in approver list; either can approve |
| DEL-02 | Delegate approves the request | Request moves to next stage; notification shows delegate acted on behalf of approver |
| DEL-03 | Delegation period expires mid-approval | Delegate access removed; original approver is sole actor again |
| DEL-04 | Requester is informed of delegate approval | Notification email references the delegate's name |

---

### Section 4.4 — Notifications & Email

| # | Trigger | Who Receives | Expected Email Content |
|---|---------|-------------|----------------------|
| NOT-01 | Request submitted | Requester | Confirmation; request reference number; submission date; summary |
| NOT-02 | LM approval required | Line Manager | Request summary; "Approve" and "Reject" links |
| NOT-03 | LM approves | Requester | "Your LM approved your request" notification |
| NOT-04 | LM rejects | Requester | Rejection reason; guidance to resubmit |
| NOT-05 | OLS approval required | OLS Approver | Request summary; Approve / Reject links |
| NOT-06 | OLS approves | Requester | OLS step approved notification |
| NOT-07 | OLS rejects | Requester | Rejection reason from OLS Approver |
| NOT-08 | RLS approval required | RLS Approver | Request summary; Approve / Reject links |
| NOT-09 | RLS approves | Requester | Access granted notification |
| NOT-10 | RLS rejects | Requester | Rejection reason |
| NOT-11 | Revoked by approver | Requester | Revocation reason; guidance to resubmit |
| NOT-12 | Cancelled by requester | — | Confirmation to requester only |

---

### Section 4.5 — My Requests Page

| # | Test | Expected UI |
|---|------|-------------|
| MR-01 | View My Requests as requester (self-requested) | All requests where `RequestedBy = me` visible |
| MR-02 | View My Requests as "requested by" (on behalf) | Requests submitted by me for others visible |
| MR-03 | View My Requests where someone requested for me | Requests where `RequestedFor = me` but `RequestedBy = someone else` visible |
| MR-04 | OLS and RLS shown separately | Each header appears as its own row |
| MR-05 | All statuses shown | Pending, Approved, Rejected, Revoked, Cancelled all visible |
| MR-06 | Click request → detail page | Detail page opens (read-only); full metadata, approval chain timeline shown |
| MR-07 | Contextual links in detail page | Links to Workspace App, Audience/SAR, Security Model, Approvers navigate correctly |

---

### Section 4.6 — My Approvals Page

| # | Test | Expected UI |
|---|------|-------------|
| MA-01 | LM Approvals tab | Only requests where current user is the Line Manager and status = 0 appear under "Awaiting Approval" |
| MA-02 | OLS Approvals tab | Only OLS headers assigned to current user and in Pending (1) state appear |
| MA-03 | RLS Approvals tab | Only RLS headers assigned to current user and in Pending (1) state appear |
| MA-04 | Filter: Awaiting Approval | Shows only items in Pending state |
| MA-05 | Filter: Approved | Shows historically approved items only |
| MA-06 | Approver no longer assigned to a security model | Past records visible (read-only); new pending items not shown |
| MA-07 | Email link to approve | Clicking email link redirects to secure approval screen; identity validated |
| MA-08 | Approve from My Approvals | Request moves to next stage; entry disappears from "Awaiting Approval" list |
| MA-09 | Reject from My Approvals — no reason | ❌ Blocked; reason field validation error shown |
| MA-10 | Reject from My Approvals — with reason | Request moves to Rejected state; disappears from "Awaiting" list |
| MA-11 | Revoke from My Approvals (OLS/RLS only) — no reason | ❌ Blocked |
| MA-12 | Revoke from My Approvals — with reason | Request/headers move to Revoked state |
| MA-13 | LM tab — no Revoke button | Revoke is not available to Line Managers; button absent |

---

### Section 4.7 — Wrong-Stage Actions (Expect UI Errors / 400)

| # | Attempt | When | Expected error message |
|---|---------|------|----------------------|
| WS-01 | LM approve | Status = 1 (Pending OLS) | "Request is not in LM approval stage" |
| WS-02 | LM approve | Status = 3 (Approved) | "Request is not in LM approval stage" |
| WS-03 | OLS approve | Status = 0 (Pending LM) | Stage validation fails |
| WS-04 | OLS approve | Status = 2 (Pending RLS) | Stage validation fails |
| WS-05 | RLS approve | Status = 0 (Pending LM) | Stage validation fails |
| WS-06 | RLS approve | Status = 1 (Pending OLS) | Stage validation fails |
| WS-07 | Revoke OLS/RLS | Status = 4 (Rejected) | "Request cannot be revoked in its current state" |
| WS-08 | Revoke OLS/RLS | Status = 5 (Revoked) | "Request cannot be revoked in its current state" |
| WS-09 | Revoke OLS/RLS | Status = 6 (Cancelled) | "Request cannot be revoked in its current state" |
| WS-10 | Revoke with blank reason | Any active state | "Revoke reason is mandatory" |
| WS-11 | Reject with blank reason (LM/OLS/RLS) | Any pending state | "Reason is required" |
| WS-12 | Revoke header already in final state | Header = Revoked / Rejected / Cancelled | "This permission header is already in a final state" |

---

### Section 4.8 — Concurrency Token

| # | Test | Expected Behaviour |
|---|------|-------------------|
| CT-01 | Action sent with valid ConcurrencyToken | Action succeeds |
| CT-02 | Action sent with stale token (another action was performed concurrently) | 409 Conflict or 400; user prompted to refresh and retry |
| CT-03 | Action uses header's token instead of root request's token | ❌ Validation fails — always use root request's `ConcurrencyToken` |

---

### Section 4.9 — Permission Request Variants — Type Matrix

| Variant | LM Stage | OLS Stage | RLS Stage | Final Status path |
|---------|----------|-----------|-----------|-------------------|
| OLS-only | ✅ | ✅ | ✗ | 0 → 1 → 3 (happy) |
| RLS-only | ✅ | ✗ | ✅ | 0 → 2 → 3 (happy) |
| OLS+RLS | ✅ | ✅ | ✅ | 0 → 1 → 2 → 3 (happy) |

> Test each variant for: approve all, LM reject, OLS reject (if applicable), RLS reject (if applicable), requester cancel, approver revoke.

---

## Part 5 — Workspace-Specific Approval Mode Matrix

For each workspace, test both applicable report delivery methods:

| Workspace | Delivery Method(s) | Approval Mode(s) | Key security types to test |
|-----------|--------------------|------------------|---------------------------|
| GI | SAR + AUR | AppBased / AudienceBased | MSS, SL/PA |
| WFI | SAR + AUR | AppBased / AudienceBased | PA (Overall, Business Area, Business Function) |
| CDI | SAR + AUR | AppBased / AudienceBased | CDI (single type) |
| DFI/FUM | SAR + AUR | AppBased / AudienceBased | FUM (Organisation, Country, Client, MSS, ProfitCenter) |
| AMER | SAR + AUR | AppBased / AudienceBased | Orga, Client, CC, PC |
| EMEA | SAR + AUR | AppBased / AudienceBased | Orga-SL/PA, Client, CC, Country, Orga-MSS |

For each row, run at minimum: OLS-only happy path, RLS-only happy path, OLS+RLS happy path, LM rejection, and approver revocation.

---

## Part 6 — Summary Checklist

Use this as a quick smoke-test pass after a deployment:

- [ ] Wizard opens from both entry points (Report Catalogue + Advanced)
- [ ] reportTag URL pre-loading works
- [ ] On-behalf-of request creates correct `RequestedBy` / `RequestedFor`
- [ ] LM is auto-resolved from Workday on email blur
- [ ] Wizard terminates gracefully when no approver found
- [ ] OLS-only: LM → OLS → Approved
- [ ] RLS-only: LM → RLS → Approved (skips OLS state 1)
- [ ] OLS+RLS: LM → OLS → RLS → Approved
- [ ] LM rejection cascades to all headers
- [ ] OLS rejection cascades to RLS header (with "due to OLS rejection" note)
- [ ] RLS rejection cascades to OLS header
- [ ] Requester can cancel at states 0, 1, 2 — blocked at 3, 4, 5, 6
- [ ] Revoke requires a mandatory reason
- [ ] revokeAll from UI sets all headers to Revoked in single transaction
- [ ] My Requests shows correct status for all request states
- [ ] My Approvals shows correct Awaiting/Approved tabs
- [ ] Email links from approval emails work and redirect to secure screen
- [ ] Rejection and revocation reasons appear in requester emails
- [ ] Delegation: delegate can approve on behalf of original approver
- [ ] ConcurrencyToken validation prevents double-submission
