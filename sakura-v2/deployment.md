Sakura – UAT & Production Setup: Plan Validation & Step-by-Step
Purpose: Validate the plan and provide a simple step-by-step checklist for this week.
Audience: Dev/ops implementing Dev → UAT → Prod.
1. Is What You’re Planning Correct? ✅ Yes
Your item	Correct?	Short note
Azure Web App for Test (UAT) and Prod	✅ Yes	You have Dev only today (azeuw1dweb01sakura). Need one Web App per environment (e.g. UAT, Prod).
Check pipeline setup for all three projects (Database, Backend, Frontend) – build and release	✅ Yes	All three need build + release pipelines, with stages/variables per environment (Dev, UAT, Prod).
Post-deployment scripts as part of Database project pipeline	✅ Yes	DB project already has post-deploy in Sakura.PostDeployment.sql; pipeline must run DACPAC deploy so those scripts run. No extra “script pipeline” – it’s part of DB deploy.
Azure Static Web App for all three environments + proper config at each level	✅ Yes	Today only Dev SWA exists. Need SWA for UAT and Prod, and per-environment config (API URL, auth, etc.).
So: your four points are correct. Below is the step-by-step plan in simple bullets with examples.
2. Step-by-Step Plan (Simple Bullets)
Phase A – Azure resources (often Ops / Infra)
A1. Create UAT Azure Web App (backend).
Example name: azeuw1tweb01sakura (if t = test/UAT).
Same stack as Dev: .NET 8.
Resource group example: AZ-VDC000006-EUW1-RG-BI-UAT-CENTRAL (confirm naming with ops).
A2. Create Production Azure Web App (backend).
Example name: azeuw1pweb01sakura (if p = prod).
Same stack: .NET 8.
Resource group example: AZ-VDC000006-EUW1-RG-BI-PROD-CENTRAL.
A3. Create UAT Azure Static Web App (frontend).
Example: new SWA in UAT resource group; note its URL (e.g. xxx.azurestaticapps.net) and deployment token for the pipeline.
A4. Create Production Azure Static Web App (frontend).
Same as A3 for prod; note URL and deployment token.
A5. Create UAT and Production databases (Sakura DB).
Separate SQL DB per environment (or separate database on same server); document server + database name for UAT and Prod.
Phase B – Database project (build + release, post-deploy is inside DB project)
B1. Ensure Database build pipeline exists and produces a DACPAC.
Project: Sakura_DB/SakuraV2.DB.sqlproj.
Example: MSBuild or dotnet build (SSDT) → output DACPAC (e.g. SakuraV2.DB.dacpac).
Post-deployment is already part of the project: Scripts\Post Deployment\Sakura.PostDeployment.sql (and scripts it calls). No separate “post-deploy pipeline” – it runs when you deploy the DACPAC.
B2. Add release stages for Dev, UAT, Prod (or separate release pipelines per env).
Dev: Deploy DACPAC to Dev SQL Server/database (already in use).
UAT: Deploy same DACPAC to UAT server/database (from A5).
Prod: Deploy same DACPAC to Prod server/database (from A5).
Use SqlPackage.exe or Azure DevOps “SQL Server Database Deploy” / “Azure SQL DacpacTask” with the right connection per stage.
B3. Manage post-deployment scripts only inside the DB project (no extra pipeline).
One-time scripts are under Sakura_DB\Scripts\Post Deployment\ and registered in Sakura.PostDeployment.sql (e.g. Grant_Rights_To_Managed_User_Of_ADF.sql, mgmt_DataTransferSettings_Default.sql, etc.).
They run automatically when DACPAC is deployed; mgmt.PostDeploymentScriptsHistory prevents re-running.
For new one-time scripts: add a new .sql file and a new block in Sakura.PostDeployment.sql (same pattern as existing ones). Deploy via pipeline as in B2.
B4. Per-environment: Grant_Rights_To_Managed_User_Of_ADF.sql.
That script grants rights to ADF managed identity. Ensure server/DB user names (or managed identity names) in the script match each environment (e.g. azeuw1dadfsakura / azeuw1tadfsakura / azeuw1padfsakura). Use variables or different script versions per env if needed.
Phase C – Backend project (build + release)
C1. Confirm build pipeline runs for Backend and publishes an artifact (e.g. zip).
Example: BE_Main/Sakura_Backend/AzureBuildPipeline.yaml or AzureReleasePipeline.yaml build stage – restore, build, test, publish, archive, publish artifact.
C2. Add release (deploy) for UAT and Prod (in addition to Dev).
Today: AzureReleasePipeline.yaml has placeholders (<dev-app-service-name>, <dev-rg-name>, <dev-service-connection-name>) and deploys only to dev when branch = dev.
Add a UAT deploy stage: same artifact, deploy to UAT Web App (e.g. azeuw1tweb01sakura), UAT resource group, UAT service connection. Trigger from a UAT branch or manual.
Add a Prod deploy stage: deploy to Prod Web App (e.g. azeuw1pweb01sakura), Prod resource group, Prod service connection (use Prod service principal). Add approval on Prod if required.
C3. Set per-environment config on the Web App (App Service).
Use App Service Application settings (or Key Vault references) for connection strings, API URLs, feature flags, etc., so the same build can run in Dev, UAT, Prod with different config.
C4. Use correct variable values in the pipeline.
Replace placeholders with real names, e.g.
Dev: webAppName: azeuw1dweb01sakura, resourceGroupName: AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL, azureSubscription: <dev-service-connection>.
UAT: same variables but UAT Web App name, RG, subscription.
Prod: same but Prod Web App name, RG, subscription (and Prod service connection).
Phase D – Frontend project (build + release, Static Web Apps)
D1. Confirm build works (install, build, test if any) and that the pipeline deploys to Azure Static Web Apps.
Example: FE/application/azure-pipelines.yml – today it deploys to one SWA (Dev) using variable group Azure-Static-Web-Apps-orange-sand-03a59b103-variable-group and token AZURE_STATIC_WEB_APPS_API_TOKEN_ORANGE_SAND_03A59B103.
D2. Add UAT and Prod deployment.
Option A (recommended): Separate pipeline YAML or stages: one for Dev, one for UAT, one for Prod. Each stage uses:
Its own variable group with that SWA’s deployment token (e.g. AZURE_STATIC_WEB_APPS_API_TOKEN_<UAT-SWA-ID>, same for Prod).
Its own branch or environment (e.g. deploy to UAT from uat or release/*, to Prod from main with approval).
Option B: One pipeline with stages (Dev → UAT → Prod), each stage using different variable group and deployment token for the corresponding SWA.
D3. Per-environment configuration at each level:
Build: Use Angular environment files so the built app points to the right API.
Dev: environment.ts → apiUrl: 'https://azeuw1dweb01sakura.azurewebsites.net' (already).
UAT: e.g. environment.uat.ts → apiUrl: 'https://azeuw1tweb01sakura.azurewebsites.net' (or your UAT backend URL).
Prod: environment.production.ts → apiUrl: 'https://azeuw1pweb01sakura.azurewebsites.net' (or your prod API URL).
In angular.json, add UAT config that uses environment.uat.ts (and prod uses environment.production.ts). In the pipeline, set configuration per stage (e.g. uat for UAT stage, production for Prod stage).
Static Web App: No backend config on SWA itself; the right API URL is baked in at build time via the environment file. Ensure auth (e.g. redirect URIs) is correct per env (UAT vs Prod URLs).
D4. Create variable groups in Azure DevOps for UAT and Prod.
Example: Azure-Static-Web-Apps-<uat-swa-id>-variable-group and Azure-Static-Web-Apps-<prod-swa-id>-variable-group, each with the corresponding SWA API token (from Azure Portal → Static Web App → Manage deployment token).
Phase E – End-to-end check and docs
E1. Run full path once per environment:
Database: Build → release to Dev → then UAT → then Prod (or in order you use). Confirm post-deploy scripts ran (e.g. check mgmt.PostDeploymentScriptsHistory).
Backend: Build → deploy to Dev → UAT → Prod. Smoke-test one API URL per env.
Frontend: Build (with correct env config) → deploy to Dev → UAT → Prod. Open each SWA URL and confirm it calls the right backend (Dev/UAT/Prod).
E2. Document in one place:
Per environment: Web App name, Static Web App URL, DB server/database, pipeline (build + release) names and branches/triggers.
Update Docs/SAKURA_AZURE_INFRASTRUCTURE_OPS_HANDOVER.md with final names and who does what (ops vs dev).
3. Summary Table (What to do this week)
#	Area	Action (short)
1	Azure Web Apps	Create UAT + Prod Web Apps (backend), same stack as Dev (.NET 8).
2	Azure Static Web Apps	Create UAT + Prod Static Web Apps; note URLs and deployment tokens.
3	Databases	Ensure UAT + Prod DBs exist; document server + DB name per env.
4	DB pipelines	Build → DACPAC; Release with Dev / UAT / Prod deploy; post-deploy is inside DB project.
5	Backend pipelines	Build already; add UAT + Prod deploy stages and replace placeholders with real names.
6	Frontend pipelines	Add UAT + Prod deploy (new stages or pipelines + variable groups + tokens).
7	Frontend config	Add UAT environment file + angular build config; point each env to correct API URL.
8	E2E + docs	Run deploy once per env; document names and responsibilities.
4. Example pipeline variable values (replace with yours)
Backend release (example):
Dev: webAppName: azeuw1dweb01sakura, resourceGroupName: AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL, azureSubscription: <dev-service-connection>.
UAT: webAppName: azeuw1tweb01sakura, resourceGroupName: AZ-VDC000006-EUW1-RG-BI-UAT-CENTRAL, azureSubscription: <uat-service-connection>.
Prod: webAppName: azeuw1pweb01sakura, resourceGroupName: AZ-VDC000006-EUW1-RG-BI-PROD-CENTRAL, azureSubscription: <prod-service-connection>.
Frontend (example):
Dev: variable group with AZURE_STATIC_WEB_APPS_API_TOKEN_ORANGE_SAND_03A59B103 (current).
UAT: new variable group with UAT SWA token; build configuration uat → environment.uat.ts.
Prod: new variable group with Prod SWA token; build configuration production → environment.production.ts.
References: Docs/SAKURA_ETL_AND_SAKURA_DB_REFERENCE.md, Docs/SAKURA_AZURE_INFRASTRUCTURE_OPS_HANDOVER.md, Sakura_DB/Scripts/Post Deployment/Sakura.PostDeployment.sql.
