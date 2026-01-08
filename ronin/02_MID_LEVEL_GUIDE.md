# Ronin Application - Mid-Level Guide

## 🎯 Overview

This guide provides detailed technical information for developers, data engineers, and system analysts working with Ronin.

---

## 🏗️ System Architecture

### Complete Schema Architecture

```mermaid
graph TB
    subgraph "External Source Systems"
        SAP[SAP R3/BPC]
        D365[Dynamics 365]
        WD[Workday]
        UK1[UK Navision]
        UK2[UK Paprika]
        US[US NetSuite]
        AT[Austria BMD]
    end
    
    subgraph "Staging Layer"
        CS[Core_Staging<br/>Master Data Staging]
        SS[Synapse_Staging<br/>DW Enhancement Staging]
    end
    
    subgraph "Core Layer"
        Core[Core Schema<br/>Master Data]
        dbo[dbo Schema<br/>Operations]
    end
    
    subgraph "Enhancement Layer"
        Synapse[Synapse Schema<br/>Enhanced Dimensions]
        MDM[mdm Schema<br/>MDM & Reference]
    end
    
    subgraph "Reporting Layer"
        Views[Views]
        PBI[Power BI]
    end
    
    SAP --> CS
    D365 --> SS
    WD --> SS
    UK1 --> SS
    UK2 --> SS
    US --> SS
    AT --> SS
    
    CS -->|sp_Load_T_*| Core
    SS -->|sp_Load_*| Synapse
    
    Core --> dbo
    Synapse --> dbo
    MDM --> dbo
    
    dbo --> Views
    Views --> PBI
    
    style CS fill:#87CEEB
    style SS fill:#87CEEB
    style Core fill:#90EE90
    style dbo fill:#FFB6C1
    style Synapse fill:#DDA0DD
    style MDM fill:#F0E68C
```

---

## 🔄 Data Flow Patterns

### ETL Pattern (Extract, Transform, Load)

```mermaid
flowchart TD
    Start[External System] --> Extract[Extract Data]
    Extract --> Stage[Load to Staging]
    Stage --> Validate{Validate Data}
    Validate -->|Invalid| Reject[Reject/Log Error]
    Validate -->|Valid| Transform[Transform & Clean]
    Transform --> Merge[MERGE to Production]
    Merge --> Enhance[Enhancement Logic]
    Enhance --> Track[Track Pipeline]
    Track --> End[Production Ready]
    
    style Stage fill:#87CEEB
    style Transform fill:#FFD700
    style Merge fill:#90EE90
    style Enhance fill:#DDA0DD
```

### Detailed ETL Process

```mermaid
sequenceDiagram
    participant Source as Source System
    participant Stage as Staging Table
    participant SP as Load Procedure
    participant Core as Core/Production
    participant History as Change History
    
    Source->>Stage: 1. Bulk Insert/Import
    Note over Stage: Data lands in staging<br/>with PipelineInfo
    
    Stage->>SP: 2. Execute sp_Load_*
    Note over SP: MERGE Operation
    
    SP->>Core: 3. WHEN MATCHED: UPDATE
    SP->>Core: 4. WHEN NOT MATCHED: INSERT
    SP->>Core: 5. WHEN NOT MATCHED BY SOURCE: DELETE
    
    Core->>History: 6. Trigger Updates History
    Note over History: Change tracking<br/>automatic
```

---

## 📊 Schema Details

### Core Schema Structure

