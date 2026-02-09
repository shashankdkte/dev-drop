Sakura ETL & Sakura_DB — Complete Reference (Zero Ambiguity)
This document distills the Sakura ETL meeting transcript and Sakura_DB codebase into: what is being said, what is expected, and how to perform each task with no ambiguity.
--------------------------------------------------------------------------------
1. What Is Being Said (Summary)
1.1 Purpose of the ETL
• ETL tool copies data from multiple sources into the Sakura database.
• Same principle as in other data projects: source → transform/load → destination (Sakura).
flowchart LR
    subgraph Sources["Data sources"]
        Fabric["Fabric"]
        Ronin["Ronin DB"]
    end
    subgraph ETL["Azure Data Factory ETL"]
        ADF["ADF Pipelines\nazeuw1dadfsakura"]
    end
    Sakura[("Sakura DB\nstage + ref tables")]
    Fabric --> ADF
    Ronin --> ADF
    ADF --> Sakura
1.2 Two Data Streams
There are exactly two data streams into Sakura:
Stream
Source
Pipeline name (concept)
1
Fabric
Central Import (Fabric → Sakura)
2
Ronin database
Ronin Import (Ronin → Sakura)
• Content/logic of both streams is the same; only the data sources (Fabric vs Ronin) differ (ADF limitation).
• Azure Data Factory (ADF) resource: azeuw1dadfsakura (tagged “Sakura”), location Central, same subscription.
flowchart LR
    subgraph Stream1["Stream 1"]
        F[Fabric] --> P1["P_REF_CENTRAL_IMPORT"]
    end
    subgraph Stream2["Stream 2"]
        R[Ronin DB] --> P2["P_REF_RONIN_IMPORT"]
    end
    P1 --> S[("Sakura DB")]
    P2 --> S
1.3 Pipeline Structure in ADF
• 3 pipelines in the ETL resource:
    1. Caller / parent pipeline — invokes the two data streams.
    2. Central Import — Fabric → Sakura.
    3. Ronin Import — Ronin → Sakura.
flowchart TB
    Parent["Parent / Caller pipeline"]
    Central["Central Import pipeline\nP_REF_CENTRAL_IMPORT\nFabric to Sakura"]
    Ronin["Ronin Import pipeline\nP_REF_RONIN_IMPORT\nRonin to Sakura"]
    Parent --> Central
    Parent --> Ronin
1.4 Where Configuration Lives (Sakura Database)
All ETL configuration and execution history live inside the Sakura database, under the mgmt (management) schema:
Object
Role
mgmt.DataTransferSettings
Definitions: which transfers to run (source query, destination table, merge SP, pipeline name, order). One row per transfer.
mgmt.DataTransferExecutions
History: last run per transfer (status, rows read/copied, duration, errors, etc.).
• The ADF pipeline uses a Lookup that reads mgmt.DataTransferSettings filtered by PipelineName.
• PipelineName in the table must exactly match the ADF pipeline name (e.g. P_REF_CENTRAL_IMPORT, P_REF_RONIN_IMPORT) so the right rows are used.
flowchart TB
    subgraph SakuraDB["Sakura database"]
        subgraph mgmt["mgmt schema"]
            DTS["DataTransferSettings\n(definitions per transfer)"]
            DTE["DataTransferExecutions\n(run history)"]
        end
    end
    ADF["ADF Lookup\nfilter by PipelineName"] --> DTS
    DTS --> DTE
