# Email and EmailTemplate — V1 Column Guide and V2 Mapping
> Explains every column in V1 `Emails` and `EmailTemplates`, who sets it, what it’s related to, and how to do the same in V2.

---

## 1. V1 — Table: `dbo.Emails`

The **Emails** table is the outbound email queue. Rows are inserted by `QueueEmail` (or `AddToEmailQueue` → `QueueEmail`). A separate sender process (e.g. job or service) reads rows where `Status = 0` or `1`, sends the email, then updates `Status`, `DateSent`, `NumberOfTries`, `LastTrialDate`, `StatusText`.

---

### Column-by-column: V1 `Emails`

| Column | Type (V1) | Who sets it | Related to | Purpose |
|--------|-----------|-------------|------------|--------|
| **EmailId** | bigint, IDENTITY | System (PK) | — | Unique row id. Returned as `@EmailId OUTPUT` from `QueueEmail` so callers can log or reference the queued email. |
| **From** | nvarchar(255) | `QueueEmail` | `ApplicationSettings.DefaultEmailFrom` | Sender email address. Default from app setting (e.g. `sakura@dentsu.com`). |
| **FromName** | nvarchar(255), NULL | `QueueEmail` | `ApplicationSettings.DefaultEmailFromName` | Display name of sender (e.g. "Sakura"). |
| **To** | nvarchar(MAX) | `QueueEmail` (from params) | **FindEmailRecipients** | Recipients. Filled by `FindEmailRecipients(@EmailTemplateKey, @ContextId)` when using `AddToEmailQueue`; or passed in when calling `QueueEmail` directly. If empty, falls back to `AdminEmail` app setting. |
| **CC** | nvarchar(MAX), NULL | `QueueEmail` (from params) | **FindEmailRecipients** | CC list. From `FindEmailRecipients` or passed in. |
| **BCC** | nvarchar(MAX), NULL | `QueueEmail` (from params) | **FindEmailRecipients** | BCC list. From `FindEmailRecipients` or passed in. |
| **Subject** | nvarchar(255) | `QueueEmail` | **ConstructEMail** + `EmailTemplates` | Subject line. Built by `ConstructEMail(@EmailTemplateKey, @ContextEntityName, @ContextId, @EmailGuid, @Subject OUTPUT, @Body OUTPUT)` using the template and context. If NULL, set to `'[SakuraUnk]: Email Notification'`. |
| **Body** | nvarchar(MAX) | `QueueEmail` | **ConstructEMail** + `EmailTemplates` | HTML/text body. Built by `ConstructEMail` from template content and context data. If NULL, set to message for administrator. |
| **DateCreated** | smalldatetime | `QueueEmail` | — | When the row was inserted (`GETDATE()`). |
| **DateSent** | smalldatetime, NULL | Sender process (e.g. **MarkEmailAsSent**) | — | When the email was successfully sent. NULL until sent. |
| **StatusText** | nvarchar(2048), NULL | `QueueEmail` + sender | — | Human-readable status. On insert: `'Ready For Dispatch'` or `'Skipped due to App Settings'`. Sender may set error text on failure. |
| **Status** | int, NULL | `QueueEmail` + sender | **EmailsToSend** view, sender logic | 0 = New, 1 = Retry, 2 = Sent, 3 = Error. On insert: 0 (or 3 if `EmailingMode = 0`). Sender sets 2 on success, 3 on failure; retry logic may set 1. |
| **NumberOfTries** | int, NULL | `QueueEmail` + sender | **EmailsToSend** view | How many send attempts. Set to 0 on insert. Sender increments on each try. Used with `EmailMaxRetrials` to stop retrying. |
| **LastTrialDate** | smalldatetime, NULL | Sender | **EmailsToSend** view | When the last send attempt happened. Used with `EmailRetryAfterMins` to throttle retries. |
| **EmailTemplateKey** | nvarchar(100), NULL | `QueueEmail` | **EmailTemplates** | Which template was used (e.g. `'APP-APRVED'`, `'APP-RYRC-Orga'`). Links this email to the template definition. |
| **ContextEntityName** | nvarchar(100), NULL | `QueueEmail` | **FindEmailRecipients**, **ConstructEMail** | Entity type that triggered the email (e.g. `'PermissionHeader'`, `'ApproversOrga'`). Used with **ContextId** to find recipients and build body. |
| **ContextId** | nvarchar(100), NULL | `QueueEmail` | **FindEmailRecipients**, **ConstructEMail** | Id of the record (e.g. RequestId, HeaderId). Together with **ContextEntityName** identifies the business context for this email. |
| **EmailGuid** | nvarchar(100) | `QueueEmail` | — | Unique GUID for this email (`NEWID()`). Used to avoid duplicate sends and for tracing. |
| **QueueName** | nvarchar(510), default `'default'` | `QueueEmail` | **fnFindAppEmailQueue**, **ApplicationSettings.ActiveEmailQueues** | Which queue this email belongs to. Set from `@QueueName` or from `fnFindAppEmailQueue(fnFindContextApp(@ContextEntityName,@ContextId))`. **EmailsToSend** filters by `ActiveEmailQueues` so only active queues are processed. |

