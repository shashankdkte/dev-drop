# Frontend Architecture Guide

## Overview
This Angular 20 application follows a **Domain-Driven Design (DDD)** architecture with clear separation of concerns, enabling parallel development by multiple teams. The architecture supports both Azure MSAL and JWT authentication, with automatic data transformation between frontend (camelCase) and backend (PascalCase).

---

## 📁 Directory Structure

### Root Level
- **`app.config.ts`** - Application configuration with providers (HTTP, routing, MSAL, PrimeNG)
- **`app.routes.ts`** - Route definitions for all application pages
- **`app.ts`** - Root component that bootstraps the application
- **`main.ts`** - Application entry point, initializes Angular app

---

## 🔧 Core Layer (`/core`)

### API (`/core/api`)
- **`api.service.ts`** - Base HTTP service handling all backend communication, automatic camelCase↔PascalCase transformation, caching, error handling, supports both BE and BE_Main backends
- **`api-response.model.ts`** - TypeScript interfaces for API response structures (PagedResponse, ApiResponse)

### Auth (`/core/auth`)
- **`auth.service.ts`** - Authentication service managing user sessions, tokens, and user info
- **`guards/auth.guard.ts`** - Route guard protecting authenticated routes
- **`guards/admin.guard.ts`** - Route guard protecting admin-only routes

### Cache (`/core/cache`)
- **`cache.service.ts`** - In-memory cache service for API responses with TTL support and pattern-based invalidation

### Interceptors (`/core/interceptors`)
- **`auth.interceptor.ts`** - Adds JWT tokens to HTTP requests (when Azure Auth disabled)
- **`error.interceptor.ts`** - Global error handler transforming backend errors to user-friendly messages
- **`loading.interceptor.ts`** - Tracks HTTP request timing and manages loading states

---

## 🎯 Domain Layer (`/domains`)

Each domain follows the pattern: `/data` (services/models) and `/feature` (components)

### Access Domain (`/domains/access`)
- **`data/access-domain.service.ts`** - Service for managing user access records and access details
- **`data/access-domain.model.ts`** - TypeScript models for access-related data structures
- **`feature/my-access/`** - Component displaying user's current access grants
- **`feature/access-detail/`** - Component showing detailed access information for a specific grant

### Approval Domain (`/domains/approval`)
- **`data/approval-domain.service.ts`** - Service handling approval workflows, decisions, and approval management
- **`feature/approval-management/`** - Component for managing pending approvals and making approval decisions

### Catalogue Domain (`/domains/catalogue`)
- **`data/catalogue-domain.service.ts`** - Service for browsing and searching catalog items (Reports, Apps, Audiences)
- **`data/catalogue-domain.model.ts`** - Models for catalog items and search results
- **`feature/catalogue/`** - Component displaying catalog items with search and filter capabilities

### Delegation Domain (`/domains/delegation`)
- **`data/delegation-domain.service.ts`** - Service managing delegation of approval authority to other users
- **`data/delegation-domain.model.ts`** - Models for delegation records
- **`feature/delegation-management/`** - Component for creating and managing delegations

### Home Domain (`/domains/home`)
- **`data/home-domain.model.ts`** - Models for dashboard/home page data
- **`feature/home/`** - Landing page component with dashboard widgets and quick actions

### Request Domain (`/domains/request`)
- **`data/request-domain.service.ts`** - Service for creating, viewing, and managing access requests (OLS/RLS)
- **`data/request-domain.model.ts`** - Models for requests, approvals, and request lifecycle
- **`feature/my-requests/`** - Component listing user's submitted requests
- **`feature/request-detail/`** - Component showing detailed request information
- **`feature/request-form/`** - Component for creating new access requests
- **`feature/request-form-scope/`** - Component for advanced request creation with scope selection
- **`feature/request-escalated/`** - Component displaying escalated requests requiring attention

### Workspace Domain (`/domains/workspace`)
- **`data/workspace-domain.service.ts`** - Service managing workspaces (CRUD operations, search, filtering)
- **`data/workspace-domain.model.ts`** - Models for workspace entities
- **`data/workspace-report-domain.service.ts`** - Service for workspace-specific report management
- **`data/workspace-report-domain.model.ts`** - Models for workspace reports
- **`feature/workspace-management/`** - Component for managing workspaces, apps, and reports within workspaces