```mermaid
erDiagram
    T_Entity ||--o{ T_Client : "has"
    T_Client ||--o{ T_ClientGroupByCompany : "belongs_to"
    T_ClientGroup ||--o{ T_ClientGroupByCompany : "groups"
    T_Entity ||--o{ T_CostCenter : "has"
    T_CostCenter ||--o{ T_Employee : "assigned_to"
    T_Entity ||--o{ T_Employee : "employs"
    T_Account ||--o{ T_BudgetPosition : "used_in"
    T_Client ||--o{ T_BudgetHeader : "has"
    
    T_Entity {
        int CompanyId PK
        string CompanyCode
        string CompanyName
        string EntityBPCCode
    }
    T_Client {
        int ClientId PK
        string ClientSAPKey
        string ClientName1
        int ClientgroupId FK
    }
    T_Account {
        int AccountId PK
        int AccountSAPCode
        string BPCCode_L1
        string BPCCode_L2
        string BPCCode_L3
        string BPCCode_L4
    }
    T_Employee {
        int EmployeeId PK
        string Employeecode
        string EmployeeName
        int CostCenterId FK
        int CompanyId FK
    }
```

### Operational Schema (dbo) Structure

```mermaid
erDiagram
    T_Scenario ||--o{ T_BudgetHeader : "uses"
    T_Scenario ||--o{ T_OpexHeader : "uses"
    T_BudgetHeader ||--o{ T_BudgetPosition : "contains"
    T_OpexHeader ||--o{ T_OpexPosition : "contains"
    T_Account ||--o{ T_BudgetPosition : "references"
    T_Account ||--o{ T_OpexPosition : "references"
    T_Client ||--o{ T_BudgetHeader : "for"
    T_Year ||--o{ T_BudgetHeader : "for"
    T_Date ||--o{ T_BudgetPosition : "for"
    
    T_BudgetHeader ||--o{ T_BudgetHeaderChangeHistory : "tracks"
    T_BudgetPosition ||--o{ T_BudgetPositionChangeHistory : "tracks"
    
    T_BudgetHeader {
        int BudgetHeaderId PK
        int ClientId FK
        string Scenario
        int YearId FK
        string Status
    }
    T_BudgetPosition {
        int BudgetPositionId PK
        int BudgetHeaderId FK
        int AccountId FK
        int DateId FK
        decimal Amount
    }
    T_OpexHeader {
        int OpexHeaderId PK
        int ClientId FK
        string Scenario
        string Status
    }
    T_OpexPosition {
        int OpexPositionId PK
        int OpexHeaderId FK
        int AccountId FK
        decimal Amount
    }
```

---

## 🔧 Stored Procedures

### Load Procedures Pattern

All load procedures follow this pattern:

```mermaid
flowchart TD
    Start[sp_Load_T_TableName] --> Check{Data in<br/>Staging?}
    Check -->|No| End1[Exit]
    Check -->|Yes| Merge[MERGE Operation]
    
    Merge --> Match{Record<br/>Exists?}
    Match -->|Yes| Compare{Values<br/>Changed?}
    Match -->|No| Insert[INSERT New Record]
    
    Compare -->|Yes| Update[UPDATE Record]
    Compare -->|No| Skip[Skip - No Changes]
    
    Update --> Track[Update PipelineInfo]
    Insert --> Track
    Track --> Delete{Records in<br/>Production but<br/>not Staging?}
    
    Delete -->|Yes| DeleteOp[DELETE Orphaned]
    Delete -->|No| End2[Complete]
    DeleteOp --> End2
    
    style Merge fill:#FFD700
    style Update fill:#90EE90
    style Insert fill:#87CEEB
    style DeleteOp fill:#FF6347
```

### Key Stored Procedures

#### Budget & OPEX Procedures

```mermaid
graph LR
    subgraph "Budget Procedures"
        B1[spBudgetPosition_Add]
        B2[spOpexBudget_Add_Batch]
        B3[spOpexBudgetPosition_Add_Batch]
        B4[spOpexBudgetReopen]
    end
    
    subgraph "OPEX Procedures"
        O1[spOpexPosition_Add]
        O2[spOpexNEWPosition_Add_Batch]
        O3[spOpexReopen]
    end
    
    subgraph "Comparison Functions"
        C1[fn_BudgetPosition_Compare]
        C2[fn_OpexPosition_Compare]
        C3[fn_BudgetAdd_Compare]
    end
    
    B1 --> C1
    B2 --> C1
    O1 --> C2
    O2 --> C2
    
    style B1 fill:#90EE90
    style O1 fill:#FFB6C1
    style C1 fill:#DDA0DD
```

