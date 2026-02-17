# Workspace Admin Guide

This guide is for **Workspace Admins** (WSO): users who manage a workspace’s apps, audiences, reports, security models, mappings, and approvers. You see only workspaces where you are listed as an owner.

---

## In this guide

| Section | What you'll do |
|--------|-----------------|
| [Open WSO and select workspace](#open-the-wso-console-and-select-your-workspace) | Enter the console and pick your workspace |
| [Change workspace properties](#change-workspace-properties) | Edit owner, approver, domain, etc. |
| [Manage Apps](#manage-apps-in-the-workspace) | List, add, edit, activate, deactivate apps |
| [Manage Audiences](#manage-audiences-for-audience-based-apps) | Add audiences for audience-based apps |
| [Associate reports with audience (AUR)](#associate-reports-with-an-audience-aur-only) | Link AUR reports to audiences |
| [Manage Reports](#manage-reports-in-the-workspace) | Add/edit reports, set AUR vs SAR and approvers |
| [Manage Security Models](#manage-security-models-in-the-workspace) | Add and maintain security models |
| [Link reports to Security Models](#link-reports-to-security-models) | Assign which models a report uses |
| [Manage RLS Approvers](#manage-rls-approvers-for-your-security-models) | Assign RLS approvers to security models |
| [View and revoke requests](#view-and-revoke-requests-in-your-workspace) | See and revoke workspace requests |
| [View user's security context](#view-a-users-security-context-in-the-workspace) | Check a user’s access in the workspace |
| [Export to Excel](#export-workspace-data-to-excel) | Export workspace data |

---

## What you can do as a Workspace Admin

- Everything a Requester can do  
- See the list of **workspaces** where you are in the Owner fields  
- **Change workspace properties** (including approvers); you cannot delete a workspace  
- **Define or deactivate Apps**, **Reports**, and **Security Models** in the workspace  
- For each report: **define which Security Models** it uses  
- For each app (if Approval Mode = Audience-based): **define or deactivate Audiences**  
- For each app: **define Additional Dynamic Questions**  
- For each app audience: **associate or remove Reports** (AUR only)  
- **Manage RLS Approvers** for your workspace’s security models  
- **View** all requests under your workspace and **revoke** access requests  
- **View** request details, history, and chain status; **view** a user’s security context in the workspace  
- **Export** workspace object data to Excel  
- **Deactivate** apps, audiences, reports, security models; **remove** report–audience and report–security model associations  

---

## Open the WSO Console and select your workspace

1. Sign in to Sakura (see [README](README.md#signing-in)).
2. Open **WSO Console** or **Workspace Console** (or the equivalent menu item).
3. You will see a list of **workspaces where you are an owner**. Select the workspace you want to manage.

![Image](screenshots/02_wso_console.png)

**Why it matters:** All following steps apply to the workspace you select. The console is the single place to manage apps, reports, audiences, and security.

---

## Select workspace (Predefined by Sakura Administrators)

Workspaces are created and assigned by **Sakura Administrators**. You only see workspaces where you are listed as an owner. After opening the WSO Console, select the workspace you want to manage from the list. The selected workspace determines which apps, reports, audiences, and security models you can configure.

![Image](screenshots/03_wso_workpace_selected.png)


**Why it matters:** Correct owners and approvers ensure the right people can manage the workspace and approve access.

> **Note:** You cannot delete a workspace; only an Administrator can create workspaces. You can deactivate one from the Admin area if your organisation allows it.

---

## Manage Apps in the workspace

### List apps

In the WSO Console, select your workspace and open the **Apps** tab. You see:

- **Tabs** for Apps, Audiences, Reports, and Mappings (with counts) so you can switch between them.
- **Search** — search apps by name, code, or owner.
- **Active only** — a toggle to show only active apps (on) or to include inactive apps (off).
- **Refresh** — reload the list.
- **Add new app** — open the form to add an app (see [Add App](#add-app)).

The **apps table** lists each app with: **App code**, **App name**, **App owner**, **Technical owner**, **Approval mode**, **OLS mode**, **Audiences** (count), **Status** (e.g. Active), **Last modified** (date and user), and **Actions** (⋮ menu for Edit, Deactivate, etc.). Use this list to find an app before editing, activating, or deactivating it.

![Image](screenshots/04_list_apps.png)

### Add App

![Image](screenshots/05_add_app_btn.png)

1. In the WSO Console, select your workspace and open the **Apps** tab or section.
2. Click **Add app**.
3. Enter **App code** and **App name**; set **Approval mode** (e.g. **Audience-based** or **Other**).
4. Save. The app appears in the workspace app list.

![Add app form – code, name, approval mode](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Apps are the containers for audiences and reports. Approval mode determines whether access is granted via audiences (AUR) or via per-request approval (SAR).

### Edit app

1. In **Apps**, find the app and click **Edit** (pencil).
2. Change **App code**, **App name**, **Approval mode**, or other fields as needed. Click **Save**.

![Apps list with Edit action](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Keeping app details correct ensures the right approval flow and naming for requesters and approvers.

### Activate app

1. In the WSO Console, open the **Apps** tab or section for your workspace.
2. If your organisation provides a list of available (inactive) apps, click **Activate app** (or the equivalent).
3. Choose the app to activate and confirm. The app becomes active in the workspace and can be used by requesters.

![Activate app from available apps list](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Activating an app from the predefined list adds it to your workspace without creating it from scratch.

### Deactivate app

1. In **Apps**, find the app and click **Deactivate**.
2. Confirm. The app is no longer active in the workspace; it will not appear for new requests but may still apply to existing access depending on your organisation’s rules.

![Apps list with Deactivate action](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Deactivating removes the app from use for new access requests while keeping historical data.

---

## Manage Audiences (for Audience-based apps)

1. In the WSO Console, select your workspace and open **Apps** → select an app whose **Approval mode** is **Audience-based**.
2. Open **Audiences** for that app.
3. Click **Add audience** (or **Define audience**). Enter **Audience code** and **Audience name** (and any other required fields). Save.
4. To deactivate an audience, use **Deactivate** on that audience.

![App Audiences list and Add audience form](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Audiences define who gets access to **Audience reports (AUR)**. You will link reports to audiences in the next steps.

> **Technical note:** Only apps with Approval Mode = **AudienceBased** allow audience management. AUR reports are linked to audiences; SAR (single-access) reports use approvers instead.

---

## Associate reports with an audience (AUR only)

1. In **Apps** → select an **Audience-based** app → **Audiences**.
2. Select an **Audience** and open **Reports** or **Associate reports** for that audience.
3. Add **Reports** that have **Report delivery method = AUR** (Audience report). Remove associations if needed.
4. Save.

![Audience – associate AUR reports](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** This links AUR reports to the audience so that members of the audience get access to those reports. (AUR = audience report, access by membership; SAR = single access report, access by approval.)

---

## Manage Reports in the workspace

### Add a report

1. In the WSO Console, select your workspace and open the **Reports** tab or section.
2. Click **Add report**.
3. Enter **Report code** and **Report name**.
4. Choose **Report delivery method**:
   - **AUR (Audience report):** delivered via an app audience; no per-report approvers.
   - **SAR (Single access report):** user requests access; you must enter **Approvers** (semicolon-separated emails).
5. For SAR, fill in **Approvers**. Then click **Save**.

![Add report form – delivery method and approvers](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Reports are what users request access to. AUR = access by audience membership; SAR = access by approval. The system uses the Approvers field to route SAR requests.

### Edit or deactivate a report

1. In **Reports**, find the report and click **Edit** or **Deactivate**.
2. For edit: change fields (including Approvers for SAR) and **Save**. For deactivate: confirm.

![Reports list with Edit / Deactivate](https://placehold.co/600x400/EEE/31343C)

---

## Manage Security Models in the workspace

1. In the WSO Console, select your workspace and open **Security Models** (or **Security models**).
2. Click **Add security model**. Enter **code**, **name**, and any required fields (e.g. type). Save.
3. To edit or deactivate a security model, use **Edit** or **Deactivate** on that row.

![Security Models list and Add form](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Security models define the security dimensions used in the workspace. Reports are linked to security models so the system knows which model applies to each report.

---

## Link reports to Security Models

1. In the WSO Console, go to **Reports** and select a **report** (or open the report’s **Security models** section).
2. Add or remove **Security models** that this report uses. Save.
3. Repeat for other reports as needed.

![Report – assign security models](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** This tells the app which security model applies when users request access to this report (e.g. for RLS approval routing).

---

## Manage RLS Approvers (for your security models)

1. In the WSO Console, open **Security Models** (or **RLS Approvers** / **Approver assignment**).
2. Select a **Security model** and open **RLS Approvers** (or the equivalent).
3. Add, edit, or remove **RLS approvers** according to your workspace’s security types and dimensions. Save.

![RLS Approvers – assign approvers to security model](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** RLS (row-level security) requests need the right approvers per security type/dimension. Defining them here ensures requests are routed correctly.

> **Coming soon:** Some workspaces use dimension-based wizards (e.g. GI, EMEA, AMER). Full step-by-step for those flows will be added when available.

---

## View and revoke requests in your workspace

### View all requests

1. In the WSO Console, select your workspace and open **Requests** (or **Access requests**).
2. You will see all requests created under this workspace. Use filters if available (status, date, requester).
3. Click a request to see **details**, **history**, and **chain status**.

![Workspace requests list](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** As a workspace admin you can monitor and follow up on all access requests in your scope.

### Revoke an access request

1. In **Requests**, find the request you want to revoke.
2. Open the request and click **Revoke** (or use a revoke action from the list). Confirm.
3. The request is revoked and access can be removed according to your organisation’s process.

![Revoke request confirmation](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Revoking is used when access should be taken back (e.g. role change or leave).

---

## View a user’s security context in the workspace

1. In the WSO Console, open **User context** or **User access** (or the equivalent).
2. Select or enter the **user** (e.g. email) and the **workspace**.
3. You will see that user’s **security context** (e.g. OLS/RLS access) within the workspace.

![User security context in workspace](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** This helps you verify what access a user has before approving or revoking.

---

## Export workspace data to Excel

1. In the WSO Console, select your workspace.
2. Find **Export** or **Export to Excel** (may be per section: e.g. export apps, reports, or full workspace).
3. Click to generate and download the Excel file.

![Export to Excel button / option](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Exports are useful for auditing, backup, or offline review of workspace configuration.

---

## Need more?

- **Requesters** use the reports and apps you configure: see [Requester guide](Requester.md).  
- **Approvers** act on the requests and approver lists you set: see [Approver guide](Approver.md).  
- **Administrators** create workspaces and manage app-wide settings: see [Administrator guide](Administrator.md).

*Everything you need is in this User Guide; the list in "What you can do as a Workspace Admin" is the full set of workspace capabilities.*





