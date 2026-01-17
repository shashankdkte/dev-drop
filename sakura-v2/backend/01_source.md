# Sakura Backend - Complete Mermaid Documentation

## 1. Solution Level - Project Dependencies

**What This Diagram Shows:**
This diagram displays all the projects in the Sakura solution and how they depend on each other. Arrows show which project references (uses code from) another project.

**How to Read It:**
- Each box represents a project (a collection of related code files)
- Arrows point from a project to the projects it uses
- Solid arrows (→) mean "references" or "depends on"
- Dotted arrows (-.->) mean "tests" (test projects)
- Colors help distinguish different types of projects

**Example:**
- `Dentsu.SakuraApi` (the API project) uses code from `Dentsu.Sakura.Application`, `Dentsu.Sakura.Domain`, `Dentsu.Sakura.Infrastructure`, and `Dentsu.Sakura.Shared`
- This means the API layer can call methods from these other projects
- `Dentsu.Sakura.Domain` only depends on `Dentsu.Sakura.Shared`, making it the most independent project

**Technical Details:**
- **API Layer** (blue): Handles HTTP requests, contains controllers
- **Application Layer** (orange): Contains business logic and services
- **Domain Layer** (green): Contains entities (data models) and core business rules
- **Infrastructure Layer** (pink): Handles database access and external services
- **Shared Layer** (purple): Contains utilities used by all layers

```mermaid
graph TB
    subgraph "SakuraApi Solution"
        API[Dentsu.SakuraApi<br/>API/Presentation Layer]
        APP[Dentsu.Sakura.Application<br/>Business Logic Layer]
        DOM[Dentsu.Sakura.Domain<br/>Domain/Entity Layer]
        INF[Dentsu.Sakura.Infrastructure<br/>Data Access Layer]
        SHR[Dentsu.Sakura.Shared<br/>Cross-cutting Utilities]
        TEST1[Dentsu.Sakura.Testing]
        TEST2[Dentsu.Sakura.Application.UnitTests]
    end
    
    API -->|References| APP
    API -->|References| DOM
    API -->|References| INF
    API -->|References| SHR
    
    APP -->|References| DOM
    APP -->|References| SHR
    
    INF -->|References| APP
    INF -->|References| DOM
    INF -->|References| SHR
    
    DOM -->|References| SHR
    
    TEST1 -.->|Tests| API
    TEST2 -.->|Tests| APP
    
    style API fill:#e1f5ff
    style APP fill:#fff4e1
    style DOM fill:#e8f5e9
    style INF fill:#fce4ec
    style SHR fill:#f3e5f5
```

## 2. Layer-by-Layer Architecture

**What This Diagram Shows:**
This diagram shows how the different layers of the application are organized and how data flows from the HTTP request through each layer to the database and back.

**How to Read It:**
- Each box represents a layer (a group of related components)
- Arrows show the flow of data/requests
- Top to bottom: Request comes in, goes through layers, reaches database, response comes back
- External boxes (right side) are services outside the application

**Example Flow:**
1. Client sends HTTP request (e.g., "Get workspace 5")
2. Middleware processes it (adds headers, handles errors)
3. Controller receives it and routes to appropriate service
4. Service contains business logic (validates, processes)
5. Service uses UnitOfWork to get repository
6. Repository queries database through DbContext
7. Database returns data
8. Data flows back up through layers
9. Service converts entity to DTO (Data Transfer Object)
10. Controller returns HTTP response

**Technical Details:**
- **Separation of Concerns**: Each layer has a specific responsibility
- **Dependency Direction**: Inner layers don't know about outer layers
- **DTOs**: Data Transfer Objects - simplified versions of entities for API responses
- **UnitOfWork**: Manages database transactions and repositories

```mermaid
graph TB
    subgraph "HTTP Layer"
        HTTP[HTTP Request/Response]
    end
    
    subgraph "API Layer - Dentsu.SakuraApi"
        MW[Middleware<br/>Exception Handler<br/>Standard Middleware]
        CTRL[Controllers<br/>12 Controllers]
        CFG[Configurations<br/>8 Config Files]
        AF[Action Filters<br/>Validation]
    end
    
    subgraph "Application Layer - Dentsu.Sakura.Application"
        SVC[Services<br/>23 Service Files]
        REQ[Requests<br/>43 DTOs]
        RES[Responses<br/>42 DTOs]
        VAL[Validators<br/>12 Validators]
        MAP[Mapping<br/>Mapster]
        GUARD[Guards<br/>Business Rules]
    end
    
    subgraph "Domain Layer - Dentsu.Sakura.Domain"
        ENT[Entities<br/>38 Entity Files]
        INT[Interfaces<br/>7 Interface Files]
        ENUM[Enums<br/>Domain Enumerations]
    end
    
    subgraph "Infrastructure Layer - Dentsu.Sakura.Infrastructure"
        DB[DbContext<br/>SakuraDbContext]
        REPO[Repositories<br/>Generic + Reference]
        UOW[UnitOfWork<br/>Transaction Management]
    end
    
    subgraph "External"
        DBEXT[(SQL Server)]
        KV[Azure Key Vault]
        AAD[Azure AD]
    end
    
    HTTP --> MW
    MW --> CTRL
    CTRL --> SVC
    SVC --> REQ
    SVC --> RES
    SVC --> VAL
    SVC --> MAP
    SVC --> GUARD
    SVC --> UOW
    UOW --> REPO
    REPO --> DB
    DB --> DBEXT
    SVC --> ENT
    SVC --> INT
    CFG --> KV
    CFG --> AAD
    
    style HTTP fill:#ffebee
    style CTRL fill:#e1f5ff
    style SVC fill:#fff4e1
    style ENT fill:#e8f5e9
    style DB fill:#fce4ec
```

## 3. API Layer - Detailed Structure

**What This Diagram Shows:**
This diagram shows all the components in the API layer (the entry point of the application). It displays controllers, middleware, configurations, and how they connect to services.

**How to Read It:**
- Controllers (top section) handle HTTP requests and call services
- Middleware (middle section) processes requests before/after controllers
- Configurations (bottom section) set up the application (DI, auth, validation, etc.)
- Arrows show which service interface each controller uses

**Example:**
- When a request comes to `GET /api/workspace/5`:
  - `WorkspaceController` receives it
  - Controller calls `IWorkspaceService.GetWorkspaceAsync(5)`
  - Service processes the request and returns data
  - Controller returns HTTP response

**Technical Details:**
- **Controllers**: Handle HTTP requests, one per domain area (Workspace, WorkspaceApp, etc.)
- **Middleware**: Global request/response processing (exception handling, headers)
- **Configurations**: Setup code that runs at application startup
- **Dependency Injection**: Controllers receive services through constructor injection

```mermaid
graph TB
    subgraph "Dentsu.SakuraApi Project"
        subgraph "Controllers"
            WSC[WorkspaceController]
            WAC[WorkspaceAppController]
            WRC[WorkspaceReportController]
            WSM[WorkspaceSecurityModelController]
            AAC[AppAudienceController]
            RAM[ReportAppAudienceMapController]
            RSM[ReportSecurityModelMapController]
            AUTH[AuthController]
            ENUM[EnumsController]
            COMM[CommonController]
            REF[RefController<br/>Multiple Reference Controllers]
            GRC[GenericRefController<br/>Base Class]
        end
        
        subgraph "Middleware"
            EXC[SakuraGlobalExceptionHandlerMiddleware]
            STD[SakuraStandardMiddleware]
        end
        
        subgraph "Configurations"
            IOC[IocContainerConfiguration]
            AUTH_CFG[AccessControlConfiguration]
            KV_CFG[KeyVaultConfiguration]
            VAL_CFG[FluentValidationConfiguration]
            MW_CFG[MiddlewareConfiguration]
            CTRL_CFG[ControllersConfiguration]
            CORS_CFG[CORSConfiguration]
            SWAG[SwaggerConfiguration]
        end
        
        subgraph "Action Filters"
            VAP[ValidateActionParametersAttribute]
        end
    end
    
    WSC --> WSS[IWorkspaceService]
    WAC --> WAS[IWorkspaceAppService]
    WRC --> WRS[IWorkspaceReportService]
    WSM --> WSMS[IWorkspaceSecurityModelService]
    AAC --> AAS[IAppAudienceService]
    RAM --> RAMS[IReportAppAudienceMapService]
    RSM --> RSMS[IReportSecurityModelMapService]
    AUTH --> TS[ITokenService]
    ENUM --> ES[IEnumService]
    COMM --> LS[ILoVService]
    REF --> GRS[IGenericRefService]
    GRC --> GRS
    
    style WSC fill:#e1f5ff
    style WAC fill:#e1f5ff
    style WRC fill:#e1f5ff
    style WSM fill:#e1f5ff
    style AAC fill:#e1f5ff
    style RAM fill:#e1f5ff
    style RSM fill:#e1f5ff
    style AUTH fill:#e1f5ff
    style ENUM fill:#e1f5ff
    style COMM fill:#e1f5ff
    style REF fill:#e1f5ff
```

