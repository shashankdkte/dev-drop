# Sakura — Onboarding Visual Guide

**Who this is for:** Anyone new to the Sakura system — support engineers, developers, business analysts, or managers who need to understand how the whole system works from day one.

**How to read this:** Go section by section. Each section has a diagram followed by a plain-English explanation. By the end you will have a complete picture of every moving part.

---

## PART 1 — The Helicopter View: What is Sakura?

Before diving into details, understand the one-sentence purpose:

> **Sakura controls who can access Power BI reports by managing Azure Active Directory group membership — with full request, approval, and audit workflow.**

```mermaid
flowchart TD
    A["👤 Dentsu Employee\nWants Power BI access"] -->|"Submits request"| B["🌸 Sakura Portal\nWeb Application"]
    B -->|"Stores request\nin database"| C["🗄️ SQL Database\nSource of Truth"]
    C -->|"Notifies"| D["📧 Email System\nNotifications"]
    D -->|"Approval email"| E["✅ Approver\nReviews & Approves"]
    E -->|"Approves in portal"| C
    C -->|"Desired state\ncomputed"| F["🔄 AD Sync Script\nSakuraADSync.ps1"]
    F -->|"Adds user\nto group"| G["🏢 Azure AD\nSecurity Groups"]
    G -->|"Group membership\ngrants access"| H["📊 Power BI\nReports & Dashboards"]
    H -->|"User can now\nview reports"| A

    style A fill:#e8f4fd,stroke:#2196F3
    style B fill:#fff3e0,stroke:#FF9800
    style C fill:#fce4ec,stroke:#E91E63
    style D fill:#f3e5f5,stroke:#9C27B0
    style E fill:#e8f5e9,stroke:#4CAF50
    style F fill:#e0f2f1,stroke:#009688
    style G fill:#fff8e1,stroke:#FFC107
    style H fill:#e8eaf6,stroke:#3F51B5
```

**What this diagram tells you:**
- The loop starts with a user wanting access and ends with them having it
- Sakura is the orchestration layer — it does not grant access directly
- Access is ultimately enforced by Azure AD group membership, which Power BI reads
- The database is the single source of truth throughout the entire flow

---

## PART 2 — The People Involved: Roles

```mermaid
flowchart LR
    subgraph USERS["👥 Human Roles in Sakura"]
        U["👤 Regular User\n\n• Submit permission requests\n• View own request status\n• Approve requests assigned to them\n• Receive email notifications"]
        AP["🔑 Approver\n\n• Receive approval emails\n• Review requests on portal\n• Approve or Reject\n• Can approve via email link\n• Can batch approve"]
        SA["🛠️ Support Admin\n\n• Everything Regular User can do\n• Create requests on behalf of others\n• Manage email queue\n• Troubleshoot issues\n• Assist with request management"]
        ADM["⚙️ Administrator\n\n• Full system access\n• Manage approvers per scope\n• Manage LoVs and settings\n• Batch revoke requests\n• Export data to Excel\n• View ALL requests\n• Append approvers\n• Manage email templates"]
    end

    U -->|"can become"| AP
    AP -->|"elevated to"| SA
    SA -->|"elevated to"| ADM
```

**Key point:** A single person can wear multiple hats. A user who is also listed as an approver for their own scope gets **auto-approved** the moment they submit — no waiting required.

---

## PART 3 — The System Components: What Runs Where

```mermaid
flowchart TB
    subgraph AZURE_VM["🖥️ Azure Virtual Machine  (Dentsu Azure Cloud — VPN Only)"]
        PORTAL["🌸 Sakura Portal\nGAPTEQ Web App\nRuns on IIS\nHTML5 + .NET"]
        EMAIL_APP["📬 EmailDispatcher\nSakura.Toolbox.EmailDispatcher.exe\n.NET 6.0 Console App\nRuns every 5 minutes via Task Scheduler"]
        SYNC["🔄 SakuraADSync.ps1\nPowerShell Script\nRuns on schedule via Task Scheduler\nNeeds Group.ReadWrite.All permission"]
    end

    subgraph AZURE_DB["🗄️ Azure SQL Database"]
        DB["SQL Server\nazeuw1senmastersvrdb01\nDatabase: Sakura\n\nStores: Requests, Approvals,\nEmails, Audit Logs,\nReference Data, Config"]
    end

    subgraph MICROSOFT_CLOUD["☁️ Microsoft Cloud"]
        AAD["🏢 Azure Active Directory\nSecurity Groups\nUser identity & group membership"]
        GRAPH["🔌 Microsoft Graph API\nHow the sync script\nreads and writes Azure AD"]
        PBI["📊 Power BI Service\nReads group membership\nfrom Azure AD to enforce\nreport access"]
    end

    subgraph EXTERNAL["🌐 External Systems"]
        SENSEI["📦 Sensei\nSource of reference data\n(Clients, Cost Centers,\nEntities, Service Lines)"]
        ADF["⚙️ Azure Data Factory\nPipeline: P_ALL_SAKURA_D_Automation\nMoves data from Sensei to Sakura DB"]
        SMTP["📮 SMTP Relay\ninternalsmtprelay.media.global.loc:25\nActual email delivery (no auth)"]
    end

    PORTAL <-->|"Read/Write via\nStored Procedures"| DB
    EMAIL_APP <-->|"Read unsent emails\nMark as sent"| DB
    SYNC <-->|"Read desired state\nWrite audit events"| DB
    SYNC <-->|"Add/Remove\ngroup members"| GRAPH
    GRAPH <-->|"Manages"| AAD
    AAD -->|"Enforces access"| PBI
    EMAIL_APP -->|"Sends emails"| SMTP
    SENSEI -->|"Raw data"| ADF
    ADF -->|"Loads into\nstaging tables"| DB
```