#### MDM Procedures

```mermaid
graph TD
    subgraph "DPC Management"
        D1[spDentsuParentClientMapClient]
        D2[spDentsuParentClientUnmapClient]
        D3[spDentsuParentClientMerge]
        D4[spDentsuParentClientDeactivateMap]
    end
    
    subgraph "MSH Management"
        M1[spMarketStakeholderCreate]
        M2[spMarketStakeholderMapClient]
        M3[spMarketStakeholderMerge]
        M4[spMarketStakeholderActivate]
    end
    
    D1 --> DPC[DentsuParentClient Table]
    D2 --> DPC
    D3 --> DPC
    M1 --> MSH[MarketStakeholder Table]
    M2 --> MSH
    M3 --> MSH
    
    style DPC fill:#FFD700
    style MSH fill:#FFA500
```

---

## 🔐 Security Model

### Security Architecture

```mermaid
graph TB
    User[User Login] --> Header{T_SecurityHeader}
    Header --> Detail[T_SecurityDetail]
    
    Detail --> Func1[fn_Sec_BPCL3<br/>Account Security]
    Detail --> Func2[fn_Sec_DccCam<br/>Cost Center/Agency]
    Detail --> Func3[fn_Sec_KSB<br/>Client Security]
    Detail --> Func4[fnGetDynamicRLS<br/>Dynamic RLS]
    
    Func1 --> Result1[Allowed Accounts]
    Func2 --> Result2[Allowed Cost Centers]
    Func3 --> Result3[Allowed Clients]
    Func4 --> Result4[Allowed Values]
    
    Result1 --> View[Views Apply Security]
    Result2 --> View
    Result3 --> View
    Result4 --> View
    
    View --> Data[Filtered Data]
    
    style Header fill:#FF6347
    style Detail fill:#FF8C00
    style View fill:#32CD32
```

### Security Flow

```mermaid
sequenceDiagram
    participant User
    participant View
    participant Security as Security Function
    participant Header as T_SecurityHeader
    participant Detail as T_SecurityDetail
    participant Data as Core Tables
    
    User->>View: Query Data
    View->>Security: Check Permissions
    Security->>Header: Get User Context
    Header->>Detail: Get Security Rules
    Detail->>Security: Return Rules
    Security->>Data: Filter by Rules
    Data->>Security: Return Filtered Data
    Security->>View: Return Allowed Data
    View->>User: Display Results
```

---

## 🔄 Integration Patterns

### Source System Integration Flow

```mermaid
flowchart LR
    subgraph "Source Systems"
        S1[SAP]
        S2[D365]
        S3[Workday]
        S4[Others]
    end
    
    subgraph "Staging"
        ST1[Synapse_Staging<br/>Raw Data]
    end
    
    subgraph "Enhancement"
        EN1[sp_Load_*<br/>Procedures]
        EN2[Business Logic]
        EN3[Enhancement Tables]
    end
    
    subgraph "Production"
        PR1[Synapse Schema<br/>Enhanced Data]
    end
    
    S1 --> ST1
    S2 --> ST1
    S3 --> ST1
    S4 --> ST1
    
    ST1 --> EN1
    EN1 --> EN2
    EN2 --> EN3
    EN3 --> PR1
    
    style ST1 fill:#87CEEB
    style EN2 fill:#FFD700
    style PR1 fill:#90EE90
```

### Enhancement Pattern Example (Workday)

