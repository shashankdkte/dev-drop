# Video 2 – OLS, RLS, and Combined Requests

**Frontend-verified:** Every label, button, and message below matches the current app. Do not say anything that is not in this script or the checklist.

---

## 1. Introduction (≈20 s)

- "In this video we'll create three types of permission requests: OLS-only, RLS-only, and combined OLS and RLS—all on the same form under **New permission request**."
- "OLS controls which reports or audiences the user can see. RLS controls which rows of data they can see, based on dimensions like Entity, Client, or Service Line."

---

## 2. OLS-only request (≈1 min 30 s)

- "Go to the sidebar and click **New permission request**. Fill the **Request** section: **Workspace**, **Requested for**, **Requested by**, **LM approver**, **Request reason**—as in the previous video."
- "In **Include in request**, check only **Include OLS (Object Level Security)**. Leave **Include RLS** unchecked."
- "The **OLS (Object Level Security)** section appears."
- "**OLS item type**: choose **Report (SAR)** or **Audience**."
- "**Report / Audience**: If you chose **Report (SAR)**, use the dropdown **— Select report —**. The hint says: *Only standalone reports (SAR) with approvers configured are listed. Approvers are resolved from the report.* If your workspace has no standalone reports with approvers, you'll see: *No standalone reports (SAR) with approvers configured for this workspace. Reports shown in Workspace Reports with delivery method "AUDIENCE-BASED" do not have direct approvers—use **Audience** below and select the app and audience for app-level approval.* In that case, switch **OLS item type** to **Audience**."
- "If you chose **Audience**, you see the text: *This is an **audience-based** report. To request access, select the app and audience below for **app-level approval**.* Then **App**—**— Select app —**—and **Audience**—**— Select audience —**. Or use the field **Or enter Audience ID** if you know the ID. The hint says: *Or enter an Audience ID manually if you know it.*"
- "Click **Resolve OLS approvers**. When done, you'll see *OLS approvers:* followed by the names."
- "Click **Submit**. The request is created with only OLS; it will go through Line Manager and then OLS approver."

---

## 3. RLS-only request (≈1 min 30 s)

- "For an RLS-only request, fill the **Request** section as before. In **Include in request**, check only **Include RLS (Row Level Security — dimensions for** [workspace code] **)**. Leave **Include OLS** unchecked."
- "The **RLS** section appears. The title is **RLS (dimensions depend on workspace —** [workspace code] **)**."
- "You may see *Loading dimension options from backend…* or the hint: *Dropdown options are loaded from the backend for this workspace (CDI, DFI, AMER, EMEA, GI, WFI). You can still type your own value if needed.*"
- "**Security model** is required. Use the dropdown **— Select security model —**. The hint says: *Select the security model for this workspace. Correct ID is sent to backend for approver resolution and permission creation.*"
- "**Security type** is required. Use **— Select security type —**. The hint says: *Types for the selected model. Correct name and ID sent to backend.*"
- "Below that you see dimension pairs—the exact list depends on the workspace. Examples: **Organization (Entity)**, **Client**, **Service Line**, **Master Service Set**, **Profit Center**, **Cost Center**, **Country**, **People Aggregator**. Each can have a dropdown with placeholder **— Select or type —** or the dimension name. You need to fill at least one dimension."
- "Click **Resolve RLS approvers**. The button shows *Resolving…* while it runs. When done, you'll see *RLS approvers:* followed by the names."
- "Click **Submit**. The request is created with only RLS; it will go through Line Manager and then RLS approver."

---

## 4. Combined OLS + RLS request (≈45 s)

- "To request both OLS and RLS in one go, check both **Include OLS (Object Level Security)** and **Include RLS (Row Level Security — dimensions for** [workspace code] **)**."
- "Both sections appear: **OLS (Object Level Security)** and **RLS (dimensions depend on workspace —** [workspace code] **)**."
- "Fill the **Request** section, then fill the OLS section—**OLS item type**, **Report / Audience** or **App** and **Audience**—and click **Resolve OLS approvers**. Then fill the RLS section—**Security model**, **Security type**, and at least one dimension—and click **Resolve RLS approvers**."
- "Review your selections, then click **Submit**. One request is created; it will go through Line Manager, then OLS approver, then RLS approver."

---

## 5. What OLS and RLS mean (≈25 s)

- "**OLS**—Object Level Security—determines *which* reports or audiences the user can access. It's object-level: you see this report or that audience."
- "**RLS**—Row Level Security—determines *which rows* of data the user can see in the data model, using dimensions such as Entity, Client, or Service Line. So even if two people have access to the same report, they may see different rows depending on their RLS."
- "In the next video we'll look at **My requests** and how to view the details of any request you've created."

---

## Frontend checklist – do NOT say if not in the UI

| Where | Say this (exact) | Do NOT say |
|-------|------------------|------------|
| Include section | **Include OLS (Object Level Security)**, **Include RLS (Row Level Security — dimensions for …)** | — |
| OLS section title | **OLS (Object Level Security)** (heading may include "— optional") | — |
| OLS fields | **OLS item type**, **Report / Audience**, **App**, **Audience** | — |
| OLS placeholders | **— Select —**, **— Select report —**, **— Select app —**, **— Select audience —**, **Or enter Audience ID** | — |
| OLS button | **Resolve OLS approvers** (or *Resolving…*) | Resolve OLS, Resolve approvers |
| OLS resolved text | *OLS approvers:* [names] | — |
| OLS empty (Report path) | *No standalone reports (SAR) with approvers configured for this workspace. Reports shown in Workspace Reports with delivery method "AUDIENCE-BASED" do not have direct approvers—use **Audience** below and select the app and audience for app-level approval.* | — |
| OLS Audience info | *This is an **audience-based** report. To request access, select the app and audience below for **app-level approval**.* | — |
| RLS section title | **RLS (dimensions depend on workspace —** [CDI / AMER / etc.] **)** | — |
| RLS loading | *Loading dimension options from backend…* | — |
| RLS hint | *Dropdown options are loaded from the backend for this workspace (CDI, DFI, AMER, EMEA, GI, WFI). You can still type your own value if needed.* | — |
| RLS fields | **Security model**, **Security type** (both required) | — |
| RLS placeholders | **— Select security model —**, **— Select security type —**, **— Select or type —** (for dimensions) | — |
| RLS dimension pair labels (examples) | **Organization (Entity)**, **Client**, **Service Line**, **Master Service Set**, **Profit Center**, **Cost Center**, **Country**, **People Aggregator** | Exact list depends on workspace; only mention examples |
| RLS button | **Resolve RLS approvers** (or *Resolving…*) | — |
| RLS resolved text | *RLS approvers:* [names] | — |
| Form actions | **Cancel**, **Submit**, **Submitting…** | — |

**Note:** RLS dimension labels and count vary by workspace (CDI, AMER, WFI, GI, DFI, EMEA). Use "dimension pairs" and give a few examples; do not promise a fixed list.