## 4. Application Layer - Detailed Structure

**What This Diagram Shows:**
This diagram shows all services, DTOs (Data Transfer Objects), validators, and other components in the Application layer. This layer contains the business logic.

**How to Read It:**
- Services are grouped by domain (Workspaces, Reference, Security, Common)
- Each service implements an interface (shown with arrows)
- Services use UnitOfWork and ObjectMapper (shown with arrows)
- DTOs, Validators, and Mapping support the services

**Example:**
- `WorkspaceService` implements `IWorkspaceService`
- It uses `ISakuraUnitOfWork` to get repositories
- It uses `IObjectMapper` to convert between entities and DTOs
- It processes `CreateWorkspaceRequest` DTOs and returns `WorkspaceResponse` DTOs

**Technical Details:**
- **Service Layer**: Contains business logic and orchestrates operations
- **Interface Segregation**: Each service has its own interface for better testability
- **DTOs**: Separate objects for API requests/responses (not the same as entities)
- **Validators**: FluentValidation rules that validate DTOs before processing
- **Mapping**: Converts between DTOs and entities using Mapster

```mermaid
graph TB
    subgraph "Dentsu.Sakura.Application Project"
        subgraph "Services - Workspaces"
            WS[WorkspaceService]
            WAS[WorkspaceAppService]
            WRS[WorkspaceReportService]
            WSMS[WorkspaceSecurityModelService]
            AAS[AppAudienceService]
            RAMS[ReportAppAudienceMapService]
            RSMS[ReportSecurityModelMapService]
        end
        
        subgraph "Services - Reference"
            GRS[GenericRefService<br/>Base for all Reference Services]
            RS[RegionService]
            CS[ClusterService]
            MS[MarketService]
            ES[EntityService]
            DS[DentsuStakeholderService]
            CP[ClientProgramService]
            BPCE[BPCEntityService]
            BPCS[BPCSegmentService]
            BPCB[BPCBrandService]
            BU[BusinessUnitService]
            CC[CostCenterService]
            CCFA[CostCenterFunctionalAreaService]
            CO[CountryService]
            CC2[CountryClusterService]
            CR[CountryRegionService]
            EMP[EmployeeService]
            MSS[MasterServiceSetService]
            PA[PeopleAggregatorService]
            PC[ProfitCenterService]
            SL[ServiceLineService]
            SLA[ServiceLineAltSLService]
            SLSH[ServiceLineServiceLineHRGroupService]
        end
        
        subgraph "Services - Security"
            TS[TokenService]
            TUS[TempUserService]
        end
        
        subgraph "Services - Common"
            ES2[EnumService]
            LS[LoVService]
        end
        
        subgraph "Interfaces"
            IWS[IWorkspaceService]
            IWAS[IWorkspaceAppService]
            IWRS[IWorkspaceReportService]
            IWSMS[IWorkspaceSecurityModelService]
            IAAS[IAppAudienceService]
            IRAMS[IReportAppAudienceMapService]
            IRSMS[IReportSecurityModelMapService]
            IGRS[IGenericRefService]
            ITS[ITokenService]
            IES[IEnumService]
            ILS[ILoVService]
            IUOW[ISakuraUnitOfWork]
            IREPO[ISakuraRepository]
            IMAP[IObjectMapper]
        end
        
        subgraph "DTOs"
            REQ[Requests<br/>43 Request DTOs]
            RES[Responses<br/>42 Response DTOs]
            DTO[Shared DTOs<br/>4 Files]
        end
        
        subgraph "Validators"
            VAL[FluentValidation Validators<br/>12 Validator Files]
        end
        
        subgraph "Mapping"
            MAP[ObjectMapper<br/>Mapster Configuration]
        end
        
        subgraph "Guards"
            WG[WorkspaceGuard]
            OG[OwnershipGuard]
        end
    end
    
    WS --> IWS
    WAS --> IWAS
    WRS --> IWRS
    WSMS --> IWSMS
    AAS --> IAAS
    RAMS --> IRAMS
    RSMS --> IRSMS
    GRS --> IGRS
    TS --> ITS
    ES2 --> IES
    LS --> ILS
    
    WS --> IUOW
    WS --> IMAP
    WAS --> IUOW
    WRS --> IUOW
    WSMS --> IUOW
    AAS --> IUOW
    RAMS --> IUOW
    RSMS --> IUOW
    
    style WS fill:#fff4e1
    style WAS fill:#fff4e1
    style WRS fill:#fff4e1
    style WSMS fill:#fff4e1
    style AAS fill:#fff4e1
    style RAMS fill:#fff4e1
    style RSMS fill:#fff4e1
    style GRS fill:#fff4e1
```

## 5. Domain Layer - Entity Hierarchy

**What This Diagram Shows:**
This diagram shows the inheritance hierarchy of all entities in the system. It shows which base classes entities extend and the relationships between entities.

**How to Read It:**
- Top section shows base classes (SakuraEntity, SakuraAuditableEntity, SakuraReferenceEntity)
- Middle sections show concrete entities grouped by type
- Arrows show inheritance (child extends parent)
- Numbers like `1:N` show relationships (one-to-many)

**Example:**
- `Workspace` extends `SakuraAuditableEntity` (which extends `SakuraEntity<int>`)
- This means Workspace has: Id, CreatedBy, CreatedAt, UpdatedBy, UpdatedAt
- `Workspace` has a `1:N` relationship with `WorkspaceApp` (one workspace has many apps)
- `WorkspaceApp` has a `1:N` relationship with `AppAudience` (one app has many audiences)

**Technical Details:**
- **Inheritance**: Base classes provide common properties (Id, audit fields)
- **SakuraEntity<TKey>**: Base with just Id property (generic key type)
- **SakuraAuditableEntity**: Adds audit trail (who/when created/updated)
- **SakuraReferenceEntity**: For read-only reference data (Regions, Countries, etc.)
- **Relationships**: Shown with cardinality (1:N = one-to-many)

```mermaid
graph TB
    subgraph "Base Entities"
        SE[SakuraEntity&lt;TKey&gt;<br/>Id: TKey]
        SAE[SakuraAuditableEntity<br/>Extends SakuraEntity&lt;int&gt;<br/>+ CreatedBy, CreatedAt<br/>+ UpdatedBy, UpdatedAt]
        SRE[SakuraReferenceEntity<br/>Extends SakuraEntity&lt;int&gt;<br/>+ MapKey, IsCurrent]
    end
    
    subgraph "Workspace Entities"
        W[Workspace<br/>Extends SakuraAuditableEntity]
        WA[WorkspaceApp<br/>Extends SakuraAuditableEntity]
        WR[WorkspaceReport<br/>Extends SakuraAuditableEntity]
        WSM[WorkspaceSecurityModel<br/>Extends SakuraAuditableEntity]
        AA[AppAudience<br/>Extends SakuraAuditableEntity]
        RAM[ReportAppAudienceMap<br/>Extends SakuraAuditableEntity]
        RSM[ReportSecurityModelMap<br/>Extends SakuraAuditableEntity]
        SMSTM[SecurityModelSecurityTypeMap<br/>Extends SakuraAuditableEntity]
    end
    
    subgraph "Reference Entities"
        R[Region<br/>Extends SakuraReferenceEntity]
        C[Cluster<br/>Extends SakuraReferenceEntity]
        M[Market<br/>Extends SakuraReferenceEntity]
        E[Entity<br/>Extends SakuraReferenceEntity]
        BPCE[BPCEntity<br/>Extends SakuraReferenceEntity]
        DS[DentsuStakeholder<br/>Extends SakuraReferenceEntity]
        CP[ClientProgram<br/>Extends SakuraReferenceEntity]
        CO[Country<br/>Extends SakuraReferenceEntity]
        EMP[Employee<br/>Extends SakuraReferenceEntity]
        BU[BusinessUnit<br/>Extends SakuraReferenceEntity]
        CC[CostCenter<br/>Extends SakuraReferenceEntity]
        PC[ProfitCenter<br/>Extends SakuraReferenceEntity]
        SL[ServiceLine<br/>Extends SakuraReferenceEntity]
        OTHERS[+ 10 More Reference Entities]
    end
    
    subgraph "Security Entities"
        U[User<br/>Extends SakuraAuditableEntity]
        RT[RefreshToken<br/>Extends SakuraEntity&lt;int&gt;]
    end
    
    subgraph "Common Entities"
        LOV[LoV<br/>Extends SakuraAuditableEntity]
    end
    
    SE --> SAE
    SE --> SRE
    SAE --> W
    SAE --> WA
    SAE --> WR
    SAE --> WSM
    SAE --> AA
    SAE --> RAM
    SAE --> RSM
    SAE --> SMSTM
    SAE --> U
    SAE --> LOV
    SRE --> R
    SRE --> C
    SRE --> M
    SRE --> E
    SRE --> BPCE
    SRE --> DS
    SRE --> CP
    SRE --> CO
    SRE --> EMP
    SRE --> BU
    SRE --> CC
    SRE --> PC
    SRE --> SL
    SRE --> OTHERS
    
    W -->|1:N| WA
    W -->|1:N| WR
    W -->|1:N| WSM
    WA -->|1:N| AA
    WSM -->|1:N| SMSTM
    WR -->|1:N| RAM
    WR -->|1:N| RSM
    
    style SE fill:#e8f5e9
    style SAE fill:#e8f5e9
    style SRE fill:#e8f5e9
    style W fill:#fff4e1
    style WA fill:#fff4e1
    style WR fill:#fff4e1
    style WSM fill:#fff4e1
```

