# Video 1 – Introduction and Creating a Permission Request

**Frontend-verified:** Every label, button, and message below matches the current app. Do not say anything that is not in this script or the checklist.

---

## 1. Introduction (≈30 s)

- "In this video we'll see how to start a permission request in Sakura."
- "All permission requests are created from one place: the sidebar."
- "We'll open the form, fill the main fields, and submit. We'll also see what happens if a similar request already exists."

---

## 2. Where to create a request (≈30 s)

- "In the left sidebar, click **New permission request**."
- "You are taken to the permission request form. At the top you see the title **New permission request** and a link **Back to Dashboard**."
- "The hint says: *One form, one screen. Select a workspace and enter request details. RLS dimensions depend on the chosen workspace (CDI, AMER, WFI, GI, DFI, EMEA). One submit creates the request in Pending LM—no bypass of the approval flow.*"

---

## 3. The Request section (≈1 min)

- "The first section is **Request**."
- "**Workspace** is required. Open the dropdown—it says **— Select workspace —**. Choose the workspace you need. You can use the **Refresh** button to reload the list from the backend. After you select, you may see a badge with the workspace name and code."
- "**Requested for** is required. Enter the email of the person you are requesting access for—for example *john.doe@dentsu.com*. The hint says: *Enter a valid email and blur or press Enter to resolve LM approver.* When you leave the field or press Enter, the system resolves the Line Manager approver."
- "**Requested by** is required. This is read-only and comes from your profile—the logged-in user."
- "**LM approver** is required. It is set when you enter Requested for; you may see *Resolving…* while it loads. The placeholder says *Set when Requested for is entered*."
- "**Request reason** is required. Use the text area—placeholder *e.g. New hire access for CDI reporting*."

---

## 4. Include in request (≈20 s)

- "After you select a workspace, a second section appears: **Include in request**."
- "The hint says: *Check the types of access to include. You can include both OLS and RLS. Only checked sections will be shown and sent to the backend.*"
- "There are two checkboxes: **Include OLS (Object Level Security)** and **Include RLS (Row Level Security — dimensions for** [workspace code] **)**."
- "You must check at least one to submit. For this video we'll check **Include OLS** so the OLS section appears."

---

## 5. OLS section (minimal – for Video 1) (≈45 s)

- "The **OLS (Object Level Security)** section appears. It's marked as optional in the heading, but if you checked Include OLS you need to fill it to submit."
- "**OLS item type**: choose **Report (SAR)** or **Audience** from the dropdown **— Select —**."
- "**Report / Audience**: If you chose Report, you get a dropdown **— Select report —**. Only standalone reports (SAR) with approvers configured are listed. If you chose Audience, you see **App** and **Audience** dropdowns—**— Select app —** and **— Select audience —**—or you can type in **Or enter Audience ID**."
- "Then click the button **Resolve OLS approvers**. When it's done you'll see a line like *OLS approvers:* followed by the names."
- "We'll go deeper into OLS and RLS in the next video; here we're just completing enough to submit."

---

## 6. Submit and success (≈40 s)

- "At the bottom there are two buttons: **Cancel** and **Submit**."
- "**Cancel** takes you back without saving. **Submit** sends the request. While it's sending, the button shows **Submitting…**."
- "When the request is created, a toast message appears: *Request created:* followed by the request code."
- "A modal opens with the title **Request created**. It shows the request code and *Status: Pending LM*."
- "You have three options: **Go to request**—to open that request in My requests—**Reset form**—to clear the form and create another—or **Close**—to dismiss the modal and stay on the form."

---

## 7. Duplicate request (≈30 s)

- "If you submit a request that matches an existing one, the system may detect a duplicate."
- "You'll see an error toast, and a modal can appear with the title **Request already exists**."
- "The text says: *A similar request already exists.* Then the existing request code, and: *You can go to that request to view its status.*"
- "You can click **Go to request** to open that request, or **Close** to stay on the form."

---

## 8. Wrap and lead to Video 2 (≈15 s)

- "In the next video we'll walk through OLS-only, RLS-only, and combined OLS and RLS requests in detail, and what each type means for access."
- "After you create a request, you'll find it under **My requests** in the sidebar—we'll cover that in a later video."

---

## Frontend checklist – do NOT say if not in the UI

| Where | Say this (exact) | Do NOT say |
|-------|------------------|------------|
| Sidebar | **New permission request** | Create Request, Create a request |
| Page title | **New permission request** | Create Request |
| Back link | **Back to Dashboard** | Back to Home |
| Section | **Request** | — |
| Section | **Include in request** | — |
| Section | **OLS (Object Level Security)** (heading includes "— optional") | — |
| Field labels | **Workspace**, **Requested for**, **Requested by**, **LM approver**, **Request reason** | User details, Requested user |
| Field labels | **OLS item type**, **Report / Audience**, **App**, **Audience** | Report / Audience only when in OLS section |
| Checkboxes | **Include OLS (Object Level Security)**, **Include RLS (Row Level Security — dimensions for …)** | — |
| Buttons | **Refresh**, **Cancel**, **Submit**, **Submitting…**, **Resolve OLS approvers** | — |
| Success modal title | **Request created** | — |
| Success modal buttons | **Go to request**, **Reset form**, **Close** | — |
| Duplicate modal title | **Request already exists** | — |
| Duplicate modal text | *A similar request already exists.* / *You can go to that request to view its status.* | — |
| Duplicate modal buttons | **Go to request**, **Close** | — |

Placeholders (you may refer to these): *— Select workspace —*, *e.g. john.doe@dentsu.com*, *Current user from profile*, *Set when Requested for is entered*, *e.g. New hire access for CDI reporting*, *— Select —*, *— Select report —*, *— Select app —*, *— Select audience —*, *Or enter Audience ID*.
