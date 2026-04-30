# Sync-EntraEmployeesToSakuraStage.ps1 — flow

Script: [`Sync-EntraEmployeesToSakuraStage.ps1`](./Sync-EntraEmployeesToSakuraStage.ps1)

End-to-end: **Microsoft Entra (Graph)** → **`stage.Employees`** → **`stage.spLoadEmployees`** → **`ref.Employees`** (and **`refv.Employees`**).

## Flowchart

```mermaid
flowchart TB
    subgraph start["Start"]
        A[Start transcript log file next to script]
        B[Import Graph modules]
    end

    subgraph auth["Graph authentication"]
        C{UseDelegatedGraphAuth?}
        C -->|Yes| D[Connect-MgGraph with scope User.Read.All — browser or cached session]
        C -->|No| E[Resolve client secret param or env SAKURA_GRAPH_CLIENT_SECRET]
        E --> F[Connect-MgGraph app-only ClientSecretCredential]
    end

    subgraph fetch["Load users from Microsoft Graph"]
        G[GET /users with select fields and expand manager]
        H[Page with nextLink until no more pages]
        G --> H
        H --> I[Build in-memory list of raw users]
    end

    subgraph filter["Filter and map rows"]
        J[For each user: enabled, id, name, email, optional domain / job / company filters]
        K{employeeId present?}
        K -->|Yes| L[MapKey and EmployeeCode = employeeId]
        K -->|No| M{UseObjectIdWhenEmployeeIdMissing?}
        M -->|Yes| N[MapKey and EmployeeCode = Entra object id]
        M -->|No| O[Skip user]
        L --> P[Resolve ManagerMapKey: manager employeeId else manager id when switch on]
        N --> P
        P --> Q[Append row with PipelineRunAt, PipelineInfo, PipelineRunId]
    end

    subgraph dry["Dry run"]
        R{DryRun?}
        R -->|Yes| S[Print counts, skip reasons, sample table]
        S --> T[Disconnect-MgGraph]
        T --> U[Stop transcript — end]
    end

    subgraph sql["Database path when not DryRun"]
        V[Open SQL connection — password or env SAKURA_SQL_PASSWORD]
        W[DELETE all rows in stage.Employees]
        X[SqlBulkCopy into stage.Employees]
        Y{SkipMerge?}
        Y -->|No| Z[EXEC stage.spLoadEmployees — merge into ref.Employees]
        Y -->|Yes| AA[Skip merge]
        Z --> AB[Close connection]
        AA --> AB
        AB --> AC[Disconnect-MgGraph]
        AC --> AD[Stop transcript — end]
    end

    A --> B
    B --> C
    D --> G
    F --> G
    I --> J
    J --> K
    Q --> R
    R -->|No| V
    V --> W --> X --> Y
```

## Notes

- **`spLoadEmployees`** treats the staged set as the full snapshot: anyone in **`ref.Employees`** not present in **`stage.Employees`** after merge can be soft-deleted when stage is non-empty (see procedure logic in `Sakura_DB`).
- Disable the Fabric Employees transfer (**`mgmt.DataTransferSettings`**, `IsActive = 0` for `stage.Employees` / `P_REF_CENTRAL_IMPORT`) if you do not want ADF to overwrite this path.