## 6. Infrastructure Layer - Data Access

**What This Diagram Shows:**
This diagram shows the data access components that interact with the database. It shows repositories, UnitOfWork, and how they connect to the database.

**How to Read It:**
- UnitOfWork creates and manages repositories
- Repositories use DbContext to query the database
- DbContext translates C# code to SQL queries
- All components work together to provide data access

**Example:**
- Service calls `UnitOfWork.GetSakuraRepository<Workspace, int>()`
- UnitOfWork creates or returns cached `SakuraRepository<Workspace, int>`
- Repository uses `SakuraDbContext` to query `Workspaces` DbSet
- DbContext generates SQL and executes it on SQL Server
- Results flow back through the layers

**Technical Details:**
- **Repository Pattern**: Abstracts database operations, makes code testable
- **Unit of Work**: Manages repositories and transactions
- **DbContext**: Entity Framework Core's database context (ORM - Object-Relational Mapping)
- **Generic Repository**: One repository class handles all entity types
- **Reference Repository**: Special read-only repository for reference views

```mermaid
graph TB
    subgraph "Dentsu.Sakura.Infrastructure"
        subgraph "Data Access"
            DB[SakuraDbContext<br/>EF Core DbContext<br/>38+ DbSets]
            REPO[SakuraRepository&lt;TEntity, TKey&gt;<br/>Generic Repository<br/>CRUD Operations]
            REFREPO[SakuraReferenceRepository&lt;TEntity&gt;<br/>Read-only Repository<br/>For Reference Views]
            UOW[UnitOfWork<br/>Transaction Management<br/>Repository Factory]
        end
        
        subgraph "Repositories"
            AUTHREPO[AuthRepository<br/>Authentication-specific]
        end
        
        subgraph "Extensions"
            EXT[Infrastructure Extensions]
        end
    end
    
    subgraph "Database"
        SQL[(SQL Server<br/>Tables & Views)]
    end
    
    UOW --> REPO
    UOW --> REFREPO
    UOW --> AUTHREPO
    REPO --> DB
    REFREPO --> DB
    AUTHREPO --> DB
    DB --> SQL
    
    style DB fill:#fce4ec
    style REPO fill:#fce4ec
    style REFREPO fill:#fce4ec
    style UOW fill:#fce4ec
```

## 7. Request Flow - Complete Example

**What This Diagram Shows:**
This is a generic sequence diagram showing the typical flow of any HTTP request through the system. It shows the order of operations and which components communicate.

**How to Read It:**
- Time flows from top to bottom
- Each horizontal arrow is a method call or message
- `->>` means a return value or response
- `->` means a request or call
- Participants on the left are different components

**Example:**
When a client requests "Get workspace 5":
1. Client sends HTTP GET request
2. Middleware catches any exceptions
3. Controller receives request
4. Validator checks if ID parameter is valid
5. Controller calls service method
6. Service gets repository from UnitOfWork
7. Repository queries database
8. Database executes SQL
9. Data flows back up
10. Service maps entity to DTO
11. Controller returns response
12. Middleware adds headers
13. Client receives response

**Technical Details:**
- **Sequence Diagram**: Shows interactions over time
- **Async Operations**: Most operations are asynchronous (non-blocking)
- **Transaction Management**: UnitOfWork ensures all changes are saved together
- **Exception Handling**: Middleware catches errors and converts to proper HTTP status codes

```mermaid
sequenceDiagram
    participant Client
    participant MW as Middleware
    participant CTRL as Controller
    participant VAL as Validator
    participant SVC as Service
    participant UOW as UnitOfWork
    participant REPO as Repository
    participant DB as DbContext
    participant SQL as SQL Server
    
    Client->>MW: HTTP Request
    MW->>MW: Exception Handler Setup
    MW->>CTRL: Route to Controller
    CTRL->>VAL: Validate Request (FluentValidation)
    VAL-->>CTRL: Validation Result
    CTRL->>SVC: Call Service Method
    SVC->>UOW: Get Repository
    UOW->>REPO: Create/Get Repository Instance
    SVC->>REPO: Query/Command
    REPO->>DB: EF Core Query
    DB->>SQL: SQL Query
    SQL-->>DB: Data
    DB-->>REPO: Entity
    REPO-->>SVC: Entity
    SVC->>SVC: Business Logic
    SVC->>SVC: Map Entity to DTO
    SVC->>UOW: Commit (if write)
    UOW->>DB: SaveChanges
    DB->>SQL: SQL Command
    SQL-->>DB: Result
    DB-->>UOW: Success
    UOW-->>SVC: Success
    SVC-->>CTRL: DTO Response
    CTRL-->>MW: ActionResult
    MW->>MW: Add Headers
    MW-->>Client: HTTP Response
```

## 8. Workspace Entity Relationships

**What This Diagram Shows:**
This Entity-Relationship Diagram (ERD) shows how workspace-related entities are connected in the database. It shows foreign keys and relationships.

**How to Read It:**
- Each box is an entity (database table)
- Lines show relationships between entities
- `||--o{` means "one-to-many" (one parent has many children)
- `}o--||` means "many-to-one" (many children belong to one parent)
- PK = Primary Key, FK = Foreign Key, UK = Unique Key

**Example:**
- `Workspace ||--o{ WorkspaceApp` means one Workspace has many WorkspaceApps
- `WorkspaceApp` has `WorkspaceId FK` which references `Workspace.Id PK`
- `Workspace }o--|| LoV` means many Workspaces belong to one LoV (Domain)
- `WorkspaceApp ||--o{ AppAudience` means one App has many Audiences

**Technical Details:**
- **Primary Key (PK)**: Unique identifier for each record (usually Id)
- **Foreign Key (FK)**: References another table's primary key
- **Unique Key (UK)**: Ensures no duplicates (e.g., WorkspaceCode must be unique)
- **Soft Delete**: IsActive field marks records as deleted without removing them
- **Audit Fields**: CreatedAt, CreatedBy, UpdatedAt, UpdatedBy track changes

```mermaid
erDiagram
    Workspace ||--o{ WorkspaceApp : "has"
    Workspace ||--o{ WorkspaceReport : "has"
    Workspace ||--o{ WorkspaceSecurityModel : "has"
    Workspace }o--|| LoV : "belongs to Domain"
    WorkspaceApp ||--o{ AppAudience : "has"
    WorkspaceReport ||--o{ ReportAppAudienceMap : "maps to"
    WorkspaceReport ||--o{ ReportSecurityModelMap : "maps to"
    WorkspaceSecurityModel ||--o{ SecurityModelSecurityTypeMap : "has"
    SecurityModelSecurityTypeMap }o--|| LoV : "references SecurityType"
    
    Workspace {
        int Id PK
        string WorkspaceCode
        string WorkspaceName
        string WorkspaceOwner
        int DomainLoVId FK
        bool IsActive
    }
    
    WorkspaceApp {
        int Id PK
        int WorkspaceId FK
        string AppCode
        string AppName
        bool IsActive
    }
    
    WorkspaceReport {
        int Id PK
        int WorkspaceId FK
        string ReportCode
        string ReportName
        bool IsActive
    }
    
    WorkspaceSecurityModel {
        int Id PK
        int WorkspaceId FK
        string SecurityModelCode
        string SecurityModelName
        bool IsActive
    }
    
    AppAudience {
        int Id PK
        int AppId FK
        string AudienceCode
        string AudienceName
        bool IsActive
    }
```

## 9. Service Method Details - WorkspaceService

**What This Diagram Shows:**
This diagram shows all the methods in WorkspaceService and what operations they perform. It shows the flow from service method to repository operations.

