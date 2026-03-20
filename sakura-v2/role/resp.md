# Sakura — Roles and Responsibilities (Simple Guide)

Easy-to-understand overview of each role. **Each responsibility is listed as a separate step.**

---

## Workspace roles (who manages the workspace)

### Workspace Owner
1. In charge of the workspace.
2. Sets up apps, reports, and who can approve.
3. Can change workspace settings (including approvers).
4. Cannot delete the workspace.
5. Sees only workspaces where they are listed as Owner.

### Technical Owner (Workspace)
1. Looks after technical setup (e.g. security, connections).
2. Can see and manage the same workspace as the Owner.
3. Focus is on technical configuration.

### Workspace Approver
1. Can open the workspace console (WSO).
2. Used to control who has access to manage the workspace.

---

## Approval roles (who approves access requests)

**Order:** Line Manager → then OLS Approver → then RLS Approver (when needed).

### Line Manager (LM)
1. Is the requester’s manager.
2. Always approves first (before anyone else).
3. Says yes or no to the request.
4. Ensures managerial sign-off before OLS or RLS approvers act.

### OLS Approver
1. Decides if the user can access this report or audience (object-level).
2. Approves after the Line Manager.
3. Validates that the business need for access is correct.
4. Stored in Approvers (per report, app, or audience). In the app this role is always called “OLS Approver”.

### RLS Approver (Data owner)
1. Decides which data rows the user can see in the report.
2. Approves after OLS when the request has new row-level access.
3. Grants the right level of data access (e.g. region, entity).

---

## App roles (per app)

### App Owner
1. Owns the app.
2. Responsible for how the app is set up (audiences, who approves, etc.).
3. For Unmanaged apps, may manage who has access using Sakura’s views.

### Technical Owner (Support contact)
1. Contact for technical or support questions about the app.
2. Can be the same person as the App Owner.

---

## Report role

### Report Owner
1. Owns the report (stored in **ReportOwner** in the database; separate from Approvers).
2. Sets report details (code, name, tag, delivery method).
3. For standalone reports (SAR), sets the list of OLS approvers in the **Approvers** field (those people become OLS Approvers; Report Owner does not approve unless also listed in Approvers).
4. In the backend, Report Owner is used only for “owner”/WSO-style access, not for who can approve — only the **Approvers** list is used for approval.

---

## System roles

### Admin
1. Has full system access.
2. Can create workspaces.
3. Can change application settings.
4. Can see all workspaces (not limited by ownership).
5. Can see emails, event logs, and configure in-app help.

### User
1. Normal user (default role).
2. Can request access (create requests, use Report Catalogue, My requests, My access).
3. If assigned as approver, can approve in My approvals and use Delegation.
4. Sees only what they are allowed (by workspace and approval role).

---

*For more detail, see [ROLES_AND_TYPES_REFERENCE.md](ROLES_AND_TYPES_REFERENCE.md).*