**What to remember:**
- Everything lives on one VM behind the VPN — portal, EmailDispatcher, and sync script all co-exist
- The database is the hub — every component reads from or writes to it
- The sync script is the **only** thing that touches Azure AD — nothing else does

---

## PART 4 — The Data Model: Key Tables and How They Connect

```mermaid
erDiagram
    PermissionHeader {
        int RequestId PK
        string RequestCode
        string RequestedFor
        string RequestedBy
        int RequestType
        int ApprovalStatus
        string Approvers
        int ApplicationLoVId
        datetime RequestDate
        datetime ApprovedDate
        string ApprovedBy
    }

    PermissionOrgaDetail {
        int RequestId FK
        string EntityCode
        string ServiceLineCode
        string CostCenterCode
    }

    PermissionCPDetail {
        int RequestId FK
        string ClientCode
        string ProjectCode
    }

    ApproversOrga {
        int ApproverId PK
        string EntityCode
        string ServiceLineCode
        string CostCenterCode
        string ApproverUserName
        string DelegateUserName
    }

    ReportingDeckSecurityGroups {
        int ReportingDeckId FK
        int ApplicationLoVId
        string SecurityGroupName
        string SecurityGroupGUID
    }

    EventLog {
        bigint EventLogId PK
        string TableName
        int RecordId
        datetime EventTimestamp
        string EventName
        string EventDescription
        string EventTriggeredBy
    }

    Emails {
        bigint EmailId PK
        string To
        string Subject
        string Body
        int Status
        int NumberOfTries
        datetime DateCreated
        datetime DateSent
    }

    PermissionHeader ||--o{ PermissionOrgaDetail : "has detail"
    PermissionHeader ||--o{ PermissionCPDetail : "has detail"
    PermissionHeader ||--o{ EventLog : "generates events"
    PermissionHeader ||--o{ Emails : "triggers emails"
    ApproversOrga ||--o{ PermissionHeader : "approves"
    ReportingDeckSecurityGroups ||--o{ PermissionHeader : "maps to groups"
```

**What to remember:**
- `PermissionHeader` is the master record — one row per request
- Detail tables (OrgaDetail, CPDetail) hold the "what scope" information
- `ReportingDeckSecurityGroups` is the bridge from a request to an actual Azure AD group GUID
- `EventLog` and `Emails` are generated as side effects of every action

---

## PART 5 — Permission Types: What Can Users Request?

```mermaid
flowchart TD
    START["User opens New Request page"]
    START --> Q1{"What type\nof permission?"}

    Q1 -->|"Orga\nType = 0"| ORGA["🏢 Organisation Permission\n\nScope: Entity + ServiceLine + CostCenter\nExample: DACH + CXM + CXM Solutions\n\n✅ Syncs to Azure AD groups\n✅ Most common type"]

    Q1 -->|"Client Project\nType = 1"| CP["👔 Client Project Permission\n\nScope: Entity + Client + Project\nExample: DACH + Client ABC + Project X\n\n❌ Does NOT sync to main AD groups\nDifferent enforcement mechanism"]

    Q1 -->|"Cost Center\nType = 2"| CC["💰 Cost Center Permission\n\nScope: ServiceLine + CostCenter\nExample: CXM + Cost Center 1234\n\n✅ Syncs to Azure AD groups"]

    Q1 -->|"MSS\nType = 7"| MSS["📋 Master Service Set\n\nScope: MSS Code\nCollection of grouped services\n\n✅ Syncs to Azure AD groups"]

    Q1 -->|"SGM\nType = 5"| SGM["🔐 Security Group Manager\n\nScope: Security Group Code\nGroup-based access control\n\n❌ Different enforcement mechanism"]

    Q1 -->|"Reporting Deck\nType = 4"| RD["📊 Reporting Deck\n\nScope: Reporting Deck selection\nDirect deck access\n\n❌ Different enforcement mechanism"]

    Q1 -->|"Samurai\n(Dynamic)"| SAM["⚔️ Samurai Permission\n\nDynamic wizard combining\nOrga + CC + CP in one flow\nUser specifies scope on-the-fly\n\n✅ Combined type"]

    ORGA --> SYNC_NOTE["⭐ Only Types 0, 2, 7\nappear in\nRDSecurityGroupPermission\nview and sync to Azure AD\ngroup membership"]
    CC --> SYNC_NOTE
    MSS --> SYNC_NOTE
```

