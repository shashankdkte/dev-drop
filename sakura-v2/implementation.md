# Azure AD + MSAL Integration - Complete Implementation Checklist

> **Purpose**: End-to-end implementation guide with verification at every step  
> **Estimated Time**: 16-20 hours total  
> **Status**: Ready to begin  
> **Date Started**: [Fill in when you start]

---

## 📋 Pre-Flight Checklist

Before starting, verify you have:

- [ ] **Azure Portal Access**: Can log in to https://portal.azure.com
- [ ] **App Registration Permissions**: Can create new app registrations in Azure AD
- [ ] **Tenant Information**: Know your Azure AD tenant ID (from Image 1: `6e8992ec-76d5-4ea5-8eae-b0c5e558749a`)
- [ ] **Backend Running**: Can run backend locally (`dotnet run`)
- [ ] **Frontend Running**: Can run frontend locally (`npm start`)
- [ ] **VS Code/Visual Studio**: Development environment ready
- [ ] **Git**: All current changes committed (checkpoint for rollback)

### ✅ Checkpoint: Pre-Flight
```bash
# Verify backend compiles
cd BE/Sakura_Backend/SakuraV2Api/SakuraV2Api
dotnet build
# Expected: Build succeeded. 0 Error(s)

# Verify frontend compiles
cd FE/application
npm install
npm run build
# Expected: ✔ Built successfully
```

**🔍 Debug Log Expected**:
```
Backend: Build succeeded
Frontend: Application bundle generation complete
Status: ✅ Ready to proceed
```

---

## 🏗️ PHASE 1: Azure AD Setup (2-3 hours)

### Step 1.1: Create Backend API App Registration

- [ ] Open Azure Portal: https://portal.azure.com
- [ ] Navigate to: **Azure Active Directory** > **App registrations**
- [ ] Click **+ New registration**
- [ ] Fill in details:
  - **Name**: `Sakura V2 API`
  - **Supported account types**: `Accounts in this organizational directory only (dentsu only)`
  - **Redirect URI**: Leave blank (API doesn't need redirect)
- [ ] Click **Register**
- [ ] **COPY** the following values (save to notepad):
  - `Application (client) ID`: _____________________
  - `Directory (tenant) ID`: _____________________

### ✅ Checkpoint 1.1: API App Registration Created
```
Expected in Azure Portal:
- App name: "Sakura V2 API" visible in app registrations list
- Status: Enabled
- Type: Web API
```

**🔍 Debug Log**:
```
Azure AD App Registration Created:
  Name: Sakura V2 API
  Client ID: [32 character GUID]
  Tenant ID: 6e8992ec-76d5-4ea5-8eae-b0c5e558749a
  Status: ✅ Registered
```

---

### Step 1.2: Expose API (Create Scope)

- [ ] In your **Sakura V2 API** app registration
- [ ] Navigate to: **Expose an API** (left sidebar)
- [ ] Click **+ Add a scope**
- [ ] **Application ID URI**: Click **Save** (accepts default: `api://[client-id]`)
- [ ] Fill in scope details:
  - **Scope name**: `access_as_user`
  - **Who can consent**: `Admins and users`
  - **Admin consent display name**: `Access Sakura V2 API`
  - **Admin consent description**: `Allows the app to access Sakura V2 API on behalf of the signed-in user`
  - **User consent display name**: `Access Sakura V2`
  - **User consent description**: `Allows Sakura to access resources on your behalf`
  - **State**: `Enabled`
- [ ] Click **Add scope**
- [ ] **COPY** the full scope value: `api://[client-id]/access_as_user`

### ✅ Checkpoint 1.2: API Scope Exposed
```
Expected in Azure Portal:
- Expose an API section shows:
  - Application ID URI: api://[your-client-id]
  - Scopes: access_as_user (Enabled)
```

**🔍 Debug Log**:
```
API Scope Created:
  Application ID URI: api://[client-id]
  Scope Name: access_as_user
  State: Enabled
  Status: ✅ Scope ready for client apps
```

---

### Step 1.3: Create Frontend SPA App Registration

- [ ] Back to: **Azure Active Directory** > **App registrations**
- [ ] Click **+ New registration**
- [ ] Fill in details:
  - **Name**: `Sakura V2 Frontend`
  - **Supported account types**: `Accounts in this organizational directory only (dentsu only)`
  - **Redirect URI**: 
    - Platform: `Single-page application (SPA)`
    - URI: `http://localhost:4200`
- [ ] Click **Register**
- [ ] **COPY** the following values:
  - `Application (client) ID`: _____________________
  - `Directory (tenant) ID`: _____________________ (same as before)

### ✅ Checkpoint 1.3: Frontend App Registration Created
```
Expected in Azure Portal:
- App name: "Sakura V2 Frontend" visible in app registrations list
- Platform: Single-page application
- Redirect URI: http://localhost:4200
```

**🔍 Debug Log**:
```
Frontend App Registration Created:
  Name: Sakura V2 Frontend
  Client ID: [32 character GUID]
  Platform: SPA
  Redirect URI: http://localhost:4200
  Status: ✅ Registered
```

---

### Step 1.4: Add API Permissions to Frontend App

- [ ] In your **Sakura V2 Frontend** app registration
- [ ] Navigate to: **API permissions** (left sidebar)
- [ ] Click **+ Add a permission**
- [ ] Click **My APIs** tab
- [ ] Select **Sakura V2 API**
- [ ] Check: `access_as_user`
- [ ] Click **Add permissions**
- [ ] Click **Grant admin consent for [your tenant]** (⚠️ Important!)
- [ ] Confirm **Yes**

### ✅ Checkpoint 1.4: Permissions Granted
```
Expected in Azure Portal:
- API permissions section shows:
  ✅ access_as_user (Granted for [tenant])
  Status: Green checkmark
```

**🔍 Debug Log**:
```
API Permissions Configured:
  Frontend App: Sakura V2 Frontend
  Can Access: Sakura V2 API
  Scope: access_as_user
  Admin Consent: ✅ Granted
  Status: ✅ Ready to authenticate
```

---

### Step 1.5: Add Production Redirect URIs (Optional for now)

⚠️ **Skip this for local development. Come back later for production.**

- [ ] When deploying to Azure, add production URIs:
  - `https://your-app.azurestaticapps.net`
  - `https://sakura.dentsu.com` (if custom domain)

---

### Step 1.6: Document Your Azure AD Configuration

Create a file: `docs/AZURE-AD-CONFIG.md` with your values:

```markdown
# Azure AD Configuration

## Backend API App
- Application (client) ID: [PASTE YOUR VALUE]
- Directory (tenant) ID: 6e8992ec-76d5-4ea5-8eae-b0c5e558749a
- Application ID URI: api://[YOUR-API-CLIENT-ID]
- Scope: api://[YOUR-API-CLIENT-ID]/access_as_user

## Frontend SPA App
- Application (client) ID: [PASTE YOUR VALUE]
- Directory (tenant) ID: 6e8992ec-76d5-4ea5-8eae-b0c5e558749a
- Redirect URI: http://localhost:4200
```

- [ ] Create the file and save your values
- [ ] ⚠️ **DO NOT commit secrets to Git** (Client IDs are OK, secrets are NOT)

### ✅ Checkpoint: Phase 1 Complete

**Verification**:
- [ ] Backend API app registered ✅
- [ ] API scope exposed ✅
- [ ] Frontend SPA app registered ✅
- [ ] Permissions granted with admin consent ✅
- [ ] Configuration documented ✅

**🔍 Debug Log Expected**:
```
=== PHASE 1 COMPLETE ===
Azure AD Configuration:
  ✅ Backend API registered
  ✅ Frontend SPA registered
  ✅ API permissions granted
  ✅ Admin consent obtained
  
Ready for Phase 2: Backend Implementation
```

---

## 🔧 PHASE 2: Backend Implementation (4-6 hours)

### Step 2.1: Install Required NuGet Packages

```bash
cd BE/Sakura_Backend/SakuraV2Api/SakuraV2Api
```

- [ ] Install packages:
```bash
dotnet add package Microsoft.Identity.Web --version 2.15.2
dotnet add package Microsoft.Identity.Web.MicrosoftGraph --version 2.15.2
```

- [ ] Verify installation:
```bash
dotnet list package | findstr Microsoft.Identity
```

### ✅ Checkpoint 2.1: Packages Installed
```
Expected Output:
> Microsoft.Identity.Web                    2.15.2
> Microsoft.Identity.Web.MicrosoftGraph     2.15.2

Status: ✅ Packages installed
```

**🔍 Debug Log**:
```
NuGet Packages Installed:
  ✅ Microsoft.Identity.Web v2.15.2
  ✅ Microsoft.Identity.Web.MicrosoftGraph v2.15.2
  
Project still compiles: dotnet build
Status: ✅ Ready for configuration
```

---

### Step 2.2: Update appsettings.json

- [ ] Open: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/appsettings.json`
- [ ] Update the `AzureAd` section with your values:

```json
{
  "Logging": { /* keep existing */ },
  "ConnectionStrings": { /* keep existing */ },
  
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "6e8992ec-76d5-4ea5-8eae-b0c5e558749a",
    "ClientId": "[YOUR-BACKEND-API-CLIENT-ID]",
    "Audience": "api://[YOUR-BACKEND-API-CLIENT-ID]",
    "Scopes": "access_as_user"
  },
  
  "Jwt": {
    "SecretKey": "DEPRECATED - Remove after Azure AD works",
    "Issuer": "DEPRECATED",
    "Audience": "DEPRECATED"
  },
  
  "CorsSettings": { /* keep existing */ },
  "AppSettings": { /* keep existing */ }
}
```

- [ ] Replace `[YOUR-BACKEND-API-CLIENT-ID]` with actual value
- [ ] Save file

### ✅ Checkpoint 2.2: Configuration Updated
```
Expected:
- AzureAd section has real values (no "your-tenant-id-here")
- TenantId is a GUID
- ClientId is a GUID
- Audience starts with "api://"