**Related stored procedures / view**

- **QueueEmail:** Inserts into `Emails` (sets From, FromName, To, CC, BCC, Subject, Body, DateCreated, StatusText, Status, NumberOfTries, EmailTemplateKey, ContextEntityName, ContextId, EmailGuid, QueueName).
- **FindEmailRecipients:** Called by `AddToEmailQueue`; returns To, CC, BCC based on `EmailTemplateKey` and `ContextId` (and reads PermissionHeader, EventLog etc.).
- **ConstructEMail:** Builds Subject and Body from `EmailTemplates` and context tables (PermissionHeader, PermissionOrgaDetail, etc.).
- **EmailsToSend (view):** Selects rows where Status in (0,1), NumberOfTries < EmailMaxRetrials, LastTrialDate within retry window, EmailingMode = '1', and QueueName in ActiveEmailQueues. Sender process reads from this view.
- **MarkEmailAsSent / MarkEmailAsUnsent:** Update Status, DateSent, StatusText, NumberOfTries, LastTriedAt.

---

## 2. V1 — Table: `dbo.EmailTemplates`

Stores one row per **email type** (template key). **ConstructEMail** reads the template by **EmailTemplateKey** and fills subject/body using placeholders and context data.

---

### Column-by-column: V1 `EmailTemplates`

| Column | Type (V1) | Who sets it | Related to | Purpose |
|--------|-----------|-------------|------------|--------|
| **EmailTemplateId** | int, IDENTITY | System (PK) | — | Unique id. |
| **EmailTemplateKey** | nvarchar(100), UNIQUE | Admin / seed data | **Emails.EmailTemplateKey**, **QueueEmail**, **FindEmailRecipients** | Code that identifies the template (e.g. `'APP-APRVED'`, `'APP-RYRC-Orga'`, `'APP-AWP-NEWAPPROVER'`). Used in `QueueEmail` and `AddToEmailQueue`; stored on each `Emails` row. |
| **EmailTemplateDesc** | nvarchar(510), NULL | Admin | — | Human-readable description of when this template is used. |
| **EmailTemplateSubject** | nvarchar(510) | Admin / seed | **ConstructEMail** | Subject line template. May contain placeholders replaced by **ConstructEMail** using context (e.g. request code, requester name). |
| **EmailTemplateContent** | nvarchar(MAX) | Admin / seed | **ConstructEMail** | Body template (HTML/text). Placeholders replaced by **ConstructEMail** from context tables (PermissionHeader, PermissionOrgaDetail, Entity, ServiceLine, etc.). |
| **ApplicationLoVId** | int | Admin / seed | **LoV** (Application) | V1-specific: which application/reporting deck the template belongs to. **ConstructEMail** / **FindEmailRecipients** may use it to scope data. In V2 there is no ApplicationLoVId; scope is by workspace/domain instead. |
| **LastChangeDate** | smalldatetime, NULL | Admin / **UpdateEmailTemplate** | — | When the template was last modified. |
| **LastChangedBy** | nvarchar(510) | Admin / **UpdateEmailTemplate** | — | Who last changed the template. |

**Related stored procedures**

