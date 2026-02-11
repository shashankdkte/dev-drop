# How to Get YAML for Each Pipeline (for Replication to Other Envs)

Three ways to get pipeline YAML: **from the repo**, **from Azure DevOps UI**, or **via API/CLI**. Use the table below to know where each pipeline’s YAML lives.

---

## Quick reference: pipeline name → YAML source

| Pipeline name (from Azure DevOps) | Type | YAML in this repo? | Path |
|----------------------------------|------|--------------------|------|
| **Sakura_Frontend_Dev_Build_Release** (Frontend) | Build + Release (combined) | Yes | `FE/application/azure-dev-build-release-pipeline.yml` |
| **Sakura Backend Deploy DEV** | **Release** (deploy only) | Yes | `BE_Main/Sakura_Backend/AzureDevDeploymentPipeline.yaml` |
| **Sakura Backend Build DEV** | **Build** (artifact only) | Yes | `BE_Main/Sakura_Backend/AzureDevBuildPipeline.yaml` |
| **Sakura Backend PR Quick Build** | Build only (PR validation) | Yes | `BE_Main/Sakura_Backend/AzurePRQuickBuildPipeline.yaml` |
| **Sakura Backend DEV Build** | **Build** (alternate) | Yes | `BE_Main/Sakura_Backend/AzureBuildPipeline.yaml` |
| **Sakura Database Build DEV** | **Build** (DB artifact) | No | Get from Azure DevOps (see Method 2 below) |
| **Sakura ETL CICD** | Build + Release (ETL) | No (likely other repo) | Get from Azure DevOps or the ETL repo |

For pipelines that are **not** in this repo, use **Method 2** or **Method 3**.

---

## Why are there Build and Release pipelines for each?

Different parts of the system (database, backend, frontend) use **Build** vs **Release** in different ways:

| Area | Build pipeline(s) | Release pipeline(s) | Why the split? |
|------|--------------------|----------------------|----------------|
| **Database** | **Sakura Database Build DEV** – compiles/packages the database (e.g. .dacpac or scripts). | *(None in list – deploy may be manual or a separate pipeline.)* | Build produces a DB artifact (package or scripts). Deploy is often run less often or to multiple envs (dev → test → prod), so it may be a separate release pipeline or manual. |
| **Backend** | **Sakura Backend Build DEV** – compile, test, publish .NET → produces a **zip artifact**. **Sakura Backend DEV Build** – alternate build (e.g. different branch/trigger). **Sakura Backend PR Quick Build** – build + test on PRs only, no deploy. | **Sakura Backend Deploy DEV** – takes the **Build** artifact and deploys it to the dev App Service. | Build runs on every commit (or PR); it produces one artifact. Release runs when we want to deploy that same artifact to an environment (dev, then later test/prod). One build, many possible deploys. |
| **Frontend** | **Sakura_Frontend_Dev_Build_Release** – single pipeline that does **build and deploy** in one run. | Same pipeline – builds the app and deploys to the Static Web App in a single run. | Static Web Apps are often wired so “build + deploy” is one step (e.g. Oryx build on Azure, then deploy). So you see “Build + Release (combined)” – no separate release pipeline. |

**Summary:**

- **Backend:** Explicit split – **Build** = produce artifact; **Release** = deploy that artifact to an environment. Makes it easy to deploy the same build to test/prod later.
- **Database:** **Build** = produce DB package/scripts; release/deploy may be separate or manual.
- **Frontend:** One pipeline only – **Sakura_Frontend_Dev_Build_Release** does **build + release combined** in a single run.

---

## Why renaming the pipeline YAML file doesn’t trigger (or breaks) the pipeline

**Azure DevOps ties each pipeline to a fixed YAML file path.** When you create the pipeline, you choose “Existing Azure Pipelines YAML file” and set the path (e.g. `FE/application/azure-dev-build-release-pipeline.yml`). That path is stored in the pipeline definition.

When you **only rename the file in the repo** (e.g. to `azure-dev-build-release-pipeline.yml`):

1. The pipeline definition in Azure DevOps still points at the **old path**.
2. On push, Azure evaluates triggers and then loads the YAML from that **stored path**.
3. The old path no longer exists → the pipeline either **fails** (“file not found”) or **doesn’t run**, because the definition can’t be loaded.

So the trigger doesn’t “see” the rename as “run this pipeline” – it still tries to load the old path and fails.

**Correct way to rename the pipeline file:**

1. **In Azure DevOps:** Pipelines → open the pipeline → **Edit** (or ⋯ → Edit).
2. Use **…** next to the YAML path and change it to the **new** path (e.g. `FE/application/azure-dev-build-release-pipeline.yml`) → **Save** (and run once if needed).
3. **In the repo:** Rename the file to match and push.

Do step 2 **before** or **in the same change** as step 3. If you already renamed only in the repo, either revert the rename (as you did) or update the pipeline’s YAML path in Azure DevOps to the new filename and push again so the file exists at that path.

---

## Method 1: From the repo (easiest when YAML is in repo)

1. Open the path in the table above in your repo (e.g. in Cursor/VS Code or on the **Repos** tab in Azure DevOps).
2. Copy the file contents — that’s the pipeline YAML.
3. To replicate for another env: copy the file, rename (e.g. `AzureTestDeploymentPipeline.yaml`), change env-specific values (app name, resource group, variable groups, etc.).

