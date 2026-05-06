1.  If one request contains combinations with different RLS approvers, should one approver approve everything, or should each approver approve only their own combinations ?

2.  If one combination has no approver, should only that combination go to workspace owner, or should the full request go to workspace owner?

3.  Should the request be considered approved only when all combination approvers approve?

4.  Can one approver reject only their combination, or does rejection reject the entire request?

5.  If approverA approves combination 1 and approverB rejects combination 3, what should happen to the whole request?

6.  Should the requester see one request code or multiple request codes?

7.  Should emails go to all approvers at once, or should approval happen sequentially?

8.  When revoking later, should the user revoke the whole request or selected combinations?

9.  Email content for RLS in case of multiple dimension selection

---

## Sakura model overview (Multi-RLS)

The diagrams below use Sakura concepts: a single **PermissionRequest** (for example `PR-1001`), **RLS combinations** built from dimension selections (client, country, MSS, and similar), **resolved approvers** per combination, and **workspace owner** when no approver is configured.

### Flow: one request, combinations grouped by approver

```mermaid
flowchart TD
    subgraph Request["Sakura permission request"]
        PR["PermissionRequest<br/>e.g. PR-1001"]
    end

    subgraph Selection["RLS combinations from UI selection"]
        C1["Combination 1<br/>dimensions resolved"]
        C2["Combination 2"]
        C3["Combination N"]
    end

    subgraph Resolve["Approver resolution per combination"]
        RES["For each combination:<br/>lookup approver OR<br/>workspace owner fallback"]
    end

    subgraph Group["Group by resolved approver"]
        G1["Approver A → their combinations"]
        G2["Approver B → their combinations"]
        GW["Workspace owner →<br/>no-approver combinations"]
    end

    subgraph Tasks["One approval task per approver group"]
        T1["Task to approver A"]
        T2["Task to approver B"]
        TW["Task to workspace owner"]
    end

    PR --> Selection
    Selection --> Resolve
    Resolve --> Group
    Group --> Tasks
```

### Approval outcome (recommended: reject-all)

```mermaid
stateDiagram-v2
    [*] --> Pending

    Pending --> PartiallyApproved: Some required parts approved
    PartiallyApproved --> Approved: All required parts approved

    Pending --> Rejected: Any part rejected
    PartiallyApproved --> Rejected: Any part rejected

    Approved --> [*]
    Rejected --> [*]

    note right of Pending: OLS and/or multiple RLS headers
```

---

**Scenario 1: All Selected Combinations Have the Same Approver**  
Example:

Combination 1 -\> approverA

Combination 2 -\> approverA

Combination 3 -\> approverA

**One request, one RLS approval/header**

- one approver owns all selected combinations

- no approval ownership conflict

- requester sees one request

- approver gets one approval task

This is the simplest case and works well with the current model.

```mermaid
flowchart LR
    subgraph S1["Scenario 1"]
        PR1["PR-1001"]
        A1["approverA"]
    end
    PR1 -->|"all combinations"| A1
```

**Scenario 2: Selected Combinations Have Different Approvers**  
Example:

Combination 1 -\> approverA

Combination 2 -\> approverB

Combination 3 -\> approverC

**One request with multiple RLS approval parts/headers**

- requester still sees one request

- each approver approves only their own combinations

- audit clearly shows who approved which access

- avoids one approver approving another approver's area

Alternative: **Multiple requests**  
This can be used if the business wants each approver's part to be fully independent with separate request codes.

```mermaid
flowchart TB
    subgraph S2["Scenario 2 — parallel approvers"]
        PR2["PR-1001<br/>one request"]
    end

    subgraph Parallel["Each approver only their combinations"]
        PA["approverA"]
        PB["approverB"]
        PC["approverC"]
    end

    PR2 --> PA
    PR2 --> PB
    PR2 --> PC
```

**Scenario 3: Some Combinations Have No Approver**  
Example:

Combination 1 -\> approverA

Combination 2 -\> no approver found

Combination 3 -\> approverB

**One request with multiple RLS approval parts/headers**

- approverA approves combination 1

- workspace owner approves combination 2 as fallback

- approverB approves combination 3

- requester still tracks one request

- fallback usage is visible and auditable

Alternative: **Multiple requests**  
One request can go to approverA, one to workspace owner, one to approverB. This is cleaner technically but creates more request codes and more user noise.

