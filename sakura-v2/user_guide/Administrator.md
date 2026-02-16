# Administrator Guide

This guide is for **Administrators**: users who create workspaces, change application settings, view event logs, and configure In-App Help. Administrators can do everything other roles can do, plus the tasks below.

---

## In this guide

| Section | What you'll do |
|--------|-----------------|
| [Access Admin areas](#access-admin-areas) | Open Workspaces, LoV, Application Settings |
| [Create a workspace](#create-a-workspace) | Add a new workspace with owner and approver |
| [Edit, activate, or deactivate a workspace](#edit-activate-or-deactivate-a-workspace) | Change workspace state and details |
| [Change application settings](#change-application-settings) | Update global app settings |
| [View event logs](#view-event-logs) | Open and filter event logs |
| [Configure In-App Help](#configure-in-app-help) | Set help content shown in the app |

---

## What you can do as an Administrator

- Everything that Requesters, Approvers, and Workspace Admins can do  
- **Create workspaces**  
- **Change application settings**  
- **See emails** (as configured)  
- **View event logs**  
- **Configure In-App Help**  

---

## Access Admin areas

1. Sign in to Sakura (see [README](README.md#signing-in)).
2. Open **Admin** or **Administration** (or **Workspace Management** for workspace list) from the main menu.
3. You will see tabs or sections such as **Workspaces**, **List of Values**, and **Application Settings**.

![Admin area – Workspaces, LoV, Application Settings tabs](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** The Admin area is the only place where you can create workspaces and change global settings.

---

## Create a workspace

1. Go to **Admin** → **Workspaces** (or **Workspace Management** → **Workspaces** tab).
2. Click **Create workspace** (or **Add workspace**).
3. Fill in the form:
   - **Workspace code** (e.g. `AUS-OPS`)
   - **Workspace name** (e.g. Australia Operations)
   - **Owner** (email of the workspace owner)
   - **Technical owner** (optional)
   - **Approver** (email)
   - **Domain** (select from dropdown)
   - **Tag** (optional, e.g. APAC-Region)
   - **Entra Group UID** (optional)
4. Click **Create** (or **Save**).

![Create workspace form – all fields](https://placehold.co/600x400/EEE/31343C)

5. The new workspace appears in the table. The owner can then open the **WSO Console** and configure apps, reports, and security models.

![Workspace created – success and table](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Workspaces are the top-level containers. Only admins can create them; after that, workspace owners manage their content.

---

## Edit, activate, or deactivate a workspace

1. In **Admin** → **Workspaces**, find the workspace in the table.
2. **View details:** Click the expand arrow to see full properties and app count.
3. **Edit:** Click the **Edit** (pencil) icon, change fields, and **Save**.
4. **Deactivate:** Click **Deactivate** and confirm. The workspace becomes inactive (hidden from most views unless “Show all” is used).
5. **Activate:** For an inactive workspace, click **Activate** to make it active again.

![Workspace list – expand, Edit, Deactivate, Activate](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Editing keeps owner and approver information correct; deactivating disables a workspace without deleting it.

---

## Change application settings

1. Go to **Admin** → **Application Settings** (or **List of Values** if settings are managed via LoV).
2. Find the setting you want to change (e.g. feature flags, URLs, or other configuration keys).
3. Edit the value and **Save**.

![Application Settings – list and edit](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Application settings control global behaviour (e.g. auth, integrations). Only admins should change them.

---

## View event logs

1. Go to **Admin** → **Event logs** (or **Event Logs**).
2. Use filters if available (date range, user, workspace, event type).
3. Review the list of events. Click a row to see more detail if the UI supports it.

![Event logs list with filters](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Event logs help with auditing and troubleshooting (e.g. who did what and when).

---

## Configure In-App Help

1. Go to **Admin** → **In-App Help** (or **Help configuration**).
2. Add or edit **help content** (e.g. text, links, or sections) that users see inside the application.
3. Save. The updated help appears in the app according to your configuration.

![In-App Help configuration screen](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** In-App Help gives users guidance without leaving Sakura; you control what they see.

---

## Need more?

- **Workspace Admins** configure the workspace after you create it: see [Workspace Admin guide](Workspace_Admin.md).  
- **Approvers** and **Requesters** use the workspaces and reports you and workspace owners set up: see [Approver guide](Approver.md) and [Requester guide](Requester.md).

*Everything you need is in this User Guide; the list in "What you can do as an Administrator" is the full set of admin capabilities. For sign-in or auth issues, see [Sign-in troubleshooting](README.md#sign-in-troubleshooting) in the main guide.*
