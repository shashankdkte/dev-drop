# SakuraV2 — Terminology & Definition Guide

> **Purpose:** This guide defines every important keyword, concept, and acronym used in the SakuraV2 system. It is written for developers, administrators, business analysts, and support staff who need a single authoritative reference.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [User Roles & Personas](#2-user-roles--personas)
3. [Access Security Concepts](#3-access-security-concepts)
4. [Workspaces & Domains](#4-workspaces--domains)
5. [Applications & Audiences](#5-applications--audiences)
6. [Reports & Delivery Methods](#6-reports--delivery-methods)
7. [Security Models & Security Types](#7-security-models--security-types)
8. [Dimensions & Hierarchies](#8-dimensions--hierarchies)
9. [Permission Requests & Approval Workflow](#9-permission-requests--approval-workflow)
10. [Database Architecture & Schemas](#10-database-architecture--schemas)
11. [Reference Data & ETL](#11-reference-data--etl)
12. [Email System](#12-email-system)
13. [List of Values (LoV)](#13-list-of-values-lov)
14. [Backend Architecture](#14-backend-architecture)
15. [Frontend Architecture](#15-frontend-architecture)
16. [Authentication & Identity](#16-authentication--identity)
17. [Downstream Enforcement & Integrations](#17-downstream-enforcement--integrations)
18. [Operational & Management Concepts](#18-operational--management-concepts)
19. [Acronym Reference](#19-acronym-reference)

---

## 1. System Overview

### Sakura

**Definition**
Sakura is Dentsu's centralised **access-request governance and management platform**. It manages who can access Power BI / Microsoft Fabric reports, orchestrates the multi-step approval workflow, and publishes approved access lists to downstream enforcement systems.

**Use Case**
Used by all Dentsu employees to request report access, by approvers (LMs, OLS approvers, RLS approvers) to grant or reject requests, and by workspace admins (WSOs) to configure reports and security rules.

**Example**
An analyst wants to see the GI (Growth Insights) client report. They submit a request in Sakura → their line manager approves → an OLS approver approves → an RLS approver assigns data rows. Access is enforced by Microsoft Fabric/EDP, not Sakura itself.

**Business Insight**
Sakura separates the concern of *who should have access* (governed here) from *who does have access* (enforced downstream). This gives Dentsu a single auditable source of truth for access decisions.

---

### SakuraV1 vs SakuraV2

**Definition**
SakuraV1 was the original system. SakuraV2 is the full redesign with a .NET 8 backend, Angular frontend, a new multi-schema SQL Server database, and expanded support for all Dentsu domains (GI, CDI, WFI, DFI, EMEA, AMER).

**Business Insight**
V2 introduced workspace isolation, audience-based delivery, configurable security models, temporal auditing, and a scalable multi-domain architecture absent from V1.

---

## 2. User Roles & Personas

### Requester

**Definition**
Any Dentsu user who submits an access request for one or more reports. The requester may be submitting for themselves or on behalf of another user (on-behalf-of scenario).

**Use Case**
A new analyst joins a team and requests access to their workspace's GI reports via the request wizard.

**Example**
User A logs in, browses the Report Catalogue, clicks "Request Access" on a GI report, fills the wizard, and submits. User A is the Requester.

**Business Insight**
Requesters have no elevated permissions. The system identifies them via Azure AD and resolves their line manager automatically from employee reference data.

---

### WSO / WSA (Workspace Security Object / Workspace Admin)

**Definition**
The designated administrator of a specific workspace. The WSO configures all workspace-level settings: apps, audiences, reports, security models, RLS approvers, and OLS approver assignments.

**Use Case**
A business owner of the CDI workspace is granted the WSO role. They set up the CDI app, define audiences, link reports to security models, and assign RLS approvers per entity.

**Example**
The CDI WSO creates an audience called `FINANCE_TEAM`, links it to the relevant Power BI app group, and assigns an OLS approver for that audience.

**Business Insight**
The WSO model decentralises administration — each domain team manages their own workspace without needing global system access, while Sakura Administrators retain oversight.

---

### Sakura Administrator

**Definition**
A global system administrator who can create workspaces, manage system-wide settings, and access all workspaces regardless of ownership.

**Use Case**
Used during initial workspace setup or to resolve escalated issues across any workspace.

**Business Insight**
Only a small number of trusted users should hold this role, as it bypasses workspace-level access restrictions.

---

### LM (Line Manager)

**Definition**
The direct manager of the person requesting access. The LM is the **first approver** in every permission request chain. Their identity is resolved automatically from the `ref.Employees` table (sourced from UMS/Workday).

**Use Case**
When a request is submitted, Sakura queries the employee hierarchy to find the requester's LM and routes the approval email to them.

**Example**
User A's manager is User B per the Workday org chart. When User A requests access, User B receives an approval notification automatically.

**Business Insight**
Involving the LM ensures that access decisions have managerial accountability at the first step, reducing the risk of inappropriate access being approved without business context.

---

### OLS Approver

**Definition**
A designated approver who decides whether a user should be granted access to a specific report or audience (object-level). The OLS Approver acts after the LM has approved.

**Use Case**
Configured at the `WorkspaceApps` level (AppBased mode) or at the `AppAudiences` level (AudienceBased mode). For SAR reports, configured directly on the report.

**Example**
The GI App has approvers `jane@dentsu.com, mike@dentsu.com`. After the LM approves, Jane receives the OLS approval email.

**Business Insight**
OLS Approvers are domain experts who validate that the business justification for report access is sound before granting visibility into sensitive analytics.

---

### RLS Approver

**Definition**
A designated approver who decides which **data rows** (dimensions) a user may see within a report. Acts after OLS approval is complete. Stored in workspace-specific approver tables (`dbo.RLSGIApprovers`, `dbo.RLSCDIApprovers`, etc.).

**Use Case**
Matched against the request's security type and dimension values. If no exact match exists, the system traverses up the entity hierarchy (Market → Cluster → Region → Global) to find a covering approver.

**Example**
A user requests GI access for Entity `DE001` (Germany). The RLS approver configured for the `EMEA` market receives the approval task.

**Business Insight**
RLS approval ensures data segregation is enforced at a granular level, preventing users from seeing client or financial data outside their authorised scope.

---

### GlobalWorkspaceAccessUsers

**Definition**
A special override table (`dbo.GlobalWorkspaceAccessUsers`) listing users (support staff, Sakura Admins) who can access every workspace regardless of WSO assignments.

**Use Case**
Support engineers troubleshooting cross-workspace issues, or administrators performing system-wide audits.

**Business Insight**
This override mechanism should be kept to a minimum and audited regularly, as it bypasses standard workspace isolation controls.

---

## 3. Access Security Concepts

### OLS (Object-Level Security)

**Definition**
OLS controls **which reports or audiences** a user is allowed to open. It answers the question: "Can this user see this report at all?" OLS is enforced via Entra (Azure AD) group membership managed by Sakura or the app owner.

**Use Case**
When a user's access request is fully approved, Sakura adds them to the relevant Entra group for the report/audience. The Power BI/Fabric app checks group membership at login.

**Example**
The `GI_FINANCE_AUDIENCE` Entra group controls who can open the Finance audience in the GI app. Only users in this group can see the report.

**Business Insight**
OLS is the gateway — without passing OLS, a user cannot interact with the report at all, regardless of their RLS settings.

---

### RLS (Row-Level Security)

**Definition**
RLS controls **which data rows** a user can see inside a report. It answers: "Given that this user can open the report, which clients, entities, or cost centres can they see?" RLS rules are published to the downstream enforcement system via Share views.

**Use Case**
After OLS approval, RLS approval defines the data scope. A user approved for the CDI workspace may only see data for their specific client portfolio.

**Example**
User A is approved for CDI with Entity `UK001` and Client `CLIENT_ALPHA`. The RLS view in `ShareCDI.RLS` includes a row for User A with those dimension values. EDP enforces it in Power BI.

**Business Insight**
RLS is critical for data privacy and commercial confidentiality — it ensures that users see only the subset of data they are authorised to access, even if they share the same report.

---

### OLSMode

**Definition**
A flag on `WorkspaceApps` that controls who manages Entra group membership for OLS.

| Value | Label | Meaning |
|-------|-------|---------|
| `0` | Managed | Sakura automatically adds/removes users from the Entra group |
| `1` | Unmanaged | The Power BI or app owner manages group membership manually |

**Use Case**
Set to `Managed` for most production workspaces. `Unmanaged` is used when an external team or tool already controls group membership.

**Business Insight**
Managed mode reduces human error and ensures immediate enforcement when access is approved or revoked.

---

### ApprovalMode

**Definition**
A flag on `WorkspaceApps` that determines whether OLS approvers are defined at the application level or per individual audience.

| Value | Label | Meaning |
|-------|-------|---------|
| `0` | AppBased | One set of OLS approvers for the entire app |
| `1` | AudienceBased | Each audience has its own OLS approvers |

**Use Case**
Use `AudienceBased` when different business units own different audiences within the same app and need separate approval authority.

**Example**
The GI app has an `Analytics` audience owned by the Analytics team and a `Finance` audience owned by Finance. AudienceBased mode lets each team approve their own audience.

**Business Insight**
AudienceBased mode enables fine-grained organisational control and accountability, preventing cross-team approval conflicts.

---

## 4. Workspaces & Domains

### Workspace

**Definition**
A logical container in Sakura representing a specific business domain or reporting area. Each workspace encapsulates its own apps, reports, security models, RLS approvers, and access records.

**Use Case**
Each Dentsu domain (GI, CDI, WFI, DFI, EMEA, AMER) has its own workspace. A workspace maps to a set of related Power BI apps and reports for that domain.

**Example**
The `GI` workspace contains all Growth Insights apps, reports, and security configuration. The `CDI` workspace separately contains all Client Data Insights configuration.

**Business Insight**
Workspace isolation ensures that administrators, approvers, and access data for one domain are completely separated from another, enabling decentralised governance.

---

### WorkspaceCode

**Definition**
A short unique identifier for a workspace (e.g. `GI`, `CDI`, `WFI`, `DFI`, `EMEA`, `AMER`). Used as a foreign key reference, in URL parameters, and in email notifications.

**Business Insight**
WorkspaceCodes make it possible to uniquely identify workspaces in a compact form across all system components.

---

### Domain

**Definition**
The business domain category that a workspace belongs to. Stored as a `LoV` entry of type `Domain`. Each domain has specific security types and dimension structures associated with it.

| Domain Code | Full Name | Notes |
|-------------|-----------|-------|
| `GI` | Growth Insights | Entity + Client + MSS + SL dimensions |
| `CDI` | Client Data Insights | Entity + Client + SL dimensions |
| `WFI` | Workforce Insights | Entity + PA (People Aggregator) dimensions |
| `DFI` | Dentsu Finance Insights | FUM security type (Entity + Country + Client + MSS + ProfitCenter) |
| `EMEA` | Europe, Middle East & Africa | 5 security types (ORGA, CLIENT, CC, COUNTRY, MSS) |
| `AMER` | Americas | 6 security types (ORGA, CLIENT, CC, PC, PA, MSS) |

**Business Insight**
Domain grouping ensures that each region or business unit's data dimensions and approval processes match their specific organisational structure.

---

### WorkspaceTag

**Definition**
An optional short tag for a workspace used in email templates and URL parameters when it differs from the `WorkspaceCode`. Allows display customisation without changing the system identifier.

---

### WorkspaceOwner / WorkspaceTechOwner

**Definition**
- **WorkspaceOwner**: The business owner email(s) responsible for the workspace (governance accountability).
- **WorkspaceTechOwner**: The technical owner email(s) responsible for system configuration and integration.

**Business Insight**
Separating business and technical ownership ensures both accountability and operational expertise are clearly defined per workspace.

---

## 5. Applications & Audiences

### WorkspaceApp (App)

**Definition**
A Power BI application registered within a workspace in Sakura. An app represents a deployable Power BI App that groups multiple reports. It is identified by an `AppCode`, linked to an Entra group, and configured with OLS settings.

**Use Case**
The GI workspace may contain multiple apps (e.g. `GI_CORE`, `GI_EXECUTIVE`). Each app has its own audiences, approvers, and Entra group.

**Example**
`AppCode = GI_MAIN`, `AppEntraGroupUID = <azure-ad-guid>`, `OLSMode = Managed`, `ApprovalMode = AudienceBased`.

**Business Insight**
Apps are the unit of OLS enforcement — being a member of an app's Entra group grants the user entry to the Power BI application.

---

### AppAudience (Audience)

**Definition**
A named audience within a Power BI app, representing a specific group of users who share a view of the same app (e.g. an audience for Finance vs. an audience for Marketing). Each audience has its own Entra group and optional OLS approvers.

**Use Case**
Used when the same Power BI App is accessed by different business groups who should see different subsets of reports or have different approval chains.

**Example**
The GI app has audience `FINANCE_AUDIENCE` (for finance users) and `OPERATIONS_AUDIENCE` (for ops users). Each has its own Entra group GUID and approver.

**Business Insight**
Audiences allow a single app to serve multiple business segments securely without deploying separate apps per segment.

---

### AudienceCode

**Definition**
A unique identifier for an audience, auto-generated from the audience name (uppercased, spaces converted to underscores). Used as a system reference in mappings and views.

---

### AudienceEntraGroupUID

**Definition**
The Azure Active Directory (Entra) Group GUID associated with an audience. Users approved for that audience are added to this group, granting them Power BI access.

**Business Insight**
The Entra Group UID is the bridge between Sakura's access decisions and Microsoft Fabric/Power BI enforcement. Without it, Managed OLS cannot function.

---

### AdditionalQuestionsJSON

**Definition**
A JSON field on `WorkspaceApps` that defines dynamic form questions presented to the requester during the access request wizard. Answers are stored in `OLSPermissions.AdditionalDetailsJSON`.

**Use Case**
A workspace may require requesters to explain their business need or select their role before their request is routed. These questions are workspace-specific and configurable by the WSO.

**Example**
`[{"questionId": "Q1", "label": "What is your role?", "type": "dropdown", "options": ["Analyst", "Manager"]}]`

**Business Insight**
Dynamic questions capture business context at request time, giving approvers richer information to make informed access decisions.

---

## 6. Reports & Delivery Methods

### WorkspaceReport (Report)

**Definition**
A Power BI report registered in Sakura under a specific workspace. A report is associated with a delivery method (AUR or SAR), linked to security models for RLS, and may be linked to one or more audiences.

**Use Case**
WSOs register each report in Sakura to make it requestable. The report configuration determines the approval workflow and data security model that applies.

---

### ReportDeliveryMethod

**Definition**
Defines how a user receives access to a report. Two methods exist:

| Code | Value | Meaning |
|------|-------|---------|
| `AUR` | Audience Report (0) | Access via audience membership. Report is linked to an `AppAudience`. |
| `SAR` | Standalone Access Report (1) | Access granted individually per user. Report has its own OLS approvers. |

**Use Case**
- Use **AUR** when a report is consumed by a defined business group (audience) and all members should see the same view.
- Use **SAR** when individual users need unique access, such as executive reports.

**Example**
The "Monthly Finance Summary" report is AUR-linked to the `FINANCE_AUDIENCE`. Any user approved for that audience can access it. The "CEO Dashboard" is a SAR with direct approvers.

**Business Insight**
AUR simplifies management for large teams by grouping access. SAR provides fine-grained individual control for sensitive or strategic reports.

---

### ReportTag

**Definition**
An optional short code used in URL parameters and navigation to uniquely identify a report in links and deep-linking within the frontend.

---

### ReportKeywords

**Definition**
A comma-separated list of search keywords associated with a report. Used by the Report Catalogue search feature to improve discoverability.

**Business Insight**
Good keyword tagging reduces support requests by helping users self-service find the correct report via search.

---

### ReportAppAudienceMap

**Definition**
A mapping table linking an AUR-type `WorkspaceReport` to one or more `AppAudiences`. This map is required for audience-based report access to function.

**Use Case**
When a user requests an AUR report, the system uses this map to know which audience's approval chain to trigger.

---

### ReportSecurityModelMap

**Definition**
A mapping table linking a `WorkspaceReport` to one or more `WorkspaceSecurityModels`. Determines which RLS security models apply when a user requests the report.

**Use Case**
A single report may use multiple security models (e.g. both GI and CDI models). This map enables flexible RLS assignment per report.

---

## 7. Security Models & Security Types

### SecurityModel (WorkspaceSecurityModel)

**Definition**
A named, reusable grouping of one or more security types, defined within a workspace. Reports are linked to security models, and RLS permission details are captured per security model.

**Use Case**
A GI workspace may have a `GI_STANDARD` security model combining EntityKey + ClientKey + SLKey security types. This model is then linked to multiple GI reports.

**Example**
`SecurityModelCode = GI_STANDARD`, `SecurityModelName = "GI Standard Access"`, associated security types: `GI`.

**Business Insight**
Security models abstract the complexity of multi-dimensional RLS configuration, making it reusable and maintainable across many reports.

---

### SecurityModelSecurityTypeMap

**Definition**
A junction table that links a `WorkspaceSecurityModel` to one or more `LoV` entries of type `SecurityType`. Defines which dimension categories belong to a model.

---

### SecurityType

**Definition**
A dimension category registered as a `LoV` entry of type `SecurityType`. Each security type corresponds to a workspace domain and determines which RLS detail table is used for permission storage.

| Security Type | Domain | Key Dimensions |
|---------------|--------|---------------|
| `GI` | GI | Entity, Client, MSS, SL |
| `CDI` | CDI | Entity, Client, SL |
| `WFI` | WFI | Entity, PA |
| `FUM` | DFI | Entity, Country, Client, MSS, ProfitCenter |
| `EMEA-ORGA` | EMEA | Entity, SL, MSS |
| `EMEA-CLIENT` | EMEA | Entity, Client |
| `EMEA-CC` | EMEA | Entity, CC |
| `EMEA-COUNTRY` | EMEA | Entity, Country |
| `EMEA-MSS` | EMEA | Entity, MSS |
| `AMER-ORGA` | AMER | Entity, SL, MSS |
| `AMER-CLIENT` | AMER | Entity, Client |
| `AMER-CC` | AMER | Entity, CC |
| `AMER-PC` | AMER | Entity, PC |
| `AMER-PA` | AMER | Entity, PA |
| `AMER-MSS` | AMER | Entity, MSS |

**Business Insight**
Security types allow different domains to use different data dimensions for RLS without sharing a single monolithic permission structure.

---

## 8. Dimensions & Hierarchies

### Dimension

**Definition**
A specific data attribute used to filter rows in a report (e.g. a particular Entity, Client, Service Line, or Cost Centre). Dimensions are the values within a security type. They are sourced from the `ref` schema tables.

**Use Case**
When a user requests RLS access, they (or the approver) specify which dimension values they are allowed to see. These values are stored in workspace-specific RLS detail tables.

**Example**
Entity dimension value: `DE001` (a German legal entity). Client dimension value: `CLIENT_ALPHA`. Service Line dimension value: `DIGITAL`.

---

### Hierarchy

**Definition**
The level in the organisational tree at which a dimension key applies. Every dimension key column in RLS tables is paired with a hierarchy column.

| Hierarchy Value | Meaning |
|----------------|---------|
| `Market` | Key applies to a specific market-level entity |
| `Cluster` | Key applies to all entities in a cluster |
| `Region` | Key applies to all entities in a region |
| `Global` | Key applies to all entities globally |
| `All` | The permission/approver covers all values at any level |

**Use Case**
An approver configured at `Cluster` hierarchy for entity `EU_CLUSTER` will receive approval tasks for any entity belonging to that cluster.

**Business Insight**
Hierarchy-aware permissions enable a single approver or permission entry to cover a range of entities, reducing configuration overhead while maintaining accurate access control.

---

### MapKey

**Definition**
The unique business key for any record in the `ref` schema tables (e.g. `ref.Entities`, `ref.Clients`, `ref.ServiceLines`). Used as the value in dimension key columns (`EntityKey`, `ClientKey`, etc.) in RLS tables.

**Use Case**
MapKeys are assigned by the upstream source systems (UMS/BPC) and are stable identifiers used for joining across reference tables.

**Business Insight**
Using MapKeys rather than display names or codes ensures that RLS permissions remain valid even when business names change.

---

### Entity

**Definition**
A legal business entity within the Dentsu organisation. Stored in `ref.Entities`. Entities sit below Markets in the hierarchy. They are the primary organisational unit used in most security types.

**Example**
`EntityCode = DE001`, `EntityName = "Dentsu Germany GmbH"`, belongs to `MarketCode = DACH`.

---

### Market

**Definition**
A geographic/commercial market grouping of entities. Stored in `ref.Markets`. Markets belong to Clusters. The entity hierarchy traversal for RLS approver resolution uses Markets as the first step above Entity level.

---

### Cluster

**Definition**
A grouping of Markets within a region. Stored in `ref.Clusters`. Used in the entity hierarchy for approver traversal (Entity → Market → Cluster → Region → Global).

---

### Region

**Definition**
The top-level geographic grouping above Clusters. Stored in `ref.Regions`.

---

### ServiceLine (SL)

**Definition**
A Profit & Loss business unit representing a specific service offering (e.g. Media, Creative, CXM). Stored in `ref.ServiceLines`. Used as an RLS dimension in GI, CDI, EMEA, and AMER security types.

---

### Client

**Definition**
A client account that Dentsu services. Stored in `ref.Clients`. Used as an RLS dimension in GI, CDI, EMEA, AMER, and FUM security types.

---

### CostCentre (CC)

**Definition**
An internal financial cost centre. Stored in `ref.CostCenters`. Used as an RLS dimension in EMEA and AMER security types.

---

### MSS (Master Service Set)

**Definition**
A grouping of services at a higher level than individual service lines. Stored in `ref.MasterServiceSets`. Used as an RLS dimension in GI, EMEA, AMER, and FUM security types.

**Business Insight**
MSS provides a cross-entity service grouping that aligns with how Dentsu organises its service delivery commercially.

---

### PA (People Aggregator / Practice Area)

**Definition**
Dual meaning depending on domain:
- **WFI domain**: People Aggregator — a workforce dimension grouping employees by organisational function.
- **AMER domain**: Practice Area — a commercial practice grouping for Americas-specific reporting.

Stored in `ref.PeopleAggregators`. Column names: `PAKey`, `PAHierarchy`.

---

### ProfitCenter (PC)

**Definition**
A profit centre dimension used in AMER and FUM (DFI) security types. Stored in `ref.ProfitCenters`. Column names: `PCKey`/`PCHierarchy` (AMER) and `ProfitCenterKey`/`ProfitCenterHierarchy` (FUM).

---

### Country

**Definition**
A geographic country dimension. Stored in `ref.Countries`. Used in EMEA and FUM (DFI) security types. Column names: `CountryKey`, `CountryHierarchy`.

---

## 9. Permission Requests & Approval Workflow

### PermissionRequest

**Definition**
The core transactional record created when a user submits an access request via the wizard. One row in `dbo.PermissionRequests` represents one complete submission for one user, one workspace.

**Key Fields:**
- `RequestCode` — Human-readable unique identifier (auto-generated via sequence)
- `RequestedFor` — The user who will receive access
- `RequestedBy` — The user who submitted (may differ in on-behalf-of scenarios)
- `LMApprover` — The resolved line manager email
- `RequestStatus` — Current state of the overall request (0–6)
- `RequestReason` — Free-text business justification

---

### RequestCode

**Definition**
A human-readable unique identifier for a permission request, auto-generated by the `dbo.PermissionRequestCodeSeq` sequence and the `GeneratePermissionRequestCode` stored procedure. Used in email notifications, audit logs, and the UI.

**Example**
`SKR-00042`, `SKR-00043` — sequential identifiers that allow users and support teams to reference specific requests easily.

---

### RequestStatus

**Definition**
The current overall state of a `PermissionRequest`. Reflects the stage of the approval chain.

| Value | Label | Meaning |
|-------|-------|---------|
| `0` | PendingLM | Submitted; awaiting Line Manager approval |
| `1` | PendingOLS | LM approved; awaiting OLS approver |
| `2` | PendingRLS | OLS approved; awaiting RLS approver |
| `3` | Approved | All approvals complete; access granted |
| `4` | Rejected | Rejected at any stage |
| `5` | Revoked | Previously approved access revoked |
| `6` | Cancelled | Request cancelled by requester or admin |

**Business Insight**
The multi-step status chain (LM → OLS → RLS) ensures that access decisions have appropriate business, domain, and data-level review at every stage.

---

### On-Behalf-Of

**Definition**
A scenario where `RequestedBy` ≠ `RequestedFor`. A manager or admin submits a request on behalf of another user. The system stores both parties and resolves the LM based on the `RequestedFor` user.

**Use Case**
A team lead onboards a new joiner and submits their access request before the new employee has system access.

---

### PermissionHeader

**Definition**
A pair of records in `dbo.PermissionHeaders` — one for OLS, one for RLS — created for every permission request. Each header tracks the approval state, approver, decision, and decision notes for its permission type.

| PermissionType | Value |
|---------------|-------|
| OLS | 0 |
| RLS | 1 |

---

### ApprovalStatus

**Definition**
The state of an individual `PermissionHeader` (OLS or RLS).

| Value | Label | Meaning |
|-------|-------|---------|
| `0` | NotStarted | Not yet reached in the workflow |
| `1` | Pending | Approval email sent; awaiting decision |
| `2` | Approved | Approver granted access |
| `3` | Rejected | Approver denied access |
| `4` | Revoked | Previously approved, now revoked |
| `5` | Cancelled | Cancelled before decision |

---

### OLSPermission

**Definition**
A record in `dbo.OLSPermissions` storing the OLS-specific details of a request: which report or audience the user wants access to, the OLS item type, and any additional form answers.

| OLSItemType | Value | Description |
|-------------|-------|-------------|
| WorkspaceReport (SAR) | 0 | Access to a standalone report |
| AppAudience (AUR) | 1 | Access to an audience within an app |

---

### RLSPermission

**Definition**
A record in `dbo.RLSPermissions` linking a permission request to a specific security model and security type. The actual dimension values are stored in the workspace-specific RLS detail table (e.g. `dbo.RLSPermissionGIDetails`).

---

### RLS Detail Tables

**Definition**
Workspace-specific tables that store the approved RLS dimension values for each permission. Each table corresponds to a workspace domain.

| Table | Domain | Dimensions |
|-------|--------|-----------|
| `dbo.RLSPermissionGIDetails` | GI | Entity, Client, MSS, SL |
| `dbo.RLSPermissionCDIDetails` | CDI | Entity, Client, SL |
| `dbo.RLSPermissionWFIDetails` | WFI | Entity, PA |
| `dbo.RLSPermissionEMEADetails` | EMEA | Entity, SL, Client, CC, Country, MSS |
| `dbo.RLSPermissionAMERDetails` | AMER | Entity, SL, Client, PC, CC, PA, MSS |
| `dbo.RLSPermissionFUMDetails` | DFI | Entity, Country, Client, MSS, ProfitCenter |

**Business Insight**
Separating RLS detail tables by domain keeps queries fast, schemas clean, and makes it straightforward to add new dimension types per domain without affecting others.

---

### RLS Approver Tables

**Definition**
Workspace-specific configuration tables that define which approvers are responsible for specific dimension combinations. The system matches a request's dimension values against these tables to route RLS approvals.

| Table | Domain |
|-------|--------|
| `dbo.RLSGIApprovers` | GI |
| `dbo.RLSCDIApprovers` | CDI |
| `dbo.RLSWFIApprovers` | WFI |
| `dbo.RLSEMEAApprovers` | EMEA |
| `dbo.RLSAMERApprovers` | AMER |
| `dbo.RLSFUMApprovers` | DFI |

**Use Case**
A WSO registers that `approver@dentsu.com` is responsible for Entity `DE001`, Client `CLIENT_ALPHA` in the GI workspace. When a user requests those dimensions, this approver is notified.

---

### Approver Hierarchy Traversal

**Definition**
When no exact dimension match is found in the RLS approver table, Sakura traverses up the entity hierarchy (Entity → Market → Cluster → Region → Global) to find a covering approver.

**Business Insight**
This fallback mechanism ensures that every request can always be routed to an approver, even if a specific entity-level approver is not yet configured.

---

## 10. Database Architecture & Schemas

### Schema Overview

**Definition**
The Sakura database uses multiple SQL Server schemas to separate concerns:

| Schema | Purpose |
|--------|---------|
| `dbo` | Core application tables (workspaces, apps, reports, permissions, email, LoV) |
| `ref` | Reference/dimension data from UMS/BPC (read-only source of truth) |
| `stage` | Staging tables used by ADF pipelines during ETL ingestion |
| `history` | SQL Server temporal table history (automatic audit trail for all core tables) |
| `mgmt` | Management tables (pipeline settings, event logs, deployment history) |
| `auto` | Automated OLS group membership records |
| `romv` | Read-only managed views exposed to the application layer |
| `refv` | Read-only reference views |
| `Share{Workspace}` | Per-workspace OLS and RLS views consumed by the downstream EDP system |
| `ShareEDP` | Enterprise Data Platform views |

---

### Temporal Tables

**Definition**
All core `dbo` tables and `ref` tables are SQL Server **temporal tables**, which automatically maintain a full change history. Every row has `ValidFrom` and `ValidTo` system-time columns. History is stored in the `history` schema.

**Use Case**
Auditors can query any table `AS OF` a specific date to see the exact state of a permission, workspace configuration, or reference data at any point in time.

**Business Insight**
Temporal tables provide an immutable, zero-effort audit trail for all governance decisions, a mandatory requirement for regulated access management systems.

---

### Standard Audit Columns

**Definition**
Every core table includes the following columns for traceability:

| Column | Purpose |
|--------|---------|
| `CreatedAt` | Timestamp when the record was created |
| `CreatedBy` | Identity of the user/system that created it |
| `UpdatedAt` | Timestamp of the last update |
| `UpdatedBy` | Identity of the user/system that last updated it |
| `ValidFrom` | System-time start (temporal) |
| `ValidTo` | System-time end (temporal) |

---

### Share Views

**Definition**
Read-only database views, one per workspace, prefixed `Share{Workspace}`. These views present approved OLS and RLS permissions in the format consumed by the downstream enforcement system (EDP/Fabric).

| View Pattern | Example | Content |
|-------------|---------|---------|
| `Share{W}.OLS` | `ShareGI.OLS` | Approved OLS permissions for GI |
| `Share{W}.RLS` | `ShareCDI.RLS` | Approved RLS permissions with dimension values for CDI |

**Use Case**
The downstream EDP system queries these views on a schedule to sync access entitlements into Power BI/Fabric row-level security rules.

**Business Insight**
Share views are the contract between Sakura (governance) and EDP (enforcement). They expose only what is needed — no internal Sakura state, just clean entitlement data.

---

### ROMV (Read-Only Managed Views)

**Definition**
A schema (`romv`) containing read-only views that the backend application layer queries instead of directly joining base tables. These views flatten complex joins and improve query maintainability.

**Example**
`romv.PermissionRequests` — a view combining `dbo.PermissionRequests`, headers, and OLS/RLS details for API consumption.

---

## 11. Reference Data & ETL

### ref Schema

**Definition**
A set of read-only dimension tables populated by Azure Data Factory (ADF) pipelines from upstream systems (UMS, Workday, BPC). These tables are the authoritative source for all organisational dimension data in Sakura.

**Key Tables:**
- `ref.Employees` — Employee records including line manager relationships
- `ref.Entities` — Legal entities with their market, cluster, region hierarchy
- `ref.Markets`, `ref.Clusters`, `ref.Regions` — Geographic hierarchy
- `ref.Clients` — Client accounts
- `ref.ServiceLines` — Service line definitions
- `ref.CostCenters` — Cost centres
- `ref.Countries` — Geographic countries
- `ref.MasterServiceSets` — MSS groupings
- `ref.PeopleAggregators` — PA dimension
- `ref.ProfitCenters` — Profit centres

---

### PipelineStatus / PipelineInfo / PipelineRunId

**Definition**
Columns present on all `ref` schema tables, used to track the ADF pipeline run that last loaded or updated each record.

| Column | Purpose |
|--------|---------|
| `PipelineStatus` | Status of the last pipeline run for this record |
| `PipelineInfo` | Descriptive info about the pipeline run |
| `PipelineRunId` | Azure Data Factory run identifier |

**Business Insight**
These columns allow support teams to trace data quality issues back to specific ADF pipeline executions.

---

### ADF (Azure Data Factory)

**Definition**
The ETL (Extract, Transform, Load) orchestration service that syncs reference data from upstream systems (UMS, Workday, BPC) into the Sakura `ref` schema tables via staging (`stage` schema).

**Use Case**
ADF runs on a schedule to keep employee data, entity hierarchies, and client lists current in Sakura, ensuring LM resolution and dimension dropdowns reflect the latest organisational state.

---

### UMS (User Management System)

**Definition**
Dentsu's internal user management system, the source of employee records, line manager relationships, and organisational hierarchy data. ADF pulls from UMS to populate `ref.Employees`.

---

### BPC (Business Planning & Consolidation)

**Definition**
A financial planning system that is the source of entity, brand, segment, and client data. ADF pulls from BPC to populate `ref.Entities`, `ref.BPCBrands`, `ref.BPCSegments`, etc.

---

### mgmt.DataTransferSettings

**Definition**
A configuration table in the `mgmt` schema that defines ADF pipeline settings for each reference data entity — including source connection, target table, schedule, and transformation rules. 16 active settings exist.

**Business Insight**
Centralising pipeline configuration in the database rather than hardcoding it in ADF makes the ETL process manageable and auditable without needing ADF access.

---

### DeletedAt

**Definition**
A soft-delete column on `ref` schema tables. When a record is deactivated in the upstream source but referenced in Sakura, it is marked with a `DeletedAt` timestamp rather than being physically deleted, preserving referential integrity.

---

## 12. Email System

### Email Queue (`dbo.Emails`)

**Definition**
A database table that acts as an outbound email queue. The backend inserts email records here; a background process sends them and updates their status.

**Key Columns:**

| Column | Purpose |
|--------|---------|
| `From`, `To`, `CC`, `BCC` | Email addresses |
| `Subject`, `Body` | Rendered email content |
| `Status` | Send status (Queued, Sent, Failed) |
| `NumberOfTries` | Retry count |
| `EmailTemplateKey` | FK to the template used |
| `ContextEntityName` | The entity type this email relates to (e.g. `PermissionRequest`) |
| `ContextId` | The ID of the related entity |
| `EmailGuid` | Unique identifier for idempotency |
| `QueueName` | Queue partition for prioritisation |

---

### EmailTemplate (`dbo.EmailTemplates`)

**Definition**
Configurable HTML email templates stored in the database. Each template has a unique `EmailTemplateKey`, a subject, and a body with placeholder tokens that are replaced at send time.

**Use Case**
When an LM approval is needed, the backend retrieves the `LM_APPROVAL_REQUEST` template, substitutes `{{RequestCode}}`, `{{RequesterName}}`, etc., and queues the rendered email.

**Business Insight**
Database-driven templates allow business teams to update email content without code deployments, improving agility.

---

## 13. List of Values (LoV)

### LoV (List of Values)

**Definition**
The central lookup/enumeration table (`dbo.LoVs`) that stores all system-wide reference values: domain types, security types, application settings, and other enumerations. The frontend fetches these via `/api/Common/lov`.

**Key Columns:**

| Column | Purpose |
|--------|---------|
| `LoVType` | Category of the entry (e.g. `Domain`, `SecurityType`, `ApplicationSetting`) |
| `LoVValue` | Unique code within its type (e.g. `GI`, `CDI`, `WFI`) |
| `LoVName` | Human-readable display name |
| `LoVDescription` | Optional description |
| `ParentLoVType` / `ParentLoVValue` | Optional parent entry for hierarchical LoVs |

**Business Insight**
Centralising all enumerations in a single table means changes to display names, new domain additions, or setting modifications can be made via data changes rather than code releases.

---

### LoVType

**Definition**
The category classifier for a LoV entry. Common LoVTypes in Sakura:

| LoVType | Examples |
|---------|---------|
| `Domain` | GI, CDI, WFI, DFI, EMEA, AMER |
| `SecurityType` | GI, CDI, WFI, FUM, EMEA-ORGA, AMER-CLIENT, etc. |
| `ApplicationSetting` | Various system configuration keys |

---

### ApplicationSettings (`dbo.ApplicationSettings`)

**Definition**
A table of key-value pairs for system-wide configuration that can be adjusted without code deployment.

| Column | Purpose |
|--------|---------|
| `SettingKey` | Unique identifier for the setting |
| `SettingValue` | The configured value |
| `SettingDataType` | Data type of the value (string, int, bool, etc.) |

**Business Insight**
Externalising application settings to the database gives operations teams the ability to tune system behaviour (e.g. email retry limits, cache TTLs) at runtime.

---

## 14. Backend Architecture

### Solution Structure

**Definition**
The Sakura backend is a **.NET 8 ASP.NET Core Web API** organised in a 4-layer clean architecture:

| Project | Layer | Responsibility |
|---------|-------|---------------|
| `Dentsu.SakuraApi` | API | Controllers, Middleware, DI configuration, routing |
| `Dentsu.Sakura.Application` | Application | Business logic, Services, DTOs, FluentValidation validators |
| `Dentsu.Sakura.Domain` | Domain | Entities, Enums, Interfaces, business rules |
| `Dentsu.Sakura.Infrastructure` | Infrastructure | EF Core DbContext, Repositories, UnitOfWork pattern |
| `Dentsu.Sakura.Shared` | Shared | Cross-cutting utilities (helpers, constants) |

---

### Service Classes

**Definition**
The Application layer services that implement business logic. Key services:

| Service | Responsibility |
|---------|---------------|
| `WorkspaceService` | CRUD for workspaces |
| `WorkspaceAppService` | CRUD for apps, OLSMode/ApprovalMode management |
| `AppAudienceService` | Audience management |
| `WorkspaceReportService` | Report registration and configuration |
| `WorkspaceSecurityModelService` | Security model and type management |
| `PermissionRequestService` | Request submission, status transitions |
| `PermissionApprovalPreparationService` | Routes approvals to correct approvers |
| `ResolveLmApproverService` | Looks up the requester's LM from `ref.Employees` |
| `RLSApproverService` | Manages RLS approver configuration |
| `GlobalWorkspaceAccessService` | Handles all-workspace override logic |
| `TokenService` | JWT token generation and validation |

---

### Repository / UnitOfWork Pattern

**Definition**
The Infrastructure layer uses the Repository pattern (one repository per aggregate root entity) and a UnitOfWork to wrap database transactions. All data access goes through `IRepository<T>` implementations backed by EF Core.

**Business Insight**
This pattern decouples business logic from data access, making services testable and the database layer replaceable without touching business rules.

---

### DTO (Data Transfer Object)

**Definition**
Typed request/response classes in the Application layer used to transfer data between the API controller and the service layer. DTOs are never the same as domain entities, preventing over-exposure of internal data structures.

**Example**
`CreateWorkspaceRequest`, `WorkspaceResponse`, `PermissionRequestDto` — all reside in `Dentsu.Sakura.Application`.

---

### Mapster

**Definition**
The object mapping library used in the backend to convert between domain entities and DTOs. Configured with explicit mapping profiles to avoid accidental field leakage.

---

### FluentValidation

**Definition**
The validation library used to validate incoming API requests before they reach the service layer. Validators are defined per DTO in the Application layer.

**Business Insight**
Centralising validation in the application layer ensures consistent error messages and prevents invalid data from ever reaching business logic or the database.

---

## 15. Frontend Architecture

### Angular SPA

**Definition**
The Sakura frontend is an **Angular 20** Single Page Application (SPA) using **PrimeNG** UI components. It communicates with the backend via the `ApiService` which auto-handles camelCase ↔ PascalCase conversion and cache invalidation.

---

### Domain-Driven Design (DDD) Frontend Structure

**Definition**
The frontend is organised into feature domains, each self-contained with its own components, services, models, and routes. Top-level domains:

| Domain Folder | Purpose |
|--------------|---------|
| `access` | My Access — view active OLS/RLS permissions |
| `approval` | My Approvals — LM/OLS/RLS approver dashboard |
| `catalogue` | Report Catalogue — browse and search all reports |
| `delegation` | Approval delegation management |
| `home` | Main dashboard |
| `request` | My Requests, request wizard, request detail |
| `workspace` | Workspace admin panel |
| `wso` | WSO console — full workspace security configuration |

---

### WSO Domain

**Definition**
The **Workspace Security Object** console in the frontend. A comprehensive admin interface for WSOs to manage all aspects of their workspace: apps, audiences, reports, security models, dimensions, approver assignments, access records, and audit logs.

**Sub-services:**
- `wso-domain-app.service.ts` — App CRUD
- `wso-domain-audience.service.ts` — Audience management
- `wso-domain-report.service.ts` — SAR report management
- `wso-domain-security-model.service.ts` — Security model configuration
- `wso-domain-dimension.service.ts` — Dimension management
- `wso-domain-assignment.service.ts` — Approver assignments
- `wso-domain-access.service.ts` — Access record views
- `wso-domain-audit.service.ts` — Audit log access

---

### Request Wizard

**Definition**
The multi-step form in the `request` domain that guides a user through selecting a workspace, report/audience, providing justification, and answering any `AdditionalQuestionsJSON` defined by the workspace.

**Use Case**
The primary entry point for requesters. Submitting the wizard creates a `PermissionRequest` record and initiates the approval chain.

---

### Report Catalogue

**Definition**
A searchable, browsable directory of all reports registered in Sakura across all workspaces. Filtered by `ReportKeywords`, workspace, and delivery method. The starting point for requesters who do not know the exact report name.

---

### ApiService

**Definition**
The central Angular service that wraps all HTTP calls to the backend. Key behaviours:
- Automatically converts PascalCase backend responses to camelCase for Angular
- Converts camelCase Angular payloads to PascalCase before sending to the backend
- Caches GET responses with TTL via `CacheService`
- Invalidates cache on POST/PUT/DELETE

---

### CacheService

**Definition**
A TTL-based in-memory cache in the Angular frontend that stores API responses. Reduces redundant backend calls for reference data (LoVs, enums, workspace lists) that change infrequently.

---

### lov.service.ts

**Definition**
The Angular service that fetches and caches all `LoV` entries from `/api/Common/lov`. Used throughout the frontend to populate dropdowns, labels, and configuration options.

---

### backend-endpoints.config.ts

**Definition**
A configuration file in the Angular frontend that centralises all API endpoint URL paths. All services reference this file instead of hard-coding URLs, making endpoint changes a single-file operation.

---

## 16. Authentication & Identity

### Azure AD / Entra ID

**Definition**
Microsoft's cloud identity platform used for authenticating Sakura users and managing Entra Groups (used for OLS enforcement). Sakura integrates via MSAL.

**Use Case**
Users log in to Sakura using their Dentsu Azure AD credentials. Access approvals result in users being added to or removed from Entra Groups.

---

### MSAL (Microsoft Authentication Library)

**Definition**
The Microsoft library used for OAuth2/OIDC authentication flows. Used in both the Angular frontend (`@azure/msal-angular`) and the .NET backend for token validation.

---

### JWT (JSON Web Token)

**Definition**
A stateless authentication token standard. Used as a fallback authentication mechanism in the Sakura backend during development/testing when Azure AD is not available.

---

### RefreshToken (`dbo.RefreshToken`)

**Definition**
A database table storing active refresh tokens for JWT-based authentication. Contains `Token`, `UserId`, `ExpiresAt`, and `Revoked` fields to support token rotation and revocation.

---

### AppEntraGroupUID / AudienceEntraGroupUID

**Definition**
The Azure AD Group Object GUID associated with a `WorkspaceApp` or `AppAudience`. When Sakura grants OLS access in Managed mode, it adds the user to this Entra group via the Microsoft Graph API.

**Business Insight**
These GUIDs are the critical link between Sakura's governance decisions and actual Power BI/Fabric access enforcement. An incorrect or missing GUID will break OLS access delivery.

---

## 17. Downstream Enforcement & Integrations

### EDP (Enterprise Data Platform)

**Definition**
Dentsu's downstream data platform (Microsoft Fabric / Power BI-based) that enforces the OLS and RLS entitlements published by Sakura. EDP reads from the `Share{Workspace}` views and applies the rules within Power BI semantic models.

**Business Insight**
Sakura governs; EDP enforces. This separation means Sakura remains a pure governance and workflow system, while enforcement is delegated to the platform closest to the data.

---

### Share Views (Downstream Contract)

**Definition**
Per-workspace read-only database views that publish approved permissions in a standardised format for EDP consumption.

- `Share{W}.OLS` — which users have approved access to which reports/audiences
- `Share{W}.RLS` — which dimension values each approved user may see

**Business Insight**
The Share views are the formal contract between Sakura and the downstream system. Any change to their schema must be coordinated with the EDP team.

---

### Power BI / Microsoft Fabric

**Definition**
The reporting and analytics platform whose reports are governed by Sakura. Power BI enforces OLS via Entra group membership and RLS via rules pushed from EDP using the Share view data.

---

### AzureSecretProvider

**Definition**
A backend service that retrieves secrets (database connection strings, API keys, Graph API credentials) from Azure Key Vault at runtime, avoiding hardcoded secrets in configuration files.

**Business Insight**
Centralising secrets in Key Vault, with access controlled by Managed Identity, is essential for security compliance and enables secret rotation without redeployment.

---

### Microsoft Graph API

**Definition**
The API used by the Sakura backend to manage Azure AD (Entra) Group memberships programmatically — adding users when access is approved (Managed OLS mode) and removing them when access is revoked.

---

## 18. Operational & Management Concepts

### mgmt Schema

**Definition**
A set of management tables used for operational oversight of the Sakura system.

| Table | Purpose |
|-------|---------|
| `mgmt.DataTransferSettings` | ADF pipeline configuration for each ref entity |
| `mgmt.DataTransferExecutions` | History of all ADF pipeline runs |
| `mgmt.EventLogs` | System event and error log |
| `mgmt.PostDeploymentScriptsHistory` | Tracks which post-deployment SQL scripts have been executed |
| `mgmt.PreDeploymentScriptsHistory` | Tracks which pre-deployment SQL scripts have been executed |

---

### DACPAC

**Definition**
Data-tier Application Package — the compiled artifact produced by the SQL Server Database Project (SSDT). Used for schema deployments via the CI/CD pipeline. The DACPAC compares the target database schema against the desired state and generates the appropriate migration SQL.

**Business Insight**
DACPAC-based deployments are declarative and idempotent — the pipeline always converges the database to the correct schema state without manual migration management.

---

### SSDT (SQL Server Data Tools)

**Definition**
The Visual Studio/VS Code toolset used to develop and manage the Sakura SQL Server database project. The project at `C:\Development\Sakura\Sakura_DB\` is an SSDT project that compiles to a DACPAC.

---

### Post-Deployment Scripts / Pre-Deployment Scripts

**Definition**
SQL scripts that run automatically after (or before) a DACPAC deployment to seed reference data, run data migrations, or set up initial configurations. Tracked in `mgmt.PostDeploymentScriptsHistory` and `mgmt.PreDeploymentScriptsHistory` to ensure they run only once.

---

### EventLog (`mgmt.EventLogs`)

**Definition**
A system-level log table recording significant events, errors, and state transitions within the Sakura application. Used by support teams to diagnose issues without requiring application log file access.

---

### Revocation

**Definition**
The act of removing a previously approved permission. Sets `RequestStatus = Revoked (5)` and `ApprovalStatus = Revoked (4)` on the relevant headers. In Managed OLS mode, also triggers removal from the Entra group.

**Business Insight**
Revocation is a critical governance capability — it ensures that users who change roles, leave teams, or whose access is no longer appropriate can be cleanly removed from all systems.

---

### Delegation

**Definition**
A feature allowing an approver to delegate their approval authority to another user for a defined period. Managed via the `delegation` domain in the frontend.

**Use Case**
An LM going on leave delegates their approval responsibilities to a colleague, ensuring approval queues do not stall during their absence.

---

## 19. Acronym Reference

| Acronym | Full Form | Context |
|---------|-----------|---------|
| **OLS** | Object-Level Security | Controls report/audience visibility |
| **RLS** | Row-Level Security | Controls data row visibility within a report |
| **SAR** | Standalone Access Report | Individual-access report delivery method |
| **AUR** | Audience Report | Audience-based report delivery method |
| **WSO** | Workspace Security Object | Workspace administrator role |
| **WSA** | Workspace Admin | Alternative label for WSO |
| **LM** | Line Manager | First approver in the approval chain |
| **GI** | Growth Insights | Workspace/domain code |
| **CDI** | Client Data Insights | Workspace/domain code |
| **WFI** | Workforce Insights | Workspace/domain code |
| **DFI** | Dentsu Finance Insights | Workspace/domain code |
| **FUM** | Finance Unified Model | Security type used in the DFI domain |
| **EMEA** | Europe, Middle East & Africa | Workspace/domain code |
| **AMER** | Americas | Workspace/domain code |
| **EDP** | Enterprise Data Platform | Downstream enforcement system |
| **UMS** | User Management System | Source of employee/LM data |
| **BPC** | Business Planning & Consolidation | Source of entity/client/brand data |
| **ADF** | Azure Data Factory | ETL pipeline for ref data sync |
| **MSS** | Master Service Set | Service grouping dimension |
| **SL** | Service Line | P&L service unit dimension |
| **CC** | Cost Centre | Financial cost centre dimension |
| **PA** | People Aggregator / Practice Area | Workforce / commercial dimension (context-dependent) |
| **PC** | Profit Centre | Financial profit centre dimension (AMER) |
| **LoV** | List of Values | Central lookup/enum table |
| **MapKey** | (Business key in ref tables) | Stable foreign key used in dimension columns |
| **SSDT** | SQL Server Data Tools | Database project development toolset |
| **DACPAC** | Data-tier Application Package | Compiled database deployment artifact |
| **DDD** | Domain-Driven Design | Frontend architecture pattern |
| **SPA** | Single Page Application | Frontend Angular app architecture |
| **MSAL** | Microsoft Authentication Library | OAuth2/OIDC auth library |
| **JWT** | JSON Web Token | Stateless auth token (fallback) |
| **TTL** | Time-To-Live | Cache expiration duration |
| **DTO** | Data Transfer Object | API request/response typed classes |
| **EF Core** | Entity Framework Core | .NET ORM used in Infrastructure layer |
| **SLA** | Service Level Agreement | Target response/approval time commitments |
| **DI** | Dependency Injection | .NET IoC pattern used in backend |
| **ROMV** | Read-Only Managed View | Application-facing DB views |

---

*Document generated for SakuraV2 | Dentsu | Last updated: March 2026*