```mermaid
flowchart LR
    subgraph S3["Scenario 3 — fallback"]
        PR3["PR-1001"]
    end

    PR3 --> A["approverA<br/>combo 1"]
    PR3 --> WO["Workspace owner<br/>combo 2 — no approver"]
    PR3 --> B["approverB<br/>combo 3"]
```

**Scenario 4: One Approver Rejects One Combination**  
Example:

Combination 1 -\> approverA approves

Combination 2 -\> workspace owner approves

Combination 3 -\> approverB rejects

Suggested approach depends on business rule.

If rejection should reject everything:

- **One request with multiple approval parts/headers**

- if any approver rejects, whole request becomes rejected

- this keeps user communication and audit simple

```mermaid
flowchart TD
    subgraph S4["Scenario 4 — one reject affects whole PR"]
        PR4["PR-1001"]
    end

    PR4 --> OK1["approverA: approve"]
    PR4 --> OK2["Workspace owner: approve"]
    PR4 --> BAD["approverB: reject"]

    BAD --> OUT["Entire PermissionRequest rejected"]
```

**Scenario 5: Request Contains OLS + Multi-RLS**  
Example:

OLS: Report X

RLS Combination 1 -\> approverA

RLS Combination 2 -\> approverB

**One request with multiple approval parts/headers**

- one request represents the full access package

- OLS approver approves report/audience access

- each RLS approver approves their own combinations

- request is approved only when all required approvals are complete

Possible header structure:

PermissionRequest PR-1001

\- OLS header -\> OLS approver

\- RLS header -\> approverA

\- RLS header -\> approverB

### Sakura: one request, multiple approval parts (OLS + RLS)

```mermaid
flowchart TB
    PR["PermissionRequest PR-1001<br/>single code for requester"]

    subgraph Parts["Approval parts on the same request"]
        H_OLS["OLS part / header<br/>Report X — OLS approver"]
        H_RLS_A["RLS part — approverA<br/>combination set A"]
        H_RLS_B["RLS part — approverB<br/>combination set B"]
    end

    PR --> H_OLS
    PR --> H_RLS_A
    PR --> H_RLS_B

    H_OLS --> Gate{All parts approved?}
    H_RLS_A --> Gate
    H_RLS_B --> Gate

    Gate -->|Yes| Done["Request approved —<br/>full access package granted"]
    Gate -->|No / any reject| Block["Request not complete or rejected"]
```

**Scenario 6: Too Many Combinations Are Selected**  
Example:

Client: 10 values

Country: 10 values

MSS: 5 values

Potential combinations: 500

**Either block or split**

- keep one request only if combination count is within limit

- if over limit, ask user to reduce selection or split into multiple requests

**If the request exceeds that:**

- frontend should show a preview and ask user to reduce

- or backend should reject validation with a clear message

**Scenario 7: Workspace Owner Fallback Is Used for Many Combinations**  
Example:

20 selected combinations

12 combinations have no approver

12 combinations go to workspace owner

**One request with multiple approval parts/headers**, but with warning/reporting

- request can proceed

- fallback combinations are still approved by an accountable owner

- missing approver configuration is visible

- if fallback count is too high, block request and ask admin to fix approver setup

- if fallback is acceptable, continue and audit fallback usage

Recommended approach

- Allow one request with multiple RLS combinations.

- Group combinations by resolved approver.

- Create one approval task per approver group.

- If any approver rejects, reject the whole request.

- If approver is missing, assign that combination to workspace owner.

- Limit total combinations per request.

### Recommended grouping (sequence)

```mermaid
sequenceDiagram
    participant U as Requester
    participant S as Sakura API / workflow
    participant R as Approver resolution
    participant A as Approver A
    participant B as Approver B
    participant W as Workspace owner

    U->>S: Submit PermissionRequest with many RLS combinations
    S->>R: Resolve approver per combination
    R-->>S: Groups: A's combos, B's combos, owner fallback combos
    S->>A: Approval task (only A's combinations)
    S->>B: Approval task (only B's combinations)
    S->>W: Approval task (fallback combinations)
    A-->>S: Approve / reject
    B-->>S: Approve / reject
    W-->>S: Approve / reject
    Note over S: Any rejection rejects whole request; all approve completes request
```
