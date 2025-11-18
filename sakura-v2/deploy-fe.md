# 🚀 Azure Static Web App - Complete Deployment Configuration Guide

**Project**: Sakura Frontend  
**Technology**: Angular 20.3.0  
**Deployment Platform**: Azure Static Web Apps (Standard Plan)  
**Last Updated**: November 18, 2025

---

## 📋 Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Azure Portal Configuration - Step by Step](#azure-portal-configuration---step-by-step)
3. [Build Configuration Details](#build-configuration-details)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Environment Variables Setup](#environment-variables-setup)
6. [Custom Domain Configuration](#custom-domain-configuration)
7. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Replication Quick Reference](#replication-quick-reference)

---

## ✅ Pre-Deployment Checklist

### **1. Azure Prerequisites**
- [ ] Active Azure Subscription
- [ ] Subscription ID: `VDC000006-EMEA-ORED7-DentsuAegiseCX-NetworkNorthYou`
- [ ] Resource Group Created: `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL`
- [ ] Appropriate permissions (Contributor or Owner role)
- [ ] Azure DevOps organization access: `DANFinanceBl`

### **2. Repository Prerequisites**
- [ ] Azure DevOps Repository: `Sakura Frontend`
- [ ] Project: `Sakura`
- [ ] Branch ready for deployment: `dev`
- [ ] Repository contains Angular application in `FE/application/`
- [ ] Build successfully completes locally: `ng build`

### **3. Application Prerequisites**
- [ ] Angular CLI version: 20.3.5
- [ ] Node.js version: 18.x or higher
- [ ] Package.json is up to date
- [ ] All dependencies installed
- [ ] Build output directory confirmed: `dist/application/browser`

---

## 🎯 Azure Portal Configuration - Step by Step

### **STEP 1: Navigate to Azure Static Web Apps**

1. Go to [Azure Portal](https://portal.azure.com)
2. Click **"+ Create a resource"**
3. Search for **"Static Web App"**
4. Click **"Static Web App"**
5. Click **"Create"**

---

### **STEP 2: Basics Tab Configuration**

#### **Project Details**

##### **Subscription** ⭐ (Required)
- **Field Label**: Subscription
- **Value**: `VDC000006-EMEA-ORED7-DentsuAegiseCX-NetworkNorthYou`
- **Type**: Dropdown selection
- **Description**: The Azure subscription that will be billed for this resource
- **Why**: This is your organization's development subscription
- **Note**: Must have active subscription and appropriate permissions

##### **Resource Group** ⭐ (Required)
- **Field Label**: Resource Group
- **Value**: `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL`
- **Type**: Dropdown selection with "Create new" option
- **Description**: Logical container for Azure resources
- **Why**: Groups all Sakura development resources together
- **Best Practice**: Use existing resource group to keep related resources together
- **Alternative**: Click "Create new" if you need a separate resource group

---

#### **Hosting Region**

##### **Static Web Apps Distributes Globally**
- **Field Label**: Static Web Apps distributes your app's static assets globally
- **Info Text**: "Configure regional features in Advanced"
- **Description**: Informational text explaining global CDN distribution
- **What it means**: Your app files will be cached globally for faster access

##### **Regions** ⭐ (Required)
- **Field Label**: Regions
- **Value**: `Global`
- **Type**: Dropdown selection
- **Options Available**:
  - Global (Recommended)
  - Specific regions (East US, West Europe, etc.)
- **Description**: Where your static content will be distributed
- **Why Global**: Provides worldwide CDN distribution for best performance
- **When to use specific region**: Only if you need data residency compliance
- **Performance**: Global = Lowest latency worldwide

---

#### **Static Web App Details**

##### **Name** ⭐ (Required)
- **Field Label**: Name
- **Value**: `sakura-frontend-dev`
- **Type**: Text input
- **Character Limit**: 1-60 characters
- **Allowed Characters**: 
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Hyphens (-)
- **Restrictions**:
  - ❌ No uppercase letters
  - ❌ No underscores
  - ❌ No special characters except hyphen
  - ❌ Cannot start or end with hyphen
- **Uniqueness**: Must be globally unique across all Azure Static Web Apps
- **URL Result**: Will create `https://sakura-frontend-dev.azurestaticapps.net`
- **Naming Convention Examples**:
  - Development: `sakura-frontend-dev`
  - Staging: `sakura-frontend-staging`
  - Production: `sakura-frontend-prod`
  - Feature branch: `sakura-frontend-feature-auth`
- **Best Practice**: Include environment in name for clarity

---

#### **Hosting Plan**

##### **Plan Type** ⭐ (Required)
- **Field Label**: Plan type
- **Value**: `Standard: For general purpose production apps`
- **Type**: Radio button selection
- **Options**:

  **Option 1: Free (For hobby or personal projects)**
  - Cost: $0/month
  - Bandwidth: 100 GB/month
  - Storage: 0.5 GB
  - Custom domains: 2
  - APIs: Azure Functions (consumption plan)
  - SLA: None
  - Use case: Personal projects, demos, testing

  **Option 2: Standard (For general purpose production apps)** ⭐ SELECTED
  - Cost: ~$9/month
  - Bandwidth: 100 GB/month (then $0.20/GB)
  - Storage: 0.5 GB (then $0.15/GB)
  - Custom domains: 5
  - APIs: Azure Functions (premium features)
  - SLA: 99.95% uptime
  - Authentication: Enhanced features
  - Staging environments: Unlimited
  - Use case: Production applications
  - **Why we chose this**: 
    - Production-grade SLA
    - Multiple custom domains
    - Better authentication features
    - Unlimited staging environments for preview deployments

- **Link**: "Compare plans" (click for detailed comparison)
- **Note**: You can upgrade from Free to Standard anytime, but downgrade requires recreation

---

#### **Deployment Details**

##### **Source** ⭐ (Required)
- **Field Label**: Source
- **Type**: Radio button selection
- **Value**: `Azure DevOps` ⭐ SELECTED
- **Options**:
  - **GitHub**: For GitHub repositories
  - **Azure DevOps**: For Azure Repos ⭐ OUR CHOICE
  - **Other**: For external Git providers or manual deployment
- **Why Azure DevOps**: Your repository is hosted in Azure DevOps
- **Authentication**: Will prompt for Azure DevOps authorization
- **Permissions Needed**: Contributor access to repository

##### **Information Banner**
- **Message**: "If you can't find an organization or repository, try the Other option."
- **Icon**: Blue information icon (ℹ️)
- **Meaning**: Fallback option if dropdowns don't show your resources
- **Action**: Only use "Other" if you can't find your resources

##### **Organization** ⭐ (Required)
- **Field Label**: Organization
- **Value**: `DANFinanceBl`
- **Type**: Dropdown selection
- **Description**: Your Azure DevOps organization name
- **Prerequisites**: 
  - Must be logged into Azure DevOps
  - Must have authorized Azure to access Azure DevOps
- **If not listed**: 
  1. Check Azure DevOps permissions
  2. Try logging out and back in
  3. Use "Other" option as fallback

##### **Project** ⭐ (Required)
- **Field Label**: Project
- **Value**: `Sakura`
- **Type**: Dropdown selection
- **Dependencies**: Loads after Organization is selected
- **Description**: The Azure DevOps project containing your repository
- **Note**: Must have access to this project

##### **Warning Banner - Protected Branches**
- **Icon**: ⚠️ Orange warning triangle
- **Message**: "The project you have chosen contains one or more repositories with protected branches. These branches may contain rules to require a pull request before merging or specify a required number of approvals which could cause your resource creation to fail."
- **What it means**: 
  - Your repository has branch protection rules
  - Azure Static Web Apps will try to commit a workflow file
  - If branch is protected, the commit might fail
- **Solutions**:
  1. **Temporary**: Temporarily disable branch protection during setup
  2. **Manual**: Create the workflow file manually via PR
  3. **Alternative**: Use a different branch without protection for initial setup
  4. **Recommended**: Allow Azure Static Web Apps service principal to bypass protection
- **After Deployment**: You can keep branch protection active; only initial setup is affected

##### **Repository** ⭐ (Required)
- **Field Label**: Repository
- **Value**: `Sakura Frontend`
- **Type**: Dropdown selection
- **Dependencies**: Loads after Project is selected
- **Description**: The Azure DevOps repository containing your frontend code
- **Verification**: Ensure this is the correct repository for frontend code

##### **Branch** ⭐ (Required)
- **Field Label**: Branch
- **Value**: `dev`
- **Type**: Dropdown selection
- **Dependencies**: Loads after Repository is selected
- **Description**: The branch that will be deployed
- **Common Values**:
  - `dev` - Development environment ⭐ OUR CHOICE
  - `main` - Production environment
  - `staging` - Staging environment
  - Feature branches for testing
- **Auto-Deploy**: Any push to this branch triggers automatic deployment
- **Best Practice**: Use `dev` for development, `main` for production
- **Multiple Environments**: Create separate Static Web Apps for each environment

---

### **STEP 3: Click "Next: Deployment configuration >"**

**Button Location**: Bottom right of the page  
**Button Text**: "Next : Deployment configuration >"  
**Alternative**: Click "Deployment configuration" tab at top

---

### **STEP 4: Deployment Configuration Tab**

#### **Build Details**

##### **Informational Text**
- **Message**: "Enter values to create an Azure DevOps pipeline for build and release. You can modify the YAML file later in your Azure DevOps repository."
- **What it means**: 
  - Azure will auto-create a pipeline configuration file
  - File will be committed to your repository
  - File name: `azure-pipelines.yml` (typically in repository root or `.azure/` folder)
  - You can edit this file later for customization

##### **Build Presets** ⭐ (Required)
- **Field Label**: Build Presets
- **Value**: `Angular` ⭐ SELECTED
- **Type**: Dropdown selection with icon
- **Icon**: 🅰️ Angular logo (red shield)
- **Options Available**:
  - Angular ⭐ OUR CHOICE
  - React
  - Vue
  - Blazor
  - Next.js
  - Nuxt.js
  - Hugo
  - Gatsby
  - VuePress
  - Custom (manual configuration)
- **What it does**: 
  - Pre-configures build commands
  - Sets up Node.js environment
  - Configures Angular CLI
  - Optimizes for Angular best practices
- **Auto-configured values**:
  - Build command: `npm run build`
  - Node version: 18.x
  - Package manager: npm
  - Build tool: Angular CLI

##### **Information Banner - Build Preset Effects**
- **Icon**: ℹ️ Blue information icon
- **Message**: "These fields will reflect the app type's default project structure. Change the values to suit your app."
- **Link**: "Learn more >"
- **Learn more URL**: Documentation about build configuration
- **What it means**: 
  - Default values are suggestions
  - You can and should customize for your project structure
  - Azure's defaults assume standard project layout
  - Your project structure may differ

##### **App location** ⭐ (Required)
- **Field Label**: App location
- **Value**: `FE/application`
- **Type**: Text input
- **Default Value** (if Angular preset): `/` (root of repository)
- **Description**: The relative path from repository root to your Angular application
- **Our Project Structure**:
  ```
  Repository Root/
  ├── FE/
  │   └── application/          ← This is our app location
  │       ├── src/
  │       ├── angular.json      ← Build config is here
  │       ├── package.json      ← Dependencies are here
  │       └── tsconfig.json
  ├── BE_Main/                  ← Backend (separate)
  └── other files
  ```
- **Format Rules**:
  - Use forward slashes `/` (even on Windows)
  - Relative to repository root
  - No leading slash
  - No trailing slash
- **Common Mistakes**:
  - ❌ `/FE/application` (no leading slash)
  - ❌ `FE/application/` (no trailing slash)
  - ❌ `FE\application` (wrong slash direction)
  - ✅ `FE/application` (correct)
- **Verification**: Directory should contain `package.json` and `angular.json`
- **Examples**:
  - Root of repo: `/` or leave empty
  - Subfolder: `frontend`
  - Nested: `apps/client/web`
  - Our case: `FE/application`

##### **API location** (Optional)
- **Field Label**: API location
- **Value**: *(Leave empty)* 🚫
- **Type**: Text input
- **Default Value**: Empty
- **Description**: The relative path to your Azure Functions API (if any)
- **When to use**: 
  - ✅ If you have Azure Functions API in same repository
  - ✅ If you want API deployed with your frontend
  - ❌ NOT for separate backend services (like your .NET backend)
  - ❌ NOT for external APIs
- **Our Case**: 
  - Leave empty because backend is separate
  - Backend is .NET in different location (`BE_Main/`)
  - Backend will be deployed separately as Azure App Service
- **Example When Used**: 
  - If you had: `api/` folder with Azure Functions
  - Then enter: `api`
- **Format**: Same as App location (relative path, no leading/trailing slashes)

##### **Output location** ⭐ (Required)
- **Field Label**: Output location
- **Value**: `dist/application/browser`
- **Type**: Text input
- **Default Value** (if Angular preset): `dist/application/browser`
- **Description**: The folder where Angular build outputs compiled files
- **Relative to**: App location (not repository root)
- **Full Path Logic**: 
  ```
  Repository root  +  App location  +  Output location
      /           +  FE/application  +  dist/application/browser
  = /FE/application/dist/application/browser
  ```
- **How to verify your output location**:
  1. Navigate to `FE/application/` (your app location)
  2. Run `ng build`
  3. Check where files are created
  4. Look for `index.html` and compiled `.js` files
  5. Note the path relative to `FE/application/`
- **Our Angular.json Configuration**:
  ```json
  {
    "projects": {
      "application": {
        "architect": {
          "build": {
            "builder": "@angular/build:application"
          }
        }
      }
    }
  }
  ```
  - Project name: `application`
  - Default output: `dist/<project-name>/browser`
  - Our output: `dist/application/browser`
- **Angular Version Differences**:
  - Angular 17+: `dist/<project>/browser` (new build system)
  - Angular 16-: `dist/<project>` (old build system)
- **Common Output Locations**:
  - Angular 17+ (new builder): `dist/application/browser` ⭐ OUR CASE
  - Angular <17 (old builder): `dist/application`
  - Custom build: Check your `angular.json` `outputPath`
- **What gets deployed**: 
  - `index.html` (main entry point)
  - `main.js` (application code)
  - `polyfills.js` (browser compatibility)
  - `styles.css` (compiled styles)
  - `assets/` (images, fonts, etc.)
  - All chunk files (code splitting)
- **Common Mistakes**:
  - ❌ `dist` (too shallow, missing project name)
  - ❌ `dist/application` (missing /browser for new Angular)
  - ❌ `FE/application/dist/application/browser` (absolute, should be relative to app location)
  - ✅ `dist/application/browser` (correct for our setup)

---

### **STEP 5: Click "Review + create"**

**Button Location**: Bottom right  
**Button Text**: "Review + create"  
**Alternative Options**:
- "< Previous" - Go back to Basics tab
- "Next: Tags >" - Add Azure resource tags (optional)

---

### **STEP 6: Tags Tab** (Optional)

#### **What are Tags?**
- Key-value pairs for organizing Azure resources
- Used for billing, automation, and resource management
- Not required but recommended for production

#### **Common Tags for This Project**:

##### **Environment**
- **Name**: `Environment`
- **Value**: `Development`
- **Purpose**: Identify which environment this resource belongs to
- **Options**: Development, Staging, Production

##### **Project**
- **Name**: `Project`
- **Value**: `Sakura`
- **Purpose**: Group all Sakura-related resources

##### **CostCenter**
- **Name**: `CostCenter`
- **Value**: *(Your organization's cost center code)*
- **Purpose**: For billing and cost allocation

##### **Owner**
- **Name**: `Owner`
- **Value**: *(Your team or email)*
- **Purpose**: Know who to contact about this resource

##### **ManagedBy**
- **Name**: `ManagedBy`
- **Value**: `AzureDevOps`
- **Purpose**: Indicate automation tool

#### **Tag Format**:
```
Name: Environment     Value: Development
Name: Project         Value: Sakura
Name: CostCenter      Value: YOUR-COST-CENTER
Name: Owner           Value: YOUR-TEAM
Name: ManagedBy       Value: AzureDevOps
```

#### **After Tags**:
Click "Next: Review + create"

---

### **STEP 7: Review + Create Tab**

#### **Validation**
- **Status Banner**: 
  - ✅ "Validation passed" (green checkmark)
  - ❌ "Validation failed" (red X with error details)
- **If Validation Failed**: 
  1. Read error message carefully
  2. Click "< Previous" to go back
  3. Fix the indicated issues
  4. Return to "Review + create"

#### **Review All Settings**

##### **Basics Section**
- Subscription: `VDC000006-EMEA-ORED7-DentsuAegiseCX-NetworkNorthYou`
- Resource Group: `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL`
- Name: `sakura-frontend-dev`
- Region: `Global`
- Hosting plan: `Standard`
- Source: `Azure DevOps`
- Organization: `DANFinanceBl`
- Project: `Sakura`
- Repository: `Sakura Frontend`
- Branch: `dev`

##### **Deployment Configuration Section**
- Build preset: `Angular`
- App location: `FE/application`
- Api location: *(empty)*
- Output location: `dist/application/browser`

##### **Tags Section** (if added)
- Your configured tags displayed

#### **Cost Summary** (Bottom right)
- Shows estimated monthly cost
- Standard plan: ~$9/month base + usage
- Click "Pricing calculator" for detailed breakdown

#### **Terms and Conditions**
- Azure Static Web Apps terms
- Review if needed

---

### **STEP 8: Click "Create"**

**Button Location**: Bottom left  
**Button Text**: "Create" (blue button)  
**Alternative**: "< Previous" to go back and change settings

#### **What Happens After Clicking Create**:

1. **Deployment Begins**:
   - Creates Azure Static Web App resource
   - Shows "Deployment is in progress" screen
   - Displays progress indicators

2. **Resource Creation** (1-2 minutes):
   - Static Web App instance created
   - CDN endpoints configured
   - SSL certificate provisioned
   - Assigned URL: `https://sakura-frontend-dev.azurestaticapps.net`

3. **Azure DevOps Integration** (2-3 minutes):
   - Azure Static Web Apps service connects to Azure DevOps
   - Creates Azure Pipeline definition
   - Adds pipeline YAML file to repository
   - File location: Repository root or `.azure/` folder
   - File name: `azure-pipelines.yml`
   - Commits to your branch (`dev`)

4. **First Build Triggered Automatically**:
   - Pipeline runs immediately after setup
   - Builds your Angular application
   - Deploys to Azure Static Web App
   - Build time: ~5-10 minutes (first build is slower)

5. **Deployment Complete** (Total: ~10-15 minutes):
   - Status: "Your deployment is complete"
   - Green checkmark displayed
   - Button: "Go to resource"

---

### **STEP 9: Post-Creation Actions**

#### **Deployment Complete Screen**

##### **Information Displayed**:
- ✅ Deployment name: `Microsoft.StaticWebApp-{timestamp}`
- ✅ Subscription: Your subscription
- ✅ Resource group: Your resource group

##### **Deployment Details**:
Click "Deployment details" to expand:
- Resource name: `sakura-frontend-dev`
- Resource type: `Microsoft.Web/staticSites`
- Status: `Created`
- Timestamp: When it was created

#### **Click "Go to resource"**

---

### **STEP 10: Azure Static Web App Overview Page**

You're now on your Static Web App's management page!

#### **Essentials Section** (Top of page)

##### **Resource Information**:
- **Resource group**: `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL`
  - Click to view all resources in this group
- **Status**: `Ready` (green indicator)
  - Possible statuses: Ready, Deploying, Failed
- **Location**: `Global`
- **Subscription**: Your subscription name
- **Subscription ID**: The GUID
- **Tags**: Your configured tags (click "Edit" to modify)

##### **URLs**:
- **URL**: `https://sakura-frontend-dev.azurestaticapps.net`
  - Click to open your deployed site
  - This is your main production URL
  - ⚠️ First visit might take a moment to wake up

##### **Deployment**:
- **Source**: `Azure DevOps`
- **Organization/Account**: `DANFinanceBl`
- **Repository**: `Sakura Frontend`
- **Branch**: `dev`

#### **Left Menu - Configuration Options**

We'll configure these in the next section.

---

## 🔧 Build Configuration Details

### **Auto-Generated Azure Pipeline File**

After deployment, check your repository for the new pipeline file.

#### **File Location**:
- **Path**: `azure-pipelines.yml` (repository root)
- **Alternative**: `.azure/azure-pipelines.yml`
- **How to find**: Look for recent commit by Azure Static Web Apps

#### **Default Pipeline Content** (Angular):

```yaml
# Azure Static Web Apps - Pipeline Configuration
# Auto-generated for: sakura-frontend-dev

trigger:
  branches:
    include:
      - dev

pool:
  vmImage: 'ubuntu-latest'

variables:
  app_location: 'FE/application'
  api_location: ''
  output_location: 'dist/application/browser'

stages:
  - stage: Build
    jobs:
      - job: BuildAndDeploy
        displayName: 'Build and Deploy Static Web App'
        steps:
          - checkout: self
            submodules: true

          - task: AzureStaticWebApp@0
            inputs:
              app_location: $(app_location)
              api_location: $(api_location)
              output_location: $(output_location)
              azure_static_web_apps_api_token: $(deployment_token)
```

#### **Understanding the Pipeline**:

##### **Trigger**:
- Runs automatically when code pushed to `dev` branch
- Add more branches if needed

##### **Pool**:
- Uses Ubuntu Linux build agent
- Can change to Windows if needed: `vmImage: 'windows-latest'`

##### **Variables**:
- `app_location`: Where your Angular app is
- `api_location`: API folder (empty for us)
- `output_location`: Build output directory

##### **AzureStaticWebApp Task**:
- Official Azure Static Web Apps deployment task
- Handles build and deployment
- Uses deployment token (stored in pipeline variable)

#### **Customizing the Pipeline**:

##### **Specify Node.js Version**:
```yaml
steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'
    displayName: 'Install Node.js'
```

##### **Custom Build Command**:
```yaml
steps:
  - script: |
      cd FE/application
      npm ci
      npm run build -- --configuration production
    displayName: 'Build Angular App'
```

##### **Environment-Specific Builds**:
```yaml
steps:
  - script: |
      cd FE/application
      npm ci
      npm run build -- --configuration api-dev
    displayName: 'Build with API-Dev Config'
```

##### **Run Tests Before Deploy**:
```yaml
steps:
  - script: |
      cd FE/application
      npm ci
      npm run test -- --watch=false --browsers=ChromeHeadless
    displayName: 'Run Unit Tests'
```

##### **Add Environment Variables**:
```yaml
steps:
  - script: |
      echo "Building with environment: Development"
      cd FE/application
      npm ci
      npm run build
    env:
      NODE_ENV: development
      API_URL: https://your-api.azurewebsites.net
    displayName: 'Build with Environment Variables'
```

---

### **Build Process Explained**

#### **What Happens During Build**:

1. **Checkout Code** (30 seconds):
   - Clones repository from Azure DevOps
   - Checks out specified branch (`dev`)
   - Downloads all files

2. **Setup Environment** (1 minute):
   - Installs Node.js 18.x
   - Sets up npm
   - Configures build environment

3. **Install Dependencies** (2-3 minutes):
   - Runs `npm install` or `npm ci`
   - Downloads all packages from package.json
   - ~50 packages for your Angular app
   - Creates node_modules folder

4. **Build Application** (2-4 minutes):
   - Runs `ng build` (via `npm run build`)
   - Compiles TypeScript to JavaScript
   - Bundles and optimizes code
   - Processes SCSS/CSS
   - Optimizes images and assets
   - Creates output in `dist/application/browser/`

5. **Deploy to Azure** (1-2 minutes):
   - Uploads built files to Azure
   - Distributes to global CDN
   - Invalidates cache
   - Updates SSL certificates

6. **Total Time**: ~8-12 minutes per deployment

#### **Build Output Files**:

After build, `dist/application/browser/` contains:

```
dist/application/browser/
├── index.html              # Main HTML entry point
├── main.js                 # Your application code (bundled)
├── main.js.map             # Source map for debugging
├── polyfills.js            # Browser compatibility code
├── polyfills.js.map
├── styles.css              # Compiled global styles
├── styles.css.map
├── chunk-*.js              # Code-split chunks (lazy loading)
├── *.component.css.map     # Component style maps
├── favicon.ico             # Site icon
└── media/                  # Font files, icons
    ├── primeicons.woff
    ├── primeicons.woff2
    └── ...
```

---

## ⚙️ Post-Deployment Configuration

Now that your Static Web App is deployed, configure it properly!

### **1. Application Settings (Environment Variables)**

#### **Navigate to Configuration**:
1. Go to your Static Web App in Azure Portal
2. Left menu → **"Configuration"**
3. Click **"Application settings"** tab

#### **What are Application Settings?**:
- Environment variables for your application
- Available at build time and runtime
- Secure storage for sensitive data
- Different values per environment

#### **Add Application Settings**:

##### **How to Add**:
1. Click **"+ Add"** button
2. Enter **Name** (variable name)
3. Enter **Value** (variable value)
4. Click **"OK"**
5. Click **"Save"** at top (don't forget!)

##### **Settings to Add for Sakura Frontend**:

###### **MSAL Authentication Settings**:

```
Name: MSAL_CLIENT_ID
Value: your-azure-ad-client-id
Description: Azure AD Application (client) ID for authentication
```

```
Name: MSAL_AUTHORITY
Value: https://login.microsoftonline.com/your-tenant-id
Description: Azure AD authority URL for authentication
```

```
Name: MSAL_REDIRECT_URI
Value: https://sakura-frontend-dev.azurestaticapps.net
Description: Redirect URI after authentication (your Static Web App URL)
```

```
Name: MSAL_POST_LOGOUT_REDIRECT_URI
Value: https://sakura-frontend-dev.azurestaticapps.net
Description: Where to redirect after logout
```

###### **Backend API Settings**:

```
Name: API_BASE_URL
Value: https://your-backend.azurewebsites.net/api
Description: Base URL for your Sakura backend API
```

```
Name: API_TIMEOUT
Value: 30000
Description: API request timeout in milliseconds
```

###### **Environment Settings**:

```
Name: ENVIRONMENT
Value: development
Description: Current environment (development/staging/production)
```

```
Name: ENABLE_DEBUG
Value: true
Description: Enable debug logging
```

###### **Feature Flags** (Optional):

```
Name: FEATURE_WSO_CONSOLE
Value: true
Description: Enable WSO Console features
```

```
Name: FEATURE_ADVANCED_FILTERS
Value: true
Description: Enable advanced filtering options
```

#### **Using Application Settings in Angular**:

These settings need to be accessed in your Angular app. There are two approaches:

##### **Approach 1: Build-Time Variables** (Recommended):
- Use Angular environment files
- Replace values during build
- More secure, values baked into build

**In your pipeline, before build**:
```yaml
- script: |
    cd FE/application/src/environments
    sed -i 's/MSAL_CLIENT_ID_PLACEHOLDER/$(MSAL_CLIENT_ID)/g' environment.ts
  displayName: 'Replace Environment Variables'
```

##### **Approach 2: Runtime Configuration**:
- Load from API endpoint
- Store in Azure App Configuration
- Fetch at application startup

---

### **2. Custom Domains**

#### **Why Custom Domain?**:
- Professional URL (e.g., `sakura.yourcompany.com`)
- Better branding
- SSL certificate included free

#### **Add Custom Domain**:

1. **Navigate**:
   - Your Static Web App → Left menu → **"Custom domains"**

2. **Click "+ Add"**:
   - Choose **"Custom domain on Azure DNS"** or **"Custom domain on other DNS"**

3. **Enter Domain**:
   - **Domain name**: `sakura.yourcompany.com`
   - **Subdomain**: (if needed)

4. **DNS Configuration**:
   
   **For Azure DNS**:
   - Automatically configured
   
   **For Other DNS**:
   - Add CNAME record:
     ```
     Type: CNAME
     Name: sakura
     Value: sakura-frontend-dev.azurestaticapps.net
     TTL: 3600
     ```
   
   **For Root Domain** (example.com without subdomain):
   - Add ALIAS or ANAME record (not all DNS providers support this)
   - Or use Azure DNS

5. **Validation**:
   - Azure validates domain ownership
   - Can take 5-60 minutes
   - Status shows in portal

6. **SSL Certificate**:
   - Automatically provisioned
   - Free managed certificate
   - Auto-renewal
   - Can take additional 10-30 minutes

#### **Multiple Domains**:
- Standard plan: Up to 5 custom domains
- Can have:
  - `sakura.yourcompany.com` (production)
  - `sakura-dev.yourcompany.com` (development)
  - `www.sakura.yourcompany.com` (www variant)

---

### **3. Authentication / Authorization**

#### **Built-in Authentication**:

Azure Static Web Apps includes free authentication providers!

#### **Navigate**:
- Your Static Web App → Left menu → **"Authentication"**

#### **Supported Providers**:
- ✅ Azure Active Directory (Microsoft Entra ID)
- ✅ GitHub
- ✅ Twitter/X
- ✅ Facebook  
- ✅ Google
- ✅ Apple

#### **Configure Azure AD** (For Sakura):

Since you're already using MSAL, you can use built-in auth OR continue with MSAL.

##### **Option 1: Use Built-in Azure AD Auth**:

1. Click **"Add provider"**
2. Select **"Microsoft"**
3. Enter:
   - **App registration name**: `Sakura Frontend Auth`
   - **Client ID**: Your Azure AD app client ID
   - **Client Secret**: From Azure AD app registration
   - **Issuer URL**: `https://login.microsoftonline.com/{tenant-id}/v2.0`
4. **Allowed external redirect URLs**: Add your application routes
5. Click **"Save"**

**Benefits**:
- No code needed
- Automatic token management
- Built-in login endpoints: `/.auth/login/aad`

##### **Option 2: Continue Using MSAL** (Current Setup):

Keep using your existing MSAL configuration:
- More control over auth flow
- Already implemented in your code
- No changes needed

---

### **4. API Management**

#### **If You Add Azure Functions API Later**:

1. **Navigate**: 
   - Your Static Web App → Left menu → **"APIs"**

2. **Link Azure Functions**:
   - Click **"Link to a function"**
   - Select your Functions app
   - Automatically proxied under `/api`

3. **Benefits**:
   - Same domain for frontend and API
   - No CORS issues
   - Shared authentication

#### **For External API** (Your .NET Backend):

Configure CORS on your backend to allow requests from Static Web App.

**In your .NET Backend**:
```csharp
// Program.cs or Startup.cs
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowStaticWebApp",
        builder =>
        {
            builder.WithOrigins(
                "https://sakura-frontend-dev.azurestaticapps.net",
                "http://localhost:4200" // For local development
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
        });
});

app.UseCors("AllowStaticWebApp");
```

---

### **5. Environments**

#### **Preview Environments**:

Azure Static Web Apps automatically creates preview environments for:
- Pull requests
- Feature branches

#### **How it Works**:

1. Create pull request in Azure DevOps
2. Azure automatically:
   - Builds the PR branch
   - Deploys to temporary URL
   - Comments PR with preview link
3. URL format: `https://sakura-frontend-dev-{pr-number}.azurestaticapps.net`

#### **Configure**:

1. **Navigate**:
   - Your Static Web App → Left menu → **"Environments"**

2. **View All Environments**:
   - Production (main branch): `sakura-frontend-dev.azurestaticapps.net`
   - Preview environments listed below

3. **Delete Old Previews**:
   - Select environment
   - Click "Delete"
   - Cleans up after PR merged

#### **Benefits**:
- Test changes before merging
- Share with stakeholders
- Isolated testing environment
- No infrastructure setup needed

---

### **6. Monitoring and Diagnostics**

#### **Application Insights Integration**:

1. **Create Application Insights**:
   - Azure Portal → Create Application Insights resource
   - Same resource group: `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL`
   - Name: `sakura-frontend-insights`

2. **Link to Static Web App**:
   - Your Static Web App → Left menu → **"Application Insights"**
   - Click **"Yes"** to enable
   - Select your Application Insights resource
   - Click **"Save"**

3. **What You Get**:
   - Page view tracking
   - Performance metrics
   - Error logging
   - User analytics
   - Custom events

#### **View Logs**:

1. **Navigate**:
   - Your Static Web App → Left menu → **"Logs"**

2. **Build Logs**:
   - See all deployments
   - Build success/failure
   - Error messages

3. **Application Logs** (after Application Insights enabled):
   - Real-time user activity
   - Errors and exceptions
   - Performance data

---

### **7. Networking**

#### **Private Endpoint** (Optional - Advanced):

For enhanced security, restrict access to Static Web App.

1. **Navigate**:
   - Your Static Web App → Left menu → **"Networking"**

2. **Configure**:
   - **Public access**: Enable/Disable
   - **Private endpoints**: Add if using VNet

#### **IP Restrictions**:

Not directly supported in Static Web Apps, but you can:
- Use Azure Front Door with WAF
- Add authentication
- Use API Management as gateway

---

## 🔑 Environment Variables Setup

### **Understanding Environment Variables in Static Web Apps**

#### **Two Types of Variables**:

1. **Build-Time Variables**:
   - Available during `ng build`
   - Baked into JavaScript files
   - Used by Angular environment files
   - Set in pipeline or Azure configuration

2. **Runtime Variables**:
   - Available after deployment
   - Not directly accessible in static sites
   - Need backend API or configuration service

### **Recommended Approach for Sakura**:

Use Angular environment files with build-time replacement.

#### **Your Current Environment Files**:

```
FE/application/src/environments/
├── environment.ts                    # Default (development)
├── environment.api-dev.ts           # API Development
└── environment.production.ts        # Production
```

#### **Strategy**:

##### **1. Define Variables in Angular Environment Files**:

**environment.api-dev.ts**:
```typescript
export const environment = {
  production: false,
  apiUrl: 'https://your-backend-dev.azurewebsites.net/api',
  msalConfig: {
    clientId: 'your-client-id',
    authority: 'https://login.microsoftonline.com/your-tenant-id',
    redirectUri: 'https://sakura-frontend-dev.azurestaticapps.net'
  },
  enableDebug: true,
  features: {
    wsoConsole: true,
    advancedFilters: true
  }
};
```

##### **2. Build with Specific Environment**:

In your pipeline:
```yaml
- script: |
    cd FE/application
    npm ci
    npm run build -- --configuration=api-dev
  displayName: 'Build with API-Dev Configuration'
```

##### **3. Or Use Variable Replacement**:

**Create template file**: `environment.api-dev.template.ts`
```typescript
export const environment = {
  production: false,
  apiUrl: '#{API_URL}#',
  msalConfig: {
    clientId: '#{MSAL_CLIENT_ID}#',
    authority: '#{MSAL_AUTHORITY}#',
    redirectUri: '#{REDIRECT_URI}#'
  }
};
```

**In pipeline, replace tokens**:
```yaml
- task: replacetokens@5
  inputs:
    rootDirectory: 'FE/application/src/environments'
    targetFiles: '**/*.template.ts'
    encoding: 'auto'
    tokenPattern: 'custom'
    tokenPrefix: '#{'
    tokenSuffix: '}#'
```

##### **4. Store Sensitive Values Securely**:

**In Azure DevOps**:
- Go to Pipeline → Library → Variable Groups
- Create variable group: `Sakura-Frontend-Config`
- Add variables:
  - `MSAL_CLIENT_ID`: `your-client-id`
  - `MSAL_AUTHORITY`: `https://login.microsoftonline.com/...`
  - `API_URL`: `https://your-backend.azurewebsites.net/api`
- Mark sensitive values as **"Secret"** 🔒

**Reference in pipeline**:
```yaml
variables:
  - group: Sakura-Frontend-Config

steps:
  - script: |
      echo "Using API URL: $(API_URL)"
      # Variables automatically available
    displayName: 'Build Configuration'
```

---

## 🌐 Custom Domain Configuration

### **Complete Custom Domain Setup**

#### **Prerequisites**:
- Access to your DNS provider
- Domain purchased (e.g., `yourcompany.com`)
- Subdomain for app (e.g., `sakura.yourcompany.com`)

#### **Step 1: Prepare DNS**

##### **If Using Azure DNS**:

1. **Create DNS Zone** (if not exists):
   - Azure Portal → DNS zones → Create
   - Name: `yourcompany.com`
   - Resource group: Same as Static Web App

2. **Update Domain Registrar**:
   - Point nameservers to Azure DNS
   - Azure shows nameservers in DNS zone overview

##### **If Using External DNS** (GoDaddy, Namecheap, etc.):
- Have login credentials ready
- Know how to add DNS records

#### **Step 2: Add Custom Domain in Azure**

1. **Navigate**:
   - Your Static Web App
   - Left menu → **"Custom domains"**
   - Click **"+ Add"**

2. **Choose Domain Type**:
   - Select **"Custom domain on other DNS"** (if external DNS)
   - Select **"Custom domain on Azure DNS"** (if using Azure DNS)

3. **Enter Domain Name**:
   - **Domain name**: `sakura.yourcompany.com`
   - Click **"Next"**

4. **Domain Validation**:
   Azure shows required DNS records:

   **CNAME Record** (for subdomain):
   ```
   Type: CNAME
   Name: sakura
   Value: sakura-frontend-dev.azurestaticapps.net
   TTL: 3600 (or 1 hour)
   ```

   **TXT Record** (for validation):
   ```
   Type: TXT
   Name: _dnsauth.sakura
   Value: {validation-code-from-azure}
   TTL: 3600
   ```

#### **Step 3: Add DNS Records**

##### **Example: GoDaddy**:
1. Login to GoDaddy
2. My Products → Domain → DNS Management
3. Click "Add" for new record
4. Add CNAME:
   - Type: CNAME
   - Name: sakura
   - Value: sakura-frontend-dev.azurestaticapps.net
   - TTL: 1 Hour
5. Add TXT:
   - Type: TXT
   - Name: _dnsauth.sakura
   - Value: {paste from Azure}
   - TTL: 1 Hour
6. Save

##### **Example: Cloudflare**:
1. Login to Cloudflare
2. Select domain
3. DNS → Add record
4. Add CNAME:
   - Type: CNAME
   - Name: sakura
   - Target: sakura-frontend-dev.azurestaticapps.net
   - Proxy status: DNS only (gray cloud) ⚠️ Important!
   - TTL: Auto
5. Add TXT:
   - Type: TXT
   - Name: _dnsauth.sakura
   - Content: {paste from Azure}
   - TTL: Auto
6. Save

##### **Example: Azure DNS**:
1. Azure Portal → DNS Zones → yourcompany.com
2. Click "+ Record set"
3. Add CNAME:
   - Name: sakura
   - Type: CNAME
   - TTL: 1
   - Alias record set: No
   - CNAME: sakura-frontend-dev.azurestaticapps.net
4. Save
5. Repeat for TXT record

#### **Step 4: Wait for DNS Propagation**

- **Time**: 5 minutes to 48 hours (usually 15-30 minutes)
- **Check propagation**: Use https://dnschecker.org
- Enter: `sakura.yourcompany.com`
- Look for CNAME pointing to your Static Web App

#### **Step 5: Validate in Azure**

1. Return to Azure Portal
2. Your Static Web App → Custom domains
3. Status should show:
   - ⏳ "Validating..." → Wait
   - ✅ "Validated" → Success!
   - ❌ "Validation failed" → Check DNS records

4. **If Validated**:
   - Click "Add"
   - Domain is now active

#### **Step 6: SSL Certificate**

After validation:

1. **Automatic Provisioning**:
   - Azure automatically requests SSL certificate
   - Uses Let's Encrypt (free)
   - Status: "Provisioning certificate..."

2. **Wait Time**: 10-60 minutes

3. **Status Check**:
   - Custom domains page shows certificate status
   - ✅ "Ready" = SSL active

4. **Test**:
   - Visit `https://sakura.yourcompany.com`
   - Check for 🔒 lock icon in browser
   - Certificate is valid

#### **Step 7: Update Application Configuration**

Update redirect URIs in your authentication:

1. **Azure AD App Registration**:
   - Azure Portal → Azure Active Directory
   - App registrations → Your app
   - Authentication → Redirect URIs
   - Add: `https://sakura.yourcompany.com`
   - Save

2. **Application Settings**:
   - Static Web App → Configuration
   - Update `MSAL_REDIRECT_URI`: `https://sakura.yourcompany.com`
   - Save

3. **Backend CORS**:
   - Add custom domain to allowed origins
   - Update backend configuration

#### **Step 8: Set Primary Domain** (Optional)

1. Navigate to Custom domains
2. Select your custom domain
3. Click "Set as primary"
4. Redirects default Azure URL to custom domain

---

### **Custom Domain Troubleshooting**

#### **Domain Validation Fails**:

**Check DNS Records**:
```bash
nslookup -type=CNAME sakura.yourcompany.com
nslookup -type=TXT _dnsauth.sakura.yourcompany.com
```

**Common Issues**:
- ❌ Wrong CNAME value (check for typos)
- ❌ Using A record instead of CNAME
- ❌ Cloudflare proxy enabled (must be DNS only)
- ❌ DNS not propagated yet (wait longer)
- ❌ TTL too high (reduce to 300-600 seconds)

#### **SSL Certificate Fails**:

**Common Issues**:
- ❌ DNS not fully propagated
- ❌ Firewall blocking Let's Encrypt validation
- ❌ CAA DNS record restricting certificate authorities
- ❌ Rate limit (too many cert requests)

**Solution**:
- Wait 30-60 minutes
- Try deleting and re-adding domain
- Check DNS CAA records (should allow Let's Encrypt)

---

## 🔄 CI/CD Pipeline Configuration

### **Understanding Your Deployment Pipeline**

#### **Pipeline Location**:
- **File**: `azure-pipelines.yml` (in repository root)
- **Created by**: Azure Static Web Apps during setup
- **Triggered by**: Commits to `dev` branch

#### **Pipeline Stages**:

1. **Trigger**: Commit pushed to branch
2. **Checkout**: Clone repository
3. **Setup**: Install Node.js
4. **Install**: Run `npm install`
5. **Build**: Run `ng build`
6. **Deploy**: Upload to Azure
7. **Complete**: Site updated

---

### **Advanced Pipeline Configuration**

#### **Full Custom Pipeline Example**:

```yaml
# Azure Static Web Apps Deployment Pipeline
# Project: Sakura Frontend
# Environment: Development

trigger:
  branches:
    include:
      - dev
      - main
  paths:
    include:
      - FE/application/**
    exclude:
      - '**/*.md'
      - '**/*.png'

pr:
  branches:
    include:
      - dev
      - main
  paths:
    include:
      - FE/application/**

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: Sakura-Frontend-Config
  - name: app_location
    value: 'FE/application'
  - name: output_location
    value: 'dist/application/browser'
  - name: node_version
    value: '18.x'

stages:
  - stage: Build
    displayName: 'Build and Deploy'
    jobs:
      - job: BuildAndDeploy
        displayName: 'Build Angular App and Deploy'
        steps:
          # Checkout code
          - checkout: self
            displayName: 'Checkout Repository'
            submodules: true
            persistCredentials: true

          # Install Node.js
          - task: NodeTool@0
            displayName: 'Install Node.js $(node_version)'
            inputs:
              versionSpec: $(node_version)

          # Install dependencies
          - script: |
              cd $(app_location)
              npm ci
            displayName: 'Install Dependencies'

          # Run linter
          - script: |
              cd $(app_location)
              npm run lint
            displayName: 'Run ESLint'
            continueOnError: true

          # Run tests
          - script: |
              cd $(app_location)
              npm run test -- --watch=false --code-coverage --browsers=ChromeHeadless
            displayName: 'Run Unit Tests'
            continueOnError: true

          # Build application
          - script: |
              cd $(app_location)
              npm run build -- --configuration=api-dev
            displayName: 'Build Angular Application'

          # Display build output
          - script: |
              echo "Build Output:"
              ls -la $(app_location)/$(output_location)
            displayName: 'Verify Build Output'

          # Deploy to Azure Static Web Apps
          - task: AzureStaticWebApp@0
            displayName: 'Deploy to Azure Static Web Apps'
            inputs:
              app_location: $(app_location)
              output_location: $(output_location)
              azure_static_web_apps_api_token: $(deployment_token)
              skip_app_build: true  # We already built in previous step

          # Success notification
          - script: |
              echo "✅ Deployment Complete!"
              echo "🌐 URL: https://sakura-frontend-dev.azurestaticapps.net"
            displayName: 'Deployment Success'
```

---

### **Pipeline Features Explained**:

#### **Trigger Configuration**:

```yaml
trigger:
  branches:
    include:
      - dev
      - main
  paths:
    include:
      - FE/application/**
    exclude:
      - '**/*.md'
```

**What it does**:
- Only triggers when frontend files change
- Ignores documentation updates
- Runs for `dev` and `main` branches

#### **Pull Request Builds**:

```yaml
pr:
  branches:
    include:
      - dev
      - main
```

**What it does**:
- Builds PRs automatically
- Creates preview environments
- Validates changes before merge

#### **Variable Groups**:

```yaml
variables:
  - group: Sakura-Frontend-Config
```

**Benefits**:
- Centralized configuration
- Secure secret storage
- Reusable across pipelines

#### **Skip App Build**:

```yaml
skip_app_build: true
```

**Use when**:
- You manually build in a previous step
- Want more control over build process
- Need custom build commands

---

### **Environment-Specific Pipelines**

#### **Strategy**: Different pipelines for each environment

##### **Development Pipeline** (`dev` branch):

```yaml
trigger:
  branches:
    include:
      - dev

variables:
  - group: Sakura-Frontend-Dev-Config

steps:
  - script: npm run build -- --configuration=api-dev
```

##### **Production Pipeline** (`main` branch):

```yaml
trigger:
  branches:
    include:
      - main

variables:
  - group: Sakura-Frontend-Prod-Config

steps:
  - script: npm run build -- --configuration=production
    
  # Additional steps: smoke tests, notifications, etc.
```

---

### **Advanced Features**:

#### **Multi-Stage Approval**:

```yaml
stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - script: npm run build

  - stage: Deploy
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployJob
        environment: 'Production'  # Requires manual approval
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureStaticWebApp@0
```

#### **Rollback Capability**:

```yaml
- script: |
    # Store current deployment ID
    echo "##vso[task.setvariable variable=previousDeployment]$(currentDeployment)"
  displayName: 'Save Current Deployment'

# If deployment fails, rollback
- script: |
    echo "Rolling back to: $(previousDeployment)"
  condition: failed()
  displayName: 'Rollback on Failure'
```

#### **Slack Notifications**:

```yaml
- task: SlackNotification@1
  condition: always()
  inputs:
    SlackConnection: 'YourSlackConnection'
    Message: |
      Build $(Build.BuildNumber): $(Agent.JobStatus)
      Branch: $(Build.SourceBranch)
      URL: https://sakura-frontend-dev.azurestaticapps.net
```

---

## 🔍 Troubleshooting Guide

### **Common Issues and Solutions**

#### **Issue 1: Build Fails - "npm install" Error**

**Symptoms**:
- Pipeline fails at dependency installation
- Error: `ERESOLVE unable to resolve dependency tree`

**Solutions**:

1. **Use `npm ci` instead of `npm install`**:
   ```yaml
   - script: npm ci
   ```
   - More reliable for CI/CD
   - Uses exact versions from package-lock.json

2. **Update package-lock.json**:
   ```bash
   cd FE/application
   npm install
   git add package-lock.json
   git commit -m "Update package-lock.json"
   ```

3. **Clear npm cache** (in pipeline):
   ```yaml
   - script: |
       npm cache clean --force
       npm ci
   ```

---

#### **Issue 2: Build Fails - TypeScript Errors**

**Symptoms**:
- Build fails during compilation
- TypeScript errors in console

**Solutions**:

1. **Check locally first**:
   ```bash
   cd FE/application
   npm run build
   ```
   Fix errors locally before pushing

2. **Verify TypeScript version**:
   - Check package.json
   - Ensure compatible with Angular version

3. **Strict mode issues**:
   - Temporarily disable in tsconfig.json:
   ```json
   {
     "compilerOptions": {
       "strict": false
     }
   }
   ```
   - Fix errors properly later

---

#### **Issue 3: Build Succeeds but App Doesn't Load**

**Symptoms**:
- Build completes successfully
- Deployed site shows blank page or errors
- Browser console shows errors

**Debugging Steps**:

1. **Check browser console**:
   - Open Dev Tools (F12)
   - Look for JavaScript errors
   - Check Network tab for failed requests

2. **Verify output location**:
   - Ensure files deployed to correct path
   - Check Static Web App logs

3. **Check base href**:
   - In `index.html`, verify: `<base href="/">`

4. **Test build locally**:
   ```bash
   cd FE/application
   npm run build
   cd dist/application/browser
   npx http-server -p 8080
   ```
   - Open http://localhost:8080
   - See if same errors occur

5. **Environment variables**:
   - Check if required variables are set
   - Verify MSAL configuration

---

#### **Issue 4: 404 Errors on Refresh**

**Symptoms**:
- Direct URL access works
- Refresh gives 404 error
- Routes don't work properly

**Solution**:

Create `staticwebapp.config.json` in `FE/application/src/`:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["*.{css,scss,js,png,jpg,gif,svg,ico,woff,woff2,ttf,eot}", "/api/*"]
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["authenticated"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html",
      "statusCode": 200
    }
  }
}
```

**Update angular.json** to include config file:

```json
{
  "architect": {
    "build": {
      "options": {
        "assets": [
          {
            "glob": "**/*",
            "input": "public"
          },
          {
            "glob": "staticwebapp.config.json",
            "input": "src",
            "output": "/"
          }
        ]
      }
    }
  }
}
```

---

#### **Issue 5: CORS Errors**

**Symptoms**:
- API calls fail
- Browser console: "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solutions**:

1. **Configure backend CORS** (in your .NET API):
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
   ```

2. **Verify backend CORS enabled**:
   ```csharp
   app.UseCors("AllowStaticWebApp");
   ```

3. **Check URL exact match**:
   - CORS requires exact URL match
   - Include/exclude trailing slash consistently
   - Check HTTP vs HTTPS

---

#### **Issue 6: Authentication Not Working**

**Symptoms**:
- Login fails
- Redirect loops
- Token errors

**Solutions**:

1. **Verify Azure AD App Registration**:
   - Redirect URI includes Static Web App URL
   - Implicit grant enabled (if using implicit flow)
   - API permissions granted

2. **Check MSAL configuration**:
   ```typescript
   // msal.config.ts
   export const msalConfig = {
     auth: {
       clientId: 'correct-client-id',
       authority: 'https://login.microsoftonline.com/correct-tenant-id',
       redirectUri: 'https://sakura-frontend-dev.azurestaticapps.net',
       postLogoutRedirectUri: 'https://sakura-frontend-dev.azurestaticapps.net'
     }
   };
   ```

3. **Browser storage**:
   - Clear cookies and local storage
   - Try incognito mode

4. **Token expiration**:
   - Implement token refresh
   - Check token validity

---

#### **Issue 7: Slow Build Times**

**Symptoms**:
- Build takes > 10 minutes
- Deployment is very slow

**Solutions**:

1. **Use npm ci instead of npm install**:
   ```yaml
   - script: npm ci  # Faster than npm install
   ```

2. **Cache node_modules**:
   ```yaml
   - task: Cache@2
     inputs:
       key: 'npm | "$(Agent.OS)" | $(app_location)/package-lock.json'
       path: $(app_location)/node_modules
     displayName: 'Cache npm packages'
   ```

3. **Optimize Angular build**:
   - Enable build cache
   - Reduce bundle size
   - Check for large dependencies

4. **Parallel builds**:
   ```yaml
   - script: npm run build -- --max-workers=4
   ```

---

#### **Issue 8: Environment Variables Not Working**

**Symptoms**:
- Variables undefined in application
- Features not working correctly

**Solutions**:

1. **Verify variable names**:
   - Check exact spelling
   - Case-sensitive

2. **Check when variables are accessed**:
   - Build-time: Must be in environment files
   - Runtime: Need configuration service

3. **Verify replacement**:
   - Check built files
   - Search for placeholder values

4. **Use Angular environments properly**:
   ```typescript
   // environment.api-dev.ts
   export const environment = {
     apiUrl: 'your-value-here'  // Hard-coded or replaced at build
   };
   ```

---

## 📚 Replication Quick Reference

### **🚀 Quick Start: Deploy New Environment**

**Total Time**: ~20 minutes

#### **Step 1: Azure Portal (5 min)**

1. Go to https://portal.azure.com
2. Create a resource → Static Web App
3. Fill in:
   - Name: `sakura-frontend-{env}`
   - Resource Group: Your resource group
   - Region: `Global`
   - Plan: `Standard`
   - Source: `Azure DevOps`
   - Organization: `DANFinanceBl`
   - Project: `Sakura`
   - Repository: `Sakura Frontend`
   - Branch: Your branch (e.g., `dev`)
4. Next → Build Configuration:
   - Build Presets: `Angular`
   - App location: `FE/application`
   - API location: *(empty)*
   - Output location: `dist/application/browser`
5. Review + Create → Create

#### **Step 2: Wait for Deployment (10 min)**

- Watch deployment progress
- Wait for "Deployment complete"
- Click "Go to resource"

#### **Step 3: Configure Application Settings (3 min)**

1. Configuration → Application settings
2. Add:
   - `MSAL_CLIENT_ID`: Your client ID
   - `MSAL_AUTHORITY`: Your authority URL
   - `API_BASE_URL`: Your backend URL
3. Save

#### **Step 4: Update Azure AD (2 min)**

1. Azure AD → App registrations → Your app
2. Authentication → Redirect URIs
3. Add: `https://your-static-web-app-url.azurestaticapps.net`
4. Save

#### **Step 5: Test (2 min)**

1. Open deployed URL
2. Test login
3. Verify functionality

**✅ Done!**

---

### **📋 Checklist Format**

Print this for quick reference:

```
□ Create Azure Static Web App
  □ Name: sakura-frontend-____
  □ Resource Group: ____
  □ Region: Global
  □ Plan: Standard
  □ Organization: DANFinanceBl
  □ Project: Sakura
  □ Repository: Sakura Frontend
  □ Branch: ____
  □ Build Preset: Angular
  □ App location: FE/application
  □ Output location: dist/application/browser

□ Application Settings
  □ MSAL_CLIENT_ID: ____
  □ MSAL_AUTHORITY: ____
  □ MSAL_REDIRECT_URI: ____
  □ API_BASE_URL: ____

□ Azure AD Configuration
  □ Add redirect URI
  □ Grant permissions
  □ Verify app registration

□ Backend CORS
  □ Add Static Web App URL to CORS policy
  □ Test API calls

□ Custom Domain (if needed)
  □ Add CNAME record
  □ Add TXT record for validation
  □ Wait for SSL certificate
  □ Update redirect URIs

□ Testing
  □ Test deployment
  □ Test authentication
  □ Test API integration
  □ Test routing
  □ Test on mobile

□ Monitoring
  □ Enable Application Insights
  □ Configure alerts
  □ Review logs
```

---

### **⚡ Command Reference**

#### **Local Testing**:
```bash
# Navigate to app
cd FE/application

# Install dependencies
npm install

# Run locally
npm start

# Build for production
npm run build

# Test production build locally
cd dist/application/browser
npx http-server -p 8080
```

#### **Azure CLI Commands**:
```bash
# Login to Azure
az login

# List Static Web Apps
az staticwebapp list --resource-group AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL

# Show Static Web App details
az staticwebapp show --name sakura-frontend-dev

# List custom domains
az staticwebapp hostname list --name sakura-frontend-dev

# Show deployment token
az staticwebapp secrets list --name sakura-frontend-dev

# Delete Static Web App (careful!)
az staticwebapp delete --name sakura-frontend-dev
```

#### **DNS Verification**:
```bash
# Check CNAME
nslookup -type=CNAME sakura.yourcompany.com

# Check TXT
nslookup -type=TXT _dnsauth.sakura.yourcompany.com

# Check all DNS records
dig sakura.yourcompany.com ANY
```

---

## 📞 Support and Resources

### **Official Documentation**:
- [Azure Static Web Apps Docs](https://docs.microsoft.com/azure/static-web-apps/)
- [Angular Deployment Guide](https://angular.io/guide/deployment)
- [Azure DevOps Pipelines](https://docs.microsoft.com/azure/devops/pipelines/)

### **Useful Links**:
- **Azure Portal**: https://portal.azure.com
- **Azure DevOps**: https://dev.azure.com
- **DNS Checker**: https://dnschecker.org
- **SSL Test**: https://www.ssllabs.com/ssltest/

### **Troubleshooting Resources**:
- **Azure Status**: https://status.azure.com
- **Stack Overflow**: [azure-static-web-apps] tag
- **GitHub Issues**: Azure Static Web Apps repository

---

## 🔄 Update History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-18 | 1.0 | Initial deployment guide created |

---

## 📝 Notes

- Keep this document updated with each deployment
- Document any custom configurations specific to Sakura
- Share with team members for consistent deployments
- Review and update after Azure updates

---

**End of Deployment Guide**

*Maintained by: Sakura Development Team*  
*Last Updated: November 18, 2025*

