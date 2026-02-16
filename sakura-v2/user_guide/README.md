# Sakura User Guide

Welcome to **Sakura** — the access request and workspace management application. This guide helps you complete everyday tasks step by step, with clear screenshots and short explanations so you know what to do and why it matters.

---

## What is Sakura?

Sakura lets you **request and manage access** to reports and apps within workspaces. Depending on your role, you can:

- **Request** access to reports or apps for yourself or others  
- **Approve or reject** access requests  
- **Configure** workspaces, apps, audiences, reports, and security models (Workspace Admins)  
- **Administer** the application: create workspaces, change settings, view logs (Administrators)

Everything is tied to **workspaces**: each workspace has its own apps, reports, and approval rules. You only see and manage what belongs to your workspace(s).

---

## Who are you?

Choose your role to jump to the right section. Each guide is step-by-step with screenshots.

| Role | Guide | What you'll do |
|------|--------|----------------|
| **Requester** | [Requester guide →](Requester.md) | Request access, view your requests, use the Report Catalogue, see your existing access |
| **Approver** | [Approver guide →](Approver.md) | View pending and past approvals, approve or reject requests, manage delegates, open Sakura from approval emails |
| **Workspace Admin** | [Workspace Admin guide →](Workspace_Admin.md) | Manage your workspace: apps, audiences, reports, security models, mappings, RLS approvers, view or revoke requests |
| **Administrator** | [Administrator guide →](Administrator.md) | Create workspaces, change application settings, view event logs, configure In-App Help |

---

## Signing in

Before following any role-specific steps, sign in with your work account.

1. Open the Sakura URL (e.g. your organisation’s Sakura link — Dev, UAT, or Production).
2. When prompted, sign in with your **work (Microsoft) account** (e.g. `your.name@dentsu.com`).
3. After sign-in, you are taken to the Sakura home or dashboard.

![Sign-in page – Microsoft work account prompt](https://placehold.co/600x400/EEE/31343C)

**Why it matters:** Sakura uses your organisation’s identity (e.g. Microsoft Entra). You only see workspaces and actions that your account is allowed to use.

### Sign-in troubleshooting

- **Cannot sign in or see "User" with no email after login:** Your administrator must enable Azure auth for the backend and set the correct redirect URIs in your organisation’s app registration. The backend needs `EnableAzureAuth = true`; the frontend needs the right API URL and Azure scope. Ask your IT or Sakura admin to check those settings.
- **Wrong workspace or no data:** You only see workspaces where you are an owner (Workspace Admin) or where you have requester/approver rights. If you should see a workspace and don’t, ask an Administrator to confirm your role and workspace ownership.

---

## Quick reference (within this guide)

| Topic | Where to look |
|-------|----------------|
| Request access, my requests, Report Catalogue | [Requester guide](Requester.md) |
| Pending approvals, approve/reject, delegates | [Approver guide](Approver.md) |
| Workspace setup: apps, audiences, reports, security | [Workspace Admin guide](Workspace_Admin.md) |
| Create workspaces, settings, event logs | [Administrator guide](Administrator.md) |

**Report types (in short):** **AUR** = audience report — users get access by being in an audience; **SAR** = single access report — users request access and an approver approves. Workspace Admins configure which reports are AUR or SAR and who the approvers are.

---

*Start with your role above and follow the linked guide. Every section has numbered steps and an image so you always know what to do. All links in this table stay inside the User Guide.*
