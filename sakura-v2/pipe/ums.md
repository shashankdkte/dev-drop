# Sakura V1 → Fabric Migration: Complete Beginner Step-by-Step Guide

> **Goal:** Move Sakura V1 off Synapse/Sensei (`DB_Synapse_Sensei`) onto Microsoft Fabric as the data source —
> **in test only first**, without touching production or V2 pipelines.

---

## What exists today (read this first)

| Piece | Name | What it does |
|---|---|---|
| ADF Pipeline | `P_ALL_SAKURA_D_Automation` (folder: `DE/DE-Staging/RoninSakuraV1/Automation`) | Reads the job list, loops, copies data, runs merge |
| Schedule trigger | `SakuraV1 DailyRun` | Runs the pipeline every 2 hours |
| Source linked service | `DB_Synapse_Sensei` | **This is what we are replacing** — points at Synapse (UMS / `BL_UMS.*` objects) |
| Source dataset | `DS_SYN_DYN_QUERY` | Uses `DB_Synapse_Sensei`; type = `AzureSqlDW` |
| Sink linked service | `DB_Master_Sakura` | Azure SQL — Sakura DB (stays unchanged) |
| Sink dataset | `DS_ASQL_DYN_SAKURA_TBL` | Writes to `Staging.*` tables (stays unchanged) |
| Settings linked service | `DB_Master_ProcessDB` | Already on Fabric endpoint — reads `BBONDataTransferSettings` |
| Settings dataset | `DS_ASQL_PRODB_DataTransferSettings` | Points at `ProcessDB.dbo.BBONDataTransferSettings` |
| Job list table | `ProcessDB.dbo.BBONDataTransferSettings` | One row per object: `SourceQuery`, destination table, merge SP, `PipelineName`, `IsEnabled` |
| Query mapping sheet | `UMS to Ronin Objects.csv` | Shows old UMS `SourceQuery` vs new Fabric `SourceQuery` for each object |

### What happens inside the pipeline (one loop iteration)

```
Set CoreObjectModelType (=0)
        ↓
LKP DTSettings  →  reads ProcessDB.dbo.BBONDataTransferSettings
                    WHERE IsEnabled=1
                    AND PipelineName = <this pipeline's name>   ← KEY filter
                    AND DestinationSchemaName = 'Staging'
        ↓
ForEach row returned
    ├── LKP DTStatus       (reads last run anchor date from ProcessDB)
    ├── Copy Data Dynamic  (SOURCE = Synapse via DS_SYN_DYN_QUERY)
    │                      (SINK   = Sakura Staging via DS_ASQL_DYN_SAKURA_TBL)
    ├── Execute SP Merge   (runs item().MergeSPName on Sakura DB)
    └── Set Transfer Status (writes run result back to ProcessDB)
```

> **Important:** `LKP DTSettings` already uses `@pipeline().Pipeline` as the filter.
> This means if you clone the pipeline and give it a new name, the lookup will
> **automatically** only return rows whose `PipelineName` matches the clone's name.
> You do NOT need to change the lookup activity itself.

---

## Phase 1 — Clone the pipeline in ADF (test)

### Step 1 — Open ADF (test environment)

1. Go to **portal.azure.com** → search for your **test** Azure Data Factory (`azeuw1npsenadf02` or your test factory name).
2. Click **Open Azure Data Factory Studio** (the blue button).

### Step 2 — Find the original pipeline

1. In the left menu click the **pencil icon** (Author).
2. Expand **Pipelines** in the left panel.
3. Navigate to folder: `DE` → `DE-Staging` → `RoninSakuraV1` → `Automation`.
4. Find `P_ALL_SAKURA_D_Automation`.

### Step 3 — Clone it

1. Right-click `P_ALL_SAKURA_D_Automation`.
2. Click **Clone**.
3. A new pipeline appears named `Copy of P_ALL_SAKURA_D_Automation`.
4. Click the pencil icon on that tab to **rename it**.
5. Name it exactly: **`P_ALL_SAKURA_D_Automation_Fabric`**
   _(This name must match exactly what you will put in `PipelineName` in the database later.)_
6. Click **OK**.
7. Click **Publish All** → **Publish** to save. Do not close without publishing.

> The original pipeline is now untouched. All further changes are on the clone only.

---

## Phase 2 — Create a new Fabric linked service (the "source" connection)

The current source (`DB_Synapse_Sensei`) points at Synapse. You need a new one pointing at Fabric.
Look at `LH_CENTRAL_GOLD_SQLEP.json` from the V2 pipelines folder — that is the pattern to follow.