- **ConstructEMail:** Reads `EmailTemplates` by `EmailTemplateKey`, uses Subject and Content plus `ContextEntityName`/`ContextId` to resolve placeholders and outputs final Subject and Body.
- **UpdateEmailTemplate:** Updates template rows (Subject, Content, LastChangeDate, LastChangedBy, etc.).
- **FindEmailRecipients:** Uses `EmailTemplateKey` and `ContextId` (and sometimes EventLog, PermissionHeader) to determine To, CC, BCC for that email type and context.

---

## 3. V2 — Current Tables (for comparison)

### V2 `dbo.Emails`

| Column | Type (V2) | Same as V1? | Notes |
|--------|-----------|-------------|--------|
| Id | BIGINT IDENTITY | Yes (V1: EmailId) | Same role. |
| From | NVARCHAR(255) | Yes | Same. |
| FromName | NVARCHAR(255) NULL | Yes | Same. |
| To | NVARCHAR(MAX) | Yes | Same. |
| CC | NVARCHAR(MAX) NULL | Yes | Same. |
| BCC | NVARCHAR(MAX) NULL | Yes | Same. |
| Subject | NVARCHAR(255) | Yes | Same. |
| Body | NVARCHAR(MAX) | Yes | Same. |
| CreatedAt | DATETIME2(0) | Yes (V1: DateCreated) | Same role; better precision in V2. |
| SentAt | DATETIME2(0) NULL | Yes (V1: DateSent) | Same. |
| StatusText | NVARCHAR(1024) NULL | Yes | Same. |
| Status | INT NULL | Yes | 0: New, 1: Retry, 2: Sent, 3: Error. |
| NumberOfTries | INT NULL | Yes | Same. |
| LastTriedAt | DATETIME2(0) NULL | Yes (V1: LastTrialDate) | Same. |
| EmailTemplateKey | NVARCHAR(50) NULL | Yes | Same. |
| ContextEntityName | NVARCHAR(50) NULL | Yes | Same. |
| ContextId | NVARCHAR(50) NULL | Yes | Same. |
| EmailGuid | NVARCHAR(50) NOT NULL, UNIQUE | Yes | Same. |
| QueueName | NVARCHAR(255) DEFAULT N'default' | Yes | Same. |

So in V2 you can **do the same** as V1: every column has a direct equivalent. Only names differ (Id vs EmailId, CreatedAt vs DateCreated, SentAt vs DateSent, LastTriedAt vs LastTrialDate).

### V2 `dbo.EmailTemplates`

| Column | Type (V2) | Same as V1? | Notes |
|--------|-----------|-------------|--------|
| Id | INT IDENTITY | Yes (V1: EmailTemplateId) | Same. |
| EmailTemplateKey | NVARCHAR(50) NOT NULL, UNIQUE | Yes | Same. |
| EmailTemplateDesc | NVARCHAR(255) NULL | Yes | Same (V1 allowed 510). |
| EmailTemplateSubject | NVARCHAR(255) NOT NULL | Yes | Same. |
| EmailTemplateContent | NVARCHAR(MAX) NOT NULL | Yes | Same. |
| CreatedAt | DATETIME2(0) | V1 had LastChangeDate | V2 uses CreatedAt/UpdatedAt for audit. |
| CreatedBy | NVARCHAR(255) | V1 had LastChangedBy | Same idea. |
| UpdatedAt | DATETIME2(0) | — | V2 adds explicit UpdatedAt. |
| UpdatedBy | NVARCHAR(255) | — | V2 adds explicit UpdatedBy. |
| ValidFrom / ValidTo | DATETIME2 (temporal) | — | V2 has system-versioning; V1 did not. |

**V1 had, V2 does not**

- **ApplicationLoVId** on EmailTemplates. In V1 this scoped templates to an “application” (reporting deck). In V2 you scope by **workspace/domain** in application logic (e.g. different template keys per workspace or use **ContextEntityName** + **ContextId** to resolve workspace). No need to add ApplicationLoVId to V2 unless you want per-application templates; then you could add a nullable **WorkspaceId** or **DomainLoVId** to EmailTemplates and use it in your “ConstructEMail” equivalent.

