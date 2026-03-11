# Sakura V2 — GI (Growth Insights) Domain Demo

This document explains how Sakura works **in the GI (Growth Insights) domain**, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** Read [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md) for Apps, Audiences, Security Model, Share OLS/RLS, Managed vs Unmanaged OLS, and the general approval flow.

---

## Table of Contents

1. [GI Domain at a Glance](#1-gi-domain-at-a-glance)
2. [Key Terms and Concepts (GI)](#2-key-terms-and-concepts-gi)
3. [How Components Interact in GI](#3-how-components-interact-in-gi)
4. [Security Types and Dimensions in GI](#4-security-types-and-dimensions-in-gi)
5. [Share OLS and Share RLS for GI](#5-share-ols-and-share-rls-for-gi)
6. [Who Can Create Permission Requests (GI)](#6-who-can-create-permission-requests-gi)
7. [Approval Process (GI)](#7-approval-process-gi)
8. [Rejection, Revocation, Cancellation (GI)](#8-rejection-revocation-cancellation-gi)
9. [Practical Use Cases and Demo Scenarios](#9-practical-use-cases-and-demo-scenarios)

---

## 1. GI Domain at a Glance

| Item | GI (Growth Insights) |
|------|------------------------|
| **WorkspaceCode** | GI |
| **Purpose** | Growth and revenue reporting; entity, client, and service-line visibility |
| **Security Types** | **MSS** (Master Service Set), **SL/PA** (Service Line / People Aggregator) |
| **Key Dimensions** | Entity, Client, MSS, SL (Service Line) |
| **RLS Detail Table** | `dbo.RLSPermissionGIDetails` |
| **RLS Approver Table** | `dbo.RLSGIApprovers` |
| **Share Views** | `ShareGI.OLS`, `ShareGI.RLS` |

---

## 2. Key Terms and Concepts (GI)

### Entity and Organisation Level

- **Entity:** A legal business entity (e.g. Dentsu Germany GmbH). Stored in `ref.Entities`; identified by **EntityKey** (MapKey).
- **Organisation level:** User chooses Global, Region, Cluster, Market, or Entity. **Global** = access across all entities; **Cluster** = e.g. DACH; **Market** = e.g. UK; **Entity** = single legal entity. Hierarchy is used for **RLS approver resolution** (traverse Entity → Market → Cluster → Region → Global until an approver is found).

### Client

- **All Clients** = user can see data for all clients in the chosen org scope.
- **Specific Client (Dentsu Stakeholder)** = user is restricted to one or more specific clients (e.g. client 57). Used for client-specific reporting.

### MSS (Master Service Set)

- Grouping of services above individual service lines (e.g. CREATIVE, MEDIA). **L0** = Overall / all MSS; **L1–L4** = specific levels. Only used when security type is **MSS**.

### SL (Service Line)

- P&L service unit (e.g. CRTV, DIGITAL). **TOTALPA** = all service lines within the chosen scope.

### GI Security Types

- **MSS:** Wizard steps = Organisation → Entity (if not Global) → Client → MSS → Service Line.
- **SL/PA:** Wizard steps = Organisation → Entity (if not Global) → Client → Service Line (no MSS step).

---

## 3. How Components Interact in GI

- **GI Workspace** contains one or more **Apps** (e.g. GI_MAIN), each with **Audiences** — each audience is a **report group** (e.g. FINANCE_AUDIENCE groups finance reports, OPERATIONS_AUDIENCE groups operations reports) linked via ReportAppAudienceMap — and an **OLSMode** (Managed/Unmanaged).
- **Reports** in GI are either **AUR** (linked to one or more audiences via ReportAppAudienceMap, so they appear in those audiences’ report sets) or **SAR** (standalone, OLSItemType 0, with report-level OLS approvers). All reports are linked to **Security Models** (e.g. GI_STANDARD) via ReportSecurityModelMap.
- **Security Model** is linked to **Security Types** GI (MSS and SL/PA). When a user requests a GI report, they pick one security type and then complete the dimension steps; values are stored in **RLSPermissionGIDetails**.
- **RLS Approvers** are configured in **RLSGIApprovers** per dimension combination (and hierarchy). When a user selects e.g. Cluster = DACH, Client = All, MSS = CREATIVE, SL = TOTALPA, the system finds the matching approver (or traverses up the entity hierarchy) and routes the RLS approval to them.

---

## 4. Security Types and Dimensions in GI

| Security Type | Dimensions (order in wizard) | RLS Detail Columns |
|---------------|------------------------------|---------------------|
| **MSS** | Organisation level → Entity (if not Global) → Client → MSS → Service Line | EntityKey/EntityHierarchy, ClientKey/ClientHierarchy, MSSKey/MSSHierarchy, SLKey/SLHierarchy |
| **SL/PA** | Organisation level → Entity (if not Global) → Client → Service Line | EntityKey/EntityHierarchy, ClientKey/ClientHierarchy, SLKey/SLHierarchy (MSS not used) |

**Examples of stored values:**

- Entity: `DACH` (Cluster), `DE001` (Entity).
- Client: All Clients vs specific MapKey (e.g. client 57).
- MSS: `TOTALPA` (L0) or specific MSS name at L1–L4.
- SL: `TOTALPA` or specific SL code (e.g. `CRTV`).

---

## 5. Share OLS and Share RLS for GI

- **ShareGI.OLS:** Exposes **approved OLS** for the GI workspace. Only **Unmanaged** apps/audiences and SAR reports (with Unmanaged app in workspace) appear. Columns include OLSItemCode/OLSItemName, RequestedFor, OLSEntraGroupId, workspace/app/audience info. Used by app owners to manage Entra groups when OLS is Unmanaged.
- **ShareGI.RLS:** Exposes **approved RLS** for GI. Joins `RLSPermissionGIDetails`, `RLSPermissions`, `PermissionHeaders` (Approved, RLS), `PermissionRequests`. Exposes EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, MSSKey, MSSHierarchy, SLKey, SLHierarchy, SecurityType, RequestedFor, RequestedBy, ApprovedBy, ApprovalDate. **Power BI/EDP** uses this to enforce row-level security for GI reports.

---

## 6. Who Can Create Permission Requests (GI)

- **Any authenticated user** can create a permission request for a **GI** report or audience:
  - From **Report Catalogue:** search for a GI report → select report (and audience if AUR) → security model → security type (MSS or SL/PA) → dimensions → submit.
  - From **Advanced:** select workspace **GI** → choose App/Audience or SAR → then same security model and dimension flow.
- **On-behalf-of:** User can request **for another person** (RequestedFor). The **Line Manager** is resolved from **ref.Employees** for the **RequestedFor** user (e.g. Workday). That LM receives the first approval email for the GI request.
- **GI-specific:** Request must have a valid **RLS approver** for the chosen dimension combination; otherwise the wizard cannot submit (e.g. “No approver found”). WSO must configure **RLSGIApprovers** so that all required dimension combinations (or a parent in the entity hierarchy) have an approver.

---

## 7. Approval Process (GI)

### Line Manager (LM)

- Resolved from **RequestedFor** via ref.Employees.
- **Action:** Approve or Reject (reason mandatory). If approved, request moves to **Pending OLS** (or **Pending RLS** if OLS-only / RLS-only change).

### OLS Approver (GI)

- **AUR:** From App (AppBased) or from the selected Audience (AudienceBased). **SAR:** From the GI report’s OLS approver list.
- **Action:** Approve or Reject (reason mandatory). If approved and request has RLS, moves to **Pending RLS**; if OLS-only, request becomes **Approved**.

### RLS Approver (GI)

- Resolved from **RLSGIApprovers** using the request’s **security type** and **dimension values** (Entity, Client, MSS, SL). If no exact match, system traverses **Entity → Market → Cluster → Region → Global** to find a covering approver.
- **Action:** Approve or Reject (reason mandatory). If approved, request becomes **Approved**; GI RLS is written to `RLSPermissionGIDetails` and appears in **ShareGI.RLS** for Power BI.

### GI-Specific Notes

- **MSS vs SL/PA:** Both use the same RLS approver table; the approver is matched on the dimensions that were selected (MSS path includes MSSKey/MSSHierarchy; SL/PA does not).
- **Hierarchy:** An approver at **Cluster (DACH)** can approve requests for any Market or Entity under DACH if no more specific approver is configured.

---

## 8. Rejection, Revocation, Cancellation (GI)

### Rejection (GI)

- **LM rejects:** Request and all headers set to Rejected; requester notified with reason. No GI access granted.
- **OLS Approver rejects:** Same; OLS and RLS headers set to Rejected. Typical reason: “No business need for this audience/report.”
- **RLS Approver rejects:** Same; RLS header Rejected; OLS is cascaded to Rejected. Typical reason: “User should not see this entity/client/MSS/SL combination.”

### Revocation (GI)

- **OLS Approver** can revoke approved **OLS** for a GI report/audience they approved. **RLS Approver** can revoke approved **RLS** for the dimension scope they approved. **WSO** for GI workspace can revoke any GI permission; **Sakura Admin** can revoke any.
- **Effect:** Header set to Revoked. For **Managed** GI apps, user is removed from the Entra group on next sync. For **ShareGI.RLS**, the row drops out (ApprovalStatus ≠ 2), so Power BI no longer shows that data to the user on next refresh.
- **Reason** is mandatory.

### Cancellation (GI)

- **Requester** can cancel a GI request only while it is **Pending LM**, **Pending OLS**, or **Pending RLS**. Cannot cancel after Approved, Rejected, or Revoked. Cancellation sets RequestStatus to **Cancelled** and all headers to **Cancelled**.

---

## 9. Practical Use Cases and Demo Scenarios

### Use Case 1: Finance analyst needs GI Finance audience (AUR, full RLS)

- **Actor:** Finance analyst (e.g. Anna).
- **Flow:** Anna opens Report Catalogue → searches “Growth Insights Finance” → selects a report that is in **FINANCE_AUDIENCE** (AUR) and **GI_STANDARD** model → chooses security type **MSS** → Organisation **Cluster** → Entity **DACH** → Client **All Clients** → MSS **TOTALPA** (L0) → SL **TOTALPA** → submits. LM (Anna’s manager) approves → OLS Approver for FINANCE_AUDIENCE approves → RLS Approver for DACH/All Clients/MSS/SL approves. Request **Approved**. Anna is added to the **FINANCE_AUDIENCE** Entra group (if Managed) and appears in **ShareGI.RLS** with that dimension set. She can open the GI app and see **all reports** in the Finance audience, with data for DACH, all clients, all MSS/SL.

### Use Case 2: Client lead needs client-specific GI (MSS, specific client)

- **Actor:** Client lead for a Dentsu Stakeholder client.
- **Flow:** User requests same GI app/audience, security type **MSS** → Cluster **DACH** → Client **Specific Client** → client 57 → MSS **CREATIVE** (L1) → SL **TOTALPA**. LM approves → OLS Approver approves → RLS Approver for that entity/client/MSS/SL approves. User sees only data for client 57, CREATIVE, all SLs under that MSS, within DACH. **ShareGI.RLS** has one row for that user with ClientKey = 57, MSSKey = CREATIVE, etc.

### Use Case 3: Executive SAR (standalone report)

- **Actor:** Regional lead.
- **Flow:** Requests **standalone report** “Executive GI Summary” (SAR). No audience; OLS approver is on the report. Selects security type **SL/PA** → Organisation **Region** → Entity **EMEA** → Client **All Clients** → SL **TOTALPA**. LM approves → **Report’s** OLS Approver approves → RLS Approver for EMEA approves. Only that report is granted (via report’s Entra group if Managed); RLS still in **ShareGI.RLS** so the report only shows EMEA, all clients, TOTALPA.

### Use Case 4: On-behalf-of for new joiner

- **Actor:** Team lead (e.g. Bob) requesting for new joiner (e.g. Carol).
- **Flow:** Bob selects “On behalf of another user” and enters Carol’s email. Chooses GI report/audience and dimensions. **LM resolved for Carol** (not Bob) receives the approval email. After LM approves, OLS and RLS approvers for GI receive the task. When fully approved, **Carol** gets the access (RequestedFor = Carol); **ShareGI.RLS** shows RequestedFor = Carol.

### Use Case 5: RLS-only change (user already has OLS)

- **Actor:** User who already has GI audience access but needs different RLS (e.g. new client).
- **Flow:** User selects same report/audience; system detects existing OLS and asks “Do you want to change RLS only?” User confirms → wizard skips OLS and goes to Security Model → Security Type → Dimensions. LM approves → **RLS Approver** approves (OLS step skipped). New RLS row added; **ShareGI.RLS** now has an additional row (or updated row, per implementation) for that user with the new dimensions.

### Use Case 6: Rejection and resubmission

- **Actor:** Analyst requests Cluster = DACH, Client = Specific 57, MSS = CREATIVE, SL = CRTV. **RLS Approver** rejects with reason “Client 57 is not under your remit; request Client 99.” Requester sees rejection in My Requests and email. They create a **new** request with Client 99 and same other dimensions; RLS Approver approves. No “edit” of rejected request; new request is the correct path.

### Use Case 7: Revocation after role change

- **Actor:** User had GI access for DACH, CREATIVE, client 57. They move to another team. **RLS Approver** (or WSO) revokes with reason “Role change; no longer responsible for this client.” User is removed from Entra group (if Managed) and row removed from **ShareGI.RLS**; on next Power BI refresh they lose access to that data.

### Use Case 8: Requester cancels pending request

- **Actor:** User submitted a GI request by mistake (e.g. chose the wrong **audience** — the wrong report group). Request is still **Pending LM**. User goes to **My Requests** → selects the request → **Cancel**. Request status → **Cancelled**; no approval emails are sent for that request; no access is ever granted.

---

*Use this document for GI-specific demos and training. For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