**How to Read It:**
- Each box is a service method
- Arrows show which repository operations each method uses
- Methods are grouped by operation type (Get, Create, Update, Delete)
- The right side shows the repository methods being called

**Example Methods:**
- `GetWorkspaceAsync(5)` - Gets workspace with ID 5
  - Calls: `Repository.GetAsync(5)`
  - Returns: WorkspaceResponse DTO
- `AddWorkspaceAsync(request)` - Creates new workspace
  - Calls: `Validate Uniqueness` (checks if code exists)
  - Calls: `Repository.Add(entity)` (adds to database)
  - Calls: `UnitOfWork.CommitAsync()` (saves changes)
- `UpdateWorkspaceAsync(id, request)` - Updates existing workspace
  - Calls: `Repository.GetAsync(id)` (loads current)
  - Calls: `Check Concurrency` (prevents conflicts)
  - Calls: `Repository.Update(entity)` (updates)
  - Calls: `UnitOfWork.CommitAsync()` (saves)

**Technical Details:**
- **Service Layer**: Contains business logic and orchestration
- **Repository Pattern**: Abstracts database operations
- **Unit of Work**: Manages transactions (all or nothing)
- **Async Methods**: All methods are asynchronous for better performance

```mermaid
graph LR
    subgraph "WorkspaceService Methods"
        GET_ALL[GetWorkspacesAsync<br/>Returns: IApiListResult]
        GET_ONE[GetWorkspaceAsync<br/>id: int<br/>Returns: IApiSingleResult]
        CREATE[AddWorkspaceAsync<br/>request: CreateWorkspaceRequest<br/>Returns: IApiSingleResult]
        UPDATE[UpdateWorkspaceAsync<br/>id: int, request: UpdateWorkspaceRequest<br/>Returns: IApiSingleResult]
        DELETE[DeleteWorkspaceAsync<br/>id: int, token: string<br/>Returns: IApiSingleResult]
    end
    
    GET_ALL --> REPO[Repository.GetAllAsync]
    GET_ONE --> REPO2[Repository.GetAsync]
    CREATE --> VAL[Validate Uniqueness]
    CREATE --> REPO3[Repository.Add]
    CREATE --> UOW[UnitOfWork.CommitAsync]
    UPDATE --> REPO4[Repository.GetAsync]
    UPDATE --> VAL2[Check Concurrency]
    UPDATE --> REPO5[Repository.Update]
    UPDATE --> UOW2[UnitOfWork.CommitAsync]
    DELETE --> REPO6[Repository.GetAsync]
    DELETE --> VAL3[Validate Not Deleted]
    DELETE --> REPO7[Repository.Delete]
    DELETE --> UOW3[UnitOfWork.CommitAsync]
    
    style GET_ALL fill:#fff4e1
    style GET_ONE fill:#fff4e1
    style CREATE fill:#fff4e1
    style UPDATE fill:#fff4e1
    style DELETE fill:#fff4e1
```

## 10. Complete Controller Endpoint Map

**What This Diagram Shows:**
This diagram lists all the HTTP endpoints (URLs) that the API exposes. Each endpoint is a way for clients to interact with the backend.

**How to Read It:**
- Each box shows an HTTP method (GET, POST, PUT, DELETE) and the URL path
- GET = retrieve data, POST = create new, PUT = update existing, DELETE = remove
- `{id}` means a number parameter (e.g., `/api/workspace/5` where 5 is the workspace ID)
- `{entity}` means a text parameter (e.g., `/api/reference/Region`)

**Example:**
- `GET /api/workspace/{id}` - To get workspace with ID 5, call: `GET /api/workspace/5`
- `POST /api/workspace` - To create a new workspace, send a POST request with workspace data in the body
- `PUT /api/workspace/{id}` - To update workspace 5, send a PUT request with updated data

**Technical Details:**
- **RESTful API**: Follows REST (Representational State Transfer) conventions
- **HTTP Methods**: 
  - GET: Read data (safe, no side effects)
  - POST: Create new resources
  - PUT: Update existing resources (idempotent - same request = same result)
  - DELETE: Remove resources (soft delete - sets IsActive = false)
- **Route Parameters**: Values in `{}` are replaced with actual values when calling

```mermaid
graph TB
    subgraph "WorkspaceController"
        WS_GET_ALL["GET /api/workspace<br/>Get all workspaces"]
        WS_GET_ONE["GET /api/workspace/{id}<br/>Get workspace by ID"]
        WS_CREATE["POST /api/workspace<br/>Create new workspace"]
        WS_UPDATE["PUT /api/workspace<br/>Update workspace"]
        WS_DELETE["PUT /api/workspace/Delete<br/>Soft delete workspace"]
    end
    
    subgraph "WorkspaceAppController"
        WA_GET_ALL["GET /api/workspaceapp<br/>Get all workspace apps"]
        WA_GET_ONE["GET /api/workspaceapp/{id}<br/>Get app by ID"]
        WA_CREATE["POST /api/workspaceapp<br/>Create new app"]
        WA_UPDATE["PUT /api/workspaceapp<br/>Update app"]
        WA_DELETE["PUT /api/workspaceapp/Delete<br/>Soft delete app"]
    end
    
    subgraph "WorkspaceReportController"
        WR_GET_ALL["GET /api/workspacereport<br/>Get all reports"]
        WR_GET_ONE["GET /api/workspacereport/{id}<br/>Get report by ID"]
        WR_CREATE["POST /api/workspacereport<br/>Create new report"]
        WR_UPDATE["PUT /api/workspacereport<br/>Update report"]
        WR_DELETE["PUT /api/workspacereport/Delete<br/>Soft delete report"]
    end
    
    subgraph "WorkspaceSecurityModelController"
        WSM_GET_ALL["GET /api/workspacesecuritymodel<br/>Get all security models"]
        WSM_GET_ONE["GET /api/workspacesecuritymodel/{id}<br/>Get model by ID"]
        WSM_CREATE["POST /api/workspacesecuritymodel<br/>Create new model"]
        WSM_UPDATE["PUT /api/workspacesecuritymodel<br/>Update model"]
        WSM_DELETE["PUT /api/workspacesecuritymodel/Delete<br/>Soft delete model"]
    end
    
    subgraph "Reference Controllers"
        REF_GET_ALL["GET /api/reference/{entity}<br/>Get all reference data"]
        REF_GET_ONE["GET /api/reference/{entity}/{id}<br/>Get reference by ID"]
    end
    
    subgraph "AuthController"
        AUTH_LOGIN["POST /api/auth/login<br/>User login"]
        AUTH_REFRESH["POST /api/auth/refresh<br/>Refresh token"]
    end
    
    style WS_GET_ALL fill:#e1f5ff
    style WA_GET_ALL fill:#e1f5ff
    style WR_GET_ALL fill:#e1f5ff
    style WSM_GET_ALL fill:#e1f5ff
    style REF_GET_ALL fill:#e1f5ff
    style AUTH_LOGIN fill:#e1f5ff
```

## 11. Repository Methods - SakuraRepository

**What This Diagram Shows:**
This diagram shows all the methods available in the generic repository class. The repository is a layer that handles database operations (CRUD - Create, Read, Update, Delete).

**How to Read It:**
- Each box is a method name with its parameters
- Arrows show which database operation each method uses
- Methods are grouped by operation type (Add, Delete, Update, Get)
- `TEntity` means "any entity type" (Workspace, WorkspaceApp, etc.)
- `VKey` means "any key type" (usually int)

**Example:**
- `Add(entity)` - Adds a new workspace to the database
  - Example: `repository.Add(newWorkspace)` creates a new workspace record
- `GetAsync(id)` - Gets one entity by its ID
  - Example: `repository.GetAsync(5)` returns workspace with ID 5
- `GetAll()` - Gets all entities (returns a query you can filter)
  - Example: `repository.GetAll().Where(w => w.IsActive == true)` gets only active workspaces

**Technical Details:**
- **Generic Repository Pattern**: One class handles all entity types using generics (`<TEntity, VKey>`)
- **Soft Delete**: `GetAsync` excludes deleted records (IsActive = false), `GetAsyncIncludingDeleted` includes them
- **IQueryable**: `GetAll()` returns a query builder, not data yet - allows filtering before database call
- **Async Methods**: Methods ending in `Async` are asynchronous (non-blocking, better performance)

