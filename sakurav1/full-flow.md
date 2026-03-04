# Sakura — Complete End-to-End System Guide

**Document Purpose:** A comprehensive reference for understanding every component, role, data flow, and potential issue across the entire Sakura system — from a user clicking "Request Access" to that user seeing a Power BI report.

**Database Server:** `azeuw1senmastersvrdb01.database.windows.net` → Database: `Sakura`  
**Portal VM:** Azure VM (Dentsu Azure Cloud, VPN-only, not public internet)  
**Last Updated:** March 2026

---

## Table of Contents

1. [What is Sakura? — The Big Picture](#1-what-is-sakura--the-big-picture)
2. [Key Players — Who Does What](#2-key-players--who-does-what)
3. [System Architecture Diagram](#3-system-architecture-diagram)
4. [Where Data Lives](#4-where-data-lives)
5. [The Complete Request Flow — Step by Step](#5-the-complete-request-flow--step-by-step)
6. [Permission Types Explained](#6-permission-types-explained)
7. [How Approvers Are Found](#7-how-approvers-are-found)
8. [The Email System — Two Separate Pipelines](#8-the-email-system--two-separate-pipelines)
9. [The AD Sync Engine — How Access Gets Enforced](#9-the-ad-sync-engine--how-access-gets-enforced)
10. [How Power BI Access Works End-to-End](#10-how-power-bi-access-works-end-to-end)
11. [The Audit Trail — Full Traceability](#11-the-audit-trail--full-traceability)
12. [Data Imports — Where Reference Data Comes From](#12-data-imports--where-reference-data-comes-from)
13. [Component Dependency Map](#13-component-dependency-map)
14. [What Can Go Wrong — Issues by Stage](#14-what-can-go-wrong--issues-by-stage)
15. [Quick Diagnostic Queries](#15-quick-diagnostic-queries)

---

## 1. What is Sakura? — The Big Picture

Sakura is a **self-service permission management portal** for the Dentsu organization. Its primary job is to control who gets access to **Power BI reports**, by managing membership in **Azure Active Directory (Azure AD) Security Groups**.

Think of it as an orchestration layer that sits between a user asking for access and that user actually getting it. Nothing happens directly — every access grant goes through a defined, auditable workflow.

**In plain language, Sakura does these six things:**

| What It Does | How |
|---|---|
| Lets users request access to Power BI reports | Web portal (GAPTEQ-based, hosted on Azure VM) |
| Routes requests to the right approvers | Automated approver-finding based on org hierarchy |
| Sends email notifications at each step | .NET EmailDispatcher + SMTP relay |
| Records every action for audit | SQL `EventLog` table (immutable) |
| Syncs approved access into Azure AD groups | PowerShell script `SakuraADSync.ps1` + Microsoft Graph API |
| Enforces access in Power BI | Azure AD group membership → Power BI workspace/app access |

**Sakura is NOT responsible for:**
- Creating Azure AD groups (they must already exist)
- Creating or managing Power BI reports
- Delivering emails (it queues them; the EmailDispatcher sends them)
- Directly modifying Azure AD (the sync script does that separately)
- User authentication (handled by Azure Active Directory / SSO)

---

## 2. Key Players — Who Does What

### 2.1 Human Roles

```
┌────────────────────────────────────────────────────────────────────────┐
│  ROLE              │  WHAT THEY DO IN SAKURA                          │
├────────────────────┼───────────────────────────────────────────────────┤
│  Regular User      │  Creates permission requests via the portal.      │
│  (Requester)       │  Can see their own requests on "My Requests".     │
│                    │  Receives emails about approval/rejection.         │
├────────────────────┼───────────────────────────────────────────────────┤
│  Approver          │  Reviews and approves/rejects requests.           │
│                    │  Assigned per organizational dimension.            │
│                    │  Sees pending requests on "My Approvals".         │
│                    │  Can approve in bulk.                              │
│                    │  Can approve via email link (anti-forgery checked) │
├────────────────────┼───────────────────────────────────────────────────┤
│  Administrator     │  Full access to everything.                       │
│                    │  Can manage approvers, LoVs, settings, templates. │
│                    │  Can revoke requests in batch.                     │
│                    │  Can export data to Excel.                         │
│                    │  Can view "All Approvals" across all users.        │
│                    │  Can append approvers to pending requests.         │
├────────────────────┼───────────────────────────────────────────────────┤
│  Support Admin     │  Elevated privileges below Admin.                 │
│                    │  Can assist with request management.               │
│                    │  Can manage email queue and troubleshoot issues.   │
│                    │  Can create requests on behalf of other users.     │
└────────────────────┴───────────────────────────────────────────────────┘
```

### 2.2 System Components (Non-Human "Players")

```
┌────────────────────────────────────────────────────────────────────────┐
│  COMPONENT                      │  WHAT IT DOES                       │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Sakura Portal (GAPTEQ Web App) │  The UI. Users interact here.       │
│                                 │  Calls SQL stored procedures.        │
├─────────────────────────────────┼─────────────────────────────────────┤
│  SQL Database (Ronin/Sakura DB) │  Source of truth. Stores all        │
│                                 │  requests, approvals, audit logs,    │
│                                 │  reference data, email queue.        │
├─────────────────────────────────┼─────────────────────────────────────┤
│  SakuraADSync.ps1               │  PowerShell script that runs on a   │
│                                 │  schedule. Reads "desired state"     │
│                                 │  from DB and syncs Azure AD groups.  │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Sakura.Toolbox.EmailDispatcher │  .NET console app running every 5   │
│                                 │  minutes. Picks unsent emails from  │
│                                 │  DB and sends via SMTP relay.        │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Azure Active Directory         │  Stores security groups. Group      │
│                                 │  membership = who can see reports.   │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Microsoft Graph API            │  The API used by SakuraADSync.ps1   │
│                                 │  to read/write Azure AD groups.      │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Power BI Service               │  Reports live here. Access enforced │
│                                 │  by Azure AD group membership.       │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Sensei (Source System)         │  External source of reference data  │
│                                 │  (Clients, Cost Centers, Entities,  │
│                                 │  Service Lines). Feeds into Sakura  │
│                                 │  via ADF pipeline + staging tables.  │
├─────────────────────────────────┼─────────────────────────────────────┤
│  Azure Data Factory (ADF)       │  Orchestrates data movement from    │
│  Pipeline: P_ALL_SAKURA_D_Auto  │  Sensei into Sakura staging tables. │
├─────────────────────────────────┼─────────────────────────────────────┤
│  SMTP Relay                     │  Internal relay server that handles │
│  internalsmtprelay.media.       │  actual email delivery (no auth).   │
│  global.loc:25                  │                                     │
└─────────────────────────────────┴─────────────────────────────────────┘
```

---

## 3. System Architecture Diagram

```
╔══════════════════════════════════════════════════════════════════════════╗
║  EXTERNAL DATA SOURCE                                                    ║
║  ┌─────────┐    ADF Pipeline    ┌─────────────────────┐                 ║
║  │ Sensei  │ ─────────────────► │ SAKURA_Staging.*    │                 ║
║  │(Source) │                    │ tables (in Ronin DB) │                 ║
║  └─────────┘                    └──────────┬──────────┘                 ║
║                                            │ sp_Load_* procedures       ║
║                                            ▼                            ║
╚══════════════════════════════════════════════════════════════════════════╝
                                             │
                                             ▼
╔══════════════════════════════════════════════════════════════════════════╗
║  SAKURA DATABASE  (azeuw1senmastersvrdb01 / Sakura DB)                   ║
║                                                                          ║
║  ┌──────────────────────┐   ┌───────────────────────┐                   ║
║  │ Reference Data       │   │ Permission Tables      │                   ║
║  │  Entity, ServiceLine │   │  PermissionHeader      │                   ║
║  │  CostCenter, Client  │   │  PermissionOrgaDetail  │                   ║
║  │  MasterServiceSet    │   │  PermissionCPDetail    │                   ║
║  │  ReportingDeck       │   │  PermissionSGMDetail   │                   ║
║  │  LoV, AppSettings    │   │  PermissionMSSDetail   │                   ║
║  └──────────────────────┘   └───────────────────────┘                   ║
║                                        │                                 ║
║  ┌──────────────────────┐   ┌──────────▼──────────────────────────┐     ║
║  │ Approver Tables      │   │ RDSecurityGroupPermission (VIEW)     │     ║
║  │  ApproversOrga       │   │ ← "Desired State" of group membership│     ║
║  │  ApproversCP         │   │   Only approved requests appear here │     ║
║  │  ApproversMSS        │   └───────────────────────┬─────────────┘     ║
║  │  ApproversSGM        │                           │ READ               ║
║  │  ApproverDelegation  │   ┌──────────────────┐    │                   ║
║  └──────────────────────┘   │ EventLog (Audit) │    │                   ║
║                             │ 600K+ records    │    │                   ║
║  ┌──────────────────────┐   └──────────────────┘    │                   ║
║  │ Email Tables         │                           │                   ║
║  │  Emails (queue)      │                           │                   ║
║  │  EmailTemplates      │                           │                   ║
║  └──────────────────────┘                           │                   ║
╚══════════════════════════════════════════════════════════════════════════╝
         │                 │                          │
         │ (every 5 min)   │ (on portal events)       │ (scheduled run)
         ▼                 ▼                          ▼
╔════════════════╗  ╔═══════════════════════════╗  ╔═══════════════════════╗
║ EmailDispatcher║  ║  Sakura Portal (GAPTEQ)   ║  ║  SakuraADSync.ps1     ║
║ .NET App       ║  ║  Web UI on Azure VM       ║  ║  PowerShell script    ║
║ sends emails   ║  ║  behind Dentsu VPN        ║  ║  on Azure VM          ║
╚══════╦═════════╝  ╚═══════════════════════════╝  ╚══════════╦════════════╝
       ║                      ▲                               ║
       ║                      │ Users, Approvers, Admins      ║ Microsoft
       ▼                      │                               ║ Graph API
╔════════════════╗            │                               ▼
║ SMTP Relay     ║            │                    ╔══════════════════════╗
║ :25 (internal) ║            │                    ║  Azure AD            ║
╚══════╦═════════╝            │                    ║  Security Groups     ║
       ║                      │                    ╚══════════╦═══════════╝
       ▼                      │                               ║
╔════════════════╗     ╔══════╧══════════════╗                ║ Group
║ User's Inbox   ║     ║  Azure AD / SSO     ║                ║ Membership
║ (email arrives)║     ║  (Authentication)   ║                ▼
╚════════════════╝     ╚═════════════════════╝     ╔══════════════════════╗
                                                   ║  Power BI Service    ║
                                                   ║  Reports & Dashboards║
                                                   ╚══════════════════════╝
```

---

## 4. Where Data Lives

### 4.1 Core Tables

| Table | What It Stores | Why It Matters |
|---|---|---|
| `PermissionHeader` | Every permission request ever made — its status, who requested it, who approved it, when. | The central record for every request. One row = one permission request. |
| `PermissionOrgaDetail` | Org-scope details: Entity, ServiceLine, CostCenter for Orga-type requests. | Determines what organizational dimension was requested. |
| `PermissionCPDetail` | Client-Project details for CP-type requests. | Determines the client/project scope. |
| `PermissionMSSDetail` | Master Service Set scope details. | For MSS-type permission requests. |
| `PermissionSGMDetail` | Security Group Manager scope details. | For SGM-type requests. |
| `PermissionReportingDeckDetail` | Reporting Deck scope details. | Direct reporting deck access requests. |
| `ApproversOrga` | Who can approve Organization permission requests for which scope. | Drives automatic approver routing. |
| `ApproversCP` | Who can approve Client Project permission requests. | Same as above, for CP type. |
| `ApproversMSS` | Who can approve MSS permission requests. | Same for MSS. |
| `ApproversSGM` | Who can approve SGM permission requests. | Same for SGM. |
| `ApproverDelegation` | Temporary delegation records (who is covering for whom). | Handles approver absences. |
| `ReportingDeck` | The reporting deck definitions. | Each deck maps to a set of AD groups. |
| `ReportingDeckSecurityGroups` | Maps reporting decks to Azure AD group GUIDs. | **Critical:** This is what ties an approved request to an actual Azure AD group. |
| `Emails` | The email queue. Every email Sakura wants to send sits here until dispatched. | If this table has stuck rows, users aren't getting notifications. |
| `EmailTemplates` | HTML email templates with variable placeholders. | Controls what users actually receive. |
| `EventLog` | Immutable audit log of every significant event in the system. | Your primary investigation tool. 600K+ rows. |
| `ApplicationSettings` | Runtime configuration flags (email mode, environment tag, retry settings). | Controls system behavior without code changes. |
| `LoV` (List of Values) | Dropdown options and configuration enumerations. | Powers all dropdowns in the portal UI. |
| `Entity` | Organizational hierarchy (Global → Region → Cluster → Market → Entity). | Used to scope permissions and find approvers. |
| `ServiceLine` | Service line hierarchy. | Critical — group names are built around service line codes. |
| `CostCenter` | Cost center data. | Used for CC-type permissions. |
| `Client` | Client/customer data (~96K rows). | Used for CP-type permissions. |
| `MasterServiceSet` | Master service set data. | Used for MSS-type permissions. |

### 4.2 Critical Views

| View | What It Aggregates | Who Reads It |
|---|---|---|
| `RDSecurityGroupPermission` | **The desired state.** All approved requests (Orga, CC, MSS types) translated into user → Azure AD group GUID mappings. Only status=1 (approved), only RequestType IN (0,2,7). | `SakuraADSync.ps1` — this is its only input. |
| `PermissionHeaderList` | All requests with human-readable descriptions, joined with reference data. | Portal UI, Power BI monitoring dashboard. |
| `EmailsToSend` | Emails table filtered to Status=0 (unsent). | EmailDispatcher .NET app — this is its query. |
| `OrgaPermission`, `CPPermission`, `CCPermission`, `SGMPermission` | Type-specific views of approved permissions. | Reporting, Power BI dashboards. |
| `EntityCluster`, `EntityClusterRegion`, etc. | Hierarchical entity views. | Portal dropdowns, reporting. |

### 4.3 Staging Tables (Data Import Area)

| Table | Source | Purpose |
|---|---|---|
| `SAKURA_Staging.Client` | Sensei (via ADF) | Staging before load into `SAKURA.Client` |
| `SAKURA_Staging.CostCenter` | Sensei (via ADF) | Staging before load into `SAKURA.CostCenter` |
| `SAKURA_Staging.Entity` | Sensei (via ADF) | Staging before load into `SAKURA.Entity` |
| `SAKURA_Staging.ServiceLine` | Sensei (via ADF) | Staging before load into `SAKURA.ServiceLine` |

### 4.4 History / Audit Tables

Every core table has a corresponding `history.*` table (e.g., `history.PermissionHeader`, `history.ApproversOrga`) that stores every change ever made — the "time machine" layer.

---

## 5. The Complete Request Flow — Step by Step

This is the single most important flow to understand. Follow a request from birth to Power BI access:

```
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 1 — USER CREATES REQUEST                                      │
│                                                                      │
│  User logs into Sakura Portal (Azure AD SSO authentication)         │
│  → Navigates to "New Request"                                        │
│  → Selects permission type (Orga / CP / CC / MSS / SGM)             │
│  → Fills in scope: Entity, Service Line, Cost Center, etc.          │
│  → Submits                                                           │
│                                                                      │
│  PORTAL CALLS: CreateOrgaPermissionRequest (or CP / MSS / SGM)      │
│  DATABASE ACTIONS:                                                   │
│  1. FindApprovers → FindOrgaApprovers → look up ApproversOrga table  │
│  2. Insert PermissionHeader (ApprovalStatus = 0 = Pending)          │
│  3. Insert PermissionOrgaDetail (the scope details)                 │
│  4. AddToEventLog: "RequestCreated"                                  │
│  5. AddToEmailQueue: email to requester (request received)          │
│  6. AddToEmailQueue: email to approvers (action needed)             │
│  [If requester IS the approver → auto-approve immediately]          │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 2 — EMAIL NOTIFICATION                                        │
│                                                                      │
│  Emails are queued in [dbo].[Emails] table (Status = 0)             │
│  EmailDispatcher .NET app runs every 5 minutes                      │
│  → Reads top 20 rows from [dbo].[EmailsToSend] view                │
│  → Constructs HTML email from template                               │
│  → Sends via SMTP relay (internalsmtprelay.media.global.loc:25)     │
│  → Calls MarkEmailAsSent → Status updated to 1                      │
│                                                                      │
│  RESULT: Requester gets "Request Received" email                    │
│          Approver(s) get "Action Required" email                    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 3 — APPROVER REVIEWS AND APPROVES                            │
│                                                                      │
│  Approver logs into portal → goes to "My Approvals"                 │
│  → Reviews the request                                               │
│  → Clicks "Approve" (or approves via email link)                    │
│                                                                      │
│  PORTAL CALLS: ApprovePermissionRequest (@RequestId, @ApprovedBy)   │
│  DATABASE ACTIONS:                                                   │
│  1. Validate request is Pending and approver is in Approvers list   │
│  2. Update PermissionHeader: ApprovalStatus = 1, ApprovedBy, Date  │
│  3. AddToEventLog: "PermissionRequestApproved"                      │
│  4. AddToEmailQueue: email to requester (request approved)          │
│                                                                      │
│  [If rejected]: ApprovalStatus = 2, email sent with reason          │
│  [If revoked later]: ApprovalStatus = 3, email sent (if enabled)    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 4 — DESIRED STATE COMPUTED                                    │
│                                                                      │
│  Now that ApprovalStatus = 1, this request appears in the          │
│  RDSecurityGroupPermission VIEW                                      │
│                                                                      │
│  The view does this logic:                                           │
│  → Takes all PermissionHeader rows with ApprovalStatus = 1         │
│  → Filters to RequestType IN (0=Orga, 2=CC, 7=MSS) only            │
│  → Joins to PermissionOrgaDetail to get ServiceLineCode            │
│  → Joins to ReportingDeckSecurityGroups                             │
│  → Filters: group name must CONTAIN the ServiceLine code            │
│    (e.g., ServiceLineCode="CXM" → matches "#SG-UN-SAKURA-CXM*")   │
│  → Returns: RequestedFor email + SecurityGroupGUID pairs            │
│                                                                      │
│  SPECIAL CASE: ALL approved users also appear for the               │
│  "#SG-UN-SAKURA-EntireOrg" group (gives app-level access)          │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 5 — AD SYNC RUNS (SakuraADSync.ps1)                          │
│                                                                      │
│  Script runs on a schedule (every 5 min or similar)                 │
│  on the Azure VM (C:\Installations\SakuraADSyncer\)                 │
│                                                                      │
│  WHAT IT DOES:                                                       │
│  1. Connect to SQL → SELECT from RDSecurityGroupPermission          │
│  2. Build list of desired users per group (desired state)           │
│  3. For each unique user → call Get-MgUser (Graph API) to get UUID  │
│  4. For each unique group:                                           │
│     a. Get-MgGroup to verify group exists                           │
│     b. Get-MgGroupMemberAsUser to get current members               │
│     c. Compare desired vs actual                                    │
│     d. REMOVE members not in desired state (Remove-MgGroupMemberByRef)│
│     e. ADD members missing from Azure AD (Update-MgGroup, 20/batch) │
│     f. Log each action to EventLog (GroupMemberAdded/Removed)       │
│  5. Send admin summary email to onur.ozturk@dentsu.com              │
│  6. Save log to output_{timestamp}.log file                         │
│                                                                      │
│  REQUIRES: Account with Group.ReadWrite.All permission              │
│  (Currently: EMEA-MEDIA\OOeztu01)                                   │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 6 — POWER BI READS GROUP MEMBERSHIP                          │
│                                                                      │
│  Azure AD security group now contains the user                      │
│  Power BI workspace/app has that group assigned to it               │
│  → Power BI reads group membership from Azure AD                    │
│  → User can now open the report                                     │
│                                                                      │
│  NOTE: There can be a propagation delay of minutes to hours in      │
│  Azure AD before the change is visible in Power BI.                 │
│  Ask users to: log out → log back in → refresh Power BI.            │
└─────────────────────────────────────────────────────────────────────┘
```

### Request Lifecycle States

```
Created → Pending (0)
             │
             ├──► Approved (1) ──► [appears in RDSecurityGroupPermission]
             │                            │
             │                            ▼ (next sync)
             │                     User added to Azure AD group
             │                            │
             │                            ▼
             │                     User can access Power BI
             │                            │
             │                     [Admin revokes] ──► Revoked (3)
             │                                              │
             │                                         (next sync)
             │                                         User removed from group
             │
             └──► Rejected (2) ──► [end state, no access granted]
```

---

## 6. Permission Types Explained

| Type Code | Name | Scope | Maps to AD Groups? | Group Logic |
|---|---|---|---|---|
| 0 | **Orga** (Organisation) | Entity + ServiceLine + CostCenter | **Yes** | ServiceLine code matched inside group name |
| 1 | **CP** (Client Project) | Entity + Client | No (direct group sync) | CP requests excluded from RDSecurityGroupPermission |
| 2 | **CC** (Cost Center) | ServiceLine + CostCenter | **Yes** | Same logic as Orga |
| 4 | **Reporting Deck** | Reporting Deck selection | No (direct) | Excluded from main sync view |
| 5 | **SGM** (Security Group Manager) | Security Group code | No (direct) | Excluded from main sync view |
| 6 | **DSR** (Data Subject Request) | Specific | No | Excluded |
| 7 | **MSS** (Master Service Set) | MSS code | **Yes** | Same logic as Orga |
| Samurai | **Samurai** | Dynamic wizard | Yes | Combines Org, CC, CP in one flow |

> **Key insight:** Only Orga (0), CC (2), and MSS (7) requests actually flow through the `RDSecurityGroupPermission` view into Azure AD group sync. CP/SGM/Reporting Deck requests have different mechanisms.

---

## 7. How Approvers Are Found

When a user creates a request, Sakura automatically determines who should approve it. This is done by a hierarchy of stored procedures:

```
CreateOrgaPermissionRequest
        │
        ▼
  FindApprovers (@RequestType)
        │
        ├─ RequestType = 0 or 2 → FindOrgaApprovers
        │                              │
        │                              ▼
        │                    fnFindOrgaApproversExact
        │                              │
        │                              ▼
        │                    Lookup ApproversOrga table
        │                    (match on EntityLevel, EntityCode,
        │                     ServiceLineCode, CostCenterCode)
        │
        ├─ RequestType = 1 → FindCPApprovers → ApproversCP
        ├─ RequestType = 5 → FindSGMApprovers → ApproversSGM
        ├─ RequestType = 7 → FindMSSApprovers → ApproversMSS
        └─ RequestType = 4 → FindReportingDeckApprovers → ApproversReportingDeck
```

**Hierarchical matching:** If no approver is found for the exact scope (e.g., exact market + service line), the system walks up the hierarchy to find an approver at a broader level (e.g., regional or global level).

**Delegation:** The `ApproverDelegation` table allows time-boxed delegation — when an approver is on leave, they can delegate to someone else.

**Auto-approval:** If the user creating the request (RequestedBy) or the user the request is for (RequestedFor) is already in the resolved approvers list, the request is auto-approved immediately.

---

## 8. The Email System — Two Separate Pipelines

Sakura has **two independent email systems**. It is critical to understand they are completely separate:

### 8.1 Pipeline 1: User Notification Emails (Sakura.Toolbox.EmailDispatcher)

This handles all access-related emails that users see.

```
Stored Procedure Event (create/approve/reject/revoke)
        │
        ▼
AddToEmailQueue → FindEmailRecipients → QueueEmail → ConstructEMail
        │
        ▼
[dbo].[Emails] table — row inserted, Status = 0 (unsent)
        │
        │   (every 5 minutes)
        ▼
Sakura.Toolbox.EmailDispatcher.exe
  - Queries [dbo].[EmailsToSend] view (Status=0, top 20, oldest first)
  - Builds MimeMessage from HTML body in DB
  - Sends via internalsmtprelay.media.global.loc:25
  - On success: calls MarkEmailAsSent → Status = 1
  - On failure: calls MarkEmailAsUnsent → Status stays 0, NumberOfTries++
        │
        ▼
User's inbox
```

**What emails are sent:**

| Event | Who Receives It |
|---|---|
| Request created | The requester (RequestedFor) |
| Awaiting approval | All assigned approvers |
| Request approved | The requester |
| Request rejected | The requester (with rejection reason) |
| Request revoked | The requester (only if setting `CreatePermissionRevokedEmails = '1'`) |
| Approver appended | The newly added approver |

### 8.2 Pipeline 2: Admin Sync Alert (SakuraADSync.ps1)

This is a completely separate, hardcoded alert that fires after each AD sync run.

```
SakuraADSync.ps1 completes a sync run
        │
        ▼
System.Net.Mail.SmtpClient
  - To: onur.ozturk@dentsu.com (HARDCODED — only one person)
  - Subject: [Sakura AD Sync - TEST]: Success / Failure
  - Body: Err Count: X — Operations Count: Y
  - Attachment: output_{timestamp}.log file
```

This is **not** user-facing. It's an operations alert only.

---

## 9. The AD Sync Engine — How Access Gets Enforced

`SakuraADSync.ps1` is the enforcement arm of Sakura. Without it running correctly, no approved requests translate into actual Power BI access.

### 9.1 What It Does

1. Reads the `RDSecurityGroupPermission` view → this is "what should exist in Azure AD"
2. Calls Microsoft Graph API to read what actually exists in Azure AD
3. Calculates the difference
4. Adds users who should be there but aren't
5. Removes users who are there but shouldn't be
6. Logs every action to `EventLog`

### 9.2 Authentication Requirement

The script connects using `Connect-MgGraph`. The account used **must have `Group.ReadWrite.All` permission** in Azure AD.

- **Reading groups/users** requires only read permissions (anyone can do this)
- **Modifying group membership** requires `Group.ReadWrite.All` (restricted)

If the wrong account runs the script, `Connect-MgGraph` will succeed (authentication works for everyone) but `Update-MgGroup` will fail with `403 Forbidden — Insufficient privileges`.

**Currently working account:** `EMEA-MEDIA\OOeztu01`

### 9.3 Sync Logic Detail

```
For each unique group in RDSecurityGroupPermission:

  Desired members (from Sakura DB):
    → All users in RDSecurityGroupPermission for this group GUID
    → Mapped to Azure AD User Object IDs via Get-MgUser lookup

  Actual members (from Azure AD):
    → Get-MgGroupMemberAsUser for this group GUID

  Diff:
    → In desired but not actual = ADD
    → In actual but not desired = REMOVE
    → In desired but user not found in Azure AD = log GroupMemberNotAdded (cannot add)

  Actions:
    → Remove: Remove-MgGroupMemberByRef (one call per user)
    → Add: Update-MgGroup with members@odata.bind (batched, 20 users per call)
```

### 9.4 What Gets Logged

Every add/remove action is written to `EventLog`:

| EventName | Meaning |
|---|---|
| `GroupMemberAdded` | User successfully added to Azure AD group |
| `GroupMemberRemoved` | User successfully removed from Azure AD group |
| `GroupMemberNotAdded` | User in desired state but could not be found in Azure AD |

All are logged with `TableName = 'RDSecurityGroupPermission'`, `RecordId = -1`, `EventTriggeredBy = 'SakuraADSync.ps1'`.

---

## 10. How Power BI Access Works End-to-End

The connection between Sakura and Power BI is **entirely via Azure AD Security Groups**. Sakura never touches Power BI directly.

```
Sakura DB          →    Azure AD Group    →    Power BI
(desired state)         (enforced state)       (consumes state)

RDSecurityGroupPermission VIEW
  RequestedFor: "user@dentsu.com"
  SecurityGroupGUID: "368c81e7-..."
  SecurityGroupName: "#SG-UN-SAKURA-CXMBU"
         │
         │ SakuraADSync.ps1 syncs this
         ▼
Azure AD Group: #SG-UN-SAKURA-CXMBU (GUID: 368c81e7-...)
  Members: [..., "user@dentsu.com", ...]
         │
         │ Power BI reads group membership
         ▼
Power BI Workspace/App:
  Access granted to group: #SG-UN-SAKURA-CXMBU
  → user@dentsu.com can now open the report
```

### Group Name Convention

Group names follow the pattern: `#SG-UN-SAKURA-{ServiceLineCode}[suffix]`

For example:
- `#SG-UN-SAKURA-CXM` — CXM service line
- `#SG-UN-SAKURA-CXMBU` — CXM Business Unit
- `#SG-UN-SAKURA-EntireOrg` — All approved users (app-level access)

The ServiceLine code is matched inside the group name by a `CHARINDEX()` check in the `RDSecurityGroupPermission` view. If the group name doesn't contain the service line code, it will not be included in the sync for that request.

### The ReportingDeckSecurityGroups Table — The Bridge

This is the table that maps everything together:

```
PermissionHeader.ApplicationLoVId
        ↓
ReportingDeckSecurityGroups
  ApplicationLoVId  →  links to the Power BI application
  ReportingDeckId   →  links to the reporting deck
  SecurityGroupGUID →  the actual Azure AD group GUID
  SecurityGroupName →  must contain the ServiceLine code
```

If `SecurityGroupGUID` is NULL for an entry, it **cannot be synced** — the sync script filters out entries with null GUIDs.

---

## 11. The Audit Trail — Full Traceability

Every significant event is written to `[dbo].[EventLog]`. This is your first stop when investigating any issue.

### EventLog Schema

| Column | What It Contains |
|---|---|
| `EventLogId` | Auto-increment PK |
| `TableName` | Which entity triggered this (e.g., 'PermissionHeader', 'RDSecurityGroupPermission') |
| `RecordId` | The RequestId or -1 for system events |
| `EventTimestamp` | When it happened |
| `EventName` | Type of event (see below) |
| `EventDescription` | Human-readable description |
| `EventTriggeredBy` | Who/what caused it (procedure name, user email, or 'SakuraADSync.ps1') |

### Full Event Timeline for One Request

```
EventTimestamp          EventName                    EventTriggeredBy
─────────────────────── ──────────────────────────── ─────────────────────────────
[T+0:00]  RequestCreated              CreateOrgaPermissionRequest
[T+0:00]  Notification-Created        QueueEmail (requester email queued)
[T+0:00]  Notification-Created        QueueEmail (approver email queued)
[T+0:05]  EmailSent                   EmailDispatcher (emails sent)

[T+approval] PermissionRequestApproved   ApprovePermissionRequest
[T+approval] Notification-Created        QueueEmail (approved email queued)

[T+next sync] GroupMemberAdded          SakuraADSync.ps1
```

### Key Queries for Investigation

**Trace a specific user's full history:**
```sql
SELECT EL.*
FROM EventLog EL
JOIN PermissionHeader PH ON EL.TableName = 'PermissionHeader' AND EL.RecordId = PH.RequestId
WHERE PH.RequestedFor = 'user@dentsu.com'
ORDER BY EL.EventTimestamp DESC;
```

**Check if AD sync ran for a user:**
```sql
SELECT EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventDescription LIKE '%user@dentsu.com%'
ORDER BY EventTimestamp DESC;
```

**Check recent sync operations:**
```sql
SELECT EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventTriggeredBy = 'SakuraADSync.ps1'
  AND EventTimestamp >= DATEADD(day, -1, GETDATE())
ORDER BY EventTimestamp DESC;
```

---

## 12. Data Imports — Where Reference Data Comes From

Sakura's dropdown options (Entities, Cost Centers, Clients, Service Lines) don't live in Sakura originally — they come from **Sensei**, an external source system.

### The Pipeline

```
Sensei (source system)
        │
        │  Azure Data Factory
        │  Pipeline: P_ALL_SAKURA_D_Automation
        ▼
SAKURA_Staging.Client / CostCenter / Entity / ServiceLine
        │
        │  Stored Procedures:
        │  sp_Load_Client
        │  sp_Load_CostCenter
        │  sp_Load_Entity
        │  sp_Load_ServiceLine
        ▼
SAKURA.Client / CostCenter / Entity / ServiceLine
(production tables used by portal and sync logic)
```

### What the Load Procedures Do

Each `sp_Load_*` procedure does 4 things:

1. **Initial Insert** — Inserts new records from staging that don't exist in production yet
2. **Resurrection** — Marks previously deleted items as active again if they reappear
3. **Deletion Marking** — Marks records as deleted (sets `DeleteDate`) if they've disappeared from staging
4. **Actualization** — Updates existing records with fresh data from staging

History of all changes is preserved in `history.*` tables. System-versioned tables (`Client`, `CostCenter`, `Entity`, `ServiceLine`) also support point-in-time queries.

---

## 13. Component Dependency Map

Understanding which components depend on which others helps you trace the impact of any failure:

```
IF THIS FAILS...          THEN THIS BREAKS...
──────────────────────    ──────────────────────────────────────────────────
Azure AD (SSO)            Users cannot log into the portal at all

Sakura Portal (GAPTEQ)    Users cannot create or approve requests
                          (but previously approved ones still sync)

SQL Database              Everything. Portal, EmailDispatcher, SakuraADSync.
                          Complete outage.

EmailDispatcher           Emails queue up in Emails table. No notifications.
                          Requests still work; users just don't get emails.
                          (Queue drains when service recovers)

SakuraADSync.ps1          Access is not enforced. Approved requests stay
                          approved in DB but Azure AD groups are not updated.
                          Users don't get access (or lose access) until sync
                          next runs successfully.

Microsoft Graph API       SakuraADSync.ps1 cannot modify group membership.
                          Sync runs but does nothing effective.

SMTP Relay                Email sending fails. EmailDispatcher retries.
                          No notification emails.

Sensei / ADF Pipeline     Reference data goes stale. New entities/cost centers
                          won't appear in dropdowns. Existing requests unaffected.

RDSecurityGroupPermission If this view breaks/returns wrong data, sync will
(VIEW)                    add wrong users or remove correct users from groups.
                          CRITICAL — any change to this view must be coordinated
                          with SakuraADSync.ps1 simultaneously.

ReportingDeckSecurityGroups If SecurityGroupGUID is NULL or wrong in this table,
(TABLE)                     affected users won't appear in the sync view,
                            so they won't be added to Azure AD groups.
```

---

## 14. What Can Go Wrong — Issues by Stage

### Stage 1: Request Creation

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| No approver found | Request created but no approver email sent; request stays in limbo | No entry in `ApproversOrga` (or CP/MSS/SGM) for the selected scope. Hierarchical lookup also found nothing. | Check `ApproversOrga` table for relevant EntityCode + ServiceLineCode |
| Duplicate request blocked | User gets "already exists" error | Same user/type/scope/app already has a pending or approved request | Check `PermissionHeader` for that user + filter by status 0 or 1 |
| Missing reference data | Dropdown is empty or entity not available | ADF pipeline hasn't run or Sensei data is missing | Check `SAKURA_Staging` tables, check ADF pipeline logs |

### Stage 2: Email Notifications

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| Emails not arriving | User doesn't receive notification | EmailDispatcher not running / SMTP relay down / EmailingMode = 0 | Check `[dbo].[Emails]` for Status=0 rows; check `ApplicationSettings` for `EmailingMode`; check scheduled task on VM |
| Emails going to wrong person | Wrong recipient receives email | Built in DEBUG mode (overrides all recipients to one address) | Check app compile mode; check `To` field in `[dbo].[Emails]` |
| Duplicate emails | User gets same email multiple times | EmailDispatcher running multiple instances / `MarkEmailAsSent` not firing | Check for duplicate scheduled tasks; check `NumberOfTries` in Emails table |

### Stage 3: Approval Process

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| Approver can't see request | "My Approvals" is empty for approver | Approver's email not matching `PermissionHeader.Approvers` list | Check `PermissionHeader.Approvers` column for that RequestId |
| Email approval link fails | Anti-forgery check fails | Token expired or approver not in approvers list | `CheckEmailApprovalAntiForgery` stored procedure |
| Request stuck in pending | No one approved for a long time | Approver changed jobs / left company / wrong email | Check `ApproversOrga` table; use "Append Approver" in portal |

### Stage 4: RDSecurityGroupPermission View

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| Approved request not appearing in view | Sync doesn't add user | RequestType is 1 (CP), 4, 5, or 6 — these are excluded from view | Check `PermissionHeader.RequestType`; only 0, 2, 7 appear in view |
| Approved request not appearing in view | Sync doesn't add user | ServiceLine code not found inside any group name | Check `ReportingDeckSecurityGroups.SecurityGroupName` contains the ServiceLine code |
| User appears in view but no group GUID | Sync skips user | `SecurityGroupGUID` is NULL in `ReportingDeckSecurityGroups` | Fix the GUID in `ReportingDeckSecurityGroups` |

### Stage 5: AD Sync

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| User approved but not added to Azure AD group | No `GroupMemberAdded` event in EventLog for user | Sync hasn't run yet / sync script failing | Check EventLog for recent `SakuraADSync.ps1` events; check log files on VM |
| Sync runs but fails with 403 | `GroupMemberNotAdded` / 403 errors in log | Account lacks `Group.ReadWrite.All` permission | Check which account runs the script; verify Graph API permissions |
| User not found in Azure AD | `GroupMemberNotAdded` events for specific users | User's UPN in Sakura DB doesn't match Azure AD UPN | Check `PermissionHeader.RequestedFor` email vs actual Azure AD UPN |
| Sync runs but does "0 operations" | Log shows "Members to Add: 0" | User is already in the group (no action needed) | This is correct behavior — verify the issue is on Power BI side |

### Stage 6: Power BI Access

| Issue | Symptom | Root Cause | Where to Look |
|---|---|---|---|
| User in Azure AD group but still can't see report | User gets access denied in Power BI | Wrong group assigned to Power BI workspace / app | Check which groups have access to that Power BI workspace in Power BI Admin |
| User in correct group but report not loading | Report shows but data is wrong | RLS (Row-Level Security) issue in Power BI report itself | Check Power BI RLS configuration for that report |
| Propagation delay | User was just added to group but Power BI still denies | Azure AD takes time to propagate group changes | Ask user to wait 10-30 minutes, then re-login to Power BI and try again |

---

## 15. Quick Diagnostic Queries

### Check a Specific User's Current Status

```sql
-- Step 1: What requests does this user have?
SELECT RequestId, RequestCode, RequestType, ApprovalStatus, 
       RequestDate, ApprovedDate, ApprovedBy, Approvers
FROM PermissionHeader
WHERE RequestedFor = 'user@dentsu.com'
ORDER BY RequestDate DESC;

-- Step 2: What groups should they be in (desired state)?
SELECT RequestedFor, SecurityGroupName, SecurityGroupGUID, LastChangeDate
FROM RDSecurityGroupPermission
WHERE RequestedFor = 'user@dentsu.com';

-- Step 3: Was the AD sync performed for this user?
SELECT EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventDescription LIKE '%user@dentsu.com%'
ORDER BY EventTimestamp DESC;
```

### Check Email Queue Health

```sql
-- How many emails are stuck unsent?
SELECT COUNT(*) AS UnsentEmails FROM [dbo].[Emails] WHERE Status = 0;

-- Emails with high retry counts (likely broken)
SELECT TOP 20 EmailId, [To], Subject, NumberOfTries, LastTrialDate, StatusText
FROM [dbo].[Emails]
WHERE Status = 0 AND NumberOfTries > 3
ORDER BY LastTrialDate DESC;

-- Recent email activity
SELECT CAST(DateSent AS DATE) AS Date, COUNT(*) AS Sent
FROM [dbo].[Emails] WHERE Status = 1 AND DateSent >= DATEADD(day, -7, GETDATE())
GROUP BY CAST(DateSent AS DATE) ORDER BY Date DESC;
```

### Check Recent Sync Activity

```sql
-- Last 50 sync events
SELECT TOP 50 EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventTriggeredBy = 'SakuraADSync.ps1'
ORDER BY EventTimestamp DESC;

-- Count of adds/removes/failures in last 24 hours
SELECT EventName, COUNT(*) AS EventCount
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventTimestamp >= DATEADD(hour, -24, GETDATE())
GROUP BY EventName;
```

### Check a Specific Request End-to-End

```sql
-- Replace 1234 with actual RequestId
SELECT EL.EventTimestamp, EL.EventName, EL.EventDescription, EL.EventTriggeredBy
FROM EventLog EL
WHERE EL.TableName = 'PermissionHeader' AND EL.RecordId = 1234
ORDER BY EL.EventTimestamp;
```

### Check ApplicationSettings

```sql
-- All current settings
SELECT SettingKey, SettingValue FROM ApplicationSettings;

-- Key settings to check
SELECT SettingKey, SettingValue
FROM ApplicationSettings
WHERE SettingKey IN (
    'EmailingMode',              -- 0=disabled, 1=enabled
    'EnvironmentTag',            -- 'PROD' or 'UAT'
    'CreatePermissionRevokedEmails', -- 0 or 1
    'EmailMaxRetrials',
    'ActiveEmailQueues'
);
```

### Find Which Group a User Should Be In

```sql
-- Look up what RDSecurityGroupPermission entry exists for a user
SELECT 
    PH.RequestedFor, 
    PH.RequestCode, 
    PH.RequestType, 
    PH.ApprovalStatus,
    SL.ServiceLineCode,
    RDSG.SecurityGroupName, 
    RDSG.SecurityGroupGUID
FROM PermissionHeader PH
LEFT JOIN PermissionOrgaDetail OD ON PH.RequestId = OD.RequestId
LEFT JOIN ServiceLine SL ON SL.ServiceLineCode = OD.ServiceLineCode
LEFT JOIN ReportingDeckSecurityGroups RDSG 
    ON PH.ApplicationLoVId = RDSG.ApplicationLoVId
    AND CHARINDEX(SL.ServiceLineCode, RDSG.SecurityGroupName, 1) > 0
WHERE PH.RequestedFor = 'user@dentsu.com'
  AND PH.ApprovalStatus = 1;
```

---

## Summary: The One-Line Version of Every Stage

| Stage | What Happens | Key Technology |
|---|---|---|
| 1. Login | User authenticates via Azure AD SSO | Azure Active Directory |
| 2. Create Request | User fills form; stored procedure creates DB records + queues emails | GAPTEQ Portal + SQL Stored Procedures |
| 3. Email Sent | .NET app reads email queue, sends via SMTP relay | Sakura.Toolbox.EmailDispatcher + SMTP |
| 4. Approve | Approver clicks approve; ApprovalStatus flips to 1 | SQL `ApprovePermissionRequest` stored procedure |
| 5. Desired State | Approved request now appears in `RDSecurityGroupPermission` view | SQL View + ServiceLine/Group name matching |
| 6. AD Sync | PowerShell script reads view, calls Graph API to update group | `SakuraADSync.ps1` + Microsoft Graph API |
| 7. Access Granted | User is now in Azure AD group; Power BI reads membership | Azure AD + Power BI Service |
| 8. Audit | Every action logged immutably in EventLog | SQL `EventLog` table |

---

*This document covers the full Sakura system based on Technical Documentation V.1.2.0, Sakura_Complete_Functional_Architecture, Sakura_Email_System_Complete_Explanation, and operational knowledge from live issue investigations.*

---

## 16. Power BI Access Timing and RLS — What Happens After AD Sync

This section answers two critical questions you will face regularly when supporting users:

### 16.1 Does the user get Power BI access the moment AD sync runs?

**No. There are two more delays after sync completes.**

```
SakuraADSync.ps1 completes
(EventLog shows: GroupMemberAdded)
        │
        ▼  ── DELAY 1 ──────────────────────────────────────────────────
Azure AD propagation delay
Azure AD must replicate the group membership change across its systems.
  ─ Typical: 5–30 minutes
  ─ Worst case: up to a few hours (rare)
        │
        ▼  ── DELAY 2 ──────────────────────────────────────────────────
Power BI session token refresh
Power BI caches the user's group memberships when they log in.
If the user is already logged in, Power BI won't "see" the new group
until their session token refreshes or they log out and back in.
  ─ Fix: ask user to sign out of Power BI and sign back in
        │
        ▼
User can open the report ✅
```

**Practical support response when a user says "I was approved but still can't access the report":**

1. Check EventLog — confirm `GroupMemberAdded` event exists for that user
2. If yes: ask them to wait 15–30 minutes, then sign out and sign back in to Power BI
3. If `GroupMemberAdded` does NOT exist: sync hasn't run or failed — investigate sync

---

### 16.2 Is group membership enough? What about RLS?

**Group membership only controls whether a user can open the report. What data they see inside is controlled separately by Row-Level Security (RLS).**

There are two completely separate layers:

```
LAYER 1 — "Can this user open the report at all?"
─────────────────────────────────────────────────
Controlled by:  Azure AD Security Group membership
Managed by:     SakuraADSync.ps1
Example group:  #SG-UN-SAKURA-EntireOrg  ← gives app-level access

If user is NOT in the group:
→ Power BI shows "You don't have access" or the app won't load
→ Fix: ensure AD sync ran correctly and user is in the right group


LAYER 2 — "What data can this user see inside the report?"
──────────────────────────────────────────────────────────
Controlled by:  Row-Level Security (RLS) rules defined in the report
Managed by:     Power BI reads the Sakura DB directly
Example rule:   "Show only rows where EntityCode = user's approved entity"

If RLS is wrong or missing:
→ User can open the report but sees blank data, or wrong/incomplete data
→ Fix: check the user's approved scope in Sakura DB
```

### 16.3 How Sakura Defines RLS Context

Sakura does not configure RLS rules inside Power BI — those are written into the Power BI report itself. But Sakura provides the **data** that those RLS rules read.

```
User submits Orga request:
  Entity = "DACH"
  ServiceLine = "CXM"
  CostCenter = "CXM Solutions"
        │
        ▼
Stored in:
  PermissionHeader (RequestedFor, ApprovalStatus=1)
  PermissionOrgaDetail (EntityCode, ServiceLineCode, CostCenterCode)
        │
        │ Power BI reads this via DirectQuery or scheduled import
        ▼
RLS rule in Power BI report:
  "For this user, only show data where EntityCode = 'DACH'
   AND ServiceLineCode = 'CXM'"
        │
        ▼
User opens report → sees only DACH + CXM data ✅
```

### 16.4 How to Check RLS Context for a User

Use the **RLS Context page** in the Sakura Power BI monitoring dashboard. It shows:
- Table 1: The user's request details (type, entity, service line, status)
- Table 2: The detailed RLS breakdown (exactly what data scope the user is entitled to)

Or query directly:

```sql
-- Check what scope is stored for a user (drives RLS)
SELECT
    PH.RequestedFor,
    PH.RequestCode,
    PH.ApprovalStatus,
    OD.EntityCode,
    OD.ServiceLineCode,
    OD.CostCenterCode,
    E.EntityDesc,
    SL.ServiceLineDesc
FROM PermissionHeader PH
JOIN PermissionOrgaDetail OD ON PH.RequestId = OD.RequestId
LEFT JOIN Entity E ON E.EntityCode = OD.EntityCode
LEFT JOIN ServiceLine SL ON SL.ServiceLineCode = OD.ServiceLineCode
WHERE PH.RequestedFor = 'user@dentsu.com'
  AND PH.ApprovalStatus = 1;
```

### 16.5 Common RLS-Related Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| Report opens but shows no data | RLS filters out everything — scope mismatch | Check approved Entity/ServiceLine in DB vs what report expects |
| Report shows data for wrong region | Wrong EntityCode on the approved request | Revoke request, re-create with correct scope |
| User sees all data (no filtering) | RLS not configured in Power BI report | Power BI report developer needs to add RLS rules |
| User sees partial data | Multiple approved requests with different scopes | Expected — each approved request adds its scope to the union |

### 16.6 Full End-to-End Timing Reference

| Step | When It Happens |
|---|---|
| User submits request | Immediate |
| Emails queued in DB | Immediate (same DB transaction) |
| Notification emails sent | Within 5 minutes (EmailDispatcher runs every 5 min) |
| Approver approves | Human-dependent (minutes to days) |
| Approval emails sent | Within 5 minutes |
| Request appears in RDSecurityGroupPermission view | Immediate (view is live) |
| AD sync runs and adds user to Azure AD group | Depends on sync schedule (every 5 min or daily) |
| Azure AD propagates the group change | 5–30 minutes (Azure infrastructure) |
| User can access Power BI after re-login | After propagation + user re-login |
| RLS data becomes visible | Same session as report access (no extra delay) |

---

## 17. Sakura Q&A — 300+ Questions and Answers

This section covers every aspect of the Sakura system as a structured question-and-answer reference. Use it to quickly find answers to questions that come up during daily operations, onboarding, or incident investigation.

---

### SECTION A — What Is Sakura and How It Works (General)

**A1. What is Sakura?**
Sakura is a self-service permission management portal for Dentsu. Its primary job is to control who gets access to Power BI reports by managing membership in Azure Active Directory security groups. Users request access, approvers approve, and the system enforces it automatically.

**A2. What problem does Sakura solve?**
Before Sakura, granting Power BI access required manual IT intervention. Sakura automates the full lifecycle: request, approval, enforcement, audit — reducing overhead and improving compliance.

**A3. Is Sakura a database or an application?**
Both. It has a web portal (UI built on GAPTEQ), a SQL Server database (the source of truth), and background automation components (EmailDispatcher, SakuraADSync.ps1).

**A4. Who built Sakura?**
Dentsu's internal team (Onur Ozturk, Shashank Dhakate, Fahmeda Ahmed). The portal UI runs on a licensed Low-Code/No-Code platform called GAPTEQ from a German vendor.

**A5. What technology stack does Sakura use?**
- Portal UI: GAPTEQ (Low-Code, HTML5, .NET, IIS)
- Database: Microsoft SQL Server
- Email: .NET 6.0 Console App (MailKit, RepoDb)
- AD Sync: PowerShell + Microsoft Graph API
- Infrastructure: Azure Virtual Machine, behind Dentsu VPN

**A6. Is Sakura accessible from the internet?**
No. It is hosted on a Virtual Machine on Dentsu Azure Cloud and is only accessible from inside the VPN.

**A7. What does Sakura NOT do?**
- It does not create Azure AD groups (they must already exist)
- It does not create or manage Power BI reports
- It does not directly authenticate users (Azure AD handles that)
- It does not directly modify Azure AD (the sync script does that)
- It does not deliver emails itself (EmailDispatcher does that)

**A8. What is the database server?**
`azeuw1senmastersvrdb01.database.windows.net`, database name: `Sakura`

**A9. What is GAPTEQ?**
A licensed Low-Code/No-Code web application platform from a German company. It allows building web forms and workflows on top of SQL databases using drag-and-drop. The Sakura portal is built on this platform.

**A10. What is the portal URL?**
The portal is accessible internally via the Dentsu VPN. The base URL pattern is `https://azeuw1dsenm01/GAPTEQForms/Sakura/`.

---

### SECTION B — User Roles and Authorization

**B1. How many roles exist in Sakura?**
Three: Administrator, Support Administrator, and Regular User (End User).

**B2. What can a Regular User do?**
Create new permission requests and approve requests assigned to them. They cannot see other users' requests or manage system settings.

**B3. What can a Support Administrator do?**
Everything a regular user can do, plus assist with request management, troubleshoot issues, manage email queue, and create requests on behalf of other users.

**B4. What can an Administrator do?**
Full access. Manage approvers, LoVs, global settings, email templates, all requests, revoke in batch, export to Excel, append approvers to pending requests, view all approvals across all users.

**B5. How does Sakura know which role a logged-in user has?**
Roles are managed in the database and mapped to the user's Azure AD identity. Sakura uses Azure AD for authentication (who you are) and its own database for authorization (what you can do).

**B6. Can a user be both a requester and an approver?**
Yes. If the person requesting access is also listed as an approver for that scope, the request is automatically approved immediately (auto-approval rule).

**B7. Can an approver approve their own request?**
Yes — if they are in the approvers list for their own scope, auto-approval fires during request creation.

**B8. Can admins create requests on behalf of other users?**
Yes. Sakura supports creating requests for up to 10 users at once on their behalf. This is useful for onboarding new team members.

**B9. What is the "Append Approver" feature?**
An admin can add a new approver to a request that is already in "Awaiting Approval" state. This is useful when the original approver is unavailable or has left the company.

**B10. What is approver delegation?**
An approver can delegate their approval authority to another person for a defined time period. This is stored in the `ApproverDelegation` table.

---

### SECTION C — Permission Types

**C1. How many permission types does Sakura support?**
Seven: Orga (0), CP/Client Project (1), CC/Cost Center (2), Reporting Deck (4), SGM/Security Group Manager (5), DSR/Data Subject Request (6), MSS/Master Service Set (7). Plus "Samurai" which is a combined dynamic type.

**C2. What is an Organization (Orga) permission?**
Grants access scoped to an organizational unit — defined by Entity, Service Line, and Cost Center. This is the most common type.

**C3. What is a Client Project (CP) permission?**
Grants access scoped to a specific client and project. Used when access needs to be restricted to client-specific data.

**C4. What is a Cost Center (CC) permission?**
Grants access scoped to a specific cost center and service line. A mid-level permission type.

**C5. What is a Security Group Manager (SGM) permission?**
Grants access based on a specific security group code. Used for centralized group-based access control.

**C6. What is a Master Service Set (MSS) permission?**
Grants access scoped to a Master Service Set. MSS is a collection of services grouped together.

**C7. What is a Samurai permission?**
A dynamic combined permission type where the user goes through a wizard and selects their access requirements on-the-fly. It consolidates Orga, CC, and CP dimensions into one flow.

**C8. Which permission types actually sync to Azure AD groups?**
Only Orga (0), CC (2), and MSS (7). These are the only types that appear in the `RDSecurityGroupPermission` view. CP (1), SGM (5), and Reporting Deck (4) are excluded.

**C9. Why are CP, SGM, and Reporting Deck excluded from the AD sync view?**
To prevent permission set extension — allowing simple client-project requests from inadvertently granting broader organizational access via group membership.

**C10. If a CP request doesn't sync to Azure AD, how does it work?**
CP requests have a different access enforcement mechanism outside the main sync view. The scope is still stored in Sakura for audit and RLS purposes.

---

### SECTION D — The Portal Pages

**D1. What is the "New Request" page?**
The starting point for users to create a new permission request. The user selects permission type, fills in scope details, and submits.

**D2. What is the "My Requests" page?**
Shows all requests created by or for the logged-in user. The user can see status (pending, approved, rejected, revoked) and full history.

**D3. What is the "My Approvals" page?**
Shows all pending requests that the logged-in user is assigned to approve. Supports batch approval.

**D4. What is the "All Approvals" page?**
An admin-only view showing all requests across all users. Used for centralized management of the approval queue.

**D5. What is "Manage Approvers"?**
Admin page to add, edit, or remove approvers for each permission type and organizational scope.

**D6. What is "Manage Global Settings"?**
Admin page to configure system-wide settings stored in the `ApplicationSettings` table (e.g., email mode, environment tag).

**D7. What is "Manage LoVs"?**
Admin page to manage the List of Values — predefined dropdown options used throughout the portal UI.

**D8. What is "Manage Emails"?**
Admin/Support Admin page to view and manage the email queue and configure email templates and notification settings.

**D9. What is "Manage Requests"?**
Admin dashboard showing all authorization requests across all users, with filtering, status tracking, batch revocation, and Excel export.

**D10. What is "Manage Smart Filters"?**
Admin page to configure context-sensitive filtering — e.g., filtering cost center dropdowns based on which service line was previously selected in the request wizard.

**D11. What is "Manage Reporting Decks"?**
Admin page to list and manage reporting decks, their associated service lines, and the Azure AD groups mapped to each deck.

**D12. What is the Help Section?**
Built-in help content inside the portal. Accessible via a help button or menu. Provides guidance on features, workflows, and troubleshooting.

---

### SECTION E — The Database

**E1. What is the most important table in Sakura?**
`PermissionHeader`. It is the central record for every permission request — its status, who requested it, who approved it, when, and all lifecycle transitions.

**E2. What does ApprovalStatus mean in PermissionHeader?**
0 = Pending, 1 = Approved, 2 = Rejected, 3 = Revoked.

**E3. What is PermissionOrgaDetail?**
Stores the organizational scope details (EntityCode, ServiceLineCode, CostCenterCode) for Orga-type requests. One row per Orga request.

**E4. What is RDSecurityGroupPermission?**
A SQL view that aggregates all approved Orga/CC/MSS requests into user-to-group mappings. This is the "desired state" consumed by `SakuraADSync.ps1`. It is the single most critical view in the system.

**E5. What is the ReportingDeckSecurityGroups table?**
Maps reporting decks and applications to Azure AD security group GUIDs. This is the bridge between an approved Sakura request and the actual Azure AD group that gets synced.

**E6. What happens if SecurityGroupGUID is NULL in ReportingDeckSecurityGroups?**
That group will be filtered out of the `RDSecurityGroupPermission` view. The user will never be added to it via sync because there's no GUID to target.

**E7. What is the EventLog table?**
An immutable audit log of every significant event in the system — request creation, approval, rejection, revocation, group membership changes, email queuing. Has 600K+ rows. Never updated or deleted.

**E8. What is the Emails table?**
The email queue. Every email Sakura wants to send is written here first. Status 0 = unsent, Status 1 = sent. The EmailDispatcher reads from this table.

**E9. What is ApplicationSettings?**
A configuration table with key-value pairs that control system behavior at runtime without requiring code changes (e.g., EmailingMode, EnvironmentTag, EmailMaxRetrials).

**E10. What is the LoV table?**
List of Values. Stores predefined options used in dropdowns and enumerations throughout the portal.

**E11. What is the Entity table?**
Stores the organizational hierarchy: Global → Region → Cluster → Market → Entity. ~1,497 rows. Used to scope permissions and find approvers.

**E12. What is the ServiceLine table?**
Stores service line definitions (~21 rows). Critical because Azure AD group names are built around service line codes.

**E13. What is the CostCenter table?**
Stores cost center data (~2,908 rows). Used for CC-type permissions.

**E14. What is the Client table?**
Stores client/customer data (~96,140 rows). Used for CP-type permissions.

**E15. What are history tables?**
Tables in the `history` schema (e.g., `history.PermissionHeader`, `history.ApproversOrga`) that capture every change made to their corresponding main tables. Used for full audit trail and point-in-time queries.

**E16. What are system-versioned tables?**
SQL Server temporal tables (Client, CostCenter, Entity, ServiceLine) that automatically maintain history and allow point-in-time queries. Useful for seeing what data looked like on a specific date.

**E17. What is the PermissionHeaderList view?**
An aggregated view of all permission requests with human-readable descriptions, joining all Permission*Detail tables and reference data. Used by the portal UI and Power BI dashboards.

**E18. What is the SakuraReportforAllEnvironments view?**
A comprehensive reporting view that calculates DaysTakenToApprove, DaysTakenToReject, and TicketLifeInDays for executive dashboards.

**E19. What is the EmailsToSend view?**
A simple view filtering the Emails table to Status = 0 (unsent). This is what the EmailDispatcher queries.

**E20. What is the share schema?**
Contains external reporting views (share.RCOEPermissionTracker, share.SenseiCCPermission, etc.) that provide data to external systems like Power BI or other reporting tools.

---

### SECTION F — Stored Procedures and Functions

**F1. What stored procedure creates an Org permission request?**
`CreateOrgaPermissionRequest`

**F2. What stored procedure approves a request?**
`ApprovePermissionRequest`

**F3. What stored procedure rejects a request?**
`RejectPermissionRequest`

**F4. What stored procedure revokes a request?**
`RevokePermissionRequest`

**F5. What stored procedure finds approvers for a request?**
`FindApprovers` — the dispatcher procedure that routes to `FindOrgaApprovers`, `FindCPApprovers`, `FindMSSApprovers`, etc. depending on request type.

**F6. What does AddToEmailQueue do?**
A high-level procedure called whenever a notification needs to be sent. It calls `FindEmailRecipients` (to determine To/CC/BCC) and then `QueueEmail` (to create the email record in the Emails table).

**F7. What does ConstructEMail do?**
Reads an email template from EmailTemplates table, reads context data from the relevant permission tables, substitutes template variables (like {RequestCode}, {ApprovedBy}) with actual values, and returns the finished email body and subject.

**F8. What does AddToEventLog do?**
Inserts one row into the EventLog table. Called by every significant stored procedure to maintain the audit trail.

**F9. What does CheckEmailApprovalAntiForgery do?**
Validates that an email approval link is legitimate — checks that the approver has proper access to the request and that the link hasn't been forged or tampered with.

**F10. What does FindEmailRecipients do?**
Determines the To/CC/BCC recipients for an email notification. Reads the approvers from `PermissionHeader.Approvers` and checks `EventLog` to avoid sending duplicate notifications.

**F11. What does AppendApproverToPermissionRequest do?**
Adds a new approver to a pending request. Appends to the semicolon-separated `Approvers` column in `PermissionHeader` and sends an email to the new approver.

**F12. What does BatchChangeStatusPermissionRequests do?**
Allows batch approval, rejection, or revocation of multiple requests in one operation.

**F13. What does fnAppSettingValue do?**
A scalar function that retrieves a value from the `ApplicationSettings` table by key. Used throughout the system (e.g., `fnAppSettingValue('EnvironmentTag')` returns 'PROD' or 'UAT').

**F14. What does fnGetCostCenterListWithContextFilter do?**
Returns a filtered list of cost centers based on context (entity and service line). Used in the request wizard to show only relevant cost centers.

**F15. What do fnLoVName, fnLoVValue, fnLoVDesc do?**
Helper functions to retrieve display names and descriptions for List of Values entries. Used in email construction and reporting views.

**F16. What triggers exist on the Approvers tables?**
`TrgApproversOrgaBL` (and similar for CP, MSS, SGM, Reporting Deck). These automatically notify new approvers via email when they are added to an approver rule.

---

### SECTION G — The AD Sync (SakuraADSync.ps1)

**G1. What is SakuraADSync.ps1?**
A PowerShell script that is the enforcement mechanism of Sakura. It reads the desired state from the `RDSecurityGroupPermission` view and synchronizes Azure AD security group membership to match it.

**G2. Where does SakuraADSync.ps1 run?**
On the Azure VM that hosts the Sakura portal, at path `C:\Installations\SakuraADSyncer\SakuraADSync.ps1`.

**G3. How often does SakuraADSync.ps1 run?**
On a schedule (Windows Task Scheduler). Typically every 5 minutes or similar interval.

**G4. What is the only input to SakuraADSync.ps1?**
The `RDSecurityGroupPermission` view. The script queries: `SELECT [RequestedFor],[SecurityGroupName],[SecurityGroupGUID],[LastChangeDate] FROM [dbo].[RDSecurityGroupPermission]`

**G5. What does SakuraADSync.ps1 do with the data it reads?**
It builds a "desired state" of who should be in which group, compares it against the actual current membership in Azure AD (via Graph API), then adds missing members and removes extra members.

**G6. What Microsoft Graph API permission does the sync script need?**
`Group.ReadWrite.All` — this is required to add/remove group members. Without it, the script can connect and read but cannot modify groups, failing with 403 Forbidden.

**G7. Which account currently runs SakuraADSync.ps1?**
`EMEA-MEDIA\OOeztu01`. This account has the required `Group.ReadWrite.All` permission.

**G8. Why does Connect-MgGraph succeed but Update-MgGroup fail for some accounts?**
Connecting to Microsoft Graph (authentication) is allowed for everyone. Modifying group membership requires the specific `Group.ReadWrite.All` permission. Connect = entering the building. Modify = accessing a locked room. They are separate checks.

**G9. How does the script add members to a group?**
Using `Update-MgGroup` with the `members@odata.bind` parameter. Members are added in batches of 20 to reduce API calls.

**G10. How does the script remove members from a group?**
Using `Remove-MgGroupMemberByRef` — one individual API call per user to be removed (not batched).

**G11. What happens if a user's email in Sakura doesn't match their Azure AD UPN?**
The script calls `Get-MgUser` and cannot find the user. It logs a `GroupMemberNotAdded` event and moves on. The user is never added to the group.

**G12. What gets logged to EventLog by the sync script?**
- `GroupMemberAdded` — user successfully added to group
- `GroupMemberRemoved` — user successfully removed from group
- `GroupMemberNotAdded` — user in desired state but not found in Azure AD

**G13. What is TableName set to in sync-related EventLog entries?**
`'RDSecurityGroupPermission'` — even though it's a view, not a table.

**G14. What is RecordId set to in sync-related EventLog entries?**
`-1` — indicating a system-level event not tied to a specific record.

**G15. What email does the script send after completion?**
A summary email to `onur.ozturk@dentsu.com` (hardcoded) with subject `[Sakura AD Sync - TEST]: Success/Failure`, body showing error count and operations count, and the log file attached.

**G16. What log file does the script produce?**
`output_{timestamp}.log` stored on the VM. Each run creates a new file.

**G17. What SMTP settings does the sync script use?**
Server: `internalsmtprelay.media.global.loc`, Port: 25, From: `sakurahelp@dentsu.com`, no authentication, SSL disabled.

**G18. What happens if a group GUID is wrong in ReportingDeckSecurityGroups?**
The `Get-MgGroup` call will fail (group not found). The script logs an error and skips that group. No members are added or removed for it.

**G19. How does the sync handle groups that no longer exist in Azure AD?**
The script tries `Get-MgGroup` — if it fails, it logs the error and continues to the next group without crashing.

**G20. Can running the sync script twice cause problems?**
No. The sync is idempotent — if a user is already in a group, trying to add them again is harmless. Azure AD ignores the duplicate add.

**G21. What is "ConsistencyLevel eventual" in the script?**
A parameter used with `Get-MgGroupMemberAsUser` for performance. It means Azure AD may return slightly stale data (milliseconds to seconds old). Used for efficiency on large groups.

**G22. What causes "Members to Add: 0" in the sync log?**
The desired members from `RDSecurityGroupPermission` are already all present in the Azure AD group. No action needed. This is correct behavior.

**G23. If sync shows success but user still can't access Power BI, what's next?**
1. Check Azure AD propagation delay (wait 15–30 min)
2. Ask user to log out and back in to Power BI
3. Confirm the Power BI workspace has that group assigned to it
4. Check RLS configuration in the Power BI report

---

### SECTION H — The Email System

**H1. How many email systems does Sakura have?**
Two: (1) Sakura.Toolbox.EmailDispatcher for user notifications, (2) SakuraADSync.ps1's own hardcoded admin alert email.

**H2. What is Sakura.Toolbox.EmailDispatcher?**
A C# .NET 6.0 console application that runs every 5 minutes, reads unsent emails from the Emails table, and sends them via the SMTP relay.

**H3. Where does EmailDispatcher run?**
On the same Azure VM as the Sakura portal. Scheduled via Windows Task Scheduler.

**H4. How many emails does EmailDispatcher process per run?**
Top 20, ordered by DateCreated ascending (oldest first).

**H5. How does EmailDispatcher know which emails to send?**
It queries the `[dbo].[EmailsToSend]` view, which filters `Emails` table to Status = 0 (unsent).

**H6. What happens if EmailDispatcher fails to send an email?**
It calls `MarkEmailAsUnsent` — the email stays at Status = 0, `NumberOfTries` increments, `LastTrialDate` is set. It will be retried on the next run.

**H7. What is the `EmailingMode` setting?**
If set to '0' in `ApplicationSettings`, emails are not sent — they are marked as skipped. If '1', emails are sent normally.

**H8. What email library does EmailDispatcher use?**
MailKit 4.8.0.

**H9. What database ORM does EmailDispatcher use?**
RepoDb 1.13.1.

**H10. What emails does a user receive during a normal request lifecycle?**
1. Request created (confirmation to requester)
2. Awaiting approval (to approvers)
3. Request approved (to requester)
4. Request rejected (to requester, with reason)
5. Request revoked (to requester, only if `CreatePermissionRevokedEmails = '1'`)

**H11. Are revocation emails sent by default?**
No. They require `CreatePermissionRevokedEmails = '1'` in `ApplicationSettings`. Default is '0' (disabled).

**H12. What does ConstructEMail do?**
Reads the appropriate email template from `EmailTemplates` table, fetches context data (request details, entity descriptions, etc.), substitutes template variables like `{RequestCode}`, `{ApprovedBy}`, and returns the final HTML email.

**H13. How are multiple email recipients stored?**
Semicolon-separated in the `To`, `CC`, and `BCC` columns of the `Emails` table. EmailDispatcher converts semicolons to commas for the SMTP send.

**H14. What tracking headers are added to sent emails?**
`X-SAKURAGUID` (the email's GUID) and `X-SAKURAEMAILID` (the email's integer ID). Used to match sent events back to the correct Emails row.

**H15. What is DEBUG mode in EmailDispatcher?**
When compiled in DEBUG mode, all emails are overridden to go to `onur.ozturk@dentsu.com` instead of real recipients. Production must always run in RELEASE mode.

**H16. What SMTP server does EmailDispatcher use?**
`internalsmtprelay.media.global.loc`, port 25, no authentication, no SSL.

**H17. How do you check if emails are being sent?**
```sql
SELECT Status, COUNT(*) FROM [dbo].[Emails] GROUP BY Status;
```
Status 0 = unsent queue depth, Status 1 = already sent.

**H18. How do you check for stuck emails?**
```sql
SELECT TOP 20 EmailId, [To], Subject, NumberOfTries, LastTrialDate
FROM [dbo].[Emails] WHERE Status = 0 AND NumberOfTries > 3
ORDER BY LastTrialDate DESC;
```

**H19. What is the `ActiveEmailQueues` setting?**
Controls which email queue names are actively processed. Allows multi-queue support for different application contexts.

**H20. Can an approver receive their notification via email and approve directly from it?**
Yes. The approval email contains a link. When clicked, `CheckEmailApprovalAntiForgery` validates the token before processing the approval.

---

### SECTION I — Reference Data and Data Imports

**I1. Where does Sakura's reference data come from?**
From Sensei — an external source system. Data flows via Azure Data Factory (ADF) pipeline into staging tables, then into production tables via stored procedures.

**I2. What is the ADF pipeline called?**
`P_ALL_SAKURA_D_Automation`

**I3. What reference data is imported from Sensei?**
Client (~96K rows), CostCenter (~2,908 rows), Entity (~1,497 rows), ServiceLine (~21 rows), MasterServiceSet (~260 rows), and LoV (List of Values).

**I4. What are the staging tables?**
`SAKURA_Staging.Client`, `SAKURA_Staging.CostCenter`, `SAKURA_Staging.Entity`, `SAKURA_Staging.ServiceLine`

**I5. What stored procedures load staging to production?**
`sp_Load_Client`, `sp_Load_CostCenter`, `sp_Load_Entity`, `sp_Load_ServiceLine`, `sp_Load_MasterServiceSet`

**I6. What are the four steps in each sp_Load_* procedure?**
1. Initial Insert (new records from staging not yet in production)
2. Resurrection Marking (reappeared records marked as active)
3. Deletion Marking (disappeared records marked as deleted with DeleteDate)
4. Actualization (existing records updated with latest data from staging)

**I7. What happens to existing permission requests if reference data changes?**
Existing requests are unaffected — they retain the data as of when they were created. New requests use the updated reference data.

**I8. What is the CostCenterServiceLineMapping table?**
Maps cost centers to their associated service lines. Used by Smart Filters to show only relevant cost centers when a service line is selected in the request wizard.

**I9. What are system-versioned tables used for in reference data?**
They allow point-in-time queries — you can ask "what did this cost center look like on January 1st?" This is useful for auditing historical data states.

**I10. If a new entity appears in Sensei but not in Sakura, what's the cause?**
The ADF pipeline hasn't run, or the `sp_Load_Entity` procedure hasn't been executed after the staging load. Check the staging tables and the ADF pipeline run history.

---

### SECTION J — Approver Management

**J1. How does Sakura determine who should approve a request?**
Via the `FindApprovers` stored procedure, which routes to type-specific finders (FindOrgaApprovers, FindCPApprovers, etc.). These query the Approvers* tables and match on scope dimensions like EntityCode, ServiceLineCode, and CostCenterCode.

**J2. What if no exact approver match is found?**
Sakura walks up the organizational hierarchy to find an approver at a broader scope (e.g., if no approver for the specific market, it tries the cluster, then region, then global level).

**J3. Can multiple approvers be assigned to the same scope?**
Yes. Multiple approvers can be defined for a single scope intersection. All of them receive the approval notification. Any one of them can approve.

**J4. What table stores Org approvers?**
`ApproversOrga`

**J5. What table stores Client Project approvers?**
`ApproversCP`

**J6. What table stores MSS approvers?**
`ApproversMSS`

**J7. What table stores SGM approvers?**
`ApproversSGM`

**J8. What is approver delegation?**
An approver can assign a delegate to cover their approvals for a time period. Stored in `ApproverDelegation` table with a time window.

**J9. What happens if an approver is deleted from the Approvers table?**
Pending requests they were assigned to remain pending — they still show the old approver email in `PermissionHeader.Approvers`. An admin must use "Append Approver" to add a new approver and unblock the request.

**J10. What triggers fire when a new approver is added?**
`TrgApproversOrgaBL` (and similar for CP, MSS, SGM). They automatically send an email to the new approver notifying them they've been assigned to a scope.

---

### SECTION K — The RDSecurityGroupPermission View (Critical)

**K1. Why is RDSecurityGroupPermission the most critical view?**
It is the only source of truth read by `SakuraADSync.ps1`. If this view is wrong, the sync does the wrong thing. If this view is broken, the sync does nothing. It is the interface between the database and Azure AD.

**K2. What are the filtering conditions in this view?**
1. `ApprovalStatus = 1` (approved only)
2. `RequestType IN (0, 2, 7)` (Orga, CC, MSS only)
3. `SecurityGroupGUID IS NOT NULL`
4. `RequestReason NOT LIKE 'SALES BULK%'`
5. `CHARINDEX(ServiceLineCode, SecurityGroupName) > 0` (group name must contain the service line code)

**K3. What is the ServiceLine matching logic in the view?**
The view joins to ServiceLine and checks if the service line code appears inside the Azure AD group name. For example, a request with ServiceLineCode = 'CXM' will match groups named `#SG-UN-SAKURA-CXM`, `#SG-UN-SAKURA-CXMBU`, `#SG-UN-SAKURA-CXMCL`, etc.

**K4. What is the EntireOrg special case?**
All users with any approved request (ApprovalStatus = 1) are automatically included in the `#SG-UN-SAKURA-EntireOrg` group (GUID: `82d513c7-f33d-4b4c-b577-d8497324c556` in PROD). This gives them app-level Power BI access regardless of their specific scope.

**K5. What is the PROD vs UAT difference in this view?**
The view uses `fnAppSettingValue('EnvironmentTag')`. If 'PROD', it uses production group GUIDs. If not 'PROD', it uses UAT group GUIDs. This allows the same database logic to serve multiple environments.

**K6. What happens if you change a column name in this view?**
`SakuraADSync.ps1` will break immediately because it references specific column names (`RequestedFor`, `SecurityGroupName`, `SecurityGroupGUID`, `LastChangeDate`). Never change this view without simultaneously updating the script.

**K7. What does LastChangeDate in this view represent?**
The maximum of all relevant change dates (request, service line, reporting deck, security group). Used by the sync script to detect changes and optimize processing.

**K8. Why might an approved request not appear in the view?**
- RequestType is not 0, 2, or 7
- No matching entry in ReportingDeckSecurityGroups for that ApplicationLoVId
- SecurityGroupGUID is NULL in ReportingDeckSecurityGroups
- ServiceLine code does not appear inside any group name
- Request reason starts with 'SALES BULK'

**K9. How do you check if a specific user appears in this view?**
```sql
SELECT * FROM RDSecurityGroupPermission WHERE RequestedFor = 'user@dentsu.com';
```

**K10. How many rows does this view typically return?**
It returns one row per approved user per matching Azure AD group. A user with one Orga approval might appear in 3–5 rows (one per matching group for their service line).

---

### SECTION L — Azure AD and Power BI Access

**L1. Does Sakura create Azure AD groups?**
No. Azure AD groups must already exist. Sakura only manages membership within existing groups.

**L2. What is the naming convention for Sakura-related Azure AD groups?**
`#SG-UN-SAKURA-{ServiceLineCode}[optional suffix]`. Examples: `#SG-UN-SAKURA-CXM`, `#SG-UN-SAKURA-CXMBU`, `#SG-UN-SAKURA-EntireOrg`.

**L3. How does Power BI know who can access a report?**
Power BI workspaces and apps are configured with specific Azure AD security groups. Users in those groups can access the reports assigned to the workspace/app.

**L4. Does Sakura directly access Power BI?**
No. Sakura never touches Power BI. The connection is entirely via Azure AD group membership: Sakura manages groups → Power BI reads groups.

**L5. What is RLS (Row-Level Security)?**
A Power BI feature that filters the data a user sees based on rules defined in the report. Sakura provides the scope data (EntityCode, ServiceLineCode, etc.) that Power BI RLS rules use.

**L6. Can a user open a report but see no data?**
Yes. If they are in the correct Azure AD group (can open the report) but the RLS rules filter out all rows for their scope (wrong entity/service line on their request), they will see a blank report.

**L7. Why does a user need to re-login to Power BI after being added to a group?**
Power BI caches group membership in the user's session token. The cached token won't reflect new group membership until it expires or the user logs out and back in.

**L8. How long does Azure AD take to propagate a group membership change?**
Typically 5–30 minutes. In rare cases up to a few hours.

**L9. What is the EntireOrg group for?**
`#SG-UN-SAKURA-EntireOrg` gives users access to the Power BI app itself (app-level access). Without it, users can't even open the application. Every approved user is automatically added to this group.

**L10. If a user has an approved request but cannot access the app at all, what should be checked first?**
Check if they are in the `#SG-UN-SAKURA-EntireOrg` group in Azure AD. If not, AD sync may not have run or may have failed.

**L11. What is ApplicationLoVId in the context of Power BI?**
A foreign key linking a permission request to a specific Power BI application. Different Power BI apps have different ApplicationLoVId values. This determines which groups from `ReportingDeckSecurityGroups` are applicable.

**L12. Can the same user have multiple approved requests for the same app?**
Yes. Each approved request adds its scope to the user's access. The union of all their approved scopes determines their RLS data visibility.

**L13. When a request is revoked, how long until Power BI access is removed?**
The revocation updates the DB immediately. The user disappears from `RDSecurityGroupPermission` immediately. But actual removal from Azure AD waits until the next sync run. Then Azure AD propagation delay applies. Total time: minutes to hours.

**L14. What happens in Power BI when a user is removed from an Azure AD group?**
On their next login (or token refresh), Power BI re-evaluates group membership and denies access to reports that require that group.

---

### SECTION M — Auditing and Troubleshooting

**M1. What is the first thing to check when investigating any Sakura issue?**
The `EventLog` table. It contains an immutable record of every significant event and is the starting point for all investigations.

**M2. How do you find all events for a specific request?**
```sql
SELECT * FROM EventLog WHERE TableName = 'PermissionHeader' AND RecordId = {RequestId}
ORDER BY EventTimestamp;
```

**M3. How do you verify AD sync ran for a specific user?**
```sql
SELECT EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventDescription LIKE '%user@dentsu.com%'
ORDER BY EventTimestamp DESC;
```

**M4. How do you check when the last sync run was?**
```sql
SELECT MAX(EventTimestamp) AS LastSyncEvent
FROM EventLog
WHERE EventTriggeredBy = 'SakuraADSync.ps1';
```

**M5. What does GroupMemberNotAdded mean?**
The sync script tried to add a user to a group but could not find that user in Azure AD (usually UPN mismatch). The user's email in Sakura doesn't match their Azure AD login.

**M6. What does a high NumberOfTries on an email row indicate?**
The EmailDispatcher is repeatedly trying but failing to send that email. Likely causes: SMTP relay down, firewall issue, or the email address is invalid/unreachable.

**M7. How do you check if EmailDispatcher is working?**
```sql
SELECT TOP 10 * FROM [dbo].[Emails] WHERE Status = 1 ORDER BY DateSent DESC;
```
If DateSent values are recent, it's working. If the most recent sent email is old, the dispatcher may have stopped.

**M8. How do you check what the current system configuration is?**
```sql
SELECT SettingKey, SettingValue FROM ApplicationSettings;
```

**M9. How do you tell if a user's request is Orga, CP, CC, or another type?**
```sql
SELECT RequestType FROM PermissionHeader WHERE RequestId = {id};
-- 0=Orga, 1=CP, 2=CC, 4=ReportingDeck, 5=SGM, 6=DSR, 7=MSS
```

**M10. Why might an approved request not appear in RDSecurityGroupPermission?**
The most common reasons: RequestType is not 0, 2, or 7; SecurityGroupGUID is NULL; service line code not in group name; or wrong ApplicationLoVId.

**M11. How do you trace the full lifecycle of a request end-to-end?**
```sql
SELECT EL.*
FROM EventLog EL
WHERE TableName = 'PermissionHeader' AND RecordId = {RequestId}
ORDER BY EventTimestamp;
```
You should see: RequestCreated → Notification-Created (emails) → PermissionRequestApproved → GroupMemberAdded.

**M12. What does the Manage Requests admin page show?**
All authorization requests across all users, with status, history, ability to batch revoke, export to Excel, and append approvers.

**M13. How do you export request data for analysis?**
Via the "Export to Excel" button on the Manage Requests page (Admins only). The system tracks the number of rows exported and who performed the export.

**M14. What are the three types of auditing in Sakura?**
1. History tables (CRUD tracking on main tables)
2. EventLog (application-level event logging)
3. System-versioned tables (point-in-time SQL Server temporal tracking for reference data)

**M15. Can you see who viewed a permission request?**
Yes — if `LogPermissionViewEvent` is called, a `PermissionViewed` event is logged in EventLog. The verbosity of this logging can be adjusted.

**M16. If the EventLog has no GroupMemberAdded event for an approved user, what does that mean?**
AD sync has not yet run since the approval, or the sync ran but the user's group mapping didn't resolve (check `RDSecurityGroupPermission` view for that user).

**M17. How do you check if emails are stuck and resend manually?**
Check `SELECT * FROM [dbo].[Emails] WHERE Status = 0 AND NumberOfTries > 0`. To force a retry, you can reset `NumberOfTries = 0` and `LastTrialDate = NULL` so the dispatcher picks it up again.

**M18. How is export to Excel tracked?**
The system records the number of rows exported and the user who performed the export. This is tracked in EventLog.

**M19. What is the PowerBI Monitoring Dashboard in Sakura?**
A set of Power BI report pages connected to the Sakura database, showing: Overall Ticket Status, RLS Context, Sakura LoV, and Emails to Send. Refreshes 5 times a day.

**M20. What are the Power BI dashboard refresh times?**
7:30 AM, 9:00 AM, 12:00 PM, 4:00 AM, and 6:00 AM (UTC+01:00).

---

### SECTION N — Common Scenarios and How to Handle Them

**N1. A user was approved but cannot access the Power BI report. What do you check?**
1. Confirm approval: `SELECT ApprovalStatus FROM PermissionHeader WHERE RequestedFor = 'user@dentsu.com' AND ApprovalStatus = 1`
2. Confirm desired state: `SELECT * FROM RDSecurityGroupPermission WHERE RequestedFor = 'user@dentsu.com'`
3. Confirm sync ran: check EventLog for GroupMemberAdded for this user
4. If GroupMemberAdded exists: wait 15–30 min, ask user to re-login to Power BI
5. If no GroupMemberAdded: sync hasn't run or failed — check sync logs

**N2. An approver says they never received the approval email. What do you check?**
1. Check `[dbo].[Emails]` for a row with their email in the To column and Status = 1 (sent) or 0 (unsent)
2. If unsent: check EmailDispatcher is running, check SMTP relay, check `EmailingMode` setting
3. If sent: the email was delivered to SMTP relay — check their spam folder or email routing

**N3. A user submitted a request but it doesn't appear on the approver's "My Approvals". Why?**
The approver's email in the `PermissionHeader.Approvers` column may not match their Sakura login email. Or the request was auto-approved and is already at ApprovalStatus = 1.

**N4. Admin wants to unblock a request whose approver has left the company. What to do?**
Use "Append Approver" in the portal (or call `AppendApproverToPermissionRequest`) to add a new approver to the pending request.

**N5. A user is in an Azure AD group but still can't see data in the report. What's happening?**
This is an RLS issue, not an access issue. Check the user's approved scope in `PermissionOrgaDetail` and compare it with what the Power BI RLS rules expect.

**N6. Reference data (entities/cost centers) in the portal is outdated. What's the fix?**
Check the ADF pipeline `P_ALL_SAKURA_D_Automation` — it may not have run recently. Trigger it if needed, then verify `SAKURA_Staging.*` tables have fresh data, then run the relevant `sp_Load_*` procedure.

**N7. The sync script is logging GroupMemberNotAdded for a user. What does that mean?**
The user's email in `PermissionHeader.RequestedFor` doesn't match their actual Azure AD UPN or mail field. Verify the correct email format and update the request if needed.

**N8. An admin revoked a request but the user still has Power BI access. Why?**
Revocation updates the DB immediately (ApprovalStatus = 3, disappears from `RDSecurityGroupPermission`). But the user won't be removed from the Azure AD group until the next sync run. Then there's Azure AD propagation delay. Total time to lose access: minutes to hours.

**N9. A user needs access urgently and the approver is unavailable. What can an admin do?**
1. Approve the request directly via the portal (if admin has override ability)
2. Or append a new approver who is available
3. Or manually add the user to the Azure AD group as a temporary measure (will be preserved as long as their Sakura request is approved)

**N10. Emails are not being sent. How do you diagnose quickly?**
1. `SELECT COUNT(*) FROM [dbo].[Emails] WHERE Status = 0` — check queue depth
2. `SELECT SettingValue FROM ApplicationSettings WHERE SettingKey = 'EmailingMode'` — check if emails are disabled
3. Check Windows Task Scheduler on the VM for the EmailDispatcher task
4. Test SMTP: `Test-NetConnection internalsmtprelay.media.global.loc -Port 25`

**N11. The sync script fails with "Insufficient privileges". What's the cause?**
The account running the script does not have `Group.ReadWrite.All` permission in Azure AD. Must use an account with that permission (like `EMEA-MEDIA\OOeztu01`).

**N12. How do you check which Azure AD groups a user should be in vs. actually is in?**
Desired state (from Sakura): `SELECT * FROM RDSecurityGroupPermission WHERE RequestedFor = 'user@dentsu.com'`
Actual state: Check Azure AD group memberships via Azure Portal or Graph API.

**N13. A new service line was added to Sensei. How does it flow into Sakura?**
Sensei → ADF pipeline → `SAKURA_Staging.ServiceLine` → `sp_Load_ServiceLine` → `SAKURA.ServiceLine`. After that, new permission requests can use the new service line. New Azure AD groups named with that service line code must also be created and added to `ReportingDeckSecurityGroups`.

**N14. Why do some approved users appear in the sync for EntireOrg but not for specific service line groups?**
The specific service line groups only match if the approval is RequestType 0, 2, or 7 AND the service line code appears inside a group name in `ReportingDeckSecurityGroups`. Check both conditions.

**N15. Can two people have the same permission request? What prevents duplicates?**
Duplicate prevention is built into the Create* procedures: if the same user already has a pending or approved request for the same scope + application, a new one is blocked.

---

### SECTION O — Configuration and Settings

**O1. What does the EnvironmentTag setting control?**
Controls whether the system uses PROD or UAT Azure AD group GUIDs. If 'PROD', production groups are used. Any other value uses UAT groups.

**O2. What does EmailingMode control?**
'1' = emails are sent normally. '0' = emails are queued but marked as skipped (not actually sent). Used to disable email notifications temporarily without code changes.

**O3. What does EmailMaxRetrials control?**
The maximum number of times EmailDispatcher will retry a failed email before giving up.

**O4. What does EmailRetryAfterMins control?**
The number of minutes to wait before retrying a failed email send.

**O5. What does CreatePermissionRevokedEmails control?**
'1' = send email to user when their access is revoked. '0' = no email on revocation. Defaults to '0'.

**O6. What does SendAddedAsNewApproverEmails control?**
Controls whether the approver trigger fires an email notification when a new approver is added to an approver rule.

**O7. What does ActiveEmailQueues control?**
Defines which email queue names are actively processed by EmailDispatcher. Allows routing different types of emails through different queues.

**O8. How do you disable all email sending immediately?**
```sql
UPDATE ApplicationSettings SET SettingValue = '0' WHERE SettingKey = 'EmailingMode';
```

**O9. How do you switch from UAT to PROD groups?**
```sql
UPDATE ApplicationSettings SET SettingValue = 'PROD' WHERE SettingKey = 'EnvironmentTag';
```

**O10. What is the difference between PROD and UAT group GUIDs?**
PROD: `#SG-UN-SAKURA-EntireOrg` GUID = `82d513c7-f33d-4b4c-b577-d8497324c556`
UAT: `#SG-UN-SAKURA-EntireOrg-UAT` GUID = `f2839f12-dc4e-44e1-9cc3-eb96afb01063`

---

### SECTION P — System Health and Monitoring

**P1. How do you check if the system is healthy overall?**
1. Recent emails sent: `SELECT TOP 5 * FROM Emails WHERE Status=1 ORDER BY DateSent DESC`
2. Recent sync events: `SELECT TOP 5 * FROM EventLog WHERE EventTriggeredBy='SakuraADSync.ps1' ORDER BY EventTimestamp DESC`
3. Pending requests: `SELECT COUNT(*) FROM PermissionHeader WHERE ApprovalStatus=0`
4. Unsent emails: `SELECT COUNT(*) FROM Emails WHERE Status=0`

**P2. What is a healthy vs. unhealthy unsent email count?**
A small number (0–20) is normal — these are emails waiting for the next 5-minute EmailDispatcher run. A count in the hundreds with old `LastTrialDate` values indicates the dispatcher has stopped or SMTP is broken.

**P3. How do you verify the sync script last ran successfully?**
```sql
SELECT MAX(EventTimestamp) AS LastSync, COUNT(*) AS EventsInLast24h
FROM EventLog
WHERE EventTriggeredBy = 'SakuraADSync.ps1'
  AND EventTimestamp >= DATEADD(hour, -24, GETDATE());
```

**P4. How do you see all requests awaiting approval?**
```sql
SELECT RequestId, RequestCode, RequestedFor, RequestDate, Approvers
FROM PermissionHeader WHERE ApprovalStatus = 0
ORDER BY RequestDate;
```

**P5. How do you identify requests pending for a very long time?**
```sql
SELECT RequestId, RequestCode, RequestedFor, RequestDate, 
       DATEDIFF(day, RequestDate, GETDATE()) AS DaysPending
FROM PermissionHeader WHERE ApprovalStatus = 0
ORDER BY RequestDate;
```

**P6. What is the Power BI Monitoring dashboard used for?**
Admins use it to track request volumes, approval rates, RLS context for users, email queue status, and LoV definitions. It refreshes 5 times daily.

**P7. How do you know how many users currently have active access?**
```sql
SELECT COUNT(DISTINCT RequestedFor) AS UsersWithActiveAccess
FROM PermissionHeader WHERE ApprovalStatus = 1;
```

**P8. How do you see the breakdown of requests by type?**
```sql
SELECT RequestType, ApprovalStatus, COUNT(*) AS Total
FROM PermissionHeader
GROUP BY RequestType, ApprovalStatus
ORDER BY RequestType, ApprovalStatus;
```

**P9. How do you check which groups exist in the desired sync state?**
```sql
SELECT DISTINCT SecurityGroupName, SecurityGroupGUID, COUNT(*) AS MemberCount
FROM RDSecurityGroupPermission
GROUP BY SecurityGroupName, SecurityGroupGUID
ORDER BY SecurityGroupName;
```

**P10. How do you measure approval turnaround time?**
```sql
SELECT AVG(DATEDIFF(hour, RequestDate, ApprovedDate)) AS AvgHoursToApprove
FROM PermissionHeader WHERE ApprovalStatus = 1 AND ApprovedDate IS NOT NULL;
```

---

### SECTION Q — Edge Cases and Advanced Topics

**Q1. What happens if a user's cost center changes?**
The existing Sakura request is not automatically updated — it retains the old cost center. The old access may no longer be appropriate. An admin should revoke the old request and the user should submit a new one with the updated cost center.

**Q2. What happens if a service line is renamed in Sensei?**
The new name flows into Sakura via the ADF pipeline. If the service line code changes, the CHARINDEX matching in `RDSecurityGroupPermission` may no longer match the Azure AD group names — users could be removed from groups on the next sync. This is a critical change that requires coordination.

**Q3. Can an approver reject part of a request?**
No. Approval and rejection operate on the whole `PermissionHeader` record. A request is either approved (all its scope) or rejected. If a different scope is needed, the original must be rejected and a new request created.

**Q4. What is a RequestBatchCode?**
A code (e.g., "BPR0000123") that groups related permission requests together — for example, when an admin creates requests for 10 users at once. All 10 PermissionHeader rows share the same `RequestBatchCode`.

**Q5. What is RequestCode?**
A human-readable unique identifier for each permission request (e.g., "SPR0001234"). Used in email subjects and for support reference.

**Q6. What is the difference between RequestedFor and RequestedBy?**
`RequestedFor` is the user who will actually get the access. `RequestedBy` is the user who submitted the form. They are the same person when a user self-requests, but different when an admin or support user requests on behalf of someone else.

**Q7. What happens if a user in Sakura DB has a different email format than Azure AD?**
The sync script's `Get-MgUser` lookup will fail, logging `GroupMemberNotAdded`. The user will never be added to Azure AD groups until the email is corrected. This is a common issue for external users (e.g., @merkle.com).

**Q8. Why might a user at @merkle.com have a different UPN in Azure AD?**
External/partner users may have a different UPN format in Dentsu's Azure AD (e.g., `user_merkle.com#EXT#@dentsu.onmicrosoft.com`). The sync script tries both `userPrincipalName` and `mail` fields, but if neither matches, the lookup fails.

**Q9. Can a request be approved by email without logging into the portal?**
Yes. The approval email contains a link. When clicked, Sakura validates the token via `CheckEmailApprovalAntiForgery` and processes the approval without the approver needing to log in.

**Q10. What is batch revocation?**
Admins can select multiple requests and revoke them all at once via `BatchChangeStatusPermissionRequests`. Useful when cleaning up access for users who have left or changed roles.

**Q11. What does the "SALES BULK" exclusion in RDSecurityGroupPermission do?**
Requests with a reason starting with 'SALES BULK' are excluded from the sync view. This is a business rule to prevent bulk sales data imports from inadvertently triggering group membership changes.

**Q12. Is there retry logic in the AD sync script?**
No. The current implementation does not have automatic retry on throttling or transient errors. If an API call fails, the error is logged and the script continues to the next group. If throttled by Graph API, that group may be skipped until the next run.

**Q13. What is the Graph API throttle limit?**
The default is 10,000 requests per 10 minutes per app. The sync script batches add operations (20 users per call) but does not batch removals. For large sync jobs, throttling may be a concern.

**Q14. Can the sync be forced to run immediately without waiting for the schedule?**
Yes — run `SakuraADSync.ps1` manually on the VM. Must be run as an account with `Group.ReadWrite.All` permission.

**Q15. What is the share schema and who uses it?**
The `share` schema contains views that expose Sakura data to external systems — likely other Power BI reports or reporting tools outside Sakura itself. Examples: `share.SenseiCCPermission`, `share.RCOEPermissionTracker`.

**Q16. What is fnFindOrgaApproversExact?**
A SQL function that performs the exact matching logic for finding Org approvers against the `ApproversOrga` table. It matches on EntityLevel, EntityCode, ServiceLineCode, CostCenterLevel, and CostCenterCode combinations.

**Q17. What happens to history tables when a record is updated?**
Triggers on the main tables automatically insert the old row into the corresponding `history.*` table before the update. This creates a complete audit of every version of every record.

**Q18. How does the portal handle sessions?**
GAPTEQ uses IIS-based session management. Sessions are tied to the Azure AD token. The portal is not exposed to the public internet — only accessible via VPN.

**Q19. Can two environments (PROD/UAT) share the same database?**
Yes — the `EnvironmentTag` application setting controls which Azure AD group GUIDs are used. The same database schema serves both environments with different configuration values.

**Q20. What does the reporting deck concept mean?**
A reporting deck is a logical grouping of Power BI reports. Users select service lines, and the system shows them only the reporting decks relevant to their selection. Each reporting deck is mapped to one or more Azure AD groups in `ReportingDeckSecurityGroups`.
