# Sakura AD Sync — Deep Reference Guide

**Covers:** App Registration, Service Principal, Client Secrets, Microsoft Graph API,  
`SakuraADSync.ps1` (V1), `SakuraV2ADSync.ps1` (V2), add/remove logic, logging, scheduling, secret rotation.

---

## Table of Contents

1. [What Problem Does This Solve?](#1-what-problem-does-this-solve)
2. [Key Azure Concepts](#2-key-azure-concepts)
   - 2.1 [App Registration](#21-app-registration)
   - 2.2 [Service Principal (Enterprise Application)](#22-service-principal-enterprise-application)
   - 2.3 [Client Secret](#23-client-secret)
   - 2.4 [Application vs. Delegated Permissions](#24-application-vs-delegated-permissions)
   - 2.5 [Microsoft Graph API](#25-microsoft-graph-api)
3. [The Sakura App Registration — What Is In The Portal](#3-the-sakura-app-registration--what-is-in-the-portal)
4. [How Service Principal Authentication Works — Step By Step](#4-how-service-principal-authentication-works--step-by-step)
5. [V1 Script — SakuraADSync.ps1](#5-v1-script--sakuraadsyncps1)
   - 5.1 [Script Location and Structure](#51-script-location-and-structure)
   - 5.2 [Configuration Block](#52-configuration-block)
   - 5.3 [SQL Source of Truth](#53-sql-source-of-truth)
   - 5.4 [User Resolution (Email → Object ID)](#54-user-resolution-email--object-id)
   - 5.5 [The Diff Logic — Who to Add, Who to Remove](#55-the-diff-logic--who-to-add-who-to-remove)
   - 5.6 [Add Operation — Batching](#56-add-operation--batching)
   - 5.7 [Remove Operation](#57-remove-operation)
   - 5.8 [Logging — Transcript + SQL EventLog](#58-logging--transcript--sql-eventlog)
   - 5.9 [Email Notification](#59-email-notification)
6. [V2 Script — SakuraV2ADSync.ps1](#6-v2-script--sakurav2adsyncps1)
   - 6.1 [What Changed from V1](#61-what-changed-from-v1)
   - 6.2 [Source View: Auto.OLSGroupMemberships](#62-source-view-autoolsgroupmemberships)
7. [V1 vs. V2 — Side-By-Side Comparison](#7-v1-vs-v2--side-by-side-comparison)
8. [Why V1 Failed In Automation (And How It Is Fixed)](#8-why-v1-failed-in-automation-and-how-it-is-fixed)
9. [Required API Permissions — What Needs Admin Consent](#9-required-api-permissions--what-needs-admin-consent)
10. [How To Rotate The Client Secret](#10-how-to-rotate-the-client-secret)
11. [How To Schedule The Script](#11-how-to-schedule-the-script)
12. [End-To-End Flow Diagram](#12-end-to-end-flow-diagram)
13. [Troubleshooting Reference](#13-troubleshooting-reference)

---

## 1. What Problem Does This Solve?

Sakura is a permission management system. When a user is approved for access to a Power BI application (OLS — Object Level Security), that approval lives as a row in the Sakura SQL database.

But Power BI enforces OLS through **Azure AD (Entra) Security Group membership** — it does not read the Sakura database directly. So there is a gap:

```
Sakura DB says:  "john@dentsu.com is approved for App-X"
Azure AD says:   "The group for App-X has no members"
Power BI sees:   "John has no access"
```

The **AD Sync script** closes this gap. It runs nightly, reads the approved state from the Sakura DB, reads the current state from Azure AD, and makes them match — adding users who should be in groups but are not, and removing users who are in groups but should no longer be.

---

## 2. Key Azure Concepts

### 2.1 App Registration

An **App Registration** is how you register an application identity in Azure Active Directory (Entra ID). Think of it as creating a "robot account" that software (scripts, APIs, background services) can use to identify itself to Azure.

An App Registration gives you:

| What | Description |
|------|-------------|
| **Application (client) ID** | A GUID that uniquely identifies your app across all of Azure |
| **Directory (tenant) ID** | Which Azure AD tenant this app belongs to |
| **Client Secrets / Certificates** | Passwords (or certificates) the app uses to prove its identity |
| **API Permissions** | What the app is allowed to do (e.g. read users, manage groups) |
| **Redirect URIs** | Where Azure sends login responses (only relevant for interactive login) |

For Sakura, the App Registration is named **"Sakura"** and is shared by:
- The frontend SPA (user login via MSAL)
- The backend API (token validation)
- The AD Sync script (service principal authentication)
- Ronin EMEA integration

Each of these uses a **different client secret** — so rotating one does not break the others.

### 2.2 Service Principal (Enterprise Application)

The App Registration is a definition — a blueprint. The **Service Principal** is the live instance of that identity in a specific tenant. In the Azure portal it appears as the **Enterprise Application**.

```
App Registration  =  the class / blueprint
Service Principal =  the live instance in your tenant
```

When you browse to **Enterprise Applications > Sakura** in your portal, you are looking at the Service Principal. This is where:
- Permissions are granted/revoked
- Admin consent is applied
- Sign-in logs appear

The sync script authenticates **as the Service Principal** — it identifies itself using the ClientId (which Service Principal?) and ClientSecret (prove it's really you).

### 2.3 Client Secret

A client secret is a password string generated in the App Registration. It:
- Has a description, expiry date, and an opaque value you can only read once (at creation time)
- Is used by non-human processes to authenticate as the service principal
- Should be rotated before expiry

In your portal, the Sakura App Registration has four secrets:

| Description | Expires | Used By |
|-------------|---------|---------|
| ADSync (old) | 13/03/2026 | V1 SakuraADSync.ps1 (expiring — replace with new) |
| RoninEMEA | 06/05/2026 | Ronin EMEA integration |
| SPA | 11/08/2026 | Frontend SPA / Backend API authentication |
| ADSync (new) | 11/03/2028 | V1 SakuraADSync.ps1 (new — use this one) |

> **Important:** The secret value is only shown once — at the moment you create it. If you didn't copy it, you must create a new one. You cannot retrieve the value later, only the Secret ID (which is not the password).

### 2.4 Application vs. Delegated Permissions

This is the most critical distinction for understanding why the sync script must use a specific authentication pattern.

| | Delegated | Application |
|---|---|---|
| **Acts as** | A logged-in human user | The app/script itself (no user) |
| **Requires** | A browser popup / user sign-in session | Only ClientId + ClientSecret |
| **Can run scheduled/unattended** | No — blocks waiting for a user | Yes — fully automated |
| **Token scope** | Limited to what the user can do | Defined by admin-granted permissions |
| **Example permission** | User.Read (read your own profile) | User.Read.All (read any user's profile) |
| **Who grants access** | The user themselves | An Azure AD admin grants + consents for the whole org |

The V1 script originally used `Connect-MgGraph` with no parameters — this triggers **Delegated** (interactive browser) auth. It worked when you ran it manually from your own laptop (your user account's browser opened). It failed in Task Scheduler because there is no browser available in a scheduled context.

The fix (now in both scripts) is to use **Application** permissions with `ClientSecretCredential` — the script authenticates as the service principal itself, no human required.

### 2.5 Microsoft Graph API

Microsoft Graph (`graph.microsoft.com`) is Microsoft's unified REST API for Azure AD, Microsoft 365, Teams, and more. The sync script uses three Graph operations:

| Operation | PowerShell Cmdlet | Graph API Endpoint | What It Does |
|-----------|-------------------|--------------------|--------------|
| Look up a user | `Get-MgUser` | `GET /users?$filter=userPrincipalName eq '...'` | Resolve an email address to an Azure AD Object ID |
| Get group members | `Get-MgGroupMemberAsUser` | `GET /groups/{id}/members` | List all current members of an Entra security group |
| Add members (batch) | `Update-MgGroup` | `PATCH /groups/{id}` with `members@odata.bind` | Add up to 20 users to a group in one request |
| Remove a member | `Remove-MgGroupMemberByRef` | `DELETE /groups/{id}/members/{userId}/$ref` | Remove one user from a group |

---

## 3. The Sakura App Registration — What Is In The Portal

From the portal screenshots, the Sakura App Registration details are:

| Field | Value |
|-------|-------|
| Display name | Sakura |
| Application (client) ID | `e73f4528-2ceb-40e3-8efa-d72287adb4c5` |
| Directory (tenant) ID | `6e0092ec-76d5-4ea5-0eae-b065e558749a` |
| Object ID | `18d6962e-7cba-49a5-9cc5-b056805f0d30` |
| Supported account types | My organization only |
| State | Activated |

These are the values that go into `TenantId` and `ClientId` in both scripts.

The **API permissions** tab (App Registration) shows what the app is configured to request:

| Permission | Type | Status | Purpose |
|------------|------|--------|---------|
| `email` | Delegated | Granted | Frontend — read user email claim |
| `Group.Read.All` | Delegated | Granted | Frontend — read group info |
| `GroupMember.ReadWrite.All` | Delegated | **Not granted** | Needs admin consent for sync |
| `GroupMember.ReadAll` | Delegated | **Not granted** | Needs admin consent for sync |
| `openid` | Delegated | Granted | Frontend — OIDC login |
| `profile` | Delegated | Granted | Frontend — read profile |
| `User.Read` | Delegated | Granted | Frontend — read own user |
| `User.Read.All` | Delegated | Granted | Read any user |

> **Action needed:** For the sync script to work with Application (non-interactive) permissions, you need to add `Group.ReadWrite.All` and `User.Read.All` as **Application type** permissions (not Delegated), then click **"Grant admin consent for dentsu"**. The Delegated versions currently shown are for the frontend SPA, not the script.

---

## 4. How Service Principal Authentication Works — Step By Step

```
Step 1: Script builds credentials
──────────────────────────────────────────────────────────────
$secureSecret = ConvertTo-SecureString -String "bH58Q~..." -AsPlainText -Force
$credential   = New-Object PSCredential("e73f4528-...", $secureSecret)
  │
  │  PSCredential packs ClientId (username) + ClientSecret (password) together
  ▼

Step 2: Connect-MgGraph calls the Microsoft Identity Platform
──────────────────────────────────────────────────────────────
Connect-MgGraph -TenantId "6e0092ec-..." -ClientSecretCredential $credential
  │
  │  HTTP POST to: https://login.microsoftonline.com/6e0092ec-.../oauth2/v2.0/token
  │  Body:
  │    grant_type=client_credentials
  │    client_id=e73f4528-...
  │    client_secret=bH58Q~...
  │    scope=https://graph.microsoft.com/.default
  ▼

Step 3: Microsoft Identity Platform validates the request
──────────────────────────────────────────────────────────────
  • Does ClientId exist in tenant 6e0092ec?       ✓
  • Does the ClientSecret match?                   ✓
  • Is the service principal enabled/not expired?  ✓
  │
  │  Returns: OAuth2 access token (JWT, valid 1 hour)
  │  The token contains: app identity, tenant, granted scopes
  ▼

Step 4: All subsequent Graph calls use the token
──────────────────────────────────────────────────────────────
Get-MgUser -Filter "userPrincipalName eq 'john@dentsu.com'"
  │
  │  HTTP GET to: https://graph.microsoft.com/v1.0/users?$filter=...
  │  Header: Authorization: Bearer eyJ0eXAi...  (the token)
  │
  │  Graph checks: does this token have User.Read.All (Application)?
  │  If yes → returns user data
  ▼

Step 5: Token auto-refreshes when near expiry (handled by SDK)
```

---

## 5. V1 Script — SakuraADSync.ps1

**File:** `SakuraV1\Sakura_DB_Metadata\SakuraADSync.ps1`

### 5.1 Script Location and Structure

```
SakuraADSync.ps1
│
├── Section 0: Configuration ($GraphConfig block)
├── Section 1: Class definitions (RDSecurityGroupPermission, RDSecurityGroup)
├── Section 2: Utility functions (WriteToLog, PrintDivider, Get-SqlConnection,
│                                  Insert-EventLog, LogProcessResult)
├── Section 3: Start transcript / log file
├── Section 4: Main execution
│   ├── Import Graph modules
│   ├── Connect to Graph (service principal)
│   ├── Query SQL DB → $PermissionsFromSakura
│   ├── Resolve distinct users → $hashLookupDistinctUsers (email → ObjectId)
│   ├── Build distinct group list → $GroupsFromSakura
│   └── For each group:
│       ├── Fetch current AD members
│       ├── Diff (who to add, who to remove)
│       ├── Remove stale members (one by one)
│       └── Add missing members (batched, 20 per request)
└── Section 5: Stop transcript + send email
```

### 5.2 Configuration Block

```powershell
$GraphConfig = @{
    TenantId     = "YOUR_TENANT_ID"    # Directory (tenant) ID from App Registration Overview
    ClientId     = "YOUR_CLIENT_ID"    # Application (client) ID from App Registration Overview
    ClientSecret = "YOUR_CLIENT_SECRET" # Value of the new ADSync secret (expires 11/03/2028)
}
```

Fill in:
- `TenantId` → `6e0092ec-76d5-4ea5-0eae-b065e558749a`
- `ClientId` → `e73f4528-2ceb-40e3-8efa-d72287adb4c5`
- `ClientSecret` → the value you copied when creating the new ADSync secret (starts `bH58Q~OdmtfvokN-S_zkG34WLKNxEbT...`)

The SQL connection is in `Get-SqlConnection` (default parameters hardcoded):
```powershell
function Get-SqlConnection {
    param (
        [string]$Server   = "azeuw1tsenmastersvrdb01.database.windows.net",
        [string]$Database = "Sakura",
        [string]$UserId   = "SakuraAppAdmin",
        [string]$Password = "Media+`$2023"
    )
    ...
}
```

### 5.3 SQL Source of Truth

The script reads the **desired state** from:

```sql
SELECT [RequestedFor], [SecurityGroupName], [SecurityGroupGUID], [LastChangeDate]
FROM   [dbo].[RDSecurityGroupPermission]
```

Each row means: "The user in `RequestedFor` (an email address) should be a member of the Azure AD security group identified by `SecurityGroupGUID`."

`SecurityGroupGUID` is the Azure AD Object ID of the Entra Security Group — this is the GUID used in all Graph API calls.

The result is loaded into a `[System.Collections.ArrayList]` of `RDSecurityGroupPermission` objects:

```powershell
class RDSecurityGroupPermission {
    [string]$RequestedFor      # e.g. "john.smith@dentsu.com"
    [string]$SecurityGroupName # e.g. "Sakura-App-GI-AMER"
    [string]$SecurityGroupGUID # e.g. "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    [Nullable[DateTime]]$LastChangeDate
}
```

### 5.4 User Resolution (Email → Object ID)

Azure AD's group member management APIs work with **Object IDs** (GUIDs), not email addresses. The script must translate every unique email in `RequestedFor` to its Azure AD Object ID before it can add/remove anyone.

```powershell
# For each unique email in the permission list:
$ADUser = Get-MgUser `
    -Property "displayName,id,userPrincipalName" `
    -Filter "userPrincipalName eq '$email' or mail eq '$email'" `
    -Top 1

# Result cached in a hashtable: email → ObjectId
$hashLookupDistinctUsers["john@dentsu.com"] = @{
    ADUserId     = "11111111-2222-3333-4444-555555555555"
    RequestedFor = "john@dentsu.com"
}
```

**Why both `userPrincipalName` and `mail`?**  
Some accounts have different UPN and mail values (e.g. contractors, renamed accounts). Checking both ensures the user is found regardless of which attribute stores their Sakura email address.

**What happens if the user is not found?**  
They are logged as a warning (`GroupMemberNotAdded` event written to SQL EventLog) and skipped. Their Azure AD Object ID is `null`, which excludes them from the add batch.

### 5.5 The Diff Logic — Who to Add, Who to Remove

For each distinct group, the script performs a **set diff** using hashtables (O(1) lookups):

```
DESIRED STATE (from SQL)          CURRENT STATE (from Azure AD)
──────────────────────────        ──────────────────────────────
john@dentsu.com  (id: 1111)       member id: 1111  (john)
jane@dentsu.com  (id: 2222)       member id: 3333  (carol)
                                  member id: 4444  (bob — left company)
```

**Diff result:**
```
TO ADD:    2222 (jane)  — in desired, not in current AD
TO REMOVE: 3333 (carol) — in current AD, not in desired
           4444 (bob)   — in current AD, not in desired
```

The hashtable approach:

```powershell
# $hashSakuraGroupMembers   = desired state, keyed by ObjectId
# $hashCurrentADGroupMembers = current AD state, keyed by ObjectId

# TO REMOVE: in AD but not in desired
$MembersToRemove = $CurrentADGroupMembers | Where-Object {
    -not $hashSakuraGroupMembers.ContainsKey($_.Id)
}

# TO ADD: in desired but not in AD
$MembersToAdd = $CurrentSakuraGroupMembers | Where-Object {
    $_.ADUserId -ne $null -and -not $hashCurrentADGroupMembers.ContainsKey($_.ADUserId)
}
```

### 5.6 Add Operation — Batching

The Graph API allows adding up to **20 members in a single PATCH request** using the `members@odata.bind` property. The script batches adds accordingly:

```powershell
$batchSize       = 20
$numberOfBatches = [Math]::Ceiling($MembersToAdd.Count / $batchSize)

for ($i = 0; $i -lt $numberOfBatches; $i++) {
    $startIndex   = $i * $batchSize
    $endIndex     = [Math]::Min(($i + 1) * $batchSize, $MembersToAdd.Count) - 1
    $currentBatch = $MembersToAdd[$startIndex..$endIndex]

    $params = @{
        "members@odata.bind" = @()
    }
    foreach ($memberToAdd in $currentBatch) {
        $params["members@odata.bind"] += 
            "https://graph.microsoft.com/v1.0/directoryObjects/$($memberToAdd.ADUserId)"
    }

    Update-MgGroup -GroupId $sakuraGroupId -BodyParameter $params
}
```

**What this looks like as an HTTP request:**

```http
PATCH https://graph.microsoft.com/v1.0/groups/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
Authorization: Bearer eyJ0eXAi...
Content-Type: application/json

{
  "members@odata.bind": [
    "https://graph.microsoft.com/v1.0/directoryObjects/11111111-...",
    "https://graph.microsoft.com/v1.0/directoryObjects/22222222-...",
    ...up to 20...
  ]
}
```

If there are 45 users to add: Batch 1 = 20, Batch 2 = 20, Batch 3 = 5. Each batch is a separate HTTP request.

### 5.7 Remove Operation

Removals are done **one at a time** — the Graph API does not support batch removals:

```powershell
foreach ($member in $MembersToRemove) {
    Remove-MgGroupMemberByRef -GroupId $sakuraGroupId -DirectoryObjectId $member.Id
}
```

**What this looks like as an HTTP request:**

```http
DELETE https://graph.microsoft.com/v1.0/groups/{groupId}/members/{userId}/$ref
Authorization: Bearer eyJ0eXAi...
```

If there are 30 users to remove, that is 30 individual HTTP requests.

### 5.8 Logging — Transcript + SQL EventLog

**Layer 1 — PowerShell transcript file**

```powershell
$logFileName = Join-Path -Path $PSScriptRoot -ChildPath "output_20250312-203000.log"
Start-Transcript -Path $logFileName

# All Write-Output calls go to both console and the transcript file
WriteToLog -Level "INFO" -Message "Processing group: aaaaaaaa-..."
WriteToLog -Level "WARN" -Message "User 'x@dentsu.com' not found in AD"
WriteToLog -Level "ERROR" -Message "Failed to remove 'y@dentsu.com': Access denied"

Stop-Transcript
```

Example log output:
```
[2025-03-12 20:30:15][INFO]: Transcript started. Logging to: output_20250312-203015.log
[2025-03-12 20:30:16][INFO]: Connected to Microsoft Graph (service principal).
[2025-03-12 20:30:17][INFO]: Fetched 142 permission records from Sakura.
[2025-03-12 20:30:18][INFO]: Unique user count in Sakura permissions: 87
  [2025-03-12 20:30:19][INFO]:   Mapped 'john@dentsu.com' to AD UserID '11111111-...'
  [2025-03-12 20:30:19][WARN]:   No AD user found for 'old.user@dentsu.com'
[2025-03-12 20:30:20][INFO]: Processing Group: aaaaaaaa-... (Sakura-App-GI-AMER)
  [2025-03-12 20:30:21][INFO]:   Current AD member count: 45
  [2025-03-12 20:30:21][INFO]:   Desired members (from DB): 47
  [2025-03-12 20:30:21][INFO]:   Members to Remove: 1
    [2025-03-12 20:30:22][INFO]:     Removed 'carol@dentsu.com'
  [2025-03-12 20:30:22][INFO]:   Members to Add: 3
  [2025-03-12 20:30:22][INFO]:   Processing additions in 1 batch(es).
    [2025-03-12 20:30:23][INFO]:     Processing Batch #1 with 3 members.
      [2025-03-12 20:30:24][INFO]:       Batch #1 added successfully.
      [2025-03-12 20:30:24][INFO]:       Added member 'jane@dentsu.com'
```

**Layer 2 — SQL EventLog table**

Every significant operation writes a row to `dbo.EventLog` in the Sakura database:

```sql
-- Schema of EventLog (V1)
INSERT INTO [dbo].[EventLog] (
    TableName,          -- "RDSecurityGroupPermission"
    RecordId,           -- -1 (not record-specific)
    EventTimestamp,     -- exact datetime of the operation
    EventName,          -- "GroupMemberAdded" / "GroupMemberRemoved" / "GroupMemberNotAdded"
    EventDescription,   -- "User 'john@dentsu.com' to Group 'Sakura-App-GI', Success!"
    EventTriggeredBy    -- "SakuraADSync.ps1"
)
```

This allows the Sakura application itself to surface sync history, and provides a permanent audit trail independent of the log file (which may be deleted or rotated).

### 5.9 Email Notification

After every run, the script sends a summary email with the log file attached:

```powershell
$subject = if (($errcount -eq 0) -and ($opcount -gt 0)) {
    "[Sakura AD Sync - TEST]: Success"
} else {
    "[Sakura AD Sync - TEST]: Failure"
}
$body = "Err Count: $($errcount) - Operations Count: $($opcount)"
# Log file ($logFileName) is attached
# Sent via SMTP relay: internalsmtprelay.media.global.loc:25
# From: sakurahelp@dentsu.com
# To:   onur.ozturk@dentsu.com
```

---

## 6. V2 Script — SakuraV2ADSync.ps1

**File:** `BE_Main\SakuraV2ADSync.ps1`

### 6.1 What Changed from V1

V2 was built from scratch with service principal auth as a first-class requirement. Key improvements:

| Aspect | V1 | V2 |
|--------|----|----|
| Auth | Interactive (`Connect-MgGraph` no params) → **broken in automation** | Service principal (`ClientSecretCredential`) → works unattended |
| Config | Hardcoded in function default params | Unified `$Config` hashtable at the top |
| SQL source | `dbo.RDSecurityGroupPermission` | `Auto.OLSGroupMemberships` view |
| Column name for group | `SecurityGroupGUID` | `EntraGroupUID` |
| Column name for user | `RequestedFor` | `RequestedFor` (same) |
| User lookup cache | `$hashLookupDistinctUsers` (hashtable of PSCustomObject) | `$userIdMap` (simple email → ObjectId hashtable) |
| Logging function | `WriteToLog` | `WriteLog` |
| EventLog function | `Insert-EventLog` + `LogProcessResult` | `Write-EventLogEntry` + `Log-SyncEvent` |
| Target DB | `Sakura` (V1 DB) | `SakuraV2` |
| Add batching | 20 per batch | 20 per batch (same) |
| Remove | One at a time | One at a time (same) |

### 6.2 Source View: Auto.OLSGroupMemberships

V2 reads from a SQL view that encapsulates all the business logic of who should be in which group:

```sql
SELECT [RequestedFor], [EntraGroupUID], [LastChangeDate]
FROM   [Auto].[OLSGroupMemberships]
```

This view joins permission requests, approval states, OLS application settings (Managed vs. NotManaged), audience-to-Entra-group mappings, and active user status. The script does not need to know any of this — it just reads the view and trusts it as the desired state.

For **Managed apps** (OLSMode = 0), the view outputs rows. For **NotManaged apps** (OLSMode = 1), the view excludes them — those apps manage their own group membership.

---

## 7. V1 vs. V2 — Side-By-Side Comparison

```
V1: SakuraADSync.ps1                 V2: SakuraV2ADSync.ps1
─────────────────────────────────    ─────────────────────────────────
Database: Sakura (V1)                Database: SakuraV2
Source: dbo.RDSecurityGroupPerm...   Source: Auto.OLSGroupMemberships
Group ID column: SecurityGroupGUID   Group ID column: EntraGroupUID
Auth: (was interactive, now fixed)   Auth: ClientSecretCredential
Config block: $GraphConfig           Config block: $Config (includes SQL+email)
Log function: WriteToLog             Log function: WriteLog
EventLog fn: Insert-EventLog         EventLog fn: Write-EventLogEntry
```

Both scripts implement **identical add/remove logic** — the diff algorithm is the same, batching (20 per PATCH) is the same, individual DELETEs for removes is the same.

---

## 8. Why V1 Failed In Automation (And How It Is Fixed)

**Original V1 authentication:**
```powershell
Connect-MgGraph   # no parameters
```

This line opens a browser window asking the user to log in. In an interactive session (you at your laptop), this works — your browser pops up, you sign in, Graph gets a delegated token on your behalf.

In **Task Scheduler** or **Azure DevOps Pipeline**, there is no browser, no user session. The command blocks indefinitely waiting for a browser that never opens. The script hangs and eventually times out.

There was also a second problem: even when run interactively, the user account running the script (`AP-MEDIA\sdhaka01`) would have needed `GroupMember.ReadWrite.All` delegated permission consented for them — which they did not have.

**The fix (now in both scripts):**
```powershell
$secureSecret = ConvertTo-SecureString -String $GraphConfig.ClientSecret -AsPlainText -Force
$credential   = New-Object PSCredential($GraphConfig.ClientId, $secureSecret)
Connect-MgGraph -TenantId $GraphConfig.TenantId -ClientSecretCredential $credential -NoWelcome
```

The script now authenticates **as the service principal itself** (not as a user). No browser. No human. The service principal has `Group.ReadWrite.All` and `User.Read.All` Application permissions, which an admin consented to for the whole organisation.

---

## 9. Required API Permissions — What Needs Admin Consent

For the sync script to work fully, the **Sakura App Registration** needs these **Application** (not Delegated) permissions with admin consent granted:

| Permission | Type | Why |
|------------|------|-----|
| `User.Read.All` | Application | Resolve user emails to Azure AD Object IDs |
| `Group.ReadWrite.All` | Application | Add and remove members from Entra security groups |

**How to add them (if not already present):**

1. Azure portal → **App registrations** → **Sakura**
2. Left menu → **API permissions**
3. Click **"+ Add a permission"** → **Microsoft Graph** → **Application permissions**
4. Search and select `User.Read.All` and `Group.ReadWrite.All`
5. Click **Add permissions**
6. Click **"Grant admin consent for dentsu"** (requires Global Admin or Privileged Role Admin)
7. Confirm both show green tick with **"Granted for dentsu"**

> Note: The Delegated permissions currently in the portal (`GroupMember.ReadWrite.All`, `User.Read.All` Delegated) are for the frontend SPA. Do not remove them — they are separate from the Application permissions the script needs.

---

## 10. How To Rotate The Client Secret

When a client secret expires (or is about to), you create a new one and update the script.

**Step 1: Create the new secret**
1. Azure portal → **App registrations** → **Sakura**
2. **Certificates & secrets** → **Client secrets** → **+ New client secret**
3. Description: `ADSync` (or `ADSync-2028` to version it)
4. Expiry: 24 months (or custom)
5. Click **Add**
6. **Immediately copy the Value** — it is only shown once

**Step 2: Update the V1 script**

Open `SakuraV1\Sakura_DB_Metadata\SakuraADSync.ps1`:
```powershell
$GraphConfig = @{
    TenantId     = "6e0092ec-76d5-4ea5-0eae-b065e558749a"
    ClientId     = "e73f4528-2ceb-40e3-8efa-d72287adb4c5"
    ClientSecret = "PASTE-NEW-SECRET-VALUE-HERE"   # ← update this line
}
```

**Step 3: Update the V2 script**

Open `BE_Main\SakuraV2ADSync.ps1`:
```powershell
$Config = @{
    ...
    ClientSecret = "PASTE-NEW-SECRET-VALUE-HERE"   # ← update this line
    ...
}
```

**Step 4: Test before deleting the old secret**

Run the script manually once and confirm it connects successfully:
```
[INFO]: Connected to Microsoft Graph (service principal).
```

**Step 5: Delete the old expired secret**

Back in the portal → **Certificates & secrets** → delete the old ADSync secret (13/03/2026).

**Security recommendation:** In production, store the secret in **Azure Key Vault** and retrieve it at runtime. This removes the secret from source code entirely:
```powershell
# Production pattern (Key Vault)
$ClientSecret = (Get-AzKeyVaultSecret -VaultName "sakura-kv" -Name "ADSync-ClientSecret").SecretValue `
    | ConvertFrom-SecureString -AsPlainText
```

---

## 11. How To Schedule The Script

### Option A: Azure DevOps Pipeline (Recommended)

1. Create a new pipeline (YAML) in Azure DevOps
2. Add a scheduled trigger:
```yaml
schedules:
  - cron: "30 20 * * *"   # 8:30 PM UTC daily
    displayName: Nightly AD Sync
    branches:
      include:
        - main
    always: true           # run even if no code changes
```
3. Add a PowerShell task:
```yaml
steps:
  - task: PowerShell@2
    inputs:
      filePath: 'SakuraV1/Sakura_DB_Metadata/SakuraADSync.ps1'
    env:
      CLIENT_SECRET: $(ADSyncClientSecret)   # pipeline secret variable — not hardcoded
```
4. In the pipeline's **Variables** settings, add `ADSyncClientSecret` as a **secret** variable with the client secret value
5. In the script, read it: `ClientSecret = $env:CLIENT_SECRET`

### Option B: Windows Task Scheduler

1. On a server that has network access to both the SQL Server and the internet
2. Task Scheduler → **Create Task**
3. **Triggers**: Daily at 8:30 PM
4. **Actions**: Start a program
   - Program: `powershell.exe`
   - Arguments: `-NonInteractive -ExecutionPolicy Bypass -File "C:\Scripts\SakuraADSync.ps1"`
5. **Run as**: a service account (does not need Graph permissions — those come from the client secret)
6. **Run whether user is logged on or not**: checked

---

## 12. End-To-End Flow Diagram

```
 ┌─────────────────────────────────────────────────────────────────────┐
 │                         NIGHTLY TRIGGER                             │
 │             (Task Scheduler / Azure DevOps Pipeline)                │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │                    SakuraADSync.ps1 STARTS                          │
 │   1. Start-Transcript → output_YYYYMMDD-HHmmss.log                 │
 │   2. Import Microsoft.Graph.Users, Microsoft.Graph.Groups           │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │                   AUTHENTICATE TO GRAPH                             │
 │   ClientId + ClientSecret → POST /oauth2/v2.0/token                │
 │   ← Access Token (JWT, 1 hour)                                      │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │               READ DESIRED STATE FROM SQL                           │
 │   SELECT RequestedFor, SecurityGroupGUID                            │
 │   FROM dbo.RDSecurityGroupPermission                                │
 │                                                                     │
 │   Result: 142 rows  → $PermissionsFromSakura                        │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │          RESOLVE EMAILS → AZURE AD OBJECT IDs                       │
 │   For each unique email in RequestedFor:                            │
 │     GET /users?$filter=userPrincipalName eq 'john@dentsu.com'       │
 │     Cache in $hashLookupDistinctUsers                               │
 │                                                                     │
 │   87 unique emails → 85 resolved, 2 not found (WARN + skip)        │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │            FOR EACH DISTINCT ENTRA GROUP (loop)                     │
 │                                                                     │
 │   ┌────────────────────────────────────────────────────────────┐   │
 │   │  GET /groups/{groupUID}  → group display name              │   │
 │   │  GET /groups/{groupUID}/members → current AD members       │   │
 │   │                                                            │   │
 │   │  DIFF:                                                     │   │
 │   │    TO REMOVE = currentAD  MINUS  desired (SQL)             │   │
 │   │    TO ADD    = desired(SQL) MINUS currentAD                │   │
 │   │                                                            │   │
 │   │  REMOVE loop (one at a time):                              │   │
 │   │    DELETE /groups/{id}/members/{userId}/$ref               │   │
 │   │    → write GroupMemberRemoved to SQL EventLog              │   │
 │   │                                                            │   │
 │   │  ADD loop (batches of 20):                                 │   │
 │   │    PATCH /groups/{id}  { "members@odata.bind": [...] }     │   │
 │   │    → write GroupMemberAdded to SQL EventLog                │   │
 │   └────────────────────────────────────────────────────────────┘   │
 └───────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │               FINALISE + NOTIFY                                     │
 │   Stop-Transcript                                                   │
 │   Send email (SMTP relay) with log file attached                    │
 │     Subject: [Sakura AD Sync]: Success / Failure                   │
 │     To: onur.ozturk@dentsu.com                                      │
 └─────────────────────────────────────────────────────────────────────┘
```

---

## 13. Troubleshooting Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `AADSTS7000215: Invalid client secret` | Secret expired or wrong value in script | Update `ClientSecret` in config block with new secret value |
| `AADSTS700016: Application not found in directory` | Wrong `ClientId` or `TenantId` | Verify against App Registration Overview page |
| `Insufficient privileges to complete the operation` | Application permissions not granted or no admin consent | Add `Group.ReadWrite.All` + `User.Read.All` Application permissions and grant admin consent |
| `Connect-MgGraph` opens a browser | Old code still uses `Connect-MgGraph` without parameters | Ensure the `$GraphConfig`/`-ClientSecretCredential` block is present and not commented out |
| User never gets added — no error | User email not found in Azure AD | Check WARN log: `No AD user found for '...'`. UPN or mail may not match |
| Group not found: `Request_ResourceNotFound` | `SecurityGroupGUID` in SQL is wrong/stale | Verify the GUID against the actual Entra group in Azure portal |
| Script hangs with no output | Modules not installed | Run: `Install-Module Microsoft.Graph.Users -Scope CurrentUser` and `Install-Module Microsoft.Graph.Groups -Scope CurrentUser` |
| Email not sent | SMTP relay unreachable from the machine running the script | Confirm the server running the script has access to `internalsmtprelay.media.global.loc:25` |
| `GroupMember.ReadWrite.All - Not granted for dentsu` | Admin consent not given for Application permission | Have a Global Admin click "Grant admin consent for dentsu" in API permissions |

---

*Last updated: March 2026 | Covers SakuraADSync.ps1 (V1) and SakuraV2ADSync.ps1 (V2)*