```mermaid
graph TB
    subgraph "SakuraRepository Methods"
        subgraph "Create Operations"
            ADD["Add(entity)<br/>Add single entity"]
            ADD_RANGE["Add(entities)<br/>Add multiple entities"]
        end
        
        subgraph "Read Operations"
            GET["GetAsync(id)<br/>Get by ID<br/>Excludes deleted"]
            GET_INC_DEL["GetAsyncIncludingDeleted(id)<br/>Get by ID<br/>Includes deleted"]
            GET_ALL["GetAll()<br/>Get all entities<br/>Returns IQueryable"]
            GET_ALL_INC["GetAll(include)<br/>Get all with related data"]
            FIND_BY["FindBy(predicate)<br/>Find by condition<br/>Returns IQueryable"]
        end
        
        subgraph "Update Operations"
            UPDATE["Update(entity)<br/>Update entity"]
        end
        
        subgraph "Delete Operations"
            DELETE_ENT["Delete(entity)<br/>Soft delete entity"]
            DELETE_ID["Delete(id)<br/>Soft delete by ID"]
            DELETE_RANGE["Delete(entities)<br/>Soft delete multiple"]
        end
        
        subgraph "Check Operations"
            EXISTS["Exists(predicate)<br/>Check if exists<br/>Excludes deleted"]
            EXISTS_INC_DEL["ExistsIncludingDeleted(predicate)<br/>Check if exists<br/>Includes deleted"]
        end
        
        subgraph "Advanced Operations"
            GET_ALL_PAGE["GetAll(page, pageCount)<br/>Get paginated results"]
            FROM_SQL["FromSql(sql)<br/>Execute raw SQL"]
        end
    end
    
    ADD --> DB1["DbSet.Add"]
    ADD_RANGE --> DB2["DbSet.AddRange"]
    DELETE_ENT --> DB3["DbSet.Remove"]
    DELETE_ID --> GET
    DELETE_ID --> DELETE_ENT
    DELETE_RANGE --> DB4["DbSet.RemoveRange"]
    UPDATE --> DB5["DbSet.Update"]
    GET --> DB6["DbSet.SingleOrDefaultAsync<br/>+ Soft Delete Filter"]
    GET_INC_DEL --> DB7["DbSet.IgnoreQueryFilters<br/>SingleOrDefaultAsync"]
    GET_ALL --> DB8["DbSet<br/>IQueryable"]
    GET_ALL_INC --> DB9["DbSet.Include"]
    FIND_BY --> DB10["DbSet.Where"]
    EXISTS --> DB11["DbSet.Any<br/>+ Soft Delete Filter"]
    EXISTS_INC_DEL --> DB12["DbSet.IgnoreQueryFilters.Any"]
    GET_ALL_PAGE --> DB13["DbSet.OrderAndPaging"]
    FROM_SQL --> DB14["DbSet.FromSqlRaw"]
    
    style ADD fill:#fce4ec
    style DELETE_ENT fill:#fce4ec
    style UPDATE fill:#fce4ec
    style GET fill:#fce4ec
    style GET_ALL fill:#fce4ec
```

## 12. UnitOfWork Pattern

**What This Diagram Shows:**
This diagram explains the Unit of Work pattern, which manages database transactions and provides repositories. It ensures all changes are saved together or not at all.

**How to Read It:**
- UnitOfWork is a factory that creates repositories
- It caches repositories so you get the same instance for the same entity type
- Commit methods save all pending changes to the database
- The cache prevents creating multiple repository instances

**Example:**
When creating a workspace:
1. Service calls `UnitOfWork.GetSakuraRepository<Workspace, int>()`
2. UnitOfWork checks cache - if not found, creates new repository
3. Service uses repository to add workspace
4. Service calls `UnitOfWork.CommitAsync()`
5. UnitOfWork calls `DbContext.SaveChangesAsync()`
6. All pending changes (adds, updates, deletes) are saved in one transaction

**Technical Details:**
- **Repository Factory**: Creates repositories on demand
- **Caching**: Same repository instance reused for same entity type
- **Transaction Management**: Commit ensures all changes succeed or fail together
- **Scoped Lifetime**: One UnitOfWork per HTTP request

```mermaid
graph TB
    subgraph "UnitOfWork"
        GET_REPO[GetSakuraRepository&lt;TEntity, VKey&gt;<br/>Returns: ISakuraRepository]
        COMMIT[Commit<br/>Returns: int]
        COMMIT_ASYNC[CommitAsync<br/>Returns: Task&lt;int&gt;]
        DISPOSE[Dispose]
    end
    
    subgraph "Repository Cache"
        CACHE[Dictionary&lt;Type, object&gt;<br/>_repositories]
    end
    
    subgraph "DbContext"
        DB[SakuraDbContext]
        SAVE[SaveChanges]
        SAVE_ASYNC[SaveChangesAsync]
    end
    
    GET_REPO --> CACHE
    CACHE -->|Check if exists| NEW_REPO[Create SakuraRepository]
    NEW_REPO --> DB
    COMMIT --> SAVE
    COMMIT_ASYNC --> SAVE_ASYNC
    SAVE --> DB
    SAVE_ASYNC --> DB
    
    style GET_REPO fill:#fce4ec
    style COMMIT fill:#fce4ec
    style COMMIT_ASYNC fill:#fce4ec
```

## 13. Detailed Request Flow - Create Workspace

**What This Diagram Shows:**
This sequence diagram shows step-by-step what happens when a client creates a new workspace. It shows the order of operations and which components talk to each other.

**How to Read It:**
- Time flows from top to bottom
- Each horizontal line is a message/call from one component to another
- `->>` means a return/response
- `->` means a call/request
- Each participant (left column) is a component in the system

**Example Scenario:**
Client wants to create a workspace with code "PROJECT_A" and name "My Project"

1. **Client sends request**: `POST /api/workspace` with workspace data
2. **Middleware** receives it and routes to the controller
3. **Controller** validates the request format
4. **Service** checks if workspace code already exists (business rule)
5. **Service** validates the DomainLoVId is valid
6. **Service** converts request DTO to entity
7. **Service** sets audit fields (CreatedAt, CreatedBy, etc.)
8. **Repository** adds entity to database context
9. **UnitOfWork** saves changes to database
10. **Service** converts entity back to response DTO
11. **Controller** returns success response to client

**Technical Details:**
- **FluentValidation**: Validates request format before processing
- **Business Logic**: Service checks uniqueness and validates references
- **Mapping**: Converts between DTOs (Data Transfer Objects) and Entities
- **Unit of Work**: Ensures all changes are saved together (transaction)
- **Soft Delete Check**: `ExistsIncludingDeleted` checks even deleted records to prevent code reuse

```mermaid
sequenceDiagram
    participant Client
    participant MW as Middleware
    participant CTRL as WorkspaceController
    participant VAL as FluentValidation
    participant SVC as WorkspaceService
    participant MAP as ObjectMapper
    participant UOW as UnitOfWork
    participant REPO as SakuraRepository
    participant LOV_REPO as LoV Repository
    participant DB as SakuraDbContext
    participant SQL as SQL Server
    
    Client->>MW: POST /api/workspace<br/>CreateWorkspaceRequest
    MW->>CTRL: Route Request
    CTRL->>VAL: Validate Request
    VAL->>VAL: Check Rules<br/>WorkspaceCode required<br/>Format validation
    VAL-->>CTRL: Validation Pass
    CTRL->>SVC: AddWorkspaceAsync(request)
    SVC->>REPO: ExistsIncludingDeleted<br/>(WorkspaceCode)
    REPO->>DB: Query with IgnoreQueryFilters
    DB->>SQL: SELECT WHERE WorkspaceCode
    SQL-->>DB: Result
    DB-->>REPO: false (not exists)
    REPO-->>SVC: Code is unique
    SVC->>UOW: GetSakuraRepository(LoV)
    UOW->>LOV_REPO: Get Repository
    SVC->>LOV_REPO: GetAll().AnyAsync<br/>(Id == DomainLoVId && LovType == "Domain")
    LOV_REPO->>DB: Query LoV
    DB->>SQL: SELECT FROM LoVs
    SQL-->>DB: LoV Data
    DB-->>LOV_REPO: LoV Entity
    LOV_REPO-->>SVC: DomainLoVId valid
    SVC->>MAP: Map CreateWorkspaceRequest to Workspace
    MAP-->>SVC: Workspace Entity
    SVC->>SVC: Set IsActive = true<br/>Set CreatedAt/By<br/>Set UpdatedAt/By
    SVC->>REPO: Add(entity)
    REPO->>DB: DbSet.Add
    SVC->>UOW: CommitAsync()
    UOW->>DB: SaveChangesAsync()
    DB->>SQL: INSERT INTO Workspaces
    SQL-->>DB: Success
    DB-->>UOW: Rows Affected
    UOW-->>SVC: Success
    SVC->>MAP: Map Workspace to WorkspaceResponse
    MAP-->>SVC: WorkspaceResponse DTO
    SVC-->>CTRL: ApiSingleResult(WorkspaceResponse)
    CTRL-->>MW: Ok(result)
    MW-->>Client: 200 OK + Response
```

