# Sakura V2 - Frontend Integration Guide

> **Framework**: Angular 18.x  
> **Language**: TypeScript 5.x  
> **State Management**: RxJS + Services  
> **Styling**: Custom CSS + CSS Variables

---

## 📑 Table of Contents

1. [Angular Project Structure](#angular-project-structure)
2. [HTTP Client Configuration](#http-client-configuration)
3. [Authentication Integration](#authentication-integration)
4. [State Management with Services](#state-management-with-services)
5. [API Service Layer](#api-service-layer)
6. [Component Communication](#component-communication)
7. [Routing & Guards](#routing--guards)
8. [Error Handling](#error-handling)
9. [Performance Optimization](#performance-optimization)

---

## 📁 Angular Project Structure

```
src/
├── app/
│   ├── core/                         # Singleton services, guards, interceptors
│   │   ├── interceptors/
│   │   │   ├── auth.interceptor.ts
│   │   │   ├── error.interceptor.ts
│   │   │   └── loading.interceptor.ts
│   │   ├── guards/
│   │   │   ├── auth.guard.ts
│   │   │   ├── role.guard.ts
│   │   │   └── workspace-admin.guard.ts
│   │   └── services/
│   │       ├── auth.service.ts
│   │       └── api.service.ts
│   │
│   ├── shared/                       # Shared components, directives, pipes
│   │   ├── components/
│   │   │   ├── loading-overlay/
│   │   │   ├── toast-container/
│   │   │   └── universal-modal/
│   │   ├── directives/
│   │   └── pipes/
│   │
│   ├── features/                     # Feature modules
│   │   ├── requests/
│   │   │   ├── components/
│   │   │   ├── services/
│   │   │   ├── models/
│   │   │   └── requests-routing.module.ts
│   │   ├── approvals/
│   │   ├── catalogue/
│   │   ├── admin/
│   │   └── workspace/
│   │
│   ├── models/                       # TypeScript interfaces/types
│   │   ├── request.model.ts
│   │   ├── user.model.ts
│   │   ├── workspace.model.ts
│   │   └── security.model.ts
│   │
│   ├── services/                     # Application-wide services
│   │   ├── request.service.ts
│   │   ├── workspace.service.ts
│   │   ├── notification.service.ts
│   │   └── theme.service.ts
│   │
│   ├── app.routes.ts
│   ├── app.config.ts
│   └── app.ts
│
├── environments/
│   ├── environment.ts
│   └── environment.prod.ts
│
└── styles.css
```

---

## 🌐 HTTP Client Configuration

### Environment Configuration

**src/environments/environment.ts**:
```typescript
export const environment = {
  production: false,
  apiUrl: 'https://localhost:5001/api/v1',
  oktaConfig: {
    issuer: 'https://{yourOktaDomain}/oauth2/default',
    clientId: '{yourClientId}',
    redirectUri: window.location.origin + '/login/callback',
    scopes: ['openid', 'profile', 'email'],
  }
};
```

**src/environments/environment.prod.ts**:
```typescript
export const environment = {
  production: true,
  apiUrl: 'https://api.sakura.dentsu.com/api/v1',
  oktaConfig: {
    issuer: 'https://dentsu.okta.com/oauth2/default',
    clientId: 'prod-client-id',
    redirectUri: 'https://sakura.dentsu.com/login/callback',
    scopes: ['openid', 'profile', 'email'],
  }
};
```

### HTTP Interceptors

**Auth Interceptor** (add JWT token to requests):
```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getAccessToken();

  if (token && !req.url.includes('/auth/')) {
    const authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
    return next(authReq);
  }

  return next(req);
};
```

**Error Interceptor** (handle API errors):
```typescript
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { ToastService } from '../services/toast.service';
import { Router } from '@angular/router';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toastService = inject(ToastService);
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      let errorMessage = 'An error occurred';

      if (error.error instanceof ErrorEvent) {
        // Client-side error
        errorMessage = `Error: ${error.error.message}`;
      } else {
        // Server-side error
        errorMessage = error.error?.error || error.message;

        // Handle specific status codes
        switch (error.status) {
          case 401:
            toastService.error('Authentication required. Please log in.');
            router.navigate(['/login']);
            break;
          case 403:
            toastService.error('You do not have permission to perform this action.');
            break;
          case 404:
            toastService.error('Resource not found.');
            break;
          case 500:
            toastService.error('Server error. Please try again later.');
            break;
          default:
            toastService.error(errorMessage);
        }
      }

      console.error('HTTP Error:', error);
      return throwError(() => error);
    })
  );
};
```

**Loading Interceptor** (show/hide loading overlay):
```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { finalize } from 'rxjs';
import { LoadingService } from '../services/loading.service';

export const loadingInterceptor: HttpInterceptorFn = (req, next) => {
  const loadingService = inject(LoadingService);

  // Don't show loading for certain requests
  if (req.url.includes('/health') || req.url.includes('/ping')) {
    return next(req);
  }

  loadingService.show();

  return next(req).pipe(
    finalize(() => loadingService.hide())
  );
};
```

### App Configuration

**src/app/app.config.ts**:
```typescript
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { errorInterceptor } from './core/interceptors/error.interceptor';
import { loadingInterceptor } from './core/interceptors/loading.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([
        authInterceptor,
        errorInterceptor,
        loadingInterceptor
      ])
    )
  ]
};
```

---

## 🔐 Authentication Integration

### Auth Service

**src/app/core/services/auth.service.ts**:
```typescript
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, BehaviorSubject, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User } from '../../models/user.model';

export interface AuthResponse {
  accessToken: string;
  expiresIn: number;
  user: User;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly TOKEN_KEY = 'sakura_access_token';
  private readonly USER_KEY = 'sakura_user';
  
  private currentUserSubject = new BehaviorSubject<User | null>(this.getUserFromStorage());
  public currentUser$ = this.currentUserSubject.asObservable();
  
  // Signal for reactive UI updates
  public isAuthenticated = signal(this.hasToken());

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  login(redirectUrl?: string): void {
    // Redirect to Okta login
    const state = redirectUrl || '/';
    window.location.href = `${environment.oktaConfig.issuer}/v1/authorize?` +
      `client_id=${environment.oktaConfig.clientId}&` +
      `response_type=code&` +
      `scope=${environment.oktaConfig.scopes.join(' ')}&` +
      `redirect_uri=${environment.oktaConfig.redirectUri}&` +
      `state=${encodeURIComponent(state)}`;
  }

  handleCallback(code: string, state: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/callback`, {
      code,
      redirectUri: environment.oktaConfig.redirectUri
    }).pipe(
      tap(response => {
        this.setSession(response);
        this.router.navigateByUrl(state || '/');
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.USER_KEY);
    this.currentUserSubject.next(null);
    this.isAuthenticated.set(false);
    this.router.navigate(['/login']);
  }

  refreshToken(): Observable<AuthResponse> {
    const refreshToken = localStorage.getItem('sakura_refresh_token');
    return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/refresh`, {
      refreshToken
    }).pipe(
      tap(response => this.setSession(response))
    );
  }

  getAccessToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    return user?.roles?.includes(role) || false;
  }

  isWorkspaceAdmin(workspaceId?: number): boolean {
    const user = this.getCurrentUser();
    if (!user) return false;

    if (this.hasRole('Sakura Administrator')) return true;

    if (workspaceId) {
      // Check if user is owner or tech owner of this workspace
      // This would require additional API call or cached workspace info
      return user.managedWorkspaces?.includes(workspaceId) || false;
    }

    return this.hasRole('Workspace Admin');
  }

  private setSession(authResponse: AuthResponse): void {
    localStorage.setItem(this.TOKEN_KEY, authResponse.accessToken);
    localStorage.setItem(this.USER_KEY, JSON.stringify(authResponse.user));
    this.currentUserSubject.next(authResponse.user);
    this.isAuthenticated.set(true);

    // Set token expiry for auto-refresh
    const expiresAt = Date.now() + (authResponse.expiresIn * 1000);
    localStorage.setItem('sakura_token_expires', expiresAt.toString());
  }

  private hasToken(): boolean {
    return !!this.getAccessToken();
  }

  private getUserFromStorage(): User | null {
    const userJson = localStorage.getItem(this.USER_KEY);
    return userJson ? JSON.parse(userJson) : null;
  }
}
```

### Auth Guard

**src/app/core/guards/auth.guard.ts**:
```typescript
import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  // Store the attempted URL for redirecting
  authService.login(state.url);
  return false;
};
```

### Role Guard

**src/app/core/guards/role.guard.ts**:
```typescript
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    const user = authService.getCurrentUser();

    if (!user) {
      router.navigate(['/login']);
      return false;
    }

    const hasRole = allowedRoles.some(role => authService.hasRole(role));

    if (!hasRole) {
      router.navigate(['/unauthorized']);
      return false;
    }

    return true;
  };
};

// Usage in routes:
// { 
//   path: 'admin', 
//   canActivate: [authGuard, roleGuard(['Sakura Administrator'])]
// }
```

---

## 📡 API Service Layer

### Base API Service

**src/app/core/services/api.service.ts**:
```typescript
import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface PagedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    totalItems: number;
    totalPages: number;
    hasNext: boolean;
    hasPrevious: boolean;
  };
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  get<T>(endpoint: string, params?: any): Observable<T> {
    const httpParams = this.buildParams(params);
    return this.http.get<T>(`${this.apiUrl}/${endpoint}`, { params: httpParams });
  }

  post<T>(endpoint: string, body: any): Observable<T> {
    return this.http.post<T>(`${this.apiUrl}/${endpoint}`, body);
  }

  put<T>(endpoint: string, body: any): Observable<T> {
    return this.http.put<T>(`${this.apiUrl}/${endpoint}`, body);
  }

  delete<T>(endpoint: string): Observable<T> {
    return this.http.delete<T>(`${this.apiUrl}/${endpoint}`);
  }

  private buildParams(params?: any): HttpParams {
    let httpParams = new HttpParams();

    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== null && params[key] !== undefined) {
          httpParams = httpParams.append(key, params[key].toString());
        }
      });
    }

    return httpParams;
  }
}
```

### Feature-Specific Service: Request Service

**src/app/services/request.service.ts**:
```typescript
import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject, tap } from 'rxjs';
import { ApiService, PagedResponse } from '../core/services/api.service';
import { 
  Request, 
  CreateRequestDto, 
  MyRequestsDto,
  RequestDetailDto 
} from '../models/request.model';

@Injectable({
  providedIn: 'root'
})
export class RequestService {
  private requestsSubject = new BehaviorSubject<MyRequestsDto[]>([]);
  public requests$ = this.requestsSubject.asObservable();

  constructor(private api: ApiService) {}

  createRequest(dto: CreateRequestDto): Observable<RequestDetailDto> {
    return this.api.post<RequestDetailDto>('requests', dto).pipe(
      tap(() => this.refreshMyRequests())
    );
  }

  getMyRequests(
    page: number = 1,
    pageSize: number = 20,
    status?: string,
    workspaceId?: number
  ): Observable<PagedResponse<MyRequestsDto>> {
    const params = {
      page,
      pageSize,
      ...(status && { status }),
      ...(workspaceId && { workspaceId })
    };

    return this.api.get<PagedResponse<MyRequestsDto>>('requests/my-requests', params).pipe(
      tap(response => this.requestsSubject.next(response.data))
    );
  }

  getRequestById(id: number): Observable<RequestDetailDto> {
    return this.api.get<RequestDetailDto>(`requests/${id}`);
  }

  getRequestHistory(id: number): Observable<any> {
    return this.api.get(`requests/${id}/history`);
  }

  private refreshMyRequests(): void {
    this.getMyRequests().subscribe();
  }
}
```

### Workspace Service

**src/app/services/workspace.service.ts**:
```typescript
import { Injectable } from '@angular/core';
import { Observable, BehaviorSubject, shareReplay } from 'rxjs';
import { ApiService, PagedResponse } from '../core/services/api.service';
import { Workspace, WorkspaceDetail } from '../models/workspace.model';

@Injectable({
  providedIn: 'root'
})
export class WorkspaceService {
  private workspacesCache$?: Observable<Workspace[]>;

  constructor(private api: ApiService) {}

  getWorkspaces(forceRefresh: boolean = false): Observable<Workspace[]> {
    if (!this.workspacesCache$ || forceRefresh) {
      this.workspacesCache$ = this.api.get<PagedResponse<Workspace>>('workspaces', {
        pageSize: 100
      }).pipe(
        map(response => response.data),
        shareReplay(1) // Cache the result
      );
    }

    return this.workspacesCache$;
  }

  getWorkspaceById(id: number): Observable<WorkspaceDetail> {
    return this.api.get<WorkspaceDetail>(`workspaces/${id}`);
  }

  getWorkspaceApps(workspaceId: number): Observable<any> {
    return this.api.get(`workspaces/${workspaceId}/apps`);
  }

  createWorkspace(workspace: Partial<Workspace>): Observable<Workspace> {
    return this.api.post<Workspace>('workspaces', workspace).pipe(
      tap(() => this.workspacesCache$ = undefined) // Invalidate cache
    );
  }

  updateWorkspace(id: number, workspace: Partial<Workspace>): Observable<Workspace> {
    return this.api.put<Workspace>(`workspaces/${id}`, workspace).pipe(
      tap(() => this.workspacesCache$ = undefined)
    );
  }
}
```

---

## 🔄 State Management with Services

### Notification Service (Toast)

**src/app/services/notification.service.ts**:
```typescript
import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

export interface Toast {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private toastSubject = new Subject<Toast>();
  public toast$ = this.toastSubject.asObservable();

  success(message: string, duration: number = 5000): void {
    this.show('success', message, duration);
  }

  error(message: string, duration: number = 7000): void {
    this.show('error', message, duration);
  }

  warning(message: string, duration: number = 5000): void {
    this.show('warning', message, duration);
  }

  info(message: string, duration: number = 5000): void {
    this.show('info', message, duration);
  }

  private show(type: Toast['type'], message: string, duration: number): void {
    const toast: Toast = {
      id: this.generateId(),
      type,
      message,
      duration
    };

    this.toastSubject.next(toast);
  }

  private generateId(): string {
    return `toast-${Date.now()}-${Math.random()}`;
  }
}
```

### Loading Service

**src/app/services/loading.service.ts**:
```typescript
import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class LoadingService {
  private loadingCount = 0;
  public isLoading = signal(false);

  show(): void {
    this.loadingCount++;
    this.isLoading.set(true);
  }

  hide(): void {
    this.loadingCount = Math.max(0, this.loadingCount - 1);
    
    if (this.loadingCount === 0) {
      // Small delay to prevent flicker
      setTimeout(() => {
        if (this.loadingCount === 0) {
          this.isLoading.set(false);
        }
      }, 100);
    }
  }

  reset(): void {
    this.loadingCount = 0;
    this.isLoading.set(false);
  }
}
```

---

## 🎨 Component Communication Patterns

### Parent-Child Communication

**Parent Component**:
```typescript
@Component({
  selector: 'app-request-list',
  template: `
    <app-request-item
      *ngFor="let request of requests"
      [request]="request"
      (requestClicked)="onRequestClick($event)"
      (approveClicked)="onApprove($event)"
    />
  `
})
export class RequestListComponent {
  requests: Request[] = [];

  onRequestClick(requestId: number): void {
    this.router.navigate(['/requests', requestId]);
  }

  onApprove(requestId: number): void {
    this.approvalService.approve(requestId).subscribe();
  }
}
```

**Child Component**:
```typescript
@Component({
  selector: 'app-request-item',
  template: `
    <div class="request-card" (click)="onClick()">
      <h3>{{ request().workspaceName }}</h3>
      <button (click)="onApproveClick($event)">Approve</button>
    </div>
  `
})
export class RequestItemComponent {
  request = input.required<Request>();
  requestClicked = output<number>();
  approveClicked = output<number>();

  onClick(): void {
    this.requestClicked.emit(this.request().requestId);
  }

  onApproveClick(event: Event): void {
    event.stopPropagation();
    this.approveClicked.emit(this.request().requestId);
  }
}
```

### Service-Based Communication

**Shared Service**:
```typescript
@Injectable({
  providedIn: 'root'
})
export class RequestStateService {
  private selectedRequestSubject = new BehaviorSubject<number | null>(null);
  public selectedRequest$ = this.selectedRequestSubject.asObservable();

  selectRequest(requestId: number): void {
    this.selectedRequestSubject.next(requestId);
  }

  clearSelection(): void {
    this.selectedRequestSubject.next(null);
  }
}
```

---

## 🛣️ Routing Configuration

**src/app/app.routes.ts**:
```typescript
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'login', loadComponent: () => import('./components/login/login.component').then(m => m.LoginComponent) },
  
  {
    path: '',
    canActivate: [authGuard],
    children: [
      { 
        path: 'home', 
        loadComponent: () => import('./components/home/home.component').then(m => m.HomeComponent) 
      },
      {
        path: 'requests',
        children: [
          { path: '', loadComponent: () => import('./components/my-requests/my-requests.component').then(m => m.MyRequestsComponent) },
          { path: 'new', loadComponent: () => import('./components/request-form/request-form.component').then(m => m.RequestFormComponent) },
          { path: ':id', loadComponent: () => import('./components/request-detail/request-detail.component').then(m => m.RequestDetailComponent) }
        ]
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
        path: 'admin',
        canActivate: [roleGuard(['Sakura Administrator'])],
        loadComponent: () => import('./components/admin/admin.component').then(m => m.AdminComponent)
      }
    ]
  },
  
  { path: '**', redirectTo: '/home' }
];
```

---

## 🚀 Performance Optimization

### Lazy Loading

```typescript
// Feature modules are loaded only when needed
{
  path: 'admin',
  loadChildren: () => import('./features/admin/admin.routes').then(m => m.ADMIN_ROUTES)
}
```

### OnPush Change Detection

```typescript
@Component({
  selector: 'app-request-item',
  changeDetection: ChangeDetectionStrategy.OnPush, // ← Performance boost
  template: `...`
})
export class RequestItemComponent {
  // Use signals for reactive updates
  request = input.required<Request>();
}
```

### Virtual Scrolling for Large Lists

```typescript
import { CdkVirtualScrollViewport } from '@angular/cdk/scrolling';

@Component({
  template: `
    <cdk-virtual-scroll-viewport itemSize="80" class="request-list">
      <app-request-item
        *cdkVirtualFor="let request of requests"
        [request]="request"
      />
    </cdk-virtual-scroll-viewport>
  `
})
export class RequestListComponent {}
```

### HTTP Caching

```typescript
// Cache GET requests for 5 minutes
this.http.get(url, {
  headers: new HttpHeaders({ 'Cache-Control': 'max-age=300' })
});
```

---

**Next Document**: [05-DEPLOYMENT-AZURE.md](./05-DEPLOYMENT-AZURE.md)

