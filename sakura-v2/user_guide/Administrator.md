# Administrator Guide

This guide is for **Administrators**: users who create workspaces, manage List of Values (LoV), and change application settings. Every step uses the **exact names and paths** you see in the Sakura app. Administrators can do everything other roles can do, plus the tasks below.

---

## In this guide

| Section | In the app |
|--------|------------|
| [Access Management](#access-management) | **Management** (left sidebar) → **Workspaces**, **List of Values (LoV)**, **Application Settings** |
| [Create a workspace](#create-a-workspace) | **Workspaces** tab → **Create workspace** |
| [Edit, activate, or deactivate a workspace](#edit-activate-or-deactivate-a-workspace) | **Workspaces** tab → expand, **Edit**, **Deactivate**, **Activate** |
| [Manage List of Values (LoV)](#manage-list-of-values-lov) | **List of Values (LoV)** tab |
| [Change application settings](#change-application-settings) | **Application Settings** tab |

---

## What you can do as an Administrator

- Everything that Requesters, Approvers, and Workspace Admins can do  
- **Create workspaces** and edit, activate, or deactivate them (**Management** → **Workspaces**)  
- **Manage List of Values (LoV)** (**Management** → **List of Values (LoV)**)  
- **Change application settings** (**Management** → **Application Settings**)  
- **View event logs** and **configure In-App Help** when enabled by your organisation    

---

## Access Management

1. Sign in to Sakura (see [README](README.md#signing-in)).
2. In the **left sidebar**, click **Management**. The page title is **System management**; the description is “Manage workspaces, List of Values (LoV), and system configurations”.
3. You will see **three tabs**: **Workspaces**, **List of Values (LoV)**, and **Application Settings**.

![Management – Workspaces, List of Values (LoV), Application Settings tabs](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Management is the only place where you can create workspaces and change global settings.

---

## Create a workspace

1. In **Management**, click the **Workspaces** tab.
2. Click **Create workspace**.
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

5. The new workspace appears in the table. The owner can then open **WSO console** and configure apps, audiences, reports, and security models.

![Workspace created – success and table](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Workspaces are the top-level containers. Only admins can create them; after that, workspace owners manage their content.

---

## Edit, activate, or deactivate a workspace

1. In **Management** → **Workspaces** tab, find the workspace in the table.
2. **View details:** Click the **expand arrow** on the left to see full properties and app count.
3. **Edit:** Click the **Edit** (pencil) icon, change fields, and **Save**.
4. **Deactivate:** Click **Deactivate** and confirm. Use the **Active only** / **Show all** toggle to include or hide inactive workspaces.

5. **Activate:** For an inactive workspace, click **Activate** to make it active again.

![Workspace list – expand, Edit, Deactivate, Activate](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Editing keeps owner and approver information correct; deactivating disables a workspace without deleting it.

---

## Manage List of Values (LoV)

1. In **Management**, click the **List of Values (LoV)** tab. The heading is **List of Values (LoV) Management**.
2. Use search and filters (e.g. by type) to find the LoV entries you need. Add, edit, or delete entries as allowed. Save changes.
3. LoV entries are used in dropdowns and configuration across Sakura. Application settings that start with `ApplicationSetting_` are stored as LoV.

![List of Values (LoV) tab](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** LoV drives consistent options across the app; admins maintain the master list.

---

## Change application settings

1. In **Management**, click the **Application Settings** tab. The description explains that settings are stored as LoV with types starting with `ApplicationSetting_`.
2. Find the setting you want to change (e.g. feature flags, URLs, or other keys). Edit the value and **Save**.

![Application Settings tab – list and edit](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Application settings control global behaviour (e.g. auth, integrations). Only admins should change them.

---

## Event logs and In-App Help

- **Event logs:** If your organisation has enabled event logging, it may appear as a separate area or under Management. Use it to review who did what and when.
- **In-App Help:** If In-App Help configuration is enabled, use it to set the help content users see inside Sakura. The exact location depends on your deployment.

---

## Need more?

- **Workspace Admins** configure the workspace after you create it: see [Workspace Admin guide](Workspace_Admin.md).  
- **Approvers** and **Requesters** use the workspaces and reports you and workspace owners set up: see [Approver guide](Approver.md) and [Requester guide](Requester.md).

*Everything you need is in this User Guide; the list in "What you can do as an Administrator" is the full set of admin capabilities. For sign-in or auth issues, see [Sign-in troubleshooting](README.md#sign-in-troubleshooting) in the main guide.*