Status: ✅ Configuration ready
```

**🔍 Debug Log**:
```
appsettings.json Updated:
  ✅ TenantId: 6e8992ec-...
  ✅ ClientId: [your-value]
  ✅ Audience: api://[your-value]
  ✅ File saved
  
Status: ✅ Ready to update code
```

---

### Step 2.3: Create New ServiceExtensions Method

- [ ] Open: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/Extensions/ServiceExtensions.cs`
- [ ] Add this NEW method (don't delete the old one yet):

```csharp
/// <summary>
/// Configure Azure AD authentication - PRODUCTION
/// </summary>
public static IServiceCollection AddAzureAdAuthentication(
    this IServiceCollection services,
    IConfiguration configuration)
{
    // Clear default claim mappings
    JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

    // Add Microsoft Identity Web authentication
    services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddMicrosoftIdentityWebApi(options =>
        {
            configuration.Bind("AzureAd", options);
            
            // Configure token validation
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                NameClaimType = "preferred_username", // Use UPN from Azure AD
                RoleClaimType = "roles" // Use roles from Azure AD
            };
            
            // Log token validation
            options.Events = new JwtBearerEvents
            {
                OnTokenValidated = context =>
                {
                    var logger = context.HttpContext.RequestServices
                        .GetRequiredService<ILogger<Program>>();
                    
                    logger.LogInformation("=== AZURE AD TOKEN VALIDATED ===");
                    logger.LogInformation($"User: {context.Principal?.Identity?.Name}");
                    
                    // Log all claims for debugging
                    if (context.Principal != null)
                    {
                        foreach (var claim in context.Principal.Claims)
                        {
                            logger.LogInformation($"  Claim: {claim.Type} = {claim.Value}");
                        }
                    }
                    logger.LogInformation("=== END TOKEN CLAIMS ===");
                    
                    return Task.CompletedTask;
                },
                OnAuthenticationFailed = context =>
                {
                    var logger = context.HttpContext.RequestServices
                        .GetRequiredService<ILogger<Program>>();
                    
                    logger.LogError("=== AZURE AD AUTHENTICATION FAILED ===");
                    logger.LogError($"Exception: {context.Exception.Message}");
                    logger.LogError($"Stack: {context.Exception.StackTrace}");
                    
                    return Task.CompletedTask;
                }
            };
        },
        options =>
        {
            configuration.Bind("AzureAd", options);
        });

    // Keep existing authorization policies
    services.AddAuthorization(options =>
    {
        options.AddPolicy("Authenticated", policy =>
            policy.RequireAuthenticatedUser());
            
        options.AddPolicy("Requester", policy =>
            policy.RequireAuthenticatedUser());
            
        options.AddPolicy("Approver", policy =>
            policy.RequireAuthenticatedUser());
            
        options.AddPolicy("WorkspaceAdmin", policy =>
            policy.RequireAuthenticatedUser());
            
        options.AddPolicy("SakuraAdmin", policy =>
            policy.RequireAuthenticatedUser());
    });

    return services;
}
```

- [ ] Save file

### ✅ Checkpoint 2.3: New Method Added
```bash
# Verify it compiles
dotnet build

Expected: Build succeeded. 0 Error(s)
```

**🔍 Debug Log**:
```
New Authentication Method Created:
  ✅ AddAzureAdAuthentication() added
  ✅ Uses Microsoft.Identity.Web
  ✅ Includes debug logging
  ✅ Compiles successfully
  
Status: ✅ Ready to switch Program.cs
```

---

### Step 2.4: Update Program.cs to Use Azure AD

- [ ] Open: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/Program.cs`
- [ ] Find line 28: `builder.Services.AddAuthenticationServices(builder.Configuration);`
- [ ] **COMMENT OUT** the old line and **ADD** new line:

```csharp
// OLD: Temporary JWT
// builder.Services.AddAuthenticationServices(builder.Configuration);

// NEW: Azure AD authentication
builder.Services.AddAzureAdAuthentication(builder.Configuration);
```

- [ ] Save file
- [ ] Build to verify:

```bash
dotnet build
```

### ✅ Checkpoint 2.4: Program.cs Updated
```bash
# Run the backend
dotnet run --launch-profile https

Expected startup logs:
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:7238
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

**🔍 Debug Log Expected**:
```
=== BACKEND STARTED WITH AZURE AD ===
Now listening on: https://localhost:7238
Swagger UI: https://localhost:7238/swagger
Authentication: Microsoft.Identity.Web (Azure AD)
Status: ✅ Backend running
```

⚠️ **Keep backend running for next test**

---

### Step 2.5: Test Backend with Invalid Token (Should Fail)

- [ ] Open new terminal (keep backend running)
- [ ] Test API without token:

```bash
curl -X GET https://localhost:7238/api/v1/workspaces -k
```

- [ ] Test API with fake token:

```bash
curl -X GET https://localhost:7238/api/v1/workspaces -k -H "Authorization: Bearer fake-token-12345"
```

### ✅ Checkpoint 2.5: Backend Rejects Invalid Requests
```
Expected Response (both tests):
HTTP/1.1 401 Unauthorized

Expected in backend logs:
=== AZURE AD AUTHENTICATION FAILED ===
Exception: IDX10223: Lifetime validation failed...
```

**🔍 Debug Log Expected**:
```
Test 1 - No Token:
  Response: 401 Unauthorized ✅
  Reason: No Authorization header

Test 2 - Fake Token:
  Response: 401 Unauthorized ✅
  Reason: Invalid token signature
  Log: === AZURE AD AUTHENTICATION FAILED ===
  
Status: ✅ Backend correctly rejects invalid tokens
```

---

### Step 2.6: Update TempAuthService to Warn (Don't Remove Yet)

- [ ] Open: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/Services/TempAuthService.cs`
- [ ] Add warning at top of class:

```csharp
/// <summary>
/// DEPRECATED - This service is NO LONGER USED
/// Authentication now handled by Azure AD via Microsoft.Identity.Web
/// This class is kept temporarily for reference only
/// TODO: Remove this file after Azure AD testing complete
/// </summary>
[Obsolete("Use Azure AD authentication instead")]
public class TempAuthService
{
    // ... existing code ...
}
```

- [ ] Save file

### ✅ Checkpoint: Phase 2 Complete

**Verification**:
- [ ] Microsoft.Identity.Web packages installed ✅
- [ ] appsettings.json has real Azure AD values ✅
- [ ] New AddAzureAdAuthentication method created ✅
- [ ] Program.cs uses Azure AD authentication ✅
- [ ] Backend starts successfully ✅
- [ ] Backend rejects invalid tokens ✅
- [ ] TempAuthService marked deprecated ✅

**🔍 Debug Log Expected**:
```
=== PHASE 2 COMPLETE ===
Backend Configuration:
  ✅ Azure AD authentication configured
  ✅ Microsoft.Identity.Web integrated
  ✅ Backend running on https://localhost:7238
  ✅ Rejects unauthorized requests
  ✅ Logging token validation events
  
Ready for Phase 3: Frontend Implementation
```

**🔴 CHECKPOINT: Backend Must Be Working Before Proceeding**

If backend doesn't start or shows errors, STOP HERE and debug before continuing.

---

## 🎨 PHASE 3: Frontend Implementation (6-8 hours)

### Step 3.1: Install MSAL Angular Packages

```bash
cd FE/application
```

- [ ] Install packages:

```bash
npm install @azure/msal-browser@3.7.0
npm install @azure/msal-angular@3.0.10
```

- [ ] Verify installation:

```bash
npm list @azure/msal-browser @azure/msal-angular
```

### ✅ Checkpoint 3.1: Packages Installed
```
Expected Output:
├── @azure/msal-angular@3.0.10
└── @azure/msal-browser@3.7.0

Status: ✅ Packages installed
```

**🔍 Debug Log**:
```
NPM Packages Installed:
  ✅ @azure/msal-browser v3.7.0
  ✅ @azure/msal-angular v3.0.10
  
Project still compiles: npm run build
Status: ✅ Ready for configuration
```

---

### Step 3.2: Update environment.ts

- [ ] Open: `FE/application/src/environments/environment.ts`
- [ ] Replace entire content with:

```typescript
/**
 * Development Environment Configuration
 * NOW USING: Azure AD Authentication
 */
export const environment = {
  production: false,
  
  // API Configuration
  apiUrl: 'https://localhost:7238',
  apiVersion: 'v1',
  apiTimeout: 30000,
  
  // Azure AD Configuration
  azureAd: {
    clientId: '[YOUR-FRONTEND-SPA-CLIENT-ID]',
    authority: 'https://login.microsoftonline.com/6e8992ec-76d5-4ea5-8eae-b0c5e558749a',
    redirectUri: 'http://localhost:4200',
    postLogoutRedirectUri: 'http://localhost:4200',
    
    // API Scopes - Request access to your backend API
    scopes: [
      'api://[YOUR-BACKEND-API-CLIENT-ID]/access_as_user'
    ]
  },
  
  // Feature Flags
  enableLogging: true,
  
  // Pagination
  defaultPageSize: 20,
  maxPageSize: 100
};
```

- [ ] Replace `[YOUR-FRONTEND-SPA-CLIENT-ID]` with your Frontend app client ID
- [ ] Replace `[YOUR-BACKEND-API-CLIENT-ID]` with your Backend API client ID
- [ ] Save file

### ✅ Checkpoint 3.2: Environment Configured
```typescript
Verify:
- azureAd.clientId is a GUID (not placeholder)
- azureAd.scopes[0] starts with "api://"
- authority has real tenant ID

Status: ✅ Environment configured
```

**🔍 Debug Log**:
```
environment.ts Updated:
  ✅ Frontend Client ID: [your-spa-client-id]
  ✅ Backend API Scope: api://[your-api-client-id]/access_as_user
  ✅ Authority: https://login.microsoftonline.com/6e8992ec...
  ✅ Redirect URI: http://localhost:4200
  
Status: ✅ Ready to configure MSAL
```

---

### Step 3.3: Create MSAL Configuration File

- [ ] Create new file: `FE/application/src/app/config/msal.config.ts`

```typescript
import { 
  BrowserCacheLocation, 
  InteractionType, 
  IPublicClientApplication, 
  LogLevel, 
  PublicClientApplication 
} from '@azure/msal-browser';
import { 
  MsalGuardConfiguration, 
  MsalInterceptorConfiguration 
} from '@azure/msal-angular';
import { environment } from '../../environments/environment';

/**
 * MSAL Browser Configuration
 */
export const msalConfig = {
  auth: {
    clientId: environment.azureAd.clientId,
    authority: environment.azureAd.authority,
    redirectUri: environment.azureAd.redirectUri,
    postLogoutRedirectUri: environment.azureAd.postLogoutRedirectUri,
    navigateToLoginRequestUrl: true
  },
  cache: {
    cacheLocation: BrowserCacheLocation.LocalStorage,
    storeAuthStateInCookie: false, // Set to true for IE11/Edge
  },
  system: {
    loggerOptions: {
      loggerCallback: (level: LogLevel, message: string, containsPii: boolean) => {
        if (containsPii) return;
        
        switch (level) {
          case LogLevel.Error:
            console.error('[MSAL]', message);
            return;
          case LogLevel.Warning:
            console.warn('[MSAL]', message);
            return;
          case LogLevel.Info:
            console.info('[MSAL]', message);
            return;
          case LogLevel.Verbose:
            console.debug('[MSAL]', message);
            return;
        }
      },
      logLevel: environment.enableLogging ? LogLevel.Verbose : LogLevel.Error,
      piiLoggingEnabled: false
    }
  }
};

/**
 * Create MSAL instance
 */
export function MSALInstanceFactory(): IPublicClientApplication {
  console.log('=== MSAL INSTANCE CREATION ===');
  console.log('Client ID:', environment.azureAd.clientId);
  console.log('Authority:', environment.azureAd.authority);
  console.log('Redirect URI:', environment.azureAd.redirectUri);
  
  const msalInstance = new PublicClientApplication(msalConfig);
  
  console.log('✅ MSAL instance created successfully');
  return msalInstance;
}

/**
 * MSAL Guard Configuration
 * Protects routes from unauthorized access
 */
export function MSALGuardConfigFactory(): MsalGuardConfiguration {
  return {
    interactionType: InteractionType.Redirect,
    authRequest: {
      scopes: environment.azureAd.scopes
    },
    loginFailedRoute: '/login-failed'
  };
}

/**
 * MSAL Interceptor Configuration
 * Automatically adds tokens to API requests
 */
export function MSALInterceptorConfigFactory(): MsalInterceptorConfiguration {
  const protectedResourceMap = new Map<string, Array<string>>();
  
  // Protect all API calls to your backend
  protectedResourceMap.set(
    environment.apiUrl + '/*',
    environment.azureAd.scopes
  );
  
  console.log('=== MSAL INTERCEPTOR CONFIG ===');
  console.log('Protected Resources:', Array.from(protectedResourceMap.entries()));
  
  return {
    interactionType: InteractionType.Redirect,
    protectedResourceMap
  };
}
```

- [ ] Create the `config` folder if it doesn't exist
- [ ] Save file

### ✅ Checkpoint 3.3: MSAL Config Created
```bash
# Verify file exists
ls src/app/config/msal.config.ts

Expected: File exists
Status: ✅ Configuration file created
```

**🔍 Debug Log**:
```
MSAL Configuration Created:
  ✅ File: src/app/config/msal.config.ts
  ✅ MSALInstanceFactory defined
  ✅ MSALGuardConfigFactory defined
  ✅ MSALInterceptorConfigFactory defined
  ✅ Logging configured
  
Status: ✅ Ready to integrate with Angular
```

---

### Step 3.4: Update app.config.ts

- [ ] Open: `FE/application/src/app/app.config.ts`
- [ ] Replace entire content with:

```typescript
import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors, HTTP_INTERCEPTORS } from '@angular/common/http';
import { 
  MSAL_INSTANCE, 
  MSAL_GUARD_CONFIG, 
  MSAL_INTERCEPTOR_CONFIG, 
  MsalService, 
  MsalGuard, 
  MsalBroadcastService,
  MsalInterceptor,
  MsalModule
} from '@azure/msal-angular';