**Critical insight:** Only Orga (0), Cost Center (2), and MSS (7) feed into Azure AD group sync. If a user has a CP or SGM request approved, they will be added to the `EntireOrg` group (app-level access) but their specific group assignment works differently.

---

## PART 6 — The Full Request Lifecycle (State Machine)

```mermaid
stateDiagram-v2
    [*] --> Submitted : User clicks Submit

    Submitted --> Pending : CreateOrgaPermissionRequest runs\nInserts PermissionHeader\nApprovalStatus = 0\nEmails queued for requester + approvers

    Pending --> Approved : Approver clicks Approve\nApprovePermissionRequest runs\nApprovalStatus = 1\nApproval email queued

    Pending --> Rejected : Approver clicks Reject\nRejectPermissionRequest runs\nApprovalStatus = 2\nRejection email queued with reason

    Approved --> Revoked : Admin clicks Revoke\nRevokePermissionRequest runs\nApprovalStatus = 3\nRevocation email queued (if enabled)

    Pending --> AutoApproved : Requester IS the approver\nAuto-approval fires immediately\nNo email wait needed

    AutoApproved --> Approved : ApprovalStatus = 1\nimmediately

    Approved --> AzureADSynced : SakuraADSync.ps1 runs\nGroupMemberAdded logged\nUser added to Azure AD group

    AzureADSynced --> PowerBIAccess : Azure AD propagation (5-30 min)\nUser re-logs into Power BI\nAccess confirmed

    Revoked --> AzureADRemoved : SakuraADSync.ps1 runs\nGroupMemberRemoved logged\nUser removed from Azure AD group

    Rejected --> [*] : End state, no access granted
    AzureADRemoved --> [*] : User loses Power BI access

    note right of Pending
        ApprovalStatus = 0
        Waiting for human action
        Can be unblocked by:
        - Approving
        - Rejecting
        - Appending new approver
    end note

    note right of Approved
        ApprovalStatus = 1
        NOW appears in
        RDSecurityGroupPermission view
        Ready for next sync run
    end note
```

**What to remember:** Approval changes the database instantly. But Power BI access is NOT instant — it still needs the sync script to run, plus Azure AD propagation time.

---

## PART 7 — How Approvers Are Found (The Algorithm)

```mermaid
flowchart TD
    A["CreateOrgaPermissionRequest called\nwith: EntityCode, ServiceLineCode, CostCenterCode"]

    A --> B["Call FindApprovers\n(dispatcher procedure)"]

    B --> C{"What is\nRequestType?"}

    C -->|"0 or 2\nOrga / CC"| D["FindOrgaApprovers"]
    C -->|"1\nCP"| E["FindCPApprovers"]
    C -->|"7\nMSS"| F["FindMSSApprovers"]
    C -->|"5\nSGM"| G["FindSGMApprovers"]
    C -->|"4\nReportingDeck"| H["FindReportingDeckApprovers"]

    D --> I["fnFindOrgaApproversExact\n\nMatch on:\n• EntityLevel + EntityCode\n• ServiceLineCode\n• CostCenterLevel + CostCenterCode\n\nAgainst: ApproversOrga table"]

    I --> J{"Match\nfound?"}

    J -->|"Yes — exact match"| K["Return approver email(s)\nsemicolon-separated"]

    J -->|"No exact match"| L["Walk UP the hierarchy\n\nTry: Market level\nThen: Cluster level\nThen: Region level\nThen: Global level"]

    L --> M{"Match found\nat higher level?"}
    M -->|"Yes"| K
    M -->|"No — truly no approver"| N["Request created\nbut no approver\nEmail not sent\nRequest stays in Pending forever\n⚠️ Admin must investigate"]

    K --> O{"Is RequestedFor\nOR RequestedBy\nalready in approver list?"}

    O -->|"Yes"| P["🚀 AUTO-APPROVE\nApprovalStatus set to 1\nimmediately\nNo human action needed"]

    O -->|"No"| Q["Send email to approvers\nRequest waits in Pending\nApproval human-dependent"]
```

**What to remember:** If a request stays in Pending forever, the first thing to check is the `ApproversOrga` (or CP/MSS/SGM) table — there may be no approver configured for that scope combination.

---

## PART 8 — The Email Pipeline: How Notifications Reach Users

