# Sakura Internal Request Management System: Complete Functional Analysis

**Document Version:** 1.0  
**Generated:** 2025-01-XX  
**Purpose:** Comprehensive internal-functional explanation of how Sakura creates, processes, tracks, approves, rejects, and revokes requests  
**Scope:** Internal Sakura logic only - no UI descriptions, no external systems

---

## Executive Summary

This document provides a complete internal-functional explanation of Sakura's request management system. It focuses exclusively on **internal Sakura logic** - how the system internally creates, classifies, routes, validates, approves, rejects, and revokes permission requests. All explanations are from the system's perspective, describing internal state transitions, data flows, and business logic without reference to UI screens or external systems.

**Core Question Answered:** How does Sakura internally create a "correct request" and manage it end-to-end?

---

## Table of Contents

1. [Request Creation - Internal Origination](#1-request-creation---internal-origination)
2. [Request Classification - Internal Logic](#2-request-classification---internal-logic)
3. [Approver Identification - Internal Resolution](#3-approver-identification---internal-resolution)
4. [Stored Procedures - Purpose & Role](#4-stored-procedures---purpose--role)
5. [Request Lifecycle - Internal States](#5-request-lifecycle---internal-states)
6. [Rejection vs Revocation - Critical Differentiation](#6-rejection-vs-revocation---critical-differentiation)
7. [Data Handling - Internal Concepts](#7-data-handling---internal-concepts)
8. [Approver View vs Requester View - Internal Meaning](#8-approver-view-vs-requester-view---internal-meaning)
9. [Error & Guardrail Logic](#9-error--guardrail-logic)
10. [Complete Internal Flow - Step-by-Step Narrative](#10-complete-internal-flow---step-by-step-narrative)

---

## 1. Request Creation - Internal Origination

### 1.1 What Internally Triggers a Request

A request is internally triggered when a stored procedure of the form `Create*PermissionRequest` is invoked. The system does not distinguish between UI-initiated or programmatic requests - all requests enter the system through these stored procedures.

**Entry Points:**
- `CreateOrgaPermissionRequest` - Organizational permission requests
- `CreateCPPermissionRequest` - Client-Project permission requests
- `CreateMSSPermissionRequest` - Master Service Set permission requests
- `CreateSGMPermissionRequest` - Security Group Manager permission requests
- `CreateReportingDeckPermissionRequest` - Reporting Deck permission requests

### 1.2 Minimum Inputs Required

Internally, Sakura requires the following minimum inputs to create a request:

**Core Identity Fields:**
- `@RequestedFor` (nvarchar(4096)) - User email/UPN requesting access (supports semicolon-separated list for multiple users)
- `@RequestedBy` (nvarchar(510)) - User email/UPN who created the request
- `@RequestReason` (nvarchar(2048)) - Business justification

**Classification Fields:**
- `@RequestType` (nvarchar(100)) - Type identifier: '0'=Orga, '1'=CP, '2'=CC, '4'=Reporting Deck, '5'=SGM, '6'=DSR, '7'=MSS
- `@ApplicationLoVId` (int) - PowerBI application identifier

**Scoping Fields (Type-Dependent):**
- **Orga Requests:** `@EntityLevel`, `@EntityCode`, `@ServiceLineCode`, `@CostCenterLevel`, `@CostCenterCode`
- **CP Requests:** `@EntityLevel`, `@EntityCode`, `@ServiceLineCode`, `@ClientCode`, `@ProjectCode`
- **MSS Requests:** `@EntityLevel`, `@EntityCode`, `@MSSCode`
- **SGM Requests:** `@SecurityGroupCode`
- **Reporting Deck Requests:** `@ReportingDeckKey`

**Optional Fields:**
- `@Approvers` (nvarchar(4096)) - Pre-specified approvers (if provided, overrides automatic resolution)
- `@ParentBatchCode` (nvarchar(40)) - Groups related requests

### 1.3 How a Request is Uniquely Identified

Internally, Sakura generates unique identifiers through a multi-level system:

**Primary Identifier:**
- `RequestId` (int, identity) - Auto-generated primary key, system-assigned sequential integer

**Human-Readable Identifier:**
- `RequestCode` (nvarchar(40)) - Generated via sequence (e.g., "SPR0000001", "SPR0000002")
  - Format: "SPR" prefix + zero-padded sequential number
  - Generated from `RequestCodeSequence` sequence object

**Batch Grouping:**
- `RequestBatchCode` (nvarchar(40)) - Groups related requests created together
  - Generated via sequence (e.g., "BPR0000123")
  - All requests created in same procedure call share same batch code
  - Enables bulk operations and tracking related requests

**Uniqueness Guarantees:**
- `RequestId` is guaranteed unique (identity column)
- `RequestCode` is guaranteed unique (sequence-based)
- `RequestBatchCode` groups related requests but is not unique per request

### 1.4 How Sakura Distinguishes Request Types Internally

Sakura internally distinguishes request types through a combination of:

**1. RequestType Field:**
- Stored in `PermissionHeader.RequestType` as nvarchar(100)
- Values: '0'=Orga, '1'=CP, '2'=CC, '4'=Reporting Deck, '5'=SGM, '6'=DSR, '7'=MSS
- Determines which detail table is populated
- Determines which approver resolution logic is used
- Determines whether request appears in `RDSecurityGroupPermission` view

**2. Detail Table Association:**
- Each request type has a corresponding detail table:
  - Orga → `PermissionOrgaDetail`
  - CP → `PermissionCPDetail`
  - MSS → `PermissionMSSDetail`
  - SGM → `PermissionSGMDetail`
  - Reporting Deck → `PermissionReportingDeckDetail`
- The detail table stores type-specific scoping information
- One-to-one relationship: one header, one detail record per type

**3. Procedure-Based Routing:**
- Different create procedures handle different types
- Each procedure validates type-specific requirements
- Each procedure calls type-specific approver finders

**New Request vs Update Request vs Revocation Request:**

**New Request:**
- Created via `Create*PermissionRequest` procedures
- `RequestId` is NULL (auto-generated)
- `ApprovalStatus` is set to '0' (Pending)
- New records inserted into `PermissionHeader` and appropriate `Permission*Detail` table

**Update Request:**
- Sakura does **NOT** support updating existing requests internally
- Requests are immutable once created
- To change a request, a new request must be created and the old one revoked
- Historical integrity is maintained - original request remains in database

**Revocation Request:**
- Not a new request type - it's a state transition
- Invoked via `RevokePermissionRequest` procedure
- Operates on existing `RequestId`
- Changes `ApprovalStatus` from '1' (Approved) or '0' (Pending) to '3' (Revoked)
- Does not create new records - updates existing request

---

## 2. Request Classification - Internal Logic

### 2.1 How Requests are Classified Internally

Sakura classifies requests through a **multi-dimensional classification system**:

**Primary Classification Dimension: RequestType**
- Determined at creation time via `@RequestType` parameter
- Stored in `PermissionHeader.RequestType`
- Values: '0'=Orga, '1'=CP, '2'=CC, '4'=Reporting Deck, '5'=SGM, '6'=DSR, '7'=MSS

**Secondary Classification Dimensions:**

1. **Application Scope:**
   - `ApplicationLoVId` - Identifies which PowerBI application the request applies to
   - Stored in `PermissionHeader.ApplicationLoVId`
   - Determines which security groups are available

2. **Organizational Scope (Type-Dependent):**
   - **Orga:** EntityLevel, EntityCode, ServiceLineCode, CostCenterLevel, CostCenterCode
   - **CP:** EntityLevel, EntityCode, ServiceLineCode, ClientCode, ProjectCode
   - **MSS:** EntityLevel, EntityCode, MSSCode
   - **SGM:** SecurityGroupCode
   - **Reporting Deck:** ReportingDeckKey

3. **Approval Status:**
   - '0' = Pending
   - '1' = Approved
   - '2' = Rejected
   - '3' = Revoked

### 2.2 Classification Mechanism: Rule-Based, Metadata-Driven, or Stored-Procedure-Driven?

Sakura uses a **hybrid approach** combining all three:

**1. Rule-Based Classification:**
- RequestType determines which rules apply
- Approver rules in `Approvers*` tables are rule-based
- Matching logic uses exact and hierarchical matching

**2. Metadata-Driven Classification:**
- Reference data tables (Entity, ServiceLine, CostCenter, Client, MasterServiceSet) drive classification
- `LoV` table provides metadata for applications, request types, statuses
- `ApplicationSettings` table provides configuration-driven behavior

**3. Stored-Procedure-Driven Classification:**
- Each `Create*PermissionRequest` procedure enforces type-specific validation
- `FindApprovers` procedure routes to type-specific approver finders based on RequestType
- Classification logic is embedded in stored procedures

### 2.3 Internal Attributes That Determine Request Path

The following internal attributes determine how a request is processed:

**1. RequestType:**
- Determines which approver resolution procedure is called
- Determines whether request appears in `RDSecurityGroupPermission` view
- Determines which detail table stores scoping information

**2. ApprovalStatus:**
- '0' (Pending) → Eligible for approval/rejection
- '1' (Approved) → Appears in `RDSecurityGroupPermission` view (if RequestType matches)
- '2' (Rejected) → End state, no further processing
- '3' (Revoked) → Removed from desired state

**3. Organizational Scope:**
- EntityCode, ServiceLineCode, CostCenterCode, ClientCode, MSSCode
- Determines which approvers are matched
- Determines which security groups the request maps to (via ServiceLine matching)

**4. ApplicationLoVId:**
- Determines which security groups are available
- Used in `RDSecurityGroupPermission` view to filter `ReportingDeckSecurityGroups`

**5. RequestReason:**
- Special handling: Requests with `RequestReason LIKE 'SALES BULK%'` are excluded from `RDSecurityGroupPermission` view
- Business rule to exclude certain bulk operations

**6. Approvers List:**
- If `RequestedFor` or `RequestedBy` is in the `Approvers` list, request is auto-approved
- Determines notification recipients

---

## 3. Approver Identification - Internal Resolution

### 3.1 Step-by-Step Approver Identification Logic

Sakura determines approvers through a **hierarchical, type-specific resolution system**:

**Step 1: Dispatcher Routing**
- `FindApprovers` procedure receives request parameters
- Examines `@RequestType` parameter
- Routes to type-specific approver finder:
  - RequestType '0' or '2' → `FindOrgaApprovers`
  - RequestType '1' → `FindCPApprovers`
  - RequestType '7' → `FindMSSApprovers`
  - RequestType '5' → `FindSGMApprovers`
  - RequestType '4' → `FindReportingDeckApprovers`

**Step 2: Type-Specific Approver Matching**

**For Orga Requests (FindOrgaApprovers):**
1. Receives: `@RequestType`, `@ApplicationLovId`, `@EntityLevel`, `@EntityCode`, `@ServiceLineCode`, `@AccountCode`, `@ProfitCenterCode`, `@CostCenterLevel`, `@CostCenterCode`
2. Calls `fnFindOrgaApproversExact` function
3. Function queries `ApproversOrga` table
4. Matching logic:
   - Matches `ApplicationLoVId` (exact)
   - Matches `EntityLevel` and `EntityCode` (exact or hierarchical)
   - Matches `ServiceLineCode` (exact or hierarchical)
   - Matches `CostCenterLevel` and `CostCenterCode` (exact or hierarchical)
   - Supports wildcard matching (e.g., 'Global' EntityLevel matches all entities)
5. Checks `DelegateUserName` column for delegation
6. Returns semicolon-separated list of approver emails

**For CP Requests (FindCPApprovers):**
1. Receives: `@RequestType`, `@ApplicationLovId`, `@EntityLevel`, `@EntityCode`, `@ServiceLineCode`, `@ClientCode`, `@ProjectCode`
2. Calls `fnFindCPApproversExact` function
3. Function queries `ApproversCP` table
4. Matching logic:
   - Matches `ApplicationLoVId` (exact)
   - Matches `EntityLevel` and `EntityCode` (exact or hierarchical)
   - Matches `ServiceLineCode` (exact or hierarchical)
   - Matches `ClientCode` and `ProjectCode` (exact or wildcard '-ALL-')
5. Checks `DelegateUserName` column for delegation
6. Returns semicolon-separated list of approver emails

**For MSS Requests (FindMSSApprovers):**
1. Receives: `@RequestType`, `@ApplicationLovId`, `@EntityLevel`, `@EntityCode`, `@MSSCode`
2. Calls `fnFindMSSApproversExact` function
3. Function queries `ApproversMSS` table
4. Matching logic:
   - Matches `ApplicationLoVId` (exact)
   - Matches `EntityLevel` and `EntityCode` (exact or hierarchical)
   - Matches `MSSCode` (exact)
5. Checks `DelegateUserName` column for delegation
6. Returns semicolon-separated list of approver emails

**Step 3: Approver List Assembly**
- All matching approvers are collected
- Delegates (from `DelegateUserName`) are included if present
- Multiple approvers are semicolon-separated
- Result stored in `PermissionHeader.Approvers` column

### 3.2 Internal Factors Evaluated

**1. Request Type:**
- Determines which approver table to query
- Determines which matching function to use

**2. Scope of Request:**
- **Entity Scope:** EntityLevel, EntityCode (supports hierarchical matching)
- **ServiceLine Scope:** ServiceLineCode (supports hierarchical matching)
- **CostCenter Scope:** CostCenterLevel, CostCenterCode (for Orga requests)
- **Client/Project Scope:** ClientCode, ProjectCode (for CP requests)
- **MSS Scope:** MSSCode (for MSS requests)
- **SecurityGroup Scope:** SecurityGroupCode (for SGM requests)
- **ReportingDeck Scope:** ReportingDeckKey (for Reporting Deck requests)

**3. Role Mapping:**
- Approvers are mapped via `Approvers*` tables
- Each table row represents an approver rule
- Rules are scoped by organizational dimensions

**4. Hierarchy or Ownership:**
- Hierarchical matching supported:
  - 'Global' EntityLevel matches all entities
  - Parent Entity approvers can match child entities (via SakuraPath)
  - ServiceLine hierarchy traversal supported
- Ownership not explicitly tracked - matching is scope-based

**5. Application Context:**
- `ApplicationLoVId` must match between request and approver rule
- Different applications can have different approvers for same scope

### 3.3 Whether Approvers are Static, Derived, or Multi-Level

**Approvers are Derived:**
- Approvers are **not** statically assigned to requests
- Approvers are **derived** at request creation time via `FindApprovers` → type-specific finders
- Derived approvers are stored in `PermissionHeader.Approvers` column (semicolon-separated)
- If approver rules change after request creation, existing requests retain original approvers

**Multi-Level Support:**
- Sakura supports **multiple approvers per request** (semicolon-separated list)
- Multiple approver rules can match the same request scope
- All matching approvers are included in the approvers list
- **No explicit multi-level approval sequence** - any approver in the list can approve

**Delegation Support:**
- `DelegateUserName` column in `Approvers*` tables supports delegation
- If an approver has a delegate, the delegate can approve on their behalf
- Delegation is rule-based, not request-based

### 3.4 How Approval Sequence is Decided

**Sakura does NOT enforce a sequential approval sequence internally:**
- All approvers in the `Approvers` list have equal authority
- **Any** approver in the list can approve the request
- First approver to call `ApprovePermissionRequest` completes the approval
- No internal logic prevents multiple approvers from attempting to approve (though only first succeeds)

**Internal Approval Logic:**
- `ApprovePermissionRequest` validates:
  1. Request exists
  2. Request is in Pending status (`ApprovalStatus = '0'`)
  3. Approver is in the `Approvers` list (semicolon-separated matching)
- If all validations pass, request is approved
- No sequential ordering or multi-step approval workflow enforced

---

## 4. Stored Procedures - Purpose & Role

### 4.1 Request Creation Procedures

**CreateOrgaPermissionRequest:**
- **Purpose:** Creates an Organizational (Orga) permission request
- **Internal Responsibility:**
  - Validates input parameters (approvers, requested for, reason, scope)
  - Generates `RequestBatchCode` via sequence
  - Loops through `@RequestedFor` list (supports multiple users)
  - Checks for duplicate requests (same user, type, scope, application, pending/approved)
  - Inserts `PermissionHeader` record (ApprovalStatus = '0')
  - Inserts `PermissionOrgaDetail` record with scoping details
  - Validates CostCenter against Entity/ServiceLine via `fnGetCostCenterListWithContextFilter`
  - Calls `FindOrgaApprovers` to determine approvers
  - Calls `AddToEventLog` (RequestCreated event)
  - Calls `AddToEmailQueue` (notify requester)
  - Auto-approves if requester/requested-for is in approvers list
  - Otherwise calls `AddToEmailQueue` (notify approvers)
- **When Invoked:** During request creation
- **State Transitions:** None → Pending ('0')

**CreateCPPermissionRequest:**
- **Purpose:** Creates a Client-Project (CP) permission request
- **Internal Responsibility:** Similar to CreateOrgaPermissionRequest, but with Client/Project scoping instead of CostCenter
- **When Invoked:** During request creation
- **State Transitions:** None → Pending ('0')

**CreateMSSPermissionRequest:**
- **Purpose:** Creates a Master Service Set (MSS) permission request
- **Internal Responsibility:** Similar to CreateOrgaPermissionRequest, but with MSS scoping
- **When Invoked:** During request creation
- **State Transitions:** None → Pending ('0')

**CreateSGMPermissionRequest:**
- **Purpose:** Creates a Security Group Manager (SGM) permission request
- **Internal Responsibility:** Similar to CreateOrgaPermissionRequest, but with SecurityGroupCode scoping
- **When Invoked:** During request creation
- **State Transitions:** None → Pending ('0')

**CreateReportingDeckPermissionRequest:**
- **Purpose:** Creates a Reporting Deck permission request
- **Internal Responsibility:** Simpler logic - no auto-approval, no email to approvers
- **When Invoked:** During request creation
- **State Transitions:** None → Pending ('0')

### 4.2 Approval Procedures

**ApprovePermissionRequest:**
- **Purpose:** Approves a permission request
- **Internal Responsibility:**
  - Validates request exists and is in Pending status
  - Validates approver is in approvers list
  - Updates `PermissionHeader`: `ApprovalStatus = '1'`, `ApprovedBy`, `ApprovedDate`
  - Calls `AddToEventLog` (PermissionRequestApproved event)
  - Calls `AddToEmailQueue` (notify requester of approval)
- **When Invoked:** During approval (by approver or auto-approval)
- **State Transitions:** Pending ('0') → Approved ('1')

**RejectPermissionRequest:**
- **Purpose:** Rejects a permission request
- **Internal Responsibility:**
  - Validates request exists and is in Pending status
  - Validates approver is in approvers list
  - Updates `PermissionHeader`: `ApprovalStatus = '2'`, `RejectedBy`, `RejectedDate`, `RejectReason`
  - Calls `AddToEventLog` (PermissionRequestRejected event)
  - Calls `AddToEmailQueue` (notify requester of rejection)
- **When Invoked:** During rejection (by approver)
- **State Transitions:** Pending ('0') → Rejected ('2')

**RevokePermissionRequest:**
- **Purpose:** Revokes an approved or pending permission request
- **Internal Responsibility:**
  - Validates request is Approved ('1') or Pending ('0')
  - Updates `PermissionHeader`: `ApprovalStatus = '3'`
  - Calls `AddToEventLog` (PermissionRequestRevoked event)
  - Conditionally calls `AddToEmailQueue` (if `CreatePermissionRevokedEmails` setting is '1')
- **When Invoked:** During revocation (by administrator)
- **State Transitions:** Approved ('1') or Pending ('0') → Revoked ('3')

**AppendApproverToPermissionRequest:**
- **Purpose:** Adds an approver to a pending request
- **Internal Responsibility:**
  - Validates request is Pending
  - Checks approver not already in list
  - Appends to `Approvers` column (semicolon-separated)
  - Calls `AddToEventLog` (ApproverAppended event)
  - Calls `AddToEmailQueue` (notify new approver)
- **When Invoked:** During request modification (adding approvers)
- **State Transitions:** None (request remains Pending)

**BatchChangeStatusPermissionRequests:**
- **Purpose:** Batch approve/reject/revoke multiple requests
- **Internal Responsibility:**
  - Loops through provided request IDs
  - Calls appropriate status change procedure (ApprovePermissionRequest, RejectPermissionRequest, or RevokePermissionRequest)
  - Aggregates results
- **When Invoked:** During bulk operations
- **State Transitions:** Varies based on operation type

### 4.3 Approver Resolution Procedures

**FindApprovers:**
- **Purpose:** Dispatcher that routes to type-specific approver finders
- **Internal Responsibility:**
  - Examines `@RequestType` parameter
  - Routes to appropriate type-specific finder
  - Returns semicolon-separated list of approver emails
- **When Invoked:** During request creation (by Create*PermissionRequest procedures)
- **State Transitions:** None (read-only operation)

**FindOrgaApprovers:**
- **Purpose:** Finds approvers for Orga requests
- **Internal Responsibility:**
  - Uses `fnFindOrgaApproversExact` function
  - Matches against `ApproversOrga` table
  - Supports hierarchical matching (Entity, ServiceLine, CostCenter)
  - Supports delegation via `DelegateUserName` column
  - Returns semicolon-separated list of approver emails
- **When Invoked:** During request creation (via FindApprovers dispatcher)
- **State Transitions:** None (read-only operation)

**FindCPApprovers, FindMSSApprovers, FindSGMApprovers, FindReportingDeckApprovers:**
- **Purpose:** Type-specific approver finders
- **Internal Responsibility:** Similar to FindOrgaApprovers, but with type-specific matching logic
- **When Invoked:** During request creation (via FindApprovers dispatcher)
- **State Transitions:** None (read-only operation)

### 4.4 Conceptual Explanation of Key Logic

**Request Validation Logic:**
- **Duplicate Detection:** Checks for existing requests with same `RequestedFor`, `RequestType`, scope (EntityCode, ServiceLineCode, etc.), `ApplicationLoVId`, and `ApprovalStatus` IN ('0', '1')
- **CostCenter Validation:** For Orga requests, validates CostCenter belongs to specified Entity and ServiceLine via `fnGetCostCenterListWithContextFilter`
- **Parameter Validation:** Ensures required parameters are provided and non-null
- **Reference Data Validation:** Validates EntityCode, ServiceLineCode, etc. exist in reference data tables

**Approval Progression Logic:**
- **Status Check:** Request must be in Pending ('0') status
- **Approver Authorization:** Approver must be in the `Approvers` list
- **State Update:** Updates `ApprovalStatus` to '1', sets `ApprovedBy` and `ApprovedDate`
- **Audit Logging:** Logs approval event to `EventLog`
- **Notification:** Queues email to requester

**Rejection Handling:**
- **Status Check:** Request must be in Pending ('0') status
- **Approver Authorization:** Approver must be in the `Approvers` list
- **State Update:** Updates `ApprovalStatus` to '2', sets `RejectedBy`, `RejectedDate`, and `RejectReason`
- **Audit Logging:** Logs rejection event to `EventLog`
- **Notification:** Queues email to requester
- **End State:** Rejection is final - request cannot be re-approved

**Revocation Rollback Handling:**
- **Status Check:** Request must be in Approved ('1') or Pending ('0') status
- **State Update:** Updates `ApprovalStatus` to '3'
- **Audit Logging:** Logs revocation event to `EventLog`
- **Conditional Notification:** Queues email to requester (if `CreatePermissionRevokedEmails` setting is '1')
- **Desired State Removal:** Request is removed from `RDSecurityGroupPermission` view (since it filters `ApprovalStatus = '1'`)
- **Historical Integrity:** Original request remains in database - revocation does not delete records

---

## 5. Request Lifecycle - Internal States

### 5.1 Complete Internal Lifecycle States

Sakura maintains the following internal states for requests:

**State 0: Pending**
- **Internal Representation:** `PermissionHeader.ApprovalStatus = '0'`
- **Meaning:** Request has been created and is awaiting approval
- **What Caused Transition:** Request creation via `Create*PermissionRequest` procedures
- **Internal Checks Performed:**
  - Request exists in `PermissionHeader`
  - Request has associated detail record in appropriate `Permission*Detail` table
  - Approvers have been determined and stored in `Approvers` column
- **What Must Exist Before Moving to Next State:**
  - Request must be in Pending status
  - Approver must be in `Approvers` list
  - Approver must call `ApprovePermissionRequest` or `RejectPermissionRequest`

**State 1: Approved**
- **Internal Representation:** `PermissionHeader.ApprovalStatus = '1'`
- **Meaning:** Request has been approved and is eligible for group membership
- **What Caused Transition:** Approver called `ApprovePermissionRequest` procedure
- **Internal Checks Performed:**
  - Request exists
  - Request is in Pending status
  - Approver is in `Approvers` list
- **What Must Exist Before Moving to Next State:**
  - Request must be Approved
  - Administrator must call `RevokePermissionRequest` to move to Revoked state
- **Special Behavior:**
  - Request appears in `RDSecurityGroupPermission` view (if RequestType matches criteria)
  - Request becomes eligible for Azure AD group membership (via sync)

**State 2: Rejected**
- **Internal Representation:** `PermissionHeader.ApprovalStatus = '2'`
- **Meaning:** Request has been rejected and will not be approved
- **What Caused Transition:** Approver called `RejectPermissionRequest` procedure
- **Internal Checks Performed:**
  - Request exists
  - Request is in Pending status
  - Approver is in `Approvers` list
- **What Must Exist Before Moving to Next State:**
  - Rejection is **final** - request cannot transition from Rejected to any other state
  - Request remains in Rejected state permanently
- **Special Behavior:**
  - Request does NOT appear in `RDSecurityGroupPermission` view
  - Request is NOT eligible for Azure AD group membership
  - `RejectReason` is stored for audit purposes

**State 3: Revoked**
- **Internal Representation:** `PermissionHeader.ApprovalStatus = '3'`
- **Meaning:** Request has been revoked and access should be removed
- **What Caused Transition:** Administrator called `RevokePermissionRequest` procedure
- **Internal Checks Performed:**
  - Request exists
  - Request is in Approved ('1') or Pending ('0') status
- **What Must Exist Before Moving to Next State:**
  - Revocation is **final** - request cannot transition from Revoked to any other state
  - Request remains in Revoked state permanently
- **Special Behavior:**
  - Request is removed from `RDSecurityGroupPermission` view (since it filters `ApprovalStatus = '1'`)
  - Request becomes eligible for removal from Azure AD groups (via sync)
  - Historical integrity maintained - original request remains in database

**Expired State:**
- **Internal Representation:** Not explicitly tracked
- **Meaning:** Sakura does NOT have an explicit "Expired" state
- **Internal Logic:** Requests do not automatically expire
- **Alternative:** Administrators can revoke requests that are no longer needed

### 5.2 State Transition Diagram

```
[NONE]
  ↓
[CREATED] → Create*PermissionRequest procedure invoked
  ↓
[PENDING] → ApprovalStatus = '0'
  ├─→ [APPROVED] → ApprovalStatus = '1' (via ApprovePermissionRequest)
  │     │
  │     └─→ [REVOKED] → ApprovalStatus = '3' (via RevokePermissionRequest)
  │
  └─→ [REJECTED] → ApprovalStatus = '2' (via RejectPermissionRequest)
        │
        └─→ [END STATE - No further transitions]
```

**Key Observations:**
- All requests start in Pending state
- Pending requests can transition to Approved or Rejected
- Approved requests can transition to Revoked
- Rejected and Revoked are end states - no further transitions
- No direct transition from Rejected to Approved (would require new request)
- No direct transition from Revoked to Approved (would require new request)

### 5.3 Internal State Validation Rules

**Before Approval:**
- Request must exist (`RequestId` must be valid)
- Request must be in Pending status (`ApprovalStatus = '0'`)
- Approver must be in `Approvers` list (semicolon-separated matching)
- Request must have associated detail record

**Before Rejection:**
- Request must exist
- Request must be in Pending status (`ApprovalStatus = '0'`)
- Approver must be in `Approvers` list
- `RejectReason` must be provided

**Before Revocation:**
- Request must exist
- Request must be in Approved ('1') or Pending ('0') status
- No approver validation required (administrative action)

**State Transition Guards:**
- Procedures validate current state before allowing transition
- Invalid state transitions are rejected with error messages
- All state transitions are logged to `EventLog`

---

## 6. Rejection vs Revocation - Critical Differentiation

### 6.1 Rejection - Internal Logic

**When Rejection is Allowed:**
- Rejection is allowed **only** when request is in Pending ('0') status
- Rejection is performed by calling `RejectPermissionRequest` procedure
- Approver must be in the `Approvers` list

**Who Can Reject:**
- Any approver in the `Approvers` list can reject
- Rejection is an approver action (not administrative)
- No special permissions required beyond being an approver

**What Internal Data is Updated:**
- `PermissionHeader.ApprovalStatus` → '2' (Rejected)
- `PermissionHeader.RejectedBy` → Approver email
- `PermissionHeader.RejectedDate` → Current timestamp
- `PermissionHeader.RejectReason` → Rejection reason (provided by approver)
- `EventLog` → New event: 'PermissionRequestRejected'
- `Emails` → Email queued to requester (notification)

**Whether Rejection is Final or Reversible:**
- **Rejection is FINAL and IRREVERSIBLE**
- Rejected requests cannot transition to any other state
- To grant access after rejection, a new request must be created
- Historical integrity maintained - rejected request remains in database

**Internal Behavior:**
- Rejected requests do NOT appear in `RDSecurityGroupPermission` view
- Rejected requests are NOT eligible for Azure AD group membership
- Rejection is logged for audit purposes
- Requester is notified via email

### 6.2 Revocation - Internal Logic

**When Revocation Applies:**
- Revocation applies to requests in **Approved ('1') or Pending ('0')** status
- Revocation is performed by calling `RevokePermissionRequest` procedure
- Revocation is an administrative action (not approver action)

**How Sakura Identifies a Revocable Request:**
- Request must exist
- Request must have `ApprovalStatus` IN ('0', '1')
- No approver validation required (administrative override)

**What Internal Cleanup or Reversal Happens:**
- `PermissionHeader.ApprovalStatus` → '3' (Revoked)
- `PermissionHeader.LastChangedBy` → Administrator email
- `EventLog` → New event: 'PermissionRequestRevoked'
- `Emails` → Email queued to requester (if `CreatePermissionRevokedEmails` setting is '1')
- **Desired State Removal:** Request is removed from `RDSecurityGroupPermission` view
  - View filters `ApprovalStatus = '1'`, so revoked requests no longer appear
  - On next sync run, user will be removed from Azure AD groups

**How Historical Integrity is Maintained:**
- **Original request records are NOT deleted**
- `PermissionHeader` record remains with `ApprovalStatus = '3'`
- `Permission*Detail` record remains unchanged
- `EventLog` contains complete audit trail:
  - RequestCreated → PermissionRequestApproved → PermissionRequestRevoked
- `history.PermissionHeader` table (via trigger) maintains historical versions
- Complete audit trail enables investigation and compliance

**Internal Behavior:**
- Revoked requests do NOT appear in `RDSecurityGroupPermission` view
- Revoked requests become eligible for removal from Azure AD groups (via sync)
- Revocation is logged for audit purposes
- Requester may be notified via email (configurable)

### 6.3 Key Differences - Internal Perspective

| Aspect | Rejection | Revocation |
|--------|-----------|------------|
| **Allowed States** | Pending ('0') only | Approved ('1') or Pending ('0') |
| **Who Can Perform** | Approver (must be in Approvers list) | Administrator (no approver validation) |
| **Final Status** | '2' (Rejected) | '3' (Revoked) |
| **Reversible** | No (final) | No (final) |
| **Requires Reason** | Yes (`RejectReason` required) | No (no reason field) |
| **Email Notification** | Always sent to requester | Conditional (if `CreatePermissionRevokedEmails = '1'`) |
| **Historical Integrity** | Request remains, status = '2' | Request remains, status = '3' |
| **Desired State Impact** | Never appears in view | Removed from view (if was Approved) |
| **Use Case** | Approver denies request | Administrator removes access |

**Internal Logic Summary:**
- **Rejection** = Approver denies a pending request (business decision)
- **Revocation** = Administrator removes access from approved/pending request (administrative action)
- Both are final states - cannot be reversed
- Both maintain historical integrity - records are not deleted
- Both are logged for audit purposes

---

## 7. Data Handling - Internal Concepts

### 7.1 What Kind of Data is Stored During Each Operation

**Request Creation:**
- **PermissionHeader Record:**
  - `RequestId` (auto-generated)
  - `RequestCode` (sequence-generated)
  - `RequestBatchCode` (sequence-generated)
  - `RequestedFor` (user email/UPN)
  - `RequestedBy` (user email/UPN)
  - `RequestReason` (business justification)
  - `RequestType` (type identifier)
  - `ApplicationLoVId` (application identifier)
  - `ApprovalStatus` ('0' = Pending)
  - `Approvers` (semicolon-separated list)
  - `RequestDate` (current timestamp)
- **Permission*Detail Record:**
  - Type-specific scoping information (EntityCode, ServiceLineCode, CostCenterCode, ClientCode, etc.)
- **EventLog Record:**
  - 'RequestCreated' event
  - Links to `PermissionHeader` via `TableName='PermissionHeader'`, `RecordId=RequestId`
- **Emails Record:**
  - Email queued to requester (request received notification)
  - Email queued to approvers (awaiting approval notification)

**Request Update:**
- **Sakura does NOT support updating existing requests**
- To change a request, a new request must be created and the old one revoked
- Historical integrity is maintained - original request remains

**Approval:**
- **PermissionHeader Record:**
  - `ApprovalStatus` → '1' (Approved)
  - `ApprovedBy` → Approver email
  - `ApprovedDate` → Current timestamp
  - `LastChangedBy` → Approver email
  - `LastChangeDate` → Current timestamp
- **history.PermissionHeader Record:**
  - Historical version created via trigger (before update)
- **EventLog Record:**
  - 'PermissionRequestApproved' event
- **Emails Record:**
  - Email queued to requester (approval notification)

**Rejection:**
- **PermissionHeader Record:**
  - `ApprovalStatus` → '2' (Rejected)
  - `RejectedBy` → Approver email
  - `RejectedDate` → Current timestamp
  - `RejectReason` → Rejection reason
  - `LastChangedBy` → Approver email
  - `LastChangeDate` → Current timestamp
- **history.PermissionHeader Record:**
  - Historical version created via trigger
- **EventLog Record:**
  - 'PermissionRequestRejected' event
- **Emails Record:**
  - Email queued to requester (rejection notification)

**Revocation:**
- **PermissionHeader Record:**
  - `ApprovalStatus` → '3' (Revoked)
  - `LastChangedBy` → Administrator email
  - `LastChangeDate` → Current timestamp
- **history.PermissionHeader Record:**
  - Historical version created via trigger
- **EventLog Record:**
  - 'PermissionRequestRevoked' event
- **Emails Record:**
  - Email queued to requester (if `CreatePermissionRevokedEmails = '1'`)

### 7.2 How Sakura Maintains Request History

**1. Immutable Records:**
- `PermissionHeader` and `Permission*Detail` records are never deleted
- State changes update existing records (status changes)
- Original data is preserved in `history.*` tables via triggers

**2. History Tables:**
- `history.PermissionHeader` - Maintains historical versions of `PermissionHeader`
- `history.PermissionOrgaDetail` - Maintains historical versions of `PermissionOrgaDetail`
- `history.PermissionCPDetail` - Maintains historical versions of `PermissionCPDetail`
- `history.PermissionMSSDetail` - Maintains historical versions of `PermissionMSSDetail`
- Triggers automatically create history records on UPDATE/DELETE

**3. EventLog Audit Trail:**
- All state transitions logged to `EventLog`
- Events link to source records via `TableName` + `RecordId`
- Complete chronological record of all operations
- Immutable - events are never updated or deleted

**4. Temporal Tracking:**
- `RequestDate` - When request was created
- `ApprovedDate` - When request was approved
- `RejectedDate` - When request was rejected
- `LastChangeDate` - When request was last modified
- `EventTimestamp` - When each event occurred

### 7.3 How Sakura Maintains Decision Traceability

**1. Actor Tracking:**
- `RequestedBy` - Who created the request
- `ApprovedBy` - Who approved the request
- `RejectedBy` - Who rejected the request
- `LastChangedBy` - Who last modified the request
- `EventTriggeredBy` - Who/what triggered each event (procedure name, user email, script name)

**2. Reason Tracking:**
- `RequestReason` - Why request was created
- `RejectReason` - Why request was rejected
- `EventDescription` - Detailed description of each event

**3. Complete Audit Trail:**
- Every significant operation generates an `EventLog` entry
- Events are linked to source records
- Chronological sequence enables reconstruction of request lifecycle
- All actors and reasons are captured

### 7.4 How Sakura Ensures Status Integrity

**1. State Validation:**
- Procedures validate current state before allowing transitions
- Invalid state transitions are rejected
- State checks are performed at procedure level

**2. Immutable State Transitions:**
- Rejected ('2') and Revoked ('3') are end states
- No transitions allowed from end states
- Historical integrity maintained - original state preserved

**3. Atomic Operations:**
- State transitions are performed in single transactions
- Either entire operation succeeds or fails
- No partial state updates

**4. Referential Integrity:**
- Foreign keys ensure `Permission*Detail` records reference valid `PermissionHeader` records
- Cascade rules prevent orphaned records
- Database constraints enforce data integrity

---

## 8. Approver View vs Requester View - Internal Meaning

### 8.1 What Sakura Internally Considers an "Approver View"

**Approver View - Internal Definition:**
- Sakura does NOT have separate "Approver View" and "Requester View" tables or views
- The distinction is **logical**, not physical
- An "Approver View" is internally determined by:
  - User email is in the `Approvers` column (semicolon-separated list)
  - User has permission to call `ApprovePermissionRequest` or `RejectPermissionRequest`
  - Request is in Pending ('0') status

**Internal Logic for Approver View:**
- System checks if user email is in `PermissionHeader.Approvers` column
- If yes, user is considered an approver for that request
- Approver can:
  - View request details
  - Approve request (via `ApprovePermissionRequest`)
  - Reject request (via `RejectPermissionRequest`)
  - Append additional approvers (via `AppendApproverToPermissionRequest`)

### 8.2 What Sakura Internally Considers a "Requester View"

**Requester View - Internal Definition:**
- A "Requester View" is internally determined by:
  - User email matches `RequestedFor` or `RequestedBy` in `PermissionHeader`
  - User has permission to view their own requests

**Internal Logic for Requester View:**
- System checks if user email matches `PermissionHeader.RequestedFor` or `PermissionHeader.RequestedBy`
- If yes, user is considered the requester for that request
- Requester can:
  - View request details
  - View request status
  - Receive email notifications
  - Cannot approve/reject their own requests (unless they are also in Approvers list)

### 8.3 How the Same Request Appears Differently Based on Internal Role Context

**Internal Role Differentiation:**

**1. Approver Context:**
- User email is in `Approvers` list
- System allows calls to `ApprovePermissionRequest` or `RejectPermissionRequest`
- System validates approver is in list before allowing approval/rejection
- Approver receives email notifications (awaiting approval)
- Approver can append additional approvers

**2. Requester Context:**
- User email matches `RequestedFor` or `RequestedBy`
- System allows viewing request details
- System sends email notifications (request received, approved, rejected, revoked)
- Requester cannot approve/reject (unless also in Approvers list)

**3. Administrator Context:**
- No explicit "Administrator" role in database
- Administrators can call `RevokePermissionRequest` (no approver validation required)
- Administrators can call `BatchChangeStatusPermissionRequests` (bulk operations)
- Administrators can view all requests (no filtering by role)

**Internal Logic Differences:**
- **Approver Logic:** Checks `Approvers` column, validates approver authorization, allows approval/rejection
- **Requester Logic:** Checks `RequestedFor`/`RequestedBy`, allows viewing, sends notifications
- **Administrator Logic:** No role-based filtering, allows revocation and bulk operations

**No UI Descriptions - Only Internal Logic:**
- The distinction is purely logical - same `PermissionHeader` record, different authorization checks
- Different stored procedures are called based on role
- Different validation logic is applied
- Different email notifications are sent

---

## 9. Error & Guardrail Logic

### 9.1 Internal Checks That Prevent Invalid Requests

**1. Duplicate Request Detection:**
- **Logic:** Before creating request, system checks for existing requests with:
  - Same `RequestedFor` (user email)
  - Same `RequestType`
  - Same scope (EntityCode, ServiceLineCode, CostCenterCode, etc.)
  - Same `ApplicationLoVId`
  - `ApprovalStatus` IN ('0', '1') - Pending or Approved
- **Action:** If duplicate found, request creation is rejected
- **Rationale:** Prevents duplicate access requests for same scope

**2. Parameter Validation:**
- **Logic:** Procedures validate required parameters are provided and non-null
- **Action:** If validation fails, procedure returns error
- **Rationale:** Ensures data integrity

**3. Reference Data Validation:**
- **Logic:** Validates EntityCode, ServiceLineCode, CostCenterCode, ClientCode, MSSCode exist in reference data tables
- **Action:** If validation fails, request creation is rejected
- **Rationale:** Ensures requests reference valid organizational entities

**4. CostCenter Validation (Orga Requests):**
- **Logic:** For Orga requests, validates CostCenter belongs to specified Entity and ServiceLine via `fnGetCostCenterListWithContextFilter`
- **Action:** If validation fails, request creation is rejected
- **Rationale:** Ensures CostCenter is valid for specified Entity/ServiceLine combination

**5. Approver Validation:**
- **Logic:** Before approval/rejection, validates approver is in `Approvers` list
- **Action:** If validation fails, approval/rejection is rejected
- **Rationale:** Prevents unauthorized approvals

**6. State Validation:**
- **Logic:** Before state transitions, validates current state allows transition
- **Action:** If validation fails, transition is rejected
- **Rationale:** Ensures valid state machine transitions

### 9.2 How Duplicate or Conflicting Requests are Detected

**Duplicate Detection Logic:**
- Performed during request creation (in `Create*PermissionRequest` procedures)
- Checks `PermissionHeader` table for existing requests matching:
  - `RequestedFor` = same user
  - `RequestType` = same type
  - Scope matches (EntityCode, ServiceLineCode, etc.)
  - `ApplicationLoVId` = same application
  - `ApprovalStatus` IN ('0', '1') - Pending or Approved only
- Rejected requests ('2') and revoked requests ('3') are NOT considered duplicates
- Rationale: User can create new request after rejection/revocation

**Conflicting Request Detection:**
- Sakura does NOT explicitly detect "conflicting" requests
- Multiple requests for same user/scope/application can exist if:
  - One is Rejected or Revoked
  - Requests are for different applications
  - Requests have different scopes
- `RDSecurityGroupPermission` view aggregates all approved requests, so multiple approved requests for same scope are allowed

### 9.3 How Sakura Ensures a Request Cannot Bypass Approval

**1. Approval Status Enforcement:**
- Requests are created with `ApprovalStatus = '0'` (Pending)
- Only `ApprovePermissionRequest` can change status to '1' (Approved)
- `ApprovePermissionRequest` validates approver is in `Approvers` list
- No direct database updates allowed (procedures enforce business rules)

**2. RDSecurityGroupPermission View Filtering:**
- View filters `ApprovalStatus = '1'` (Approved only)
- Pending, Rejected, and Revoked requests do NOT appear in view
- View is the sole source for Azure AD sync
- Even if status is manually changed, view filtering prevents bypass

**3. Procedure-Based Workflow:**
- All state transitions go through stored procedures
- Procedures enforce business rules
- Direct database updates are discouraged (no application code should bypass procedures)

**4. Audit Trail:**
- All approvals are logged to `EventLog`
- `ApprovedBy` and `ApprovedDate` are recorded
- Complete audit trail enables detection of unauthorized approvals

### 9.4 What Happens When Stored Procedures Detect Invalid State Transitions

**1. Validation Failure:**
- Procedure checks current state
- If state does not allow transition, procedure returns error
- `ResultValue` output parameter indicates failure
- `ResultMessage` output parameter contains error description

**2. Transaction Rollback:**
- State transitions are performed in transactions
- If validation fails, transaction is rolled back
- No partial updates occur

**3. Error Logging:**
- Validation failures may be logged to `EventLog` (depending on procedure)
- Error messages are returned to caller
- No state change occurs

**4. Common Validation Failures:**
- **Approval of non-Pending request:** Request must be in Pending ('0') status
- **Rejection of non-Pending request:** Request must be in Pending ('0') status
- **Revocation of Rejected request:** Request must be in Approved ('1') or Pending ('0') status
- **Approval by non-approver:** Approver must be in `Approvers` list
- **Duplicate request:** Request with same scope already exists in Pending/Approved status

---

## 10. Complete Internal Flow - Step-by-Step Narrative

### 10.1 Request Creation Flow - Internal Narrative

**Step 1: Procedure Invocation**
- `CreateOrgaPermissionRequest` (or type-specific variant) is invoked
- Parameters include: `@RequestedFor`, `@RequestedBy`, `@RequestReason`, `@RequestType`, `@ApplicationLoVId`, scope parameters

**Step 2: Input Validation**
- Procedure validates all required parameters are provided
- Procedure validates reference data (EntityCode, ServiceLineCode, etc. exist)
- For Orga requests, procedure validates CostCenter via `fnGetCostCenterListWithContextFilter`

**Step 3: Duplicate Detection**
- Procedure queries `PermissionHeader` for existing requests with:
  - Same `RequestedFor`, `RequestType`, scope, `ApplicationLoVId`
  - `ApprovalStatus` IN ('0', '1')
- If duplicate found, procedure returns error and exits

**Step 4: Code Generation**
- Procedure generates `RequestBatchCode` via sequence
- Procedure generates `RequestCode` via sequence for each user in `@RequestedFor` list

**Step 5: Approver Resolution**
- Procedure calls `FindApprovers` with request parameters
- `FindApprovers` routes to type-specific finder (e.g., `FindOrgaApprovers`)
- Type-specific finder queries `Approvers*` table and matches approvers
- Approvers list is returned (semicolon-separated)

**Step 6: Record Creation**
- For each user in `@RequestedFor` list:
  - Procedure inserts `PermissionHeader` record:
    - `RequestId` (auto-generated)
    - `RequestCode` (sequence-generated)
    - `RequestBatchCode` (shared for batch)
    - `RequestedFor` (user email)
    - `RequestedBy` (creator email)
    - `RequestReason` (justification)
    - `RequestType` (type identifier)
    - `ApplicationLoVId` (application)
    - `ApprovalStatus` = '0' (Pending)
    - `Approvers` (semicolon-separated list)
    - `RequestDate` (current timestamp)
  - Procedure inserts `PermissionOrgaDetail` record (or type-specific detail):
    - `RequestId` (FK to PermissionHeader)
    - Scope fields (EntityCode, ServiceLineCode, etc.)

**Step 7: Audit Logging**
- Procedure calls `AddToEventLog`:
  - `TableName` = 'PermissionHeader'
  - `RecordId` = RequestId
  - `EventName` = 'RequestCreated'
  - `EventDescription` = 'The permission request is created.'
  - `EventTriggeredBy` = Procedure name

**Step 8: Email Notification - Requester**
- Procedure calls `AddToEmailQueue`:
  - Template: 'APP-RYRC-Orga' (request received)
  - Recipients: `RequestedFor` (user email)
  - Context: RequestId

**Step 9: Auto-Approval Check**
- Procedure checks if `RequestedFor` or `RequestedBy` is in `Approvers` list
- If yes, procedure calls `ApprovePermissionRequest` (auto-approval)
- If no, continues to Step 10

**Step 10: Email Notification - Approvers**
- Procedure calls `AddToEmailQueue`:
  - Template: 'APP-AWP-Orga' (awaiting approval)
  - Recipients: `Approvers` (semicolon-separated list)
  - Context: RequestId

**Step 11: Completion**
- Procedure returns success
- Request is now in Pending ('0') status
- Request is eligible for approval/rejection

### 10.2 Approval Flow - Internal Narrative

**Step 1: Procedure Invocation**
- `ApprovePermissionRequest` is invoked
- Parameters: `@RequestId`, `@ApprovedBy`, `@ApprovalChannel`

**Step 2: Request Validation**
- Procedure queries `PermissionHeader` for request
- Procedure validates request exists
- Procedure validates `ApprovalStatus` = '0' (Pending)

**Step 3: Approver Authorization**
- Procedure checks if `@ApprovedBy` is in `Approvers` column
- Procedure performs semicolon-separated string matching
- If approver not found, procedure returns error and exits

**Step 4: State Transition**
- Procedure updates `PermissionHeader`:
  - `ApprovalStatus` = '1' (Approved)
  - `ApprovedBy` = `@ApprovedBy`
  - `ApprovedDate` = Current timestamp
  - `LastChangedBy` = `@ApprovedBy`
  - `LastChangeDate` = Current timestamp

**Step 5: History Record Creation**
- Trigger on `PermissionHeader` creates record in `history.PermissionHeader`
- Historical version of request is preserved

**Step 6: Audit Logging**
- Procedure calls `AddToEventLog`:
  - `TableName` = 'PermissionHeader'
  - `RecordId` = RequestId
  - `EventName` = 'PermissionRequestApproved'
  - `EventDescription` = 'The permission request is approved via: {Channel}'
  - `EventTriggeredBy` = `@ApprovedBy`

**Step 7: Email Notification**
- Procedure calls `AddToEmailQueue`:
  - Template: 'APP-APRVED' (approved)
  - Recipients: `RequestedFor` (user email)
  - Context: RequestId

**Step 8: Desired State Update**
- Request now has `ApprovalStatus` = '1'
- Request becomes eligible for `RDSecurityGroupPermission` view (if RequestType matches criteria)
- View filters `ApprovalStatus = '1'`, so request appears in view
- On next sync run, user will be added to Azure AD groups

**Step 9: Completion**
- Procedure returns success
- Request is now in Approved ('1') status
- Request is eligible for revocation (by administrator)

### 10.3 Rejection Flow - Internal Narrative

**Step 1: Procedure Invocation**
- `RejectPermissionRequest` is invoked
- Parameters: `@RequestId`, `@RejectedBy`, `@RejectReason`, `@RejectChannel`

**Step 2: Request Validation**
- Procedure queries `PermissionHeader` for request
- Procedure validates request exists
- Procedure validates `ApprovalStatus` = '0' (Pending)

**Step 3: Approver Authorization**
- Procedure checks if `@RejectedBy` is in `Approvers` column
- If approver not found, procedure returns error and exits

**Step 4: State Transition**
- Procedure updates `PermissionHeader`:
  - `ApprovalStatus` = '2' (Rejected)
  - `RejectedBy` = `@RejectedBy`
  - `RejectedDate` = Current timestamp
  - `RejectReason` = `@RejectReason`
  - `LastChangedBy` = `@RejectedBy`
  - `LastChangeDate` = Current timestamp

**Step 5: History Record Creation**
- Trigger creates record in `history.PermissionHeader`

**Step 6: Audit Logging**
- Procedure calls `AddToEventLog`:
  - `EventName` = 'PermissionRequestRejected'
  - `EventDescription` = 'The permission request is rejected via: {Channel}'
  - `EventTriggeredBy` = `@RejectedBy`

**Step 7: Email Notification**
- Procedure calls `AddToEmailQueue`:
  - Template: 'APP-REJECTED' (rejected)
  - Recipients: `RequestedFor` (user email)
  - Context: RequestId

**Step 8: End State**
- Request is now in Rejected ('2') status
- Request does NOT appear in `RDSecurityGroupPermission` view
- Request is NOT eligible for Azure AD group membership
- Request cannot transition to any other state (final)

**Step 9: Completion**
- Procedure returns success
- Request remains in Rejected state permanently

### 10.4 Revocation Flow - Internal Narrative

**Step 1: Procedure Invocation**
- `RevokePermissionRequest` is invoked
- Parameters: `@RequestId`, `@RevokedBy`, `@RevokeChannel`

**Step 2: Request Validation**
- Procedure queries `PermissionHeader` for request
- Procedure validates request exists
- Procedure validates `ApprovalStatus` IN ('0', '1') - Pending or Approved
- No approver validation required (administrative action)

**Step 3: State Transition**
- Procedure updates `PermissionHeader`:
  - `ApprovalStatus` = '3' (Revoked)
  - `LastChangedBy` = `@RevokedBy`
  - `LastChangeDate` = Current timestamp

**Step 4: History Record Creation**
- Trigger creates record in `history.PermissionHeader`

**Step 5: Audit Logging**
- Procedure calls `AddToEventLog`:
  - `EventName` = 'PermissionRequestRevoked'
  - `EventDescription` = 'The permission request is revoked via: {Channel}'
  - `EventTriggeredBy` = `@RevokedBy`

**Step 6: Conditional Email Notification**
- Procedure checks `ApplicationSettings` table for `CreatePermissionRevokedEmails` setting
- If setting = '1', procedure calls `AddToEmailQueue`:
  - Template: 'APP-REVKED' (revoked)
  - Recipients: `RequestedFor` (user email)
  - Context: RequestId
- If setting ≠ '1', no email is sent

**Step 7: Desired State Removal**
- Request now has `ApprovalStatus` = '3'
- Request is removed from `RDSecurityGroupPermission` view (view filters `ApprovalStatus = '1'`)
- On next sync run, user will be removed from Azure AD groups

**Step 8: Historical Integrity**
- Original request records remain in database
- `PermissionHeader` record remains with `ApprovalStatus` = '3'
- `Permission*Detail` record remains unchanged
- Complete audit trail preserved in `EventLog`

**Step 9: Completion**
- Procedure returns success
- Request is now in Revoked ('3') status
- Request cannot transition to any other state (final)

### 10.5 Complete Lifecycle Example - Internal Narrative

**Scenario: User requests Orga permission, approver approves, administrator revokes**

**Phase 1: Request Creation**
1. `CreateOrgaPermissionRequest` invoked with user email, EntityCode, ServiceLineCode, CostCenterCode
2. System validates inputs, checks for duplicates, generates RequestCode
3. System calls `FindOrgaApprovers` → matches approvers from `ApproversOrga` table
4. System inserts `PermissionHeader` (ApprovalStatus = '0') and `PermissionOrgaDetail`
5. System logs 'RequestCreated' event
6. System queues emails to requester and approvers
7. Request is now in Pending state

**Phase 2: Approval**
1. Approver calls `ApprovePermissionRequest` with RequestId
2. System validates request is Pending and approver is authorized
3. System updates `PermissionHeader` (ApprovalStatus = '1')
4. System logs 'PermissionRequestApproved' event
5. System queues email to requester
6. Request now appears in `RDSecurityGroupPermission` view
7. Request is now in Approved state

**Phase 3: Sync (External - Not Internal)**
- `SakuraADSync.ps1` reads `RDSecurityGroupPermission` view
- User is added to Azure AD groups
- Sync events logged to `EventLog`

**Phase 4: Revocation**
1. Administrator calls `RevokePermissionRequest` with RequestId
2. System validates request is Approved or Pending
3. System updates `PermissionHeader` (ApprovalStatus = '3')
4. System logs 'PermissionRequestRevoked' event
5. System conditionally queues email to requester
6. Request is removed from `RDSecurityGroupPermission` view
7. Request is now in Revoked state

**Phase 5: Sync (External - Not Internal)**
- `SakuraADSync.ps1` reads `RDSecurityGroupPermission` view
- User is removed from Azure AD groups
- Sync events logged to `EventLog`

**Complete Audit Trail:**
- `EventLog` contains: RequestCreated → PermissionRequestApproved → PermissionRequestRevoked → GroupMemberAdded → GroupMemberRemoved
- Complete traceability from request creation through access removal

---

## Conclusion

This document provides a complete internal-functional explanation of how Sakura creates, processes, tracks, approves, rejects, and revokes requests. All explanations focus on **internal Sakura logic** - state transitions, data flows, business rules, and stored procedure behavior - without reference to UI screens or external systems.

**Key Takeaways:**
1. Requests are created via type-specific `Create*PermissionRequest` procedures
2. Requests are classified by RequestType and organizational scope
3. Approvers are derived via hierarchical matching against `Approvers*` tables
4. Requests transition through states: Pending → Approved/Rejected/Revoked
5. Rejection and Revocation are distinct operations with different rules
6. All operations maintain historical integrity and complete audit trails
7. Internal guardrails prevent invalid requests and unauthorized approvals

---

**Document Maintenance:**
- **Last Updated:** 2025-01-XX
- **Next Review:** When stored procedures or business logic change
- **Owner:** Sakura Team

---

**End of Document**

