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
- For each app (if Approval Workflow = Audience Based): **define or deactivate Audiences**  
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

![WSO Console – list of workspaces where you are an owner](screenshots/02_wso_console.png)

**Why it matters:** All following steps apply to the workspace you select. The console is the single place to manage apps, reports, audiences, and security.

---

## Select workspace (Predefined by Sakura Administrators)

Workspaces are created and assigned by **Sakura Administrators**. You only see workspaces where you are listed as an owner. After opening the WSO Console, select the workspace you want to manage from the list. The selected workspace determines which apps, reports, audiences, and security models you can configure.

![Workspace selected – workspace name and context shown](screenshots/03_wso_workpace_selected.png)


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

The **apps table** lists each app with: **App code**, **App name**, **App owner**, **Technical owner**, **Approval mode**, **OLS mode**, **Audiences** (count), **Status** (e.g. Active), **Last modified** (date and user), and **Actions** (⋮ menu with **View Details**, **Edit App**, **Deactivate**). The count line shows “Showing X of Y total” (or a range when paginated). Use this list to find an app before editing or deactivating it.

![Apps tab – search, Active only toggle, Refresh, Add new app, and apps table](screenshots/04_list_apps.png)

### Add App

1. In the WSO Console, select your workspace and open the **Apps** tab.
2. Click **Add new app**.

![Add new app button on the Apps tab](screenshots/05_add_app_btn.png)

3. In the form, fill in the required fields:
   - **App code** — uppercase, max 50 characters (e.g. FIN, MKTG, HR). Cannot be changed after save.
   - **App name** — display name of the app.
   - **Workspace** — select the workspace (if not already set).
   - **App owner** — one or two owner email addresses.
   - **Support contact** — one or two technical owner email addresses.
   - **OLS Security Mode** — choose one:
     - **Unmanaged (Power BI manages security)** — Sakura does not manage app-level security.
     - **Managed (Sakura manages security)** — Sakura manages security; you must provide **App Entra Group UID** (Azure AD / Entra ID group GUID, 36 characters). This links the app to the Entra group for access sync.
   - **Approval Workflow** — choose one:
     - **App Based (Single approval for entire app)** — one approval covers the whole app; you can optionally set **OLS approver** emails.
     - **Audience Based (Separate approvals per audience)** — approvals are per audience; use this for AUR-style access.
   - **(Optional) Additional Dynamic Questions** — add custom questions that requesters see when requesting access to this app.

![Add new app form – code, name, workspace, owners, security and approval](screenshots/06_add_new_app_form.png)

![Filled add app form with sample values](screenshots/07_filled_app_form.png)

![Managed OLS mode – App Entra Group UID field (required when Managed)](screenshots/08_managed_entra_id.png)

![Additional Dynamic Questions editor (optional)](screenshots/09_additional_questions.png)

4. Click **Add new app** (or **Update App** when editing). A success message appears and the app is listed in the Apps table.

![Success message after adding an app](screenshots/10_success_message_app.png)

5. Confirm the new app in the list (e.g. turn off **Active only** if it does not appear).

![Apps list showing the newly added app](screenshots/11_newly_added_app.png)

**Why it matters:** Apps are the containers for audiences and reports. **Approval Workflow** determines whether access is by app-level approval (App Based) or by audience (Audience Based / AUR). **OLS Security Mode** and **App Entra Group UID** (when Managed) control how Sakura syncs with Power BI and Entra ID.

### Edit app

1. In the **Apps** tab, find the app and open the **Actions** menu (⋮).
2. Click **Edit App**. The same form opens with existing values; **App code** is read-only.
3. Change **App name**, **App owner**, **Support contact**, **OLS Security Mode**, **App Entra Group UID** (if Managed), **Approval Workflow**, **OLS approver** (if App Based), or **Additional Dynamic Questions**. Click **Update App**.

![Apps list – Actions menu with Edit App](screenshots/wso-apps-list-actions.png)

**Why it matters:** Keeping app details correct ensures the right approval flow and naming for requesters and approvers.

### Activate app

1. In the **Apps** tab, turn the **Active only** toggle **off** so inactive apps are shown.
2. If your organisation provides a way to activate a previously deactivated app, use the **Actions** menu (⋮) on that app and choose **Activate** (or the equivalent). Confirm.
3. The app status becomes **Active** and the app can be used by requesters again.

![Apps list with Active only off – activate or reactivate an app](screenshots/wso-apps-list-actions.png)

**Why it matters:** Reactivating an app restores it for new access requests without recreating it.

### Deactivate app

1. In the **Apps** tab, find the app and open the **Actions** menu (⋮).
2. Click **Deactivate App**. Confirm in the dialog.
3. The app status becomes inactive; it will not appear for new requests but may still apply to existing access depending on your organisation’s rules.

![Apps list – Actions menu with Deactivate App](screenshots/wso-apps-list-actions.png)

**Why it matters:** Deactivating removes the app from use for new access requests while keeping historical data.

---

## Manage Audiences (for Audience-based apps)

