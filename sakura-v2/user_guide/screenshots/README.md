# Screenshots for Sakura User Guide

This folder is for **real screenshots**. The User Guide uses the placeholder image **https://placehold.co/600x400/EEE/31343C** everywhere by default, so every step shows an image with no broken links and no dependency on external files. Each image is used in the markdown files under `Docs/UserGuide/` to improve clarity and retention.

---

## How to add screenshots

1. **Capture** the screen (or region) that matches the description in the table below. Use PNG for best quality.
2. **Save** the file in this folder (`Docs/UserGuide/screenshots/`) with the **exact filename** listed (e.g. `sign-in-page.png`).
3. **Optional:** Use a simple placeholder image (e.g. a “Screenshot needed” graphic) for any file not yet captured so links do not break in viewers that resolve relative paths.

The guide currently uses the placeholder URL everywhere. When you add a real screenshot, replace that URL in the guide with `screenshots/filename.png` so the real image displays.

---

## Checklist: all screenshot placeholders

Use this list to track which screenshots are done. Filenames must match exactly (case-sensitive on some systems).

### README (entry & sign-in)

| Filename | What to capture |
|----------|------------------|
| `sign-in-page.png` | Sakura sign-in page with Microsoft work account prompt (before or after entering email). |

---

### Requester

| Filename | What to capture |
|----------|------------------|
| `requester-my-requests-list.png` | List of “My requests” – table or card view showing request rows. |
| `requester-request-detail.png` | Single request detail: history and chain status visible. |
| `requester-create-request-form.png` | Create request form: workspace and report/app selection visible. |
| `requester-report-catalogue.png` | Report Catalogue: browsing workspaces and reports (tree or list). |
| `requester-existing-access.png` | “My existing access” (or equivalent) per workspace. |
| `requester-help-me.png` | “Help me” button and/or the help request form. |

---

### Approver

| Filename | What to capture |
|----------|------------------|
| `approver-pending-approvals-list.png` | Pending approvals list with optional filter (workspace, type). |
| `approver-previous-approvals-list.png` | Previous / history approvals list. |
| `approver-approve-reject-dialog.png` | Approve/Reject dialog with reason field (and Confirm). |
| `approver-bulk-approve-reject.png` | Bulk approve/reject: multiple requests selected and action button. |
| `approver-request-detail-chain-status.png` | Request detail with history and chain status (approver view). |
| `approver-requester-existing-rights.png` | Section showing requester’s existing rights in the workspace. |
| `approver-email-link.png` | Sample approval email with link that opens Sakura. |
| `approver-delegate-form.png` | Delegate form: person and date range (start/end). |

---

### Workspace Admin (WSO)

| Filename | What to capture |
|----------|------------------|
| `wso-console-workspace-list.png` | WSO Console: list of workspaces where the user is owner. |
| `wso-workspace-edit-form.png` | Workspace properties / edit form (all main fields visible). |
| `wso-app-add-form.png` | Add app form: code, name, approval mode. |
| `wso-apps-list-actions.png` | Apps list with Edit and Deactivate (or similar) actions. |
| `wso-audiences-list-add.png` | App Audiences list and “Add audience” (or form). |
| `wso-audience-associate-reports.png` | Audience: screen to associate AUR reports to the audience. |
| `wso-report-add-form.png` | Add report form: delivery method (AUR/SAR) and approvers field. |
| `wso-reports-list-actions.png` | Reports list with Edit / Deactivate actions. |
| `wso-security-models-list-add.png` | Security Models list and Add (or add form). |
| `wso-report-security-model-mapping.png` | Report: assign/link security models to the report. |
| `wso-rls-approvers-assignment.png` | RLS Approvers: assign approvers to a security model. |
| `wso-requests-list.png` | Workspace requests list (all requests under the workspace). |
| `wso-revoke-request.png` | Revoke request: confirmation dialog or success state. |
| `wso-user-security-context.png` | User security context in workspace (user + workspace, OLS/RLS view). |
| `wso-export-excel.png` | Export to Excel button or option in WSO. |

**Workspace Admin guide (step-by-step):** The updated [Workspace_Admin.md](../Workspace_Admin.md) uses numbered sections (§1–§11) and **17 screenshot points**. For each, capture the screen described in the **Screenshot:** line under the image. Suggested filenames: `wso-01-console-tabs-filter.png` (§1), `wso-02-apps-tab-list.png`, `wso-03-app-add-form.png` (§2), `wso-04-audiences-tab-list.png`, `wso-05-audience-add-form.png` (§3), `wso-06-reports-tab-list.png`, `wso-07-report-add-form.png` (§4), `wso-08-mappings-tab.png` (§5), `wso-09-security-models-list.png`, `wso-10-security-model-add-form.png` (§6), `wso-11-approver-ols-tab.png`, `wso-12-approver-rls-tab.png` (§7), `wso-13-permission-requests-list.png`, `wso-14-permission-revoke-confirm.png` (§8), `wso-15-access-management-summary.png`, `wso-16-access-revoke.png` (§9), `wso-17-audit-logs-tab.png` (§10).

---

### Administrator

| Filename | What to capture |
|----------|------------------|
| `admin-tabs-overview.png` | Admin area: Workspaces, List of Values, Application Settings tabs. |
| `admin-create-workspace-form.png` | Create workspace form with all fields visible. |
| `admin-workspace-created-success.png` | After create: success message and workspace in table. |
| `admin-workspace-list-actions.png` | Workspace list: expand row, Edit, Deactivate, Activate. |
| `admin-application-settings.png` | Application Settings list and edit view. |
| `admin-event-logs.png` | Event logs list with filters (if any). |
| `admin-in-app-help.png` | In-App Help configuration screen. |

---

## Summary count

| Section | Count |
|---------|-------|
| README | 1 |
| Requester | 6 |
| Approver | 8 |
| Workspace Admin | 17 (see WSO step-by-step list in guide) |
| Administrator | 7 |
| **Total** | **39** |

---

*Use the exact filenames above when you add PNGs. Then update the corresponding image link in the guide from the placeholder URL to `screenshots/filename.png` so the real screenshot appears.*