1.5 How One Transfer Runs (Per Row in DataTransferSettings)
For each active row in mgmt.DataTransferSettings (for that pipeline):
1. Copy data from source (Fabric or Ronin) into Sakura stage (e.g. stage.BPCBrands). Highly parameterized; source comes from SourceQuery / SourceQueryType.
2. Merge from stage into final tables: the Merge SP name is in MergeSPName (e.g. stage.spLoadBPCBrands). That SP is executed after the copy.
3. Set status: either “success” or “failed” via two different steps/stored procedures. Those steps call mgmt.spSetDataTransferExecution with a JSON string built in ADF (object schema, table name, pipeline, run id, rows read/copied, duration, errors, etc.).
4. mgmt.spSetDataTransferExecution parses the JSON and upserts mgmt.DataTransferExecutions (and writes to event log). Keep the existing conditions in the pipeline (success vs failed branches); that’s the current design and best practice.
flowchart TB
    subgraph ADF["ADF pipeline per transfer row"]
        L["Lookup: mgmt.DataTransferSettings\nWHERE PipelineName = current pipeline"]
        L --> F["For each row"]
        F --> C["Copy: SourceQuery to stage table"]
        C --> M["Execute Merge SP\nMergeSPName e.g. stage.spLoadBPCBrands"]
        M --> S{"Copy succeeded?"}
        S -->|Yes| SP["Set success\ncall spSetDataTransferExecution"]
        S -->|No| FP["Set failed\ncall spSetDataTransferExecution"]
    end
    subgraph Sakura["Sakura DB"]
        SP --> DTE["mgmt.DataTransferExecutions\nMERGE plus event log"]
        FP --> DTE
    end
1.6 Post-Deployment and Data Transfer Settings
• Initial load of mgmt.DataTransferSettings is done by a post-deployment script that is already part of the Sakura database project: Scripts\Post Deployment\Data\mgmt_DataTransferSettings_Default.sql
• That script is included from Sakura.PostDeployment.sql via SQLCMD :r and is run only once per database (guarded by mgmt.PostDeploymentScriptsHistory so it is not re-executed).
• For the first deployment (e.g. UAT/Prod): you can deploy the DB without worrying about this script; it will run and seed the table.
• Later, if you need to change Data Transfer Settings with a release:
    ◦ Do not change the default script to re-insert everything.
    ◦ Create a separate post-deployment script file (e.g. mgmt_DataTransferSettings_Update_YYYYMMDD.sql) that only updates/inserts the rows you need.
    ◦ Register that new script in Sakura.PostDeployment.sql the same way (with a new ScriptName and the same IF NOT EXISTS (PostDeploymentScriptsHistory) pattern) so it runs once.
flowchart TB
    Build["Build DB project\nDACPAC"]
    Deploy["Deploy DACPAC\nto target server"]
    PDM["Sakura.PostDeployment.sql\nruns top to bottom"]
    Check["IF NOT EXISTS in\nmgmt.PostDeploymentScriptsHistory"]
    Run[" :r script\nrun once"]
    Log["INSERT into\nPostDeploymentScriptsHistory"]
    Seed["mgmt_DataTransferSettings_Default.sql\nDELETE + INSERT default rows"]
    Build --> Deploy
    Deploy --> PDM
    PDM --> Check
    Check -->|Not run yet| Run
    Run --> Seed
    Seed --> Log
    Check -->|Already run| Skip["Skip script"]