```mermaid
sequenceDiagram
    actor User
    participant Portal as Sakura Portal
    participant SP as Stored Procedure
    participant DB as SQL Database
    participant EQ as Emails Table
    participant ED as EmailDispatcher
    participant SMTP as SMTP Relay
    participant Inbox as User's Inbox

    User->>Portal: Submits permission request
    Portal->>SP: CreateOrgaPermissionRequest
    SP->>DB: Insert PermissionHeader (Status=0)
    SP->>SP: AddToEmailQueue
    SP->>SP: QueueEmail → ConstructEMail
    SP->>EQ: INSERT into Emails table (Status=0)
    Note over EQ: Email sits here waiting

    loop Every 5 minutes
        ED->>EQ: SELECT TOP 20 from EmailsToSend view
        EQ-->>ED: Returns unsent emails
        ED->>SMTP: Send via MailKit
        SMTP->>Inbox: Delivered
        ED->>DB: MarkEmailAsSent (Status=1)
    end

    Note over Inbox: User receives Request Confirmation email

    Inbox->>Portal: Approver logs in, reviews request
    Portal->>SP: ApprovePermissionRequest
    SP->>EQ: INSERT approval notification (Status=0)

    loop Every 5 minutes
        ED->>EQ: SELECT TOP 20 from EmailsToSend view
        ED->>SMTP: Send
        SMTP->>Inbox: Approval notification delivered
    end
```

**What to remember:**
- Emails are **never sent directly** by stored procedures — they are always queued first
- The EmailDispatcher is the only component that actually sends emails
- If EmailDispatcher stops running, emails pile up in the `Emails` table (Status=0) and users see nothing
- `EmailingMode = '0'` in ApplicationSettings disables all email sending

---

## PART 9 — The AD Sync: How Access Gets Enforced in Azure AD

```mermaid
flowchart TD
    subgraph DB["🗄️ SQL Database"]
        VIEW["RDSecurityGroupPermission VIEW\n\nReturns rows like:\nuser@dentsu.com → Group GUID ABC\nuser@dentsu.com → Group GUID XYZ\nother@dentsu.com → Group GUID ABC\n\nFILTERED TO:\n• ApprovalStatus = 1 only\n• RequestType 0, 2, 7 only\n• Non-null GUIDs only\n• ServiceLine code in group name"]
    end

    subgraph SCRIPT["🔄 SakuraADSync.ps1 (on Azure VM)"]
        S1["1. Connect to SQL Server\nQuery RDSecurityGroupPermission view"]
        S2["2. For each unique user email:\nCall Get-MgUser via Graph API\nMap email → Azure AD Object ID"]
        S3["3. For each unique group GUID:\nCall Get-MgGroup to verify it exists\nCall Get-MgGroupMemberAsUser to get\ncurrent members from Azure AD"]
        S4["4. COMPARE\nDesired (from view) vs Actual (Azure AD)\n\nTo ADD = in view but not in Azure AD\nTo REMOVE = in Azure AD but not in view\nNot Found = in view but user not in Azure AD"]
        S5["5. REMOVE extra members\nRemove-MgGroupMemberByRef\n(one API call per user)"]
        S6["6. ADD missing members\nUpdate-MgGroup with members@odata.bind\n(batched: 20 users per API call)"]
        S7["7. LOG to EventLog\nGroupMemberAdded\nGroupMemberRemoved\nGroupMemberNotAdded"]
        S8["8. SEND summary email\nTo: onur.ozturk@dentsu.com\nSubject: Sakura AD Sync Success/Failure\nBody: Err Count + Operations Count\nAttachment: log file"]
    end

    subgraph AZURE["☁️ Azure AD"]
        GRP["Security Group\ne.g. #SG-UN-SAKURA-CXM\n(GUID: abc-123-...)"]
    end

    VIEW --> S1
    S1 --> S2
    S2 --> S3
    S3 --> S4
    S4 --> S5
    S4 --> S6
    S5 --> S7
    S6 --> S7
    S7 --> S8
    S5 <-->|"Graph API calls\nNeed Group.ReadWrite.All"| GRP
    S6 <-->|"Graph API calls\nNeed Group.ReadWrite.All"| GRP
```

**Critical point about permissions:**

```mermaid
flowchart LR
    subgraph PERMISSION_LEVELS["Microsoft Graph Permission Levels"]
        L1["Level 1: Authentication\nConnect-MgGraph\n✅ Everyone can do this\nJust proves who you are"]
        L2["Level 2: Read\nGet-MgUser, Get-MgGroup\n✅ Most accounts can do this\nRead-only, low risk"]
        L3["Level 3: Write\nUpdate-MgGroup\nRemove-MgGroupMemberByRef\n❌ RESTRICTED\nNeeds Group.ReadWrite.All\nOnly specific accounts"]
    end

    L1 -->|"Does NOT mean"| L2
    L2 -->|"Does NOT mean"| L3

    FAIL["If your account lacks\nGroup.ReadWrite.All:\n\nConnect-MgGraph ✅ WORKS\nGet-MgUser ✅ WORKS\nGet-MgGroup ✅ WORKS\nUpdate-MgGroup ❌ 403 FORBIDDEN"]
```

---

## PART 10 — The Group Matching Logic: How a Request Maps to an Azure AD Group