import { routes } from './app.routes';
import { 
  MSALInstanceFactory, 
  MSALGuardConfigFactory, 
  MSALInterceptorConfigFactory 
} from './config/msal.config';

export const appConfig: ApplicationConfig = {
  providers: [
    // Routing
    provideRouter(routes),
    
    // HTTP Client with MSAL Interceptor
    provideHttpClient(),
    
    // MSAL Configuration
    {
      provide: HTTP_INTERCEPTORS,
      useClass: MsalInterceptor,
      multi: true
    },
    {
      provide: MSAL_INSTANCE,
      useFactory: MSALInstanceFactory
    },
    {
      provide: MSAL_GUARD_CONFIG,
      useFactory: MSALGuardConfigFactory
    },
    {
      provide: MSAL_INTERCEPTOR_CONFIG,
      useFactory: MSALInterceptorConfigFactory
    },
    
    // MSAL Services
    MsalService,
    MsalGuard,
    MsalBroadcastService,
    
    // Import MSAL Module (for compatibility)
    importProvidersFrom(MsalModule)
  ]
};
```

- [ ] Save file
- [ ] Build to verify:

```bash
npm run build
```

### ✅ Checkpoint 3.4: App Config Updated
```bash
# Build should succeed
npm run build

Expected: ✔ Built successfully
Status: ✅ MSAL integrated with Angular
```

**🔍 Debug Log Expected**:
```
app.config.ts Updated:
  ✅ MSAL providers added
  ✅ HTTP_INTERCEPTORS configured
  ✅ MSAL factories registered
  ✅ Build successful
  