## 14. Detailed Request Flow - Update Workspace

**What This Diagram Shows:**
This sequence diagram shows what happens when updating an existing workspace. It includes optimistic concurrency checking to prevent conflicts when multiple users edit the same record.

**How to Read It:**
- The `alt` block shows two possible paths: concurrency mismatch (error) or success
- Concurrency token is a version number that changes each time the record is updated
- If tokens don't match, someone else updated the record first - update is rejected

**Example Scenario:**
User A and User B both load workspace ID 5. User A updates it first. When User B tries to update, their token is outdated, so the update is rejected.

**Step-by-Step:**
1. Client sends update request with ID and concurrency token
2. Service checks if workspace exists
3. Service loads current workspace from database
4. Service compares request token with database token
5. **If tokens match**: Proceed with update
   - Check workspace code uniqueness
   - Validate DomainLoVId
   - Map only allowed fields
   - Update audit fields
   - Save to database
6. **If tokens don't match**: Return error (someone else updated it)

**Technical Details:**
- **Optimistic Concurrency**: Prevents lost updates when multiple users edit simultaneously
- **ConcurrencyToken**: A hash/version number that changes on each update
- **GetAsyncIncludingDeleted**: Loads workspace even if soft-deleted (needed for updates)
- **Partial Update**: Only specified fields are updated, others remain unchanged

```mermaid
sequenceDiagram
    participant Client
    participant CTRL as WorkspaceController
    participant SVC as WorkspaceService
    participant REPO as SakuraRepository
    participant DB as SakuraDbContext
    participant SQL as SQL Server
    
    Client->>CTRL: PUT /api/workspace<br/>UpdateWorkspaceRequest<br/>{Id, ConcurrencyToken, ...}
    CTRL->>SVC: UpdateWorkspaceAsync(request)
    SVC->>REPO: ExistsIncludingDeleted(Id)
    REPO->>DB: Query
    DB->>SQL: SELECT WHERE Id
    SQL-->>DB: Found
    DB-->>REPO: true
    REPO-->>SVC: Workspace exists
    SVC->>REPO: GetAsyncIncludingDeleted(Id)
    REPO->>DB: Query with IgnoreQueryFilters
    DB->>SQL: SELECT WHERE Id
    SQL-->>DB: Workspace Entity
    DB-->>REPO: Entity
    REPO-->>SVC: Workspace Entity
    SVC->>SVC: CheckConcurrency<br/>(request.Token vs entity.Token)
    
    alt Concurrency Mismatch
        Note over SVC: Tokens don't match<br/>Someone else updated first
        SVC-->>CTRL: Throw ConcurrencyException
        CTRL-->>Client: 409 Conflict Error
    else Concurrency OK
        Note over SVC: Tokens match<br/>Safe to update
        SVC->>REPO: ExistsIncludingDeleted<br/>(WorkspaceCode && Id != request.Id)
        REPO->>DB: Query
        DB->>SQL: SELECT WHERE WorkspaceCode
        SQL-->>DB: Result
        DB-->>REPO: false (unique)
        REPO-->>SVC: Code is unique
        SVC->>SVC: Validate DomainLoVId
        SVC->>SVC: Map UpdateRequest to Entity<br/>(only allowed fields)
        SVC->>SVC: Set UpdatedAt/By
        SVC->>REPO: Update(entity)
        REPO->>DB: DbSet.Update
        SVC->>UOW: CommitAsync()
        UOW->>DB: SaveChangesAsync()
        DB->>SQL: UPDATE Workspaces SET ...
        SQL-->>DB: Success
        DB-->>UOW: Rows Affected
        UOW-->>SVC: Success
        SVC->>SVC: Map Entity to Response
        SVC-->>CTRL: ApiSingleResult(WorkspaceResponse)
        CTRL-->>Client: 200 OK
    end
```

## 15. Detailed Request Flow - Delete Workspace (Soft Delete)

**What This Diagram Shows:**
This sequence diagram shows the soft delete process. Instead of removing the record from the database, it sets `IsActive = false`, so the data is preserved but hidden.

**How to Read It:**
- Soft delete means the record stays in the database but is marked as inactive
- `GetAsync(Id)` only returns active records (IsActive = true)
- If workspace is already inactive, deletion is rejected
- The `alt` block shows two paths: already deleted (error) or active (can delete)

**Example Scenario:**
User wants to delete workspace ID 5. The system:
1. Checks if workspace exists
2. Loads the workspace (only if active)
3. Checks concurrency token
4. If already inactive, returns error
5. If active, sets IsActive = false and updates audit fields
6. Record remains in database but won't appear in normal queries