```mermaid
sequenceDiagram
    participant WD as Workday System
    participant SS as Synapse_Staging.WD_Employee
    participant SP as sp_Load_WD_EmployeeEnhancements
    participant SE as Synapse.WD_EmployeeEnhancements
    participant Core as Core.T_Employee
    
    WD->>SS: 1. Export Employee Data
    Note over SS: Raw Workday data<br/>with all fields
    
    SS->>SP: 2. Execute Load Procedure
    Note over SP: Apply business rules<br/>Map to Core entities<br/>Add calculated fields
    
    SP->>SE: 3. MERGE to Enhancement
    Note over SE: Enhanced with<br/>- Cost Center mapping<br/>- Entity mapping<br/>- Status flags
    
    SE->>Core: 4. Reference in Operations
    Note over Core: Used in budgets<br/>and forecasts
    
    style SS fill:#87CEEB
    style SP fill:#FFD700
    style SE fill:#90EE90
```

---

## 📈 Change Tracking

### Change History Pattern

```mermaid
stateDiagram-v2
    [*] --> Insert: New Record
    Insert --> Update: Modify
    Update --> Update: Modify Again
    Update --> Delete: Remove
    Delete --> [*]
    
    note right of Insert
        Trigger fires
        Creates history record
    end note
    
    note right of Update
        Trigger fires
        Creates history record
        with old values
    end note
```

### Trigger Pattern

```mermaid
flowchart TD
    Start[User Action] --> Action{Action Type}
    
    Action -->|INSERT| Insert[INSERT Trigger]
    Action -->|UPDATE| Update[UPDATE Trigger]
    Action -->|DELETE| Delete[DELETE Trigger]
    
    Insert --> GetNew[Get inserted values]
    Update --> GetOld[Get deleted values]
    Update --> GetNew2[Get inserted values]
    Delete --> GetOld2[Get deleted values]
    
    GetNew --> Hist1[Insert into History]
    GetOld --> Hist2[Insert Old Values]
    GetNew2 --> Hist2
    GetOld2 --> Hist3[Insert Deleted Record]
    
    Hist1 --> End1[Complete]
    Hist2 --> End2[Complete]
    Hist3 --> End3[Complete]
    
    style Insert fill:#90EE90
    style Update fill:#FFD700
    style Delete fill:#FF6347
```

---

## 🎯 Business Process Flows

### Budget Creation Process

```mermaid
flowchart TD
    Start[Create Budget] --> CreateHeader[Create Budget Header]
    CreateHeader --> SetScenario[Set Scenario]
    SetScenario --> SetYear[Set Year]
    SetYear --> AddPositions[Add Budget Positions]
    
    AddPositions --> Validate{Validate<br/>Positions?}
    Validate -->|Invalid| Fix[Fix Errors]
    Fix --> AddPositions
    Validate -->|Valid| Submit[Submit Budget]
    
    Submit --> Approve{Approved?}
    Approve -->|No| Reject[Reject]
    Reject --> Fix
    Approve -->|Yes| Close[Close Budget]
    
    Close --> Reopen{Need<br/>Changes?}
    Reopen -->|Yes| ReopenProc[spOpexBudgetReopen]
    ReopenProc --> AddPositions
    Reopen -->|No| End[Complete]
    
    style CreateHeader fill:#90EE90
    style Submit fill:#FFD700
    style Close fill:#32CD32
```

### OPEX Forecasting Process

```mermaid
flowchart LR
    Start[Start Forecast] --> LoadActuals[Load Actuals]
    LoadActuals --> Compare[Compare to Budget]
    Compare --> Adjust[Adjust Forecast]
    Adjust --> Validate{Valid?}
    Validate -->|No| Adjust
    Validate -->|Yes| Save[Save Forecast]
    Save --> Report[Generate Reports]
    Report --> End[Complete]
    
    style LoadActuals fill:#87CEEB
    style Compare fill:#FFD700
    style Adjust fill:#FFB6C1
```

---

## 🔍 Views and Reporting

### View Hierarchy

