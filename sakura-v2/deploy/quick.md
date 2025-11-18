# 🚀 Azure Static Web App - Quick Reference Card

**Project**: Sakura Frontend  
**Repository**: Sakura Frontend (Azure DevOps)  
**Structure**: Angular app at repository root

---

## ⚡ Configuration Values (Copy-Paste Ready)

### **Azure Portal Configuration**

| Field | Value | Notes |
|-------|-------|-------|
| **Subscription** | `VDC000006-EMEA-ORED7-DentsuAegiseCX-NetworkNorthYou` | Your Azure subscription |
| **Resource Group** | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | Development resources |
| **Name** | `sakura-frontend-dev` | Change suffix for other envs |
| **Region** | `Global` | CDN distribution worldwide |
| **Plan Type** | `Standard` | Production-grade with SLA |
| **Source** | `Azure DevOps` | Your Git provider |
| **Organization** | `DANFinanceBl` | Azure DevOps org |
| **Project** | `Sakura` | DevOps project |
| **Repository** | `Sakura Frontend` | ⭐ Angular app at root |
| **Branch** | `dev` | Or `main` for production |

### **Build Configuration**

| Field | Value | Notes |
|-------|-------|-------|
| **Build Presets** | `Angular` | Auto-configures for Angular |
| **App location** | `/` or *leave empty* | ⭐ App is at repository root |
| **API location** | *leave empty* | Backend is separate |
| **Output location** | `dist/application/browser` | Angular 17+ output folder |

---

## 📂 Repository Structure

Your **Sakura Frontend** repository structure:

```
Sakura Frontend Repository (Root)/
├── .vscode/                    ← VS Code settings
├── pdf_pages_approver/         ← PDF screenshots
├── pdf_pages_requester/        ← PDF screenshots  
├── pdf_pages_workspaceadmin/   ← PDF screenshots
├── public/                     ← Static assets
│   └── favicon.ico
├── src/                        ⭐ Angular source code
│   ├── app/                    ← Application code
│   ├── environments/           ← Environment configs
│   ├── index.html              ← Main HTML
│   ├── main.ts                 ← Entry point
│   └── styles.css              ← Global styles
├── .editorconfig               
├── .gitignore                  
├── angular.json                ⭐ Build configuration (at root!)
├── db-design.md                
├── package.json                ⭐ Dependencies (at root!)
├── package-lock.json           
├── README.md                   
├── tsconfig.app.json           
└── tsconfig.json               

After build, creates:
└── dist/
    └── application/
        └── browser/            ⭐ Deployed files here
            ├── index.html
            ├── main.js
            └── ... other built files
```

**Key Point**: Your Angular app (`angular.json`, `package.json`) is at the **repository root**, not in a subfolder!

---

## ✅ Step-by-Step Deployment

### **1. Create Static Web App (Azure Portal)**

```
1. Azure Portal → Create a resource → Static Web App
2. Fill in values from table above
3. Next: Deployment configuration
4. Enter build values from table above
5. Review + create → Create
6. Wait ~10-15 minutes for first deployment
```

### **2. Configure Application Settings**

```
1. Go to your Static Web App → Configuration
2. Add these settings:

Name: MSAL_CLIENT_ID
Value: [Your Azure AD client ID]

Name: MSAL_AUTHORITY  
Value: https://login.microsoftonline.com/[your-tenant-id]

Name: MSAL_REDIRECT_URI
Value: https://sakura-frontend-dev.azurestaticapps.net

Name: API_BASE_URL
Value: [Your backend API URL]

3. Save
```

### **3. Update Azure AD App Registration**

```
1. Azure Portal → Azure Active Directory
2. App registrations → [Your app]
3. Authentication → Redirect URIs
4. Add: https://sakura-frontend-dev.azurestaticapps.net
5. Save
```

### **4. Test Deployment**

```
1. Open: https://sakura-frontend-dev.azurestaticapps.net
2. Test login
3. Test API calls
4. Test routing
```

---

## 🔧 Pipeline Configuration

**File created in repo**: `azure-pipelines.yml`

**Minimal working configuration**:

```yaml
trigger:
  branches:
    include:
      - dev

pool:
  vmImage: 'ubuntu-latest'

variables:
  app_location: '/'                           # ⭐ Root of repo
  output_location: 'dist/application/browser' # ⭐ Build output
  node_version: '18.x'

stages:
  - stage: Build
    jobs:
      - job: BuildAndDeploy
        steps:
          - checkout: self
          
          - task: NodeTool@0
            inputs:
              versionSpec: $(node_version)
          
          - script: npm ci
            displayName: 'Install Dependencies'
          
          - script: npm run build -- --configuration=api-dev
            displayName: 'Build'
          
          - task: AzureStaticWebApp@0
            inputs:
              app_location: $(app_location)
              output_location: $(output_location)
              azure_static_web_apps_api_token: $(deployment_token)
```

**Important**: No `cd` commands needed since app is at root!

---

## 🚨 Common Mistakes to Avoid

### ❌ **WRONG - Don't Use These Values**

```
App location: FE/application        ← WRONG! This folder doesn't exist
App location: src                   ← WRONG! Too deep, config is at root
Output location: dist               ← WRONG! Missing /application/browser

In pipeline:
- script: cd FE/application         ← WRONG! No need to cd
```

### ✅ **CORRECT - Use These Values**

```
App location: /                     ← CORRECT! Or leave empty
Output location: dist/application/browser  ← CORRECT!

In pipeline:
- script: npm ci                    ← CORRECT! Already at root
- script: npm run build             ← CORRECT! No cd needed
```

---

## 🐛 Troubleshooting

### **Build Fails: "Cannot find angular.json"**

**Problem**: Wrong app location  
**Solution**: Set app location to `/` or leave empty

### **Build Succeeds but Site is Blank**

**Problem**: Wrong output location  
**Solution**: Verify output location is `dist/application/browser`

**Test locally**:
```bash
npm run build
ls dist/application/browser/index.html  # Should exist
```

### **404 on Page Refresh**

**Problem**: Missing SPA fallback config  
**Solution**: Create `staticwebapp.config.json` in `src/`:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["*.{css,js,png,jpg,svg,ico}", "/api/*"]
  }
}
```

Then add to `angular.json` assets:
```json
{
  "glob": "staticwebapp.config.json",
  "input": "src",
  "output": "/"
}
```

### **CORS Errors**

**Problem**: Backend doesn't allow Static Web App origin  
**Solution**: Add to your .NET backend:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowStaticWebApp", builder =>
    {
        builder.WithOrigins(
            "https://sakura-frontend-dev.azurestaticapps.net",
            "http://localhost:4200"
        )
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials();
    });
});

app.UseCors("AllowStaticWebApp");
```

---

## 🎯 Environment Variations

### **Development**
```
Name: sakura-frontend-dev
Branch: dev
Build config: --configuration=api-dev
URL: https://sakura-frontend-dev.azurestaticapps.net
```

### **Staging**
```
Name: sakura-frontend-staging  
Branch: staging
Build config: --configuration=staging
URL: https://sakura-frontend-staging.azurestaticapps.net
```

### **Production**
```
Name: sakura-frontend-prod
Branch: main
Build config: --configuration=production
URL: https://sakura-frontend-prod.azurestaticapps.net
```

---

## 📋 Pre-Deployment Checklist

```
□ Azure subscription access
□ Azure DevOps access (DANFinanceBl organization)
□ Angular app builds locally (npm run build)
□ Verify build output: dist/application/browser/index.html exists
□ Azure AD app registration created
□ Backend API CORS configured
□ Environment files configured (src/environments/)
```

---

## 🔗 Quick Links

- **Azure Portal**: https://portal.azure.com
- **Azure DevOps**: https://dev.azure.com/DANFinanceBl
- **Your Repo**: https://danfinancebi.visualstudio.com/Sakura/_git/Sakura%20Frontend
- **Full Guide**: See `AZURE_STATIC_WEB_APP_DEPLOYMENT_GUIDE.md`

---

## 📞 Need Help?

1. Check full guide: `AZURE_STATIC_WEB_APP_DEPLOYMENT_GUIDE.md`
2. View pipeline logs in Azure DevOps
3. Check browser console for errors (F12)
4. Verify build output: `npm run build` locally

---

**Last Updated**: November 18, 2025  
**Valid For**: Sakura Frontend Repository Structure

