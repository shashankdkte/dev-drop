# How to Get YAML for Each Pipeline (for Replication to Other Envs)

Three ways to get pipeline YAML: **from the repo**, **from Azure DevOps UI**, or **via API/CLI**. Use the table below to know where each pipeline’s YAML lives.

---

## Quick reference: pipeline name → YAML source

| Pipeline name (from Azure DevOps) | YAML in this repo? | Path |
|----------------------------------|--------------------|------|
| **Sakura Frontend** | Yes | `FE/application/azure-pipelines.yml` |
| **azure-static-web-apps-orange-sand-03...** | Yes | `FE/application/azure-static-web-apps-orange-sand-03a59b103.yml` |
| **Sakura Backend Deploy DEV** | Yes | `BE_Main/Sakura_Backend/AzureDevDeploymentPipeline.yaml` |
| **Sakura Backend Build DEV** | Yes | `BE_Main/Sakura_Backend/AzureDevBuildPipeline.yaml` |
| **Sakura Backend PR Quick Build** | Yes | `BE_Main/Sakura_Backend/AzurePRQuickBuildPipeline.yaml` |
| **Sakura Backend DEV Build** | Yes | `BE_Main/Sakura_Backend/AzureBuildPipeline.yaml` |
| **Sakura Database Build DEV** | No | Get from Azure DevOps (see Method 2 below) |
| **Sakura ETL CICD** | No (likely other repo) | Get from Azure DevOps or the ETL repo |

For pipelines that are **not** in this repo, use **Method 2** or **Method 3**.

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
    "Sakura-Frontend" = 101
    "azure-static-web-apps-orange-sand-03" = 102
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