### WSO Domain (`/domains/wso`) - Workspace Security Objects
- **`data/wso-domain.service.ts`** - Facade service delegating to all WSO sub-services (main entry point)
- **`data/wso-domain.model.ts`** - Comprehensive models for all WSO entities (Apps, Reports, Audiences, Security Models, etc.)
- **`data/wso-domain-app.service.ts`** - Service for managing App configurations
- **`data/wso-domain-audience.service.ts`** - Service for managing Audience configurations
- **`data/wso-domain-report.service.ts`** - Service for managing Standalone Report (SAR) configurations
- **`data/wso-domain-security-model.service.ts`** - Service for managing Security Models and their dimensions
- **`data/wso-domain-dimension.service.ts`** - Service for managing Security Dimensions
- **`data/wso-domain-assignment.service.ts`** - Service for managing Approver Assignments
- **`data/wso-domain-access.service.ts`** - Service for managing Access Records and grants
- **`data/wso-domain-audit.service.ts`** - Service for retrieving audit logs
- **`feature/wso-console/`** - Main WSO console component with tabbed navigation
  - **`wso-object-management/`** - Component for managing Apps, Reports, Audiences, and Mappings
    - **`wso-app-list/`** - Component displaying list of apps with CRUD operations
    - **`wso-add-app-form/`** - Component for creating/editing app configurations
    - **`wso-report-list/`** - Component displaying list of standalone reports
    - **`wso-add-sar-form/`** - Component for creating/editing standalone report configurations
    - **`wso-audience-list/`** - Component displaying list of audiences
    - **`wso-add-audience-form/`** - Component for creating/editing audience configurations
    - **`wso-mapping-list/`** - Component for managing app-to-report mappings
    - **`wso-dynamic-questions-editor/`** - Component for editing dynamic questions for requests
  - **`wso-security-models/`** - Component for managing security models
    - **`add-security-model-form/`** - Component for creating/editing security models
    - **`add-dimension-form/`** - Component for adding dimensions to security models
  - **`wso-approver-assignments/`** - Component for managing approver assignments
  - **`wso-access-management/`** - Component for viewing and managing access grants
  - **`wso-audit-logs/`** - Component displaying audit log entries with filtering

---

## 🎨 Shared Layer (`/shared`)

### Layout (`/shared/layout`)
- **`layout/layout.component.ts`** - Main layout wrapper with header, sidebar, and router outlet
- **`header/header.component.ts`** - Top navigation bar with user menu, notifications, theme switcher
- **`sidebar/sidebar.component.ts`** - Left navigation menu with route links

### Services (`/shared/services`)
- **`lov.service.ts`** - Service for managing List of Values (dropdown options, reference data)
- **`theme.service.ts`** - Service managing application theme (light/dark mode)
- **`toast.service.ts`** - Service for displaying toast notifications
- **`notification.service.ts`** - Service for managing user notifications
- **`universal-modal.service.ts`** - Service for displaying modal dialogs
- **`error-handler.service.ts`** - Centralized error handling and logging
- **`mock-data.service.ts`** - Service providing mock data when `environment.mockMode` is enabled

### Models (`/shared/models`)
- **`lov.model.ts`** - Models for List of Values entities
- **`security.model.ts`** - Models for security-related entities (dimensions, selections)
- **`dynamic-question.model.ts`** - Models for dynamic form questions
- **`user.model.ts`** - Models for user entities

### UI Components (`/shared/ui`)
- **`ui-modal/`** - Reusable modal dialog component
- **`ui-toast/`** - Toast notification component
- **`ui-loading-overlay/`** - Loading spinner overlay component
- **`ui-notification-panel/`** - Notification panel component
- **`ui-theme-switcher/`** - Theme toggle component
- **`ui-custom-select/`** - Custom dropdown select component
- **`ui-multi-email-input/`** - Multi-email input component
- **`ui-azure-login/`** - Azure MSAL login component
- **`ui-login/`** - JWT login component

### Utils (`/shared/utils`)
- **`property-mapper.util.ts`** - Utilities for mapping object properties between formats
- **`response-mapper.util.ts`** - Utilities for transforming API responses

---

## ⚙️ Configuration (`/config`)

- **`backend-endpoints.config.ts`** - Maps generic endpoints to backend-specific paths (BE vs BE_Main), handles path parameter substitution
- **`msal.config.ts`** - Azure MSAL configuration factories for authentication setup

---

## 🔄 Data Flow Architecture

### Request Flow
1. **Component** → Calls domain service method
2. **Domain Service** → Calls `ApiService` with endpoint
3. **ApiService** → Transforms camelCase → PascalCase, makes HTTP request
4. **Interceptor** → Adds auth token, handles errors, tracks loading
5. **Backend** → Returns PascalCase response
6. **ApiService** → Transforms PascalCase → camelCase, caches response
7. **Domain Service** → Returns Observable to component
8. **Component** → Updates UI with data

### Adding New Features

#### 1. Add New Domain
```
/domains/new-domain/
  /data/
    - new-domain.service.ts      // Service calling ApiService
    - new-domain.model.ts        // TypeScript interfaces
    - index.ts                   // Barrel export
  /feature/
    - new-feature/               // Component folder
      - new-feature.component.ts
      - new-feature.component.html
      - new-feature.component.css
    - index.ts                   // Barrel export
  - index.ts                     // Barrel export
```

#### 2. Add New Endpoint
1. Add endpoint mapping to `backend-endpoints.config.ts`
2. Add method to domain service calling `apiService.get/post/put/delete()`
3. Use in component via domain service

#### 3. Add New Route
1. Add route to `app.routes.ts`
2. Import component in route file
3. Add navigation link in `sidebar.component.ts` if needed

#### 4. Add New Shared Component
1. Create component in `/shared/ui/`
2. Export from `/shared/ui/index.ts`
3. Use in any feature component