Status: ✅ Angular knows about MSAL
```

---

### Step 3.5: Update App Component to Initialize MSAL

- [ ] Open: `FE/application/src/app/app.ts`
- [ ] Replace entire content with:

```typescript
import { Component, OnInit, Inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { 
  MsalService, 
  MsalBroadcastService, 
  MSAL_GUARD_CONFIG, 
  MsalGuardConfiguration 
} from '@azure/msal-angular';
import { 
  InteractionStatus, 
  RedirectRequest, 
  EventMessage, 
  EventType 
} from '@azure/msal-browser';
import { filter, takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet />',
  styles: []
})
export class App implements OnInit {
  private readonly _destroying$ = new Subject<void>();
  
  constructor(
    @Inject(MSAL_GUARD_CONFIG) private msalGuardConfig: MsalGuardConfiguration,
    private authService: MsalService,
    private msalBroadcastService: MsalBroadcastService
  ) {}

  ngOnInit(): void {
    console.log('=== APP INITIALIZATION ===');
    console.log('MSAL Guard Config:', this.msalGuardConfig);
    
    // Initialize MSAL
    this.authService.instance.initialize().then(() => {
      console.log('✅ MSAL initialized');
      
      // Handle redirect after login
      this.authService.instance.handleRedirectPromise().then(response => {
        if (response) {
          console.log('=== REDIRECT RESPONSE ===');
          console.log('Account:', response.account?.username);
          console.log('Access Token received:', !!response.accessToken);
          console.log('ID Token received:', !!response.idToken);
          
          // Set active account
          this.authService.instance.setActiveAccount(response.account);
          console.log('✅ Active account set');
        }
      }).catch(error => {
        console.error('❌ Error handling redirect:', error);
      });
    });

    // Subscribe to MSAL events
    this.msalBroadcastService.msalSubject$
      .pipe(
        filter((msg: EventMessage) => msg.eventType === EventType.LOGIN_SUCCESS),
        takeUntil(this._destroying$)
      )
      .subscribe((result: EventMessage) => {
        console.log('=== LOGIN SUCCESS EVENT ===');
        console.log('Event:', result);
        
        const payload = result.payload as any;
        if (payload.account) {
          this.authService.instance.setActiveAccount(payload.account);
          console.log('✅ Account set:', payload.account.username);
        }
      });

    // Subscribe to interaction status
    this.msalBroadcastService.inProgress$
      .pipe(
        filter((status: InteractionStatus) => status === InteractionStatus.None),
        takeUntil(this._destroying$)
      )
      .subscribe(() => {
        console.log('=== INTERACTION STATUS: None ===');
        this.checkAndSetActiveAccount();
      });
  }