1.7 Execution History and System-Versioned Tables
• mgmt.DataTransferExecutions stores the latest execution per transfer (plus history via system-versioned tables).
• mgmt.DataTransferSettings is also system-versioned; changes to settings (e.g. query or merge SP name) are tracked in the history table.
• For historical execution or settings data, use the history tables (e.g. history.DataTransferExecutions, history.DataTransferSettings).
erDiagram
    mgmt_DataTransferSettings ||--o{ mgmt_DataTransferExecutions : "DataTransferSettingId"
    mgmt_DataTransferSettings {
        int Id PK
        int SourceQueryType
        nvarchar SourceQuery
        nvarchar DestinationSchemaName
        nvarchar DestinationTableName
        nvarchar MergeSPName
        nvarchar PipelineName "must match ADF pipeline name"
        int ExecutionOrder
        bit IsActive
        datetime2 ValidFrom
        datetime2 ValidTo
    }
    mgmt_DataTransferExecutions {
        int Id PK
        int DataTransferSettingId FK
        nvarchar ObjectSchemaName
        nvarchar ObjectTableName
        nvarchar PipelineName
        nvarchar LastExecutionStatus
        int RowsRead
        int RowsCopied
        int CopyDurationSec
        nvarchar LastRunOutput
        datetime2 ValidFrom
        datetime2 ValidTo
    }
    history_DataTransferSettings {
        int Id
        datetime2 ValidFrom
        datetime2 ValidTo
    }
    history_DataTransferExecutions {
        int Id
        datetime2 ValidFrom
        datetime2 ValidTo
    }
    mgmt_DataTransferSettings ||--o{ history_DataTransferSettings : "system versioning"
    mgmt_DataTransferExecutions ||--o{ history_DataTransferExecutions : "system versioning"
1.8 Environments and Deployment
• Scripts are prepared in development first; the same scripts are then run/executed in UAT and production after those DBs exist.
• UAT and Production: At the time of the call, no UAT/Prod pipelines or stages were created yet. Request: create release pipelines/stages for UAT and Prod when possible; if not, deployment can be done manually.
• Database: Sakura V2 database lives on the same server as “process DB” (Ronin/Sakura); Fabric has been ported/migrated separately.
• Service principal: ADF uses a service connection in the (Sakura) DevOps project; for deploying to prod, use a prod service principal that has access to prod subscription/resources. The exact SP used for Fabric deployments can be reused if it has the right scope.
flowchart LR
    Dev["Dev\nprepare scripts"]
    UAT["UAT\nDB + ADF"]
    Prod["Production\nDB + ADF"]
    Dev --> UAT
    UAT --> Prod
    subgraph Each["Per environment"]
        DB[("Sakura DB\nDACPAC deploy")]
        ADF[ADF pipelines\nlinked services]
        DB --- ADF
    end
1.9 Access and Repos
• Sakura is a different DevOps project (e.g. “Dentsu Finance BI” / Sakura). Amit needed to be added as administrator to that project to configure pipelines.
• Database project: Sakura DB (e.g. under dev.visualstudio.com/.../Sakura). Build produces a DACPAC that includes the post-deployment script (single compiled post-deployment at build time).
• Order of execution: Post-deployment runs top to bottom; order of scripts in Sakura.PostDeployment.sql matters. Do not put GO inside the one-time script files referenced by :r (it can terminate the outer script).
1.10 ADF Deployment (UAT/Prod)
• Copy the ADF pipelines (or the whole factory) to UAT/Prod, or create a new factory and deploy.
• Override in ADF:
    ◦ Sakura DB linked service (server/database).
    ◦ Ronin linked service (server/database).
    ◦ Any Fabric / Central connection (e.g. “Central Gold”) for the environment.
• Authentication: ADF uses managed identity (system-assigned) where possible; confirm linked services use that for Fabric/Ronin and Sakura.
1.11 Data Upload and Dependencies
• Data uploads (into Sakura for app use) can only happen after:
    1. Resources (e.g. UAT/Prod DB and ADF) are created.
    2. ETL has been run so that database tables are filled with data.
• Dev: Some integrity/plausibility checks and tests (including truncation/recreation) were being done; temporary “data weirdness” in dev can occur during that phase. Structure (e.g. views) remains the same.
flowchart TB
    subgraph Prereq["Prerequisites for data upload"]
        R["Resources created: UAT/Prod DB and ADF"]
        E["ETL run: stage and ref tables filled"]
    end
    R --> E
    E --> U["Data upload into Sakura for app"]
--------------------------------------------------------------------------------
2. What Is Expected (Responsibilities and Outcomes)
Who / What
Expectation
Sakura DB deployment
Deploy DB project (DACPAC) to Dev → UAT → Prod so that mgmt.DataTransferSettings and mgmt.DataTransferExecutions (and the rest of Sakura) exist. First deployment runs the default Data Transfer Settings script once.
ADF ETL
Two pipelines (Central Import, Ronin Import) run from a parent; they read from mgmt.DataTransferSettings (by PipelineName), copy to stage, run the merge SP, then call mgmt.spSetDataTransferExecution for logging.
UAT/Prod
Create UAT/Prod DBs (e.g. copy from Dev or deploy via DACPAC). Create/release ADF to UAT/Prod and update linked services (Sakura, Ronin, Fabric/Central). Run ETL so tables are filled.
Future changes to transfer definitions
Add new post-deployment scripts (with date in name) for incremental updates to mgmt.DataTransferSettings; do not rely on re-running the default script.
Security
ETL identity (e.g. SakuraETLUser or ADF managed identity) needs: read/write to Sakura, execute mgmt.spSetDataTransferExecution, and (as stated in scripts) ALTER on mgmt schema for truncate. Grant scripts are in post-deployment (e.g. Grant_Rights_To_Managed_User_Of_ADF.sql).
flowchart TB
    subgraph Responsibilities["Responsibilities"]
        DB["Sakura DB deployment\nDACPAC to Dev/UAT/Prod"]
        ADF["ADF ETL\nread DataTransferSettings by PipelineName\ncopy → merge SP → spSetDataTransferExecution"]
        UAT["UAT/Prod\ncreate DBs and ADF\nupdate linked services"]
        Future["Future config\nnew post-deploy script per change"]
        Sec["Security\ndb_datareader/writer, EXECUTE spSetDataTransferExecution\nALTER on mgmt"]
    end
    DB --> ADF
    UAT --> ADF
    Future --> DB
    Sec --> ADF
--------------------------------------------------------------------------------
3. How to Perform (Step-by-Step, No Ambiguity)
3.1 Deploy Sakura Database (e.g. to UAT or Prod)
1. Build the Sakura database project (e.g. SakuraV2.DB.sqlproj). This produces a DACPAC including the compiled post-deployment script.
2. Deploy the DACPAC to the target SQL Server (UAT or Prod) using:
    ◦ Azure DevOps release pipeline, or
    ◦ SqlPackage / SSDT deploy from your machine.
3. No extra step for the first deployment: mgmt_DataTransferSettings_Default.sql will run once (guarded by mgmt.PostDeploymentScriptsHistory).
4. Do not add GO inside the script file referenced by :r (e.g. inside mgmt_DataTransferSettings_Default.sql when called from Sakura.PostDeployment.sql).
flowchart LR
    A["Build\nSakuraV2.DB.sqlproj"] --> B["DACPAC\n+ post-deploy compiled"]
    B --> C["Deploy to\nUAT or Prod"]
    C --> D["Post-deploy runs\nDataTransferSettings seed once"]
3.2 Add or Update Data Transfer Settings in a Future Release
1. Do not edit mgmt_DataTransferSettings_Default.sql to add one-off changes (that would re-delete and re-insert all rows on every new DB).
2. Create a new script, e.g. Scripts\Post Deployment\Data\mgmt_DataTransferSettings_Update_20250206.sql, containing only the INSERT/UPDATE you need for the new or changed transfers.
3. Register it in Sakura.PostDeployment.sql:
    ◦ :SETVAR ScriptName ".\Data\mgmt_DataTransferSettings_Update_20250206.sql"
    ◦ Then the same block: IF NOT EXISTS (SELECT * FROM mgmt.PostDeploymentScriptsHistory WHERE [ScriptName] = '$(ScriptName)' AND [DatabaseName] = DB_NAME()) → :r $(ScriptName) → INSERT INTO mgmt.PostDeploymentScriptsHistory ....
4. Order: Place this block in the right position (top-to-bottom order matters).
flowchart TB
    A["Create new script\nmgmt_DataTransferSettings_Update_YYYYMMDD.sql"]
    B["Only INSERT/UPDATE\nrows you need"]
    C["In Sakura.PostDeployment.sql\n:SETVAR ScriptName ..."]
    D["IF NOT EXISTS PostDeploymentScriptsHistory\n:r script\nINSERT History"]
    A --> B
    B --> C
    C --> D
3.3 Deploy ADF to UAT or Prod
1. Copy the ETL pipelines (parent + Central Import + Ronin Import) to the target factory, or deploy the whole factory (e.g. from ARM/template or DevOps).
2. Update linked services so they point to the target environment:
    ◦ Sakura DB: server + database for UAT/Prod.
    ◦ Ronin: server + database for UAT/Prod.
    ◦ Fabric / Central (e.g. “Central Gold”): connection for UAT/Prod.
3. Override any pipeline or global parameters (e.g. server name, DB name) so they match the environment.
4. Confirm authentication: managed identity (or service principal) must have access to Fabric/Ronin and to Sakura (with EXECUTE on mgmt.spSetDataTransferExecution and any other required rights).
flowchart TB
    Copy["Copy pipelines: parent, Central, Ronin"]
    LS["Update linked services: Sakura DB, Ronin, Fabric/Central"]
    Params["Override parameters: server, database"]
    Auth["Confirm auth: managed identity or SP"]
    Copy --> LS
    LS --> Params
    Params --> Auth
3.4 Run ETL and Verify
1. Trigger the parent pipeline (or run Central Import and Ronin Import).
2. Check mgmt.DataTransferExecutions for each pipeline: LastExecutionStatus, RowsRead, RowsCopied, LastExecutionMessage, etc.
3. Check history.DataTransferExecutions for full history if needed.
4. Confirm stage and final tables in Sakura are populated (e.g. stage.* and ref tables) before enabling or testing “data upload” features that depend on this data.
sequenceDiagram
    participant User
    participant ADF as ADF parent pipeline
    participant Central as Central Import
    participant Ronin as Ronin Import
    participant Sakura as Sakura DB
    User->>ADF: Trigger run
    ADF->>Central: Execute
    ADF->>Ronin: Execute
    Central->>Sakura: Lookup DataTransferSettings
    Central->>Sakura: Copy to stage, Merge SP, spSetDataTransferExecution
    Ronin->>Sakura: Lookup DataTransferSettings
    Ronin->>Sakura: Copy to stage, Merge SP, spSetDataTransferExecution
    User->>Sakura: Check mgmt.DataTransferExecutions
3.5 Match Pipeline Name to Database
• In ADF, the pipeline that runs the “Central” or “Ronin” transfers has a name (e.g. P_REF_CENTRAL_IMPORT, P_REF_RONIN_IMPORT).
• In mgmt.DataTransferSettings, the column PipelineName must contain exactly that same name (same string).
• The Lookup in ADF filters by this name; if it doesn’t match, no rows are returned and no transfers run for that pipeline.
flowchart LR
    subgraph ADF["ADF pipeline name"]
        P1["P_REF_CENTRAL_IMPORT"]
        P2["P_REF_RONIN_IMPORT"]
    end
    subgraph DB["mgmt.DataTransferSettings.PipelineName"]
        C1["P_REF_CENTRAL_IMPORT"]
        C2["P_REF_RONIN_IMPORT"]
    end
    P1 <--> C1
    P2 <--> C2
3.6 Granting Rights for ETL (Already in DB Project)
• SakuraETLUser (or the ADF managed user) needs:
    ◦ db_datareader, db_datawriter
    ◦ EXECUTE on mgmt.spSetDataTransferExecution
    ◦ ALTER ON SCHEMA::mgmt (for truncate, as per comment in SakuraETLUser.sql)
• Post-deployment script Grant_Rights_To_Managed_User_Of_ADF.sql grants EXECUTE on mgmt.spSetDataTransferExecution to the ADF managed identities (e.g. azeuw1dadfsakura, azeuw1tadfsakura, azeuw1padfsakura). Ensure the correct server/DB user names exist and are used in that script for each environment.
flowchart TB
    ETL["ETL identity\nSakuraETLUser or ADF managed identity"]
    ETL --> R1["db_datareader"]
    ETL --> R2["db_datawriter"]
    ETL --> R3["EXECUTE mgmt.spSetDataTransferExecution"]
    ETL --> R4["ALTER ON SCHEMA mgmt"]
    Grant["Grant_Rights_To_Managed_User_Of_ADF.sql\npost-deployment"]
    Grant --> R3
--------------------------------------------------------------------------------
4. Sakura_DB Objects Involved (Quick Reference)
Object
Purpose
mgmt.DataTransferSettings
Config: SourceQueryType, SourceQuery, DestinationSchemaName, DestinationTableName, MergeSPName, PipelineName, ExecutionOrder, IsActive. System-versioned.
mgmt.DataTransferExecutions
Run history per transfer: status, rows read/copied, duration, errors, LastRunOutput (JSON). System-versioned.
mgmt.spSetDataTransferExecution
Called by ADF with @RunOutputJSONTxt and @DataTransferSettingId; parses JSON and MERGEs into DataTransferExecutions; writes to event log.
mgmt.PostDeploymentScriptsHistory
Tracks which post-deployment scripts have run (ScriptName, DatabaseName) to avoid double execution.
stage schema + tables
Staging tables (e.g. BPCBrands, Employees) and stage.spLoad* merge stored procedures.
Scripts\Post Deployment\Data\mgmt_DataTransferSettings_Default.sql
One-time seed: DELETE then INSERT default rows for Central and Ronin pipelines.
Sakura.PostDeployment.sql
Master post-deployment: uses :r and PostDeploymentScriptsHistory to run Default and one-time scripts in order.
flowchart TB
    subgraph mgmt["mgmt schema"]
        DTS[("DataTransferSettings")]
        DTE[("DataTransferExecutions")]
        SP["spSetDataTransferExecution"]
        Hist["PostDeploymentScriptsHistory"]
    end
    subgraph history["history schema"]
        H_DTS[("DataTransferSettings")]
        H_DTE[("DataTransferExecutions")]
    end
    subgraph stage["stage schema"]
        StageT["stage tables\nBPCBrands, Employees, ..."]
        MergeSP["spLoad* merge procedures"]
    end
    ADF["ADF"] --> DTS
    ADF --> SP
    SP --> DTE
    DTS -.-> H_DTS
    DTE -.-> H_DTE
    ADF --> StageT
    ADF --> MergeSP
    PDM["Sakura.PostDeployment.sql"] --> Hist
    PDM --> DTS
--------------------------------------------------------------------------------
5. Pipeline Names (Exact Values Matter)
• Central Import (Fabric → Sakura): P_REF_CENTRAL_IMPORT
• Ronin Import (Ronin → Sakura): P_REF_RONIN_IMPORT
Every row in mgmt.DataTransferSettings that belongs to Central Import must have PipelineName = 'P_REF_CENTRAL_IMPORT'; every row for Ronin Import must have PipelineName = 'P_REF_RONIN_IMPORT'. No extra spaces or different casing.
flowchart TB
    subgraph Central["Central Import"]
        direction TB
        C1["PipelineName = 'P_REF_CENTRAL_IMPORT'"]
        C2["BPCBrands, BPCSegments, CostCenters\nEmployees, Entities, MasterServiceSets\nProfitCenters, ServiceLines, ..."]
    end
    subgraph Ronin["Ronin Import"]
        direction TB
        R1["PipelineName = 'P_REF_RONIN_IMPORT'"]
        R2["BusinessUnits, Regions, ClientPrograms\nMarkets, Clusters, Countries\nDentsuStakeholders, PeopleAggregators, ..."]
    end
    C1 --> C2
    R1 --> R2
--------------------------------------------------------------------------------
This reference is the single source for what was said, what is expected, and how to perform ETL and Sakura_DB tasks without ambiguity.
