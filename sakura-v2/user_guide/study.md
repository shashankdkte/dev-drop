# Sakura V2 — Complete Self-Study Guide
> 527 Questions & Answers across all major topics.  
> Covers architecture, DB schema, permission flows, approval workflow, RLS, OLS, sync, auth, email, and V1 vs V2 comparisons.

---

## Table of Contents

1. [V2 Overall Architecture](#1-v2-overall-architecture)
2. [Workspace Entity](#2-workspace-entity)
3. [WorkspaceApps — OLSMode & ApprovalMode](#3-workspaceapps--olsmode--approvalmode)
4. [AppAudiences](#4-appaudiences)
5. [WorkspaceReports](#5-workspacereports)
6. [WorkspaceSecurityModels & SecurityModelSecurityTypeMap](#6-workspacesecuritymodels--securitymodelsecuritytypemap)
7. [LoVs — List of Values](#7-lovs--list-of-values)
8. [Permission Request Wizard — OLS Flow](#8-permission-request-wizard--ols-flow)
9. [Permission Request Wizard — RLS Flow](#9-permission-request-wizard--rls-flow)
10. [PermissionRequests Table](#10-permissionrequests-table)
11. [PermissionHeaders Table](#11-permissionheaders-table)
12. [OLSPermissions Table](#12-olspermissions-table)
13. [RLSPermissions Table](#13-rlspermissions-table)
14. [RLS Domain Details — AMER](#14-rls-domain-details--amer)
15. [RLS Domain Details — EMEA](#15-rls-domain-details--emea)
16. [RLS Domain Details — GI, CDI, WFI, FUM](#16-rls-domain-details--gi-cdi-wfi-fum)
17. [Key vs Hierarchy Columns in RLS](#17-key-vs-hierarchy-columns-in-rls)
18. [Approver Resolution — LM Level](#18-approver-resolution--lm-level)
19. [Approver Resolution — OLS Level](#19-approver-resolution--ols-level)
20. [Approver Resolution — RLS Level per Domain](#20-approver-resolution--rls-level-per-domain)
21. [RLS Approver Tables](#21-rls-approver-tables)
22. [Approval Workflow State Machine](#22-approval-workflow-state-machine)
23. [Revocation & Cancellation](#23-revocation--cancellation)
24. [WSO Console — Approver Assignments](#24-wso-console--approver-assignments)
25. [Email Notification System](#25-email-notification-system)
26. [OLS Managed vs Non-Managed](#26-ols-managed-vs-non-managed)
27. [Auto Schema — OLSGroupMemberships](#27-auto-schema--olsgroupmemberships)
28. [SakuraV2ADSync.ps1 — Sync Script](#28-sakurav2adsyncps1--sync-script)
29. [Service Principal vs Delegated Auth](#29-service-principal-vs-delegated-auth)
30. [Share*.OLS Views](#30-shareols-views)
31. [Share*.RLS Views](#31-sharерls-views)
32. [Authentication & Authorization in the Backend](#32-authentication--authorization-in-the-backend)
33. [GlobalWorkspaceAccessUsers](#33-globalworkspaceaccessusers)
34. [EventLog & Audit](#34-eventlog--audit)
35. [Temporal Tables & Historisation](#35-temporal-tables--historisation)
36. [V1 RDSecurityGroupPermission View](#36-v1-rdsecuritygrouppermission-view)
37. [V1 SakuraADSync.ps1](#37-v1-sakuraadsyncps1)
38. [V1 vs V2 — OLS Comparison](#38-v1-vs-v2--ols-comparison)
39. [V1 vs V2 — RLS Comparison](#39-v1-vs-v2--rls-comparison)
40. [V1 vs V2 — Auth & Sync Comparison](#40-v1-vs-v2--auth--sync-comparison)

---

## 1. V2 Overall Architecture

**Q1. What are the five core structural entities in Sakura V2 and how do they relate?**  
A: Workspaces → WorkspaceApps → AppAudiences (for app-based OLS). Workspaces also have WorkspaceReports (standalone reports) and WorkspaceSecurityModels (for RLS). A Workspace is the top-level container; everything else hangs off it.

**Q2. What is a Workspace in Sakura V2?**  
A: A Workspace represents a business domain (e.g. DFI, AMER, EMEA). It groups all the apps, reports, and security models that belong to that domain. It has an owner, tech owner, approver, and an optional Entra Group UID.

**Q3. What does the `DomainLoVId` on a Workspace point to?**  
A: It is a foreign key to the `dbo.LoVs` table where `LoVType = 'Domain'`. The domain LoV values include DFI, GI, CDI, WFI, EMEA, AMER. This domain code is used by the backend to route to the correct RLS detail builder.

**Q4. How does a permission request relate to a workspace?**  
A: Every `PermissionRequest` has a `WorkspaceId` FK. The workspace determines which security models are available for RLS and which apps/audiences are available for OLS.

**Q5. What are the two types of permissions a wizard request can include?**  
A: OLS (Object Level Security — controls which report/app/audience a user can access) and RLS (Row Level Security — controls which data rows a user can see within a report). A request must have at least one; it can have both.

**Q6. What is the difference between OLS and RLS in V2?**  
A: OLS grants access to a PowerBI app, audience, or standalone report. RLS grants access to specific data rows within a report, scoped to dimensional keys like Entity, ServiceLine, Client etc. OLS leads to Entra group membership (for managed apps). RLS is stored directly in the DB and read by Power BI.

**Q7. How many approval stages does a permission request go through?**  
A: Three: LM (Line Manager) approval first, then OLS approval, then RLS approval. If the request only has OLS, there are two stages. If only RLS, two stages. If both, three stages.

**Q8. What schemas exist in the Sakura V2 database and what is each for?**  
A: `dbo` — core application tables and operational views. `history` — temporal history tables (auto-managed). `romv` — rich operational meta-views for the backend. `Share[Domain]` (ShareAMER, ShareEMEA, ShareGI, ShareFUM, ShareCDI, ShareWFI) — published surfaces for OLS and RLS consumed by Power BI or app owners. `Auto` — automation views (OLSGroupMemberships, for the sync script).

**Q9. What is the `romv` schema used for?**  
A: It contains operational views (`romv.PermissionRequests`, `romv.PermissionHeaders`) that give a rich denormalized view of permission data. The backend uses these to display summaries, e.g. showing all dimension Key|Hierarchy pairs for any RLS permission as a single human-readable `Info` string.

**Q10. What does `romv.PermissionRequests` expose that the base table does not?**  
A: It pivots the OLS and RLS approval statuses from `PermissionHeaders` side by side — `OLSStatus` and `RLSStatus` — alongside the `RequestStatus` from `PermissionRequests`. This lets you see the status of both headers at a glance without joining multiple tables.

**Q11. What is the `Auto` schema used for?**  
A: It holds views that are the integration surface for automated processes. Currently `Auto.OLSGroupMemberships` is the view consumed by the `SakuraV2ADSync.ps1` nightly sync script to determine desired Entra group membership.

**Q12. Why are there separate `Share[Domain]` schemas instead of a single shared schema?**  
A: So that Power BI datasets and app owners can be granted access per domain independently. A workspace admin for AMER only needs SELECT on `ShareAMER`, not on `ShareEMEA`. It's a security boundary at the DB schema level.

**Q13. What is `AdditionalDetailsJSON` on `OLSPermissions` and `RLSPermissions` used for?**  
A: It stores flexible extra metadata about a permission that doesn't fit the structured columns — for example custom answers to the `AdditionalQuestionsJSON` form fields defined on the app. It's nullable and optional.

**Q14. How does the backend know which RLS detail table to write to (AMER vs EMEA vs GI etc.)?**  
A: The `PermissionRequestService` uses a dictionary (`_rlsDetailBuilders`) keyed by the workspace's domain LoV value (e.g. "AMER", "EMEA", "DFI"). When creating a request, it looks up the domain, finds the matching builder method, and calls it to populate the correct details entity.

**Q15. What happens if the workspace domain is not recognized by the RLS builder dictionary?**  
A: A `ValidationException` is thrown with the message "Unsupported domain." The request is not created. This is a hard guard in `AddPermissionRequestAsync`.

---

## 2. Workspace Entity

**Q16. What columns does the `Workspaces` table have?**  
A: `Id`, `WorkspaceCode` (unique, e.g. "DFI"), `WorkspaceName`, `WorkspaceOwner`, `WorkspaceTechOwner`, `WorkspaceApprover`, `WorkspaceEntraGroupUID` (nullable), `WorkspaceTag` (nullable), `DomainLoVId`, `IsActive`, `CreatedAt/By`, `UpdatedAt/By`, plus temporal `ValidFrom/ValidTo`.

**Q17. What is `WorkspaceTag` used for?**  
A: It is appended to email subjects when it differs from the `WorkspaceCode`. It's a short label for tagging resources. If not set, the `WorkspaceCode` is used instead.

**Q18. What is `WorkspaceEntraGroupUID` on the Workspaces table?**  
A: It stores the Azure AD / Entra group object ID (GUID) associated with the workspace as a whole. It is nullable (not required). In V2 it is stored but currently not acted upon by any sync logic — it's a placeholder for future workspace-level Entra group automation.

**Q19. Can two workspaces share the same `WorkspaceCode`?**  
A: No. There is a unique constraint `UK_Workspaces` on `WorkspaceCode`. Each workspace must have a distinct code.

**Q20. How is workspace-level access controlled in the backend API?**  
A: `WorkspaceService.GetWorkspacesForUserAsync` filters workspaces by checking if the user's email matches any value in the `WorkspaceOwner`, `WorkspaceTechOwner`, or `WorkspaceApprover` CSV fields. There is also a `GlobalWorkspaceAccessUsers` bypass for admin users.

**Q21. What does `IsActive` on a Workspace do?**  
A: It soft-deletes the workspace. Inactive workspaces are excluded from queries in OLS views and workspace listings. No physical deletion ever happens — this is consistent with the temporal/historisation design.

**Q22. What does `WorkspaceApprover` store?**  
A: A comma-separated list of user email addresses who are approvers at the workspace level. This is used when filtering workspaces visible to a user in the backend API.

**Q23. Why does `Workspaces` have `WorkspaceOwner`, `WorkspaceTechOwner`, and `WorkspaceApprover` as CSV strings rather than a separate relation table?**  
A: Design simplicity — these roles have a small, known number of people and are managed by workspace admins. A full user-role table would add complexity for a relationship that rarely has more than 2-3 emails per field.

**Q24. What is the FK from `Workspaces` to `LoVs`?**  
A: `FK_Workspaces_To_LoVs` on `DomainLoVId → dbo.LoVs(Id)`. This links the workspace to its domain classification (DFI, AMER, EMEA, GI, CDI, WFI).

**Q25. If you want to look up a workspace's domain code in SQL, what do you join?**  
A: `JOIN dbo.LoVs L ON L.Id = W.DomainLoVId` — then use `L.LoVValue` which will be the domain code (e.g. "AMER").

**Q26. How does the temporal history work for Workspaces?**  
A: SQL Server automatically maintains a `history.Workspaces` table. Every time a row in `dbo.Workspaces` is updated, the old version is written to `history.Workspaces` with the `ValidFrom`/`ValidTo` period. You can query history using `FOR SYSTEM_TIME AS OF '...'` syntax.

---

## 3. WorkspaceApps — OLSMode & ApprovalMode

**Q27. What is a WorkspaceApp?**  
A: A PowerBI application that belongs to a workspace. It has a unique `AppCode` within its workspace, an owner, tech owner, OLS mode, approval mode, and optional Entra group UID.

**Q28. What are the two values of `OLSMode` and what does each mean?**  
A: `0 = Managed` — Sakura automates the Entra group membership for this app via the nightly sync script. `1 = NotManaged` — The app owner manages OLS themselves; Sakura only records the approval and exposes it via the `Share[Domain].OLS` views.

**Q29. What are the two values of `ApprovalMode` and what does each mean?**  
A: `0 = AppBased` — the whole app has a single set of approvers stored in `WorkspaceApps.Approvers`. `1 = AudienceBased` — each audience within the app has its own approvers stored in `AppAudiences.Approvers`.

**Q30. When `ApprovalMode = AppBased`, where are the OLS approvers stored?**  
A: In `WorkspaceApps.Approvers` as a comma-separated list of email addresses.

**Q31. When `ApprovalMode = AudienceBased`, where are the OLS approvers stored?**  
A: In `AppAudiences.Approvers` per audience row, also as a comma-separated list.

**Q32. What is `AppEntraGroupUID` on `WorkspaceApps`?**  
A: The Entra group object ID for the app as a whole. It is nullable — the comment says "Not mandatory based on the OLSMode". For `Managed` apps it should be populated so the sync script knows which group to manage. For `NotManaged` apps it may be NULL.

**Q33. What is `AdditionalQuestionsJSON` on `WorkspaceApps`?**  
A: A JSON field that defines extra form questions shown to users during the permission request wizard for this specific app. The UI dynamically renders these questions and stores the answers in `OLSPermissions.AdditionalDetailsJSON`.

**Q34. Can two apps in the same workspace share the same `AppCode`?**  
A: No. The unique constraint `UK_WorkspaceApps` is on `(WorkspaceId, AppCode)`. Different workspaces can reuse the same code, but within one workspace it must be unique.

**Q35. If an app is `NotManaged` and a user gets an approved OLS request, what happens?**  
A: The approval is recorded in the DB (`OLSPermissions`, `PermissionHeaders`). It appears in the `Share[Domain].OLS` view. But Sakura does NOT add the user to any Entra group — the app owner reads the view and handles access themselves.

**Q36. If an app is `Managed`, what triggers the user getting actual access in PowerBI?**  
A: The nightly `SakuraV2ADSync.ps1` script reads `Auto.OLSGroupMemberships`, resolves the user to their Azure AD Object ID, and calls the Graph API to add them to the Entra group associated with their approved audience. PowerBI then sees the group membership and grants access.

**Q37. What is `IsActive` on `WorkspaceApps` used for?**  
A: Soft-delete flag. Inactive apps are excluded from OLS views (`WA.IsActive = 1`) and from the permission wizard. No rows are physically deleted.

**Q38. What relationship does `WorkspaceApps` have to `WorkspaceReports`?**  
A: Both belong to the same `Workspace`, but they are independent entities. `WorkspaceReports` with `ReportDeliveryMethod = 0 (AUR)` are audience-based reports that appear inside apps. `ReportDeliveryMethod = 1 (SAR)` are standalone reports directly under the workspace, not nested under an app.

---

## 4. AppAudiences

**Q39. What is an AppAudience?**  
A: A named audience segment within a WorkspaceApp (e.g. "Finance Team", "Senior Leadership"). Each audience can have its own Entra group UID and its own approvers. OLS permissions are granted at the audience level when the app uses `ApprovalMode = AudienceBased`.

**Q40. What does `AudienceEntraGroupUID` store?**  
A: The Azure AD / Entra group object ID for this specific audience. When the app is Managed, the sync script uses this GUID to add/remove users from the Azure AD group for this audience.

**Q41. What unique constraint exists on `AppAudiences`?**  
A: `UK_AppAudiences` on `(AppId, AudienceCode)`. An audience code must be unique within an app.

**Q42. Where does the `OLSItemId` in `OLSPermissions` point when `OLSItemType = 1`?**  
A: It points to `AppAudiences.Id`. The permission grants the user access to that specific audience.

**Q43. What happens if `AudienceEntraGroupUID` is NULL for an audience in a Managed app?**  
A: The sync script cannot add the user to a group for that audience — there is no GUID to reference. The user would appear in `Auto.OLSGroupMemberships` with a NULL `EntraGroupUID`, and the sync script would skip them (or handle it as an error). This is a configuration mistake that needs to be corrected.

**Q44. What is `IsActive` on `AppAudiences` used for?**  
A: Soft-delete. Inactive audiences are filtered out in OLS views (`AA.IsActive = 1`). No physical deletion.

**Q45. How is an AppAudience related to `ReportAppAudienceMap`?**  
A: `ReportAppAudienceMap` links `WorkspaceReports` (AUR type) to `AppAudiences`. This defines which reports appear within which audiences. It is a many-to-many bridge table.

---

## 5. WorkspaceReports

**Q46. What are the two delivery methods for a `WorkspaceReport` and what do they mean?**  
A: `0 = AUR (Audience Reports)` — report is delivered through an audience (nested inside an app). `1 = SAR (Standalone Reports)` — report is delivered standalone, directly accessible without going through an app/audience.

**Q47. What is `ReportTag` on `WorkspaceReports`?**  
A: A unique, alphanumeric string used within URL parameters to reference the report. It must be unique across all reports (unique constraint `UK_WorkspaceReports_ReportTag`).

**Q48. What is `ReportEntraGroupUID` on `WorkspaceReports`?**  
A: The Entra group object ID for the standalone report. Used in OLS `Share[Domain].OLS` views as `OLSEntraGroupId` when the OLS item type is a standalone report. Nullable — not compulsory.

**Q49. Where does `OLSItemId` point in `OLSPermissions` when `OLSItemType = 0`?**  
A: It points to `WorkspaceReports.Id`. The OLS permission grants access to a specific standalone report.

**Q50. Can a `WorkspaceReport` belong to multiple workspaces?**  
A: No. `WorkspaceReports` has `WorkspaceId` as a FK — each report belongs to exactly one workspace. But a report can be linked to multiple audiences via `ReportAppAudienceMap`.

**Q51. What are `ReportKeywords` used for?**  
A: A comma-separated list of keywords used by the UI search/filter functionality to help users find reports.

**Q52. What does `ReportDeliveryMethod = 1 (SAR)` mean in the context of the Share*.OLS views?**  
A: The OLS view's second `UNION ALL` branch handles SAR reports. It joins `WorkspaceReports` where `ReportDeliveryMethod = 1` and exposes `ReportEntraGroupUID` as `OLSEntraGroupId`. It also checks that the workspace has at least one NotManaged app (`OLSMode = 1`) via an `EXISTS` subquery.

---

## 6. WorkspaceSecurityModels & SecurityModelSecurityTypeMap

**Q53. What is a `WorkspaceSecurityModel`?**  
A: It defines a named security model for a workspace (e.g. "EMEA", "FIN", "AMER"). A workspace can have multiple security models. The security model determines which RLS details table is used and which security types are valid for that model.

**Q54. What unique constraint exists on `WorkspaceSecurityModels`?**  
A: `UK_WorkspaceSecurityModels` on `(WorkspaceId, SecurityModelCode)`. A security model code must be unique within a workspace.

**Q55. What is `SecurityModelSecurityTypeMap` used for?**  
A: It maps a `WorkspaceSecurityModel` to its allowed `SecurityType` LoV values. This defines which security types (e.g. EMEA-ORGA, EMEA-CLIENT) are valid options when requesting RLS access under a given security model.

**Q56. What unique constraint exists on `SecurityModelSecurityTypeMap`?**  
A: `UK_SecurityModelSecurityTypeMap` on `(SecurityModelId, SecurityTypeLoVId)`. A security type can only be mapped to a given security model once.

**Q57. How does the backend use `SecurityModelId` and `SecurityTypeLoVId` together?**  
A: They are stored on `RLSPermissions` and used to route to the correct detail table. In the `romv.PermissionHeaders` view, `OUTER APPLY` tries each of the 6 domain detail tables — the one that has a matching `RLSPermissionsId` returns the data, the others return nothing.

**Q58. Why does `RLSPermissions` store both `SecurityModelId` and `SecurityTypeLoVId` when the backend already knows the domain from the workspace?**  
A: `SecurityModelId` alone identifies the model (e.g. "EMEA model for EMEA workspace"), but `SecurityTypeLoVId` further narrows down to the exact type of RLS requested (e.g. EMEA-ORGA vs EMEA-CLIENT). Both are needed because a single model can support multiple security types, and the detail dimensions differ per type.

**Q59. What is the relationship between `WorkspaceSecurityModels` and `RLS[Domain]Approvers` tables?**  
A: The `RLS[Domain]Approvers` tables each have `SecurityModelId` and `SecurityTypeLoVId` FKs. Approver rows are seeded per workspace+model+type+dimension combination. When resolving RLS approvers, the system queries the relevant Approvers table filtered by the request's `SecurityModelId` + `SecurityTypeLoVId` + the dimensional keys the user selected.

**Q60. Can the same security model code exist in multiple workspaces?**  
A: Yes — the unique constraint is per workspace. For example both AMER and EMEA workspaces could each have a model called "FIN" if needed. But they would have different `WorkspaceSecurityModels.Id` values.

---

## 7. LoVs — List of Values

**Q61. What is the `LoVs` table and what is it used for?**  
A: It is a general-purpose lookup/reference table (List of Values). It stores all enum-like values used across the system: domains, security types, email modes, etc. Items are grouped by `LoVType` and identified by `LoVValue`.

**Q62. What columns does `LoVs` have beyond the basic key?**  
A: `LoVType` (e.g. "Domain", "SecurityType"), `LoVValue` (e.g. "AMER"), `LoVName` (human-readable), `LoVDescription`, `ParentLoVType` and `ParentLoVValue` (for hierarchical relationships), `SystemDataTypeName`.

**Q63. What unique constraint exists on `LoVs`?**  
A: `UK_LoVs` on `(LoVType, LoVValue)`. Within a LoV type, each value must be unique.

**Q64. What are the domain LoV values in Sakura V2?**  
A: DFI (Dentsu Finance Insights), GI (Growth Insights), CDI (Client Data Insights), WFI (Workforce Insights), EMEA (Europe And Middle East Region), AMER (Americas Region).

**Q65. What are all the security type LoV values?**  
A: FUM, GI, CDI, WFI (single-type domains), EMEA-ORGA, EMEA-CLIENT, EMEA-CC, EMEA-COUNTRY, EMEA-MSS (EMEA sub-types), AMER-ORGA, AMER-CLIENT, AMER-CC, AMER-PC, AMER-PA, AMER-MSS (AMER sub-types).

**Q66. Why does DFI map to FUM security type?**  
A: DFI (Dentsu Finance Insights) uses the Finance Unified Model (FUM) for its row-level security. The backend's `_rlsDetailBuilders` dictionary maps both "DFI" and "FUM" to `BuildFumDetails`. The domain code in the workspace is DFI but the security model type is FUM.

**Q67. What are the `EmailingMode` LoV values?**  
A: 0 = Skip (skip sending, but continue generating emails), 1 = Send (send emails), 2 = Pause (queue emails, send later when re-enabled). These are LoVType = 'ApplicationSetting_EmailingMode'.

**Q68. How does `ParentLoVType` and `ParentLoVValue` work in LoVs?**  
A: They allow hierarchical relationships between LoV items. For example a security type LoV could reference its parent domain LoV. This enables the UI or backend to filter available security types based on a selected domain.

**Q69. Why are LoVs stored in a table rather than as C# enums?**  
A: So they can be changed, extended, or re-labeled without a code deployment. The UI can read them dynamically via API. New domains or security types can be added by inserting rows, not by changing code.

---

## 8. Permission Request Wizard — OLS Flow

**Q70. What is the entry point for creating a permission request in the backend?**  
A: `PermissionRequestService.AddPermissionRequestAsync(CreatePermissionRequestRequest request)`.

**Q71. What is the minimum requirement for a permission request to be valid?**  
A: It must have at least one permission header — either OLS (`HasOLS = true`) or RLS (`HasRLS = true`), or both. If neither is true, a `ValidationException` is thrown: "At least one permission header (OLS or RLS) is required."

**Q72. What is `RequestedFor` vs `RequestedBy` on a permission request?**  
A: `RequestedFor` is the user who will receive the access (the beneficiary). `RequestedBy` is the user who submitted the request (the requester — could be an admin submitting on behalf of someone else, or the same person).

**Q73. What is `LMApprover` on `PermissionRequests`?**  
A: The line manager who must approve the request first — before it moves to OLS or RLS approval. This is stored at request creation time and cannot change after submission.

**Q74. What `RequestStatus` does a new permission request get when first created?**  
A: `PendingLM (0)` — it is waiting for the line manager's decision.

**Q75. When the LM approves, what happens to `RequestStatus`?**  
A: It moves to either `PendingOLS (1)` or `PendingRLS (2)`, depending on which header type is next (`NotStarted`). The first available `NotStarted` header is set to `Pending`.

**Q76. What is the OLS approval mode when `OLSItemType = 0`?**  
A: The OLS item is a Standalone Report (SAR). `OLSItemId` points to `WorkspaceReports.Id`.

**Q77. What is the OLS approval mode when `OLSItemType = 1`?**  
A: The OLS item is an Audience. `OLSItemId` points to `AppAudiences.Id`.

**Q78. How does the OLS approval mode (`AppBased` vs `AudienceBased`) affect the request?**  
A: In `AppBased` mode, the approvers come from `WorkspaceApps.Approvers`. In `AudienceBased` mode, the approvers come from `AppAudiences.Approvers` for the specific audience requested. The backend resolves and stores the approvers in `PermissionHeaders.Approvers` at request creation time.

**Q79. What does `PermissionHeaders.Approvers` store?**  
A: A comma-separated list of email addresses who can approve this specific permission header. Set at creation time from either the app-level or audience-level approvers list.

**Q80. After OLS is approved, what happens if the request also has an RLS header?**  
A: In `ApproveHeaderAsync`, after setting the OLS header to `Approved`, the code looks for the next `NotStarted` header. It finds the RLS header, sets it to `Pending`, and updates `RequestStatus` to `PendingRLS (2)`.

**Q81. What does it mean when `RequestStatus = Approved`?**  
A: All permission headers (OLS and/or RLS) have been approved. There are no more `NotStarted` headers. The request is fully approved and the user should now have access (for OLS-managed apps, after the next sync).

**Q82. Can a request have two OLS headers?**  
A: No. The unique constraint `UK_PermissionHeaders_Request_Type` on `(PermissionRequestId, PermissionType)` prevents it. There can be at most one OLS header and one RLS header per request.

**Q83. What `OLSItemId` value is stored in `OLSPermissions` — a single ID or a list?**  
A: Looking at the service code, `OLSItemId` is set to `request.SelectedReportIds` or `request.SelectedAudienceIds` — this suggests the entity may support multiple IDs per permission. However the table has a single `OLSItemId INT` column, so in practice one permission record per item is created (the service iterates or creates one per selection).

**Q84. What does `ReportDeliveryMethod` on the request determine?**  
A: Whether the OLS item type is `StandaloneReport (1)` or `Audience (0)` — which maps to `OLSPermissions.OLSItemType`.

**Q85. What is `RequestCode` on `PermissionRequests`?**  
A: A unique human-readable code for the request (e.g. "DFI-2024-001"). It is auto-generated by `GeneratePermissionRequestCodeAsync`. It has a unique constraint `UK_PermissionRequests_RequestCode`.

**Q86. How does the backend know which workspace to generate the request code for?**  
A: `request.WorkspaceId` is passed to `GeneratePermissionRequestCodeAsync`. The code typically incorporates the workspace domain code and a sequence number.

**Q87. What is `RequestReason` on `PermissionRequests`?**  
A: A free-text justification the requester provides explaining why they need the access. It is required (NOT NULL) and stored for audit purposes.

---

## 9. Permission Request Wizard — RLS Flow

**Q88. What additional information does an RLS request require compared to OLS?**  
A: It requires `SecurityModelId` (which security model to use), `SecurityTypeLoVId` (which security type variant), and the domain-specific dimensional key/hierarchy values (e.g. EntityKey, ClientKey, MSSKey etc. for AMER).

**Q89. How does the backend determine which RLS detail builder to use?**  
A: It calls `_uow.GeneratePermissionRequestCodeAsync` which returns `domainLov` — the workspace's domain LoV value. It then looks up this value in `_rlsDetailBuilders` dictionary to find the correct method.

**Q90. What does `BuildAmerDetails` do?**  
A: It creates and populates an `RLSPermissionAMERDetails` entity with the Entity, SL, Client, PC, CC, PA, and MSS key/hierarchy values from the request, then adds it to the `RLSPermission`.

**Q91. Why does "DFI" map to `BuildFumDetails` in the `_rlsDetailBuilders` dictionary?**  
A: DFI workspace uses the FUM (Finance Unified Model) security model. The domain code is DFI but the details structure is the same as FUM. Having "DFI" as an alias in the dictionary means the service handles DFI without needing a separate detail table.

**Q92. Why does "CGI" map to `BuildGiDetails`?**  
A: CGI is an alias for "Client & Growth Insights" which uses the same GI (Growth Insights) data structure. The dictionary has both "GI" and "CGI" pointing to the same builder.

**Q93. What happens to the RLS header when only RLS (no OLS) is in the request?**  
A: On LM approval, the first `NotStarted` header found is the RLS header. It is set to `Pending` and `RequestStatus` moves to `PendingRLS (2)`.

**Q94. After RLS is approved, is there any further sync required?**  
A: No. RLS data is stored directly in the DB (`RLSPermissions` + domain detail table). Power BI reads `Share[Domain].RLS` views directly. There is no sync script for RLS — approval means immediate visibility in Power BI on its next refresh.

**Q95. What is `AdditionalDetailsJSON` on `RLSPermissions`?**  
A: Optional extra metadata for the RLS permission. Could store additional context not covered by the structured Key/Hierarchy columns, e.g. custom notes or extra form answers.

**Q96. When creating an RLS permission, what validation runs regarding the domain?**  
A: The code checks `string.IsNullOrEmpty(domainLov) || !_rlsDetailBuilders.TryGetValue(domainLov, out var builder)`. If either condition is true, a `ValidationException` is thrown saying "Unsupported domain."

**Q97. How are RLS approvers resolved — are they stored at request creation time like OLS?**  
A: Yes. `request.RLSApprovers` is resolved before the request is created and stored in `PermissionHeaders.Approvers` as a comma-separated list. The resolution logic queries the appropriate `RLS[Domain]Approvers` table.

---

## 10. PermissionRequests Table

**Q98. What are all the `RequestStatus` values and their numeric codes?**  
A: 0 = PendingLM, 1 = PendingOLS, 2 = PendingRLS, 3 = Approved, 3 = Rejected (note: both Approved and Rejected are coded as 3 in the table comment — this is likely a documentation error; Rejected is typically a separate value like 4), 4 = Revoked, 5 = Cancelled.

**Q99. What does `RequestStatus = Cancelled` mean vs `RequestStatus = Rejected`?**  
A: Cancelled means the requester or an admin cancelled the request while it was still in a pending state. Rejected means an approver (LM, OLS, or RLS) explicitly rejected it.

**Q100. Can a `Cancelled` request be reactivated?**  
A: No — the `CancelAsync` method in the service marks all headers as `Cancelled` and the request as `Cancelled`. There is no reactivation path in the current codebase.

**Q101. Can the `LMApprover` be changed after a request is created?**  
A: No. `LMApprover` is set at creation time and there is no update method that changes it. The only way is a direct DB update.

**Q102. What is the `WorkspaceId` FK on `PermissionRequests` used for?**  
A: It ties the request to a specific workspace, which in turn determines available apps, audiences, security models, and the domain code for RLS routing.

**Q103. How many permission headers can a `PermissionRequest` have at most?**  
A: Two — one OLS header and one RLS header. The table comment says "min 1, max 2". The unique constraint on `(PermissionRequestId, PermissionType)` enforces this.

**Q104. How many permission headers must a `PermissionRequest` have at minimum?**  
A: One. The service validates `HasOLS || HasRLS` before creating the request.

---

## 11. PermissionHeaders Table

**Q105. What are all `ApprovalStatus` values and their codes?**  
A: 0 = NotStarted, 1 = Pending, 2 = Approved, 3 = Rejected, 4 = Revoked, 5 = Cancelled.

**Q106. What does `ApprovalStatus = NotStarted (0)` mean?**  
A: The header has been created but the approval process for it has not begun yet. This is the initial state when a multi-header request is created — the second header starts as `NotStarted` until the first is resolved.

**Q107. What is the difference between `NotStarted` and `Pending` for a header?**  
A: `NotStarted` means the header is waiting for the previous stage to complete. `Pending` means it is now active — the approvers have been notified and can take action.

**Q108. When does a header transition from `NotStarted` to `Pending`?**  
A: When the previous header (or the LM stage) is approved. In `ApproveLMAsync` or `ApproveHeaderAsync`, the code looks for the next `NotStarted` header and sets it to `Pending`.

**Q109. What fields are populated on a `PermissionHeader` when it is approved?**  
A: `ApprovalStatus = 2`, `ApprovedBy` (email of approver), `ApprovedAt` (timestamp), `ApproveNote` (optional note), `UpdatedAt/By`.

**Q110. What fields are populated on a `PermissionHeader` when it is rejected?**  
A: `ApprovalStatus = 3`, `RejectedBy`, `RejectedAt`, `RejectNote`, `UpdatedAt/By`.

**Q111. What happens to sibling headers when one header is rejected?**  
A: In `RejectHeaderAsync`, all other headers that are not already in a terminal state (Rejected/Revoked/Cancelled) are also set to `Rejected` with a reason note like "Rejected due to OLS rejection." The parent request's `RequestStatus` becomes `Rejected`.

**Q112. What fields are set on revocation?**  
A: `ApprovalStatus = 4`, `RevokedBy`, `RevokedAt`, `RevokeNote`, `UpdatedAt/By`.

**Q113. What is `PermissionType` on `PermissionHeaders`?**  
A: 0 = OLS, 1 = RLS. Determines what kind of permission this header represents.

**Q114. Why is there a unique constraint on `(PermissionRequestId, PermissionType)`?**  
A: To prevent duplicate OLS or RLS headers for the same request. A request can have at most one OLS header and one RLS header.

**Q115. What does `PermissionHeaders.Approvers` store?**  
A: A comma-separated list of approver emails who can approve this specific header. Populated at request creation from app/audience-level approver config for OLS, or from RLS approver tables for RLS.

---

## 12. OLSPermissions Table

**Q116. What is the relationship between `OLSPermissions` and `PermissionHeaders`?**  
A: One-to-one (unique constraint `UK_OLSPermissions` on `PermissionHeaderId`). Each OLS permission header has exactly one `OLSPermissions` record.

**Q117. What does `OLSItemType` mean?**  
A: 0 = Workspace Standalone Report (SAR) — `OLSItemId` references `WorkspaceReports.Id`. 1 = Audience — `OLSItemId` references `AppAudiences.Id`.

**Q118. What does `OLSItemId` reference?**  
A: Either `WorkspaceReports.Id` or `AppAudiences.Id`, depending on `OLSItemType`. It is not a FK-enforced reference (no FK constraint) — it's a flexible polymorphic ID.

**Q119. Why is there no FK constraint on `OLSItemId`?**  
A: Because it's polymorphic — it references different tables depending on `OLSItemType`. SQL Server FKs cannot be polymorphic, so the constraint is enforced at the application layer instead.

**Q120. What is `AdditionalDetailsJSON` on `OLSPermissions` used for?**  
A: Stores answers to any extra questions defined in `WorkspaceApps.AdditionalQuestionsJSON`. This is flexible JSON for custom form data that varies by app.

**Q121. Can a user have multiple OLS permissions for the same audience?**  
A: In theory no — at the business level, a new request would be created. The data model does not prevent it explicitly at the DB level (no unique constraint on `OLSItemId`), but the request workflow would handle duplicates at the business logic layer.

---

## 13. RLSPermissions Table

**Q122. What is the relationship between `RLSPermissions` and `PermissionHeaders`?**  
A: One-to-one (unique constraint `UK_RLSPermissions` on `PermissionHeaderId`). Each RLS permission header has exactly one `RLSPermissions` record.

**Q123. What two FKs on `RLSPermissions` determine the routing?**  
A: `SecurityModelId` → `WorkspaceSecurityModels.Id` and `SecurityTypeLoVId` → `LoVs.Id`. Together they identify which domain detail table to look up.

**Q124. How does the `romv.PermissionHeaders` view determine which detail table has data for a given `RLSPermissions` row?**  
A: It uses `OUTER APPLY` with `CROSS APPLY VALUES` against all 6 domain detail tables. Each sub-query filters by `RLSPermissionsId = RLSH.Id`. The one that finds a matching row returns its data; the others return nothing. `STRING_AGG` then concatenates all found Key|Hierarchy pairs.

**Q125. What is the `Info` field in `romv.PermissionHeaders` for RLS records?**  
A: A semicolon-separated string of "KeyValue|HierarchyValue" pairs from whichever domain detail table has data for that permission. E.g. "Global|Global; Overall|Default". Used by the backend to display a summary of the RLS scope in the UI.

**Q126. When is `AdditionalDetailsJSON` on `RLSPermissions` populated?**  
A: When there is extra metadata about the RLS grant that doesn't fit the structured dimensional columns. Optional — can be NULL.

---

## 14. RLS Domain Details — AMER

**Q127. What are all the dimensional columns in `RLSPermissionAMERDetails`?**  
A: EntityKey/EntityHierarchy, SLKey/SLHierarchy, ClientKey/ClientHierarchy, PCKey/PCHierarchy, CCKey/CCHierarchy, PAKey/PAHierarchy, MSSKey/MSSHierarchy. (7 dimension pairs = 14 columns plus Id, RLSPermissionsId, audit fields.)

**Q128. What does `SL` stand for in AMER RLS?**  
A: Service Line.

**Q129. What does `PC` stand for in AMER RLS?**  
A: Profit Center.

**Q130. What does `CC` stand for in AMER RLS?**  
A: Cost Center.

**Q131. What does `PA` stand for in AMER RLS?**  
A: Practice Area.

**Q132. What does `MSS` stand for in AMER RLS?**  
A: Management Segment / MSS is a common Dentsu abbreviation for a specific organizational dimension. It represents a strategic business unit classification.

**Q133. What security types are valid for AMER?**  
A: AMER-ORGA (Organization Based), AMER-CLIENT (Client Based), AMER-CC (Cost Center Based), AMER-PC (Profit Center Based), AMER-PA (Practice Area Based), AMER-MSS (MSS Based).

**Q134. Are all 7 dimension columns required for an AMER RLS permission?**  
A: No — all are nullable. Only the dimensions relevant to the security type being granted need to be populated. For AMER-CLIENT, for example, ClientKey would be populated; irrelevant dimensions can be NULL.

**Q135. How does `ShareAMER.RLS` handle NULL dimension values?**  
A: It uses `ISNULL(d.EntityKey, 'N/A')` for every column. NULLs are replaced with 'N/A' so Power BI sees a consistent string rather than NULL, which could break RLS filter expressions.

**Q136. What `ApprovalStatus` does `ShareAMER.RLS` filter on?**  
A: `ApprovalStatus = 2 (Approved)`. Only fully approved RLS permissions appear in the view.

**Q137. What `PermissionType` does `ShareAMER.RLS` filter on?**  
A: `PermissionType = 1 (RLS)`. OLS permissions are excluded.

---

## 15. RLS Domain Details — EMEA

**Q138. What dimensions does `RLSPermissionEMEADetails` have that AMER does not?**  
A: `CountryKey/CountryHierarchy`. EMEA has country as a dimension; AMER does not.

**Q139. What dimensions does AMER have that EMEA does not?**  
A: `PCKey/PCHierarchy` (Profit Center) and `PAKey/PAHierarchy` (Practice Area). EMEA doesn't use those dimensions.

**Q140. What security types are valid for EMEA?**  
A: EMEA-ORGA, EMEA-CLIENT, EMEA-CC, EMEA-COUNTRY, EMEA-MSS.

**Q141. What is EMEA-ORGA?**  
A: Organisation Based security type for EMEA. Grants access based on the organizational hierarchy (Entity, ServiceLine).

**Q142. What is EMEA-COUNTRY?**  
A: Country Based security type for EMEA. The country dimension (`CountryKey/CountryHierarchy`) is the primary scoping dimension.

**Q143. How many dimension pairs does `RLSPermissionEMEADetails` have?**  
A: 6 pairs — Entity, SL, Client, CC, Country, MSS (12 columns + Id + RLSPermissionsId + audit = 18 total data-meaningful columns).

---

## 16. RLS Domain Details — GI, CDI, WFI, FUM

**Q144. What dimensions does `RLSPermissionGIDetails` have?**  
A: Entity, Client, MSS, SL — 4 dimension pairs (8 columns).

**Q145. What dimensions does `RLSPermissionCDIDetails` have?**  
A: Entity, Client, SL — 3 dimension pairs (6 columns). The simplest multi-dimension detail table.

**Q146. What dimensions does `RLSPermissionWFIDetails` have?**  
A: Entity, PA (Practice Area) — only 2 dimension pairs (4 columns). The simplest detail table overall.

**Q147. What dimensions does `RLSPermissionFUMDetails` have?**  
A: Entity, Country, Client, MSS, ProfitCenter — 5 dimension pairs (10 columns).

**Q148. Why does FUM have `ProfitCenterKey/ProfitCenterHierarchy` rather than `PCKey/PCHierarchy` like AMER?**  
A: Naming convention difference. Both represent Profit Center but AMER uses the abbreviated column naming (PC) while FUM uses the full name (ProfitCenter). They represent the same concept but are different detail tables with their own conventions.

**Q149. Which domain has the most dimensions?**  
A: AMER with 7 dimension pairs (Entity, SL, Client, PC, CC, PA, MSS).

**Q150. Which domain has the fewest dimensions?**  
A: WFI with 2 dimension pairs (Entity, PA).

**Q151. What security type is used for GI requests?**  
A: `GI` — Growth Insights. There is one security type for GI (not subdivided like EMEA/AMER).

**Q152. What security type is used for WFI requests?**  
A: `WFI` — Workforce Insights. Single security type.

**Q153. What security type is used for CDI requests?**  
A: `CDI` — Client Data Insights. Single security type.

**Q154. What security type is used for FUM/DFI requests?**  
A: `FUM` — Finance Unified Model. Used by the DFI workspace.

---

## 17. Key vs Hierarchy Columns in RLS

**Q155. What is the difference between a `Key` column and a `Hierarchy` column in RLS detail tables?**  
A: `Key` holds the actual value/identifier for that dimension (e.g. a specific client code or entity code). `Hierarchy` indicates the level of the hierarchy the key represents (e.g. "Market", "Cluster", "Region", "Global") — it tells Power BI at what granularity to apply the filter.

**Q156. What does a NULL `Key` column mean in an RLS detail record?**  
A: The user's access is not scoped by that dimension. The permission applies across all values of that dimension. The view replaces NULL with 'N/A' for Power BI consumption.

**Q157. Why does Power BI need the `Hierarchy` value in addition to the `Key`?**  
A: Power BI's RLS expressions can be hierarchical — the hierarchy level tells it whether to match exactly (leaf level) or to match all children of a parent node. Without the hierarchy, Power BI wouldn't know whether "ABC" means a specific entity or a group of entities.

**Q158. What does `EntityHierarchy = 'Global'` typically mean?**  
A: The user has access to all entities (no entity restriction). This is often paired with `EntityKey = 'Global'` or `EntityKey = NULL` and results in the broadest possible access level.

**Q159. What does `EntityHierarchy = 'Market'` mean?**  
A: The user's access is restricted to a specific market (the narrowest entity level). `EntityKey` would contain the specific market code.

**Q160. In approver resolution, what traversal does entity hierarchy drive?**  
A: When looking up approvers, the system tries to find a matching row in the `RLS[Domain]Approvers` table. If no match at "Market" level, it moves up to "Cluster", then "Region", then "Global". This traversal applies only to EntityKey/EntityHierarchy — other dimensions stay fixed throughout the traversal.

**Q161. Why does the traversal apply only to Entity and not to other dimensions?**  
A: Entity is the primary organizational hierarchy. Other dimensions (Client, SL, MSS etc.) are point-in-time selections — there is no hierarchy of approvers for "a specific client" that rolls up. Only Entity has a defined geographic/org tree traversal.

---

## 18. Approver Resolution — LM Level

**Q162. What is the LM approver and when is it set?**  
A: The Line Manager (LM) is the first-stage approver for every permission request. The user selects or the system auto-fills their LM email at wizard start. It is stored in `PermissionRequests.LMApprover` at creation time.

**Q163. Can the LM approver be different from the OLS and RLS approvers?**  
A: Yes — they are completely separate. The LM is typically the requester's direct manager. OLS and RLS approvers are defined by the workspace/app configuration, not by the individual user's reporting line.

**Q164. What are the two actions an LM can take?**  
A: Approve (moves to the first pending header — OLS or RLS) or Reject (sets entire request and all headers to `Rejected`).

**Q165. In `ApproveLMAsync`, what stage validation runs?**  
A: `ValidateLmStage(entity)` — ensures the request is still in `PendingLM` status before allowing the LM decision. If it's already past that stage, the approval is rejected.

**Q166. What is concurrency checking in the approval flow?**  
A: `request.CheckConcurrency(entity)` validates that the client's version of the entity matches the current DB version. This prevents two users from simultaneously approving the same request and creating inconsistent state.

**Q167. After LM approval, if the request has only an RLS header, what status does the request move to?**  
A: `PendingRLS (2)`. The RLS header's `ApprovalStatus` moves from `NotStarted` to `Pending`.

**Q168. After LM approval, if the request has both OLS and RLS headers, which goes first?**  
A: OLS. The code finds the first `NotStarted` header — since OLS headers are added to the collection before RLS headers in `AddPermissionRequestAsync`, OLS is processed first.

---

## 19. Approver Resolution — OLS Level

**Q169. Where are OLS approvers stored at runtime?**  
A: In `PermissionHeaders.Approvers` as a comma-separated list. They are resolved and written there at request creation time.

**Q170. For `ApprovalMode = AppBased`, where does the OLS approver list come from?**  
A: `WorkspaceApps.Approvers` — the app-level approver list.

**Q171. For `ApprovalMode = AudienceBased`, where does the OLS approver list come from?**  
A: `AppAudiences.Approvers` — the audience-level approver list for the specific audience requested.

**Q172. Who can approve an OLS header?**  
A: Any user whose email appears in `PermissionHeaders.Approvers` for that header. The backend checks this in the approval endpoint.

**Q173. What happens when OLS is approved in a dual-header (OLS+RLS) request?**  
A: `ApproveHeaderAsync` sets OLS to `Approved`, then finds the next `NotStarted` header (the RLS header), sets it to `Pending`, updates `RequestStatus` to `PendingRLS`.

**Q174. Can a standalone report (SAR) have audience-based approval mode?**  
A: No — `ApprovalMode` is on `WorkspaceApps`, not on standalone reports. SAR reports have their own `Approvers` field on `WorkspaceReports`. They don't use the app's `ApprovalMode`.

---

## 20. Approver Resolution — RLS Level per Domain

**Q175. How are RLS approvers found?**  
A: By querying the relevant `RLS[Domain]Approvers` table (e.g. `RLSAMERApprovers`) filtered by `SecurityModelId`, `SecurityTypeLoVId`, and the dimensional Key/Hierarchy values the user selected in the wizard.

**Q176. What traversal strategy is used if no exact match is found in the RLS approvers table?**  
A: Entity-level traversal. Start at the user's requested entity level (e.g. Market). If no matching approver row is found, move up: Cluster → Region → Global. The first level that returns a match provides the approvers. Non-entity dimensions (Client, SL, MSS etc.) remain fixed throughout.

**Q177. What happens if no approver is found even at Global level?**  
A: No approver is found — the request cannot be submitted or is flagged with an error. The system requires at least one approver to be configured.

**Q178. Why is a separate approvers table used for each domain (RLSAMERApprovers, RLSEMEAApprovers etc.) instead of one table?**  
A: Each domain has a different set of dimensions. A single table would either have many NULL columns or require a more complex EAV design. Separate tables with exact columns for each domain are cleaner and more performant with indexes.

**Q179. What is the `Approvers` column in the `RLS[Domain]Approvers` tables?**  
A: A comma-separated list of email addresses who are responsible for approving RLS requests matching that dimensional combination for the given security model + type.

**Q180. Can the same dimensional combination have multiple approver rows?**  
A: No — each table has a unique constraint on the combination of SecurityModelId + SecurityTypeLoVId + all dimensional keys. Only one approver row per combination is allowed.

---

## 21. RLS Approver Tables

**Q181. What foreign keys do all RLS Approvers tables share?**  
A: `SecurityModelId → dbo.WorkspaceSecurityModels(Id)` and `SecurityTypeLoVId → dbo.LoVs(Id)`.

**Q182. What dimensions does `RLSAMERApprovers` have (matching which detail table)?**  
A: Entity, SL, Client, PC, CC, PA, MSS — exactly matching `RLSPermissionAMERDetails`.

**Q183. What dimensions does `RLSWFIApprovers` have?**  
A: Entity, PA — the simplest approvers table, matching `RLSPermissionWFIDetails`.

**Q184. What dimensions does `RLSFUMApprovers` have?**  
A: Entity, Country, Client, MSS, ProfitCenter — matching `RLSPermissionFUMDetails`.

**Q185. How are approvers tables populated in practice?**  
A: Via the WSO Console in the frontend (Approver Assignments feature) or directly via SQL seed scripts (e.g. `Script_Populate/1-DFI Script.sql`).

**Q186. Are the approver tables temporal (system-versioned)?**  
A: Yes. All `RLS[Domain]Approvers` tables use `SYSTEM_VERSIONING = ON` with corresponding `history.*` tables. Historical approver assignments are preserved.

---

## 22. Approval Workflow State Machine

**Q187. What is the complete state machine for `PermissionRequests.RequestStatus`?**  
A:  
- Created → `PendingLM (0)`  
- LM Approves → `PendingOLS (1)` or `PendingRLS (2)` (whichever is first)  
- OLS Approved (with RLS pending) → `PendingRLS (2)`  
- All headers approved → `Approved (3)`  
- LM or header Rejected → `Rejected`  
- User/admin cancels → `Cancelled (5)`  
- Admin revokes approved/pending → `Revoked (4)`  

**Q188. What is the complete state machine for `PermissionHeaders.ApprovalStatus`?**  
A:  
- Created → `NotStarted (0)` (if second header) or skipped if first  
- Previous stage complete → `Pending (1)`  
- Approver approves → `Approved (2)`  
- Approver rejects → `Rejected (3)` (siblings also rejected)  
- Admin revokes → `Revoked (4)`  
- Request cancelled → `Cancelled (5)`  

**Q189. Can a `Pending` header go back to `NotStarted`?**  
A: No — there is no backward transition defined in the service. The state machine is strictly forward-moving.

**Q190. If a request has OLS + RLS and the OLS is rejected, what happens to the RLS header?**  
A: In `RejectHeaderAsync`, all other headers that are not already in a terminal state are also set to `Rejected` with the note "Rejected due to OLS rejection." The request becomes `Rejected`.

**Q191. What validates that an LM decision can only happen when in `PendingLM` state?**  
A: `ValidateLmStage(entity)` called in both `ApproveLMAsync` and `RejectLmAsync`. It throws a validation exception if the request is not in the correct state.

**Q192. What validates header-level decisions happen at the correct stage?**  
A: `ValidateStage(entity, request.PermissionType)` in `ApproveHeaderAsync` and `RejectHeaderAsync`. This checks the request is in the expected `PendingOLS` or `PendingRLS` state before allowing the decision.

**Q193. What does `ApproveHeaderAsync` do if there is no next `NotStarted` header after approving one?**  
A: It sets `entity.RequestStatus = RequestStatus.Approved`. The request is fully approved.

**Q194. What request statuses can be revoked?**  
A: `PendingLM, PendingOLS, PendingRLS, Approved`. A request that is already `Rejected`, `Revoked`, or `Cancelled` cannot be revoked again.

**Q195. Is a revocation reason required?**  
A: Yes — in `RevokeAsync`, if `request.Reason` is null or whitespace, a `ValidationException` is thrown.

**Q196. After revocation, what status do the headers get?**  
A: In `RevokeAsync`, all headers that are not already terminal are set to `Revoked` with the revocation note and timestamp.

---

## 23. Revocation & Cancellation

**Q197. What is the difference between Revoke and Cancel?**  
A: Cancel is for in-progress requests (PendingLM/PendingOLS/PendingRLS) where the requester wants to withdraw before it's finalized. Revoke is for any non-terminal request including already-`Approved` ones — it is an administrative action to remove a previously granted permission.

**Q198. Who can cancel a request?**  
A: The requester or an admin. Cancellation is only allowed when `RequestStatus` is PendingLM, PendingOLS, or PendingRLS — not after final approval.

**Q199. What happens to an approved OLS permission when revoked?**  
A: The DB record is marked as Revoked. For managed apps, the user will be removed from the Entra group on the next nightly sync (because they will no longer appear in `Auto.OLSGroupMemberships`). For non-managed apps, the app owner reads the updated `Share[Domain].OLS` view and removes access manually.

**Q200. What happens to an approved RLS permission when revoked?**  
A: The DB record is marked as Revoked. Since `Share[Domain].RLS` views filter on `ApprovalStatus = 2 (Approved)`, the revoked permission disappears from the view immediately. Power BI will no longer see the record on its next refresh.

**Q201. Can a revoked request be re-approved?**  
A: No — there is no re-approval path. A new permission request would need to be submitted.

---

## 24. WSO Console — Approver Assignments

**Q202. What is the WSO Console in Sakura V2?**  
A: The Workspace Setup & Operations console — the admin UI used by workspace administrators to configure approvers, security models, apps, audiences, and other workspace-level settings.

**Q203. What is the Approver Assignments feature in the WSO Console used for?**  
A: To configure which users are responsible for approving RLS requests for specific dimensional combinations. This populates the `RLS[Domain]Approvers` tables.

**Q204. What data does an approver assignment row represent?**  
A: A combination of `SecurityModelId` + `SecurityTypeLoVId` + dimensional Key/Hierarchy values + a list of approver emails. It says "for requests of this type, scoped to this dimension, these people are the approvers."

**Q205. Why is the WSO console component (`approver-assignments.component.ts`) 4356 lines long?**  
A: It handles all 6 domain variants (AMER, EMEA, GI, CDI, WFI, FUM/DFI), each with different dimensional structures, plus CRUD operations, validation, filtering, pagination, and bulk operations across all of them. The complexity reflects the multi-domain nature of the approver configuration.

**Q206. What happens in the UI if a workspace has no approver rows configured for a specific security type?**  
A: The RLS approver resolution in the backend will find no match, even at Global level. Users attempting to submit an RLS request of that type will either get an error or the request will be created without OLS/RLS approvers (depending on backend validation), making it stuck.

---

## 25. Email Notification System

**Q207. What are the two tables that power the email system?**  
A: `dbo.EmailTemplates` (stores template keys, subjects, and HTML/text body templates) and `dbo.Emails` (the outbound email queue — one row per email to send).

**Q208. What is `EmailTemplateKey` on `EmailTemplates` used for?**  
A: A unique code that identifies the template (e.g. "LM_APPROVAL_REQUIRED", "OLS_APPROVED"). The application references templates by this key.

**Q209. What is `Email.Status` and what are its values?**  
A: 0 = New (ready to send), 1 = Retry, 2 = Sent, 3 = Error.

**Q210. What is `EmailingMode` in `ApplicationSettings` and what are its values?**  
A: A runtime switch: 0 = Skip (generate emails in the DB but don't actually send them), 1 = Send (actively send), 2 = Pause (queue emails, resume later).

**Q211. Why does the default `EmailingMode` in `ApplicationSettings_Default.sql` start at `0 (Skip)`?**  
A: Safety default — new deployments don't accidentally spam users. Ops must explicitly set it to `1 (Send)` to activate real email delivery.

**Q212. What is `ActiveEmailQueues` in `ApplicationSettings`?**  
A: A setting that controls which email queues are actively processed (default: `default_emea`). Emails are assigned to a `QueueName` — only emails in active queues are dispatched.

**Q213. What is `EmailRetryAfterMins`?**  
A: The number of minutes to wait before retrying a failed email. Default is 5 minutes.

**Q214. What is `EmailMaxRetrials`?**  
A: The maximum number of send attempts per email before giving up. Default is 10.

**Q215. What is `ContextEntityName` and `ContextId` on the `Emails` table?**  
A: They link the email to the entity that triggered it (e.g. `ContextEntityName = "PermissionRequest"`, `ContextId = "42"`). This allows tracing which emails were sent for which request.

**Q216. What is `EmailGuid` on `Emails` used for?**  
A: A unique identifier for the email (unique constraint). Prevents duplicate sends — if an email with the same GUID already exists, it won't be inserted again.

**Q217. What is `SakuraEmailSubjectTag` in `ApplicationSettings`?**  
A: A prefix added to all email subjects to identify the environment (e.g. "[Sakura-DEV]: " or "[Sakura]: "). Set via deployment variable `$(AppEnvironment)`.

---

## 26. OLS Managed vs Non-Managed

**Q218. What is the fundamental difference between Managed and NotManaged OLS?**  
A: Managed = Sakura automates Azure AD group membership via the nightly sync script. NotManaged = Sakura records the approval but the app owner manages access in their own system using the `Share[Domain].OLS` views.

**Q219. Where is `OLSMode` stored?**  
A: On `WorkspaceApps.OLSMode`. It is a per-app setting, not per-workspace.

**Q220. Can a workspace have some Managed and some NotManaged apps simultaneously?**  
A: Yes. Each app independently has its own `OLSMode`. A workspace could have App A as Managed and App B as NotManaged.

**Q221. In the `ShareAMER.OLS` view, what condition ensures only NotManaged apps are included?**  
A: `WA.OLSMode = 1` in the JOIN condition to `WorkspaceApps`. Managed apps are excluded from Share*.OLS views by design.

**Q222. Why are Managed apps excluded from the Share*.OLS views?**  
A: Because their membership is handled automatically by the sync script — the app owner doesn't need to do anything manually. Showing them in the Share views would be confusing and redundant.

**Q223. For a Managed app, what does `Auto.OLSGroupMemberships` need to have for the user to get access?**  
A: A row where `RequestedFor = user's email` and `EntraGroupUID = the audience's or app's Entra group GUID`. Currently this view is a hardcoded stub and needs to be rebuilt to dynamically derive data from approved `OLSPermissions` records.

**Q224. What is the current state of `Auto.OLSGroupMemberships` in the codebase?**  
A: It is a hardcoded stub with only 4 email addresses and a single hardcoded Entra group GUID. It needs to be replaced with a real SQL view that joins approved `OLSPermissions` → `PermissionHeaders` → `PermissionRequests` → `AppAudiences` to return real desired memberships.

**Q225. Who should be the audience for Share*.OLS views in production?**  
A: App owners and workspace technical owners of NotManaged apps. They query these views to know who has approved access and manage their PowerBI/app OLS accordingly.

---

## 27. Auto Schema — OLSGroupMemberships

**Q226. What columns does `Auto.OLSGroupMemberships` expose?**  
A: `RequestedFor` (user email), `EntraGroupUID` (Azure AD group GUID), `LastChangeDate` (timestamp of the last relevant change).

**Q227. Why is `LastChangeDate` included in `Auto.OLSGroupMemberships`?**  
A: It allows the sync script to do delta/incremental processing if needed — only sync records that changed since the last run. Currently the sync script does a full diff each run, but the column is designed to enable future optimization.

**Q228. What should the real `Auto.OLSGroupMemberships` view look like conceptually?**  
A: A query that joins: `OLSPermissions` (approved OLS records) → `PermissionHeaders` (filter PermissionType=0, ApprovalStatus=2) → `PermissionRequests` (get `RequestedFor`) → `AppAudiences` (get `AudienceEntraGroupUID`). Output: one row per (user email, Entra group GUID) pair for all currently approved managed-app memberships.

**Q229. What happens when a user's OLS permission is revoked, relative to `OLSGroupMemberships`?**  
A: The revoked record has `ApprovalStatus = 4 (Revoked)` — it would no longer appear in the real view (which only includes `ApprovalStatus = 2`). On the next sync, the user would appear in Azure AD but not in the desired state view → removed from the group.

**Q230. What schema is `OLSGroupMemberships` in?**  
A: The `Auto` schema. This separates automation-facing surfaces from application-facing (`dbo`) and Power BI-facing (`Share*`) surfaces.

---

## 28. SakuraV2ADSync.ps1 — Sync Script

**Q231. What does `SakuraV2ADSync.ps1` do at a high level?**  
A: Reads desired Azure AD group membership from `[Auto].[OLSGroupMemberships]`, compares it against current Azure AD group membership via Graph API, then adds missing users and removes obsolete users. Logs results and sends an email summary.

**Q232. How does the script authenticate to Microsoft Graph?**  
A: Using a service principal (client ID + client secret) via `Connect-MgGraph -ClientSecretCredential`. This is non-interactive and safe for scheduled/automated execution.

**Q233. What Graph API permission does the service principal need?**  
A: `Group.ReadWrite.All` as an Application permission (not delegated), with admin consent granted in Azure AD.

**Q234. What is the first data operation the sync script performs?**  
A: Opens a SQL connection and executes `SELECT [RequestedFor], [EntraGroupUID], [LastChangeDate] FROM [Auto].[OLSGroupMemberships]`. This is the desired state.

**Q235. After reading the desired state, what does the script do next?**  
A: Resolves all distinct user emails to Azure AD Object IDs using `Get-MgUser -Filter "userPrincipalName eq '...' or mail eq '...'"`. Results are cached in a `$userIdMap` hashtable.

**Q236. Why does the script look up both `userPrincipalName` and `mail`?**  
A: Some users may have their Sakura email stored differently from their UPN. Using both fields ensures the lookup finds the user regardless of which attribute holds their address.

**Q237. What happens if a user email in `OLSGroupMemberships` cannot be resolved to an Azure AD user?**  
A: The user is skipped for addition (no Object ID to add). They are not added to any group. A warning is logged. If `EventLog` integration is implemented, a `GroupMemberNotAdded` event is written.

**Q238. How does the script determine which users to REMOVE from a group?**  
A: For each group, it gets current Azure AD members (`Get-MgGroupMemberAsUser`). It builds a hashtable of desired members. Any user in Azure AD who is NOT in the desired hashtable is added to the "to remove" list.

**Q239. How does the script determine which users to ADD to a group?**  
A: It builds a hashtable of current Azure AD members. Any user in the desired state who is NOT in the current Azure AD members hashtable (and has a resolved Object ID) is added to the "to add" list.

**Q240. How are users added to groups — individually or in batches?**  
A: In batches of 20. The Graph API supports adding up to 20 members in one `Update-MgGroup` call using `members@odata.bind`. The script batches the adds in groups of 20.

**Q241. Why is batching needed?**  
A: The Microsoft Graph API has a per-request limit of 20 for bulk member additions via `members@odata.bind`. Individual calls for each member would be slower and hit throttling limits faster.

**Q242. How are users removed — in batches or individually?**  
A: Individually. `Remove-MgGroupMemberByRef` is called once per user. There is no bulk removal API equivalent to the bulk add.

**Q243. What does the script log to the `dbo.EventLog` table?**  
A: `GroupMemberAdded` (user successfully added), `GroupMemberRemoved` (user removed), `GroupMemberNotAdded` (user not found in AD or add failed).

**Q244. What does the email notification at the end of the script contain?**  
A: Subject indicates success or failure. Body contains groups processed count and error count. The log file is attached.

**Q245. How is the log file generated?**  
A: Via PowerShell's `Start-Transcript` at the start of the script and `Stop-Transcript` at the end. All `Write-Output` calls go to the transcript file as well as the console.

**Q246. What happens if the Graph connection fails at startup?**  
A: The script logs the error, calls `Stop-Transcript`, and exits with code 1. No sync is attempted.

**Q247. What Graph API call fetches all members of a group?**  
A: `Get-MgGroupMemberAsUser -GroupId $groupUID -ConsistencyLevel eventual -CountVariable memberCount -All -Property "id,displayName,mail"`. The `-ConsistencyLevel eventual` is required for `$count` and large group queries.

**Q248. What does `-ConsistencyLevel eventual` mean in Graph API calls?**  
A: It tells the Graph API to use eventual consistency rather than strong consistency. This is required for queries that use `$count` or advanced query features. Without it, those queries fail.

**Q249. What is `$odata.bind` used for in the add batch call?**  
A: `members@odata.bind` is a special OData navigation property syntax that tells Graph API to add the listed directory objects as members of the group. Each entry is a URL like `https://graph.microsoft.com/v1.0/directoryObjects/{objectId}`.

**Q250. How does the script handle a failed batch add?**  
A: It logs the error, increments `$errCount`, and continues to the next batch. It does not abort the entire sync for a single batch failure.

---

## 29. Service Principal vs Delegated Auth

**Q251. What is a service principal in Azure AD?**  
A: An application identity in Azure AD that acts as a non-human actor. It has its own client ID and can be granted permissions independently of any user. Used for automated, unattended processes.

**Q252. Why did V1's `SakuraADSync.ps1` fail in automation?**  
A: It used `Connect-MgGraph` with no parameters — interactive delegated authentication. This requires a browser popup to sign in. Task Scheduler cannot show a browser window, and the specific user account running it (`AP-MEDIA\sdhaka01`) lacked the required Graph API permissions.

**Q253. How does V2's `SakuraV2ADSync.ps1` solve the V1 auth problem?**  
A: It uses `Connect-MgGraph -TenantId ... -ClientSecretCredential ...` with a service principal. No browser, no interactive login. The service principal has `Group.ReadWrite.All` Application permission granted by an admin.

**Q254. What is the difference between Application and Delegated Graph API permissions?**  
A: Application permissions: the app acts as itself, no user involved, works without a logged-in user. Delegated permissions: the app acts on behalf of a logged-in user, requires a user to authenticate. For automation, Application permissions are required.

**Q255. What is `ClientSecretCredential` in the V2 sync script?**  
A: A `PSCredential` object built from the service principal's `ClientId` (as username) and `ClientSecret` (as secure string password). `Connect-MgGraph` accepts this to authenticate as the service principal.

**Q256. What is the risk of storing `ClientSecret` in the script file?**  
A: Plain-text secrets in source code are a security risk. In production, the secret should be stored in Azure Key Vault and retrieved at runtime, or injected as a pipeline variable/secret.

**Q257. What minimum Graph API permissions are needed for the sync script?**  
A: `Group.ReadWrite.All` (to add/remove group members) and `User.Read.All` (to look up users by email/UPN). Both must be Application permissions.

---

## 30. Share*.OLS Views

**Q258. How many Share*.OLS views are there?**  
A: Six — `ShareAMER.OLS`, `ShareEMEA.OLS`, `ShareGI.OLS`, `ShareFUM.OLS`, `ShareCDI.OLS`, `ShareWFI.OLS`.

**Q259. What is the purpose of the Share*.OLS views?**  
A: To expose approved OLS permissions for NotManaged apps so that app owners can read them and manually manage access in their own systems (PowerBI, other apps etc.). As the design note in the view says: "AppOwners can read this view and manage their own OLS."

**Q260. What filter ensures only NotManaged apps appear in Share*.OLS views?**  
A: `WA.OLSMode = 1` in the JOIN on `WorkspaceApps`.

**Q261. What filter ensures only approved records appear?**  
A: `PH.ApprovalStatus = 2 -- Approved` and `PH.PermissionType = 0 -- OLS`.

**Q262. What are the two branches of the `UNION ALL` in `ShareAMER.OLS`?**  
A: Branch 1: OLS permissions for Audiences (`OLSItemType = 1`). Branch 2: OLS permissions for Standalone Reports (`OLSItemType = 0`, `ReportDeliveryMethod = 1`).

**Q263. What does `OLSEntraGroupId` in the Share*.OLS view represent?**  
A: For audience records it comes from `AppAudiences.AudienceEntraGroupUID`. For standalone report records it comes from `WorkspaceReports.ReportEntraGroupUID`. It tells the app owner which Entra group to use for this item if they want to manage group-based access.

**Q264. What does the domain filter do in Share*.OLS views?**  
A: `DL.LoVValue = 'AMER'` (or the relevant domain) filters workspaces to only show those belonging to the AMER domain. This is how the view is domain-scoped.

**Q265. Who is the intended consumer of Share*.OLS views?**  
A: App owners and workspace technical owners of NotManaged apps. They query this view to see who has been approved and take action in their own systems.

**Q266. Do Share*.OLS views include revoked permissions?**  
A: No — only `ApprovalStatus = 2 (Approved)`. Revoked permissions fall out of the view automatically, so the app owner reading the view sees only currently valid grants.

---

## 31. Share*.RLS Views

**Q267. How many Share*.RLS views are there?**  
A: Six — `ShareAMER.RLS`, `ShareEMEA.RLS`, `ShareGI.RLS`, `ShareFUM.RLS`, `ShareCDI.RLS`, `ShareWFI.RLS`.

**Q268. What is the purpose of Share*.RLS views?**  
A: To be the direct Power BI consumption surface for RLS. Power BI datasets connect to these views to determine which data rows each user is allowed to see.

**Q269. What filters does `ShareAMER.RLS` apply?**  
A: `PH.PermissionType = 1 (RLS)` and `PH.ApprovalStatus = 2 (Approved)`. Only approved RLS headers are included.

**Q270. Why does `ShareAMER.RLS` use `ISNULL(d.EntityKey, 'N/A')` instead of just `d.EntityKey`?**  
A: Power BI RLS expressions typically compare against string values. If a column is NULL, the comparison `[EntityKey] = SomeValue` would evaluate to UNKNOWN (not TRUE or FALSE), breaking the filter. Replacing NULL with 'N/A' ensures consistent string matching behavior.

**Q271. What columns does `ShareAMER.RLS` expose to Power BI?**  
A: All 7 domain-specific Key/Hierarchy pairs (NULL-safe), `AdditionalDetailsJSON`, `SecurityType` (from LoV), `RequestedBy`, `RequestedFor`, `RequestDate`, `ApprovedBy`, `ApprovalDate`.

**Q272. Unlike Share*.OLS views, do Share*.RLS views have a domain filter?**  
A: No explicit domain filter by LoV — instead they join directly to the domain-specific detail table (e.g. `RLSPermissionAMERDetails`). Since that table only contains AMER records, it is implicitly domain-filtered.

**Q273. Is there a sync mechanism needed to keep Share*.RLS views current?**  
A: No. They are live SQL views — they reflect the current state of the DB instantly. When an RLS permission is approved, it appears in the view immediately. When revoked, it disappears. Power BI just needs to refresh its dataset to pick up changes.

**Q274. What happens if a user's RLS permission is revoked?**  
A: The `PermissionHeaders.ApprovalStatus` is set to `Revoked (4)`. The `ShareAMER.RLS` view only includes `ApprovalStatus = 2`, so the row disappears from the view. Power BI drops the user's row-level access on its next dataset refresh.

**Q275. What are the `Sample` versions of the Share views (e.g. `ShareAMER.RLSSample`)?**  
A: Static hardcoded test-data views used during Power BI dataset development when no real approved records exist yet. Developers point the Power BI dataset at the sample view during development, then switch to the live view for production.

---

## 32. Authentication & Authorization in the Backend

**Q276. How does the Sakura V2 backend support both local development and production Azure auth?**  
A: Via a feature flag `AppSettings:EnableAzureAuth`. When `true`, it uses `Microsoft.Identity.Web` (`AddMicrosoftIdentityWebApi`) to validate Entra ID Bearer tokens. When `false`, it uses locally-generated symmetric-key JWTs via a local `TokenService`.

**Q277. What is `LocalMockAuthMiddleware`?**  
A: A middleware that runs in local development (when `EnableAzureAuth = false`). It intercepts requests and provides mock authentication without requiring a real Azure AD token.

**Q278. What claims does `AuthController.GetMe()` extract from the token?**  
A: `oid` (Azure AD Object ID), `preferred_username`, `name`, `role`, `workspaceId`, `approverLevel`.

**Q279. Why is `AzureTokenValidator.cs` excluded from compilation?**  
A: It is an older manual token validation class (using OpenID Connect metadata). It has been superseded by `Microsoft.Identity.Web` middleware which handles validation automatically. The file is kept for reference but compiled out via the `.csproj`.

**Q280. What is `GlobalWorkspaceAccessService.HasAllWorkspacesAccessAsync` used for?**  
A: Checks if a user is in the `GlobalWorkspaceAccessUsers` table. If yes, the user bypasses the normal workspace filtering and sees all workspaces. This is the admin bypass for users like `sakurahelp@dentsu.com`.

**Q281. How does the backend filter which workspaces a normal user can see?**  
A: `WorkspaceService.GetWorkspacesForUserAsync` filters workspaces where the user's email appears in the `WorkspaceOwner`, `WorkspaceTechOwner`, or `WorkspaceApprover` CSV fields. If the user is in `GlobalWorkspaceAccessUsers`, all workspaces are returned.

**Q282. What is `role` in the JWT used for in V2?**  
A: It is a plain string embedded in the token. Currently there is no server-side role enforcement via `[Authorize(Roles)]` — the role claim is read and returned via `GetMe()` but not used to gate endpoint access beyond the basic `[Authorize]` attribute.

**Q283. What does `UserRoles` table contain?**  
A: Role definitions (`RoleName`, `RoleDescription`, `RoleStatus`). It exists in the DB but has no EF entity, no repository, and no service references it. It is currently dormant — wired up for future role-based authorization.

**Q284. What is the `AzureAd` config section in `appsettings.json` used for?**  
A: It contains `TenantId`, `ClientId`, and `Audience` for Entra ID JWT validation. `Microsoft.Identity.Web` reads this section to configure the token validation middleware.

**Q285. What is the `ValidAudiences` setting critical for?**  
A: It must match the `aud` claim in the JWT. If the audience in the token doesn't match `ValidAudiences`, token validation fails with a 401. This is a common misconfiguration issue when setting up the API behind a different URL than expected.

**Q286. What is the `SAKURA_ENTRA_ROADMAP_MASTER_TOKEN_ONLY.md` document about?**  
A: The master roadmap for the "token-only, no User table" Entra approach. It defines all work needed: creating `dbo.SupportUsers` and `dbo.PlatformAdmins` tables keyed by Azure AD oid, implementing `ICurrentUserService`, configuring Entra App Registrations, token claims, and all 6 phases of work.

---

## 33. GlobalWorkspaceAccessUsers

**Q287. What is `GlobalWorkspaceAccessUsers` used for?**  
A: A table of users who bypass the normal workspace visibility filter and can see ALL workspaces. Used for support/admin users.

**Q288. What is the seed data in `GlobalWorkspaceAccessUsers.sql`?**  
A: `sakurahelp@dentsu.com` with `Role = 'SakuraAdmin'` is seeded as the initial admin user. This gives the support mailbox full visibility of all workspaces.

**Q289. Is the `GlobalWorkspaceAccessUsers` table idempotent on deployment?**  
A: Yes. The SQL uses `IF NOT EXISTS` to check if the table exists, and within the `ELSE` branch, another `IF NOT EXISTS` checks if `sakurahelp@dentsu.com` already exists before inserting. Safe to run multiple times.

**Q290. Does `GlobalWorkspaceAccessUsers` require a code deployment to add a user?**  
A: No. The comment in the file says "Add or remove users by inserting/deleting rows or setting IsActive = 0. No deployment required." An admin just runs a SQL insert.

**Q291. What is the `Role` column on `GlobalWorkspaceAccessUsers` used for?**  
A: A label/note for why the user has global access. It is nullable and not enforced anywhere — purely informational.

**Q292. What is `IsActive` on `GlobalWorkspaceAccessUsers` used for?**  
A: Soft-disable. Setting `IsActive = 0` removes the global access without deleting the row, so the grant can be re-enabled easily.

---

## 34. EventLog & Audit

**Q293. What is the `EventLog` table used for?**  
A: An immutable audit trail. It records significant events: group member additions/removals/failures from the sync script. All major operations write to this table.

**Q294. What events does the V2 sync script write to `EventLog`?**  
A: `GroupMemberAdded`, `GroupMemberRemoved`, `GroupMemberNotAdded`.

**Q295. What information does an `EventLog` entry contain?**  
A: `TableName` (which entity the event relates to), `RecordId`, `EventTimestamp`, `EventName`, `EventDescription`, `EventTriggeredBy` (e.g. "SakuraV2ADSync.ps1").

**Q296. Who calls `Write-EventLogEntry` in the V2 sync script?**  
A: The `Log-SyncEvent` helper function, which is called after each successful add, removal, or "not found in AD" scenario.

**Q297. Are temporal history tables the same as the EventLog?**  
A: No. Temporal tables automatically track all row-level changes to DB records (every UPDATE creates a history row). EventLog is an application-level audit trail — it records business events (user added to group) not DB row changes.

---

## 35. Temporal Tables & Historisation

**Q298. Which tables in Sakura V2 are temporal (system-versioned)?**  
A: Nearly all core tables — Workspaces, WorkspaceApps, AppAudiences, WorkspaceReports, WorkspaceSecurityModels, SecurityModelSecurityTypeMap, LoVs, PermissionRequests, PermissionHeaders, OLSPermissions, RLSPermissions, all RLS domain detail tables, all RLS approver tables, EmailTemplates, UserRoles, ApplicationSettings, and more.

**Q299. What are `ValidFrom` and `ValidTo` columns on temporal tables?**  
A: System-maintained datetime2 columns that define the period during which a row version was current. `ValidFrom` is when the row was created/last updated. `ValidTo` is when it was superseded (or max datetime if still current). They are `GENERATED ALWAYS AS ROW START/END`.

**Q300. Where are historical versions of temporal table rows stored?**  
A: In corresponding `history.*` tables (e.g. `history.Workspaces`, `history.PermissionRequests`). SQL Server manages this automatically.

**Q301. How do you query a temporal table as it looked at a specific point in time?**  
A: Using `FOR SYSTEM_TIME AS OF '2024-01-01 12:00:00'` in the FROM clause. SQL Server automatically queries the history table for rows valid at that timestamp.

**Q302. Why is `DATA_CONSISTENCY_CHECK = ON` specified in temporal table definitions?**  
A: It tells SQL Server to verify that historical rows are consistent on table creation or modification. It's a safety check to ensure the history table is in sync with the main table.

**Q303. Can you UPDATE a row in a temporal table?**  
A: Yes. SQL Server automatically writes the old version to the history table before applying the update. The developer writes a normal UPDATE statement — historisation is transparent.

**Q304. Can you DELETE a row from a temporal table?**  
A: Yes technically, but in Sakura V2 the pattern is to use `IsActive = 0` (soft delete) rather than physical deletion. Physical deletion does remove the current row but the history rows remain.

---

## 36. V1 RDSecurityGroupPermission View

**Q305. What is `RDSecurityGroupPermission` in V1?**  
A: The central SQL view that defines the desired state of user-to-Azure-AD-group membership. It is the single object consumed by `SakuraADSync.ps1`. Its output is `(RequestedFor, SecurityGroupName, SecurityGroupGUID, LastChangeDate)`.

**Q306. What request types feed into `RDSecurityGroupPermission`?**  
A: `RequestType IN (0, 2, 7)` — Orga (0), Cost Center (2), and MSS (7). CP (Client Project = type 1), SGM (5), and DSR (6) are excluded.

**Q307. What approval status does `RDSecurityGroupPermission` filter on?**  
A: `ApprovalStatus = 1` (Approved). Only approved requests appear.

**Q308. How does the view match a user's service line to an Azure AD group?**  
A: Using `CHARINDEX(t.ServiceLineCode, SecurityGroupName, 1) > 0` — it checks if the service line code string is contained within the security group name. For example, a user with ServiceLine "CXM" would match the group "#SG-UN-SAKURA-CXM".

**Q309. What does the `UNION ALL` at the bottom of `RDSecurityGroupPermission` add?**  
A: Every approved user (regardless of request type) is added to the `#SG-UN-SAKURA-EntireOrg` group (PROD) or `#SG-UN-SAKURA-EntireOrg-UAT` (UAT). This grants basic app access in Power BI even if the user only has a CP request.

**Q310. What table defines the actual Azure AD group GUIDs in V1?**  
A: `dbo.ReportingDeckSecurityGroups` — it maps `ApplicationLoVId` + `ReportingDeckId` to `SecurityGroupGUID` + `SecurityGroupName`.

**Q311. What is `ServiceLine.SakuraPath` used for in the view?**  
A: The `OUTER APPLY` joins `PermissionOrgaDetail.ServiceLineCode` to `ServiceLine.SakuraPath LIKE '%|SL_CODE|%'`. This finds all service lines in the hierarchy that include the user's service line code, enabling hierarchical matching.

**Q312. What is the `EnvironmentTag` function used for in the EntireOrg union?**  
A: `CASE [dbo].[fnAppSettingValue]('EnvironmentTag') WHEN 'PROD' THEN ... ELSE ...` — it returns different group names and GUIDs for PROD vs UAT environments. The same view works in both environments.

---

## 37. V1 SakuraADSync.ps1

**Q313. What is the overall structure of `SakuraADSync.ps1`?**  
A: Five sections: (1) Global class definitions, (2) Utility functions, (3) Start transcript/log file, (4) Main execution (Graph connect, DB query, user/group resolution, diff and sync), (5) Stop transcript and send email.

**Q314. What classes are defined in `SakuraADSync.ps1`?**  
A: `RDSecurityGroupPermission` (fields: RequestedFor, SecurityGroupName, SecurityGroupGUID, LastChangeDate) and `RDSecurityGroup` (SecurityGroupName, SecurityGroupGUID).

**Q315. What does `WriteToLog` function do?**  
A: Writes a formatted log entry to the PowerShell transcript with timestamp, level (INFO/WARN/ERROR), and optional indentation. All output goes to both console and transcript file.

**Q316. What SQL connection string does V1 use?**  
A: Server=`azeuw1tsenmastersvrdb01.database.windows.net`, Database=`Sakura`, User=`SakuraAppAdmin`, Password=`Media+$2023`.

**Q317. How does V1 authenticate to Graph API?**  
A: `Connect-MgGraph` with no parameters — interactive delegated auth. This is the root cause of the automation failure.

**Q318. After reading all permission rows from `RDSecurityGroupPermission`, what does the script build first?**  
A: A `$hashLookupDistinctUsers` hashtable mapping each unique user email to their Azure AD Object ID (resolved via `Get-MgUser`).

**Q319. How does V1 handle a user not found in Azure AD?**  
A: Logs a WARN and skips them. The user is NOT added to any group. A `GroupMemberNotAdded` event is written to `EventLog` if the user appears in a group's desired members list but has no Object ID.

**Q320. How does V1 handle errors on a per-group basis?**  
A: Each group processing is wrapped in a try/catch. If an error occurs (e.g. can't fetch group from AD), `$errcount` is incremented and `continue` skips to the next group. The script doesn't abort on per-group errors.

**Q321. What determines success vs failure in the email subject?**  
A: `($errcount -eq 0) -and ($opcount -gt 0)` → "[Sakura AD Sync - TEST]: Success". Otherwise → "[Sakura AD Sync - TEST]: Failure".

**Q322. What is `PrintDivider` used for?**  
A: Prints a line of `=` characters to visually separate groups in the log output. Purely cosmetic.

**Q323. What SMTP server does V1 use for email?**  
A: `internalsmtprelay.media.global.loc` on port 25, with `EnableSSL = false`.

---

## 38. V1 vs V2 — OLS Comparison

**Q324. In V1, how was OLS controlled?**  
A: Via Azure AD Security Group membership. Power BI used group membership to control which reports/apps a user could access. The V1 sync script managed the group membership.

**Q325. In V2, how is OLS controlled for Managed apps?**  
A: Same mechanism — Entra group membership — but driven by the `Auto.OLSGroupMemberships` view and managed by `SakuraV2ADSync.ps1`.

**Q326. What V1 concept maps to V2's `Managed OLS`?**  
A: The entire V1 system — all OLS in V1 was "managed" (automated via the sync script). V2 introduces the concept of NotManaged apps as a new option.

**Q327. What is new in V2 that V1 didn't have?**  
A: NotManaged apps where app owners manage their own OLS. The `Share[Domain].OLS` views provide the handoff. V1 had no equivalent.

**Q328. What V1 table maps to V2's `AppAudiences.AudienceEntraGroupUID`?**  
A: V1's `ReportingDeckSecurityGroups.SecurityGroupGUID`. Both store the Azure AD group GUID that users should be members of.

**Q329. What V1 view maps to V2's `Auto.OLSGroupMemberships`?**  
A: V1's `dbo.RDSecurityGroupPermission`. Both are the "desired state" views consumed by the sync script. Column names differ (`SecurityGroupGUID` vs `EntraGroupUID`) but the purpose is identical.

**Q330. What is more granular in V2 — the group assignment?**  
A: Yes. In V1 groups were assigned at Reporting Deck level (service line code embedded in group name). In V2 groups are assigned at Audience level (`AudienceEntraGroupUID`) or App level (`AppEntraGroupUID`). V2 is more explicit and structured.

**Q331. Why did V1 embed service line codes in group names for matching?**  
A: Because the `CHARINDEX` string match was the only way to dynamically determine which groups a user should be in without storing explicit mappings per user. It was a clever but fragile workaround.

**Q332. How does V2 avoid the fragile string-matching approach?**  
A: By storing explicit `AudienceEntraGroupUID` on each audience. No string parsing — if a user is approved for Audience X, they go into the group whose GUID is stored on Audience X. Direct and explicit.

---

## 39. V1 vs V2 — RLS Comparison

**Q333. How was RLS implemented in V1?**  
A: Through the same Azure AD group membership mechanism as OLS. Power BI groups determined which data rows users could see. There was no separate RLS storage — the AD group membership was the RLS enforcement.

**Q334. How is RLS implemented in V2?**  
A: Via direct DB storage. Approved RLS records are stored in `RLSPermissions` + domain detail tables. Power BI reads `Share[Domain].RLS` views directly. No Azure AD group sync is needed for RLS in V2.

**Q335. In V1, was there a separate sync for RLS vs OLS?**  
A: No — `SakuraADSync.ps1` handled both. The `RDSecurityGroupPermission` view output covered both OLS (app access) and RLS (row filters) through AD group membership.

**Q336. In V2, does the sync script handle RLS?**  
A: No. `SakuraV2ADSync.ps1` only handles OLS (Managed apps → Entra group membership). RLS is handled entirely through DB writes and Power BI direct view access.

**Q337. What is the access latency difference between V1 and V2 for RLS?**  
A: V1: up to 24 hours (next nightly sync). V2: near real-time — approval writes to DB, Power BI refreshes its dataset on next scheduled refresh.

**Q338. How many RLS-related tables does V2 have that V1 did not?**  
A: 14+ tables: `RLSPermissions`, 6 domain detail tables (`RLSPermissionAMER/EMEA/GI/FUM/CDI/WFIDetails`), 6 domain approver tables (`RLS[Domain]Approvers`), plus `WorkspaceSecurityModels` and `SecurityModelSecurityTypeMap`. V1 had none of these — it relied entirely on AD groups.

**Q339. In V2, what enforces that RLS data is per-domain?**  
A: Separate domain detail tables. Each domain's dimensions are explicitly modeled. There is no cross-contamination — an AMER approval cannot accidentally affect EMEA data.

**Q340. How does V2's RLS support multiple security types for one domain (e.g. EMEA-ORGA vs EMEA-CLIENT)?**  
A: Via `RLSPermissions.SecurityTypeLoVId`. The same `RLSPermissionEMEADetails` table holds all EMEA requests regardless of type, but `SecurityTypeLoVId` distinguishes what type each grant is. Power BI can then filter by `SecurityType` in its RLS expressions.

---

## 40. V1 vs V2 — Auth & Sync Comparison

**Q341. What was the auth problem with V1's sync?**  
A: `Connect-MgGraph` with no parameters requires interactive browser login. This made automation impossible — Task Scheduler couldn't show a browser, and the script only worked when a specific authorized user ran it manually.

**Q342. How is V2's auth fundamentally different?**  
A: V2 uses a service principal with `ClientSecretCredential`. Non-interactive, safe for automated/scheduled execution. The service principal holds `Group.ReadWrite.All` Application permission.

**Q343. What is the practical deployment difference for the sync script?**  
A: V1: had to be run manually by a specific person. V2: can be scheduled via Azure DevOps pipeline, Task Scheduler, Azure Function, or any automation tool — no human involved.

**Q344. In V1, what was the only person who could reliably run the sync?**  
A: `EMEA-MEDIA\OOeztu01` — who had the required delegated Graph API permissions. Anyone else (including `AP-MEDIA\sdhaka01`) would get "insufficient permissions" from Graph.

**Q345. What is the V2 equivalent of the V1 `$hashLookupDistinctUsers` hashtable?**  
A: `$userIdMap` in `SakuraV2ADSync.ps1` — same concept, different name. Maps user email to Azure AD Object ID.

**Q346. What is the key naming difference between V1 and V2 view columns?**  
A: V1 used `SecurityGroupGUID`, V2 uses `EntraGroupUID`. V1 used `RequestedFor` → same in V2. V1 had `SecurityGroupName` (no equivalent in V2 view — name isn't needed for sync).

**Q347. Does V2's sync script need a `SecurityGroupName` column?**  
A: No. The sync only needs the GUID to call Graph API. The name is fetched from Graph API at runtime (`Get-MgGroup -GroupId $groupUID` → `$adGroup.DisplayName`) for logging purposes only.

**Q348. How does V2's sync handle the case where `Auto.OLSGroupMemberships` returns zero rows?**  
A: `$distinctGroupUIDs` would be empty. The foreach loop would not execute. `$opCount = 0`. The email subject would be "Completed with errors" (because `$opCount -eq 0`). No changes made to Azure AD.

**Q349. What is the V2 equivalent of V1's EntireOrg group union in the sync view?**  
A: Not yet implemented — the current `Auto.OLSGroupMemberships` stub doesn't include it. When the real view is built, a similar pattern could add all approved users to a base-access Entra group.

**Q350. Should `Auto.OLSGroupMemberships` filter by workspace domain (like V1 filtered by RequestType)?**  
A: Yes — it should filter by `ApprovalStatus = 2 (Approved)` and `OLSMode = 0 (Managed)` apps only. Non-managed apps should be excluded, just as V1 excluded CP/SGM request types from the sync view.

---

## Additional Deep-Dive Questions

### Architecture Edge Cases

**Q351. What happens if a `PermissionRequest` has OLS only and OLS gets rejected?**  
A: `RejectHeaderAsync` sets the OLS header to `Rejected`. Since there are no other headers, no sibling rejection happens. `RequestStatus` becomes `Rejected`.

**Q352. What happens if a `PermissionRequest` has RLS only and RLS gets rejected?**  
A: Same — RLS header set to `Rejected`, `RequestStatus = Rejected`. Clean.

**Q353. Can a user have two active (approved) `PermissionRequests` for the same workspace?**  
A: The DB doesn't prevent it — there is no unique constraint on `(RequestedFor, WorkspaceId)` in `PermissionRequests`. Business logic may prevent duplicate requests, but at the schema level it is allowed.

**Q354. What does `RequestCode` look like in practice?**  
A: It incorporates the workspace domain code (from `GeneratePermissionRequestCodeAsync`) and is unique. The exact format is determined by the stored procedure/function but typically includes domain + sequence.

**Q355. Why is there a unique constraint on `RequestCode`?**  
A: To allow human-readable reference to requests (e.g. in email notifications, support tickets). A user can quote their request code and support can look it up directly.

**Q356. What happens if `BuildGiDetails` is called but the request has no GI-specific dimension values?**  
A: All Key/Hierarchy fields would be NULL in `RLSPermissionGIDetails`. The record is created with all NULLs (except RLSPermissionsId and audit fields). This represents a "global" GI access grant.

**Q357. In `ApproveHeaderAsync`, what happens if `request.PermissionHeaderId = 0`?**  
A: The code falls back to `entity.PermissionHeaders.FirstOrDefault(h => h.PermissionType == request.PermissionType)`. It finds the first header of the requested type rather than looking up by specific ID.

**Q358. Why is concurrency checking important in the approval flow?**  
A: Two approvers might simultaneously try to approve the same header. Without concurrency checking, both could succeed, causing double-approval. The check ensures only one succeeds; the other gets a conflict error.

**Q359. What is the `IWorkspaceRequestService` dependency in `PermissionRequestService`?**  
A: Used to call `GeneratePermissionRequestCodeAsync` which returns the request code and domain LoV value needed for routing.

**Q360. What does `IRlsDomainDefinitionProvider` do?**  
A: Provides the domain-specific RLS definition (which dimensions apply to which domain). Used by the service to know how to build domain-specific detail entities.

### Database Design Patterns

**Q361. Why do all RLS detail tables use `NULL` for all dimension columns rather than `NOT NULL`?**  
A: Because not all dimensions are relevant for every request. A user requesting access at "Global" level would have NULL for all dimension-specific keys. NULLs represent "no restriction on this dimension."

**Q362. Why is `AdditionalDetailsJSON` on both `OLSPermissions` and `RLSPermissions` rather than on `PermissionHeaders`?**  
A: OLS and RLS have fundamentally different additional detail structures. Keeping it on each permission type separately allows different JSON schemas per type without a shared messy JSON blob.

**Q363. What is the purpose of the `history.*` schema in Sakura V2?**  
A: It holds all temporal history tables auto-managed by SQL Server system versioning. These tables are never written to directly — SQL Server maintains them automatically on every UPDATE/DELETE of the main tables.

**Q364. Why is `Email.Id` a `BIGINT` while most other tables use `INT`?**  
A: Email volume can be very high over time — one email per approval event across many requests. `BIGINT` provides a much larger range than `INT` for a table expected to grow continuously.

**Q365. Why does `ApplicationSettings` use `SettingKey/SettingValue` (key-value) design rather than explicit columns?**  
A: It allows new settings to be added without schema changes. Adding a setting is just an INSERT, not an ALTER TABLE. This makes the system more configurable without deployments.

### OLS & RLS Integration

**Q366. In the Share*.OLS view, why is there an `EXISTS` subquery for the SAR branch?**  
A: To ensure the standalone report's workspace has at least one NotManaged app. If the workspace only has Managed apps, standalone reports wouldn't need to be in the NotManaged Share view.

**Q367. Can a standalone report (SAR) belong to an audience-based OLS approval flow?**  
A: No. SARs use `OLSItemType = 0` and reference `WorkspaceReports.Id` directly. They have their own `Approvers` on the `WorkspaceReports` table. They are independent of the audience system.

**Q368. What is `ReportAppAudienceMap` used for?**  
A: It maps AUR (Audience Reports) to audiences. A report that is part of an audience-based app would have rows here linking `WorkspaceReports.Id` to `AppAudiences.Id`.

**Q369. Can the same report appear in multiple audiences?**  
A: Yes — `ReportAppAudienceMap` is a many-to-many table, so the same report can be linked to multiple audiences.

**Q370. What is `ReportSecurityModelMap` used for?**  
A: Links a `WorkspaceReport` to one or more `WorkspaceSecurityModels`. This defines which security models apply when requesting RLS access for a given report.

### Email System Deep Dive

**Q371. What is the `QueueName` column on `Emails` used for?**  
A: Different email queues can be processed at different rates or by different workers. The `ActiveEmailQueues` application setting determines which queues are being processed. Emails in inactive queues sit pending until their queue is activated.

**Q372. Why is there a `FromName` column separate from `From`?**  
A: `From` is the email address (e.g. `sakura@dentsu.com`). `FromName` is the display name shown to recipients (e.g. `Sakura`). Many email clients show "Sakura <sakura@dentsu.com>" using both.

**Q373. What is `EmailTemplateKey` on the `Emails` table (not `EmailTemplates`)?**  
A: Records which template was used to generate a given email. This allows tracing and analytics — you can see which template produced which emails.

**Q374. What is `DefaultEmailFrom` in `ApplicationSettings`?**  
A: The default sender address for all Sakura emails (`sakura@dentsu.com`). Individual emails can override this if needed.

**Q375. What is `SendAddedAsNewApproverEmails` in ApplicationSettings?**  
A: A flag (1/0) controlling whether emails are sent when a user is newly added as an approver. Default is 1 (send).

### Approver Resolution Deep Dive

**Q376. What doc describes approver finding flow in detail?**  
A: `Docs/Data_Entry/APPROVER_FINDING_FLOW.md`. It defines the 3-step chain (LM → OLS → RLS) with Mermaid diagrams per domain.

**Q377. According to `APPROVER_RESOLUTION_DB_VS_BACKEND_PLAN.md`, where should traversal logic live?**  
A: In the backend (C# application layer), not in SQL. The DB should have indexed single-level lookups. The backend orchestrates the traversal (Market → Cluster → Region → Global) with one DB call per level.

**Q378. What performance optimization is recommended for RLS approver lookups?**  
A: Composite indexes on the `RLS*Approvers` tables covering `SecurityModelId + SecurityTypeLoVId + EntityKey/EntityHierarchy` (and other dimensions). Combined with backend caching (`IMemoryCache` or Redis) to avoid repeated DB calls for common dimension combinations.

**Q379. What is the `PERMISSION_REQUEST_ENTRY_VS_APPROVAL_DIMENSIONS_CHECK.md` document about?**  
A: It identifies a mismatch between the permission request form (which shows only one dimension pair per security type) and the WSO approval dimension configuration (which requires combinations). 12 mismatches were found for CDI, AMER, EMEA. GI, WFI, DFI are OK.

**Q380. Which workspaces have single-type RLS (one security type, no variants)?**  
A: GI (just GI), WFI (just WFI), CDI (just CDI), DFI/FUM (just FUM). Only AMER and EMEA have multiple sub-types (ORGA, CLIENT, CC, etc.).

### Wizard Flow Details

**Q381. How many steps does the WFI permission request wizard have?**  
A: 3 steps — Step 1: Organisation Level, Step 2: Entity Selection (skipped if Global/N/A), Step 3: People Aggregator (Overall / Business Area / Business Function).

**Q382. What are the two security types in the GI wizard?**  
A: MSS-based (5 steps: Org → Entity → Client → MSS → Service Line) and SL/PA-based (4 steps: Org → Entity → Client → Service Line).

**Q383. What is the `Data_Entry/ARCHITECTURE.md` feature?**  
A: An optional Data Entry feature (behind a `enableDataEntry` feature flag) that provides a guided form interface for entering workspace configuration data (apps, audiences, security models, approvers etc.) — described as "better than Excel." It reuses existing backend APIs with no new tables.

### Infrastructure & Deployment

**Q384. What are the three Sakura V2 environments?**  
A: Dev (orange-sand Static Web App), UAT (lemon-wave), Prod (green-stone). Each has its own Azure Static Web App, Angular environment config, variable group, and App Service.

**Q385. Why was Prod sending traffic to the wrong Angular config?**  
A: The Prod pipeline YAML was missing `fileReplacements` in its Angular configuration. Without it, the build used the default `environment.ts` (which had `enableAzureAuth: false` / mock auth) instead of `environment.production.ts`. This was the root cause of Prod auth issues.

**Q386. What is the App Service used by the Sakura V2 backend?**  
A: `azeuw1pweb01sakura` in resource group `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL`.

**Q387. What is the 403 error that occurred on the Dev Static Web App?**  
A: DNS resolves to the public IP instead of the private endpoint IP `10.19.54.134`. Corporate DNS doesn't route to the private endpoint. Fix: link the private DNS zone to the VNet, or use hosts file as immediate workaround.

**Q388. What Azure AD App Registration permission is needed for the backend API?**  
A: The app registration needs a valid `ClientId`, `TenantId`, and `Audience`. Depending on the auth flow, either the frontend calls the backend with a user token (delegated), or the backend uses its own app identity.

**Q389. What pipeline deploys the Sakura frontend to Dev?**  
A: `Sakura_Frontend_Dev_Build_Release` (definition ID 118). It uses Node 20, `npm ci`, lint, tests, and `AzureStaticWebApp@0` deploy task. Variable group: `Azure-Static-Web-Apps-orange-sand-03a59b103-variable-group`.

### Final Integration Questions

**Q390. If you wanted to test that the full OLS flow works end-to-end, what would you check?**  
A: (1) Create a permission request with OLS for a Managed app. (2) LM approves. (3) OLS approver approves. (4) Verify `Auto.OLSGroupMemberships` includes the user+group pair. (5) Run `SakuraV2ADSync.ps1`. (6) Verify the user is now a member of the Entra group in Azure AD.

**Q391. If you wanted to test that the full RLS flow works end-to-end, what would you check?**  
A: (1) Create a permission request with RLS for an AMER workspace. (2) LM approves. (3) RLS approver approves. (4) Verify `ShareAMER.RLS` includes a row for the user with correct Key/Hierarchy values. (5) Verify Power BI dataset refresh picks up the new row.

**Q392. What would break if `AppAudiences.AudienceEntraGroupUID` is NULL for all audiences in a Managed app?**  
A: `Auto.OLSGroupMemberships` (once rebuilt) would have NULL `EntraGroupUID` for those users. The sync script would find no Entra group to add them to — they'd be logged as "not found" or skipped. Users would never get actual access.

**Q393. What would break if `WorkspaceSecurityModels` had no rows for a workspace?**  
A: Users couldn't create RLS requests for that workspace — there would be no valid `SecurityModelId` to reference. The wizard would show no security model options.

**Q394. What would break if `SecurityModelSecurityTypeMap` had no rows for a security model?**  
A: The wizard would show no security type options for that model. Users couldn't select any RLS type and couldn't proceed.

**Q395. What would break if the `RLS[Domain]Approvers` tables had no rows?**  
A: Approver resolution would return no approvers for any RLS request. Either the request can't be submitted (validation fails) or it proceeds with no approvers (stuck in Pending forever).

**Q396. If `EmailingMode = 0 (Skip)` in ApplicationSettings, do approval notification emails still get created in the DB?**  
A: Yes — the email records are inserted into `dbo.Emails` (so there's a record they were triggered), but they are not actually dispatched to recipients. The email worker skips them.

**Q397. If `Auto.OLSGroupMemberships` is a stub with hardcoded data, what happens when `SakuraV2ADSync.ps1` runs in a real environment?**  
A: It would manage group membership based on the 4 hardcoded entries only. Real approved users would not appear in the view and would not be added to groups. Users in Azure AD groups who are NOT in the stub would be REMOVED. This could cause significant unintended removals.

**Q398. What is the safest way to deploy the sync script initially?**  
A: Run it in a "dry run" mode first (log what it would add/remove without actually calling the Graph API mutation endpoints). Once the view is fully populated with real data and verified, enable actual mutations.

**Q399. How many Azure AD groups does a typical sync run process?**  
A: One per distinct `EntraGroupUID` in `Auto.OLSGroupMemberships`. Currently the stub has 1 group. In production, it would be one per active Managed app audience/report that has approved users.

**Q400. What is the difference between `ApprovalStatus = 2 (Approved)` in V2 vs `ApprovalStatus = 1 (Approved)` in V1?**  
A: In V1, `ApprovalStatus = 1` meant Approved. In V2, `ApprovalStatus = 2` means Approved (1 = Pending in V2). This is a key difference — if you copy a V1 SQL query to V2, the approval filter would be wrong.

---

### Bonus Questions — Tricky Edge Cases

**Q401. A user's permission is approved, they get Entra group access, then an admin revokes the permission. When exactly does the user lose access in Power BI (for OLS)?**  
A: They lose access the day after revocation — on the next nightly sync run. The sync reads `Auto.OLSGroupMemberships` (which no longer includes the revoked user), sees the user as "to remove," and calls `Remove-MgGroupMemberByRef`. After the sync, Power BI sees the user is no longer in the group.

**Q402. A user's RLS permission is approved, they can see data. An admin revokes it. When do they lose access in Power BI (for RLS)?**  
A: On the next Power BI dataset refresh after revocation. The `Share[Domain].RLS` view is live — the revoked record disappears immediately from the view. The delay is only how long until Power BI refreshes its dataset.

**Q403. Can a user have OLS access (can see the app) but no RLS access (can't see any data)?**  
A: Yes. OLS and RLS are independent. A user could be in the Entra group for an app (OLS approved) but have no approved RLS record for that workspace. Power BI would show the app but no data.

**Q404. Can a user have RLS access (row data scoped) but no OLS access (can't open the app at all)?**  
A: Yes technically in the DB. But practically, a user without OLS group membership can't open the Power BI app. Their RLS record would be unused.

**Q405. If `OLSItemType = 0` (SAR) but `OLSItemId` points to an `AppAudiences.Id` by mistake, what happens?**  
A: The Share views' JOIN to `WorkspaceReports` (`ON WR.Id = OLS.OLSItemId`) would find no matching report, so the permission wouldn't appear in any view. The data is inconsistent but there's no FK to catch it.

**Q406. Why doesn't `OLSPermissions.OLSItemId` have a FK constraint?**  
A: Polymorphism — the same column references different tables depending on `OLSItemType`. SQL Server FKs must reference a single table. Application-layer validation must enforce consistency.

**Q407. If `PermissionHeaders.Approvers` is accidentally left empty, what happens?**  
A: No one can approve the header (no valid approver email). The request sits in `Pending` indefinitely. This is a data quality issue that can be prevented by validating the approver list at request creation.

**Q408. What happens if the same user submits two identical RLS requests for the same workspace?**  
A: Both would be created (no DB-level prevention). Both would go through the approval workflow independently. The user would end up with two `RLSPermissionAMERDetails` rows with the same data — duplicate but harmless from a Power BI perspective (both appear in `ShareAMER.RLS`).

**Q409. Can the LM reject a request and then re-submit on behalf of the user?**  
A: No — there's no re-open path. A new `PermissionRequest` must be created from scratch.

**Q410. What would happen to all history if you ran `ALTER TABLE [dbo].[Workspaces] SET (SYSTEM_VERSIONING = OFF)`?**  
A: System versioning would be disabled. The history table would still exist with all past versions, but no new versions would be written. The temporal query syntax would stop working. This is a destructive operation that should never be done in production.

**Q411. If `ApplicationSettings.EmailingMode = 2 (Pause)`, do approval emails eventually get sent?**  
A: Yes — when the mode is changed back to `1 (Send)`, the email worker picks up all queued emails in the active queues and sends them. The `Status = 0 (New)` emails that were skipped during Pause are retried.

**Q412. What is `LogReadEventGracePeriodMins` in ApplicationSettings?**  
A: A grace period (in minutes) for logging "read" events. If an event is read within this window, it may not be logged again. Default is 5 minutes.

**Q413. Why does EMEA have 5 security sub-types while AMER has 6?**  
A: AMER has an extra sub-type for Profit Center (AMER-PC) that EMEA doesn't have. Organizational structures differ between regions — AMER uses Profit Centers as a distinct dimension while EMEA does not.

**Q414. What is the `RevokedBy`, `RevokedAt`, `RevokeNote` audit trail on `PermissionHeaders` useful for?**  
A: Compliance — it records who revoked a permission, when, and why. This is important for auditing data access changes, especially in regulated industries.

**Q415. In `RejectLmAsync`, are individual header fields (like `RejectedBy`) set?**  
A: Looking at the code — in `RejectLmAsync`, the headers' `ApprovalStatus` is set to `Rejected` and `UpdatedAt/By` are set, but `RejectedBy`, `RejectedAt`, `RejectNote` are NOT explicitly set in that method. The LM rejection reason is at the request level, not the header level in LM stage.

**Q416. What does `ValidateLmStage` check?**  
A: It validates that the `PermissionRequest.RequestStatus == RequestStatus.PendingLM`. If not, it throws a validation exception preventing the LM action from proceeding.

**Q417. What is `request.CheckConcurrency(entity)` checking specifically?**  
A: It compares a timestamp or row version from the client request against the DB entity. If they don't match, it means someone else modified the entity since the client last read it — an optimistic concurrency conflict.

**Q418. Why is optimistic concurrency used rather than pessimistic (row locking)?**  
A: Optimistic concurrency is better for web applications where users hold data for extended periods (filling in a form). Pessimistic locking would block other users for too long. Optimistic lets multiple users work simultaneously and only fails when an actual conflict is detected.

**Q419. What does `FirstOrDefault` on `PermissionHeaders` ordered by `NotStarted` achieve?**  
A: It picks the first header that hasn't started yet. Since OLS headers are added before RLS headers in the `AddPermissionRequestAsync` method, OLS is naturally first in the collection, ensuring OLS is always processed before RLS.

**Q420. What is the `CGI` alias in the `_rlsDetailBuilders` dictionary for?**  
A: `CGI` stands for "Client & Growth Insights" — an alias for the GI domain. Some workspaces may be configured with domain LoV `CGI` instead of `GI`. The alias ensures both route to `BuildGiDetails` correctly.

---

### Final 100 Questions — Cross-Cutting Topics

**Q421. What does the `romv` schema name stand for?**  
A: "Read Only Meta Views" — they are views that enrich the data for reading/display purposes, never written to directly.

**Q422. What is `String_AGG` used for in `romv.PermissionHeaders`?**  
A: To concatenate all Key|Hierarchy pairs from the relevant domain detail table into a single semicolon-separated `Info` string, ordered by priority (EntityKey first, then other dimensions in order).

**Q423. What is `OUTER APPLY` used for in `romv.PermissionHeaders`?**  
A: To try all 6 domain detail sub-queries against each RLS permission record. Only the matching domain returns rows; others return nothing. `OUTER APPLY` ensures the main row still appears even if no detail sub-query matches (returns NULL for `Info`).

**Q424. What is `CROSS APPLY (VALUES ...)` used for in the detail sub-queries?**  
A: To "unpivot" the dimensional columns into rows, producing (Priority, KeyValue, HierarchyValue) tuples for each dimension. This allows `STRING_AGG` to concatenate them in priority order.

**Q425. Why does the AMER sub-query in `romv.PermissionHeaders` check `v.KeyValue IS NOT NULL`?**  
A: To exclude dimensions where no value was set (NULL key = no restriction on that dimension). Only populated dimensions should appear in the `Info` string.

**Q426. If a request has both OLS and RLS, what does `romv.PermissionRequests` show for `OLSStatus` and `RLSStatus`?**  
A: The current `ApprovalStatus` of each header. E.g. if OLS is approved and RLS is pending: `OLSStatus = 2, RLSStatus = 1`. If only OLS exists, `RLSStatus = NULL`.

**Q427. What is `MAX(CASE WHEN PH.PermissionType = 0 THEN PH.ApprovalStatus END)` doing in `romv.PermissionRequests`?**  
A: It uses conditional aggregation to pivot the OLS header's status into a single column. `MAX` handles the grouping — since there's at most one OLS header per request, `MAX` effectively selects its value.

**Q428. Why use `MAX` rather than just a plain `CASE`?**  
A: Because of the `GROUP BY` on request ID. Without aggregation, the non-grouped `ApprovalStatus` column would be invalid in a grouped query. `MAX` is the simplest aggregation for a "pick the one value" scenario.

**Q429. What is `LoVs.SystemDataTypeName` used for?**  
A: Maps the LoV to a .NET system type if needed for strong typing. For example, a LoV value representing a boolean might have `SystemDataTypeName = 'System.Boolean'`. Allows generic code to handle LoV values in a typed way.

**Q430. What is `LoVs.ParentLoVType` + `LoVs.ParentLoVValue` used for?**  
A: Hierarchical LoV relationships. A security type LoV (e.g. `AMER-CLIENT`) could reference its parent domain LoV (`AMER`). This enables filtered dropdowns: when a user selects domain "AMER", only security types with parent `AMER` are shown.

**Q431. What is the `WorkspaceTag` field on `Workspaces` used for in practice?**  
A: Appended to email subjects and resource labels when it differs from `WorkspaceCode`. For example if a workspace has code "DFI" but the tag should read "Finance", the subject might be "[Sakura]: [Finance] ..." rather than "[Sakura]: [DFI] ...".

**Q432. What happens to `Share[Domain].RLS` if the `history.RLSPermissions` table grows very large?**  
A: Nothing — `Share[Domain].RLS` only queries `dbo.RLSPermissions` (the current table), not the history table. Temporal history tables do not affect live query performance.

**Q433. What type of constraint is `CONSTRAINT UK_PermissionHeaders_Request_Type UNIQUE (PermissionRequestId, PermissionType)`?**  
A: A composite unique constraint. It prevents the same request from having two headers of the same type (two OLS or two RLS headers).

**Q434. In `RejectHeaderAsync`, why does rejecting one header also reject all sibling headers?**  
A: Business rule — if OLS is rejected, there's no point approving RLS (the user can't see the app anyway). And vice versa. An approval without the paired component is meaningless, so rejection cascades.

**Q435. What is the `rejectReasonForOther` string set to in sibling header rejection?**  
A: Either "Rejected due to OLS rejection." or "Rejected due to RLS rejection." depending on which header was originally rejected.

**Q436. What if an admin wants to reject only RLS but keep OLS approved?**  
A: Not supported by current logic — rejecting any header rejects all siblings. A workaround would be to manually revoke the RLS header after full approval if the business needs it.

**Q437. Can `RevokeAsync` revoke an already-rejected request?**  
A: No. The `revocableStatuses` array in the service contains `PendingLM, PendingOLS, PendingRLS, Approved`. `Rejected` is not in this list, so a `ValidationException` is thrown.

**Q438. What is the `ApproveNote` field on `PermissionHeaders`?**  
A: An optional free-text note the approver can leave when approving. E.g. "Approved for Q1 project access." Stored for audit purposes.

**Q439. What is `RejectNote` on `PermissionHeaders`?**  
A: The reason the approver provided for rejecting. It is typically required to be non-empty (enforced at API/business layer level) to prevent approvers from rejecting without explanation.

**Q440. What is `RevokeNote` on `PermissionHeaders`?**  
A: The reason the revoker provides. In `RevokeAsync`, the service validates `!string.IsNullOrWhiteSpace(request.Reason)` — a reason is mandatory for revocation.

**Q441. What does `CreatedBy` on `PermissionRequests` store vs `RequestedBy`?**  
A: `RequestedBy` is the person who submitted the request (may differ from `RequestedFor`). `CreatedBy` is the system user who inserted the row (usually same as `RequestedBy` but could be a system account in automated scenarios).

**Q442. What does `UpdatedBy` on tables track?**  
A: The email/identity of the last user who modified the record. Combined with `UpdatedAt`, it provides a basic "last modified by" audit trail at the row level (in addition to the full temporal history).

**Q443. Is `ApplicationSettings` a temporal table?**  
A: Yes — it has `ValidFrom`/`ValidTo` and `SYSTEM_VERSIONING = ON`. Setting changes are historised.

**Q444. Why would you historise application settings?**  
A: To audit configuration changes — e.g. "who changed `EmailingMode` to `0` and when?" In production this is valuable for debugging and compliance.

**Q445. What is the default `EmailingMode` on a fresh deployment?**  
A: `0 (Skip)` — emails are generated but not sent. This prevents accidental email delivery on first deployment.

**Q446. What email address is the `DefaultEmailFrom` in the seeded ApplicationSettings?**  
A: `sakura@dentsu.com`.

**Q447. What is `DefaultEmailFromName` in ApplicationSettings?**  
A: `Sakura` — the display name shown in email clients as the sender.

**Q448. How does `SakuraEmailSubjectTag` adapt per environment?**  
A: It is set via `$(AppEnvironment)` deployment variable. In Dev it might be "[Sakura-DEV]: ", in UAT "[Sakura-UAT]: ", in Prod "[Sakura]: ". This prevents users from confusing test emails with production emails.

**Q449. What is `AdminEmail` in ApplicationSettings for?**  
A: A fallback/admin email address (`onur.ozturk@dentsu.com`) used for system notifications, error reports, or as the default recipient for admin-level emails.

**Q450. What is `BaseUrl` in ApplicationSettings for?**  
A: The base URL of the Sakura portal, used to generate email links (e.g. "Click here to approve your request: {BaseUrl}/..."). Must be set correctly per environment.

**Q451. What is `EmailLandingZonePath` in ApplicationSettings?**  
A: The path within the application used for email deep links — e.g. `/Pages/LandingZone/EmailLandingPage`. Combined with `BaseUrl` to create full URLs in email bodies.

**Q452. Can `ApplicationSettings` rows be changed without a code deployment?**  
A: Yes — that's the whole point. An admin runs a SQL UPDATE and the application picks up the new setting value (depending on how it reads settings — at startup vs per-request).

**Q453. What is `EnvironmentTag` in ApplicationSettings used for in V2?**  
A: Same as V1 — distinguishing the environment (PROD vs non-PROD). In V2 it can control things like email subjects and any environment-dependent behavior.

**Q454. What does `LoVType = 'ApplicationSetting_EmailingMode'` enable?**  
A: The valid values for `EmailingMode` are defined as LoVs. This means they can be read and displayed in admin UI dropdowns dynamically, rather than being hardcoded in the frontend.

**Q455. What would be the consequence of setting `AppSettings:EnableAzureAuth = false` in production?**  
A: The API would use locally-generated symmetric-key JWTs instead of validating Entra ID tokens. Any request with any JWT would potentially be accepted. This is a critical security misconfiguration for production.

**Q456. What is `Microsoft.Identity.Web` library responsible for in the backend?**  
A: It configures JWT Bearer authentication middleware using the `AzureAd` settings section. It validates incoming Entra ID tokens — checking signature, issuer, audience, expiry — and extracts claims for the request principal.

**Q457. What happens if a user's Entra token has expired when they call the API?**  
A: `Microsoft.Identity.Web` middleware rejects the request with a 401 Unauthorized. The frontend must refresh the token using its refresh token and retry the call.

**Q458. What is `ICurrentUserService` mentioned in the Entra roadmap?**  
A: A planned service abstraction that provides the current user's identity (email, oid, roles) to any backend service. Currently identity is read directly from controller actions — `ICurrentUserService` would centralize this.

**Q459. What are `dbo.SupportUsers` and `dbo.PlatformAdmins` mentioned in the Entra roadmap?**  
A: Two planned tables keyed by Azure AD `oid` (not email). `SupportUsers` would hold Tier-1 support staff. `PlatformAdmins` would hold platform administrators. These replace the email-keyed `GlobalWorkspaceAccessUsers` approach with a more robust oid-keyed design.

**Q460. Why is oid-keyed better than email-keyed for user tables?**  
A: Azure AD oid is immutable — it never changes even if a user's email changes. Email addresses can change when users change departments or names. Using oid avoids broken access when email changes.

**Q461. What is the `EnvironmentTag` in `ApplicationSettings` in V1?**  
A: It is used in the `RDSecurityGroupPermission` view to dynamically select the PROD vs UAT Entra group GUIDs for the EntireOrg group. Same concept as V2 but applied to group selection.

**Q462. What is the key difference between `fnAppSettingValue` in V1 and how V2 reads application settings?**  
A: V1 uses a SQL function `fnAppSettingValue` to read settings inline in SQL queries. V2 reads settings through the C# application service layer from `ApplicationSettings` table. V2 decouples setting reads from SQL objects.

**Q463. What is a `ReportingDeck` in V1?**  
A: A named collection/bundle of Power BI reports. V1 had 24 Reporting Decks. Each deck could have associated security groups (`ReportingDeckSecurityGroups`). V2 replaced this with the `WorkspaceApps`/`AppAudiences` model.

**Q464. What V1 concept does V2's `WorkspaceApps` most closely replace?**  
A: `ReportingDeck` — both represent a collection of reports available under a workspace/application context. V2's naming is more intuitive (App vs Deck).

**Q465. What is `PermissionOrgaDetail` in V1 and what does it map to in V2?**  
A: V1's `PermissionOrgaDetail` stored the service line, entity, and cost center scoping for Orga-type requests. In V2 this maps to the domain detail tables (`RLSPermissionAMERDetails` etc.) which store the dimensional scope.

**Q466. In V1, what prevented CP (Client Project) requests from getting Entra group membership via the sync?**  
A: The `WHERE H.RequestType IN (0, 2, 7)` filter in `RDSecurityGroupPermission` explicitly excluded type 1 (CP). CP users still got the EntireOrg group (from the UNION ALL), but no service-line-specific group.

**Q467. Does V2 have an equivalent of V1's "EntireOrg" base-access group?**  
A: Not yet in the current stub. The real `Auto.OLSGroupMemberships` view when built could include a UNION ALL adding all approved users to a base-access group — mirroring V1's approach.

**Q468. What is `BulkImportSubmission` in V1?**  
A: A staging/bulk import mechanism for large batches of permission requests. V1 had stored procedures like `Populate_BulkImportSubmissionOrga_From_Orga_Requests.sql` for processing hundreds of requests at once during migrations.

**Q469. Does V2 have a bulk import equivalent?**  
A: Not in the current codebase. Individual wizard requests are the only creation path. The Data Entry feature (behind feature flag) could support bulk-entry workflows.

**Q470. What is the `process.sql` file in V1's Sakura_DB_Metadata?**  
A: A large SQL script (155KB) used to batch-process large numbers of permission requests — likely used during migrations or major bulk access grants. V2 has no equivalent.

**Q471. What does `RequestCode` generation depend on?**  
A: The workspace ID (to include the domain code prefix) and likely a sequence number from the DB. The exact logic is in `GeneratePermissionRequestCodeAsync` in the unit of work layer.

**Q472. What is `ISakuraUnitOfWork` responsible for?**  
A: It is the Unit of Work abstraction — coordinates multiple repository operations within a single transaction, provides `CommitAsync()` to persist all changes atomically, and provides `GetSakuraRepository<T, K>` for typed repository access.

**Q473. What is `IObjectMapper` in `PermissionRequestService`?**  
A: A mapping abstraction (likely wrapping AutoMapper or a custom mapper) that converts domain entities to response DTOs. E.g. `_mapper.Map<PermissionRequest, PermissionRequestResponse>(entity)`.

**Q474. What is `FluentValidation` used for in the service?**  
A: `ValidationException` from FluentValidation is thrown throughout the service for business rule violations. The API layer catches these and converts them to 400 Bad Request responses with validation error details.

**Q475. What entity is returned by all the service approval methods?**  
A: `IApiSingleResult<PermissionRequestResponse>`. This is a generic result wrapper that holds the mapped response DTO.

**Q476. What is `ReportDeliveryMethod` on the `CreatePermissionRequestRequest`?**  
A: An enum value (`StandaloneReport` or `Audience`) that determines `OLSItemType`. If `StandaloneReport`, `OLSItemId` comes from `SelectedReportIds`; if `Audience`, from `SelectedAudienceIds`.

**Q477. What does `request.OLSApprovers!` (with `!`) indicate in C#?**  
A: The null-forgiving operator — tells the compiler that `OLSApprovers` is not null here. It's used because the validation logic above should have already ensured it's set when `HasOLS = true`.

**Q478. What is `RLSApprovers!` similarly in the RLS header creation?**  
A: Same null-forgiving pattern — `request.RLSApprovers` is guaranteed non-null at this point in the flow (resolved before the request entity is built).

**Q479. What method signature does `ApproveLMAsync` have?**  
A: `Task<IApiSingleResult<PermissionRequestResponse>> ApproveLMAsync(int id, LmDecisionRequest request)` — takes the request ID and the LM's decision request body.

**Q480. What method signature does `ApproveHeaderAsync` have?**  
A: `Task<IApiSingleResult<PermissionRequestResponse>> ApproveHeaderAsync(int id, ApproveHeaderRequest request)` — takes the request ID and the approval request (containing which header to approve and an optional note).

**Q481. Why do approval methods load the entity with `p => p.PermissionHeaders` in the `FindBy` call?**  
A: To eagerly load the permission headers collection in one query. Without this, accessing `entity.PermissionHeaders` would trigger a lazy load (or throw if lazy loading is disabled), resulting in N+1 query problems.

**Q482. What is `FirstOrDefault` vs `First` and why does the service use `FirstOrDefault`?**  
A: `First` throws if no element is found. `FirstOrDefault` returns null. The service uses `FirstOrDefault` and then explicitly checks `if (entity is null)` to throw a descriptive `KeyNotFoundException`.

**Q483. What happens in `ApproveHeaderAsync` if both OLS and RLS headers are in `NotStarted` state?**  
A: This shouldn't happen — when LM approves, only the first header moves to `Pending`. The service always moves headers one at a time. But if both were somehow `NotStarted`, `FirstOrDefault` would pick OLS (first in the collection) and set it to `Pending`.

**Q484. What is `entity.PermissionHeaders.FirstOrDefault(h => h.ApprovalStatus == ApprovalStatus.NotStarted)` looking for?**  
A: The next header that hasn't started yet — either because it was waiting for a previous stage, or because it just became available after an approval. This is how the sequential pipeline (LM → OLS → RLS) advances.

**Q485. What is the `CancelAsync` validation check?**  
A: `entity.RequestStatus is not PendingLM and not PendingOLS and not PendingRLS` — if the request is already in a terminal state (`Approved`, `Rejected`, `Revoked`, `Cancelled`), cancellation is rejected with "Cannot cancel finalized request."

**Q486. Why is cancellation limited to pending states only?**  
A: Once approved or rejected, the outcome is final. Cancelling an approved request would need to be done via revocation (which has stricter requirements including a mandatory reason).

**Q487. After `CancelAsync`, what status do all headers get?**  
A: `ApprovalStatus.Cancelled (5)`.

**Q488. What is the `revocableStatuses` check in `RevokeAsync`?**  
A: It allows revocation only when `RequestStatus` is one of: `PendingLM`, `PendingOLS`, `PendingRLS`, `Approved`. `Rejected`, `Revoked`, `Cancelled` cannot be revoked.

**Q489. In `RevokeAsync`, which headers get revoked?**  
A: All headers that are not already in a terminal state (not already Rejected, Revoked, or Cancelled). The revoke note is written to each revoked header.

**Q490. What is the significance of `DateTime.UtcNow` vs `DateTime.Now` in the service?**  
A: `UtcNow` is used for most timestamps to ensure consistent UTC storage regardless of server timezone. Some places use `DateTime.Now` (local time) — this inconsistency exists in the code and could be a source of timezone-related bugs.

**Q491. What is the relationship between `PermissionRequestService` and `IWorkspaceRequestService`?**  
A: `PermissionRequestService` depends on `IWorkspaceRequestService` to call `GeneratePermissionRequestCodeAsync`. This avoids the permission service needing to know the code generation logic directly — it delegates to the workspace service.

**Q492. What is `IRlsDomainDefinitionProvider` injected into `PermissionRequestService` for?**  
A: It provides domain-specific RLS definitions — but looking at the service code, it is injected but the main use is via `_rlsDetailBuilders` dictionary. The provider may be used in the builders or for validation of which dimensions are required per domain.

**Q493. What is the `[DOMAIN]` part in `BuildAmerDetails`, `BuildEmeaDetails` etc.?**  
A: These are private methods in `PermissionRequestService` that create and attach the domain-specific detail entity (e.g. `RLSPermissionAMERDetails`) to the `RLSPermission` object.

**Q494. How does the batch addition in `SakuraV2ADSync.ps1` handle an array with fewer than 20 members?**  
A: `$batchCount = [Math]::Ceiling($toAdd.Count / $batchSize)` — for 5 members, this is `Ceiling(5/20) = 1`. The single batch contains all 5. The `$end` calculation ensures no out-of-bounds array access.

**Q495. What does `$batch = @($toAdd[$start..$end])` do in PowerShell?**  
A: Creates a new array by slicing `$toAdd` from index `$start` to `$end`. The `@()` ensures it's always treated as an array even if only one element is returned.

**Q496. What is `Remove-MgGroupMemberByRef` in the context of Graph API?**  
A: A Microsoft.Graph PowerShell cmdlet that removes a specific user (by Object ID) from a group's members. It calls the `DELETE /groups/{groupId}/members/{memberId}/$ref` Graph API endpoint.

**Q497. What is `Update-MgGroup` used for in the sync script?**  
A: It calls `PATCH /groups/{groupId}` with `members@odata.bind` array. This bulk-adds up to 20 members in a single Graph API call.

**Q498. What does `Get-MgGroupMemberAsUser` return vs `Get-MgGroupMember`?**  
A: `Get-MgGroupMemberAsUser` returns only user-type members (not service principals, devices, other groups). `Get-MgGroupMember` returns all member types. For Sakura's use case, user-only members is correct.

**Q499. What is `-CountVariable memberCount` in the `Get-MgGroupMemberAsUser` call?**  
A: Stores the total count of results in the `$memberCount` variable. With `-ConsistencyLevel eventual`, the API returns `@odata.count` in the response — this parameter captures it.

**Q500. Why is `-All` specified in the `Get-MgGroupMemberAsUser` call?**  
A: To retrieve all pages of results (handling pagination automatically). Without `-All`, only the first page (default 100 members) would be returned, missing members in large groups.

---

### Final 27 Questions

**Q501. What is `LoVDescription` on `LoVs` used for?**  
A: Human-readable description of the LoV entry. Used for tooltips, help text, and documentation in the UI.

**Q502. Why is `AppAudiences.IsActive` defaulted to `1`?**  
A: New audiences should be active by default. If someone creates an audience, it should immediately be usable in the permission wizard without requiring an extra activation step.

**Q503. What is `UK_AppAudiences` enforcing?**  
A: `UNIQUE (AppId, AudienceCode)` — an audience code must be unique within its app. Two apps can share the same audience code, but not two audiences within the same app.

**Q504. What happens to `WorkspaceApps.Approvers` when `ApprovalMode = AudienceBased`?**  
A: It should be NULL or ignored — when audience-based approval is used, approvers come from `AppAudiences.Approvers`. The app-level `Approvers` field is not used. It is nullable (`NULL`) to reflect this.

**Q505. What does `WA.IsActive = 1` in the Share*.OLS view ensure?**  
A: Only active apps appear. Soft-deleted apps (IsActive = 0) are excluded from the view, preventing stale permissions from appearing.

**Q506. What does `W.IsActive = 1` in the Share*.OLS view ensure?**  
A: Only active workspaces are included. If a workspace is soft-deleted, all its OLS records disappear from the view.

**Q507. What is the purpose of `AA.IsActive = 1` in the Audience branch of Share*.OLS?**  
A: Ensures only active audiences appear. A soft-deleted audience's permissions are excluded.

**Q508. In the SAR branch of Share*.OLS, why is `WR.IsActive = 1` checked?**  
A: To exclude permissions for soft-deleted reports. If a report is deactivated, its OLS permissions should no longer appear.

**Q509. What does the `EXISTS` subquery in the SAR branch of Share*.OLS check?**  
A: `EXISTS (SELECT 1 FROM WorkspaceApps WHERE WorkspaceId = WR.WorkspaceId AND OLSMode = 1 AND IsActive = 1)` — verifies the workspace has at least one active NotManaged app. This ensures standalone report permissions only appear in the NotManaged share view when appropriate.

**Q510. What is `PH.PermissionType = 0 -- OLS` checking in Share*.OLS views?**  
A: Ensuring only OLS permission headers are included. RLS headers (PermissionType = 1) are excluded from OLS views.

**Q511. What is `l.LoVValue AS SecurityType` in `ShareAMER.RLS`?**  
A: The security type label from the LoVs table (e.g. "AMER-ORGA", "AMER-CLIENT"). Power BI uses this column in RLS expressions to filter by security type.

**Q512. Why does `ShareAMER.RLS` use `LEFT JOIN dbo.LoVs`?**  
A: In case `SecurityTypeLoVId` is NULL or the LoV row doesn't exist — using LEFT JOIN ensures the permission record still appears, just with `SecurityType = NULL`.

**Q513. What are `RLSPermissionXDetails.RLSPermissionsId` values?**  
A: FK to `dbo.RLSPermissions.Id`. Each detail row belongs to exactly one `RLSPermissions` record.

**Q514. Why are there no unique constraints on the RLS domain detail tables (unlike RLSPermissions which has one)?**  
A: Because theoretically you could have multiple detail records per `RLSPermissionsId` (though current business logic creates only one). The unique constraint is on `RLSPermissions` (one per header), not on the detail table.

**Q515. What is `ApprovedAt` on `PermissionHeaders` used for?**  
A: Records the exact timestamp when an approver approved the header. Used in the `Share[Domain].RLS` view as `ApprovalDate` — important for audit and compliance reporting.

**Q516. What is `RequestDate` in the Share views derived from?**  
A: `PH.CreatedAt` (when the permission header was created) in `Share*.OLS`, and `pr.CreatedAt` in `Share*.RLS`. This is the request submission date.

**Q517. What is `RequestedBy` in Share views?**  
A: In `Share*.OLS`: `PH.CreatedBy` (who created the permission header — usually same as the requester). In `Share*.RLS`: `pr.RequestedBy` (explicit requester field from the `PermissionRequests` table).

**Q518. In `ShareAMER.RLS`, what is `pr.RequestedFor`?**  
A: The user who will receive the RLS access. This is the key field Power BI uses to match against the current report viewer and apply the row filters.

**Q519. How does Power BI use `RequestedFor` in the RLS view?**  
A: Power BI's RLS expressions compare `[RequestedFor] = USERPRINCIPALNAME()` (or similar DAX function). Rows where the current user's UPN matches `RequestedFor` determine their data access scope.

**Q520. What is `AdditionalDetailsJSON` exposed in `ShareAMER.RLS` for?**  
A: Extra context that Power BI or the app owner might use for advanced filtering. It's exposed as a raw JSON string — Power BI or custom queries can parse it if needed.

**Q521. What is `ApprovalDate` (`ph.ApprovedAt`) in Share*.RLS used for?**  
A: Audit trail. Power BI reports can show when access was approved. Also useful for time-bound access scenarios where you want to show only records approved before a certain date.

**Q522. What is `ApprovedBy` in Share*.RLS used for?**  
A: Records who approved the RLS grant. Used for audit purposes — "who approved this user's data access and when."

**Q523. What is the conceptual equivalent of `dbo.EventLog` in V1 for V2?**  
A: The same `dbo.EventLog` table — it exists in both V1 and V2. The V2 sync script writes the same event types (GroupMemberAdded, GroupMemberRemoved, GroupMemberNotAdded) to it.

**Q524. Why are `ValidFrom` and `ValidTo` marked as `GENERATED ALWAYS AS ROW START/END`?**  
A: SQL Server syntax for defining temporal table period columns. These are system-managed — you cannot manually INSERT or UPDATE them. SQL Server handles their values automatically.

**Q525. What is `DATA_CONSISTENCY_CHECK = ON` in temporal table `WITH` clause?**  
A: Ensures that when the system versioning is turned on (or when restoring), SQL Server verifies that the history table doesn't contain future-dated rows that violate the temporal contract. It's a data integrity check on activation.

**Q526. How many total tables are in the `dbo` schema of Sakura V2 (approximately)?**  
A: 31 tables are visible in the `Dbo/Tables` folder — including all RLS domain tables (6 detail + 6 approvers), permission tables, workspace tables, LoVs, ApplicationSettings, Emails, EmailTemplates, UserRoles, GlobalWorkspaceAccessUsers, and more.

**Q527. If you were starting from scratch and had to explain Sakura V2 in one sentence, what would it be?**  
A: Sakura V2 is a permission management portal that lets users request access to Power BI apps (OLS — automated via Entra group sync) and data rows (RLS — stored in the DB and read directly by Power BI), with a structured multi-stage approval workflow (LM → OLS → RLS) and full temporal audit history across all entities.

---

*End of Sakura V2 Study Guide — 527 Questions & Answers*