  checkAndSetActiveAccount() {
    const activeAccount = this.authService.instance.getActiveAccount();
    
    if (!activeAccount && this.authService.instance.getAllAccounts().length > 0) {
      const accounts = this.authService.instance.getAllAccounts();
      this.authService.instance.setActiveAccount(accounts[0]);
      console.log('✅ Set first account as active:', accounts[0].username);
    } else if (activeAccount) {
      console.log('✅ Active account already set:', activeAccount.username);
    } else {
      console.log('⚠️ No accounts found - user needs to log in');
    }
  }

  ngOnDestroy(): void {
    this._destroying$.next();
    this._destroying$.complete();
  }
}
```

- [ ] Save file
- [ ] Build to verify:

```bash
npm run build
```

### ✅ Checkpoint 3.5: App Component Updated
```bash
Expected: ✔ Built successfully

Status: ✅ App initializes MSAL on startup
```

**🔍 Debug Log Expected** (when you run the app later):
```
=== APP INITIALIZATION ===
MSAL Guard Config: { interactionType: "redirect", ... }
✅ MSAL initialized
=== INTERACTION STATUS: None ===
⚠️ No accounts found - user needs to log in
```

---

### Step 3.6: Create Login Component (Temporary - for explicit login)

- [ ] Create file: `FE/application/src/app/components/azure-login/azure-login.component.ts`

```typescript
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MsalService } from '@azure/msal-angular';
import { RedirectRequest } from '@azure/msal-browser';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-azure-login',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="login-container">
      <div class="login-card">
        <div class="login-header">
          <h1>🌸 Sakura V2</h1>
          <p>Access Request & Approval System</p>
        </div>

        <div class="login-body">
          <div class="info-section">
            <h3>🔐 Authentication Required</h3>
            <p>Sign in with your dentsu Microsoft account</p>
          </div>

          <button 
            class="btn-microsoft" 
            (click)="login()"
            [disabled]="isLoggingIn">
            <span *ngIf="!isLoggingIn">
              <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='21' height='21'%3E%3Cpath fill='%23f25022' d='M0 0h10v10H0z'/%3E%3Cpath fill='%2300a4ef' d='M11 0h10v10H11z'/%3E%3Cpath fill='%237fba00' d='M0 11h10v10H0z'/%3E%3Cpath fill='%23ffb900' d='M11 11h10v10H11z'/%3E%3C/svg%3E" 
                   alt="Microsoft" 
                   class="ms-icon">
              Sign in with Microsoft
            </span>
            <span *ngIf="isLoggingIn">
              Redirecting to Microsoft...
            </span>
          </button>

          <div class="debug-info" *ngIf="showDebug">
            <h4>🔍 Debug Information</h4>
            <pre>{{ debugInfo }}</pre>
          </div>
        </div>

        <div class="login-footer">
          <small>Azure AD Authentication Enabled</small>
          <small>Tenant: dentsu</small>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .login-container {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 20px;
    }

    .login-card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      max-width: 450px;
      width: 100%;
      overflow: hidden;
    }

    .login-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 40px 30px;
      text-align: center;
    }

    .login-header h1 {
      margin: 0 0 10px 0;
      font-size: 36px;
    }

    .login-header p {
      margin: 0;
      opacity: 0.9;
      font-size: 16px;
    }

    .login-body {
      padding: 40px 30px;
    }

    .info-section {
      text-align: center;
      margin-bottom: 30px;
    }

    .info-section h3 {
      margin: 0 0 10px 0;
      color: #333;
      font-size: 20px;
    }

    .info-section p {
      margin: 0;
      color: #666;
      font-size: 14px;
    }

    .btn-microsoft {
      width: 100%;
      padding: 14px 24px;
      background: #2f2f2f;
      color: white;
      border: none;
      border-radius: 4px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      transition: background 0.2s;
    }

    .btn-microsoft:hover:not(:disabled) {
      background: #1f1f1f;
    }

    .btn-microsoft:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .ms-icon {
      width: 21px;
      height: 21px;
    }

    .debug-info {
      margin-top: 30px;
      padding: 15px;
      background: #f5f5f5;
      border-radius: 8px;
      border: 1px solid #ddd;
    }

    .debug-info h4 {
      margin: 0 0 10px 0;
      font-size: 14px;
      color: #333;
    }

    .debug-info pre {
      margin: 0;
      font-size: 11px;
      color: #666;
      white-space: pre-wrap;
      word-break: break-all;
    }

    .login-footer {
      background: #f8f9fa;
      padding: 20px 30px;
      text-align: center;
      border-top: 1px solid #e9ecef;
    }

    .login-footer small {
      display: block;
      color: #6c757d;
      margin: 5px 0;
    }
  `]
})
export class AzureLoginComponent {
  isLoggingIn = false;
  showDebug = environment.enableLogging;
  debugInfo = '';

  constructor(
    private authService: MsalService,
    private router: Router
  ) {
    this.updateDebugInfo();
  }

  login(): void {
    console.log('=== LOGIN BUTTON CLICKED ===');
    
    this.isLoggingIn = true;
    
    const loginRequest: RedirectRequest = {
      scopes: environment.azureAd.scopes,
      prompt: 'select_account'
    };

    console.log('Login Request:', loginRequest);
    console.log('Redirecting to Azure AD...');
    
    this.authService.loginRedirect(loginRequest);
  }

  updateDebugInfo(): void {
    this.debugInfo = JSON.stringify({
      clientId: environment.azureAd.clientId,
      authority: environment.azureAd.authority,
      redirectUri: environment.azureAd.redirectUri,
      scopes: environment.azureAd.scopes,
      accounts: this.authService.instance.getAllAccounts().length
    }, null, 2);
  }
}
```

- [ ] Create the directory if it doesn't exist: `FE/application/src/app/components/azure-login/`
- [ ] Save file

### ✅ Checkpoint 3.6: Login Component Created
```bash
# Verify file exists
ls src/app/components/azure-login/azure-login.component.ts

Expected: File exists
Status: ✅ Login component ready
```

**🔍 Debug Log**:
```
Login Component Created:
  ✅ File: azure-login.component.ts
  ✅ Uses MsalService.loginRedirect()
  ✅ Shows Microsoft sign-in button
  ✅ Includes debug information
  
Status: ✅ Ready to update routes
```

---

### Step 3.7: Update Routes to Use MSAL Guard

- [ ] Open: `FE/application/src/app/app.routes.ts`
- [ ] Replace with:

```typescript
import { Routes } from '@angular/router';
import { MsalGuard } from '@azure/msal-angular';
import { AzureLoginComponent } from './components/azure-login/azure-login.component';

export const routes: Routes = [
  // Public route - login page
  {
    path: 'login',
    component: AzureLoginComponent
  },
  
  // All other routes protected by MSAL Guard
  {
    path: '',
    canActivate: [MsalGuard],
    children: [
      {
        path: '',
        loadComponent: () => import('./components/layout/layout.component').then(m => m.LayoutComponent),
        children: [
          {
            path: '',
            loadComponent: () => import('./components/home/home.component').then(m => m.HomeComponent)
          },
          {
            path: 'request',
            loadComponent: () => import('./components/request-form/request-form.component').then(m => m.RequestFormComponent)
          },
          {
            path: 'my-requests',
            loadComponent: () => import('./components/my-requests/my-requests.component').then(m => m.MyRequestsComponent)
          },
          {
            path: 'approvals',
            loadComponent: () => import('./components/approvals/approvals.component').then(m => m.ApprovalsComponent)
          },
          {
            path: 'catalogue',
            loadComponent: () => import('./components/catalogue/catalogue.component').then(m => m.CatalogueComponent)
          },
          {
            path: 'my-access',
            loadComponent: () => import('./components/my-access/my-access.component').then(m => m.MyAccessComponent)
          },
          {
            path: 'delegation',
            loadComponent: () => import('./components/delegation/delegation.component').then(m => m.DelegationComponent)
          },
          {
            path: 'management',
            loadComponent: () => import('./components/management/management.component').then(m => m.ManagementComponent)
          }
        ]
      }
    ]
  },
  
  // Redirect unknown routes to home
  {
    path: '**',
    redirectTo: ''
  }
];
```

- [ ] Save file
- [ ] Build:

```bash
npm run build
```

### ✅ Checkpoint 3.7: Routes Updated
```bash
Expected: ✔ Built successfully

Status: ✅ All routes protected by MsalGuard
```

**🔍 Debug Log**:
```
Routes Updated:
  ✅ /login is public
  ✅ All other routes use canActivate: [MsalGuard]
  ✅ Unauthenticated users will be redirected to Azure AD
  ✅ Build successful
  
Status: ✅ Ready to test authentication flow
```

---

### ✅ Checkpoint: Phase 3 Complete

**Verification**:
- [ ] MSAL packages installed ✅
- [ ] environment.ts has Azure AD config ✅
- [ ] msal.config.ts created ✅
- [ ] app.config.ts uses MSAL providers ✅
- [ ] app.ts initializes MSAL ✅
- [ ] azure-login component created ✅
- [ ] Routes protected by MsalGuard ✅
- [ ] Project builds successfully ✅

**🔍 Debug Log Expected**:
```
=== PHASE 3 COMPLETE ===
Frontend Configuration:
  ✅ MSAL Angular integrated
  ✅ Azure AD configuration set
  ✅ Login component created
  ✅ Routes protected
  ✅ Build successful
  
Ready for Phase 4: End-to-End Testing
```

---

## 🧪 PHASE 4: End-to-End Testing (4-6 hours)

### Step 4.1: Start Backend with Logging

- [ ] Open terminal 1:

```bash
cd BE/Sakura_Backend/SakuraV2Api/SakuraV2Api
dotnet run --launch-profile https
```

### ✅ Checkpoint 4.1: Backend Running
```
Expected Output:
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:7238
info: Microsoft.Hosting.Lifetime[0]
      Application started.
```

**🔍 Debug Log Expected**:
```
=== BACKEND STARTED ===
Environment: Development
URL: https://localhost:7238
Swagger: https://localhost:7238/swagger
Authentication: Microsoft.Identity.Web (Azure AD)
Status: ✅ Ready to accept requests
```

⚠️ **Keep this terminal open**

---

### Step 4.2: Start Frontend with Logging

- [ ] Open terminal 2:

```bash
cd FE/application
npm start
```

### ✅ Checkpoint 4.2: Frontend Running
```
Expected Output:
✔ Browser application bundle generation complete.
** Angular Live Development Server is listening on localhost:4200
```