---

## 4. How to do the same in V2

### 4.1 Emails table

- **Insert (queue) an email:** Same as V1: set **From**, **FromName**, **To**, **CC**, **BCC**, **Subject**, **Body**, **CreatedAt**, **Status** (0 or 3), **StatusText**, **NumberOfTries** (0), **EmailTemplateKey**, **ContextEntityName**, **ContextId**, **EmailGuid**, **QueueName**. Leave **SentAt**, **LastTriedAt** NULL until the sender runs.
- **Who sets what:** Your “queue email” service (equivalent to `QueueEmail`) should set all of the above. “From”/“FromName” can come from **ApplicationSettings** (e.g. DefaultEmailFrom, DefaultEmailFromName) or app config.
- **To/CC/BCC:** Either resolve in code (your version of **FindEmailRecipients**) from **EmailTemplateKey** + **ContextId** (and **ContextEntityName**) and pass into the insert, or have a single stored procedure that does recipient resolution + insert.
- **Subject/Body:** Build them from **EmailTemplates** (lookup by **EmailTemplateKey**) and context (e.g. PermissionRequests, PermissionHeaders). That is your **ConstructEMail** equivalent — can be in C# or in SQL.
- **Sender process:** Something (e.g. background job or Azure Function) selects from an **EmailsToSend**-like view (Status in (0,1), NumberOfTries < max, retry delay, EmailingMode, ActiveEmailQueues), sends the email, then updates **Status**, **SentAt**, **StatusText**, **NumberOfTries**, **LastTriedAt** (and optionally writes to **EventLog**).

So: **no schema change needed** for V2 `Emails` to behave like V1; just implement the same responsibilities (queue with context, resolve recipients, build subject/body from templates, send and update).

### 4.2 EmailTemplates table

- **Same usage:** One row per logical email type; **EmailTemplateKey** is the unique code (e.g. `PermissionRequest-Created`, `PermissionHeader-Approved`, `PermissionHeader-Rejected`). **EmailTemplateSubject** and **EmailTemplateContent** hold the templates; your “ConstructEMail” replaces placeholders from context.
- **V1 ApplicationLoVId:** In V2 you can either:
  - Ignore it and use **EmailTemplateKey** (and optionally **ContextEntityName** / **ContextId**) to decide context, or
  - Add a nullable **WorkspaceId** or **DomainLoVId** to **EmailTemplates** and use it when resolving which template to use for a given workspace/request.
- **Audit:** V2 already has **CreatedAt/CreatedBy/UpdatedAt/UpdatedBy** and temporal tables; no need for **LastChangeDate**/ **LastChangedBy** unless you want that naming.

### 4.3 Suggested V2 flow (mirror V1)

1. **When to queue:** On the same events as V1 (e.g. permission request created, LM/OLS/RLS approved, rejected, revoked, new approver added). Call a single “queue email” API or stored procedure.
2. **Queue email implementation:**  
   - Resolve **To/CC/BCC** from template key + context (your **FindEmailRecipients** in code or SQL).  
   - Load **EmailTemplates** by **EmailTemplateKey**; build **Subject** and **Body** from template + context (your **ConstructEMail**).  
   - Insert into **Emails** with **EmailGuid** = new GUID, **Status** = 0 (or 3 if EmailingMode = Skip), **QueueName** from config or from context (e.g. workspace).  
   - Optionally write to **EventLog**: “Notification-Created” with **ContextEntityName**, **ContextId**, **EventTriggeredBy**.
3. **Sender:** Periodically select from an **EmailsToSend** view (same conditions as V1), send via SMTP/send grid, then update **Emails** (Status 2/3, SentAt, LastTriedAt, NumberOfTries, StatusText). Optionally log “Notification-Sent” / “Notification-Failed” to **EventLog**.

This gives you the same behaviour as V1: every column in **Emails** and **EmailTemplates** is used in the same way, with naming and minor type differences only. The only design choice in V2 is whether to add **WorkspaceId**/ **DomainLoVId** to **EmailTemplates** for per-workspace templates; the rest can stay as-is and you “do the same in V2” by implementing the same queue + resolve + construct + send flow.
