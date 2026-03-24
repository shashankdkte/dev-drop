###############################################################################
# Script Name: Add-UserToGroup.ps1
# Description:
#   Adds a single user to an Entra (Azure AD) security group via Microsoft
#   Graph using service principal (client secret) authentication.
#
#   Unlike SakuraV2ADSync.ps1, this script performs a targeted one-off add -
#   it does NOT diff or remove any existing members.
#
#   Default target group: #SG-UN-SAKURA-FINCOM
#   Object ID:            00f52f9a-df4b-4edd-a655-15ceafa8d5f0
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Users  -Scope CurrentUser
#   Install-Module Microsoft.Graph.Groups -Scope CurrentUser
#   Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
#
#   The Sakura app registration must have Application permissions granted
#   (admin consent) for:
#     - User.Read.All
#     - GroupMember.ReadWrite.All  (or Group.ReadWrite.All)
#   See: Docs/AD_SYNC_ENTRA_PERMISSIONS_SETUP.md
#
# Usage:
#   .\Add-UserToGroup.ps1 -UserEmail "firstname.lastname@dentsu.com"
#   .\Add-UserToGroup.ps1 -UserEmail "firstname.lastname@dentsu.com" -GroupObjectId "00f52f9a-df4b-4edd-a655-15ceafa8d5f0"
#
# WARNING - sync overwrite risk:
#   If SakuraV2ADSync.ps1 runs after this script and the user does not have
#   an approved OLS entry in [Auto].[OLSGroupMemberships] for this group,
#   the nightly sync will remove them. For a permanent add, ensure the user
#   also has an approved Sakura permission record.
###############################################################################

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$UserEmail,

    [Parameter()]
    [string]$GroupObjectId = "00f52f9a-df4b-4edd-a655-15ceafa8d5f0"
)

# ==============================================================================
# 1. CONFIGURATION - fill in ClientSecret before running
# ==============================================================================

$Config = @{

    # ---- Azure AD / Microsoft Graph (Service Principal) ----------------------
    TenantId     = "6e8992ec-76d5-4ea5-8eae-b0c5e558749a"
    ClientId     = "e73f4528-2ceb-40e3-8e4a-d72287adb4c5"
    ClientSecret = "TOKEN"          # never commit the real value

    # ---- SQL Server (Sakura V2 DB - for EventLog write) ----------------------
    SqlServer    = "azeuw1senmastersvrdb01.database.windows.net"
    SqlDatabase  = "SakuraV2"
    SqlUserId    = "SakuraAppAdmin"
    SqlPassword  = "Media+`$2023"

    # ---- Script identity (written to EventLog) ---------------------------------
    ScriptName   = "Add-UserToGroup.ps1"
}

# ==============================================================================
# 2. UTILITY FUNCTIONS
# ==============================================================================

function WriteLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [int]$Indent = 0
    )

    $ts     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = " " * $Indent
    Write-Output "`n[$ts][$Level]: $prefix$Message"
}

function PrintDivider {
    Write-Output "`n============================================================"
}

function Get-SqlConnection {
    $cs   = "Server=$($Config.SqlServer);Database=$($Config.SqlDatabase);Integrated Security=False;User Id=$($Config.SqlUserId);Password=$($Config.SqlPassword);"
    $conn = New-Object System.Data.SqlClient.SqlConnection($cs)
    return $conn
}

function Write-EventLogEntry {
    param(
        [string]$EventName,
        [string]$EventDescription
    )

    $conn = Get-SqlConnection
    $sql  = @"
INSERT INTO [dbo].[EventLog]
    (TableName, RecordId, EventTimestamp, EventName, EventDescription, EventTriggeredBy)
VALUES
    (@TableName, @RecordId, @EventTimestamp, @EventName, @EventDescription, @EventTriggeredBy)
"@

    $cmd = New-Object System.Data.SqlClient.SqlCommand($sql, $conn)
    $cmd.Parameters.AddWithValue("@TableName",        "OLSGroupMemberships") | Out-Null
    $cmd.Parameters.AddWithValue("@RecordId",         -1)                    | Out-Null
    $cmd.Parameters.AddWithValue("@EventTimestamp",   (Get-Date))            | Out-Null
    $cmd.Parameters.AddWithValue("@EventName",        $EventName)            | Out-Null
    $cmd.Parameters.AddWithValue("@EventDescription", $EventDescription)     | Out-Null
    $cmd.Parameters.AddWithValue("@EventTriggeredBy", $Config.ScriptName)    | Out-Null

    try {
        $conn.Open()
        $cmd.ExecuteNonQuery() | Out-Null
        WriteLog -Level "INFO" -Message "EventLog written: '$EventName'" -Indent 4
    }
    catch {
        WriteLog -Level "WARN" -Message "EventLog insert failed (non-fatal): $($_.Exception.Message)" -Indent 4
    }
    finally {
        $conn.Close()
    }
}

# ==============================================================================
# 3. START TRANSCRIPT
# ==============================================================================

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$logFile    = Join-Path -Path $scriptRoot -ChildPath "Add-UserToGroup_$timestamp.log"