No need to use the Azure DevOps UI for these.

---

## Method 2: From Azure DevOps UI (Edit pipeline)

Use this for **any** pipeline (including Database, ETL, or if the pipeline is not linked to a repo file).

1. In **Pipelines** → **Recently run pipelines**, find the pipeline.
2. Click the **⋯** (three dots) on the right.
3. Click **Edit**.
4. You’ll see either:
   - **“Get sources” / repo + path**: the YAML is in that repo at that path. Open that file in the repo to get/copy the YAML.
   - **Full YAML in the editor**: the definition is shown in the browser. Select all and copy, then paste into a local `.yml`/`.yaml` file in your repo (e.g. under `Docs/pipelines-export/` or next to your other pipeline files).
5. Save a copy with a clear name, e.g. `Sakura-Database-Build-DEV.yaml`, so you can replicate and change env-specific parts.

To replicate for another env: duplicate the file, rename, then replace dev-specific values (service connection, resource group, app name, variable group, etc.) with test/prod values.

---

## Method 3: Export all pipeline YAML via Azure DevOps REST API (bulk)

Use this to get YAML for **every** pipeline in the project at once (including Database and ETL).

### Prerequisites

- **Personal Access Token (PAT)** with **Build (Read)** scope.  
  Azure DevOps → User settings (top right) → **Personal access tokens** → New token → Scopes: **Build – Read**.
- **Organization URL**, e.g. `https://dev.azure.com/YourOrg` or `https://danfinancebi.visualstudio.com`.
- **Project name**, e.g. `Sakura`.
- **Pipeline IDs**: in Azure DevOps, open each pipeline; the URL has `...?definitionId=XXX`. That number is the pipeline ID.

### Option A: PowerShell script (export by pipeline ID)

Save the script below, fill in the variables at the top, then run it. It will create one file per pipeline under `Docs/pipelines-export/`.

```powershell
# Fill these in
$orgUrl = "https://dev.azure.com/YourOrg"   # or https://danfinancebi.visualstudio.com
$project = "Sakura"
$pat = "YOUR_PAT_HERE"

# Pipeline display name -> definition id (get from pipeline URL: definitionId=XXX)
$pipelineIds = @{
    "Sakura_Frontend_Dev_Build_Release" = 102
    "Sakura-Backend-Deploy-DEV" = 103
    "Sakura-Backend-Build-DEV" = 104
    "Sakura-Database-Build-DEV" = 105
    "Sakura-Backend-PR-Quick-Build" = 106
    "Sakura-ETL-CICD" = 107
    "Sakura-Backend-DEV-Build" = 108
}

$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{ Authorization = "Basic $base64Auth" }

$exportDir = "Docs/pipelines-export"
if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Path $exportDir -Force }

foreach ($name in $pipelineIds.Keys) {
    $id = $pipelineIds[$name]
    $uri = "$orgUrl/$project/_apis/build/definitions/$id`?api-version=7.0"
    try {
        $def = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        $yaml = $def.process.yamlFilename
        if ($def.configuration) {
            # If definition stores YAML inline or we have config, save it
            $outFile = Join-Path $exportDir "$name.yaml"
            $def | ConvertTo-Json -Depth 20 | Set-Content $outFile -Encoding UTF8
            Write-Host "Exported $name to $outFile"
        }
    } catch {
        Write-Warning "Failed $name : $_"
    }
}
```

To get **actual YAML content** (when the pipeline is stored as YAML in the definition), Azure DevOps often serves it from the repo. So the most reliable “get YAML” flow is:

1. Use the API to list definitions and see which repo/path each uses.
2. For pipelines that use a repo file: pull that file from the repo (Method 1).
3. For pipelines that don’t (e.g. UI-only or different repo): use Method 2 (Edit → copy YAML from the editor).

### Option B: List all pipelines and open Edit in browser

If you prefer not to use the API, you can:

1. Go to **Pipelines** and note each pipeline name.
2. For each: **⋯ → Edit** → copy the YAML from the editor (Method 2) and save into a file under e.g. `Docs/pipelines-export/<Pipeline-Name>.yaml`.

---

## Recommended workflow for replicating to another env

1. **Collect YAML**  
   - Use the table above for pipelines that are in this repo (Method 1).  
   - For **Sakura Database Build DEV** (and ETL if needed): use **Edit** (Method 2) and save a copy.

2. **Create env-specific copies**  
   - Example: `AzureDevDeploymentPipeline.yaml` → `AzureTestDeploymentPipeline.yaml`.  
   - Use a naming convention, e.g. `*Dev*.yaml` vs `*Test*.yaml` vs `*Prod*.yaml`.

3. **Parameterise**  
   - Replace hardcoded dev values with variables (e.g. `$(webAppName)`, `$(resourceGroupName)`), and set those in a variable group or in the pipeline UI (e.g. “Sakura-Test-Variables”).

4. **Create the new pipeline in Azure DevOps**  
   - Pipelines → New pipeline → Azure Repos Git (or GitHub) → choose repo → choose “Existing Azure Pipelines YAML file” → point to the new file (e.g. `AzureTestDeploymentPipeline.yaml`).

5. **Set variable groups and service connections**  
   - Attach the right variable group and service connection for that env (test/prod).

Using **Method 1** for pipelines that are in the repo and **Method 2** for Database (and ETL) gives you all YAML with minimal effort and makes replication to other envs straightforward.