1. In the WSO Console, select your workspace and open the **Apps** tab, then select an app whose **Approval mode** is **Audience Based**.
2. Open the **Audiences** tab for that app.
3. Click **Add new audience**. Enter **Audience code** and **Audience name** (and any other required fields, e.g. **Audience Entra Group UID**). Click **Add new audience** (or **Update audience** when editing).
4. To deactivate an audience, open the **Actions** menu (⋮) on that audience and choose **Deactivate** (or the equivalent). Confirm.

![App Audiences list and Add audience form](screenshots/wso-audiences-list-add.png)

**Why it matters:** Audiences define who gets access to **Audience reports (AUR)**. You will link reports to audiences in the next steps.

> **Technical note:** Only apps with **Approval Workflow = Audience Based** allow audience management. AUR reports are linked to audiences; SAR (single-access) reports use approvers instead.

---

## Associate reports with an audience (AUR only)

1. In **Apps** → select an **Audience Based** app → **Audiences** tab.
2. Select an **Audience** and open **Reports** or **Associate reports** for that audience.
3. Add **Reports** that have **Report delivery method = AUR** (Audience report). Remove associations if needed.
4. Save.

![Audience – associate AUR reports](screenshots/wso-audience-associate-reports.png)

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

![Add report form – delivery method and approvers](screenshots/wso-report-add-form.png)

**Why it matters:** Reports are what users request access to. AUR = access by audience membership; SAR = access by approval. The system uses the Approvers field to route SAR requests.

### Edit or deactivate a report

1. In **Reports**, find the report and click **Edit** or **Deactivate**.
2. For edit: change fields (including Approvers for SAR) and **Save**. For deactivate: confirm.

![Reports list with Edit / Deactivate](screenshots/wso-reports-list-actions.png)

---

## Manage Security Models in the workspace

1. In the WSO Console, select your workspace and open **Security Models** (or **Security models**).
2. Click **Add security model**. Enter **code**, **name**, and any required fields (e.g. type). Save.
3. To edit or deactivate a security model, use **Edit** or **Deactivate** on that row.

![Security Models list and Add form](screenshots/wso-security-models-list-add.png)

**Why it matters:** Security models define the security dimensions used in the workspace. Reports are linked to security models so the system knows which model applies to each report.

---

## Link reports to Security Models

1. In the WSO Console, go to **Reports** and select a **report** (or open the report’s **Security models** section).
2. Add or remove **Security models** that this report uses. Save.
3. Repeat for other reports as needed.

![Report – assign security models](screenshots/wso-report-security-model-mapping.png)

**Why it matters:** This tells the app which security model applies when users request access to this report (e.g. for RLS approval routing).

---

## Manage RLS Approvers (for your security models)

1. In the WSO Console, open **Security Models** (or **RLS Approvers** / **Approver assignment**).
2. Select a **Security model** and open **RLS Approvers** (or the equivalent).
3. Add, edit, or remove **RLS approvers** according to your workspace’s security types and dimensions. Save.

![RLS Approvers – assign approvers to security model](screenshots/wso-rls-approvers-assignment.png)

**Why it matters:** RLS (row-level security) requests need the right approvers per security type/dimension. Defining them here ensures requests are routed correctly.

> **Coming soon:** Some workspaces use dimension-based wizards (e.g. GI, EMEA, AMER). Full step-by-step for those flows will be added when available.

---

## View and revoke requests in your workspace

### View all requests

1. In the WSO Console, select your workspace and open **Requests** (or **Access requests**).
2. You will see all requests created under this workspace. Use filters if available (status, date, requester).
3. Click a request to see **details**, **history**, and **chain status**.

![Workspace requests list](screenshots/wso-requests-list.png)

**Why it matters:** As a workspace admin you can monitor and follow up on all access requests in your scope.

### Revoke an access request

1. In **Requests**, find the request you want to revoke.
2. Open the request and click **Revoke** (or use a revoke action from the list). Confirm.
3. The request is revoked and access can be removed according to your organisation’s process.

![Revoke request confirmation](screenshots/wso-revoke-request.png)

**Why it matters:** Revoking is used when access should be taken back (e.g. role change or leave).

---

## View a user’s security context in the workspace

1. In the WSO Console, open **User context** or **User access** (or the equivalent).
2. Select or enter the **user** (e.g. email) and the **workspace**.
3. You will see that user’s **security context** (e.g. OLS/RLS access) within the workspace.

![User security context in workspace](screenshots/wso-user-security-context.png)

**Why it matters:** This helps you verify what access a user has before approving or revoking.

---

## Export workspace data to Excel

1. In the WSO Console, select your workspace.
2. Find **Export** or **Export to Excel** (may be per section: e.g. export apps, reports, or full workspace).
3. Click to generate and download the Excel file.

![Export to Excel button or option](screenshots/wso-export-excel.png)

**Why it matters:** Exports are useful for auditing, backup, or offline review of workspace configuration.

---

## Need more?

- **Requesters** use the reports and apps you configure: see [Requester guide](Requester.md).  
- **Approvers** act on the requests and approver lists you set: see [Approver guide](Approver.md).  
- **Administrators** create workspaces and manage app-wide settings: see [Administrator guide](Administrator.md).

*Everything you need is in this User Guide; the list in "What you can do as a Workspace Admin" is the full set of workspace capabilities.*