This is one of the trickiest parts. Understanding this prevents a lot of confusion.

```mermaid
flowchart TD
    A["Approved Orga Request\nRequestedFor: user@dentsu.com\nApplicationLoVId: 9\nServiceLineCode: CXM\nEntityCode: DACH"]

    A --> B["RDSecurityGroupPermission view logic"]

    B --> C["JOIN to ServiceLine table\nGet all ServiceLine rows where\nSakuraPath LIKE '%|CXM|%'\n\nResult: ServiceLineCode = CXM"]

    C --> D["JOIN to ReportingDeckSecurityGroups\non ApplicationLoVId = 9"]

    D --> E["All groups for this application:\n#SG-UN-SAKURA-CXM       GUID: aaa-111\n#SG-UN-SAKURA-CXMBU     GUID: bbb-222\n#SG-UN-SAKURA-CXMCL     GUID: ccc-333\n#SG-UN-SAKURA-Media     GUID: ddd-444\n#SG-UN-SAKURA-EntireOrg GUID: eee-555"]

    E --> F{"For each group:\nDoes group name CONTAIN\nthe ServiceLine code CXM?"}

    F -->|"#SG-UN-SAKURA-CXM\nContains CXM? YES ✅"| G["Include this group"]
    F -->|"#SG-UN-SAKURA-CXMBU\nContains CXM? YES ✅"| G
    F -->|"#SG-UN-SAKURA-CXMCL\nContains CXM? YES ✅"| G
    F -->|"#SG-UN-SAKURA-Media\nContains CXM? NO ❌"| H["Skip this group"]
    F -->|"#SG-UN-SAKURA-EntireOrg\nSpecial rule: always include"| G

    G --> I["View returns:\nuser@dentsu.com → aaa-111\nuser@dentsu.com → bbb-222\nuser@dentsu.com → ccc-333\nuser@dentsu.com → eee-555"]

    I --> J["SakuraADSync.ps1 adds user\nto all 4 groups in Azure AD"]
```

**Why this matters for troubleshooting:** If a user is approved but not being added to a specific group, check whether that group's name in `ReportingDeckSecurityGroups` actually contains the ServiceLine code of the user's approved request.

---

## PART 11 — Power BI Access: The Last Mile

```mermaid
flowchart TD
    A["User is added to Azure AD group\n#SG-UN-SAKURA-CXM\nby SakuraADSync.ps1"]

    A --> B["⏱️ Azure AD propagation\n5 to 30 minutes\nAzure replicates the change\nacross its internal systems"]

    B --> C{"Has user\nre-logged into\nPower BI?"}

    C -->|"No — old session\ncached token"| D["❌ Power BI still denies access\nOld session token does not\nreflect new group membership"]

    C -->|"Yes — fresh login"| E["Power BI fetches\nfresh group memberships\nfrom Azure AD"]

    D --> F["✅ Fix: Ask user to\nSign out of Power BI\nSign back in\nRetry the report link"]

    E --> G{"Is user in\nthe group that\nPower BI workspace\nrequires?"}

    G -->|"Yes"| H["✅ User can OPEN the report\nLayer 1 cleared"]

    G -->|"No — wrong group\nor group not assigned\nto workspace"| I["❌ Access Denied\nPower BI workspace access\nmust be fixed by admin\nin Power BI Service"]

    H --> J{"RLS check:\nDoes user's approved scope\nin Sakura match the\nRLS rules in the report?"}

    J -->|"Yes — EntityCode,\nServiceLineCode match"| K["✅ User sees their\nscoped data\nFull access working"]

    J -->|"No — wrong scope\nor RLS misconfigured"| L["⚠️ User opens report\nbut sees NO DATA\nor WRONG DATA\n\nFix: Check approved scope\nin PermissionOrgaDetail\nRevoke and re-create if wrong"]
```

**The two layers explained simply:**
- **Layer 1 (Can they enter?)** — Azure AD group membership → managed by Sakura sync
- **Layer 2 (What can they see?)** — RLS rules in Power BI → driven by Sakura's approved scope data

---

## PART 12 — Where Reference Data Comes From (The Data Pipeline)