```mermaid
graph TD
    subgraph "Base Tables"
        T1[T_BudgetHeader]
        T2[T_BudgetPosition]
        T3[T_OpexHeader]
        T4[T_OpexPosition]
        T5[T_ActualAmountDetail]
    end
    
    subgraph "Helper Views"
        V1[V_BudgetHelper]
        V2[V_ForecastHelper]
        V3[V_CubeBudgetHelper]
    end
    
    subgraph "Fact Views"
        F1[FactOpexForecast]
        F2[FactNBClientTracker]
    end
    
    subgraph "Comparison Views"
        C1[V_BudgetPosition_Compare]
        C2[V_OpexPosition_Compare]
    end
    
    T1 --> V1
    T2 --> V1
    T3 --> V2
    T4 --> V2
    T1 --> V3
    T2 --> V3
    
    V1 --> F1
    V2 --> F1
    V3 --> F1
    
    T2 --> C1
    T4 --> C2
    T5 --> C1
    T5 --> C2
    
    style T1 fill:#E6E6FA
    style V1 fill:#DDA0DD
    style F1 fill:#90EE90
    style C1 fill:#FFD700
```

---

## 🛠️ Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Data not appearing in Core after staging load

```mermaid
flowchart TD
    Problem[Data Missing] --> Check1{Staging has<br/>data?}
    Check1 -->|No| Fix1[Check source system]
    Check1 -->|Yes| Check2{Load procedure<br/>executed?}
    Check2 -->|No| Fix2[Execute sp_Load_*]
    Check2 -->|Yes| Check3{MERGE<br/>conditions met?}
    Check3 -->|No| Fix3[Check ON clause]
    Check3 -->|Yes| Check4{PipelineInfo<br/>set?}
    Check4 -->|No| Fix4[Check ETL process]
    Check4 -->|Yes| Success[Data should be there]
    
    style Problem fill:#FF6347
    style Success fill:#90EE90
```

#### Issue: Budget comparison showing wrong values

```mermaid
flowchart TD
    Problem[Wrong Comparison] --> Check1{Actuals<br/>loaded?}
    Check1 -->|No| Fix1[Load actuals]
    Check1 -->|Yes| Check2{Dates<br/>match?}
    Check2 -->|No| Fix2[Check date mapping]
    Check2 -->|Yes| Check3{Accounts<br/>match?}
    Check3 -->|No| Fix3[Check account mapping]
    Check3 -->|Yes| Check4{Scenario<br/>correct?}
    Check4 -->|No| Fix4[Check scenario filter]
    Check4 -->|Yes| Success[Should work]
    
    style Problem fill:#FF6347
    style Success fill:#90EE90
```

---

## 📝 Best Practices

### 1. Querying Data

```sql
-- ✅ Good: Use views when available
SELECT * FROM dbo.V_BudgetHelper WHERE YearId = 2024

-- ❌ Bad: Direct table access without understanding relationships
SELECT * FROM dbo.T_BudgetPosition
```

### 2. Understanding Dependencies

```mermaid
graph LR
    A[Need Budget Data] --> B{Use View or Table?}
    B -->|View Available| C[Use View<br/>V_BudgetHelper]
    B -->|View Not Available| D[Join Tables<br/>T_BudgetHeader<br/>T_BudgetPosition]
    
    C --> E[Apply Filters]
    D --> E
    E --> F[Get Results]
    
    style C fill:#90EE90
    style D fill:#FFD700
```

### 3. ETL Development

- Always use staging tables first
- Implement proper error handling
- Track pipeline execution (PipelineInfo, PipelineRunId)
- Use MERGE for idempotent operations
- Test with small datasets first

---

## 🔗 Next Steps

- → See [Senior Guide](./03_SENIOR_GUIDE.md) for architecture deep dive
- → Learn about performance optimization
- → Understand advanced security patterns
- → Explore system dependencies

---

**Key Takeaways**:
- Ronin uses a staging → core → operations pattern
- All ETL follows consistent MERGE patterns
- Security is function-based and applied in views
- Change tracking is automatic via triggers
- Views provide abstraction over complex joins