---

## 🛠️ Key Patterns

### Service Pattern
- All domain services inject `ApiService`
- Services return `Observable<T>` for async operations
- Services handle data transformation and business logic
- Services support both mock mode and real API mode

### Component Pattern
- Components are standalone (Angular 20)
- Components inject domain services, not `ApiService` directly
- Components use reactive forms and PrimeNG components
- Components handle UI state and user interactions

### Model Pattern
- Models are TypeScript interfaces/classes
- Models use camelCase (frontend convention)
- Models match backend structure after transformation
- Models are exported via barrel files (`index.ts`)

### Caching Pattern
- GET requests are cached by default
- POST/PUT/PATCH/DELETE invalidate related cache
- Cache keys based on method + URL + params
- Cache TTL configurable via `CacheService`

### Error Handling Pattern
- Errors caught by `error.interceptor.ts`
- Errors transformed to user-friendly messages
- Errors displayed via `toast.service.ts`
- Validation errors shown in forms

---

## 🔐 Authentication

### Azure MSAL (when `environment.enableAzureAuth = true`)
- Uses `@azure/msal-angular` library
- Configured in `msal.config.ts`
- Protected routes use `MsalGuard`
- Tokens added automatically via `MsalInterceptor`

### JWT (when `environment.enableAzureAuth = false`)
- Uses `auth.interceptor.ts` to add tokens
- Tokens stored via `AuthService`
- Protected routes use `authGuard`

---

## 📦 Dependencies

### Core
- **Angular 20** - Framework
- **RxJS 7.8** - Reactive programming
- **PrimeNG 20.2** - UI component library
- **PrimeIcons** - Icon library

### Auth
- **@azure/msal-angular** - Azure authentication
- **@azure/msal-browser** - MSAL browser support

### Utilities
- **lucide-angular** - Icon library
- **@primeuix/themes** - PrimeNG theme system

---

## 🚀 Development Guidelines

### Code Organization
- **One feature per domain** - Each domain is self-contained
- **Barrel exports** - Use `index.ts` for clean imports
- **Path aliases** - Use `@core`, `@shared`, `@domains` for imports
- **Standalone components** - All components are standalone

### Naming Conventions
- **Files**: `kebab-case.component.ts`
- **Classes**: `PascalCase`
- **Variables/Methods**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Interfaces**: `PascalCase` (no `I` prefix)

### Adding New Functionality
1. **Identify domain** - Which domain does this belong to?
2. **Create/update service** - Add methods to domain service
3. **Create/update models** - Define TypeScript interfaces
4. **Create/update component** - Build UI component
5. **Add route** - Register in `app.routes.ts`
6. **Add endpoint mapping** - Update `backend-endpoints.config.ts`
7. **Test** - Verify in both mock and real API modes

### Parallel Development
- **Domain isolation** - Teams can work on different domains independently
- **Shared contracts** - Models and services define clear contracts
- **No cross-domain dependencies** - Domains don't import from each other
- **Shared layer** - Common utilities in `/shared` for all teams

---

## 🔍 Debugging

### Enable Logging
Set `environment.enableLogging = true` to see:
- API request/response logs
- Cache hits/misses
- Service initialization
- Error details

### Common Issues
- **CamelCase/PascalCase mismatch** - Check `ApiService` transformation
- **Cache stale data** - Call `apiService.invalidateCache(endpoint)`
- **Auth errors** - Check interceptor and guard configuration
- **Route not found** - Verify route in `app.routes.ts` and component import

---

## 📝 Notes

- **Mock Mode**: Set `environment.mockMode = true` to use in-memory data
- **Backend Types**: Supports both `BE` (Sakura_Backend) and `BE_Main` (Dentsu.SakuraApi)
- **Data Transformation**: Automatic camelCase ↔ PascalCase conversion
- **Caching**: GET requests cached, mutations invalidate cache
- **Error Handling**: Global error interceptor with user-friendly messages
- **Theming**: PrimeNG Aura theme with dark mode support
- **Standalone**: All components use Angular standalone architecture

---

## 🎯 Quick Reference

### Import Paths
```typescript
import { ApiService } from '@core/api';
import { AuthService } from '@core/auth';
import { LoVService } from '@shared/services';
import { WorkspaceDomainService } from '@domains/workspace/data';
import { MyRequestsComponent } from '@domains/request/feature';
```

### Common Service Methods
```typescript
// Domain Service
this.apiService.get<T>(endpoint, params, pathParams, useCache)
this.apiService.post<T>(endpoint, body, pathParams)
this.apiService.put<T>(endpoint, body, pathParams)
this.apiService.delete<T>(endpoint, pathParams)
```

### Component Template
```typescript
@Component({
  selector: 'app-feature',
  standalone: true,
  imports: [CommonModule, FormsModule, /* ... */],
  templateUrl: './feature.component.html'
})
export class FeatureComponent {
  constructor(private domainService: DomainService) {}
}
```

---

*Last Updated: After Frontend Migration*
*Architecture: Domain-Driven Design with Standalone Components*
*Framework: Angular 20 with PrimeNG*