```mermaid
flowchart LR
    subgraph SENSEI["📦 Sensei\nExternal Source System"]
        S_CLIENT["Clients\n~96K records"]
        S_CC["Cost Centers\n~2,908 records"]
        S_ENTITY["Entities\n~1,497 records"]
        S_SL["Service Lines\n~21 records"]
    end

    subgraph ADF["⚙️ Azure Data Factory\nPipeline: P_ALL_SAKURA_D_Automation"]
        ADF_RUN["Runs on schedule\nFetches SQL queries\nfrom ProcessDB.dbo.BBONDataTransferSettings\nTransfers data to staging tables"]
    end

    subgraph STAGING["📥 Staging Tables\nSAKURA_Staging schema"]
        ST_CLIENT["SAKURA_Staging.Client"]
        ST_CC["SAKURA_Staging.CostCenter"]
        ST_ENTITY["SAKURA_Staging.Entity"]
        ST_SL["SAKURA_Staging.ServiceLine"]
    end

    subgraph LOAD_PROCS["⚙️ Load Stored Procedures\nRun after ADF completes"]
        LP1["sp_Load_Client\n\n1. Insert new records\n2. Resurrect returned records\n3. Mark deleted records\n4. Update changed records"]
        LP2["sp_Load_CostCenter"]
        LP3["sp_Load_Entity"]
        LP4["sp_Load_ServiceLine"]
    end

    subgraph PROD["✅ Production Tables\nSAKURA schema (used by portal + sync)"]
        P_CLIENT["SAKURA.Client"]
        P_CC["SAKURA.CostCenter"]
        P_ENTITY["SAKURA.Entity"]
        P_SL["SAKURA.ServiceLine"]
    end

    SENSEI --> ADF
    ADF --> STAGING
    ST_CLIENT --> LP1
    ST_CC --> LP2
    ST_ENTITY --> LP3
    ST_SL --> LP4
    LP1 --> P_CLIENT
    LP2 --> P_CC
    LP3 --> P_ENTITY
    LP4 --> P_SL
```

**What to remember:** If a new entity, cost center, or client appears in Sensei but is missing from Sakura's dropdowns, the ADF pipeline may not have run — or the `sp_Load_*` stored procedures may not have been executed after staging was populated.

---

## PART 13 — The Audit Trail: How to Investigate Anything

```mermaid
flowchart TD
    INCIDENT["🚨 Issue reported:\nUser cannot access Power BI report"]

    INCIDENT --> STEP1["STEP 1: Check if request is approved\n\nSELECT RequestId, ApprovalStatus\nFROM PermissionHeader\nWHERE RequestedFor = 'user@dentsu.com'\nORDER BY RequestDate DESC"]

    STEP1 --> Q1{"ApprovalStatus?"}

    Q1 -->|"0 = Pending"| FIX1["Request not yet approved\nCheck 'My Approvals' in portal\nOr check if approver received email\nOr append a new approver"]

    Q1 -->|"2 = Rejected"| FIX2["Request was rejected\nUser must submit a new request\nCheck rejection reason in EventLog"]

    Q1 -->|"3 = Revoked"| FIX3["Access was revoked\nUser must submit a new request\nCheck who revoked it in EventLog"]

    Q1 -->|"1 = Approved"| STEP2["STEP 2: Check desired state view\n\nSELECT * FROM RDSecurityGroupPermission\nWHERE RequestedFor = 'user@dentsu.com'"]

    STEP2 --> Q2{"Rows returned?"}

    Q2 -->|"No rows"| FIX4["Request approved but not in view\nCommon causes:\n• RequestType is CP/SGM/RD (not 0,2,7)\n• SecurityGroupGUID is NULL\n• ServiceLine not in group name\n• Wrong ApplicationLoVId"]

    Q2 -->|"Rows exist"| STEP3["STEP 3: Check if sync ran\n\nSELECT EventTimestamp, EventName, EventDescription\nFROM EventLog\nWHERE TableName = 'RDSecurityGroupPermission'\nAND EventDescription LIKE '%user@dentsu.com%'\nORDER BY EventTimestamp DESC"]

    STEP3 --> Q3{"GroupMemberAdded\nevent exists?"}

    Q3 -->|"No — sync\nnever ran or\nfailed for this user"| FIX5["Check if SakuraADSync.ps1 is scheduled\nCheck account has Group.ReadWrite.All\nCheck EventLog for GroupMemberNotAdded\n(means user not found in Azure AD)"]

    Q3 -->|"Yes — sync\ndid run"| STEP4["STEP 4: Azure AD + Power BI check\n\nAzure AD propagation: wait 15-30 min\nAsk user to:\n• Sign out of Power BI\n• Sign back in\n• Retry the link"]

    STEP4 --> Q4{"Still failing?"}

    Q4 -->|"Yes"| FIX6["Check Power BI workspace access:\nIs the Azure AD group assigned\nto that specific Power BI app/workspace?\n\nCheck RLS: Does user see blank data?\nIf so → scope mismatch in Sakura request"]

    Q4 -->|"No"| RESOLVED["✅ RESOLVED\nLog the fix in issue tracker"]
```

---

## PART 14 — Complete End-to-End Timeline (All Stages Together)