**🔍 Debug Log Expected in Browser Console** (after opening http://localhost:4200):
```
=== APP INITIALIZATION ===
MSAL Guard Config: { interactionType: "redirect", authRequest: {...} }
✅ MSAL initialized
=== MSAL INTERCEPTOR CONFIG ===
Protected Resources: [["https://localhost:7238/*", ["api://[your-api-id]/access_as_user"]]]
=== INTERACTION STATUS: None ===
⚠️ No accounts found - user needs to log in
```

⚠️ **Keep this terminal open**

---

### Step 4.3: Test Redirect to Login

- [ ] Open browser: http://localhost:4200
- [ ] Open browser DevTools (F12)
- [ ] Go to Console tab
- [ ] Watch for redirects

### ✅ Checkpoint 4.3: Redirect Works
```
Expected Behavior:
1. Navigate to http://localhost:4200
2. MsalGuard detects no authentication
3. Browser redirects to http://localhost:4200/login
4. Login page shows "Sign in with Microsoft" button
```

**🔍 Debug Log Expected in Console**:
```
=== APP INITIALIZATION ===
✅ MSAL initialized
⚠️ No accounts found - user needs to log in
[MSAL] Interaction required - redirecting to login
```

**Screenshot Checkpoint**: You should see the purple login page with Microsoft button.

---

### Step 4.4: Test Azure AD Login

- [ ] Click "Sign in with Microsoft" button
- [ ] Watch console logs

### ✅ Checkpoint 4.4: Redirect to Azure AD
```
Expected Console Logs:
=== LOGIN BUTTON CLICKED ===
Login Request: {scopes: Array(1), prompt: "select_account"}
Redirecting to Azure AD...
```

**Expected Browser Behavior**:
1. Browser redirects to: `https://login.microsoftonline.com/6e8992ec.../oauth2/v2.0/authorize?...`
2. Azure AD login page appears
3. Shows your organization name (dentsu)

**🔍 Debug Log Expected**:
```
Browser Navigating to:
  https://login.microsoftonline.com/6e8992ec-76d5-4ea5-8eae-b0c5e558749a/oauth2/v2.0/authorize
  ?client_id=[your-frontend-client-id]
  &response_type=code
  &redirect_uri=http://localhost:4200
  &scope=api://[your-api-id]/access_as_user

Status: ✅ Azure AD login page loaded
```

---

### Step 4.5: Complete Azure AD Login

- [ ] Enter your dentsu credentials (email/password)
- [ ] Complete MFA if prompted
- [ ] Watch for redirect back to app

### ✅ Checkpoint 4.5: Login Success
```
Expected Browser Behavior:
1. Azure AD validates credentials
2. Browser redirects back to: http://localhost:4200?code=...
3. MSAL exchanges code for tokens
4. App loads dashboard
```

**🔍 Debug Log Expected in Console**:
```
=== REDIRECT RESPONSE ===
Account: your-email@dentsu.com
Access Token received: true
ID Token received: true
✅ Active account set

=== LOGIN SUCCESS EVENT ===
✅ Account set: your-email@dentsu.com

=== INTERACTION STATUS: None ===
✅ Active account already set: your-email@dentsu.com
```

**Screenshot Checkpoint**: You should see the Sakura dashboard, not the login page.

---

### Step 4.6: Verify Token in API Call

- [ ] In browser DevTools, go to Network tab
- [ ] Navigate to any page (e.g., My Requests)
- [ ] Find a request to `https://localhost:7238/api/v1/...`
- [ ] Click on it
- [ ] Go to Headers tab
- [ ] Look for `Authorization` header

### ✅ Checkpoint 4.6: Token Added to Requests
```
Expected in Network Tab:
Request Headers:
  Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...

(Long token starting with "eyJ")
```

**🔍 Debug Log Expected in Backend Console**:
```
=== AZURE AD TOKEN VALIDATED ===
User: your-email@dentsu.com
  Claim: aud = api://[your-api-id]
  Claim: iss = https://login.microsoftonline.com/6e8992ec.../v2.0
  Claim: preferred_username = your-email@dentsu.com
  Claim: name = Your Name
  Claim: oid = [your-object-id]
  Claim: scp = access_as_user
=== END TOKEN CLAIMS ===
```

**Screenshot Checkpoint**: Take screenshot of:
1. Authorization header in Network tab
2. Backend console showing token validation

---

### Step 4.7: Test API Call Success

- [ ] Navigate to Workspaces page (or any page that calls API)
- [ ] Check browser console for errors
- [ ] Check backend console for logs

### ✅ Checkpoint 4.7: API Calls Work
```
Expected:
Frontend: 
  - No 401 errors
  - Data loads successfully
  
Backend:
  - Token validated
  - Request processed
  - Response returned 200 OK
```

**🔍 Debug Log Expected**:

**Frontend Console**:
```
[API Service] GET /api/v1/workspaces
[API Service] Response 200: {data: Array(6)}
```

**Backend Console**:
```
=== AZURE AD TOKEN VALIDATED ===
User: your-email@dentsu.com
info: Processing GET /api/v1/workspaces
info: Response 200 OK
```

---

### Step 4.8: Test Logout

- [ ] Click user menu in header
- [ ] Click Logout
- [ ] Watch console logs

### ✅ Checkpoint 4.8: Logout Works
```
Expected Behavior:
1. Click logout
2. MSAL clears tokens
3. Browser redirects to Azure AD logout
4. Azure AD clears session
5. Browser redirects back to app
6. App redirects to login page
```

**🔍 Debug Log Expected**:
```
[MSAL] Logging out...
[MSAL] Clearing cache
[MSAL] Redirecting to logout endpoint
Browser navigating to:
  https://login.microsoftonline.com/.../oauth2/v2.0/logout

Then redirecting back to:
  http://localhost:4200/login
```

---

### Step 4.9: Test Login Again

- [ ] Click "Sign in with Microsoft" again
- [ ] Should not ask for credentials (already logged in to Azure AD)

### ✅ Checkpoint 4.9: SSO Works
```
Expected Behavior:
1. Click "Sign in with Microsoft"
2. Redirect to Azure AD
3. Azure AD sees existing session
4. Immediately redirects back with token
5. No credentials needed!
```

**🔍 Debug Log Expected**:
```
=== LOGIN BUTTON CLICKED ===
Redirecting to Azure AD...
[Brief redirect to login.microsoftonline.com]
=== REDIRECT RESPONSE ===
Account: your-email@dentsu.com
✅ Active account set
[Dashboard loads immediately]
```

**This proves SSO is working!** ✅

---

### Step 4.10: Test Token Refresh

- [ ] Stay logged in
- [ ] Wait 5 minutes (or close and reopen browser tab)
- [ ] Navigate to a different page
- [ ] Watch for token refresh

### ✅ Checkpoint 4.10: Token Refresh Works
```
Expected in Console:
[MSAL] Access token expired
[MSAL] Attempting silent token refresh
[MSAL] Token refresh successful
[MSAL] Using new access token
```

**🔍 Debug Log Expected**:
```
[MSAL] Token expiration check
[MSAL] Token expires at: [timestamp]
[MSAL] Time remaining: 45 minutes
[MSAL] Token still valid - no refresh needed

OR (if expired):

[MSAL] Token expired
[MSAL] Calling acquireTokenSilent()
[MSAL] Silent refresh successful
✅ New token acquired
```

---

### ✅ Checkpoint: Phase 4 Complete

**Full Integration Test Checklist**:
- [ ] Backend starts with Azure AD ✅
- [ ] Frontend starts with MSAL ✅
- [ ] Unauthenticated users redirected to login ✅
- [ ] Login button redirects to Azure AD ✅
- [ ] Azure AD login works ✅
- [ ] Tokens received after login ✅
- [ ] Tokens added to API requests ✅
- [ ] Backend validates tokens ✅
- [ ] API calls return data ✅
- [ ] Logout clears session ✅
- [ ] SSO works on second login ✅
- [ ] Token refresh works ✅

**🔍 Debug Log Expected**:
```
=== PHASE 4 COMPLETE ===
Integration Test Results:
  ✅ Authentication flow working end-to-end
  ✅ Tokens issued by Azure AD
  ✅ Backend validates tokens
  ✅ API calls secured
  ✅ SSO working
  ✅ Logout working
  ✅ Token refresh working
  
Status: ✅ Azure AD integration fully functional!
```

---

## 🧹 PHASE 5: Cleanup (2 hours)

### Step 5.1: Remove Old Login Component

- [ ] Delete file: `FE/application/src/app/components/login/login.component.ts`
- [ ] Verify no imports reference it:

```bash
grep -r "from './components/login/login.component'" src/
```

### ✅ Checkpoint 5.1: Old Login Removed
```
Expected: No matches found
Status: ✅ Old login component removed
```

---

### Step 5.2: Remove TempAuthService

- [ ] Delete: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/Services/TempAuthService.cs`
- [ ] Open: `ServiceExtensions.cs`
- [ ] Delete the old `AddAuthenticationServices` method (the temporary JWT one)
- [ ] Remove TempAuthService registration from DI

```bash
cd BE/Sakura_Backend/SakuraV2Api/SakuraV2Api
dotnet build
```

### ✅ Checkpoint 5.2: Temp Auth Removed
```
Expected: Build succeeded. 0 Error(s)
Status: ✅ Temporary auth code removed
```

---

### Step 5.3: Update Old AuthService (Frontend)

The existing `auth.service.ts` is no longer needed for authentication (MSAL handles it), but we can keep it for user info:

- [ ] Open: `FE/application/src/app/services/auth.service.ts`
- [ ] Rename to: `user.service.ts`
- [ ] Update to use MSAL for user info:

```typescript
import { Injectable } from '@angular/core';
import { Observable, from } from 'rxjs';
import { map } from 'rxjs/operators';
import { MsalService } from '@azure/msal-angular';
import { AccountInfo } from '@azure/msal-browser';

/**
 * User Service
 * Wraps MSAL to provide user information
 */
@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private msalService: MsalService) {}

  /**
   * Get current user account
   */
  getCurrentUser(): AccountInfo | null {
    return this.msalService.instance.getActiveAccount();
  }

  /**
   * Get user email/UPN
   */
  getUserEmail(): string | null {
    const account = this.getCurrentUser();
    return account?.username || null;
  }

  /**
   * Get user display name
   */
  getUserName(): string | null {
    const account = this.getCurrentUser();
    return account?.name || null;
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return this.getCurrentUser() !== null;
  }

  /**
   * Login (redirect to Azure AD)
   */
  login(): void {
    this.msalService.loginRedirect();
  }

  /**
   * Logout (clears session)
   */
  logout(): void {
    this.msalService.logoutRedirect();
  }
}
```

- [ ] Update components that use `AuthService` to use `UserService`
- [ ] Build to verify:

```bash
npm run build
```

### ✅ Checkpoint 5.3: Services Refactored
```
Expected: ✔ Built successfully
Status: ✅ Auth logic now fully managed by MSAL
```

---

### Step 5.4: Remove JWT Config from appsettings.json

- [ ] Open: `BE/Sakura_Backend/SakuraV2Api/SakuraV2Api/appsettings.json`
- [ ] Remove or comment out the `Jwt` section:

```json
{
  "Logging": { /* keep */ },
  "ConnectionStrings": { /* keep */ },
  
  "AzureAd": { /* keep - this is active */ },
  
  // OLD - No longer used
  // "Jwt": {
  //   "SecretKey": "...",
  //   "Issuer": "...",
  //   "Audience": "..."
  // },
  
  "CorsSettings": { /* keep */ },
  "AppSettings": { /* keep */ }
}
```

- [ ] Save and restart backend

### ✅ Checkpoint 5.4: Config Cleaned
```
Status: ✅ Only Azure AD config remains
```

---

### Step 5.5: Update Documentation

- [ ] Create: `docs/AZURE-AD-MIGRATION-COMPLETE.md`

```markdown
# ✅ Azure AD Migration Complete