### Step 4 — Get the Fabric SQL endpoint address

Ask your platform/data engineering team for the **Fabric SQL analytics endpoint** or **Warehouse server address** that hosts the Fabric versions of `BL_UMS` objects.

It will look like:
```
xxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx.datawarehouse.fabric.microsoft.com
```
Also confirm the **database name** (e.g. `LH_UMS_GOLD` or equivalent).

### Step 5 — Create the linked service in ADF

1. In ADF Studio, click the **toolbox icon** in the left menu → **Manage**.
2. Click **Linked services** → **+ New**.
3. In the search box type **Azure SQL Database** → select it → click **Continue**.
4. Fill in the form:

| Field | Value |
|---|---|
| Name | `DB_Fabric_UMS` _(or agree a name with your team)_ |
| Server name | _(paste the Fabric endpoint from Step 4)_ |
| Database name | _(the Fabric database name from Step 4)_ |
| Authentication type | **System Assigned Managed Identity** _(same as V2's `LH_CENTRAL_GOLD_SQLEP`)_ |

5. Click **Test connection** — it must say **Connection successful** before continuing.
   - If it fails: check that the ADF managed identity has been granted access on the Fabric side (ask your platform team to run `CREATE USER [<ADF name>] FROM EXTERNAL PROVIDER` on the Fabric warehouse).
6. Click **Create**.
7. Click **Publish All** → **Publish**.

---

## Phase 3 — Create a new source dataset pointing at Fabric

The current source dataset `DS_SYN_DYN_QUERY` is type `AzureSqlDW` (Synapse).
Fabric SQL uses the `AzureSqlDatabase` type, so you need a new dataset.

### Step 6 — Create the dataset

1. In ADF Studio → **Author** → right-click **Datasets** → **New dataset**.
2. Search for **Azure SQL Database** → select it → click **Continue**.
3. Fill in:

| Field | Value |
|---|---|
| Name | `DS_FAB_DYN_QUERY` |
| Linked service | `DB_Fabric_UMS` _(the one you created in Step 5)_ |
| Table name | Leave blank (the query comes from `SourceQuery` at runtime) |

4. Click **OK**.
5. Click **Publish All** → **Publish**.

---

## Phase 4 — Update the cloned pipeline to use Fabric as source

### Step 7 — Open the cloned pipeline

1. In **Author** → navigate to `P_ALL_SAKURA_D_Automation_Fabric`.
2. Click on the **ForEach1** activity box on the canvas.
3. Click the **pencil / edit** icon inside the ForEach to open its inner activities.

### Step 8 — Update the Copy activity source

1. Click on the **Copy Data Dynamic** activity.
2. Click the **Source** tab at the bottom panel.
3. You will see **Source dataset** is set to `DS_SYN_DYN_QUERY`.
4. Click the dropdown next to it → select **`DS_FAB_DYN_QUERY`** (your new Fabric dataset).
5. The **Source type** will automatically change from `SqlDWSource` to `AzureSqlSource` — this is correct.
6. **Do not change anything else** on the Source tab (the query expression `@replace(item().SourceQuery,...)` stays the same — it pulls the SQL from the database at runtime).

### Step 9 — Verify the Sink tab (should be unchanged)

1. Click the **Sink** tab.
2. Confirm **Sink dataset** is still `DS_ASQL_DYN_SAKURA_TBL` → linked to `DB_Master_Sakura`.
3. Do **not** change anything here.

### Step 10 — Go back to the main pipeline canvas

1. Click the breadcrumb at the top to go back to `P_ALL_SAKURA_D_Automation_Fabric`.
2. Click **Publish All** → **Publish**.

---

## Phase 5 — Prepare the job list in ProcessDB (BBONDataTransferSettings)

This is the database step. You are inserting new rows for the **Fabric** pilot objects.

### Step 11 — Open SSMS and connect to ProcessDB (test)

Connect to your **test** `ProcessDB` instance (same one ADF reads from in test).

### Step 12 — Check the existing rows

```sql
SELECT Id, ObjectModelType, SourceQuery, DestinationSchemaName,
       DestinationTableName, MergeSPName, IsEnabled, PipelineName
FROM dbo.BBONDataTransferSettings
WHERE PipelineName = 'P_ALL_SAKURA_D_Automation'
  AND DestinationSchemaName = 'Staging'
ORDER BY Id;
```

You will see rows like:

| Id | DestinationTableName | PipelineName | IsEnabled |
|---|---|---|---|
| 53 | Client | P_ALL_SAKURA_D_Automation | 0 |
| 41 | CostCenter | P_ALL_SAKURA_D_Automation | 0 |
| 39 | Entity | P_ALL_SAKURA_D_Automation | 0 |
| 99 | MasterServiceSet | P_ALL_SAKURA_D_Automation | 0 |
| 40 | ServiceLine | P_ALL_SAKURA_D_Automation | 0 |

### Step 13 — Understand what Fabric query to use for each object

Open `C:\Development\Sakura\PipelIneUMSFabric\UMS to Ronin Objects.csv`.

For each object find the row where:
- Column **"Ronin Object"** matches your staging table name (e.g. `[WD_Employee]`)
- Column **"Fabric Source Query"** = the new SQL to run on Fabric
- Column **"Fabric DataSource"** = which Fabric workspace/lakehouse (useful for confirming with your platform team)

Example from the CSV for CostCenter:

| | Source Query (UMS) | Fabric Source Query | Fabric DataSource |
|---|---|---|---|
| CostCenter | `FROM [BL_UMS].[DimCostCenterNode...]` | `FROM [BL_...] (Fabric equivalent)` | _(see CSV column)_ |

### Step 14 — Insert pilot rows for the clone pipeline

Start with **one object** (e.g. `Entity` or `CostCenter` — low risk, well-understood).

```sql
-- PILOT: Insert ONE Fabric row for the cloned pipeline
INSERT INTO dbo.BBONDataTransferSettings
    (ObjectModelType, SourceQueryType, SourceQuery,
     DestinationSchemaName, DestinationTableName, MergeSPName,
     IsEnabled, DateCreated, UserCreated, PipelineName)
VALUES
(
    0,          -- ObjectModelType (same as original row)
    1,          -- SourceQueryType (same as original)
    -- *** REPLACE THIS WITH THE FABRIC QUERY FROM THE CSV ***
    N'SELECT CONCAT(SourceSystem,''~'',EntityMapKey) AS EntityKey, ...
      FROM [BL_FABRIC_SCHEMA].[DimEntityNode...]  -- Fabric version
      WHERE ...',
    N'Staging',                                   -- DestinationSchemaName (DO NOT CHANGE)
    N'Entity',                                    -- DestinationTableName  (DO NOT CHANGE)
    N'[Staging].[sp_Load_Entity]',                -- MergeSPName           (DO NOT CHANGE)
    1,          -- IsEnabled = 1 to be picked up by the pilot run
    GETDATE(),
    N'YourName',
    N'P_ALL_SAKURA_D_Automation_Fabric'           -- *** must match clone name exactly ***
);
```

> **Rules:**
> - `DestinationSchemaName`, `DestinationTableName`, `MergeSPName` must stay the **same** as the original row — the staging contract does not change.
> - `SourceQuery` changes to the **Fabric SQL** from the CSV.
> - `PipelineName` = **`P_ALL_SAKURA_D_Automation_Fabric`** (your clone name exactly).
> - `IsEnabled = 1` only for this pilot row. Leave all others as `0` for now.

### Step 15 — Confirm the lookup will pick it up

```sql
-- Simulate what LKP DTSettings will run
SELECT * FROM dbo.BBONDataTransferSettings
WHERE IsEnabled = 1
  AND ObjectModelType = 0
  AND PipelineName = 'P_ALL_SAKURA_D_Automation_Fabric'
  AND DestinationSchemaName = 'Staging';
```

You should see exactly the **one pilot row** you just inserted. If you see 0 rows, recheck the `PipelineName` value (case must match exactly).

---

## Phase 6 — Run the cloned pipeline manually (pilot test)

### Step 16 — Do NOT attach a trigger yet

Make sure **no trigger** is pointing at `P_ALL_SAKURA_D_Automation_Fabric`. The trigger `SakuraV1 DailyRun` points at the original pipeline — leave it alone.

### Step 17 — Trigger a manual debug run

1. In ADF Studio → open `P_ALL_SAKURA_D_Automation_Fabric`.
2. Click **Debug** (the bug icon at the top of the canvas).
3. Click **OK** (no parameters needed).
4. Watch the activity run statuses at the bottom. All should turn **green**.

### Step 18 — If the Copy activity fails

Common errors and fixes:

| Error message | Likely cause | Fix |
|---|---|---|
| `Invalid object name 'BL_FABRIC_SCHEMA.xxx'` | Schema/table name wrong on Fabric | Check the CSV "Fabric Source Query" column and align with actual Fabric schema |
| `Login failed` / `Principal not found` | ADF managed identity not granted on Fabric | Ask platform team to grant access on the Fabric warehouse |
| `Timeout expired` | Query runs too long | Add a `TOP 100` temporarily to test connectivity, then remove |
| `Lookup returned no rows` | `PipelineName` mismatch in settings table | Re-check Step 15 |

---

## Phase 7 — Validate the data landed correctly

### Step 19 — Check staging table

In SSMS, connect to the **Sakura DB (test)** and run:

```sql
-- Check rows landed in staging
SELECT TOP 20 * FROM Staging.Entity ORDER BY 1 DESC;

-- Check row count
SELECT COUNT(*) FROM Staging.Entity;
```

Compare the count to what the old Synapse-sourced row count was (check `ProcessDB.dbo.BBONDataTransferStatus` for the last Synapse run count).

### Step 20 — Check the merge procedure ran

In the **ADF run**, confirm **Execute SP Merge** activity is also green.
Then check the target table in Sakura:

```sql
-- Check data made it to the live table after merge
SELECT TOP 20 * FROM SAKURA.Entity ORDER BY 1 DESC;
SELECT COUNT(*) FROM SAKURA.Entity;
```

### Step 21 — Compare counts Synapse vs Fabric

```sql
-- In ProcessDB: last Synapse run stats for Entity
SELECT TOP 1 *
FROM dbo.BBONDataTransferStatus
WHERE CoreObjectTableName = 'Entity'
ORDER BY DateCreated DESC;
```

If the counts are **close** (within expected delta) and key columns look right → pilot is validated.

---

## Phase 8 — Widen to all objects

### Step 22 — Add more rows one by one

Repeat **Steps 13–21** for each remaining object in your scope:
- `Client`
- `CostCenter`
- `MasterServiceSet`
- `ServiceLine`
- _(and others from the CSV)_

Insert one row at a time, run the pipeline manually, validate, then move to the next.

### Step 23 — Do NOT touch the original pipeline

At no point change `P_ALL_SAKURA_D_Automation` or its `BBONDataTransferSettings` rows.
The original runs on Synapse in test/prod as before — only the clone uses Fabric.

---

## Phase 9 — Sign-off and promote

### Step 24 — Record sign-off criteria

Before promoting to UAT or prod, confirm:
- [ ] All objects row counts match (or difference is understood/acceptable)
- [ ] All merge procedures ran without error
- [ ] No downstream Sakura portal features broken (spot check permissions, reports)
- [ ] Run the clone pipeline **3 consecutive scheduled runs** successfully

### Step 25 — Promote to production (when ready — not now)

This is a separate decision. Options:
1. **Swap trigger**: Point `SakuraV1 DailyRun` at `P_ALL_SAKURA_D_Automation_Fabric` and disable the original.
2. **Replace linked service**: Swap `DB_Synapse_Sensei` on the original pipeline for the Fabric linked service and update original `BBONDataTransferSettings` rows.

Choose **option 1** (swap trigger) for the cleanest and safest rollback path.

---

## Quick reference: what you changed vs what you did NOT change

| Item | Changed? | Notes |
|---|---|---|
| `P_ALL_SAKURA_D_Automation` (original) | **NO** | Never touched |
| `P_ALL_SAKURA_D_Automation_Fabric` (clone) | **YES** | Source dataset swapped to Fabric |
| `DB_Synapse_Sensei` linked service | **NO** | Still used by original |
| `DB_Fabric_UMS` linked service | **YES (new)** | Points at Fabric SQL endpoint |
| `DS_SYN_DYN_QUERY` dataset | **NO** | Still used by original |
| `DS_FAB_DYN_QUERY` dataset | **YES (new)** | Used by clone's Copy source |
| `DS_ASQL_DYN_SAKURA_TBL` (sink dataset) | **NO** | Same sink for both |
| `DB_Master_Sakura` linked service | **NO** | Same sink connection |
| `DB_Master_ProcessDB` linked service | **NO** | Already on Fabric, shared |
| `BBONDataTransferSettings` original rows | **NO** | `IsEnabled=0`, untouched |
| `BBONDataTransferSettings` new pilot rows | **YES (new inserts)** | New rows, `PipelineName = _Fabric` clone name |
| `SakuraV1 DailyRun` trigger | **NO** | Still fires original pipeline |
| Staging tables / merge SPs | **NO** | Same contract, unchanged |
