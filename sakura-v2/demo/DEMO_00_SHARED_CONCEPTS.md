# Sakura V2 — Shared Concepts (All Domains)

This document explains **cross-cutting concepts** that apply to every Sakura domain. Use it as the foundation before diving into domain-specific demos.

---

## Table of Contents

1. [Key Terms and Concepts](#1-key-terms-and-concepts)
2. [How Components Interact](#2-how-components-interact)
3. [Share OLS and Share RLS](#3-share-ols-and-share-rls)
4. [How Security Is Consumed in Power BI](#4-how-security-is-consumed-in-power-bi)
5. [Managed OLS vs Unmanaged OLS](#5-managed-ols-vs-unmanaged-ols)
6. [Who Can Create Permission Requests](#6-who-can-create-permission-requests)
7. [Approval Process](#7-approval-process)
8. [Rejection, Revocation, and Cancellation](#8-rejection-revocation-and-cancellation)

---

## 1. Key Terms and Concepts

### Apps (WorkspaceApp)

- **What it is:** A Power BI application registered in a workspace. An app groups multiple reports and is tied to an **Entra (Azure AD) group** (at app or audience level).
- **Why it matters:** OLS is enforced at the app or **audience** level. Users approved for an audience are added to that audience’s Entra group and see **all reports** grouped in that audience.
- **Use case:** The GI workspace has an app *GI_MAIN* with audiences that each group specific reports. Users approved for the *Finance* audience are added to that audience’s Entra group and see the Finance audience’s set of reports in the app.

### Audiences (AppAudience) — Workspace App Audience

- **What it is:** A **subdivision of a Workspace App** that **groups specific reports together** for delivery to users. An audience defines **which reports are visible** to anyone who is granted access to that audience — it does **not** define the users themselves.
- **Purpose:** Represents a distinct view configuration within an app: it defines **the set of reports** that authorized individuals are allowed to see when they are granted access to that audience.
- **Functionality:** Audiences define **sets of reports**; the **users** are determined by who is approved for that audience (and thus added to its Entra group). When a user is granted access to an audience, they receive visibility for **all reports** grouped within that audience container.
- **Fabric equivalent:** Functionally equivalent to **Power BI App Audiences** in Microsoft Fabric.
- **Security role (OLS):** In Sakura’s Object-Level Security model, an **audience is a primary unit of access**. Granting a user access to an audience grants them visibility for all reports in that audience. Each audience has its own **Entra group** and can have its own **OLS approvers** when Approval Mode is *AudienceBased*.
- **System identification:** In the database, an audience is identified as **OLSItemType = 1** (distinguishing it from a standalone report, which is **OLSItemType = 0**).
- **Use case:** The GI app has *FINANCE_AUDIENCE* (a report group for finance) and *OPERATIONS_AUDIENCE* (a report group for operations). Reports are linked to these audiences via ReportAppAudienceMap. When a user is approved for *FINANCE_AUDIENCE*, they see all reports in that audience; the Finance OLS approver (if AudienceBased) approves that access.

### Standalone Reports (SAR)

- **What it is:** A report with **delivery method = SAR**. Access is granted **per user**, not via an audience. The report has its own **OLS approvers** (configured on the report). In the database, a standalone report is identified as **OLSItemType = 0** (vs audience = OLSItemType 1).
- **Why it matters:** Used for sensitive or executive reports where access is individual, not via a report-group (audience).
- **Use case:** “CEO Dashboard” is a SAR; each executive’s access is approved individually by the report’s OLS approver.

### Security Model (WorkspaceSecurityModel)

- **What it is:** A named, reusable set of **security types** in a workspace. Reports are linked to one or more security models via **Report–Security Model mapping**.
- **Why it matters:** Defines *which* RLS dimensions apply to a report (e.g. GI Standard = Entity + Client + MSS + SL).
- **Use case:** GI report “Revenue by Client” is linked to security model *GI_STANDARD*; when a user requests it, they choose dimensions from that model.

### Security Types

- **What it is:** A dimension category (e.g. GI, CDI, WFI, FUM, EMEA-ORGA, AMER-CLIENT). Each security type corresponds to a **domain** and determines which **RLS detail table** and which **dimensions** are used.
- **Why it matters:** Different domains use different dimensions (GI: Entity, Client, MSS, SL; WFI: Entity, PA; etc.). Security type drives the request wizard and RLS storage.
- **Use case:** In GI, user picks security type *MSS* or *SL/PA*; the wizard then shows the right dimension steps (e.g. Organisation → Client → MSS → Service Line for MSS).

### Mapping

- **Report–App/Audience (ReportAppAudienceMap):** Links an **AUR** report **to** one or more **audiences**. This defines **which audiences contain which reports** — i.e. which set of reports a user will see when granted access to that audience. When a user requests an AUR report, the map also determines which audience’s approval chain applies.
- **Report–Security Model (ReportSecurityModelMap):** Links a report to one or more **security models**. Determines which RLS models (and thus security types and dimensions) the user can request for that report.
- **Use case:** Report “Monthly Finance Summary” is AUR and **mapped to** *FINANCE_AUDIENCE* — so it is one of the reports in that audience. When a user is granted access to *FINANCE_AUDIENCE*, they see this report (and all others in that audience). The report is also mapped to *GI_STANDARD* so requesters select Entity/Client/MSS/SL for RLS.

### Dimensions

- **What it is:** The actual data attributes used to filter rows in a report (Entity, Client, Service Line, Cost Centre, Country, etc.). Values come from **ref** schema (e.g. `ref.Entities`, `ref.Clients`). Stored as **MapKeys** in RLS detail tables.
- **Why it matters:** RLS = “this user can see rows where Entity = X, Client = Y, SL = Z.” Dimensions are those X, Y, Z.
- **Use case:** User approved for Entity *DE001*, Client *CLIENT_ALPHA*, SL *DIGITAL* — those dimension values are stored in `RLSPermissionGIDetails` and exposed in `ShareGI.RLS` for Power BI.

---

## 2. How Components Interact

- **Workspace** contains **Apps**, **Reports**, **Security Models**, and **RLS Approvers** (per domain).
- **App** has **Audiences** — each audience is a **report group** (a set of reports linked via ReportAppAudienceMap). Each audience has its own Entra group and optional OLS approvers if Approval Mode = AudienceBased. The app also has an **OLSMode** (Managed vs Unmanaged).
- **Report** has **Delivery Method** (AUR or SAR). If **AUR**, the report is **linked to one or more audiences** via ReportAppAudienceMap (so it appears in those audiences’ report sets). All reports are also linked to **Security Models** via ReportSecurityModelMap. If **SAR**, the report is not in an audience; access is per-user with report-level OLS approvers.
- **Security Model** is linked to **Security Types** (LoV); security types define which **dimensions** appear in the RLS wizard and which **RLS detail table** is used.
- **Permission Request** is created when a user submits the wizard. It creates **PermissionHeaders** (one OLS, one RLS) and **OLSPermissions** / **RLSPermissions** + domain-specific RLS detail rows. For OLS, the item is either an **audience** (OLSItemType 1) or a **standalone report** (OLSItemType 0). **Approvers** (LM, OLS, RLS) are resolved from workspace/report/audience and RLS approver tables (with hierarchy traversal).

End-to-end: **User** → **Report Catalogue or Advanced mode** → **Report/Audience + Security Model** → **Dimension selection** → **Approver resolution** → **Submit** → **LM → OLS → RLS** → **Approved** → **Share views** → **Power BI**.

---

## 3. Share OLS and Share RLS

### Share OLS (`Share{W}.OLS`, e.g. `ShareGI.OLS`)

- **Purpose:** Expose **approved OLS permissions** for a workspace so the downstream system (or app owner) knows who can open which reports/audiences.
- **Content:** Rows are **approved** OLS only (`ApprovalStatus = 2`). The OLS item is either an **audience** (OLSItemType = 1) or a **standalone report** (OLSItemType = 0). Includes OLS item code/name, user (`RequestedFor`), request/approval dates, workspace/app/audience identifiers, and **OLSEntraGroupId** (Entra group for that audience or SAR).
- **Important:** In the current design, **Share*.OLS** is used for **Unmanaged** apps only. For **Managed** apps, Sakura syncs users into Entra groups via automation (e.g. `Auto` schema); app owners do not need to read Share OLS for those.
- **Use case:** App owner for an Unmanaged CDI app queries `ShareCDI.OLS` and adds/removes users from the appropriate Entra groups in their own process.

### Share RLS (`Share{W}.RLS`, e.g. `ShareGI.RLS`)

- **Purpose:** Expose **approved RLS permissions** with dimension keys and hierarchy so Power BI/EDP can enforce row-level security.
- **Content:** Joins domain RLS detail table (e.g. `RLSPermissionGIDetails`), `RLSPermissions`, `PermissionHeaders` (ApprovalStatus = 2, PermissionType = RLS), `PermissionRequests`. Exposes dimension keys/hierarchies, SecurityType, RequestedFor, RequestedBy, ApprovedBy, ApprovalDate.
- **Use case:** EDP refreshes a dataset that reads `ShareGI.RLS`; for each user, it applies RLS rules so they only see rows matching their Entity/Client/MSS/SL.

---

## 4. How Security Is Consumed in Power BI

- **Sakura does not enforce access.** It stores approved OLS and RLS and exposes them via **Share*.OLS** and **Share*.RLS**.
- **EDP / Microsoft Fabric** (or the app owner) **pulls** from these views and enforces:
  - **OLS:** User can open a report or app **audience** if they appear in the OLS view for that workspace (or, for Managed apps, if they are in the corresponding Entra group managed by Sakura). **Granting access to an audience** means the user sees **all reports** grouped in that audience.
  - **RLS:** When a user opens a report, the dataset applies RLS rules derived from the RLS view: only rows matching that user’s dimension values (Entity, Client, SL, etc.) are visible.
- **Link between report and RLS:** By **user + workspace**. The RLS view is per workspace; the same user’s RLS for that workspace applies to **all reports** in that workspace that use the same security model/dimensions.

---

## 5. Managed OLS vs Unmanaged OLS

| | Managed OLS | Unmanaged OLS |
|---|-------------|----------------|
| **OLSMode** | 0 (Managed) | 1 (Unmanaged) |
| **Who manages Entra group?** | Sakura (e.g. nightly sync adds/removes users) | App owner (manual or their own process) |
| **Share*.OLS** | Not needed for OLS enforcement (Sakura drives Entra directly) | Used by app owner to see who is approved and to manage their own groups |
| **When access is approved** | User is added to Entra group by Sakura automation | No automatic add; app owner reads Share OLS and grants access |
| **When access is revoked** | User is removed from Entra group by Sakura | App owner reads Share OLS (revoked users drop out) and removes access |

- **Managed:** Best for most production apps; consistent, automated enforcement.
- **Unmanaged:** Used when an external team or tool already owns group membership; Sakura remains the source of truth for *who is approved*, and Share OLS is the handoff.

---

## 6. Who Can Create Permission Requests

- **Requester:** Any authenticated Dentsu user can create a permission request for **themselves** by going to **Requests → New Request** (Report Catalogue or Advanced) and completing the wizard.
- **On-behalf-of:** The same user can request access **for another person** by selecting “On behalf of another user” and entering the **RequestedFor** email. The system then:
  - Resolves the **Line Manager** from `ref.Employees` (e.g. Workday) for the **RequestedFor** user (not the submitter).
  - Sends approval notifications to that LM and the resolved OLS/RLS approvers.
- **Who cannot create requests:** There is no separate “creator” role; if you can log in and see the Report Catalogue / Advanced flow, you can submit. WSOs and Sakura Administrators can configure workspaces and approvers but do not get a different “create” permission — they create requests the same way as any user when they need access.

**Summary:** **Any authenticated user** can create a request for themselves or (if the UI supports it) on behalf of another user. The **RequestedFor** user is who gets the access; the **RequestedBy** user is who submitted the form. LM is always derived from **RequestedFor**.

---

## 7. Approval Process

Flow is **sequential**: Line Manager → OLS Approver → RLS Approver. Each step must approve before the next step is reached. Any rejection ends the request (status = Rejected).

### Step 1 — Line Manager (LM)

- **Who:** Resolved automatically from **ref.Employees** (e.g. Workday) using the **RequestedFor** user.
- **When:** As soon as the request is submitted (RequestStatus = Pending LM).
- **Actions:** Approve or Reject (with mandatory reason).
- **If approved:** Request moves to Pending OLS (or Pending RLS if OLS-only and no RLS, or if OLS was skipped).
- **If rejected:** Request and all headers set to Rejected; no further steps.

### Step 2 — OLS Approver

- **Who:** For **AUR:** from App (AppBased) or from Audience (AudienceBased). For **SAR:** from the report’s OLS approvers.
- **When:** After LM has approved (RequestStatus = Pending OLS).
- **Actions:** Approve or Reject (with mandatory reason). Can also **Revoke** an already-approved OLS (see below).
- **If approved:** If there is RLS, request moves to Pending RLS; if OLS-only, request becomes Approved.
- **If rejected:** Request and all headers (including RLS) set to Rejected.

### Step 3 — RLS Approver

- **Who:** Resolved from workspace RLS approver tables (e.g. `RLSGIApprovers`) by matching the request’s **security type** and **dimension values**; hierarchy traversal (Entity → Market → Cluster → Region → Global) is used if no exact match.
- **When:** After OLS has approved (RequestStatus = Pending RLS).
- **Actions:** Approve or Reject (with mandatory reason). Can also **Revoke** an already-approved RLS.
- **If approved:** Request becomes **Approved**; access is granted (and for Managed OLS, user is added to Entra group; RLS appears in Share RLS).
- **If rejected:** Request and headers set to Rejected (OLS is cascaded to Rejected as well).

### Delegation

- An approver can **delegate** their approval authority to another user for a date range. During that period, either the approver or the delegate can approve/reject; notifications can include both.

---

## 8. Rejection, Revocation, and Cancellation

### Rejection

- **Who:** LM, OLS Approver, or RLS Approver.
- **When:** While the request is in their pending step.
- **Effect:** RequestStatus → **Rejected (4)**; all permission headers set to **Rejected (3)**. Requester is notified with the reason. No access is granted; no further approvals.
- **Mandatory:** A reason must be provided; otherwise the action is blocked.

### Revocation

- **Who:** OLS Approver can revoke OLS permission they approved; RLS Approver can revoke RLS permission they approved. WSO can revoke permissions within their workspace; Sakura Admin can revoke any.
- **When:** After the request is **Approved** (or on an individual header that was approved).
- **Effect:** Permission header(s) set to **Revoked (4)**; if both OLS and RLS are revoked (or the only active permission is revoked), RequestStatus → **Revoked (5)**. In **Managed** OLS, user is removed from the Entra group (e.g. on next sync). In **Share RLS**, the row disappears from the view (ApprovalStatus ≠ 2), so Power BI stops showing that data to the user on next refresh.
- **Mandatory:** Revocation reason is required.

### Cancellation

- **Who:** **Requester** (the person who submitted, or possibly the RequestedFor user — per implementation).
- **When:** Only while the request is **pending** (Pending LM, Pending OLS, or Pending RLS). **Not** allowed when status is Approved, Rejected, or Revoked.
- **Effect:** RequestStatus → **Cancelled (6)**; all headers set to **Cancelled (5)**. No access was granted; request is closed.
- **Use case:** Requester no longer needs the access or submitted by mistake; they cancel from “My Requests” before any approver acts.

---

*Use this document together with the domain-specific demo documents (GI, CDI, WFI, DFI, EMEA, AMER) for a complete demo experience. Last updated: March 2026.*
