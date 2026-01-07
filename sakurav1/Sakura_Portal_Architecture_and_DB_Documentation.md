# Sakura Portal: Architecture and Database Documentation

**Document Version:** 1.0
**Generated:** 2025-01-XX
**Database:** Sakura (azeuw1tsenmastersvrdb01)
**Purpose:** Production-grade documentation for onboarding, audits, incident response, and future redesign

- - -

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Context](#system-context)
3. [Architecture Diagrams](#architecture-diagrams)
4. [Core Domain Model](#core-domain-model)
5. [DB Logic Layer](#db-logic-layer)
6. [Authorization Model](#authorization-model)
7. [Audit Trail Model](#audit-trail-model)
8. [External Integrations](#external-integrations)
9. [Operational Runbook](#operational-runbook)
10. [Security & Compliance Review](#security--compliance-review)
11. [Change Impact & Safe Migration](#change-impact--safe-migration)

- - -

## Executive Summary

**Sakura Portal** is a self-service authorization management system for PowerBI reports. The portal enables users to request access to PowerBI resources, which are then granted through Azure AD Security Groups. Authorization is enforced via Azure AD group membership, with Sakura maintaining the desired state in SQL Server.

### Key Characteristics

* **Authorization Model:** Azure AD Security Groups mapped to PowerBI reports
* **State Management:** Desired group membership state stored in SQL (not in AspNet tables)
* **Synchronization:** Scheduled PowerShell script (`SakuraADSync.ps1`) syncs SQL desired state to Azure AD via Microsoft Graph
* **Audit Trail:** Comprehensive event logging in `EventLog` table (600K+ records)
* **Request Types:** Supports multiple permission types (Orga, CP, MSS, Reporting Deck, SGM, CC, DSR)
* **Approval Workflow:** Multi-level approver system with delegation support

### Critical Exclusions

**AspNet* objects (AspNetUsers, AspNetRoles, AspNetUserRoles, etc.) are explicitly excluded from this documentation and are NOT part of the Sakura authorization model.*\* These tables are managed separately by the ASP.NET Identity framework and are not used for PowerBI authorization decisions.

- - -

## System Context

### High-Level Architecture

Sakura operates as a middleware layer between:

* **Users/Requesters** → Portal UI → **Sakura SQL Database**
* **Sakura SQL Database** → **SakuraADSync.ps1** → **Microsoft Graph API** → **Azure AD**
* **Azure AD Security Groups** → **PowerBI** (enforces access)

### System Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                    Sakura Portal (Web UI)                    │
│  - Request creation/management                                │
│  - Approval workflows                                         │
│  - Reporting/audit views                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Sakura SQL Database (State Store)                │
│  - PermissionHeader (requests)                               │
│  - Permission*Detail (request details)                       │
│  - RDSecurityGroupPermission (VIEW - desired state)          │
│  - EventLog (audit trail)                                     │
│  - Approvers* (approval rules)                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         SakuraADSync.ps1 (Scheduled Integration)              │
│  - Reads RDSecurityGroupPermission view                      │
│  - Syncs to Azure AD via Microsoft Graph                     │
│  - Logs actions to EventLog                                  │
│  - Sends email notifications                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Microsoft Graph / Azure AD                       │
│  - Security Groups (GUID-based)                              │
│  - Group membership management                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    PowerBI Service                           │
│  - Report access enforcement via AD groups                   │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Summary

1. **Request Creation:** User creates permission request → `PermissionHeader` + `Permission*Detail` inserted
2. **Approval:** Approver approves → `PermissionHeader.ApprovalStatus` = 1
3. **Desired State:** Approved requests appear in `RDSecurityGroupPermission` view
4. **Sync:** `SakuraADSync.ps1` reads view, compares with Azure AD, adds/removes members
5. **Audit:** All sync actions logged to `EventLog` table
6. **Notification:** Email sent with sync results

- - -

## Architecture Diagrams

### Diagram 1: System Context Diagram

``` mermaid
graph TB
    subgraph "User Layer"
        U[Users/Requesters]
        A[Approvers]
    end

    subgraph "Sakura Portal"
        UI[Web UI]
        API[Application API]
    end

    subgraph "Sakura Database"
        DB[(Sakura SQL DB)]
        PH[PermissionHeader]
        PD[Permission*Detail]
        RDSG[RDSecurityGroupPermission VIEW]
        EL[EventLog]
    end

    subgraph "Integration Layer"
        PS[SakuraADSync.ps1]
    end

    subgraph "Microsoft Cloud"
        MG[Microsoft Graph API]
        AAD[Azure AD Security Groups]
    end

    subgraph "Reporting"
        PBI[PowerBI Reports]
        SMTP[SMTP Server]
    end

    U -->|Create Requests| UI
    A -->|Approve/Reject| UI
    UI -->|Read/Write| API
    API -->|Read/Write| DB
    DB -->|Contains| PH
    DB -->|Contains| PD
    DB -->|Contains| RDSG
    DB -->|Contains| EL

    PS -->|Reads| RDSG
    PS -->|Writes| EL
    PS -->|Calls| MG
    MG -->|Manages| AAD
    AAD -->|Enforces Access| PBI
    PS -->|Sends| SMTP

    style DB fill:#e1f5ff
    style RDSG fill:#fff4e1
    style EL fill:#ffe1f5
    style PS fill:#e1ffe1
```

### Diagram 2: Data Flow - Membership Request to Sync

``` mermaid
sequenceDiagram
    participant U as User
    participant UI as Portal UI
    participant DB as Sakura DB
    participant PS as SakuraADSync.ps1
    participant MG as Microsoft Graph
    participant AD as Azure AD
    participant PBI as PowerBI

    U->>UI: Create Permission Request
    UI->>DB: INSERT PermissionHeader + Detail
    DB->>DB: ApprovalStatus = 0 (Pending)

    Note over DB: Approver reviews and approves
    DB->>DB: UPDATE ApprovalStatus = 1 (Approved)

    Note over DB: RDSecurityGroupPermission VIEW<br/>aggregates approved requests

    PS->>DB: SELECT FROM RDSecurityGroupPermission
    DB-->>PS: Returns desired state (User, GroupGUID, GroupName)

    PS->>MG: Get-MgGroup (by GUID)
    MG-->>PS: Current AD group members

    PS->>PS: Compare desired vs actual

    alt Members to Add
        PS->>MG: Update-MgGroup (batch add)
        MG->>AD: Add members to group
        PS->>DB: INSERT EventLog (GroupMemberAdded)
    end

    alt Members to Remove
        PS->>MG: Remove-MgGroupMemberByRef
        MG->>AD: Remove members from group
        PS->>DB: INSERT EventLog (GroupMemberRemoved)
    end

    AD->>PBI: Group membership change
    PBI->>U: Access granted/revoked
```

### Diagram 3: Core Entity Relationship Diagram (Excluding AspNet\*)

``` mermaid
erDiagram
    PermissionHeader ||--o{ PermissionOrgaDetail : "has"
    PermissionHeader ||--o{ PermissionCPDetail : "has"
    PermissionHeader ||--o{ PermissionMSSDetail : "has"
    PermissionHeader ||--o{ PermissionSGMDetail : "has"
    PermissionHeader ||--o{ PermissionReportingDeckDetail : "has"
    PermissionHeader ||--o{ EventLog : "logged_in"

    PermissionOrgaDetail }o--|| Entity : "references"
    PermissionOrgaDetail }o--|| ServiceLine : "references"
    PermissionOrgaDetail }o--|| CostCenter : "references"

    PermissionCPDetail }o--|| Entity : "references"
    PermissionCPDetail }o--|| ServiceLine : "references"
    PermissionCPDetail }o--|| Client : "references"

    PermissionMSSDetail }o--|| Entity : "references"
    PermissionMSSDetail }o--|| MasterServiceSet : "references"

    ReportingDeckSecurityGroups }o--|| ReportingDeck : "belongs_to"
    ReportingDeckSecurityGroups }o--|| LoV : "application"

    PermissionHeader }o--|| LoV : "application"
    PermissionHeader }o--|| LoV : "request_type"
    PermissionHeader }o--|| LoV : "approval_status"

    ApproversOrga }o--|| Entity : "scoped_to"
    ApproversOrga }o--|| ServiceLine : "scoped_to"
    ApproversCP }o--|| Entity : "scoped_to"
    ApproversCP }o--|| ServiceLine : "scoped_to"
    ApproversMSS }o--|| Entity : "scoped_to"

    RDSecurityGroupPermission ||--o{ PermissionHeader : "derived_from"
    RDSecurityGroupPermission ||--o{ PermissionOrgaDetail : "derived_from"
    RDSecurityGroupPermission ||--o{ ReportingDeckSecurityGroups : "derived_from"
    RDSecurityGroupPermission ||--o{ ServiceLine : "derived_from"

    Emails ||--o| EmailTemplates : "uses"

    PermissionHeader {
        int RequestId PK
        nvarchar RequestCode
        nvarchar RequestedFor
        nvarchar RequestedBy
        nvarchar ApprovalStatus
        nvarchar RequestType
        int ApplicationLoVId FK
    }

    PermissionOrgaDetail {
        int RequestId PK_FK
        nvarchar EntityCode
        nvarchar ServiceLineCode
        nvarchar CostCenterCode
    }

    EventLog {
        bigint EventLogId PK
        nvarchar TableName
        int RecordId
        smalldatetime EventTimestamp
        nvarchar EventName
        nvarchar EventDescription
        nvarchar EventTriggeredBy
    }

    RDSecurityGroupPermission {
        nvarchar RequestedFor
        nvarchar SecurityGroupName
        nvarchar SecurityGroupGUID
        smalldatetime LastChangeDate
    }
```

### Diagram 4: Module Dependency Graph (Top 15 Most Connected)

``` mermaid
graph TD
    PH[PermissionHeader<br/>Table]
    EL[EventLog<br/>Table]
    AEL[AddToEventLog<br/>SP]
    AER[AddToEmailQueue<br/>SP]
    QE[QueueEmail<br/>SP]
    CE[ConstructEMail<br/>SP]
    APR[ApprovePermissionRequest<br/>SP]
    RPR[RejectPermissionRequest<br/>SP]
    VPR[RevokePermissionRequest<br/>SP]
    CCPR[CreateCPPermissionRequest<br/>SP]
    COPR[CreateOrgaPermissionRequest<br/>SP]
    CMSSPR[CreateMSSPermissionRequest<br/>SP]
    CSGMPR[CreateSGMPermissionRequest<br/>SP]
    FAE[FindApprovers<br/>SP]
    FER[FindEmailRecipients<br/>SP]

    PH -->|read/write| APR
    PH -->|read/write| RPR
    PH -->|read/write| VPR
    PH -->|read/write| CCPR
    PH -->|read/write| COPR
    PH -->|read/write| CMSSPR
    PH -->|read/write| CSGMPR
    PH -->|read| FER

    APR -->|calls| AEL
    APR -->|calls| AER
    RPR -->|calls| AEL
    RPR -->|calls| AER
    VPR -->|calls| AEL
    VPR -->|calls| AER

    CCPR -->|calls| APR
    CCPR -->|calls| AEL
    CCPR -->|calls| AER
    COPR -->|calls| APR
    COPR -->|calls| AEL
    COPR -->|calls| AER
    CMSSPR -->|calls| APR
    CMSSPR -->|calls| AEL
    CMSSPR -->|calls| AER
    CSGMPR -->|calls| APR
    CSGMPR -->|calls| AEL
    CSGMPR -->|calls| AER

    AER -->|calls| QE
    AER -->|calls| FER
    QE -->|calls| CE
    QE -->|calls| AEL

    AEL -->|writes| EL
    FER -->|reads| EL
    FER -->|reads| PH

    style PH fill:#ffcccc
    style EL fill:#ccffcc
    style AEL fill:#ccccff
    style AER fill:#ffffcc
```

### Diagram 5: Table Impact Graph (Top 15 Most Referenced Tables)

``` mermaid
graph LR
    PH[PermissionHeader<br/>2280 rows<br/>HIGH IMPACT]
    POD[PermissionOrgaDetail<br/>2074 rows]
    PCD[PermissionCPDetail<br/>109 rows]
    PMSSD[PermissionMSSDetail<br/>20 rows]
    EL[EventLog<br/>600K+ rows]
    E[Entity<br/>1497 rows]
    SL[ServiceLine<br/>21 rows]
    CC[CostCenter<br/>2908 rows]
    C[Client<br/>96K+ rows]
    RD[ReportingDeck<br/>24 rows]
    RDSG[ReportingDeckSecurityGroups<br/>85 rows]
    AORG[ApproversOrga<br/>449 rows]
    ACP[ApproversCP<br/>33 rows]
    AMSS[ApproversMSS<br/>8 rows]
    LOV[LoV<br/>23 rows]

    PH -->|FK| POD
    PH -->|FK| PCD
    PH -->|FK| PMSSD
    PH -->|referenced_by| EL
    PH -->|used_in| RDSG

    POD -->|references| E
    POD -->|references| SL
    POD -->|references| CC
    POD -->|used_in| RDSG

    PCD -->|references| E
    PCD -->|references| SL
    PCD -->|references| C

    PMSSD -->|references| E

    RDSG -->|references| RD
    RDSG -->|references| LOV

    AORG -->|scopes| E
    AORG -->|scopes| SL
    ACP -->|scopes| E
    ACP -->|scopes| SL
    AMSS -->|scopes| E

    style PH fill:#ff9999
    style EL fill:#99ff99
    style POD fill:#9999ff
    style RDSG fill:#ffcc99
```

- - -

## Core Domain Model

### Core Tables Overview

The Sakura database centers around **permission requests** and their **approval lifecycle**. The core domain consists of:

1. **PermissionHeader** \- Request lifecycle and metadata
2. **Permission\*Detail** tables - Request-specific details (Orga, CP, MSS, SGM, Reporting Deck)
3. **RDSecurityGroupPermission** (VIEW) - Aggregated desired state for AD sync
4. **EventLog** \- Immutable audit trail
5. **Approvers**\* tables - Approval rules and delegation
6. **Reference Data** \- Entity\, ServiceLine\, CostCenter\, Client\, MasterServiceSet\, ReportingDeck

### PermissionHeader

**Purpose:** Central table for all permission requests. Tracks request lifecycle from creation through approval/rejection/revocation.

**Key Columns:**

* `RequestId` (PK, int, identity) - Unique request identifier
* `RequestCode` (nvarchar(40)) - Human-readable code (e.g., "SPR0000001")
* `RequestBatchCode` (nvarchar(40)) - Groups related requests
* `RequestedFor` (nvarchar(510)) - User email/UPN requesting access
* `RequestedBy` (nvarchar(510)) - User email/UPN who created the request
* `RequestReason` (nvarchar(2048)) - Business justification
* `RequestType` (nvarchar(100)) - Type: '0'=Orga, '1'=CP, '2'=CC, '4'=Reporting Deck, '5'=SGM, '6'=DSR, '7'=MSS
* `ApplicationLoVId` (int) - FK to LoV table (PowerBI application identifier)
* `ApprovalStatus` (nvarchar(100)) - '0'=Pending, '1'=Approved, '2'=Rejected, '3'=Revoked
* `Approvers` (nvarchar(4096)) - Comma-separated list of approver emails
* `ApprovedBy`, `ApprovedDate` \- Approval metadata
* `RejectedBy`, `RejectedDate`, `RejectReason` \- Rejection metadata
* `LastChangedBy`, `LastChangeDate` \- Audit fields

**Relationships:**

* One-to-many with `PermissionOrgaDetail`, `PermissionCPDetail`, `PermissionMSSDetail`, `PermissionSGMDetail`, `PermissionReportingDeckDetail`
* Referenced by `EventLog` (via `TableName='PermissionHeader'`, `RecordId=RequestId`)

**Typical Reads/Writes:**

* **Reads:** High-frequency reads by UI for listing requests, approval workflows, reporting
* **Writes:** Inserts on request creation, updates on approval/rejection/revocation, status changes

**Indexes:**

* Primary key on `RequestId` (clustered)
* Consider indexes on: `RequestedFor`, `ApprovalStatus`, `RequestType`, `ApplicationLoVId`, `RequestDate`

**Retention Considerations:**

* Historical data preserved in `history.PermissionHeader` via triggers
* No automatic purging observed; consider retention policy for audit compliance

### PermissionOrgaDetail

**Purpose:** Stores organizational-level permission details (Entity, ServiceLine, CostCenter scoping).

**Key Columns:**

* `RequestId` (PK/FK to PermissionHeader)
* `EntityLevel` (nvarchar(100)) - 'Global', 'Region', 'Cluster', 'Market', 'Entity', 'N'
* `EntityCode` (nvarchar(100)) - Entity key/code
* `ServiceLineCode` (nvarchar(100)) - ServiceLine key
* `AccountCode`, `ProfitCenterCode` \- Additional scoping
* `CostCenterLevel` (nvarchar(100)) - 'N', 'Single Cost Center', 'BPC Rollup', 'Business Unit'
* `CostCenterCode` (nvarchar(100)) - CostCenter key

**Relationships:**

* Foreign key to `PermissionHeader.RequestId`
* References `Entity`, `ServiceLine`, `CostCenter` (via code matching, not explicit FKs)

**Typical Reads/Writes:**

* **Reads:** Used by `RDSecurityGroupPermission` view to determine group membership
* **Writes:** Inserted when Orga/CC permission requests are created

**Indexes:**

* Primary key on `RequestId` (clustered)
* Consider indexes on: `EntityCode`, `ServiceLineCode`, `CostCenterCode` for join performance

### RDSecurityGroupPermission (VIEW)

**Purpose:** **Critical view** that aggregates approved permission requests into desired Azure AD group membership state. This is the **sole source of truth** read by `SakuraADSync.ps1`.

**Definition Logic:**

``` sql
-- Simplified representation of view logic
SELECT 
    H.RequestedFor,
    g.SecurityGroupName,
    G.SecurityGroupGUID,
    MAX(GREATEST(H.LastChangeDate, t.LastChangeDate, rd.LastChangeDate, g.[LastChangeDate])) AS LastChangeDate
FROM PermissionHeader H
LEFT JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
OUTER APPLY (SELECT ServiceLineCode, LastChangeDate FROM ServiceLine WHERE SakuraPath LIKE '%|' + D.ServiceLineCode + '|%') t
LEFT JOIN ReportingDeckSecurityGroups g ON H.ApplicationLoVId = g.ApplicationLoVId
LEFT JOIN ReportingDeck RD ON g.ReportingDeckId = RD.ReportingDeckId
WHERE CHARINDEX(t.ServiceLineCode, SecurityGroupName, 1) > 0
  AND H.RequestType IN (0, 2, 7)  -- Only Orga, CC, MSS
  AND H.ApprovalStatus = 1  -- Approved only
  AND G.SecurityGroupGUID IS NOT NULL
  AND H.RequestReason NOT LIKE 'SALES BULK%'
GROUP BY H.RequestedFor, g.SecurityGroupName, G.SecurityGroupGUID
```

**Key Columns:**

* `RequestedFor` (nvarchar(510)) - User email/UPN
* `SecurityGroupName` (nvarchar(510)) - Azure AD group display name
* `SecurityGroupGUID` (nvarchar(510)) - Azure AD group object ID (GUID)
* `LastChangeDate` (smalldatetime) - Most recent change timestamp

**Relationships:**

* Derived from: `PermissionHeader`, `PermissionOrgaDetail`, `ReportingDeckSecurityGroups`, `ServiceLine`, `ReportingDeck`
* Uses `fnAppSettingValue('EnvironmentTag')` for environment-specific group mappings

**Typical Reads/Writes:**

* **Reads:** <b>Only read by `SakuraADSync.ps1`</b> \- full table scan on each sync run
* **Writes:** View is read-only; changes via underlying tables

**Indexes:**

* No direct indexes (view); optimize underlying tables:
    * `PermissionHeader`: `ApprovalStatus`, `RequestType`, `ApplicationLoVId`
    * `PermissionOrgaDetail`: `ServiceLineCode`
    * `ReportingDeckSecurityGroups`: `ApplicationLoVId`, `SecurityGroupGUID`

**Critical Notes:**

* **This view is the interface contract** between Sakura DB and the sync script
* Any changes to view definition require coordination with `SakuraADSync.ps1`
* View filters to only Orga/CC/MSS request types (excludes CP, SGM, Reporting Deck direct requests)
* Includes special case: adds all approved users to "EntireOrg" group for app access

### EventLog

**Purpose:** Immutable audit trail of all significant events in the system. Used for compliance, troubleshooting, and audit reporting.

**Key Columns:**

* `EventLogId` (PK, bigint, identity) - Unique event identifier
* `TableName` (nvarchar(100)) - Source table (e.g., 'PermissionHeader', 'RDSecurityGroupPermission')
* `RecordId` (int) - Related record ID (e.g., RequestId, or -1 for system events)
* `EventTimestamp` (smalldatetime) - When event occurred
* `EventName` (nvarchar(100)) - Event type (e.g., 'GroupMemberAdded', 'GroupMemberRemoved', 'PermissionRequestApproved')
* `EventDescription` (nvarchar(2048)) - Detailed description
* `EventTriggeredBy` (nvarchar(510)) - Actor (e.g., 'SakuraADSync.ps1', user email, stored procedure name)

**Relationships:**

* Referenced by `FindEmailRecipients` stored procedure for notification logic
* Written by: `AddToEventLog`, `SakuraADSync.ps1` (via `Insert-EventLog` function)

**Typical Reads/Writes:**

* **Reads:** Audit queries, email notification logic, reporting
* **Writes:** High-frequency inserts (600K+ records observed)

**Indexes:**

* Primary key on `EventLogId` (clustered)
* **Critical indexes needed:**
    * `EventTimestamp` (for time-range queries)
    * `TableName`, `RecordId` (for record-specific audit trails)
    * `EventName` (for event type filtering)
    * `EventTriggeredBy` (for actor-based queries)

**Retention Considerations:**

* **No automatic purging observed** \- consider retention policy
* Large table size (600K+ rows) may impact query performance
* Consider partitioning by `EventTimestamp` for long-term retention

**Event Types Logged by SakuraADSync.ps1:**

* `GroupMemberAdded` \- User successfully added to Azure AD group
* `GroupMemberRemoved` \- User successfully removed from Azure AD group
* `GroupMemberNotAdded` \- User not found in Azure AD \(cannot add\)

### ReportingDeckSecurityGroups

**Purpose:** Maps Reporting Decks (PowerBI report collections) to Azure AD Security Groups.

**Key Columns:**

* `ReportingDeckSecurityGroupsId` (PK, int, identity)
* `ReportingDeckId` (int) - FK to ReportingDeck
* `ApplicationLoVId` (int) - FK to LoV (application identifier)
* `SecurityGroupName` (nvarchar(510)) - Azure AD group display name
* `SecurityGroupGUID` (nvarchar(510)) - **Azure AD group object ID (GUID) - used by sync script**
* `LastChangeDate`, `LastChangedBy` \- Audit fields

**Relationships:**

* Foreign key to `ReportingDeck.ReportingDeckId`
* Foreign key to `LoV.Id` (Application)
* Used by `RDSecurityGroupPermission` view to determine group mappings

**Typical Reads/Writes:**

* **Reads:** High-frequency reads by `RDSecurityGroupPermission` view
* **Writes:** Infrequent administrative updates when groups are created/renamed

**Indexes:**

* Primary key on `ReportingDeckSecurityGroupsId` (clustered)
* Consider unique index on `SecurityGroupGUID` (if one-to-one mapping expected)
* Index on `ApplicationLoVId` for view performance

### Reference Data Tables

#### Entity

* **Purpose:** Organizational hierarchy (Global → Region → Cluster → Market → Entity)
* **Key Columns:** `EntityKey`, `EntityCode`, `EntityDesc`, `RegionKey`, `ClusterKey`, `MarketKey`, `SakuraPath`
* **Row Count:** 1,497 active rows
* **Usage:** Scoping for Orga/CP/MSS permissions

#### ServiceLine

* **Purpose:** Service line hierarchy
* **Key Columns:** `ServiceLineKey`, `ServiceLineCode`, `ServiceLineDesc`, `ServiceLineParentKey`, `SakuraPath`
* **Row Count:** 21 rows
* **Usage:** Critical for `RDSecurityGroupPermission` view (group name matching logic)

#### CostCenter

* **Purpose:** Cost center hierarchy (Single, BPC Rollup, Business Unit)
* **Key Columns:** `CostCenterKey`, `CostCenterCode`, `CostCenterDesc`, `CostCenterParentKey`, `CostCenterGroupKey`
* **Row Count:** 2,908 rows
* **Usage:** Scoping for Orga/CC permissions

#### Client

* **Purpose:** Client hierarchy
* **Key Columns:** `ClientKey`, `ClientCode`, `ClientDesc`, `ClientParentKey`
* **Row Count:** 96,140 rows
* **Usage:** Scoping for CP permissions

#### MasterServiceSet (MSS)

* **Purpose:** Master Service Set hierarchy
* **Key Columns:** `MSSKey`, `MSSCode`, `MSSDesc`, `MSSParentKey`
* **Row Count:** 260 rows
* **Usage:** Scoping for MSS permissions

#### ReportingDeck

* **Purpose:** PowerBI report deck definitions
* **Key Columns:** `ReportingDeckId`, `ReportingDeckKey`, `ReportingDeckCode`, `ReportingDeckDesc`
* **Row Count:** 24 rows
* **Usage:** Maps to security groups via `ReportingDeckSecurityGroups`

#### LoV (List of Values)

* **Purpose:** Configuration and lookup values (applications, request types, approval statuses)
* **Key Columns:** `Id`, `LoVType`, `LoVValue`, `LoVName`, `LoVDescription`
* **Row Count:** 23 rows
* **Usage:** Used throughout system for dropdowns, status mappings, application identification

- - -

## DB Logic Layer

### Capability Clustering

Database logic is organized into the following functional capabilities:

1. **Permission Request Management** \- Create\, approve\, reject\, revoke requests
2. **Approver Resolution** \- Find approvers based on request scope
3. **Email Notification** \- Queue and send emails
4. **Audit Logging** \- Event log management
5. **Lookup/Configuration** \- LoV and application settings
6. **Data Loading** \- Staging to production ETL
7. **Reporting Views** \- Aggregated views for reporting

### Capability 1: Permission Request Management

#### CreateCPPermissionRequest

**Purpose:** Creates a Client-Project (CP) permission request.

**Parameters:**

* `@RequestedFor` (nvarchar(510)) - User requesting access
* `@RequestedBy` (nvarchar(510)) - User creating request
* `@RequestReason` (nvarchar(2048)) - Business justification
* `@ApplicationLoVId` (int) - Application identifier
* `@EntityLevel` (nvarchar(100)) - Entity hierarchy level
* `@EntityCode` (nvarchar(100)) - Entity code
* `@ServiceLineCode` (nvarchar(100)) - Service line code
* `@ClientCode` (nvarchar(100)) - Client code
* `@ProjectCode` (nvarchar(100)) - Project code

**Workflow:**

1. Generates `RequestBatchCode` and `RequestCode` (via sequence)
2. Inserts `PermissionHeader` record (ApprovalStatus = 0)
3. Inserts `PermissionCPDetail` record
4. Calls `ApprovePermissionRequest` (if auto-approval configured)
5. Calls `AddToEventLog` (RequestCreated event)
6. Calls `AddToEmailQueue` (notify approvers)

**Tables Read:**

* `RequestCodeSequence` (sequence)
* `LoV` (for application name lookup)

**Tables Written:**

* `PermissionHeader` (INSERT)
* `PermissionCPDetail` (INSERT)
* `EventLog` (via AddToEventLog)

**Call Chain:**

```
CreateCPPermissionRequest
  → ApprovePermissionRequest (if auto-approve)
  → AddToEventLog
  → AddToEmailQueue
    → FindEmailRecipients
    → QueueEmail
      → ConstructEMail
```

#### CreateOrgaPermissionRequest

**Purpose:** Creates an Organizational (Orga) permission request.

**Parameters:** Similar to CreateCPPermissionRequest, plus:

* `@AccountCode`, `@ProfitCenterCode`
* `@CostCenterLevel`, `@CostCenterCode`

**Workflow:** Similar to CreateCPPermissionRequest, with additional cost center validation via `fnGetCostCenterListWithContextFilter`.

**Tables Read:**

* `PermissionHeader`, `PermissionOrgaDetail`
* `CostCenter`, `CostCenterServiceLineMapping`, `Entity`, `ServiceLine` (via function)

**Tables Written:**

* `PermissionHeader` (INSERT)
* `PermissionOrgaDetail` (INSERT)
* `EventLog` (via AddToEventLog)

#### CreateMSSPermissionRequest

**Purpose:** Creates a Master Service Set (MSS) permission request.

**Parameters:** Similar to CreateCPPermissionRequest, with `@MSSCode` instead of Client/Project.

**Workflow:** Similar to CreateCPPermissionRequest.

#### ApprovePermissionRequest

**Purpose:** Approves a permission request.

**Parameters:**

* `@RequestId` (int) - Request to approve
* `@ApprovedBy` (nvarchar(510)) - Approver email

**Workflow:**

1. Validates request is in Pending status
2. Updates `PermissionHeader`: `ApprovalStatus = 1`, `ApprovedBy`, `ApprovedDate`
3. Calls `AddToEventLog` (PermissionRequestApproved)
4. Calls `AddToEmailQueue` (notify requester)

**Tables Read:**

* `PermissionHeader` (for validation)

**Tables Written:**

* `PermissionHeader` (UPDATE)
* `history.PermissionHeader` (via trigger)
* `EventLog` (via AddToEventLog)

**Call Chain:**

```
ApprovePermissionRequest
  → AddToEventLog
  → AddToEmailQueue
    → FindEmailRecipients
    → QueueEmail
```

#### RejectPermissionRequest

**Purpose:** Rejects a permission request.

**Parameters:**

* `@RequestId` (int)
* `@RejectedBy` (nvarchar(510))
* `@RejectReason` (nvarchar(2048))

**Workflow:** Similar to ApprovePermissionRequest, sets `ApprovalStatus = 2`.

#### RevokePermissionRequest

**Purpose:** Revokes an approved permission request.

**Parameters:**

* `@RequestId` (int)
* `@RevokedBy` (nvarchar(510))

**Workflow:**

1. Validates request is Approved
2. Updates `PermissionHeader`: `ApprovalStatus = 3`
3. Calls `AddToEventLog` (PermissionRequestRevoked)
4. Calls `AddToEmailQueue` (notify requester)
5. **Note:** Revocation removes user from `RDSecurityGroupPermission` view (since it filters `ApprovalStatus = 1`), which will cause `SakuraADSync.ps1` to remove them from Azure AD group on next sync

**Tables Written:**

* `PermissionHeader` (UPDATE)
* `EventLog` (via AddToEventLog)

### Capability 2: Approver Resolution

#### FindApprovers

**Purpose:** Dispatcher procedure that routes to type-specific approver finders.

**Parameters:**

* `@RequestType` (int) - Request type
* `@ApplicationLoVId` (int)
* `@EntityCode`, `@ServiceLineCode`, etc. (request-specific scoping)

**Workflow:**

* Routes to: `FindCPApprovers`, `FindOrgaApprovers`, `FindMSSApprovers`, `FindSGMApprovers`, `FindReportingDeckApprovers`

**Call Chain:**

```
FindApprovers
  → FindOrgaApprovers
    → fnFindOrgaApproversExact
      → ApproversOrga (table lookup)
  → FindCPApprovers
    → fnFindCPApproversExact
      → ApproversCP (table lookup)
```

#### FindOrgaApprovers

**Purpose:** Finds approvers for Orga requests based on Entity/ServiceLine/CostCenter scoping.

**Tables Read:**

* `ApproversOrga` \- Approver rules table
* `Entity` \- For hierarchy traversal
* `ServiceLine` \- For hierarchy traversal

**Logic:**

* Matches approvers based on exact or hierarchical matches of EntityCode, ServiceLineCode, CostCenterCode
* Supports delegation (DelegateUserName column)

### Capability 3: Email Notification

#### QueueEmail

**Purpose:** Queues an email for sending.

**Parameters:**

* `@EmailTemplateKey` (nvarchar(100))
* `@ContextEntityName` (nvarchar(100)) - Usually 'PermissionHeader'
* `@ContextId` (nvarchar(100)) - Usually RequestId
* `@To`, `@CC`, `@BCC` (nvarchar(max))

**Workflow:**

1. Calls `ConstructEMail` to build email body/subject from template
2. Inserts into `Emails` table (Status = 0, unsent)
3. Calls `AddToEventLog` (EmailQueued)

**Tables Read:**

* `EmailTemplates` (via ConstructEMail)
* `PermissionHeader`, `Permission*Detail` (via ConstructEMail for context)

**Tables Written:**

* `Emails` (INSERT)
* `EventLog` (via AddToEventLog)

#### ConstructEMail

**Purpose:** Builds email body and subject from template with context substitution.

**Parameters:**

* `@EmailTemplateKey` (nvarchar(100))
* `@ContextEntityName`, `@ContextId`
* `@To`, `@CC`, `@BCC`

**Workflow:**

1. Reads `EmailTemplates` table
2. Reads context entity (e.g., `PermissionHeader` + `Permission*Detail`)
3. Substitutes template variables with context data
4. Returns formatted email body/subject

**Tables Read:**

* `EmailTemplates`
* `PermissionHeader`, `PermissionCPDetail`, `PermissionOrgaDetail`, etc.
* `ApproversCP`, `ApproversOrga`, etc. (for approver lists)
* `Entity`, `ServiceLine`, `Client`, `CostCenter`, `MasterServiceSet` (for descriptions)
* `LoV` (for status/type descriptions)

#### FindEmailRecipients

**Purpose:** Determines email recipients for permission request notifications.

**Tables Read:**

* `PermissionHeader` \- For request details
* `EventLog` \- For previous notification history \(to avoid duplicates\)
* `ApplicationSettings` \- For configuration \(via `fnAppSettingValue`)

**Logic:**

* Reads approvers from `PermissionHeader.Approvers` column
* Checks `EventLog` to avoid duplicate notifications
* Returns list of email addresses

### Capability 4: Audit Logging

#### AddToEventLog

**Purpose:** Inserts an event into the audit trail.

**Parameters:**

* `@TableName` (nvarchar(100))
* `@RecordId` (int)
* `@EventTimestamp` (smalldatetime)
* `@EventName` (nvarchar(100))
* `@EventDescription` (nvarchar(2048))
* `@EventTriggeredBy` (nvarchar(510))

**Workflow:**

* Simple INSERT into `EventLog` table

**Tables Written:**

* `EventLog` (INSERT)

**Usage:**

* Called by all permission request procedures
* Called by `SakuraADSync.ps1` via `Insert-EventLog` PowerShell function

#### LogPermissionViewEvent

**Purpose:** Logs when a user views permission details (for audit compliance).

**Parameters:**

* `@RequestId` (int)
* `@ViewedBy` (nvarchar(510))

**Workflow:**

* Calls `AddToEventLog` with event name 'PermissionViewed'

### Capability 5: Lookup/Configuration

#### fnAppSettingValue

**Purpose:** Retrieves application setting value by key.

**Parameters:**

* `@SettingKey` (nvarchar(100))

**Returns:** Setting value (nvarchar)

**Tables Read:**

* `ApplicationSettings`

**Usage:**

* Used throughout system for configuration (e.g., 'EnvironmentTag', 'EmailMaxRetrials', 'EmailRetryAfterMins', 'EmailingMode', 'ActiveEmailQueues')

#### fnLoVValues

**Purpose:** Returns list of values for a given LoV type.

**Parameters:**

* `@LoVType` (nvarchar(100))

**Returns:** Table with `Id`, `LoVValue`, `LoVName`, `LoVDescription`

**Tables Read:**

* `LoV`

**Usage:**

* Used by views and procedures for dropdown population and lookups

### Capability 6: Data Loading (Staging)

#### sp\_Load\_Client, sp\_Load\_Entity, sp\_Load\_CostCenter, sp\_Load\_ServiceLine, sp\_Load\_MasterServiceSet

**Purpose:** ETL procedures that load reference data from `staging` schema to `dbo` schema.

**Workflow:**

1. Validates staging data
2. Inserts/updates `dbo` tables
3. Maintains `history` schema via triggers
4. Updates `ValidFrom`/`ValidTo` for temporal tracking

**Tables Read:**

* `staging.*` tables

**Tables Written:**

* `dbo.*` tables (INSERT/UPDATE)
* `history.*` tables (via triggers)

### Capability 7: Reporting Views

#### PermissionHeaderList

**Purpose:** Aggregated view of permission requests with human-readable descriptions.

**Columns:** Request metadata \+ concatenated info string \(Entity\|ServiceLine\|CostCenter/Client\)

**Tables Read:**

* `PermissionHeader`, `PermissionOrgaDetail`, `PermissionCPDetail`, `PermissionMSSDetail`
* `Entity`, `ServiceLine`, `Client`, `CostCenterList`, `MasterServiceSet`
* `LoV` (for status/type descriptions)

#### SakuraReportforAllEnviroments

**Purpose:** Comprehensive reporting view with approval metrics and timing.

**Columns:** Request details + `DaysTakenToApprove`, `DaysTakenToReject`, `TicketLifeInDays`

**Tables Read:**

* `PermissionHeaderList` (view)
* `PermissionOrgaDetail`, `PermissionCPDetail`
* `Entity`, `ServiceLine`, `CCPermission`

- - -

## Authorization Model

### User Identity Mapping

Sakura uses **email addresses** (UPN format) as the primary user identifier:

* **RequestedFor** (in `PermissionHeader`) - User requesting access (email/UPN)
* **RequestedBy** (in `PermissionHeader`) - User creating request (email/UPN)
* **ApproverUserName** (in `Approvers*` tables) - Approver email/UPN

**Note:** Sakura does **NOT** use `AspNetUsers` table for authorization decisions. User identity is managed separately by ASP.NET Identity framework.

### Azure AD Group Mapping

Authorization is enforced through **Azure AD Security Groups**, which are mapped to PowerBI reports. The mapping is stored in:

1. **ReportingDeckSecurityGroups** table:
    * `SecurityGroupGUID` \- Azure AD group object ID \(GUID format\)
    * `SecurityGroupName` \- Azure AD group display name
    * `ApplicationLoVId` \- PowerBI application identifier
    * `ReportingDeckId` \- Reporting deck identifier
2. **RDSecurityGroupPermission** view:
    * Aggregates approved requests into desired group membership
    * Output: `RequestedFor` (user email) → `SecurityGroupGUID` (group GUID)

### Group Membership Determination Logic

The `RDSecurityGroupPermission` view determines group membership using the following logic:

1. **Base Query:**
    * Joins `PermissionHeader` (approved requests only, `ApprovalStatus = 1`)
    * Joins `PermissionOrgaDetail` (for Entity/ServiceLine/CostCenter scoping)
    * Joins `ServiceLine` (for ServiceLine code matching)
    * Joins `ReportingDeckSecurityGroups` (for group mappings)
    * Joins `ReportingDeck` (for deck details)
2. **Filtering:**
    * Only `RequestType IN (0, 2, 7)` \- Orga\, CC\, MSS requests \(excludes CP\, SGM\, Reporting Deck direct\)
    * Only `ApprovalStatus = 1` \- Approved requests
    * Excludes `RequestReason LIKE 'SALES BULK%'` \- Excludes bulk sales requests
    * Requires `SecurityGroupGUID IS NOT NULL` \- Only groups with valid GUIDs
3. **Group Name Matching:**
    * Uses `CHARINDEX(t.ServiceLineCode, SecurityGroupName, 1) > 0` to match ServiceLine codes in group names
    * This implies group names must contain ServiceLine codes (e.g., "#SG-UN-SAKURA-{ServiceLineCode}")
4. **Special Case - EntireOrg Group:**
    * Adds all approved users to "EntireOrg" group (environment-specific GUIDs)
    * Ensures users can access the PowerBI application itself

### PowerBI Access Grant Flow

```
1. User requests permission via Portal
   → PermissionHeader created (ApprovalStatus = 0)

2. Approver approves request
   → PermissionHeader.ApprovalStatus = 1

3. RDSecurityGroupPermission view includes user
   → User appears in view with SecurityGroupGUID

4. SakuraADSync.ps1 runs (scheduled)
   → Reads RDSecurityGroupPermission view
   → Compares with Azure AD group membership
   → Adds user to group if missing

5. Azure AD group membership updated
   → PowerBI reads group membership
   → User gains access to reports
```

### Request Type to Group Mapping

* **Orga (RequestType = 0):** Maps to groups based on Entity/ServiceLine/CostCenter scoping
* **CC (RequestType = 2):** Cost Center-specific groups
* **MSS (RequestType = 7):** Master Service Set groups
* **CP (RequestType = 1):** Client-Project permissions (may not map to groups directly)
* **SGM (RequestType = 5):** Security Group Manager permissions (direct group assignment)
* **Reporting Deck (RequestType = 4):** Reporting deck-specific groups

### Approver Rules

Approvers are determined by the `Approvers*` tables:

* **ApproversOrga** \- Scoped by EntityLevel\, EntityCode\, ServiceLineCode\, CostCenterLevel\, CostCenterCode
* **ApproversCP** \- Scoped by EntityLevel\, EntityCode\, ServiceLineCode\, ClientCode\, ProjectCode
* **ApproversMSS** \- Scoped by EntityLevel\, EntityCode\, MSSCode
* **ApproversSGM** \- Scoped by SecurityGroupCode
* **ApproversReportingDeck** \- Scoped by ReportingDeckKey

**Delegation Support:**

* `DelegateUserName` column allows approvers to delegate approval authority
* `ApproverDelegation` table supports time-based delegation

- - -

## Audit Trail Model

### EventLog Schema

The `EventLog` table provides an immutable audit trail of all significant system events.

**Schema:**

* `EventLogId` (bigint, PK, identity) - Unique event identifier
* `TableName` (nvarchar(100)) - Source table (e.g., 'PermissionHeader', 'RDSecurityGroupPermission')
* `RecordId` (int) - Related record ID (e.g., RequestId, or -1 for system events)
* `EventTimestamp` (smalldatetime) - When event occurred
* `EventName` (nvarchar(100)) - Event type identifier
* `EventDescription` (nvarchar(2048)) - Detailed description
* `EventTriggeredBy` (nvarchar(510)) - Actor (procedure name, script name, user email)

### Event Types

#### Portal-Generated Events

**Permission Request Lifecycle:**

* `RequestCreated` \- Permission request created
* `PermissionRequestApproved` \- Request approved
* `PermissionRequestRejected` \- Request rejected
* `PermissionRequestRevoked` \- Request revoked
* `ApproverAppended` \- Additional approver added
* `PermissionViewed` \- User viewed permission details

**Email Events:**

* `EmailQueued` \- Email queued for sending
* `EmailSent` \- Email successfully sent \(via external email service\)

#### SakuraADSync.ps1 Generated Events

**Group Membership Changes:**

* `GroupMemberAdded` \- User successfully added to Azure AD group
    * Description format: "User '{UserId}' to Group '{GroupId}', Success!"
* `GroupMemberRemoved` \- User successfully removed from Azure AD group
    * Description format: "User '{UserId}' to Group '{GroupId}', Should not be a member anymore."
* `GroupMemberNotAdded` \- User not found in Azure AD \(cannot add\)
    * Description format: "User '{UserId}' to Group '{GroupId}', Could not find this User in AD."

**EventTriggeredBy:** Always "SakuraADSync.ps1" for sync-generated events

**TableName:** "RDSecurityGroupPermission" (even though it's a view, the script logs it as a table)

**RecordId:** -1 (system event, not tied to a specific record)

### Audit Completeness

**What is Logged:**

* ✅ All permission request lifecycle events (create, approve, reject, revoke)
* ✅ All Azure AD group membership changes (add, remove, errors)
* ✅ Email queue operations
* ✅ Permission view events (for compliance)

**What is NOT Logged:**

* ❌ Direct database updates (if done outside procedures)
* ❌ Failed sync attempts (if script exits before logging)
* ❌ Azure AD API errors (only successful operations are logged)

**Gaps:**

* No logging of `SakuraADSync.ps1` script start/end
* No logging of sync summary (total groups processed, total errors)
* No logging of Azure AD API throttling/retry events

### Tracing User/Group Changes End-to-End

**Scenario:** Trace why user `user@example.com` was added to group `#SG-UN-SAKURA-Finance`

**Step 1: Find Permission Request**

``` sql
SELECT RequestId, RequestCode, RequestDate, ApprovalStatus, ApprovedDate
FROM PermissionHeader
WHERE RequestedFor = 'user@example.com'
  AND ApprovalStatus = 1
ORDER BY RequestDate DESC
```

**Step 2: Find Approval Event**

``` sql
SELECT EventLogId, EventTimestamp, EventName, EventDescription, EventTriggeredBy
FROM EventLog
WHERE TableName = 'PermissionHeader'
  AND RecordId = @RequestId
  AND EventName = 'PermissionRequestApproved'
```

**Step 3: Find Group Membership Event**

``` sql
SELECT EventLogId, EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventDescription LIKE '%user@example.com%'
  AND EventDescription LIKE '%#SG-UN-SAKURA-Finance%'
  AND EventName = 'GroupMemberAdded'
ORDER BY EventTimestamp DESC
```

**Step 4: Verify Current State**

``` sql
SELECT RequestedFor, SecurityGroupName, SecurityGroupGUID, LastChangeDate
FROM RDSecurityGroupPermission
WHERE RequestedFor = 'user@example.com'
  AND SecurityGroupGUID = '<group-guid>'
```

### Audit Retention

**Current State:**

* No automatic purging observed
* 600K+ records in `EventLog` table
* Historical data preserved in `history` schema for core tables

**Recommendations:**

* Implement retention policy (e.g., 7 years for compliance)
* Consider partitioning `EventLog` by `EventTimestamp` for performance
* Archive old events to separate table/database

- - -

## External Integrations

### Microsoft Graph API Integration

**Integration Point:** `SakuraADSync.ps1` PowerShell script

#### Required Modules

* `Microsoft.Graph.Users` \- User lookup operations
* `Microsoft.Graph.Groups` \- Group membership management

#### Authentication

**Current Implementation:**

* Uses `Connect-MgGraph` (interactive authentication)
* **Security Risk:** Requires interactive login; no app-only authentication observed

**Required Scopes/Permissions:**
Based on script analysis:

* `Group.ReadWrite.All` \- Read and write group membership
* `User.Read.All` \- Read user profiles for lookup
* `Directory.Read.All` \- Read directory objects \(for group lookups\)

#### API Calls Made

**1\. User Lookup**

``` powershell
Get-MgUser -Property "displayName,id,userPrincipalName" `
  -Filter "userPrincipalName eq '$RequestedFor' or mail eq '$RequestedFor'"
```

* **Purpose:** Resolve user email/UPN to Azure AD user object ID
* **Frequency:** Once per unique user in `RDSecurityGroupPermission` view
* **Throttling:** Subject to Graph API rate limits (typically 10,000 requests per 10 minutes per app)

**2\. Group Retrieval**

``` powershell
Get-MgGroup -GroupId $SecurityGroupGUID
```

* **Purpose:** Verify group exists and retrieve metadata
* **Frequency:** Once per unique group in `RDSecurityGroupPermission` view

**3\. Group Members Retrieval**

``` powershell
Get-MgGroupMemberAsUser -GroupId $SecurityGroupGUID `
  -CountVariable MemberCount -ConsistencyLevel eventual -All `
  -Property "displayName,id,mail"
```

* **Purpose:** Get current group membership for comparison
* **Frequency:** Once per unique group
* **Note:** Uses `ConsistencyLevel eventual` for performance (may have slight delay)

**4\. Remove Group Member**

``` powershell
Remove-MgGroupMemberByRef -GroupId $SecurityGroupGUID -DirectoryObjectId $MemberId
```

* **Purpose:** Remove user from group (when not in desired state)
* **Frequency:** Per user that should be removed
* **Throttling:** Individual API calls (not batched)

**5\. Add Group Members \(Batch\)**

``` powershell
Update-MgGroup -GroupId $SecurityGroupGUID -BodyParameter @{
  "members@odata.bind" = @(
    "https://graph.microsoft.com/v1.0/directoryObjects/$UserId1",
    "https://graph.microsoft.com/v1.0/directoryObjects/$UserId2",
    ...
  )
}
```

* **Purpose:** Add multiple users to group in single API call
* **Frequency:** Per batch (20 users per batch)
* **Throttling:** Batched to reduce API calls

#### Error Handling

**Current Implementation:**

* Try-catch blocks around each API call
* Errors logged to transcript and `EventLog`
* Script continues processing other groups on error
* Error count tracked and included in email notification

**Limitations:**

* No retry logic for transient errors (throttling, network issues)
* No exponential backoff
* No idempotency checks (may retry same operation if script rerun)

#### Throttling Considerations

**Graph API Limits:**

* 10,000 requests per 10 minutes per app (default)
* Batch operations count as single request
* Script batches additions (20 users per batch) but not removals

**Risk:**

* Large number of groups/users may hit throttling limits
* Script may fail mid-execution if throttled
* No automatic retry on throttling errors

### SMTP Notification

**Integration Point:** `SakuraADSync.ps1` (end of script)

#### Configuration

* **SMTP Server:** `internalsmtprelay.media.global.loc`
* **SMTP Port:** 25
* **From:** `sakurahelp@dentsu.com`
* **To:** `onur.ozturk@dentsu.com` (hardcoded - **security risk**)
* **SSL:** Disabled

#### Email Content

* **Subject:** `[Sakura AD Sync - TEST]: Success` or `[Sakura AD Sync - TEST]: Failure`
* **Body:** `Err Count: {errcount} - Operations Count: {opcount}`
* **Attachment:** Log file (`output_{timestamp}.log`)

#### Email Flow

1. Script completes sync run
2. Generates summary (error count, operation count)
3. Creates email message with log file attachment
4. Sends via SMTP (no authentication required)
5. Disposes attachment

**Limitations:**

* Hardcoded recipient (should be configurable)
* No retry logic if email send fails
* No notification if script fails before email step

### Database-Level External Patterns

**From FA08\_ExternalIntegrationSignals.csv analysis:**

* `RDSecurityGroupPermission` view is marked as external integration point (read by `SakuraADSync.ps1`)
* No other explicit external integration patterns observed at DB level

- - -

## Operational Runbook

### SakuraADSync.ps1 Execution

#### Schedule Assumptions

* **Assumed Schedule:** Daily (exact schedule not documented in script)
* **Recommended:** Run during off-peak hours (e.g., 2 AM) to minimize impact
* **Frequency:** Should align with business needs (daily recommended for timely access)

#### Prerequisites

**1\. PowerShell Environment:**

* PowerShell 5.1 or later
* Microsoft Graph PowerShell modules installed:
    * `Microsoft.Graph.Users`
    * `Microsoft.Graph.Groups`

**2\. Authentication:**

* Azure AD account with appropriate permissions
* Interactive login capability (or service principal if modified)

**3\. Database Access:**

* SQL Server connection string configured
* Database user `SakuraAppAdmin` with read access to `RDSecurityGroupPermission` view
* Database user with write access to `EventLog` table

**4\. Network:**

* Outbound connectivity to `graph.microsoft.com`
* Outbound connectivity to SMTP relay server

#### Execution Flow

```
1. Start transcript logging
2. Import Microsoft Graph modules
3. Connect to Microsoft Graph (interactive)
4. Connect to SQL Server
5. Execute query: SELECT FROM RDSecurityGroupPermission
6. For each unique user:
   a. Lookup user in Azure AD (Get-MgUser)
   b. Build user lookup hashtable
7. For each unique group:
   a. Fetch group from Azure AD (Get-MgGroup)
   b. Fetch current group members (Get-MgGroupMemberAsUser)
   c. Compare desired vs actual membership
   d. Remove members not in desired state
   e. Add members in desired state (batched, 20 per batch)
   f. Log each operation to EventLog
8. Close database connection
9. Stop transcript
10. Send email notification with summary
```

#### Failure Modes

**1\. Database Connection Failure**

* **Symptom:** Script exits with error on connection open
* **Impact:** No sync occurs
* **Recovery:** Check SQL Server availability, connection string, credentials
* **Monitoring:** Alert on script non-zero exit code

**2\. Microsoft Graph Authentication Failure**

* **Symptom:** `Connect-MgGraph` fails, no context available
* **Impact:** No sync occurs
* **Recovery:** Re-authenticate, check account permissions
* **Monitoring:** Alert on authentication errors in log

**3\. User Not Found in Azure AD**

* **Symptom:** `Get-MgUser` returns null
* **Impact:** User not added to group, logged as `GroupMemberNotAdded`
* **Recovery:** Verify user exists in Azure AD, check UPN/email format
* **Monitoring:** Alert on high count of `GroupMemberNotAdded` events

**4\. Group Not Found in Azure AD**

* **Symptom:** `Get-MgGroup` fails with 404
* **Impact:** Group skipped, error logged
* **Recovery:** Verify `SecurityGroupGUID` in `ReportingDeckSecurityGroups` is correct
* **Monitoring:** Alert on group lookup failures

**5\. API Throttling**

* **Symptom:** Graph API returns 429 (Too Many Requests)
* **Impact:** Script may fail or skip operations
* **Recovery:** Implement retry logic with exponential backoff (not currently implemented)
* **Monitoring:** Alert on 429 errors in log

**6\. Batch Add Failure**

* **Symptom:** `Update-MgGroup` fails for batch
* **Impact:** Entire batch not added (no partial success)
* **Recovery:** Retry failed batch, or add users individually
* **Monitoring:** Alert on batch operation failures

**7\. Email Send Failure**

* **Symptom:** SMTP send fails
* **Impact:** No notification sent (but sync may have succeeded)
* **Recovery:** Check SMTP server availability, retry email send
* **Monitoring:** Alert on email send failures

#### Throttling and Retries

**Current Implementation:**

* ❌ No retry logic for transient errors
* ❌ No exponential backoff
* ❌ No throttling detection/handling

**Recommendations:**

* Implement retry logic for 429 (throttling) and 5xx (server errors)
* Use exponential backoff (e.g., 1s, 2s, 4s, 8s)
* Add delay between group processing to avoid throttling
* Monitor API call rate and adjust batch sizes

#### Idempotency

**Current Behavior:**

* Script is **idempotent** for group membership operations:
    * Adding user who is already a member: No error (Graph API handles gracefully)
    * Removing user who is not a member: May error (should be handled)
* Script is **NOT idempotent** for EventLog:
    * Re-running script will create duplicate EventLog entries
    * No check for existing events before inserting

**Recommendations:**

* Add idempotency check for EventLog (e.g., check for existing event with same timestamp/description)
* Handle "user already member" and "user not member" cases gracefully

#### Rollback Plan

**Scenario:** Incorrect sync removes users from groups

**Recovery Steps:**

1. Identify affected users from `EventLog`:

``` sql
SELECT EventDescription, EventTimestamp
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventName = 'GroupMemberRemoved'
  AND EventTimestamp >= '<incident-start-time>'
```

2. Verify desired state in `RDSecurityGroupPermission` view:

``` sql
SELECT RequestedFor, SecurityGroupName, SecurityGroupGUID
FROM RDSecurityGroupPermission
WHERE RequestedFor IN ('user1@example.com', 'user2@example.com', ...)
```

3. Re-run `SakuraADSync.ps1` to restore correct membership (if desired state is correct)
4. If desired state is incorrect, fix underlying permission requests:
    * Revoke incorrect requests
    * Create correct requests
    * Re-run sync

**Prevention:**

* Test sync script in non-production environment first
* Implement dry-run mode (log actions without executing)
* Add confirmation prompt for large changes

### Monitoring Checklist

#### Log Files to Review

**1\. PowerShell Transcript Log:**

* Location: `output_{timestamp}.log` (in script directory)
* Contains: Full execution log, all API calls, errors, warnings
* Review: After each run, check for errors/warnings

**2\. EventLog Table:**

* Query recent sync events:

``` sql
SELECT EventLogId, EventTimestamp, EventName, EventDescription
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventTriggeredBy = 'SakuraADSync.ps1'
  AND EventTimestamp >= DATEADD(day, -1, GETDATE())
ORDER BY EventTimestamp DESC
```

#### Alerts to Configure

**1\. Script Execution Failure:**

* Alert if script exits with non-zero code
* Alert if script does not run (schedule monitoring)

**2\. High Error Rate:**

* Alert if `errcount > 10` in email notification
* Alert if `GroupMemberNotAdded` events > 5% of total operations

**3\. Group Lookup Failures:**

* Alert if any `Get-MgGroup` calls fail (group not found)

**4\. API Throttling:**

* Alert on 429 (Too Many Requests) errors in transcript log

**5\. Database Connection Issues:**

* Alert on SQL connection failures

**6\. Email Notification Failure:**

* Alert if email send fails (may indicate script completion issue)

#### Performance Monitoring

**Metrics to Track:**

* Script execution time (should be < 30 minutes for typical load)
* Number of groups processed
* Number of users processed
* API call count (to detect throttling risk)
* Database query execution time

**Queries:**

``` sql
-- Recent sync execution summary
SELECT 
    COUNT(*) AS TotalEvents,
    SUM(CASE WHEN EventName = 'GroupMemberAdded' THEN 1 ELSE 0 END) AS Added,
    SUM(CASE WHEN EventName = 'GroupMemberRemoved' THEN 1 ELSE 0 END) AS Removed,
    SUM(CASE WHEN EventName = 'GroupMemberNotAdded' THEN 1 ELSE 0 END) AS NotAdded,
    MIN(EventTimestamp) AS StartTime,
    MAX(EventTimestamp) AS EndTime,
    DATEDIFF(minute, MIN(EventTimestamp), MAX(EventTimestamp)) AS DurationMinutes
FROM EventLog
WHERE TableName = 'RDSecurityGroupPermission'
  AND EventTriggeredBy = 'SakuraADSync.ps1'
  AND EventTimestamp >= DATEADD(day, -1, GETDATE())
GROUP BY CAST(EventTimestamp AS DATE)
```

- - -

## Security & Compliance Review

### Identified Risks

#### 1\. Hardcoded Credentials

**Location:** `SakuraADSync.ps1` lines 76-77

``` powershell
[string]$UserId   = "SakuraAppAdmin",
[string]$Password = "Media+`$2023"
```

**Risk Level:** **CRITICAL**

**Impact:**

* Database credentials exposed in source code
* Credentials may be committed to version control
* Credentials cannot be rotated without code changes

**Recommendations:**

* Move credentials to Azure Key Vault
* Use managed identity for Azure SQL authentication (if running on Azure)
* Use Windows Authentication if script runs on domain-joined machine
* Never commit credentials to source control

#### 2\. Hardcoded Email Recipient

**Location:** `SakuraADSync.ps1` line 465

``` powershell
$To = "onur.ozturk@dentsu.com"
```

**Risk Level:** **MEDIUM**

**Impact:**

* Email notifications go to single hardcoded recipient
* Cannot change recipients without code modification
* No distribution list support

**Recommendations:**

* Move to configuration file or environment variable
* Support multiple recipients (distribution list)
* Use `ApplicationSettings` table for configuration

#### 3\. Interactive Authentication

**Location:** `SakuraADSync.ps1` line 180

``` powershell
Connect-MgGraph
```

**Risk Level:** **HIGH**

**Impact:**

* Requires interactive login (cannot run unattended)
* User account credentials must be stored/managed
* No app-only authentication (uses delegated permissions)

**Recommendations:**

* Use service principal with app-only authentication
* Use certificate-based authentication
* Store service principal credentials in Azure Key Vault
* Grant minimal required permissions (least privilege)

#### 4\. Excessive Graph API Permissions

**Current Permissions (inferred):**

* `Group.ReadWrite.All` \- Full read/write access to all groups
* `User.Read.All` \- Read access to all users
* `Directory.Read.All` \- Read access to entire directory

**Risk Level:** **HIGH**

**Impact:**

* Script has broad access to Azure AD
* Compromise of script credentials = compromise of entire directory
* Violates principle of least privilege

**Recommendations:**

* Create dedicated service principal with minimal permissions
* Scope permissions to specific groups (if possible)
* Use `GroupMember.ReadWrite.All` instead of `Group.ReadWrite.All` (if available)
* Regularly audit service principal permissions

#### 5\. Database Permissions

**Current User:** `SakuraAppAdmin`

**Required Permissions:**

* **Read:** `RDSecurityGroupPermission` view, `EventLog` table
* **Write:** `EventLog` table (INSERT only)

**Risk Level:** **MEDIUM**

**Recommendations:**

* Create dedicated database user for sync script
* Grant only required permissions:

``` sql
GRANT SELECT ON dbo.RDSecurityGroupPermission TO SakuraSyncUser;
GRANT INSERT ON dbo.EventLog TO SakuraSyncUser;
```

* Do NOT grant `db_owner` or `db_datawriter` roles
* Use database role for permission management

#### 6\. Audit Immutability

**Current State:**

* `EventLog` table has no write protection
* Procedures can insert events, but no protection against updates/deletes
* No row-level security or audit triggers

**Risk Level:** **MEDIUM**

**Impact:**

* Audit trail could be tampered with
* Compliance violations if audit trail is modified

**Recommendations:**

* Implement audit table with INSERT-only permissions
* Use database triggers to prevent UPDATE/DELETE on `EventLog`
* Enable SQL Server audit to track access to `EventLog` table
* Consider using temporal tables for automatic history

#### 7\. SMTP Relay Security

**Current Configuration:**

* No authentication required
* Plain text communication (no TLS/SSL)
* Internal relay (may be acceptable for internal network)

**Risk Level:** **LOW** (if internal network only)

**Recommendations:**

* Use authenticated SMTP if possible
* Enable TLS/SSL for SMTP communication
* Restrict SMTP relay to specific IP addresses

### Security Recommendations Summary

#### Immediate Actions (Critical)

1. **Remove hardcoded credentials:**
    * Move to Azure Key Vault or environment variables
    * Update script to read from secure store
2. **Implement app-only authentication:**
    * Create service principal for `SakuraADSync.ps1`
    * Use certificate-based authentication
    * Store credentials in Azure Key Vault
3. **Reduce Graph API permissions:**
    * Create dedicated service principal
    * Grant minimal required permissions
    * Document required permissions

#### Short-Term Actions (High Priority)

4. **Secure database access:**
    * Create dedicated database user for sync script
    * Grant only required permissions
    * Use Windows Authentication if possible
5. **Protect audit trail:**
    * Implement INSERT-only permissions on `EventLog`
    * Add triggers to prevent UPDATE/DELETE
    * Enable SQL Server audit
6. **Improve error handling:**
    * Add retry logic for transient errors
    * Implement exponential backoff
    * Add idempotency checks

#### Long-Term Actions (Medium Priority)

7. **Configuration management:**
    * Move all hardcoded values to `ApplicationSettings` table
    * Support environment-specific configuration
    * Implement configuration validation
8. **Monitoring and alerting:**
    * Implement comprehensive monitoring
    * Set up alerts for security events
    * Regular security audits
9. **Documentation:**
    * Document all required permissions
    * Document security procedures
    * Maintain runbook for incident response

### Compliance Considerations

#### Data Retention

**Current State:**

* No automatic data purging
* 600K+ events in `EventLog` table
* Historical data preserved in `history` schema

**Recommendations:**

* Implement retention policy (align with compliance requirements)
* Archive old events to separate storage
* Document retention periods

#### Audit Trail Completeness

**Gaps Identified:**

* No logging of script start/end
* No logging of sync summary statistics
* No logging of API throttling events

**Recommendations:**

* Add script execution start/end events
* Log sync summary (groups processed, users processed, errors)
* Log all API errors (including throttling)

#### Access Control

**Recommendations:**

* Implement role-based access control (RBAC) for database
* Regular access reviews
* Document who has access to what

- - -

## Change Impact & Safe Migration

### Top Referenced Tables - Impact Analysis

#### 1\. PermissionHeader \(Highest Impact\)

**Dependencies:**

* **Foreign Keys From:** `PermissionOrgaDetail`, `PermissionCPDetail`, `PermissionMSSDetail`, `PermissionSGMDetail`, `PermissionReportingDeckDetail` (all have FK to `RequestId`)
* **Referenced By:** 50+ stored procedures, views, functions
* **Used In:** All permission request workflows, reporting views, `RDSecurityGroupPermission` view

**Safe Refactoring Approach:**

* **Column Rename:** Will break all dependent objects (procedures, views, functions)
    * **Checklist:**
        1. Identify all dependent objects (use `sys.sql_expression_dependencies`)
        2. Update all references in single transaction
        3. Test all permission request workflows
        4. Test `RDSecurityGroupPermission` view
        5. Test reporting views
* **Column Add:** Low risk (add nullable columns)
* **Column Remove:** High risk (break dependent objects)
* **Data Type Change:** High risk (may break application code)

**Migration Strategy:**

1. Create new column alongside old column
2. Update all code to use new column
3. Migrate data
4. Drop old column (after validation period)

#### 2\. EventLog \(High Impact\)

**Dependencies:**

* **Referenced By:** `AddToEventLog` procedure, `FindEmailRecipients` procedure, `LogPermissionViewEvent` procedure
* **Written By:** All permission request procedures, `SakuraADSync.ps1`

**Safe Refactoring Approach:**

* **Column Rename:** Medium risk (update procedures, PowerShell script)
* **Column Add:** Low risk (add nullable columns)
* **Column Remove:** High risk (may break audit queries)
* **Index Changes:** Medium risk (may impact query performance)

**Migration Strategy:**

1. Add new columns/indexes
2. Update procedures to use new structure
3. Migrate historical data (if needed)
4. Remove old columns (after validation)

#### 3\. PermissionOrgaDetail \(High Impact\)

**Dependencies:**

* **Foreign Key To:** `PermissionHeader.RequestId`
* **Referenced By:** `RDSecurityGroupPermission` view (critical), `CreateOrgaPermissionRequest` procedure, reporting views

**Safe Refactoring Approach:**

* **Column Rename:** High risk (breaks `RDSecurityGroupPermission` view)
* **Column Add:** Low risk
* **Column Remove:** High risk (breaks view logic)

**Migration Strategy:**

* Coordinate with `RDSecurityGroupPermission` view changes
* Test sync script after any changes

#### 4\. RDSecurityGroupPermission \(VIEW\) \- Critical Interface

**Dependencies:**

* **Read By:** `SakuraADSync.ps1` (sole consumer)
* **Derived From:** `PermissionHeader`, `PermissionOrgaDetail`, `ReportingDeckSecurityGroups`, `ServiceLine`, `ReportingDeck`

**Safe Refactoring Approach:**

* **Column Rename:** **CRITICAL RISK** \- Will break `SakuraADSync.ps1`
* **Column Remove:** **CRITICAL RISK** \- Will break sync script
* **Column Add:** Low risk (if script ignores unknown columns)
* **View Definition Change:** **CRITICAL RISK** \- Must coordinate with script update

**Migration Strategy:**

1. **Never change view without coordinating with `SakuraADSync.ps1`**
2. If changing view:
    * Update view definition
    * Update PowerShell script simultaneously
    * Test in non-production first
    * Deploy view and script together
3. Consider versioning view (e.g., `RDSecurityGroupPermission_v2`)

#### 5\. ReportingDeckSecurityGroups \(High Impact\)

**Dependencies:**

* **Referenced By:** `RDSecurityGroupPermission` view
* **Used For:** Group mapping (critical for sync)

**Safe Refactoring Approach:**

* **SecurityGroupGUID Column:** **CRITICAL** \- Do not change data type or rename
* **SecurityGroupName Column:** Medium risk (used in view)
* **Column Add:** Low risk

**Migration Strategy:**

* Any changes to `SecurityGroupGUID` or `SecurityGroupName` require view and script updates

### Module Dependency Impact

#### High-Impact Procedures

**AddToEventLog:**

* **Called By:** 15+ procedures
* **Impact of Change:** High (affects all audit logging)
* **Safe Change:** Add optional parameters (with defaults)

**AddToEmailQueue:**

* **Called By:** 10+ procedures
* **Impact of Change:** High (affects all email notifications)
* **Safe Change:** Add optional parameters

**ApprovePermissionRequest:**

* **Called By:** `CreateCPPermissionRequest`, `CreateOrgaPermissionRequest`, `CreateMSSPermissionRequest`, `CreateSGMPermissionRequest`, `BatchChangeStatusPermissionRequests`
* **Impact of Change:** High (affects all approval workflows)
* **Safe Change:** Add optional parameters, preserve existing behavior

### "What Breaks if We Rename a Column" Checklist

#### Pre-Change Analysis

1. **Identify All Dependencies:**

``` sql
SELECT 
    OBJECT_SCHEMA_NAME(referencing_id) AS ReferencingSchema,
    OBJECT_NAME(referencing_id) AS ReferencingObject,
    OBJECT_SCHEMA_NAME(referenced_id) AS ReferencingSchema,
    OBJECT_NAME(referenced_id) AS ReferencedObject
FROM sys.sql_expression_dependencies
WHERE referenced_id = OBJECT_ID('dbo.PermissionHeader')
  AND referenced_minor_id = (
      SELECT column_id 
      FROM sys.columns 
      WHERE object_id = OBJECT_ID('dbo.PermissionHeader') 
        AND name = 'RequestId'
  )
```

2. **Check Stored Procedures:**
    * Search procedure definitions for column name
    * Check parameter names (may reference column)
3. **Check Views:**
    * Search view definitions for column name
    * Check `RDSecurityGroupPermission` view (critical)
4. **Check Functions:**
    * Search function definitions for column name
5. **Check Application Code:**
    * Search application codebase for column name
    * Check API contracts
6. **Check External Integrations:**
    * Check `SakuraADSync.ps1` for column references
    * Check reporting tools/queries

#### Change Execution

1. **Create Migration Script:**
    * Rename column using `sp_rename`
    * Update all dependent objects in single transaction
    * Add rollback script
2. **Test in Non-Production:**
    * Run full test suite
    * Test permission request workflows
    * Test sync script
    * Test reporting views
3. **Deploy:**
    * Deploy during maintenance window
    * Execute migration script
    * Verify all objects updated
    * Test critical workflows
4. **Validation:**
    * Monitor for errors
    * Verify sync script runs successfully
    * Verify reporting works

### Safe Refactoring Best Practices

1. **Always Use Transactions:**
    * Wrap changes in transactions
    * Test rollback procedures
2. **Version Control:**
    * Track all schema changes in version control
    * Use migration scripts
3. **Backward Compatibility:**
    * Add new columns alongside old columns
    * Deprecate old columns gradually
    * Remove old columns after validation period
4. **Coordinate External Dependencies:**
    * Always coordinate with `SakuraADSync.ps1` changes
    * Test integration points thoroughly
5. **Documentation:**
    * Document all changes
    * Update this documentation
    * Communicate changes to stakeholders

- - -

## Appendix A: Table Inventory (Excluding AspNet\*)

### Core Tables

| Schema | Table Name | Row Count | Purpose |
| ------ | ---------- | --------- | ------- |
| dbo | PermissionHeader | 2,280 | Request lifecycle |
| dbo | PermissionOrgaDetail | 2,074 | Orga request details |
| dbo | PermissionCPDetail | 109 | CP request details |
| dbo | PermissionMSSDetail | 20 | MSS request details |
| dbo | PermissionSGMDetail | 2 | SGM request details |
| dbo | PermissionReportingDeckDetail | 0 | Reporting deck details |
| dbo | EventLog | 600,462 | Audit trail |
| dbo | ReportingDeckSecurityGroups | 85 | Group mappings |
| dbo | ReportingDeck | 24 | Reporting decks |

### Reference Data Tables

| Schema | Table Name | Row Count | Purpose |
| ------ | ---------- | --------- | ------- |
| dbo | Entity | 1,497 | Organizational hierarchy |
| dbo | ServiceLine | 21 | Service line hierarchy |
| dbo | CostCenter | 2,908 | Cost center hierarchy |
| dbo | Client | 96,140 | Client hierarchy |
| dbo | MasterServiceSet | 260 | MSS hierarchy |
| dbo | LoV | 23 | Lookup values |

### Approver Tables

| Schema | Table Name | Row Count | Purpose |
| ------ | ---------- | --------- | ------- |
| dbo | ApproversOrga | 449 | Orga approver rules |
| dbo | ApproversCP | 33 | CP approver rules |
| dbo | ApproversMSS | 8 | MSS approver rules |
| dbo | ApproversSGM | 3 | SGM approver rules |
| dbo | ApproversReportingDeck | 0 | Reporting deck approvers |
| dbo | ApproverDelegation | 0 | Delegation rules |

### Supporting Tables

| Schema | Table Name | Row Count | Purpose |
| ------ | ---------- | --------- | ------- |
| dbo | Emails | 5,643 | Email queue |
| dbo | EmailTemplates | 15 | Email templates |
| dbo | ApplicationSettings | 14 | Application configuration |
| dbo | BulkImportRecords | 1 | Bulk import staging |
| dbo | BulkImportSubmissions | 0 | Bulk import submissions |
| dbo | HelpContents | 17 | Help content |

### History Schema

All core tables have corresponding `history.*` tables for temporal tracking (via triggers).

### Staging Schema

Reference data tables have `staging.*` counterparts for ETL operations.

- - -

## Appendix B: Stored Procedure Inventory

### Permission Request Management (11 procedures)

* `CreateCPPermissionRequest`
* `CreateOrgaPermissionRequest`
* `CreateMSSPermissionRequest`
* `CreateSGMPermissionRequest`
* `CreateReportingDeckPermissionRequest`
* `ApprovePermissionRequest`
* `RejectPermissionRequest`
* `RevokePermissionRequest`
* `AppendApproverToPermissionRequest`
* `BatchChangeStatusPermissionRequests`

### Approver Resolution (6 procedures)

* `FindApprovers`
* `FindCPApprovers`
* `FindOrgaApprovers`
* `FindMSSApprovers`
* `FindSGMApprovers`
* `FindReportingDeckApprovers`

### Email Notification (5 procedures)

* `QueueEmail`
* `ConstructEMail`
* `AddToEmailQueue`
* `FindEmailRecipients`
* `MarkEmailAsSent`
* `MarkEmailAsUnsent`
* `CheckEmailApprovalAntiForgery`

### Audit Logging (2 procedures)

* `AddToEventLog`
* `LogPermissionViewEvent`

### Data Loading (5 procedures)

* `sp_Load_Client`
* `sp_Load_Entity`
* `sp_Load_CostCenter`
* `sp_Load_ServiceLine`
* `sp_Load_MasterServiceSet`

### Bulk Import (2 procedures)

* `ProcessBulkImportRecords`
* `UpsertBulkImportRecord`

### Configuration (1 procedure)

* `UpdateEmailTemplate`

- - -

## Document Maintenance

This documentation should be updated when:

* Database schema changes (tables, columns, indexes)
* Stored procedures are added/modified/removed
* Views are created/modified (especially `RDSecurityGroupPermission`)
* `SakuraADSync.ps1` script is modified
* External integrations change (Graph API, SMTP)
* Security configurations change

**Last Updated:** 2025-01-XX
**Next Review:** 2025-04-XX (quarterly)

- - -

**End of Document**