```mermaid
sequenceDiagram
    actor U as 👤 User
    participant P as 🌸 Portal
    participant DB as 🗄️ Database
    participant ED as 📬 EmailDispatcher
    actor APR as 🔑 Approver
    participant SYNC as 🔄 ADSync Script
    participant AAD as 🏢 Azure AD
    participant PBI as 📊 Power BI

    Note over U,PBI: T = 0: User submits request

    U->>P: Fill and submit New Request form
    P->>DB: CreateOrgaPermissionRequest SP runs
    DB->>DB: Insert PermissionHeader (Status=0)
    DB->>DB: Find approvers via FindApprovers
    DB->>DB: Queue emails in Emails table

    Note over ED: T+0 to T+5 min: EmailDispatcher runs

    ED->>DB: Read EmailsToSend view
    ED->>U: Send "Request Received" email
    ED->>APR: Send "Approval Needed" email
    ED->>DB: MarkEmailAsSent

    Note over APR: T+varies: Approver reviews

    APR->>P: Log in, see My Approvals page
    APR->>P: Click Approve
    P->>DB: ApprovePermissionRequest SP runs
    DB->>DB: ApprovalStatus = 1
    DB->>DB: Queue approval email
    ED->>U: Send "Request Approved" email

    Note over U: Request is now APPROVED in Sakura DB

    Note over SYNC: T+next schedule: Sync script runs

    SYNC->>DB: SELECT from RDSecurityGroupPermission
    DB-->>SYNC: user@dentsu.com → Group GUID abc-123
    SYNC->>AAD: Get-MgUser for user@dentsu.com
    AAD-->>SYNC: Azure AD Object ID returned
    SYNC->>AAD: Get-MgGroupMemberAsUser (current members)
    AAD-->>SYNC: Current member list
    SYNC->>AAD: Update-MgGroup (add user to group)
    AAD-->>SYNC: Success
    SYNC->>DB: Log GroupMemberAdded to EventLog

    Note over AAD: T+5 to 30 min: Azure AD propagates change

    Note over U: T+propagation+re-login: User tries report

    U->>PBI: Open Power BI report link
    PBI->>AAD: Check group membership
    AAD-->>PBI: User is in group #SG-UN-SAKURA-CXM
    PBI-->>U: ✅ Report opens

    PBI->>DB: RLS check — what scope is approved?
    DB-->>PBI: EntityCode=DACH, ServiceLine=CXM
    PBI-->>U: ✅ Shows data filtered to DACH + CXM scope
```

---

## PART 15 — Common Issues at a Glance

```mermaid
flowchart TD
    ISSUES["Common Issues\nand Where They Live"]

    ISSUES --> ISS1["📧 User not getting emails\n\nWhere to look:\n• Emails table: Status=0 pile-up?\n• ApplicationSettings: EmailingMode='0'?\n• Task Scheduler: EmailDispatcher running?\n• SMTP relay reachable?"]

    ISSUES --> ISS2["⏳ Request stuck in Pending\n\nWhere to look:\n• ApproversOrga: is there an approver\n  for this EntityCode + ServiceLineCode?\n• PermissionHeader.Approvers: is it empty?\n• Use Append Approver to unblock"]

    ISSUES --> ISS3["🔄 Sync ran but user not in Azure AD\n\nWhere to look:\n• EventLog: GroupMemberNotAdded?\n  (UPN mismatch)\n• RDSecurityGroupPermission:\n  does user appear at all?\n• ReportingDeckSecurityGroups:\n  is SecurityGroupGUID populated?"]

    ISSUES --> ISS4["📊 User in Azure AD but\ncannot access Power BI\n\nWhere to look:\n• Power BI workspace:\n  is the group assigned to it?\n• Azure AD propagation:\n  waited 15-30 min?\n• User re-logged into Power BI?"]

    ISSUES --> ISS5["📊 User opens report\nbut sees no data\n\nWhere to look:\n• This is RLS not access\n• PermissionOrgaDetail:\n  correct EntityCode + ServiceLineCode?\n• Revoke and re-create with\n  correct scope if wrong"]

    ISSUES --> ISS6["❌ Sync fails with 403 Forbidden\n\nWhere to look:\n• Account running SakuraADSync.ps1\n• Needs Group.ReadWrite.All permission\n• Connect-MgGraph succeeds\n  BUT write operations fail\n• Fix: use account with correct permission"]

    ISSUES --> ISS7["🔑 Reference data missing\nin portal dropdowns\n\nWhere to look:\n• SAKURA_Staging tables: data there?\n• ADF pipeline: ran recently?\n• sp_Load_* procedures: executed?\n• Check last load date in production tables"]
```

---

## PART 16 — Component Dependency: If X Breaks, What Else Breaks?