**Step-by-Step:**
1. Client sends delete request with ID and concurrency token
2. Service checks if workspace exists (including deleted ones)
3. Service loads workspace (only active ones via `GetAsync`)
4. Service checks concurrency token
5. **If already inactive**: Return error (can't delete twice)
6. **If active**: 
   - Set audit fields (UpdatedAt, UpdatedBy)
   - Mark for deletion
   - Save changes triggers soft delete rule
   - Database sets IsActive = false
   - Return success

**Technical Details:**
- **Soft Delete**: Data is preserved for audit/history, but hidden from normal operations
- **Hard Delete**: Would use `DELETE FROM Workspaces WHERE Id = ...` (not used here)
- **ApplySoftDeleteRules**: DbContext intercepts deletion and converts to UPDATE
- **GetAsync vs GetAsyncIncludingDeleted**: First excludes deleted, second includes them

```mermaid
sequenceDiagram
    participant Client
    participant CTRL as WorkspaceController
    participant SVC as WorkspaceService
    participant REPO as SakuraRepository
    participant DB as SakuraDbContext
    participant SQL as SQL Server
    
    Client->>CTRL: PUT /api/workspace/Delete<br/>DeleteWorkspaceRequest<br/>{Id, ConcurrencyToken}
    CTRL->>SVC: DeleteWorkspaceAsync(request)
    SVC->>REPO: ExistsIncludingDeleted(Id)
    REPO->>DB: Query
    DB->>SQL: SELECT WHERE Id
    SQL-->>DB: Found
    DB-->>REPO: true
    REPO-->>SVC: Workspace exists
    SVC->>REPO: GetAsync(Id)
    Note over REPO,DB: Only returns active records<br/>(IsActive = true)
    REPO->>DB: Query (with soft delete filter)
    DB->>SQL: SELECT WHERE Id AND IsActive = true
    SQL-->>DB: Workspace Entity
    DB-->>REPO: Entity
    REPO-->>SVC: Workspace Entity
    SVC->>SVC: CheckConcurrency(request.Token)
    
    alt Already Inactive
        Note over SVC: Workspace already deleted<br/>Cannot delete twice
        SVC-->>CTRL: ValidationException<br/>"Already inactive"
        CTRL-->>Client: 400 Bad Request
    else Active
        Note over SVC: Workspace is active<br/>Can be deleted
        SVC->>SVC: Set UpdatedAt/By
        SVC->>REPO: Delete(entity)
        REPO->>DB: DbSet.Remove(entity)
        SVC->>UOW: CommitAsync()
        UOW->>DB: SaveChangesAsync()
        Note over DB: DbContext intercepts<br/>Converts to soft delete
        DB->>DB: ApplySoftDeleteRules<br/>(Set IsActive = false)
        DB->>SQL: UPDATE Workspaces<br/>SET IsActive = 0<br/>WHERE Id = ...
        SQL-->>DB: Success
        DB-->>UOW: Rows Affected
        UOW-->>SVC: Success
        SVC-->>CTRL: ApiScalarResult(bool)<br/>ValueResult = true
        CTRL-->>Client: 200 OK
    end
```

## 16. All Service Methods - Complete Overview

**What This Diagram Shows:**
This diagram lists all service methods across all services in the application. It shows how many methods each service has and groups them by service type.

**How to Read It:**
- Each subgraph represents one service class
- Boxes inside are method names
- Numbers in service names show how many methods each service has
- Methods are grouped by service for easy reference

**Example:**
- `WorkspaceService` has 8 methods:
  - 5 read methods (GetWorkspaceAsync, GetWorkspacesAsync, etc.)
  - 3 write methods (AddWorkspaceAsync, UpdateWorkspaceAsync, DeleteWorkspaceAsync)
- `WorkspaceSecurityModelService` has 12 methods (most complex service)
- `GenericRefService` has only 2 methods (simple read-only service)

**Technical Details:**
- **Service Methods**: All methods are async (return Task) for better performance
- **Naming Convention**: Methods ending in "Async" are asynchronous
- **CRUD Operations**: Most services have Create, Read, Update, Delete methods
- **Specialized Methods**: Some services have domain-specific methods (e.g., AddSecurityTypeToModelAsync)

```mermaid
graph TB
    subgraph "WorkspaceService - 8 Methods"
        WS1[GetWorkspaceAsync]
        WS2[GetWorkspacesAsync]
        WS3[GetWorkspacesForUserAsync]
        WS4[GetAnyWorkspaceAsync]
        WS5[GetAnyWorkspacesAsync]
        WS6[AddWorkspaceAsync]
        WS7[UpdateWorkspaceAsync]
        WS8[DeleteWorkspaceAsync]
    end
    
    subgraph "WorkspaceAppService - 6 Methods"
        WA1[GetWorkspaceAppsAsync]
        WA2[GetAnyWorkspaceAppsAsync]
        WA3[GetWorkspaceAppByIdAsync]
        WA4[AddWorkspaceAppAsync]
        WA5[UpdateWorkspaceAppAsync]
        WA6[UpdateWorkspaceAppStatus]
        WA7[AddUpdateOLSApproversAsync]
    end
    
    subgraph "WorkspaceReportService - 7 Methods"
        WR1[GetWorkspaceReportByIdAsync]
        WR2[ListWorkspaceReportsAsync]
        WR3[GetWorkspaceReportAsync]
        WR4[CreateWorkspaceReportAsync]
        WR5[UpdateWorkspaceReportAsync]
        WR6[UpdateWorkspaceReportStatus]
        WR7[AddUpdateOLSApproversAsync]
    end
    
    subgraph "WorkspaceSecurityModelService - 12 Methods"
        WSM1[CreateAsync]
        WSM2[UpdateAsync]
        WSM3[DeleteAsync]
        WSM4[GetByIdAsync]
        WSM5[ListByWorkspaceAsync]
        WSM6[UpdateWorkspaceSecurityModelStatus]
        WSM7[GetAllSecurityTypesOfModelAsync]
        WSM8[AddSecurityTypeToModelAsync]
        WSM9[RemoveSecurityTypeFromModelAsync]
        WSM10[AddAllSecurityTypesToModelAsync]
        WSM11[RemoveAllSecurityTypesFromModelAsync]
        WSM12[SetAllSecurityTypesOfModelAsync]
    end
    
    subgraph "AppAudienceService - 8 Methods"
        AA1[GetAppAudienceAsync]
        AA2[GetAnyAppAudienceAsync]
        AA3[AddAppAudienceAsync]
        AA4[GetAppAudienceByIdAsync]
        AA5[UpdateAppAudienceAsync]
        AA6[GetAppAudienceByAppIdAsync]
        AA7[GetAppAudienceByAudienceCodeAsync]
        AA8[UpdateAppAudienceStatus]
        AA9[AddUpdateOLSApproversAsync]
    end
    
    subgraph "ReportAppAudienceMapService - 5 Methods"
        RAM1[GetReportAppAudienceMapByIdAsync]
        RAM2[ListAppAudiencesByReportAsync]
        RAM3[ListReportsByAppAudienceAsync]
        RAM4[CreateReportAppAudienceMapAsync]
        RAM5[DeleteReportAppAudienceMapAsync]
    end
    
    subgraph "ReportSecurityModelMapService - 5 Methods"
        RSM1[GetReportSecurityModelMapByIdAsync]
        RSM2[ListReportSecurityModelsByReportAsync]
        RSM3[ListReportsBySecurityModelAsync]
        RSM4[CreateReportSecurityModelMapAsync]
        RSM5[DeleteReportSecurityModelMapAsync]
    end
    
    subgraph "GenericRefService - 2 Methods"
        GR1[GetAllAsync]
        GR2[GetByIdAsync]
    end
    
    style WS1 fill:#fff4e1
    style WA1 fill:#fff4e1
    style WR1 fill:#fff4e1
    style WSM1 fill:#fff4e1
    style AA1 fill:#fff4e1
    style RAM1 fill:#fff4e1
    style RSM1 fill:#fff4e1
    style GR1 fill:#fff4e1
```

## 17. DbContext - All DbSets

**What This Diagram Shows:**
This diagram shows all the DbSets defined in SakuraDbContext. Each DbSet represents a database table or view that can be queried.

**How to Read It:**
- Each box is a DbSet property
- DbSets are grouped by entity type (Workspace, Common, Reference)
- All DbSets connect to SQL Server (shown at bottom)
- DbSet names match entity class names (pluralized)

**Example:**
- `Workspaces` DbSet maps to the `Workspaces` table in SQL Server
- Querying `context.Workspaces` returns all workspace records
- `Regions` DbSet maps to a read-only view in the `refv` schema
- Reference entities (Regions, Countries, etc.) are read-only views

**Technical Details:**
- **DbSet**: Entity Framework Core's representation of a database table/view
- **38+ DbSets**: Total number of tables/views in the database
- **Workspace Entities**: Writable tables (can insert, update, delete)
- **Reference Entities**: Read-only views (can only query, not modify)
- **Schema Separation**: Reference views are in `refv` schema, workspace tables in `dbo` schema

```mermaid
graph TB
    subgraph "SakuraDbContext - 38+ DbSets"
        subgraph "Workspace Entities"
            DB1[Workspaces]
            DB2[WorkspaceApps]
            DB3[WorkspaceReports]
            DB4[WorkspaceSecurityModels]
            DB5[AppAudiences]
            DB6[ReportAppAudienceMap]
            DB7[ReportSecurityModelMap]
            DB8[SecurityModelSecurityTypeMap]
        end
        
        subgraph "Common Entities"
            DB9[Lovs]
            DB10[RefreshTokens]
        end
        
        subgraph "Reference Entities"
            DB11[DentsuStakeholders]
            DB12[ClientPrograms]
            DB13[Clusters]
            DB14[Regions]
            DB15[Markets]
            DB16[Entities]
            DB17[BPCEntities]
            DB18[CountryRegions]
            DB19[CountryClusters]
            DB20[Countries]
            DB21[MasterServiceSets]
            DB22[ProfitCenters]
            DB23[BPCBrands]
            DB24[CostCenters]
            DB25[CostCenterFunctionalAreas]
            DB26[BusinessUnits]
            DB27[BPCSegments]
            DB28[ServiceLines]
            DB29[ServiceLineAltSLs]
            DB30[ServiceLineServiceLineHRGroups]
            DB31[PeopleAggregators]
            DB32[Employees]
        end
    end
    
    DB1 --> SQL[(SQL Server)]
    DB2 --> SQL
    DB3 --> SQL
    DB4 --> SQL
    DB5 --> SQL
    DB6 --> SQL
    DB7 --> SQL
    DB8 --> SQL
    DB9 --> SQL
    DB10 --> SQL
    DB11 --> SQL
    DB12 --> SQL
    DB13 --> SQL
    DB14 --> SQL
    DB15 --> SQL
    DB16 --> SQL
    DB17 --> SQL
    DB18 --> SQL
    DB19 --> SQL
    DB20 --> SQL
    DB21 --> SQL
    DB22 --> SQL
    DB23 --> SQL
    DB24 --> SQL
    DB25 --> SQL
    DB26 --> SQL
    DB27 --> SQL
    DB28 --> SQL
    DB29 --> SQL
    DB30 --> SQL
    DB31 --> SQL
    DB32 --> SQL
    
    style DB1 fill:#fce4ec
    style DB2 fill:#fce4ec
    style DB3 fill:#fce4ec
    style DB4 fill:#fce4ec
    style DB5 fill:#fce4ec
    style DB9 fill:#fce4ec
```

## 18. Complete Entity Relationship Diagram

**What This Diagram Shows:**
This is a comprehensive Entity-Relationship Diagram showing all workspace-related entities, their properties, and how they relate to each other. It includes all fields (columns) for each entity.

**How to Read It:**
- Each entity box shows all its properties (fields/columns)
- PK = Primary Key, FK = Foreign Key, UK = Unique Key
- Relationship lines show how entities connect
- Field types show data types (int, string, bool, DateTime)

**Example:**
- `Workspace` entity has properties like Id (PK), WorkspaceCode (UK), WorkspaceName, etc.
- `WorkspaceApp` has `WorkspaceId FK` which links to `Workspace.Id PK`
- `ReportAppAudienceMap` is a junction table linking Reports to AppAudiences
- All entities have audit fields (CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)

**Technical Details:**
- **Primary Keys**: Unique identifiers (usually Id, auto-increment)
- **Foreign Keys**: References to other tables (e.g., WorkspaceId references Workspace.Id)
- **Unique Keys**: Prevent duplicates (e.g., WorkspaceCode must be unique)
- **ConcurrencyToken**: Used for optimistic concurrency control
- **Audit Trail**: All entities track who created/updated and when
- **Soft Delete**: IsActive field marks records as deleted

```mermaid
erDiagram
    Workspace ||--o{ WorkspaceApp : "has many"
    Workspace ||--o{ WorkspaceReport : "has many"
    Workspace ||--o{ WorkspaceSecurityModel : "has many"
    Workspace }o--|| LoV : "belongs to Domain"
    
    WorkspaceApp ||--o{ AppAudience : "has many"
    
    WorkspaceReport ||--o{ ReportAppAudienceMap : "maps to"
    WorkspaceReport ||--o{ ReportSecurityModelMap : "maps to"
    
    WorkspaceSecurityModel ||--o{ SecurityModelSecurityTypeMap : "has many"
    SecurityModelSecurityTypeMap }o--|| LoV : "references SecurityType"
    
    ReportAppAudienceMap }o--|| AppAudience : "references"
    ReportAppAudienceMap }o--|| WorkspaceReport : "references"
    
    ReportSecurityModelMap }o--|| WorkspaceSecurityModel : "references"
    ReportSecurityModelMap }o--|| WorkspaceReport : "references"
    
    Workspace {
        int Id PK
        string WorkspaceCode UK
        string WorkspaceName
        string WorkspaceOwner
        string WorkspaceTechOwner
        string WorkspaceApprover
        string WorkspaceEntraGroupUID
        string WorkspaceTag
        int DomainLoVId FK
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
        string ConcurrencyToken
    }
    
    WorkspaceApp {
        int Id PK
        int WorkspaceId FK
        string AppCode
        string AppName
        string AppOwner
        string AppTechnicalOwner
        string AppEntraGroupUID
        int OLSMode
        int ApprovalMode
        string Approvers
        string AdditionalQuestionsJSON
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
        string ConcurrencyToken
    }
    
    WorkspaceReport {
        int Id PK
        int WorkspaceId FK
        string ReportCode
        string ReportName
        string ReportOwner
        string ReportTechnicalOwner
        string ReportEntraGroupUID
        string Approvers
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
        string ConcurrencyToken
    }
    
    WorkspaceSecurityModel {
        int Id PK
        int WorkspaceId FK
        string SecurityModelCode UK
        string SecurityModelName
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
        string ConcurrencyToken
    }
    
    AppAudience {
        int Id PK
        int AppId FK
        string AudienceCode
        string AudienceName
        string AudienceEntraGroupUID
        string Approvers
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
        string ConcurrencyToken
    }
    
    ReportAppAudienceMap {
        int Id PK
        int ReportId FK
        int AppAudienceId FK
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
    }
    
    ReportSecurityModelMap {
        int Id PK
        int ReportId FK
        int SecurityModelId FK
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
    }
    
    SecurityModelSecurityTypeMap {
        int Id PK
        int SecurityModelId FK
        int SecurityTypeLoVId FK
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
    }
    
    LoV {
        int Id PK
        string LovType
        string LoVValue
        string LoVName
        string LoVDescription
        string ParentLoVType
        string ParentLoVValue
        bool IsActive
        DateTime CreatedAt
        string CreatedBy
        DateTime UpdatedAt
        string UpdatedBy
    }
```

## 19. Middleware Pipeline

**What This Diagram Shows:**
This diagram shows the order in which middleware components process HTTP requests. It shows the request flow through the ASP.NET Core pipeline.

**How to Read It:**
- Request flows left to right (top path)
- Response flows right to left (bottom path)
- Each box is a middleware component
- Order matters - middleware executes in sequence

**Example Flow:**
1. HTTP Request enters
2. SakuraStandardMiddleware adds custom headers
3. SakuraGlobalExceptionHandlerMiddleware sets up exception handling
4. Routing determines which controller to use
5. Authentication verifies user identity
6. Controller processes request
7. Response flows back through middleware (exception handler, standard middleware)
8. HTTP Response sent to client

**Technical Details:**
- **Middleware Pipeline**: Components that process requests/responses
- **Request Pipeline**: Top-to-bottom flow (incoming request)
- **Response Pipeline**: Bottom-to-top flow (outgoing response)
- **Exception Handler**: Catches all unhandled exceptions and converts to HTTP errors
- **Standard Middleware**: Adds custom headers (version info, correlation IDs, etc.)

```mermaid
graph LR
    subgraph "ASP.NET Core Pipeline"
        REQ[HTTP Request]
        MW1[SakuraStandardMiddleware<br/>Add Headers]
        MW2[SakuraGlobalExceptionHandlerMiddleware<br/>Exception Handling]
        ROUTE[Routing]
        AUTH[Authentication]
        CTRL[Controllers]
        RESP[HTTP Response]
    end
    
    REQ --> MW1
    MW1 --> MW2
    MW2 --> ROUTE
    ROUTE --> AUTH
    AUTH --> CTRL
    CTRL --> MW2
    MW2 --> MW1
    MW1 --> RESP
    
    style MW1 fill:#e1f5ff
    style MW2 fill:#e1f5ff
    style CTRL fill:#fff4e1
```

## 20. Dependency Injection Container

**What This Diagram Shows:**
This diagram shows how services are registered in the Dependency Injection (DI) container. It shows which interfaces map to which implementations and their lifetimes.

**How to Read It:**
- Each box shows an interface → implementation mapping
- Arrows show dependencies (which services use which other services)
- Scoped services are created once per HTTP request
- Singleton services are created once for the entire application lifetime

**Example:**
- `IWorkspaceService → WorkspaceService` means when code asks for IWorkspaceService, DI provides WorkspaceService instance
- All workspace services depend on `ISakuraUnitOfWork` (shown by arrows)
- `ISakuraUnitOfWork → UnitOfWork` depends on `SakuraDbContext`
- `SakuraDbContext` depends on `ISecretProvider` (to get connection string from Key Vault)

**Technical Details:**
- **Dependency Injection**: Services are provided by the framework, not created manually
- **Scoped Lifetime**: One instance per HTTP request (most services)
- **Singleton Lifetime**: One instance for entire application (configurations, secret providers)
- **Interface-Based**: Code depends on interfaces, not concrete classes (enables testing)
- **Constructor Injection**: Services are provided through constructor parameters

```mermaid
graph TB
    subgraph "IocContainerConfiguration"
        subgraph "Scoped Services"
            S1[IWorkspaceService → WorkspaceService]
            S2[IWorkspaceAppService → WorkspaceAppService]
            S3[IWorkspaceReportService → WorkspaceReportService]
            S4[IWorkspaceSecurityModelService → WorkspaceSecurityModelService]
            S5[IAppAudienceService → AppAudienceService]
            S6[IReportAppAudienceMapService → ReportAppAudienceMapService]
            S7[IReportSecurityModelMapService → ReportSecurityModelMapService]
            S8[IGenericRefService → GenericRefService]
            S9[ISakuraUnitOfWork → UnitOfWork]
            S10[ISakuraRepository → SakuraRepository]
            S11[ISakuraReadonlyRepository → SakuraReferenceRepository]
            S12[IObjectMapper → ObjectMapper]
            S13[ILoVService → LoVService]
            S14[IEnumService → EnumService]
            S15[ITokenService → TokenService]
        end
        
        subgraph "Singleton Services"
            SING1[ISecretProvider → AzureSecretProvider]
            SING2[TypeAdapterConfig → Mapster Config]
        end
        
        subgraph "DbContext"
            DB[SakuraDbContext<br/>Scoped Lifetime]
        end
    end
    
    S1 --> S9
    S2 --> S9
    S3 --> S9
    S4 --> S9
    S5 --> S9
    S6 --> S9
    S7 --> S9
    S8 --> S10
    S8 --> S11
    S9 --> DB
    S10 --> DB
    S11 --> DB
    S12 --> SING2
    DB --> SING1
    
    style S1 fill:#fff4e1
    style S9 fill:#fce4ec
    style DB fill:#fce4ec
    style SING1 fill:#e8f5e9
```

---

## Summary

This documentation provides a complete visual representation of the Sakura Backend architecture using Mermaid diagrams:

1. **Solution Level**: Project dependencies and relationships
2. **Layer Architecture**: High-level layer structure
3. **API Layer**: All controllers, middleware, configurations
4. **Application Layer**: All services, DTOs, validators
5. **Domain Layer**: Entity hierarchy and relationships
6. **Infrastructure Layer**: DbContext, repositories, UnitOfWork
7. **Request Flows**: Detailed sequence diagrams for CRUD operations
8. **Service Methods**: Complete method listings
9. **Repository Methods**: All repository operations
10. **Entity Relationships**: Complete ER diagrams
11. **Middleware Pipeline**: Request processing flow
12. **Dependency Injection**: Service registrations

All diagrams use Mermaid syntax and can be rendered in any Markdown viewer that supports Mermaid (GitHub, GitLab, VS Code, etc.).