## Date: [Today's Date]
## Status: Production Ready

### Changes Made
- ✅ Replaced temporary JWT with Azure AD
- ✅ Integrated Microsoft.Identity.Web (backend)
- ✅ Integrated MSAL Angular (frontend)
- ✅ Removed old auth components
- ✅ Tested end-to-end authentication

### Configuration
- **Tenant ID**: 6e8992ec-76d5-4ea5-8eae-b0c5e558749a
- **Backend API App**: [Your Client ID]
- **Frontend SPA App**: [Your Client ID]
- **API Scope**: api://[your-api-id]/access_as_user

### Testing Completed
- [x] Login redirects to Azure AD
- [x] Tokens received after login
- [x] API calls include token
- [x] Backend validates tokens
- [x] SSO works
- [x] Logout works
- [x] Token refresh works

### Next Steps
- [ ] Test with multiple users
- [ ] Test role-based authorization
- [ ] Deploy to Azure (update redirect URIs)
- [ ] Enable production logging
```

- [ ] Save file

---

### ✅ Checkpoint: Phase 5 Complete

**Cleanup Checklist**:
- [ ] Old login component removed ✅
- [ ] TempAuthService removed ✅
- [ ] Auth service refactored ✅
- [ ] JWT config removed ✅
- [ ] Documentation updated ✅

**🔍 Debug Log Expected**:
```
=== PHASE 5 COMPLETE ===
Cleanup Summary:
  ✅ Old authentication code removed
  ✅ Only Azure AD code remains
  ✅ Project builds successfully
  ✅ All tests passing
  
Status: ✅ Ready for production deployment
```

---

## 🎉 FINAL VERIFICATION

### Complete Integration Test

- [ ] **Test 1: Fresh Browser (Incognito)**
  - Open incognito window
  - Go to http://localhost:4200
  - Should redirect to login
  - Click "Sign in with Microsoft"
  - Login with Azure AD
  - Should see dashboard
  - **✅ PASS**

- [ ] **Test 2: API Authorization**
  - Navigate to My Requests
  - Check Network tab - token present
  - Check backend logs - token validated
  - Data loads successfully
  - **✅ PASS**

- [ ] **Test 3: Logout**
  - Click logout
  - Should return to login page
  - Try accessing /dashboard directly
  - Should redirect back to login
  - **✅ PASS**

- [ ] **Test 4: Token Expiry**
  - Wait 1 hour (or manipulate token expiry)
  - Make an API call
  - Should automatically refresh token
  - API call succeeds
  - **✅ PASS**

- [ ] **Test 5: Multiple Tabs**
  - Login in tab 1
  - Open tab 2 (same browser)
  - Tab 2 should automatically be logged in
  - **✅ PASS**

### ✅ Final Checkpoint: ALL TESTS PASSED

```
=== AZURE AD INTEGRATION COMPLETE ===

Test Results:
  ✅ Authentication: WORKING
  ✅ Authorization: WORKING
  ✅ SSO: WORKING
  ✅ Logout: WORKING
  ✅ Token Refresh: WORKING
  ✅ Multi-tab: WORKING

Time Taken: [Your actual time]
Status: 🎉 PRODUCTION READY
```

---

## 📊 Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Backend build | Success | ✅ | Pass |
| Frontend build | Success | ✅ | Pass |
| Login flow | < 5 sec | ✅ | Pass |
| Token validation | 100% | ✅ | Pass |
| API calls secured | 100% | ✅ | Pass |
| Tests passing | 100% | ✅ | Pass |

---

## 🐛 Troubleshooting Guide

### Problem: "AADSTS50011: Redirect URI mismatch"

**Solution**:
- Check Azure AD app registration
- Verify redirect URI is EXACTLY: `http://localhost:4200` (no trailing slash)
- Check environment.ts has same redirect URI

### Problem: "AADSTS700016: Application not found"

**Solution**:
- Check Client ID in environment.ts matches Frontend app registration
- Check Tenant ID is correct

### Problem: Backend returns 401 after login

**Solution**:
- Check Network tab - is Authorization header present?
- Check backend logs - what error in token validation?
- Verify API Client ID in appsettings.json matches Backend app registration
- Verify Audience in appsettings.json is `api://[backend-client-id]`

### Problem: "Failed to acquire token silently"

**Solution**:
- Check scopes in environment.ts
- Verify admin consent was granted
- Try logout and login again

---

## 📝 Next Steps After Completion

1. **Test with Different Users**
   - Login as different dentsu employees
   - Verify roles are assigned correctly
   - Test approver assignments

2. **Implement Role-Based Authorization**
   - Map Azure AD groups to Sakura roles
   - Implement hybrid authorization (claims + database)
   - Test admin-only endpoints

3. **Production Deployment**
   - Update redirect URIs for production domain
   - Configure Azure Key Vault for secrets
   - Enable production logging
   - Deploy to Azure App Service + Static Web App

4. **Monitoring**
   - Set up Application Insights
   - Monitor failed login attempts
   - Track token refresh rates
   - Alert on authentication failures

---

## ✅ Completion Certificate

```
╔════════════════════════════════════════════════════════╗
║                                                        ║
║       🎉 AZURE AD INTEGRATION COMPLETE 🎉             ║
║                                                        ║
║   Sakura V2 now uses enterprise-grade authentication  ║
║                                                        ║
║   ✅ Microsoft Identity Platform                      ║
║   ✅ Single Sign-On (SSO)                             ║
║   ✅ Multi-Factor Authentication                      ║
║   ✅ Secure Token Management                          ║
║   ✅ Production Ready                                 ║
║                                                        ║
║   Completed by: ________________                      ║
║   Date: ________________                              ║
║   Time taken: _______ hours                           ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

---

**🚀 You did it! Sakura V2 is now secured with Azure AD!**