```mermaid
flowchart TD
    subgraph CRITICAL["🔴 Critical — Everything Stops"]
        SQL["SQL Database\n\nIf this goes down:\n• Portal cannot load\n• No requests can be created\n• EmailDispatcher cannot read queue\n• Sync script cannot read desired state\n• Complete outage"]
        AAD_AUTH["Azure AD Authentication\n\nIf this goes down:\n• No one can log into the portal\n• Complete user lockout"]
    end

    subgraph HIGH["🟠 High Impact — Access Enforcement Stops"]
        SYNC_FAIL["SakuraADSync.ps1 Fails\n\nIf this stops running:\n• Approved requests DO NOT\n  grant Azure AD access\n• Revoked requests DO NOT\n  lose Azure AD access\n• Everything in Sakura DB\n  is correct but not enforced\n• Existing access unchanged\n  until next successful run"]
        GRAPH_FAIL["Microsoft Graph API Down\n\nIf this is unavailable:\n• Sync script cannot modify groups\n• Same impact as sync failure"]
    end

    subgraph MEDIUM["🟡 Medium Impact — Notifications Stop"]
        EMAIL_FAIL["EmailDispatcher Stops\n\nIf this stops running:\n• Emails pile up (Status=0)\n• Users do not get notifications\n• Approvers do not get alerted\n• Requests still work\n• Backlog drains when service restarts"]
        SMTP_FAIL["SMTP Relay Down\n\nIf this is down:\n• EmailDispatcher retries endlessly\n• All emails stuck in queue\n• Same as above but\n  harder to detect"]
    end

    subgraph LOW["🟢 Low Impact — Partial Degradation"]
        ADF_FAIL["ADF Pipeline Stops\n\nIf this stops:\n• Reference data goes stale\n• New entities/clients/cost centers\n  do not appear in dropdowns\n• Existing requests and access\n  completely unaffected"]
        PBI_FAIL["Power BI Service Down\n\nIf this is down:\n• Users cannot view reports\n• Sakura itself is unaffected\n• Access configuration preserved"]
    end
```

---

## PART 17 — Quick Reference Card (Print-Friendly Summary)

```mermaid
flowchart LR
    subgraph WHAT["What is Sakura?"]
        W1["Permission management portal\nfor Power BI access control\nvia Azure AD group membership"]
    end

    subgraph WHO["Who uses it?"]
        WH1["Users — request access\nApprovers — grant/deny\nSupport Admins — assist\nAdmins — full control"]
    end

    subgraph WHERE["Where does data live?"]
        WR1["SQL DB: azeuw1senmastersvrdb01\nKey tables: PermissionHeader,\nRDSecurityGroupPermission view,\nEventLog, Emails"]
    end

    subgraph HOW["How does access work?"]
        H1["1. User requests in portal\n2. Approver approves\n3. Sync script reads view\n4. Sync adds user to Azure AD group\n5. Power BI reads group → access granted"]
    end

    subgraph TIMING["How long does it take?"]
        T1["Email: ~5 min\nApproval: human-dependent\nAD Sync: per schedule\nAzure AD propagation: 5-30 min\nTotal after approval: 15-60 min"]
    end

    subgraph DIAGNOSE["How to diagnose issues?"]
        D1["1. Check PermissionHeader (ApprovalStatus)\n2. Check RDSecurityGroupPermission view\n3. Check EventLog (GroupMemberAdded?)\n4. Check Azure AD propagation\n5. Check Power BI workspace access\n6. Check RLS if data missing"]
    end
```

---

## Glossary

| Term | Plain English Meaning |
|---|---|
| **Sakura** | The permission management portal for Power BI access control |
| **GAPTEQ** | The Low-Code web platform Sakura's portal UI is built on |
| **PermissionHeader** | The master database record for one permission request |
| **ApprovalStatus** | 0=Pending, 1=Approved, 2=Rejected, 3=Revoked |
| **RDSecurityGroupPermission** | The SQL view that computes "desired state" — who should be in which Azure AD group |
| **ReportingDeckSecurityGroups** | Maps Power BI apps + reporting decks to Azure AD group GUIDs |
| **SakuraADSync.ps1** | PowerShell script that syncs Sakura's desired state into Azure AD groups |
| **EmailDispatcher** | .NET app that reads the email queue and sends notifications via SMTP |
| **ApplicationLoVId** | A foreign key identifying which Power BI application a request is for |
| **ServiceLineCode** | Short code for a service line (e.g., "CXM") — embedded in Azure AD group names |
| **EventLog** | Immutable audit table — your first stop for all investigations |
| **Group.ReadWrite.All** | The Azure AD permission required to add/remove Azure AD group members |
| **Orga permission** | Organisation-scoped request (most common) — syncs to Azure AD groups |
| **CP permission** | Client Project-scoped request — does NOT sync via main view |
| **EntireOrg group** | `#SG-UN-SAKURA-EntireOrg` — every approved user is added here for app-level access |
| **RLS** | Row-Level Security — Power BI feature that filters data per user based on their approved scope |
| **Sensei** | External source system that feeds reference data (clients, entities, service lines) into Sakura |
| **ADF** | Azure Data Factory — the pipeline that moves data from Sensei to Sakura's staging tables |
| **LoV** | List of Values — predefined dropdown options stored in the LoV table |
| **Auto-approval** | When the requester is also the approver, the request approves itself immediately |
| **RequestBatchCode** | Groups multiple requests created together (e.g., bulk creation for a team) |

---

*This onboarding guide is designed to be read end-to-end on first encounter, and used as a reference afterwards. For detailed SQL queries and troubleshooting steps, see `Sakura_End_to_End_Complete_Guide.md`.*