try {
    Start-Transcript -Path $logFile -ErrorAction Stop
    WriteLog -Level "INFO" -Message "Transcript started: $logFile"
}
catch {
    Write-Host "ERROR: Could not start transcript: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

PrintDivider
WriteLog -Level "INFO" -Message "Add-UserToGroup.ps1 started"
WriteLog -Level "INFO" -Message "Target user:  $UserEmail"
WriteLog -Level "INFO" -Message "Target group: $GroupObjectId"

# ==============================================================================
# 4. IMPORT GRAPH MODULES
# ==============================================================================

foreach ($module in @("Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Groups")) {
    try {
        Import-Module $module -ErrorAction Stop
        WriteLog -Level "INFO" -Message "Imported module: $module"
    }
    catch {
        WriteLog -Level "ERROR" -Message "Failed to import '$module': $($_.Exception.Message)"
        Stop-Transcript
        exit 1
    }
}

# ==============================================================================
# 5. CONNECT TO MICROSOFT GRAPH (Service Principal - no interactive login)
# ==============================================================================

try {
    $secureSecret = ConvertTo-SecureString -String $Config.ClientSecret -AsPlainText -Force
    $credential   = New-Object System.Management.Automation.PSCredential($Config.ClientId, $secureSecret)

    Connect-MgGraph `
        -TenantId               $Config.TenantId `
        -ClientSecretCredential $credential `
        -NoWelcome `
        -ErrorAction            Stop

    $ctx = Get-MgContext
    if (-not $ctx) {
        WriteLog -Level "ERROR" -Message "Graph connection returned no context."
        Stop-Transcript
        exit 1
    }

    WriteLog -Level "INFO" -Message "Connected to Microsoft Graph. TenantId: $($ctx.TenantId) | AppId: $($ctx.ClientId)"
}
catch {
    WriteLog -Level "ERROR" -Message "Graph connection failed: $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

# ==============================================================================
# 6. RESOLVE EMAIL → ENTRA OBJECT ID
# ==============================================================================

WriteLog -Level "INFO" -Message "Resolving user: $UserEmail"

$adUser = $null
try {
    $adUser = Get-MgUser `
        -Filter   "userPrincipalName eq '$UserEmail' or mail eq '$UserEmail'" `
        -Property "id,userPrincipalName,displayName" `
        -Top      1 `
        -ErrorAction Stop
}
catch {
    WriteLog -Level "ERROR" -Message "Graph user lookup failed: $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

if (-not $adUser) {
    WriteLog -Level "ERROR" -Message "No Entra user found for '$UserEmail'. Aborting."
    Stop-Transcript
    exit 1
}

WriteLog -Level "INFO" -Message "Resolved '$UserEmail' -> Object ID: '$($adUser.Id)' | Display name: '$($adUser.DisplayName)'" -Indent 2

# ==============================================================================
# 7. FETCH GROUP AND VERIFY IT EXISTS
# ==============================================================================

WriteLog -Level "INFO" -Message "Fetching group: $GroupObjectId"

$adGroup = $null
try {
    $adGroup = Get-MgGroup -GroupId $GroupObjectId -ErrorAction Stop
    WriteLog -Level "INFO" -Message "Group resolved: '$($adGroup.DisplayName)'" -Indent 2
}
catch {
    WriteLog -Level "ERROR" -Message "Cannot fetch group '$GroupObjectId': $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

# ==============================================================================
# 8. CHECK IF USER IS ALREADY A MEMBER
# ==============================================================================

WriteLog -Level "INFO" -Message "Checking existing membership..."

$alreadyMember = $false
try {
    $existingMembers = Get-MgGroupMemberAsUser `
        -GroupId          $GroupObjectId `
        -ConsistencyLevel eventual `
        -All `
        -Property         "id" `
        -ErrorAction      Stop

    $alreadyMember = $existingMembers | Where-Object { $_.Id -eq $adUser.Id }
}
catch {
    WriteLog -Level "ERROR" -Message "Cannot fetch current members for '$($adGroup.DisplayName)': $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}

if ($alreadyMember) {
    WriteLog -Level "INFO" -Message "'$UserEmail' is already a member of '$($adGroup.DisplayName)'. Nothing to do."
    Write-EventLogEntry `
        -EventName        "GroupMemberAlreadyExists" `
        -EventDescription "User '$UserEmail' | Group '$($adGroup.DisplayName)' | Already a member - no action taken."
    Stop-Transcript
    exit 0
}

# ==============================================================================
# 9. ADD USER TO GROUP
# ==============================================================================

WriteLog -Level "INFO" -Message "Adding '$UserEmail' to '$($adGroup.DisplayName)'..." -Indent 2

try {
    $newMember = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($adUser.Id)" }
    New-MgGroupMember -GroupId $GroupObjectId -BodyParameter $newMember -ErrorAction Stop

    WriteLog -Level "INFO" -Message "Successfully added '$UserEmail' to '$($adGroup.DisplayName)'." -Indent 2

    Write-EventLogEntry `
        -EventName        "GroupMemberAdded" `
        -EventDescription "User '$UserEmail' (ID: $($adUser.Id)) | Group '$($adGroup.DisplayName)' (ID: $GroupObjectId) | Added successfully."
}
catch {
    WriteLog -Level "ERROR" -Message "Failed to add '$UserEmail': $($_.Exception.Message)" -Indent 2

    Write-EventLogEntry `
        -EventName        "GroupMemberNotAdded" `
        -EventDescription "User '$UserEmail' (ID: $($adUser.Id)) | Group '$($adGroup.DisplayName)' (ID: $GroupObjectId) | Error: $($_.Exception.Message)"

    Stop-Transcript
    exit 1
}

# ==============================================================================
# 10. DONE
# ==============================================================================

PrintDivider
WriteLog -Level "INFO" -Message "Completed. '$UserEmail' added to '$($adGroup.DisplayName)'."

try {
    Stop-Transcript
}
catch {
    $errMsg = $_.Exception.Message
    Write-Host "Warning: Stop-Transcript failed: $errMsg" -ForegroundColor Yellow
}
