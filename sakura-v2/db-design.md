# Sakura V2.0 - Complete SQL Server Database Guide

## 📚 Table of Contents
1. [Introduction & Overview](#introduction--overview)
2. [Database Architecture](#database-architecture)
3. [Core Foundation](#core-foundation)
4. [Security Models & Dimensions](#security-models--dimensions)
5. [Approval Flow System](#approval-flow-system)
6. [Request Management](#request-management)
7. [Supporting Systems](#supporting-systems)
8. [End-to-End Flow Examples](#end-to-end-flow-examples)
9. [Implementation Guide](#implementation-guide)

---

## Introduction & Overview

### What is Sakura V2.0?

**Sakura V2.0** is an **Access Request and Approval Management System** - think of it like a sophisticated security checkpoint system for a large corporate building, but for data access.

### 🏢 Real-World Analogy: The Corporate Building Access System

Imagine you work at a large multinational corporation with multiple buildings (Workspaces), floors (Apps), and rooms (Reports/Audiences). You can't just walk into any room - you need permissions:

```
🏢 Corporate Campus (Sakura System)
│
├── 🏛️ Building A (EMEA Workspace)
│   ├── 📊 Floor 3 (Finance App)
│   │   ├── 🚪 Room 301 (Revenue Report)
│   │   ├── 🚪 Room 302 (Budget Report)
│   │   └── 👥 Audience (Finance Team Members)
│   │
│   └── 📊 Floor 5 (HR App)
│       └── 🚪 Room 501 (Headcount Report)
│
├── 🏛️ Building B (WFI Workspace)
│   └── 📊 Floor 2 (Workforce App)
│       └── 🚪 Room 201 (Staffing Report)
│
└── 🔐 Security Checkpoint (Approval System)
    ├── 👤 Your Manager (LM - Line Manager)
    ├── 🔑 Building Owner (OLS - Object Level Security)
    └── 📋 Floor/Department Head (RLS - Row Level Security)
```

### The Approval Journey

When you need access to Room 301 (a specific report), you must:

1. **Ask Your Manager First** (LM Approval)
   - Like getting permission from your direct supervisor
   - They verify: "Does this person need this for their job?"

2. **Get Building/Floor Owner Approval** (OLS Approval)
   - The owner of that specific floor/room decides
   - They verify: "Should this person have access to this room?"

3. **Specify What You Can See Inside** (RLS Approval)
   - Once in the room, what files can you access?
   - Like having access to only certain file cabinets:
     - Only France data (not Germany)
     - Only Marketing budget (not Engineering)
     - Only your cost center (not others)

### The Three Security Layers

```
┌─────────────────────────────────────────────┐
│  Layer 1: Line Manager (LM)                 │
│  Question: "Does this person need access?"  │
│  Real-world: Your direct supervisor         │
└─────────────────────────────────────────────┘
              ↓ (Approved)
┌─────────────────────────────────────────────┐
│  Layer 2: Object Level Security (OLS)       │
│  Question: "Can they access this            │
│            Report/Audience/App?"            │
│  Real-world: Building/Room owner            │
└─────────────────────────────────────────────┘
              ↓ (Approved)
┌─────────────────────────────────────────────┐
│  Layer 3: Row Level Security (RLS)          │
│  Question: "What data can they see inside?" │
│  Real-world: File cabinet permissions       │
└─────────────────────────────────────────────┘
```

---

## Database Architecture

### Schema Organization

The Sakura database uses **7 schemas** - think of them as organized filing cabinets in an office:

| Schema | Purpose | Real-World Analogy |
|--------|---------|-------------------|
| **core** | Domain objects (Users, Workspaces, Apps, Reports) | The main office directory and building registry |
| **sec** | Security models, dimensions, approvers | The security office with access control lists |
| **req** | Requests and approvals | The request forms filing cabinet |
| **admin** | Settings, email templates, help | The admin office with configuration files |
| **log** | Audit trails and logging | The security camera recordings and logbook |
| **imp** | Imported data from external systems | The mailroom receiving external documents |
| **shr** | Read-only views for data sharing | The public information board |

### Database Design Principles

```
┌────────────────────────────────────────────────────────┐
│ PRINCIPLE 1: Identity & Tracking                       │
│ Every table has: IDENTITY(1,1) BIGINT Primary Key     │
│ Why: Like giving every document a unique ID number     │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ PRINCIPLE 2: Time & History                            │
│ All times: DATETIME2(3) in UTC                         │
│ Soft deletes: IsActive BIT                            │
│ History: ValidFrom/ValidTo                            │
│ Why: Like stamping documents with dates and keeping   │
│      old versions instead of shredding them            │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ PRINCIPLE 3: Who & When                                │
│ Track: CreatedAt, UpdatedAt, CreatedBy                │
│ Why: Always know who did what and when                │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ PRINCIPLE 4: Referential Integrity                     │
│ Foreign Keys everywhere (strict enforcement)           │
│ Cascading deletes only where safe                     │
│ Why: Like ensuring every reference points to          │
│      an actual document, no broken links              │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ PRINCIPLE 5: Extensibility via LoV Tables             │
│ Lookup Values (LoV) for enumerations                  │
│ Why: Admin can add new types without code changes     │
└────────────────────────────────────────────────────────┘
```

### High-Level Database Flow

```
                    ┌─────────────────┐
                    │   CORE SCHEMA   │
                    │  (The Building) │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐      ┌────▼────┐      ┌─────▼─────┐
    │ Workspaces│      │  Users  │      │   Apps    │
    │  (Buildings)│    │(People) │      │  (Floors) │
    └─────┬─────┘      └────┬────┘      └─────┬─────┘
          │                  │                  │
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │   SEC SCHEMA    │
                    │ (Security Office)│
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼──────┐    ┌─────▼──────┐    ┌─────▼──────┐
    │ Security   │    │ Dimensions │    │ Approvers  │
    │  Models    │    │  (Filters) │    │(Gatekeepers)│
    └─────┬──────┘    └─────┬──────┘    └─────┬──────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │   REQ SCHEMA    │
                    │  (Request Forms)│
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐      ┌────▼────┐      ┌─────▼─────┐
    │ Requests  │      │   OLS   │      │    RLS    │
    │ (Applications)   │(Room    │      │ (File     │
    │           │      │ Access) │      │  Cabinet) │
    └───────────┘      └─────────┘      └───────────┘
```

---

## Core Foundation

This section covers the fundamental building blocks - the "who, what, and where" of the system.

### 1. Lookup Values (LoV Tables)

**Real-World Analogy:** These are like dropdown lists on forms - predefined choices that keep data consistent.

#### Step 1: Create All Schemas

```sql
-- Think of these as creating different filing cabinets
CREATE SCHEMA core;   -- Main business objects
CREATE SCHEMA sec;    -- Security & permissions
CREATE SCHEMA req;    -- Requests & approvals
CREATE SCHEMA admin;  -- System settings
CREATE SCHEMA log;    -- Audit trails
CREATE SCHEMA imp;    -- External data imports
CREATE SCHEMA shr;    -- Shared read-only views
GO
```

#### Step 2: Catalog Item Types

```sql
-- What types of things can users request access to?
CREATE TABLE core.CatalogItemTypeLoV(
  CatalogItemTypeCode VARCHAR(20) PRIMARY KEY,
  DisplayName         NVARCHAR(50) NOT NULL
);

-- Insert the three types
INSERT core.CatalogItemTypeLoV VALUES 
  ('Report', 'Report'),
  ('App', 'Workspace App'),
  ('Audience', 'App Audience');
```

**Real-World Example:**
```
Report    = A specific document (like "Q4 Revenue Report")
App       = An entire application (like "Finance Dashboard")
Audience  = A group of people who see related reports (like "CFO Team")
```

#### Step 3: Approval Stages

```sql
-- The three approval gates everyone must pass through
CREATE TABLE req.ApprovalStageLoV(
  ApprovalStageCode VARCHAR(10) PRIMARY KEY,
  StageOrder        TINYINT NOT NULL UNIQUE CHECK(StageOrder BETWEEN 1 AND 3)
);

INSERT req.ApprovalStageLoV VALUES 
  ('LM', 1),   -- Line Manager (your boss)
  ('OLS', 2),  -- Object Level Security (data owner)
  ('RLS', 3);  -- Row Level Security (granular access)
```

**Flow Visualization:**
```
Request Submitted
      ↓
[Stage 1: LM]  ← Your direct manager
      ↓ (Approved)
[Stage 2: OLS] ← Report/App owner
      ↓ (Approved)
[Stage 3: RLS] ← Data domain approver
      ↓ (Approved)
Access Granted! ✅
```

#### Step 4: Decision Types

```sql
-- What can happen to a request?
CREATE TABLE req.DecisionLoV(
  DecisionCode VARCHAR(12) PRIMARY KEY,
  IsTerminal   BIT NOT NULL DEFAULT 0  -- Does this end the request?
);

INSERT req.DecisionLoV VALUES 
  ('Pending', 0),    -- Still waiting
  ('Approved', 1),   -- Approved (terminal)
  ('Rejected', 1),   -- Rejected (terminal - no more processing)
  ('Revoked', 1);    -- Access removed after approval (terminal)
```

**Real-World Example:**
```
Pending  = Your application is being reviewed
Approved = You got the keys to the room ✅
Rejected = Access denied ❌
Revoked  = Keys taken back (you had access, now removed) 🔒
```

#### Step 5: Security Type Lookups

```sql
-- Different ways data can be filtered/restricted
CREATE TABLE sec.SecurityTypeLoV(
  SecurityTypeCode VARCHAR(20) PRIMARY KEY,
  DisplayName      NVARCHAR(80) NOT NULL
);

INSERT sec.SecurityTypeLoV VALUES
  ('ORGA', 'Organization (Entity + Service Line)'),
  ('Client', 'Client'),
  ('CC', 'Cost Center'),
  ('MSS', 'Master Service Set'),
  ('Country', 'Country'),
  ('PC', 'Profit Center'),
  ('SLPA', 'Service Line / Practice Area'),
  ('WFI', 'Workforce Fixed Type');
```

**Real-World Example:**
When you get access to the "Revenue Report", you might be restricted by:
- **ORGA**: Only see data from "Dentsu France" (not Germany)
- **Client**: Only see data for "Nike" (not Adidas)
- **CC**: Only see Cost Center 1234 (not 5678)
- **Country**: Only see France data (not UK)

#### Step 6: Approval Mode

```sql
-- How are OLS approvals determined?
CREATE TABLE sec.ApprovalModeLoV(
  ApprovalModeCode VARCHAR(20) PRIMARY KEY,
  DisplayName      NVARCHAR(50) NOT NULL
);

INSERT sec.ApprovalModeLoV VALUES
  ('AppBased', 'App Based'),
  ('AudienceBased', 'Audience Based');
```

**Real-World Example:**
```
AppBased:
  - One set of approvers for the entire Finance App
  - Like having one key holder for the whole floor

AudienceBased:
  - Different approvers for "CFO Audience" vs "Accountants Audience"
  - Like having different key holders for different rooms on the same floor
```

---

### 2. Users Table

```sql
-- The people in the system
CREATE TABLE core.Users(
  UserId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  UPN           NVARCHAR(256) NOT NULL UNIQUE,  -- user@dentsu.com
  DisplayName   NVARCHAR(200) NULL,
  EntraObjectId UNIQUEIDENTIFIER NULL,  -- Azure AD reference
  IsActive      BIT NOT NULL DEFAULT 1,
  CreatedAt     DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt     DATETIME2(3) NULL
);
```

**Real-World Analogy:** This is your employee directory - everyone who can use the system.

**Key Points:**
- `UPN` = Email address (user@dentsu.com) - your unique identifier
- `EntraObjectId` = Azure Active Directory ID (for single sign-on)
- `IsActive` = Still employed? (soft delete - never actually delete users for audit trail)

**Example Data:**
```sql
INSERT core.Users (UPN, DisplayName, EntraObjectId, IsActive) VALUES
  ('john.doe@dentsu.com', 'John Doe', 'a1b2c3...', 1),
  ('jane.smith@dentsu.com', 'Jane Smith', 'd4e5f6...', 1);
```

---

### 3. Line Manager Relationships

```sql
-- Who reports to whom? (imported from Workday/UMS)
CREATE TABLE imp.LineManager(
  LineManagerId BIGINT IDENTITY(1,1) PRIMARY KEY,
  EmployeeUPN   NVARCHAR(256) NOT NULL,
  ManagerUPN    NVARCHAR(256) NOT NULL,
  ValidFrom     DATETIME2(3) NOT NULL,
  ValidTo       DATETIME2(3) NULL,
  CONSTRAINT UQ_LineMgr UNIQUE(EmployeeUPN, ValidFrom)
);
```

**Real-World Analogy:** This is the organizational chart showing who your boss is.

**Why History (ValidFrom/ValidTo)?**
```
John's manager history:
2023-01-01 to 2023-06-30: Manager = Sarah
2023-07-01 to NULL:       Manager = Michael

When reviewing a request from June 2023, we need to know 
Sarah was the manager then, not Michael!
```

**Example Data:**
```sql
INSERT imp.LineManager (EmployeeUPN, ManagerUPN, ValidFrom, ValidTo) VALUES
  ('john.doe@dentsu.com', 'sarah.jones@dentsu.com', '2023-01-01', '2023-06-30'),
  ('john.doe@dentsu.com', 'michael.brown@dentsu.com', '2023-07-01', NULL);
```

---

### 4. Workspaces (Buildings)

```sql
-- The top-level container - like different buildings in a campus
CREATE TABLE core.Workspaces(
  WorkspaceId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceCode  VARCHAR(20) NOT NULL UNIQUE,
  WorkspaceName  NVARCHAR(200) NOT NULL,
  OwnerUPN       NVARCHAR(256) NULL,      -- Business owner
  TechOwnerUPN   NVARCHAR(256) NULL,      -- Technical owner
  IsActive       BIT NOT NULL DEFAULT 1,
  CreatedAt      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt      DATETIME2(3) NULL
);
```

**Real-World Example:**
```
Workspace: EMEA (Europe, Middle East, Africa)
  Owner: Regional VP
  TechOwner: IT Manager for EMEA

Workspace: WFI (Workforce Intelligence)
  Owner: Global HR Director
  TechOwner: HR Systems Admin
```

**Example Data:**
```sql
INSERT core.Workspaces (WorkspaceCode, WorkspaceName, OwnerUPN, TechOwnerUPN) VALUES
  ('EMEA', 'EMEA Regional Workspace', 'emea.vp@dentsu.com', 'emea.tech@dentsu.com'),
  ('WFI', 'Workforce Intelligence', 'hr.director@dentsu.com', 'hr.tech@dentsu.com'),
  ('AMER', 'Americas Workspace', 'amer.vp@dentsu.com', 'amer.tech@dentsu.com');
```

---

### 5. Apps (Floors within Buildings)

```sql
-- Applications within a workspace
CREATE TABLE core.WorkspaceApps(
  AppId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId       BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  AppCode           VARCHAR(50) NOT NULL,
  AppName           NVARCHAR(200) NOT NULL,
  ApprovalModeCode  VARCHAR(20) NOT NULL REFERENCES sec.ApprovalModeLoV(ApprovalModeCode),
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(3) NULL,
  CONSTRAINT UQ_App UNIQUE(WorkspaceId, AppCode)
);
```

**Real-World Hierarchy:**
```
🏢 EMEA Workspace (Building)
  ├── 📊 Finance App (Floor 1)
  ├── 📊 HR App (Floor 2)
  └── 📊 Sales App (Floor 3)

🏢 WFI Workspace (Building)
  └── 📊 Staffing Analytics App (Floor 1)
```

**Example Data:**
```sql
-- Get WorkspaceId for EMEA first
DECLARE @EMEAWorkspaceId BIGINT = (SELECT WorkspaceId FROM core.Workspaces WHERE WorkspaceCode = 'EMEA');

INSERT core.WorkspaceApps (WorkspaceId, AppCode, AppName, ApprovalModeCode) VALUES
  (@EMEAWorkspaceId, 'FIN', 'Finance Dashboard', 'AudienceBased'),
  (@EMEAWorkspaceId, 'HR', 'HR Analytics', 'AppBased'),
  (@EMEAWorkspaceId, 'SALES', 'Sales Performance', 'AudienceBased');
```

---

### 6. Audiences (Rooms/Groups within Apps)

```sql
-- Groups of users who see related content within an app
CREATE TABLE core.AppAudiences(
  AudienceId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  AppId           BIGINT NOT NULL REFERENCES core.WorkspaceApps(AppId),
  AudienceCode    VARCHAR(50) NOT NULL,
  AudienceName    NVARCHAR(200) NOT NULL,
  EntraGroupUid   UNIQUEIDENTIFIER NULL,  -- Azure AD Group for distribution
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  CONSTRAINT UQ_Audience UNIQUE(AppId, AudienceCode)
);
```

**Real-World Example:**
```
Finance Dashboard App
  ├── 👥 CFO Audience (executives)
  ├── 👥 Controllers Audience (finance managers)
  └── 👥 Analysts Audience (junior analysts)

Each audience sees different reports:
  CFO Audience: Strategic reports, board presentations
  Controllers: Detailed budgets, forecasts
  Analysts: Operational reports, data extracts
```

**Example Data:**
```sql
-- Get AppId for Finance Dashboard
DECLARE @FinAppId BIGINT = (SELECT AppId FROM core.WorkspaceApps WHERE AppCode = 'FIN');

INSERT core.AppAudiences (AppId, AudienceCode, AudienceName) VALUES
  (@FinAppId, 'CFO', 'CFO Executive Audience'),
  (@FinAppId, 'CTRL', 'Controllers Audience'),
  (@FinAppId, 'ANLY', 'Analysts Audience');
```

---

### 7. Reports (Documents/Files)

```sql
-- Individual reports in the system
CREATE TABLE core.Reports(
  ReportId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId     BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  ReportCode      VARCHAR(80) NOT NULL,
  ReportName      NVARCHAR(200) NOT NULL,
  ReportTag       VARCHAR(120) NULL,        -- For deep-linking/cataloging
  OwnerUPN        NVARCHAR(256) NULL,       -- Report owner
  EntraGroupUid   UNIQUEIDENTIFIER NULL,    -- For SAR (Single Access Report)
  DeliveryMethod  VARCHAR(10) NOT NULL CHECK (DeliveryMethod IN ('SAR','AUR')),
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  CONSTRAINT UQ_Report UNIQUE(WorkspaceId, ReportCode)
);
```

**Delivery Methods Explained:**

```
SAR (Single Access Report):
  - Individual report access
  - Like requesting access to one specific document
  - Example: "Q4 Revenue Report"
  
AUR (Audience-based Report):
  - Report delivered through audience membership
  - Like getting access to all documents in a shared folder
  - Example: All reports in "CFO Audience"
```

**Real-World Example:**
```
🏢 EMEA Workspace
  📄 Revenue Report (SAR) - request individually
  📄 Budget Report (SAR) - request individually
  📄 Executive Dashboard (AUR) - comes with CFO Audience access
```

**Example Data:**
```sql
DECLARE @EMEAWorkspaceId BIGINT = (SELECT WorkspaceId FROM core.Workspaces WHERE WorkspaceCode = 'EMEA');

INSERT core.Reports (WorkspaceId, ReportCode, ReportName, OwnerUPN, DeliveryMethod) VALUES
  (@EMEAWorkspaceId, 'REV_Q4_2024', 'Q4 2024 Revenue Report', 'finance.owner@dentsu.com', 'SAR'),
  (@EMEAWorkspaceId, 'BUDGET_2025', '2025 Budget Report', 'finance.owner@dentsu.com', 'SAR'),
  (@EMEAWorkspaceId, 'EXEC_DASH', 'Executive Dashboard', 'cfo@dentsu.com', 'AUR');
```

---

### 8. Audience-Report Mapping

```sql
-- Which reports belong to which audience (only for AUR reports)
CREATE TABLE core.AudienceReports(
  AudienceReportId BIGINT IDENTITY(1,1) PRIMARY KEY,
  AudienceId       BIGINT NOT NULL REFERENCES core.AppAudiences(AudienceId),
  ReportId         BIGINT NOT NULL REFERENCES core.Reports(ReportId),
  IsActive         BIT NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UNIQUE(AudienceId, ReportId)
);
```

**Real-World Example:**
```
CFO Audience gets access to:
  ✓ Executive Dashboard
  ✓ Board Presentation Report
  ✓ Strategic Planning Report

Controllers Audience gets access to:
  ✓ Detailed Budget Report
  ✓ Forecast Report
  ✓ Variance Analysis Report
```

**Example Data:**
```sql
-- Get IDs
DECLARE @CFOAudienceId BIGINT = (SELECT AudienceId FROM core.AppAudiences WHERE AudienceCode = 'CFO');
DECLARE @ExecDashReportId BIGINT = (SELECT ReportId FROM core.Reports WHERE ReportCode = 'EXEC_DASH');

INSERT core.AudienceReports (AudienceId, ReportId) VALUES
  (@CFOAudienceId, @ExecDashReportId);
```

---

### Core Foundation Summary

**What we've built so far:**

```
┌──────────────────────────────────────────────────────┐
│  CORE SCHEMA COMPLETE                                │
│                                                      │
│  ✓ Users (people)                                   │
│  ✓ Line Manager relationships (org chart)          │
│  ✓ Workspaces (buildings)                          │
│  ✓ Apps (floors)                                    │
│  ✓ Audiences (groups/rooms)                        │
│  ✓ Reports (documents)                             │
│  ✓ Report-to-Audience mapping                      │
│                                                      │
│  This is the "WHAT" - what exists in the system    │
│  Next: The "WHO CAN" - security models             │
└──────────────────────────────────────────────────────┘
```

---

## Security Models & Dimensions

This is where it gets interesting - the **WHO CAN SEE WHAT DATA** layer.

### 🎯 Real-World Analogy: The Filing Cabinet with Labeled Drawers

Imagine you get access to a filing cabinet (a Report). But the cabinet has many drawers, each labeled:
- **Entity Drawer**: France, Germany, UK
- **Client Drawer**: Nike, Adidas, Puma
- **Cost Center Drawer**: CC-1234, CC-5678, CC-9999

You don't get to open ALL drawers - only specific ones:
```
John's Access:
  ✓ Can open France drawer (not Germany/UK)
  ✓ Can open Nike drawer (not Adidas/Puma)
  ✓ Can open CC-1234 drawer (not CC-5678/CC-9999)
```

This is **Row-Level Security (RLS)** - filtering data based on dimensions.

---

### 1. Security Models

```sql
-- Each workspace can have one or more security models
CREATE TABLE sec.SecurityModels(
  SecurityModelId BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId     BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  SecurityModelCode VARCHAR(50) NOT NULL,
  SecurityModelName NVARCHAR(200) NOT NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  UNIQUE(WorkspaceId, SecurityModelCode)
);
```

**Real-World Example:**

```
🏢 EMEA Workspace
  └── 🔒 "EMEA_STD_MODEL" (Standard Security Model)
      - Used for most EMEA reports
      - Has 5 security types: ORGA, Client, CC, MSS, Country

🏢 WFI Workspace
  └── 🔒 "WFI_FIXED_MODEL" (Fixed Security Model)
      - Simpler model for workforce data
      - Has 1 security type: WFI (Entity → People Aggregator)
```

**Example Data:**
```sql
DECLARE @EMEAWorkspaceId BIGINT = (SELECT WorkspaceId FROM core.Workspaces WHERE WorkspaceCode = 'EMEA');
DECLARE @WFIWorkspaceId BIGINT = (SELECT WorkspaceId FROM core.Workspaces WHERE WorkspaceCode = 'WFI');

INSERT sec.SecurityModels (WorkspaceId, SecurityModelCode, SecurityModelName) VALUES
  (@EMEAWorkspaceId, 'EMEA_STD', 'EMEA Standard Security Model'),
  (@WFIWorkspaceId, 'WFI_FIXED', 'WFI Fixed Security Model');
```

---

### 2. Security Dimensions

```sql
-- The "dimensions" you can filter by
CREATE TABLE sec.SecurityDimensions(
  SecurityDimensionId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityDimensionCode VARCHAR(20) NOT NULL UNIQUE,
  SecurityDimensionName NVARCHAR(100) NOT NULL,
  IsHierarchical   BIT NOT NULL DEFAULT 0  -- Does it have parent-child relationships?
);
```

**Real-World Example:**

```
Non-Hierarchical Dimensions (flat lists):
  ✓ Client: [Nike, Adidas, Puma] - no parent-child
  ✓ Country: [France, Germany, UK] - simple list

Hierarchical Dimensions (tree structure):
  Entity:
    Global
      ├── Region: EMEA
      │   ├── Cluster: Europe
      │   │   └── Market: France
      │   └── Cluster: Middle East
      │       └── Market: UAE
      └── Region: Americas
          └── Cluster: North America
              └── Market: USA

  Master Service Set (MSS):
    MSS L1: Creative
      └── MSS L2: Brand Design
          └── MSS L3: Logo Design
              └── MSS L4: Digital Logos
```

**Example Data:**
```sql
INSERT sec.SecurityDimensions(SecurityDimensionCode, SecurityDimensionName, IsHierarchical) VALUES
  ('ENT', 'Entity', 1),              -- Hierarchical
  ('SL', 'Service Line', 1),         -- Hierarchical
  ('CL', 'Client', 0),               -- Flat
  ('CC', 'Cost Center', 1),          -- Hierarchical
  ('CTY', 'Country', 1),             -- Hierarchical
  ('PC', 'Profit Center', 1),        -- Hierarchical
  ('MSS', 'Master Service Set', 1),  -- Hierarchical
  ('WFIAGG', 'WFI People Aggregator', 1); -- Hierarchical
```

---

### 3. Security Type to Dimension Mapping

```sql
-- For a given Security Model and Security Type, what dimensions are needed?
CREATE TABLE sec.SecurityTypeDimension(
  SecurityModelId     BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode    VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  SecurityDimensionId BIGINT NOT NULL REFERENCES sec.SecurityDimensions(SecurityDimensionId),
  StepOrder           TINYINT NOT NULL,  -- Order in the wizard
  PRIMARY KEY(SecurityModelId, SecurityTypeCode, SecurityDimensionId)
);
```

**Real-World Example - EMEA Workspace:**

```
EMEA Security Model has 5 Security Types:

1. ORGA (Organization):
   Step 1: Entity dimension
   Step 2: Service Line dimension

2. Client:
   Step 1: Client dimension

3. Cost Center (CC):
   Step 1: Cost Center dimension

4. MSS (Master Service Set):
   Step 1: Entity dimension
   Step 2: MSS dimension

5. Country:
   Step 1: Country dimension
```

**Visual Flow:**
```
User requests "ORGA" type access:
  
  Wizard Step 1: Select Entity
    ┌──────────────────────┐
    │ Choose your Entity:  │
    │ ○ France             │
    │ ○ Germany            │
    │ ○ UK                 │
    └──────────────────────┘
            ↓
  Wizard Step 2: Select Service Line
    ┌──────────────────────┐
    │ Choose Service Line: │
    │ ○ Creative           │
    │ ○ Media              │
    │ ○ Technology         │
    └──────────────────────┘
```

**Example Data:**
```sql
DECLARE @EMEAModelId BIGINT = (SELECT SecurityModelId FROM sec.SecurityModels WHERE SecurityModelCode = 'EMEA_STD');
DECLARE @EntityDimId BIGINT = (SELECT SecurityDimensionId FROM sec.SecurityDimensions WHERE SecurityDimensionCode = 'ENT');
DECLARE @SLDimId BIGINT = (SELECT SecurityDimensionId FROM sec.SecurityDimensions WHERE SecurityDimensionCode = 'SL');
DECLARE @ClientDimId BIGINT = (SELECT SecurityDimensionId FROM sec.SecurityDimensions WHERE SecurityDimensionCode = 'CL');

-- ORGA type needs Entity (step 1) and Service Line (step 2)
INSERT sec.SecurityTypeDimension (SecurityModelId, SecurityTypeCode, SecurityDimensionId, StepOrder) VALUES
  (@EMEAModelId, 'ORGA', @EntityDimId, 1),
  (@EMEAModelId, 'ORGA', @SLDimId, 2);

-- Client type needs only Client dimension (step 1)
INSERT sec.SecurityTypeDimension (SecurityModelId, SecurityTypeCode, SecurityDimensionId, StepOrder) VALUES
  (@EMEAModelId, 'Client', @ClientDimId, 1);
```

---

### 4. Dimension Source Data (Imported)

```sql
-- Actual dimension values imported from external systems (UMS/EDP)
CREATE TABLE imp.DimensionSource(
  DimensionSourceId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityDimensionId BIGINT NOT NULL REFERENCES sec.SecurityDimensions(SecurityDimensionId),
  NaturalKey        NVARCHAR(200) NOT NULL,   -- The actual code (e.g., "MKT_FR", "CLIENT_001")
  ParentNaturalKey  NVARCHAR(200) NULL,       -- For hierarchies
  LevelName         NVARCHAR(50) NULL,        -- Market, Cluster, Region, Global
  DisplayName       NVARCHAR(200) NOT NULL,   -- What users see
  ExtraJSON         NVARCHAR(MAX) NULL,       -- Additional metadata
  ValidFrom         DATETIME2(3) NOT NULL,
  ValidTo           DATETIME2(3) NULL,
  UNIQUE(SecurityDimensionId, NaturalKey, ValidFrom)
);

CREATE INDEX IX_imp_DimensionSource_Parent 
  ON imp.DimensionSource(SecurityDimensionId, ParentNaturalKey, ValidFrom);
```

**Real-World Example - Entity Hierarchy:**

```
Global Level: "GLOBAL"
  │
  ├─ Region Level: "EMEA"
  │   │
  │   ├─ Cluster Level: "EUROPE"
  │   │   │
  │   │   ├─ Market Level: "FRANCE"
  │   │   ├─ Market Level: "GERMANY"
  │   │   └─ Market Level: "UK"
  │   │
  │   └─ Cluster Level: "MIDDLE_EAST"
  │       └─ Market Level: "UAE"
  │
  └─ Region Level: "AMERICAS"
      └─ Cluster Level: "NORTH_AMERICA"
          └─ Market Level: "USA"
```

**Example Data:**
```sql
DECLARE @EntityDimId BIGINT = (SELECT SecurityDimensionId FROM sec.SecurityDimensions WHERE SecurityDimensionCode = 'ENT');

-- Insert Entity hierarchy
INSERT imp.DimensionSource (SecurityDimensionId, NaturalKey, ParentNaturalKey, LevelName, DisplayName, ValidFrom) VALUES
  -- Global
  (@EntityDimId, 'GLOBAL', NULL, 'Global', 'Global', '2020-01-01'),
  
  -- Regions
  (@EntityDimId, 'EMEA', 'GLOBAL', 'Region', 'EMEA Region', '2020-01-01'),
  (@EntityDimId, 'AMERICAS', 'GLOBAL', 'Region', 'Americas Region', '2020-01-01'),
  
  -- Clusters
  (@EntityDimId, 'EUROPE', 'EMEA', 'Cluster', 'Europe Cluster', '2020-01-01'),
  (@EntityDimId, 'MIDDLE_EAST', 'EMEA', 'Cluster', 'Middle East Cluster', '2020-01-01'),
  (@EntityDimId, 'NORTH_AMERICA', 'AMERICAS', 'Cluster', 'North America Cluster', '2020-01-01'),
  
  -- Markets
  (@EntityDimId, 'MKT_FR', 'EUROPE', 'Market', 'France', '2020-01-01'),
  (@EntityDimId, 'MKT_DE', 'EUROPE', 'Market', 'Germany', '2020-01-01'),
  (@EntityDimId, 'MKT_UK', 'EUROPE', 'Market', 'United Kingdom', '2020-01-01'),
  (@EntityDimId, 'MKT_UAE', 'MIDDLE_EAST', 'Market', 'UAE', '2020-01-01'),
  (@EntityDimId, 'MKT_USA', 'NORTH_AMERICA', 'Market', 'USA', '2020-01-01');
```

**Why History?**
```
Client "Nike" was called "Nike Inc" until 2023-06-01:

NaturalKey='CLIENT_001', DisplayName='Nike Inc', ValidFrom='2020-01-01', ValidTo='2023-05-31'
NaturalKey='CLIENT_001', DisplayName='Nike', ValidFrom='2023-06-01', ValidTo=NULL

This preserves what the name was when the access was granted!
```

---

### 5. Entity Hierarchy Helper Table

```sql
-- Flattened hierarchy for fast traversal (used in approver lookup)
CREATE TABLE sec.EntityHierarchy(
  SecurityModelId BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  LevelName       NVARCHAR(50) NOT NULL,
  NaturalKey      NVARCHAR(200) NOT NULL,
  ParentNaturalKey NVARCHAR(200) NULL,
  PRIMARY KEY(SecurityModelId, LevelName, NaturalKey)
);
```

**Real-World Use Case:**

When you request access to "France" (Market level), the system looks for RLS approvers:
1. Check for approver at Market level (France) ← Start here
2. If not found, check Cluster level (Europe)
3. If not found, check Region level (EMEA)
4. If not found, check Global level

This is like escalating to higher management when your immediate boss is unavailable!

**Example Data:**
```sql
DECLARE @EMEAModelId BIGINT = (SELECT SecurityModelId FROM sec.SecurityModels WHERE SecurityModelCode = 'EMEA_STD');

INSERT sec.EntityHierarchy (SecurityModelId, LevelName, NaturalKey, ParentNaturalKey) VALUES
  -- Market → Cluster → Region → Global chain
  (@EMEAModelId, 'Market', 'MKT_FR', 'EUROPE'),
  (@EMEAModelId, 'Cluster', 'EUROPE', 'EMEA'),
  (@EMEAModelId, 'Region', 'EMEA', 'GLOBAL'),
  (@EMEAModelId, 'Global', 'GLOBAL', NULL);
```

---

### 6. OLS Approvers

```sql
-- Who approves Object-Level Security (access to Report/App/Audience)?
CREATE TABLE sec.OLSApprovers(
  OLSApproverId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId   BIGINT NOT NULL,  -- ReportId, AppId, or AudienceId
  ApproverUPN     NVARCHAR(256) NOT NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
```

**Real-World Example:**

```
Revenue Report (SAR):
  OLS Approvers: 
    - finance.director@dentsu.com
    - cfo@dentsu.com

CFO Audience:
  OLS Approvers:
    - cfo@dentsu.com

Finance App (if AppBased):
  OLS Approvers:
    - finance.vp@dentsu.com
```

**Example Data:**
```sql
DECLARE @RevenueReportId BIGINT = (SELECT ReportId FROM core.Reports WHERE ReportCode = 'REV_Q4_2024');

INSERT sec.OLSApprovers (CatalogItemTypeCode, CatalogItemId, ApproverUPN) VALUES
  ('Report', @RevenueReportId, 'finance.director@dentsu.com'),
  ('Report', @RevenueReportId, 'cfo@dentsu.com');
```

---

### 7. RLS Approvers

```sql
-- Who approves Row-Level Security (access to specific data slices)?
CREATE TABLE sec.RLSApproverScopes(
  RLSApproverScopeId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityModelId    BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode   VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  ApproverUPN        NVARCHAR(256) NOT NULL,
  ScopeJSON          NVARCHAR(MAX) NOT NULL,  -- What they can approve
  IsActive           BIT NOT NULL DEFAULT 1,
  CreatedAt          DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
```

**Real-World Example:**

```
RLS Approver: france.director@dentsu.com
  Can approve ORGA type requests for:
    - Entity: France (Market level)
    - Service Line: Any

RLS Approver: europe.vp@dentsu.com
  Can approve ORGA type requests for:
    - Entity: Europe (Cluster level) ← Can approve France, Germany, UK
    - Service Line: Any

RLS Approver: nike.account.lead@dentsu.com
  Can approve Client type requests for:
    - Client: Nike only
```

**ScopeJSON Example:**
```json
[
  {
    "SecurityDimensionId": 1,
    "SecurityDimensionCode": "ENT",
    "NaturalKey": "MKT_FR",
    "LevelName": "Market",
    "DisplayName": "France"
  },
  {
    "SecurityDimensionId": 2,
    "SecurityDimensionCode": "SL",
    "NaturalKey": "*",
    "LevelName": "All",
    "DisplayName": "All Service Lines"
  }
]
```

**Example Data:**
```sql
DECLARE @EMEAModelId BIGINT = (SELECT SecurityModelId FROM sec.SecurityModels WHERE SecurityModelCode = 'EMEA_STD');

INSERT sec.RLSApproverScopes (SecurityModelId, SecurityTypeCode, ApproverUPN, ScopeJSON) VALUES
  (@EMEAModelId, 'ORGA', 'france.director@dentsu.com', 
   '[{"SecurityDimensionCode":"ENT","NaturalKey":"MKT_FR","LevelName":"Market"},
     {"SecurityDimensionCode":"SL","NaturalKey":"*","LevelName":"All"}]'),
  
  (@EMEAModelId, 'Client', 'nike.account.lead@dentsu.com',
   '[{"SecurityDimensionCode":"CL","NaturalKey":"CLIENT_001","LevelName":"Client"}]');
```

---

### 8. Object Security Binding

```sql
-- Which Security Model applies to which Report/Audience?
CREATE TABLE sec.ObjectSecurityBinding(
  BindingId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId    BIGINT NOT NULL,  -- ReportId or AudienceId
  SecurityModelId  BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  IsActive         BIT NOT NULL DEFAULT 1,
  UNIQUE(CatalogItemTypeCode, CatalogItemId)
);
```

**Real-World Example:**

```
Revenue Report uses → EMEA Standard Security Model
Budget Report uses → EMEA Standard Security Model
CFO Audience uses → EMEA Standard Security Model
WFI Staffing Report uses → WFI Fixed Security Model
```

**Example Data:**
```sql
DECLARE @EMEAModelId BIGINT = (SELECT SecurityModelId FROM sec.SecurityModels WHERE SecurityModelCode = 'EMEA_STD');
DECLARE @RevenueReportId BIGINT = (SELECT ReportId FROM core.Reports WHERE ReportCode = 'REV_Q4_2024');

INSERT sec.ObjectSecurityBinding (CatalogItemTypeCode, CatalogItemId, SecurityModelId) VALUES
  ('Report', @RevenueReportId, @EMEAModelId);
```

---

### Security Models Summary

**What we've built:**

```
┌──────────────────────────────────────────────────────┐
│  SEC SCHEMA COMPLETE                                 │
│                                                      │
│  ✓ Security Models (per workspace)                 │
│  ✓ Security Dimensions (Entity, Client, etc.)      │
│  ✓ Security Type ↔ Dimension mapping               │
│  ✓ Dimension source data (imported)                │
│  ✓ Entity hierarchy (for approver traversal)       │
│  ✓ OLS Approvers (who approves access)            │
│  ✓ RLS Approvers (who approves data filters)      │
│  ✓ Object ↔ Security Model binding                 │
│                                                      │
│  This is the "WHO CAN" - who can approve what      │
│  Next: The "HOW" - the approval flow               │
└──────────────────────────────────────────────────────┘
```

**The Full Picture So Far:**

```
┌─────────────────────────────────────────────────┐
│         USER REQUESTS ACCESS TO                 │
│         "Revenue Report"                        │
└───────────────────┬─────────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    ▼               ▼               ▼
┌───────┐      ┌────────┐     ┌────────┐
│ Core  │      │  Sec   │     │  Sec   │
│ Reports│────▶│Binding │────▶│ Model  │
└───────┘      └────────┘     └────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
              ┌──────────┐  ┌──────────┐  ┌──────────┐
              │   OLS    │  │Security  │  │   RLS    │
              │Approvers │  │  Types   │  │Approvers │
              └──────────┘  └──────────┘  └──────────┘
```

---

## Approval Flow System

This section explains HOW requests flow through the three approval stages.

### 🚦 Real-World Analogy: The Airport Security Checkpoints

Think of accessing a report like boarding an international flight:

```
┌────────────────────────────────────────────────┐
│  YOU: "I want to board flight Revenue-Report" │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────┐
    │  CHECKPOINT 1: Your Boss   │  ← LM (Line Manager)
    │  "Do you have a reason     │
    │   to travel?"              │
    └────────────┬───────────────┘
                 │ [APPROVED]
                 ▼
    ┌────────────────────────────┐
    │  CHECKPOINT 2: Airline     │  ← OLS (Object Level Security)
    │  "Do you have a valid      │
    │   ticket for THIS flight?" │
    └────────────┬───────────────┘
                 │ [APPROVED]
                 ▼
    ┌────────────────────────────┐
    │  CHECKPOINT 3: Customs     │  ← RLS (Row Level Security)
    │  "Which countries can      │
    │   you visit? (visa check)" │
    └────────────┬───────────────┘
                 │ [APPROVED]
                 ▼
         ✈️ ACCESS GRANTED!
```

**Key Rules:**
1. **Sequential**: Must pass LM before OLS, must pass OLS before RLS
2. **Any Rejection = STOP**: If any checkpoint says NO, you're done
3. **Optional RLS**: Some reports don't need Checkpoint 3 (OLS-only access)

---

## Request Management

### 1. Request Header

```sql
-- The master request record
CREATE TABLE req.Requests(
  RequestId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestedByUPN   NVARCHAR(256) NOT NULL,  -- Who submitted the request
  RequestedForUPN  NVARCHAR(256) NOT NULL,  -- Who will get access (can be same or different)
  WorkspaceId      BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CurrentDecision  VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  ClosedAt         DATETIME2(3) NULL
);
```

**Real-World Example:**

```
Request #12345:
  RequestedBy: john.doe@dentsu.com (me)
  RequestedFor: jane.smith@dentsu.com (my colleague - "on behalf of")
  Workspace: EMEA
  Status: Pending
  Created: 2024-10-11 09:30:00
```

**"On Behalf Of" Scenario:**
```
John (manager) requests access for Jane (employee):
  - John submits the request (RequestedBy)
  - Jane will get the access (RequestedFor)
  - Jane's Line Manager approves (not John's manager!)
```

---

### 2. OLS Request (Object-Level Security)

```sql
-- The "which Report/App/Audience" portion
CREATE TABLE req.OLSRequest(
  OLSRequestId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId    BIGINT NOT NULL,  -- ReportId, AppId, or AudienceId
  ApproverList     NVARCHAR(MAX) NULL,  -- Snapshot of approvers (for audit)
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecidedByUPN     NVARCHAR(256) NULL,
  DecidedAt        DATETIME2(3) NULL
);
```

**Real-World Example:**

```
OLS Request #501 (part of Request #12345):
  Request: #12345
  Type: Report
  Item: Revenue Report (ReportId = 789)
  Approvers: finance.director@dentsu.com, cfo@dentsu.com
  Decision: Pending
```

**Why ApproverList?**
```
When request is created, we snapshot who the approvers are:
  "finance.director@dentsu.com, cfo@dentsu.com"

If approvers change later (someone leaves company), 
we still know who was supposed to approve THIS request!
```

---

### 3. RLS Request (Row-Level Security)

```sql
-- The "what data can I see" portion
CREATE TABLE req.RLSRequest(
  RLSRequestId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  SecurityModelId  BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecidedByUPN     NVARCHAR(256) NULL,
  DecidedAt        DATETIME2(3) NULL
);

-- The detail lines for RLS (which dimensions and values)
CREATE TABLE req.RLSRequestLine(
  RLSRequestLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  RLSRequestId     BIGINT NOT NULL REFERENCES req.RLSRequest(RLSRequestId) ON DELETE CASCADE,
  SecurityDimensionId BIGINT NOT NULL REFERENCES sec.SecurityDimensions(SecurityDimensionId),
  NaturalKey       NVARCHAR(200) NOT NULL,  -- The selected value (e.g., "MKT_FR")
  LevelName        NVARCHAR(50) NULL,       -- Market, Cluster, etc.
  SortOrder        SMALLINT NOT NULL DEFAULT 1
);
```

**Real-World Example:**

```
RLS Request #601 (part of Request #12345):
  Request: #12345
  SecurityModel: EMEA_STD
  SecurityType: ORGA
  Decision: Pending

  Lines:
    Line 1: Entity = MKT_FR (France, Market level)
    Line 2: Service Line = SL_CREATIVE (Creative)
```

**Visual Representation:**

```
Request #12345
  │
  ├── OLS Request #501
  │   └── "Access to Revenue Report"
  │
  └── RLS Request #601
      └── "See only France + Creative data"
          ├── Line 1: Entity = France
          └── Line 2: Service Line = Creative
```

**Multiple RLS Requests:**
```
A single Request can have multiple RLS portions:

Request #12346
  │
  ├── OLS Request #502
  │   └── "Access to Multi-Region Report"
  │
  ├── RLS Request #602
  │   └── "ORGA type: France + Creative"
  │
  └── RLS Request #603
      └── "Client type: Nike"

This means: "Give me access to the report, 
             AND let me see France+Creative data,
             AND let me see Nike client data"
```

---

### 4. Approval Chain

```sql
-- Individual approval records for each stage
CREATE TABLE req.Approvals(
  ApprovalId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  OLSRequestId     BIGINT NULL REFERENCES req.OLSRequest(OLSRequestId) ON DELETE CASCADE,
  RLSRequestId     BIGINT NULL REFERENCES req.RLSRequest(RLSRequestId) ON DELETE CASCADE,
  ApprovalStageCode VARCHAR(10) NOT NULL REFERENCES req.ApprovalStageLoV(ApprovalStageCode),
  ApproverUPN      NVARCHAR(256) NOT NULL,
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecisionReason   NVARCHAR(1000) NULL,  -- Required if Rejected or Revoked
  DecidedAt        DATETIME2(3) NULL,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_req_Approvals_Pending 
  ON req.Approvals(ApproverUPN, Decision) 
  WHERE Decision='Pending';
```

**Real-World Example - Complete Flow:**

```
Request #12345: Jane wants access to "Revenue Report" with "France + Creative" filter

Approval Chain:

┌─────────────────────────────────────────────────────────┐
│ Approval #1001                                          │
│ Stage: LM (Line Manager)                                │
│ Approver: jane.manager@dentsu.com                       │
│ Decision: Approved ✅                                   │
│ Decided: 2024-10-11 10:00:00                           │
│ Note: (LM approves overall request)                     │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ Approval #1002                                          │
│ Stage: OLS (Object Level Security)                      │
│ For: OLS Request #501 (Revenue Report)                  │
│ Approver: finance.director@dentsu.com                   │
│ Decision: Approved ✅                                   │
│ Decided: 2024-10-11 11:30:00                           │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ Approval #1003                                          │
│ Stage: RLS (Row Level Security)                         │
│ For: RLS Request #601 (France + Creative)               │
│ Approver: france.director@dentsu.com                    │
│ Decision: Approved ✅                                   │
│ Decided: 2024-10-11 14:00:00                           │
└─────────────────────────────────────────────────────────┘

FINAL RESULT: Jane gets access to Revenue Report 
              (but only sees France + Creative data)
```

**Example Data:**
```sql
-- LM Approval
INSERT req.Approvals (RequestId, ApprovalStageCode, ApproverUPN, Decision, DecidedAt) VALUES
  (12345, 'LM', 'jane.manager@dentsu.com', 'Approved', '2024-10-11 10:00:00');

-- OLS Approval
INSERT req.Approvals (RequestId, OLSRequestId, ApprovalStageCode, ApproverUPN, Decision, DecidedAt) VALUES
  (12345, 501, 'OLS', 'finance.director@dentsu.com', 'Approved', '2024-10-11 11:30:00');

-- RLS Approval
INSERT req.Approvals (RequestId, RLSRequestId, ApprovalStageCode, ApproverUPN, Decision, DecidedAt) VALUES
  (12345, 601, 'RLS', 'france.director@dentsu.com', 'Approved', '2024-10-11 14:00:00');
```

---

### 5. Rejection Scenario

**What happens when someone says NO?**

```
Request #12346: John wants "Budget Report" access

┌─────────────────────────────────────────────────────────┐
│ Approval #2001                                          │
│ Stage: LM                                               │
│ Approver: john.manager@dentsu.com                       │
│ Decision: Approved ✅                                   │
└─────────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│ Approval #2002                                          │
│ Stage: OLS                                              │
│ Approver: cfo@dentsu.com                                │
│ Decision: Rejected ❌                                   │
│ Reason: "Budget data is confidential. Requester does   │
│         not have business need for this report."        │
│ Decided: 2024-10-11 12:00:00                           │
└─────────────────────────────────────────────────────────┘

FINAL RESULT: Request stopped at OLS stage
              No RLS approval needed (already rejected)
              John does NOT get access
```

**Example Data:**
```sql
INSERT req.Approvals (RequestId, OLSRequestId, ApprovalStageCode, ApproverUPN, Decision, DecisionReason, DecidedAt) VALUES
  (12346, 502, 'OLS', 'cfo@dentsu.com', 'Rejected', 
   'Budget data is confidential. Requester does not have business need for this report.', 
   '2024-10-11 12:00:00');
```

---

### 6. Revocation

```sql
-- Track when access is revoked after approval
CREATE TABLE req.Revocations(
  RevocationId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId     BIGINT NOT NULL REFERENCES req.Requests(RequestId),
  Scope         VARCHAR(10) NOT NULL CHECK (Scope IN ('OLS','RLS')),
  ScopeId       BIGINT NOT NULL,  -- OLSRequestId or RLSRequestId
  Reason        NVARCHAR(1000) NOT NULL,
  RevokedByUPN  NVARCHAR(256) NOT NULL,
  RevokedAt     DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
```

**Real-World Example:**

```
Jane had access to "Revenue Report" (Request #12345 from 6 months ago)

Today: Jane changed roles, no longer needs finance access

┌─────────────────────────────────────────────────────────┐
│ Revocation #3001                                        │
│ Request: #12345                                         │
│ Scope: OLS (remove report access)                       │
│ ScopeId: 501 (OLS Request)                              │
│ Reason: "Employee changed to HR department. No longer   │
│         requires finance data access."                  │
│ RevokedBy: finance.director@dentsu.com                  │
│ RevokedAt: 2024-10-11 15:00:00                         │
└─────────────────────────────────────────────────────────┘

RESULT: Jane loses access to Revenue Report
        (Previous approvals stay in history for audit)
```

**Example Data:**
```sql
INSERT req.Revocations (RequestId, Scope, ScopeId, Reason, RevokedByUPN) VALUES
  (12345, 'OLS', 501, 
   'Employee changed to HR department. No longer requires finance data access.', 
   'finance.director@dentsu.com');

-- Also update the decision
UPDATE req.OLSRequest SET Decision = 'Revoked' WHERE OLSRequestId = 501;
UPDATE req.Approvals SET Decision = 'Revoked' WHERE OLSRequestId = 501;
```

---

### 7. Delegations

```sql
-- Temporary delegation of approval authority
CREATE TABLE sec.Delegations(
  DelegationId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  ApproverUPN      NVARCHAR(256) NOT NULL,  -- Original approver
  DelegateUPN      NVARCHAR(256) NOT NULL,  -- Temporary replacement
  StartsAt         DATETIME2(3) NOT NULL,
  EndsAt           DATETIME2(3) NOT NULL,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UNIQUE(ApproverUPN, DelegateUPN, StartsAt)
);
```

**Real-World Example:**

```
Sarah (finance.director@dentsu.com) is going on vacation:

┌─────────────────────────────────────────────────────────┐
│ Delegation #4001                                        │
│ Approver: finance.director@dentsu.com (Sarah)           │
│ Delegate: finance.backup@dentsu.com (Michael)           │
│ StartsAt: 2024-10-20 00:00:00                          │
│ EndsAt: 2024-10-27 23:59:59                            │
└─────────────────────────────────────────────────────────┘

During Oct 20-27:
  - New requests that need Sarah's approval
  - Go to Michael instead (or BOTH Sarah & Michael get emails)
  - Michael can approve on Sarah's behalf

After Oct 27:
  - Delegation expires
  - Requests go back to Sarah only
```

**Important Rules:**
```
✓ Delegations apply to NEW requests only (created after StartAt)
✓ "Any-of" logic: Either Sarah OR Michael can approve
✓ Old requests (before delegation) still go to original approver
✗ "Both-of" logic NOT supported (out of scope)
```

**Example Data:**
```sql
INSERT sec.Delegations (ApproverUPN, DelegateUPN, StartsAt, EndsAt) VALUES
  ('finance.director@dentsu.com', 'finance.backup@dentsu.com', 
   '2024-10-20 00:00:00', '2024-10-27 23:59:59');
```

---

### Complete Flow Visualization

```
┌───────────────────────────────────────────────────────────────────┐
│                    USER SUBMITS REQUEST                           │
│  "I need: Revenue Report, with France + Creative filter"          │
└──────────────────────────────┬────────────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  Create req.Requests │
                    │    RequestId: 12345  │
                    └──────────┬───────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐    ┌────────────────┐    ┌────────────────┐
│req.OLSRequest │    │req.RLSRequest  │    │req.Approvals   │
│#501: Revenue  │    │#601: ORGA      │    │#1001: LM Stage │
│      Report   │    │France+Creative │    │(Pending)       │
└───────────────┘    └────────────────┘    └────────┬───────┘
                                                     │
                                                     ▼
                                        ┌────────────────────┐
                                        │ Email to LM        │
                                        │ jane.manager@...   │
                                        └────────┬───────────┘
                                                 │
                                        [Clicks "Approve"]
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Update Approval    │
                                        │ #1001: Approved ✅ │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Create Approval    │
                                        │ #1002: OLS Stage   │
                                        │ (Pending)          │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Email to OLS       │
                                        │ finance.director@  │
                                        └────────┬───────────┘
                                                 │
                                        [Clicks "Approve"]
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Update Approval    │
                                        │ #1002: Approved ✅ │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Create Approval    │
                                        │ #1003: RLS Stage   │
                                        │ (Pending)          │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Email to RLS       │
                                        │ france.director@   │
                                        └────────┬───────────┘
                                                 │
                                        [Clicks "Approve"]
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Update Approval    │
                                        │ #1003: Approved ✅ │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Update req.Requests│
                                        │ CurrentDecision:   │
                                        │ Approved           │
                                        │ ClosedAt: Now      │
                                        └────────┬───────────┘
                                                 │
                                                 ▼
                                        ┌────────────────────┐
                                        │ Email to Requester │
                                        │ "Access Granted!"  │
                                        └────────────────────┘
```

---

## Supporting Systems

These are the supporting tables that make the system work smoothly.

### 1. Email System

#### Email Settings

```sql
-- Global email configuration
CREATE TABLE admin.EmailSettings(
  EmailSettingsId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SendEnabled     BIT NOT NULL DEFAULT 1,
  SenderAddress   NVARCHAR(256) NOT NULL,
  SubjectPrefix   NVARCHAR(50) NULL,
  RetryCount      TINYINT NOT NULL DEFAULT 3,
  UpdatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
```

**Real-World Example:**
```
Email Configuration:
  SendEnabled: Yes
  SenderAddress: sakura-noreply@dentsu.com
  SubjectPrefix: "[Sakura Access]"
  RetryCount: 3 (try sending up to 3 times if fails)
```

#### Email Templates

```sql
-- Customizable email templates
CREATE TABLE admin.EmailTemplates(
  TemplateCode    VARCHAR(40) PRIMARY KEY,
  SubjectTemplate NVARCHAR(200) NOT NULL,
  BodyTemplate    NVARCHAR(MAX) NOT NULL
);
```

**Template Types:**
```
1. RequestSubmitted
   Subject: "[Sakura Access] New access request #{RequestId}"
   Body: "A new access request has been submitted by {RequesterName}..."

2. StageApproved
   Subject: "[Sakura Access] Request #{RequestId} - {Stage} Approved"
   Body: "{ApproverName} has approved your request at {Stage} stage..."

3. StageRejected
   Subject: "[Sakura Access] Request #{RequestId} - Rejected"
   Body: "{ApproverName} has rejected your request. Reason: {Reason}..."

4. Revoked
   Subject: "[Sakura Access] Access Revoked for Request #{RequestId}"
   Body: "Your access has been revoked. Reason: {Reason}..."

5. AssignedAsApprover
   Subject: "[Sakura Access] Action Required: Approve Request #{RequestId}"
   Body: "You have been assigned to approve a request. Click here to review..."
```

**Example Data:**
```sql
INSERT admin.EmailTemplates (TemplateCode, SubjectTemplate, BodyTemplate) VALUES
  ('RequestSubmitted', 
   '[Sakura Access] New Request #{RequestId}',
   'Hello {RequesterName},

Your access request has been submitted successfully.

Request ID: {RequestId}
Requested For: {RequestedForName}
Report/App: {CatalogItemName}

Current Status: Awaiting Line Manager approval

You will receive email updates as your request progresses.

Thank you,
Sakura Access Management System'),

  ('AssignedAsApprover',
   '[Sakura Access] ACTION REQUIRED: Approve Request #{RequestId}',
   'Hello {ApproverName},

You have been assigned to review an access request.

Request ID: {RequestId}
Requester: {RequesterName}
Requested For: {RequestedForName}
Report/App: {CatalogItemName}
Stage: {StageName}

[Approve Button] [Reject Button] [View Details]

This request requires your attention.

Thank you,
Sakura Access Management System');
```

#### Email Queue

```sql
-- Queue for outgoing emails
CREATE TABLE admin.EmailQueue(
  EmailId         BIGINT IDENTITY(1,1) PRIMARY KEY,
  TemplateCode    VARCHAR(40) NOT NULL REFERENCES admin.EmailTemplates(TemplateCode),
  ToUPN           NVARCHAR(256) NOT NULL,
  CcUPN           NVARCHAR(MAX) NULL,  -- JSON array of emails
  PayloadJSON     NVARCHAR(MAX) NOT NULL,  -- Merge fields (variables)
  Status          VARCHAR(12) NOT NULL DEFAULT 'Pending',
  Attempts        TINYINT NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  SentAt          DATETIME2(3) NULL,
  ErrorText       NVARCHAR(2000) NULL
);
```

**Real-World Example:**
```
Email #5001:
  Template: AssignedAsApprover
  To: finance.director@dentsu.com
  CC: finance.vp@dentsu.com
  Payload: {
    "RequestId": "12345",
    "RequesterName": "Jane Smith",
    "RequestedForName": "Jane Smith",
    "CatalogItemName": "Revenue Report",
    "StageName": "OLS (Object Level Security)",
    "ApproverName": "Sarah Johnson"
  }
  Status: Pending
  Attempts: 0
  Created: 2024-10-11 11:30:00
```

**Email Flow:**
```
1. Request submitted → Add "RequestSubmitted" email to queue (to requester)
2. LM stage starts → Add "AssignedAsApprover" email to queue (to LM)
3. LM approves → Add "StageApproved" email to queue (to requester)
4. OLS stage starts → Add "AssignedAsApprover" email to queue (to OLS approver)
... and so on

Background job processes the queue every 30 seconds:
  - Get all Pending emails
  - Try to send via SMTP
  - If success: Status = Sent, SentAt = Now
  - If fail: Status = Pending, Attempts++, ErrorText = error message
  - If Attempts > 3: Status = Failed (stop trying)
```

---

### 2. Audit & Logging

```sql
-- Complete audit trail of all actions
CREATE TABLE log.Audit(
  AuditId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  ObjectType   VARCHAR(40) NOT NULL,
  ObjectId     BIGINT NULL,
  Action       VARCHAR(40) NOT NULL,
  WhoUPN       NVARCHAR(256) NOT NULL,
  WhenAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  BeforeJSON   NVARCHAR(MAX) NULL,  -- State before change
  AfterJSON    NVARCHAR(MAX) NULL   -- State after change
);

CREATE INDEX IX_log_Audit_Object 
  ON log.Audit(ObjectType, ObjectId, WhenAt DESC);
```

**What Gets Audited:**
```
✓ Request created/updated
✓ Approval given/rejected
✓ Access revoked
✓ Delegation created
✓ Approver added/removed
✓ Report/App created/updated
✓ Settings changed
✓ Email sent
```

**Real-World Examples:**

**Example 1: Request Created**
```
AuditId: 10001
ObjectType: Request
ObjectId: 12345
Action: Create
WhoUPN: jane.smith@dentsu.com
WhenAt: 2024-10-11 09:30:00
BeforeJSON: null
AfterJSON: {
  "RequestId": 12345,
  "RequestedBy": "jane.smith@dentsu.com",
  "RequestedFor": "jane.smith@dentsu.com",
  "WorkspaceId": 1,
  "OLS": {
    "Type": "Report",
    "ItemId": 789,
    "ItemName": "Revenue Report"
  },
  "RLS": {
    "SecurityType": "ORGA",
    "Dimensions": [
      {"Dimension": "Entity", "Value": "France"},
      {"Dimension": "ServiceLine", "Value": "Creative"}
    ]
  }
}
```

**Example 2: Approval Given**
```
AuditId: 10002
ObjectType: Approval
ObjectId: 1001
Action: Approve
WhoUPN: jane.manager@dentsu.com
WhenAt: 2024-10-11 10:00:00
BeforeJSON: {
  "Decision": "Pending",
  "DecidedBy": null,
  "DecidedAt": null
}
AfterJSON: {
  "Decision": "Approved",
  "DecidedBy": "jane.manager@dentsu.com",
  "DecidedAt": "2024-10-11 10:00:00"
}
```

**Example 3: Access Revoked**
```
AuditId: 10003
ObjectType: Request
ObjectId: 12345
Action: Revoke
WhoUPN: finance.director@dentsu.com
WhenAt: 2024-10-11 15:00:00
BeforeJSON: {
  "CurrentDecision": "Approved"
}
AfterJSON: {
  "CurrentDecision": "Revoked",
  "RevocationReason": "Employee changed to HR department."
}
```

---

### 3. System Settings

```sql
-- Global system configuration
CREATE TABLE admin.SystemSettings(
  SettingKey   VARCHAR(100) PRIMARY KEY,
  SettingValue NVARCHAR(1000) NOT NULL,
  UpdatedAt    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
```

**Example Settings:**
```
Setting: MaxPendingRequestsPerUser
Value: 10
Purpose: A user can have max 10 pending requests at once

Setting: AutoRejectAfterDays
Value: 30
Purpose: Auto-reject requests pending for more than 30 days

Setting: RequireLMApprovalForSelfRequest
Value: true
Purpose: Even when requesting for yourself, LM approval is required

Setting: AllowOnBehalfRequests
Value: true
Purpose: Managers can request on behalf of their team members

Setting: DelegationMaxDurationDays
Value: 90
Purpose: Delegations cannot exceed 90 days
```

**Example Data:**
```sql
INSERT admin.SystemSettings (SettingKey, SettingValue) VALUES
  ('MaxPendingRequestsPerUser', '10'),
  ('AutoRejectAfterDays', '30'),
  ('RequireLMApprovalForSelfRequest', 'true'),
  ('AllowOnBehalfRequests', 'true'),
  ('DelegationMaxDurationDays', '90');
```

---

### 4. Help Bubbles (In-App Help)

```sql
-- Contextual help text for UI elements
CREATE TABLE admin.HelpBubbles(
  HelpId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  PageKey      VARCHAR(100) NOT NULL,
  ElementKey   VARCHAR(100) NOT NULL,
  HelpText     NVARCHAR(1000) NOT NULL,
  IsActive     BIT NOT NULL DEFAULT 1,
  UNIQUE(PageKey, ElementKey)
);
```

**Real-World Example:**
```
Page: RequestForm
Element: OLS_Selection
Help: "Select the Report, App, or Audience you need access to. 
       This determines which approvers will review your request."

Page: RequestForm
Element: RLS_SecurityType
Help: "Choose how you want to filter data. For example, 'Organization' 
       lets you select specific countries or business units."

Page: ApprovalDashboard
Element: DelegationButton
Help: "Going on vacation? Delegate your approval authority to a 
       colleague for a specified time period."
```

**Example Data:**
```sql
INSERT admin.HelpBubbles (PageKey, ElementKey, HelpText) VALUES
  ('RequestForm', 'OLS_Selection', 
   'Select the Report, App, or Audience you need access to. This determines which approvers will review your request.'),
  
  ('RequestForm', 'RLS_SecurityType',
   'Choose how you want to filter data. For example, Organization lets you select specific countries or business units.'),
  
  ('ApprovalDashboard', 'DelegationButton',
   'Going on vacation? Delegate your approval authority to a colleague for a specified time period.');
```

---

### 5. Data Sharing Views (Read-Only)

These views expose approved access data for consumption by external systems (Power BI, etc.).

#### RLS Grants View

```sql
-- Show all approved RLS access grants
CREATE VIEW shr.RLS_UserGrants AS
SELECT
  rr.RLSRequestId,
  r.RequestedForUPN              AS RequestedFor,
  r.CreatedAt                    AS RequestDate,
  rr.SecurityModelId,
  sm.SecurityModelName,
  rr.SecurityTypeCode            AS SecurityType,
  a.DecidedAt                    AS ApprovalDate,
  a.ApproverUPN                  AS ApprovedBy,
  -- Flatten dimension selections:
  JSON_QUERY((
    SELECT 
      sd.SecurityDimensionName AS Dimension,
      rl.NaturalKey,
      rl.LevelName,
      ds.DisplayName
    FROM req.RLSRequestLine rl
    JOIN sec.SecurityDimensions sd ON sd.SecurityDimensionId = rl.SecurityDimensionId
    LEFT JOIN imp.DimensionSource ds 
      ON ds.SecurityDimensionId = rl.SecurityDimensionId 
      AND ds.NaturalKey = rl.NaturalKey
      AND ds.ValidTo IS NULL  -- Current version
    WHERE rl.RLSRequestId = rr.RLSRequestId
    ORDER BY rl.SortOrder
    FOR JSON PATH
  ))                             AS DimensionSelectionsJSON
FROM req.RLSRequest rr
JOIN req.Requests r       ON r.RequestId = rr.RequestId
JOIN sec.SecurityModels sm ON sm.SecurityModelId = rr.SecurityModelId
JOIN req.Approvals a      ON a.RLSRequestId = rr.RLSRequestId 
                           AND a.Decision = 'Approved'
                           AND a.ApprovalStageCode = 'RLS'
WHERE rr.Decision = 'Approved';
```

**Example Output:**
```
RLSRequestId: 601
RequestedFor: jane.smith@dentsu.com
RequestDate: 2024-10-11 09:30:00
SecurityModelName: EMEA Standard Security Model
SecurityType: ORGA
ApprovalDate: 2024-10-11 14:00:00
ApprovedBy: france.director@dentsu.com
DimensionSelectionsJSON: [
  {
    "Dimension": "Entity",
    "NaturalKey": "MKT_FR",
    "LevelName": "Market",
    "DisplayName": "France"
  },
  {
    "Dimension": "Service Line",
    "NaturalKey": "SL_CREATIVE",
    "LevelName": "ServiceLine",
    "DisplayName": "Creative"
  }
]
```

#### OLS Access View

```sql
-- Show all approved OLS access grants
CREATE VIEW shr.OLS_UserAccess AS
SELECT
  o.OLSRequestId,
  r.RequestedForUPN         AS RequestedFor,
  r.CreatedAt               AS RequestDate,
  o.CatalogItemTypeCode     AS CatalogueItemType,
  o.CatalogItemId           AS CatalogueItemId,
  CASE o.CatalogItemTypeCode
    WHEN 'Report' THEN rep.ReportName
    WHEN 'App' THEN app.AppName
    WHEN 'Audience' THEN aud.AudienceName
  END                       AS CatalogueItemName,
  ap.DecidedAt              AS ApprovalDate,
  ap.ApproverUPN            AS ApprovedBy
FROM req.OLSRequest o
JOIN req.Requests r ON r.RequestId = o.RequestId
JOIN req.Approvals ap ON ap.OLSRequestId = o.OLSRequestId 
                      AND ap.Decision = 'Approved'
                      AND ap.ApprovalStageCode = 'OLS'
LEFT JOIN core.Reports rep ON o.CatalogItemTypeCode = 'Report' AND rep.ReportId = o.CatalogItemId
LEFT JOIN core.WorkspaceApps app ON o.CatalogItemTypeCode = 'App' AND app.AppId = o.CatalogItemId
LEFT JOIN core.AppAudiences aud ON o.CatalogItemTypeCode = 'Audience' AND aud.AudienceId = o.CatalogItemId
WHERE o.Decision = 'Approved';
```

**Example Output:**
```
OLSRequestId: 501
RequestedFor: jane.smith@dentsu.com
RequestDate: 2024-10-11 09:30:00
CatalogueItemType: Report
CatalogueItemId: 789
CatalogueItemName: Revenue Report
ApprovalDate: 2024-10-11 11:30:00
ApprovedBy: finance.director@dentsu.com
```

---

### 6. Database Roles & Security

```sql
-- Database roles for different user types
-- (These are SQL Server roles, not tables)

-- 1. Admin role (full access)
CREATE ROLE sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::sec TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::req TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::admin TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::log TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::imp TO sakura_admin;
GRANT SELECT ON SCHEMA::shr TO sakura_admin;

-- 2. Support role (read-only, for troubleshooting)
CREATE ROLE sakura_support;
GRANT SELECT ON SCHEMA::core TO sakura_support;
GRANT SELECT ON SCHEMA::sec TO sakura_support;
GRANT SELECT ON SCHEMA::req TO sakura_support;
GRANT SELECT ON SCHEMA::admin TO sakura_support;
GRANT SELECT ON SCHEMA::log TO sakura_support;
GRANT SELECT ON SCHEMA::imp TO sakura_support;
GRANT SELECT ON SCHEMA::shr TO sakura_support;

-- 3. Import role (for ETL jobs)
CREATE ROLE sakura_import;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::imp TO sakura_import;
GRANT SELECT ON SCHEMA::sec TO sakura_import;

-- 4. Sharing/Export role (for external systems consuming data)
CREATE ROLE sakura_sharing;
GRANT SELECT ON SCHEMA::shr TO sakura_sharing;

-- 5. Application role (for the web app)
CREATE ROLE sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::core TO sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::sec TO sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::req TO sakura_app;
GRANT SELECT ON SCHEMA::admin TO sakura_app;
GRANT INSERT ON SCHEMA::log TO sakura_app;
GRANT SELECT ON SCHEMA::imp TO sakura_app;
GRANT SELECT ON SCHEMA::shr TO sakura_app;
```

---

### Supporting Systems Summary

```
┌──────────────────────────────────────────────────────┐
│  SUPPORTING SYSTEMS COMPLETE                         │
│                                                      │
│  ✓ Email system (templates, queue, retry)          │
│  ✓ Audit logging (full history)                    │
│  ✓ System settings (configurable behavior)         │
│  ✓ Help bubbles (in-app guidance)                  │
│  ✓ Data sharing views (for external systems)       │
│  ✓ Database roles (security)                       │
│                                                      │
│  These enable the system to operate smoothly       │
└──────────────────────────────────────────────────────┘
```

---

## End-to-End Flow Examples

Let's walk through complete scenarios from start to finish.

### 🎬 Scenario 1: Simple SAR Request (Report with RLS)

**Actors:**
- **Jane Smith** (Analyst) - wants access
- **Michael Brown** (Jane's manager) - LM approver
- **Sarah Johnson** (Finance Director) - OLS approver
- **Pierre Dubois** (France Director) - RLS approver

**What Jane wants:**
- Access to "Revenue Report" (SAR)
- Filter: Only France + Creative data

#### Step-by-Step Flow:

```
DAY 1 - 09:30 AM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jane logs into Sakura portal and submits request:

1. SELECT Report: "Revenue Report"
2. SELECT RLS Type: ORGA (Organization)
3. SELECT Entity: France (Market level)
4. SELECT Service Line: Creative
5. Click "Submit"

DATABASE ACTIONS:
├─ INSERT INTO req.Requests
│  (RequestId=12345, RequestedBy=jane.smith@dentsu.com, 
│   RequestedFor=jane.smith@dentsu.com, WorkspaceId=1)
│
├─ INSERT INTO req.OLSRequest
│  (OLSRequestId=501, RequestId=12345, CatalogItemTypeCode='Report',
│   CatalogItemId=789, ApproverList='sarah.johnson@dentsu.com')
│
├─ INSERT INTO req.RLSRequest
│  (RLSRequestId=601, RequestId=12345, SecurityModelId=1,
│   SecurityTypeCode='ORGA')
│
├─ INSERT INTO req.RLSRequestLine
│  (RLSRequestId=601, SecurityDimensionId=1, NaturalKey='MKT_FR')
│  (RLSRequestId=601, SecurityDimensionId=2, NaturalKey='SL_CREATIVE')
│
├─ INSERT INTO req.Approvals
│  (ApprovalId=1001, RequestId=12345, ApprovalStageCode='LM',
│   ApproverUPN='michael.brown@dentsu.com', Decision='Pending')
│
├─ INSERT INTO admin.EmailQueue  [To Jane: RequestSubmitted]
└─ INSERT INTO admin.EmailQueue  [To Michael: AssignedAsApprover]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Request', ObjectId=12345, Action='Create',
    WhoUPN='jane.smith@dentsu.com')
```

```
DAY 1 - 10:00 AM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Michael (LM) receives email, clicks "Approve"

DATABASE ACTIONS:
├─ UPDATE req.Approvals SET Decision='Approved', 
│  DecidedByUPN='michael.brown@dentsu.com', DecidedAt=NOW()
│  WHERE ApprovalId=1001
│
├─ INSERT INTO req.Approvals
│  (ApprovalId=1002, RequestId=12345, OLSRequestId=501,
│   ApprovalStageCode='OLS', ApproverUPN='sarah.johnson@dentsu.com',
│   Decision='Pending')
│
├─ INSERT INTO admin.EmailQueue  [To Jane: StageApproved - LM]
└─ INSERT INTO admin.EmailQueue  [To Sarah: AssignedAsApprover]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Approval', ObjectId=1001, Action='Approve',
    WhoUPN='michael.brown@dentsu.com')
```

```
DAY 1 - 11:30 AM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sarah (OLS) receives email, clicks "Approve"

DATABASE ACTIONS:
├─ UPDATE req.Approvals SET Decision='Approved',
│  DecidedByUPN='sarah.johnson@dentsu.com', DecidedAt=NOW()
│  WHERE ApprovalId=1002
│
├─ UPDATE req.OLSRequest SET Decision='Approved'
│  WHERE OLSRequestId=501
│
├─ INSERT INTO req.Approvals
│  (ApprovalId=1003, RequestId=12345, RLSRequestId=601,
│   ApprovalStageCode='RLS', ApproverUPN='pierre.dubois@dentsu.com',
│   Decision='Pending')
│
├─ INSERT INTO admin.EmailQueue  [To Jane: StageApproved - OLS]
└─ INSERT INTO admin.EmailQueue  [To Pierre: AssignedAsApprover]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Approval', ObjectId=1002, Action='Approve',
    WhoUPN='sarah.johnson@dentsu.com')
```

```
DAY 1 - 02:00 PM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pierre (RLS) receives email, clicks "Approve"

DATABASE ACTIONS:
├─ UPDATE req.Approvals SET Decision='Approved',
│  DecidedByUPN='pierre.dubois@dentsu.com', DecidedAt=NOW()
│  WHERE ApprovalId=1003
│
├─ UPDATE req.RLSRequest SET Decision='Approved'
│  WHERE RLSRequestId=601
│
├─ UPDATE req.Requests SET CurrentDecision='Approved', ClosedAt=NOW()
│  WHERE RequestId=12345
│
└─ INSERT INTO admin.EmailQueue  [To Jane: Request Fully Approved!]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Approval', ObjectId=1003, Action='Approve',
    WhoUPN='pierre.dubois@dentsu.com')
```

```
FINAL STATE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Request #12345: APPROVED
✅ Jane has access to "Revenue Report"
✅ Jane can only see: France + Creative data
✅ Available in shr.OLS_UserAccess view
✅ Available in shr.RLS_UserGrants view
```

**Query to verify:**
```sql
-- Check Jane's approved access
SELECT * FROM shr.OLS_UserAccess 
WHERE RequestedFor = 'jane.smith@dentsu.com';

SELECT * FROM shr.RLS_UserGrants 
WHERE RequestedFor = 'jane.smith@dentsu.com';
```

---

### 🎬 Scenario 2: Rejection at OLS Stage

**Actors:**
- **John Doe** (New employee) - wants access
- **Emma Wilson** (John's manager) - LM approver
- **CFO** - OLS approver

**What John wants:**
- Access to "Executive Board Report" (highly confidential)

#### Step-by-Step Flow:

```
DAY 1 - 03:00 PM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
John submits request → LM approves (Stage 1 ✅)

DATABASE STATE:
├─ Request #12350 created
├─ Approval #2001 (LM): Approved ✅
└─ Approval #2002 (OLS): Pending ⏳
```

```
DAY 1 - 04:00 PM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CFO receives email, reviews request, clicks "Reject"

WHY REJECTED:
"This report contains board-level confidential information.
 Employee does not have sufficient seniority or business need."

DATABASE ACTIONS:
├─ UPDATE req.Approvals SET Decision='Rejected',
│  DecisionReason='This report contains board-level confidential...',
│  DecidedByUPN='cfo@dentsu.com', DecidedAt=NOW()
│  WHERE ApprovalId=2002
│
├─ UPDATE req.OLSRequest SET Decision='Rejected'
│  WHERE OLSRequestId=510
│
├─ UPDATE req.Requests SET CurrentDecision='Rejected', ClosedAt=NOW()
│  WHERE RequestId=12350
│
└─ INSERT INTO admin.EmailQueue  [To John: StageRejected]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Approval', ObjectId=2002, Action='Reject',
    WhoUPN='cfo@dentsu.com')
```

```
FINAL STATE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Request #12350: REJECTED
❌ John does NOT get access
📧 John receives rejection email with reason
🛑 No RLS stage (stopped at OLS)
📋 Full audit trail preserved
```

---

### 🎬 Scenario 3: Multiple RLS Types in One Request

**Actors:**
- **Alice Johnson** (Senior Analyst) - wants access

**What Alice wants:**
- Access to "Multi-Dimensional Report"
- Filter 1: France + Creative (ORGA type)
- Filter 2: Nike client (Client type)

#### Step-by-Step Flow:

```
REQUEST STRUCTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Request #12360
│
├── OLS Request #520
│   └── "Multi-Dimensional Report"
│
├── RLS Request #630 (ORGA type)
│   ├── Line: Entity = France
│   └── Line: Service Line = Creative
│
└── RLS Request #631 (Client type)
    └── Line: Client = Nike
```

```
APPROVAL FLOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Stage 1: LM Approval
└─ Approval #3001: Approved ✅

Stage 2: OLS Approval  
└─ Approval #3002: Approved ✅

Stage 3a: RLS Approval (ORGA)
└─ Approval #3003: Approved ✅ (by France Director)

Stage 3b: RLS Approval (Client)
└─ Approval #3004: Approved ✅ (by Nike Account Lead)
```

**Key Point:** Both RLS requests must be approved for full access!

```
FINAL STATE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Request #12360: APPROVED
✅ Alice has access to "Multi-Dimensional Report"
✅ Alice can see:
   ✓ France + Creative data (ORGA filter)
   ✓ Nike client data (Client filter)
```

---

### 🎬 Scenario 4: On-Behalf Request

**Actors:**
- **Manager Tom** - submits request
- **Employee Lisa** - will receive access
- **Lisa's Manager** (not Tom!) - LM approver

**What Tom wants:**
- Request access FOR Lisa (his team member)
- Report: "Sales Dashboard"

#### Important Rule:

```
┌──────────────────────────────────────────────────────┐
│  When requesting "on behalf of" someone:             │
│                                                      │
│  LM approval comes from the REQUESTEE's manager,     │
│  NOT the requester's manager!                        │
│                                                      │
│  Lisa's access → Lisa's manager approves (LM)        │
└──────────────────────────────────────────────────────┘
```

#### Step-by-Step:

```
DAY 1 - 10:00 AM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tom submits request

DATABASE:
└─ INSERT INTO req.Requests
   (RequestedBy='tom.manager@dentsu.com',   ← Tom submits
    RequestedFor='lisa.employee@dentsu.com')  ← Lisa gets access

SYSTEM LOGIC:
1. Query imp.LineManager for Lisa's current manager
2. Found: lisa.manager@dentsu.com
3. Create LM approval for Lisa's manager (not Tom!)

└─ INSERT INTO req.Approvals
   (ApproverUPN='lisa.manager@dentsu.com')  ← Lisa's manager!
```

```
APPROVAL FLOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Stage 1: LM (Lisa's Manager)
└─ Email to: lisa.manager@dentsu.com
   Message: "Tom has requested access for Lisa..."
```

---

### 🎬 Scenario 5: Delegation During Vacation

**Actors:**
- **Sarah** (Finance Director) - going on vacation
- **Michael** (Backup) - delegated approver
- **New request arrives** during Sarah's vacation

#### Setup Delegation:

```
BEFORE VACATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sarah creates delegation:

INSERT INTO sec.Delegations
  (ApproverUPN='sarah@dentsu.com',
   DelegateUPN='michael@dentsu.com',
   StartsAt='2024-10-20 00:00:00',
   EndsAt='2024-10-27 23:59:59')
```

#### Request During Vacation:

```
Oct 22 (During vacation):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
New request needs Sarah's OLS approval

SYSTEM LOGIC:
1. Check: Is Sarah on delegation?
   Query: SELECT * FROM sec.Delegations 
          WHERE ApproverUPN='sarah@dentsu.com'
          AND NOW() BETWEEN StartsAt AND EndsAt
   
2. Found active delegation → Michael is delegate

3. Send email to BOTH Sarah AND Michael
   (Or just Michael, depending on config)

DATABASE:
└─ INSERT INTO req.Approvals
   (ApproverUPN='sarah@dentsu.com',
    Note: 'Delegated to michael@dentsu.com')

EMAIL:
├─ To: sarah@dentsu.com  [Optional - on vacation]
└─ To: michael@dentsu.com  [Primary recipient]
```

```
APPROVAL:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Michael approves on behalf of Sarah:

UPDATE req.Approvals
SET Decision='Approved',
    DecidedByUPN='michael@dentsu.com',  ← Michael actually approved
    DecidedAt=NOW()
WHERE ApprovalId=5001;

AUDIT LOG:
└─ Action: 'Approve (Delegated)'
   WhoUPN: 'michael@dentsu.com'
   Extra: 'Approved on behalf of sarah@dentsu.com'
```

---

### 🎬 Scenario 6: Revocation After 6 Months

**What happened:**
- 6 months ago: Jane got access to "Finance Report"
- Today: Jane changed to HR department
- Finance Director revokes her access

#### Revocation Process:

```
TODAY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finance Director logs in, finds Jane's old request #12345

Clicks "Revoke Access"
Enters reason: "Employee transferred to HR. No longer needs finance access."

DATABASE ACTIONS:
├─ INSERT INTO req.Revocations
│  (RequestId=12345, Scope='OLS', ScopeId=501,
│   Reason='Employee transferred to HR...',
│   RevokedByUPN='finance.director@dentsu.com')
│
├─ UPDATE req.OLSRequest SET Decision='Revoked'
│  WHERE OLSRequestId=501
│
├─ UPDATE req.Approvals SET Decision='Revoked'
│  WHERE OLSRequestId=501
│
├─ UPDATE req.Requests SET CurrentDecision='Revoked'
│  WHERE RequestId=12345
│
└─ INSERT INTO admin.EmailQueue  [To Jane: Access Revoked]

AUDIT LOG:
└─ INSERT INTO log.Audit
   (ObjectType='Request', ObjectId=12345, Action='Revoke',
    WhoUPN='finance.director@dentsu.com',
    BeforeJSON: '{"Decision":"Approved"}',
    AfterJSON: '{"Decision":"Revoked","Reason":"..."}')
```

```
IMPORTANT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Original approval history is PRESERVED
✓ All audit records remain intact
✓ shr.OLS_UserAccess view automatically excludes revoked access
✓ Jane no longer appears in access lists
✓ If Jane needs access again, NEW request required
```

---

### Complete System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SAKURA SYSTEM ARCHITECTURE                   │
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                    │
│  │   EXTERNAL   │────────▶│  IMPORT (imp)│                    │
│  │   SYSTEMS    │         │  - LineManager│                    │
│  │ (UMS/Workday)│         │  - Dimensions │                    │
│  └──────────────┘         └──────┬───────┘                    │
│                                   │                             │
│  ┌──────────────┐                 │                             │
│  │     USER     │                 ▼                             │
│  │   SUBMITS    │         ┌───────────────┐                    │
│  │   REQUEST    │────────▶│  CORE SCHEMA  │                    │
│  └──────────────┘         │  - Workspaces │                    │
│                           │  - Reports    │                    │
│                           │  - Apps       │                    │
│                           └───────┬───────┘                    │
│                                   │                             │
│                                   ▼                             │
│                           ┌───────────────┐                    │
│                           │  SEC SCHEMA   │                    │
│                           │  - Models     │                    │
│                           │  - Approvers  │                    │
│                           │  - Dimensions │                    │
│                           └───────┬───────┘                    │
│                                   │                             │
│                                   ▼                             │
│                           ┌───────────────┐                    │
│                           │  REQ SCHEMA   │                    │
│                           │  - Requests   │                    │
│                           │  - Approvals  │                    │
│                           └───────┬───────┘                    │
│                                   │                             │
│         ┌─────────────────────────┼─────────────────────────┐  │
│         │                         │                         │  │
│         ▼                         ▼                         ▼  │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────┐
│  │  ADMIN SCHEMA│         │  LOG SCHEMA  │         │ SHR SCHEMA│
│  │  - Emails    │         │  - Audit     │         │ - Views   │
│  │  - Settings  │         │              │         │ (Export)  │
│  └──────┬───────┘         └──────────────┘         └─────┬────┘
│         │                                                 │  │
│         ▼                                                 ▼  │
│  ┌──────────────┐                                 ┌──────────┐
│  │ EMAIL QUEUE  │                                 │ POWER BI │
│  │   PROCESSOR  │                                 │ EXTERNAL │
│  └──────────────┘                                 └──────────┘
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Guide

This section provides step-by-step instructions for implementing the Sakura database.

### Phase 1: Database Creation

#### Step 1: Create the Database

```sql
-- Create the database (adjust file paths for your environment)
CREATE DATABASE Sakura
ON PRIMARY
(
  NAME = 'Sakura_Data',
  FILENAME = 'C:\SQLData\Sakura_Data.mdf',
  SIZE = 100MB,
  MAXSIZE = UNLIMITED,
  FILEGROWTH = 10MB
)
LOG ON
(
  NAME = 'Sakura_Log',
  FILENAME = 'C:\SQLData\Sakura_Log.ldf',
  SIZE = 50MB,
  MAXSIZE = UNLIMITED,
  FILEGROWTH = 10MB
);
GO

USE Sakura;
GO
```

#### Step 2: Create All Schemas

```sql
-- Create schemas in order
CREATE SCHEMA core;
CREATE SCHEMA sec;
CREATE SCHEMA req;
CREATE SCHEMA admin;
CREATE SCHEMA log;
CREATE SCHEMA imp;
CREATE SCHEMA shr;
GO
```

---

### Phase 2: Foundation Tables

#### Step 3: Create Lookup Value (LoV) Tables

```sql
-- Execute these in order (no dependencies)

-- 1. Catalog Item Types
CREATE TABLE core.CatalogItemTypeLoV(
  CatalogItemTypeCode VARCHAR(20) PRIMARY KEY,
  DisplayName         NVARCHAR(50) NOT NULL
);

-- 2. Approval Stages
CREATE TABLE req.ApprovalStageLoV(
  ApprovalStageCode VARCHAR(10) PRIMARY KEY,
  StageOrder        TINYINT NOT NULL UNIQUE CHECK(StageOrder BETWEEN 1 AND 3)
);

-- 3. Decision Types
CREATE TABLE req.DecisionLoV(
  DecisionCode VARCHAR(12) PRIMARY KEY,
  IsTerminal   BIT NOT NULL DEFAULT 0
);

-- 4. Security Types
CREATE TABLE sec.SecurityTypeLoV(
  SecurityTypeCode VARCHAR(20) PRIMARY KEY,
  DisplayName      NVARCHAR(80) NOT NULL
);

-- 5. Approval Modes
CREATE TABLE sec.ApprovalModeLoV(
  ApprovalModeCode VARCHAR(20) PRIMARY KEY,
  DisplayName      NVARCHAR(50) NOT NULL
);
GO
```

#### Step 4: Seed Lookup Data

```sql
-- Insert seed data for all LoV tables

INSERT core.CatalogItemTypeLoV VALUES 
  ('Report', 'Report'),
  ('App', 'Workspace App'),
  ('Audience', 'App Audience');

INSERT req.ApprovalStageLoV VALUES 
  ('LM', 1),
  ('OLS', 2),
  ('RLS', 3);

INSERT req.DecisionLoV VALUES 
  ('Pending', 0),
  ('Approved', 1),
  ('Rejected', 1),
  ('Revoked', 1);

INSERT sec.SecurityTypeLoV VALUES
  ('ORGA', 'Organization (Entity + Service Line)'),
  ('Client', 'Client'),
  ('CC', 'Cost Center'),
  ('MSS', 'Master Service Set'),
  ('Country', 'Country'),
  ('PC', 'Profit Center'),
  ('SLPA', 'Service Line / Practice Area'),
  ('WFI', 'Workforce Fixed Type');

INSERT sec.ApprovalModeLoV VALUES
  ('AppBased', 'App Based'),
  ('AudienceBased', 'Audience Based');
GO
```

---

### Phase 3: Core Schema Tables

#### Step 5: Create Core Tables

```sql
-- Execute in this order (respecting dependencies)

-- 1. Users
CREATE TABLE core.Users(
  UserId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  UPN           NVARCHAR(256) NOT NULL UNIQUE,
  DisplayName   NVARCHAR(200) NULL,
  EntraObjectId UNIQUEIDENTIFIER NULL,
  IsActive      BIT NOT NULL DEFAULT 1,
  CreatedAt     DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt     DATETIME2(3) NULL
);

-- 2. Workspaces
CREATE TABLE core.Workspaces(
  WorkspaceId    BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceCode  VARCHAR(20) NOT NULL UNIQUE,
  WorkspaceName  NVARCHAR(200) NOT NULL,
  OwnerUPN       NVARCHAR(256) NULL,
  TechOwnerUPN   NVARCHAR(256) NULL,
  IsActive       BIT NOT NULL DEFAULT 1,
  CreatedAt      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt      DATETIME2(3) NULL
);

-- 3. Workspace Apps
CREATE TABLE core.WorkspaceApps(
  AppId             BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId       BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  AppCode           VARCHAR(50) NOT NULL,
  AppName           NVARCHAR(200) NOT NULL,
  ApprovalModeCode  VARCHAR(20) NOT NULL REFERENCES sec.ApprovalModeLoV(ApprovalModeCode),
  IsActive          BIT NOT NULL DEFAULT 1,
  CreatedAt         DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt         DATETIME2(3) NULL,
  CONSTRAINT UQ_App UNIQUE(WorkspaceId, AppCode)
);

-- 4. App Audiences
CREATE TABLE core.AppAudiences(
  AudienceId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  AppId           BIGINT NOT NULL REFERENCES core.WorkspaceApps(AppId),
  AudienceCode    VARCHAR(50) NOT NULL,
  AudienceName    NVARCHAR(200) NOT NULL,
  EntraGroupUid   UNIQUEIDENTIFIER NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  CONSTRAINT UQ_Audience UNIQUE(AppId, AudienceCode)
);

-- 5. Reports
CREATE TABLE core.Reports(
  ReportId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId     BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  ReportCode      VARCHAR(80) NOT NULL,
  ReportName      NVARCHAR(200) NOT NULL,
  ReportTag       VARCHAR(120) NULL,
  OwnerUPN        NVARCHAR(256) NULL,
  EntraGroupUid   UNIQUEIDENTIFIER NULL,
  DeliveryMethod  VARCHAR(10) NOT NULL CHECK (DeliveryMethod IN ('SAR','AUR')),
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  CONSTRAINT UQ_Report UNIQUE(WorkspaceId, ReportCode)
);

-- 6. Audience-Report Mapping
CREATE TABLE core.AudienceReports(
  AudienceReportId BIGINT IDENTITY(1,1) PRIMARY KEY,
  AudienceId       BIGINT NOT NULL REFERENCES core.AppAudiences(AudienceId),
  ReportId         BIGINT NOT NULL REFERENCES core.Reports(ReportId),
  IsActive         BIT NOT NULL DEFAULT 1,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UNIQUE(AudienceId, ReportId)
);
GO
```

---

### Phase 4: Import Schema

#### Step 6: Create Import Tables

```sql
-- 1. Line Manager (from UMS/Workday)
CREATE TABLE imp.LineManager(
  LineManagerId BIGINT IDENTITY(1,1) PRIMARY KEY,
  EmployeeUPN   NVARCHAR(256) NOT NULL,
  ManagerUPN    NVARCHAR(256) NOT NULL,
  ValidFrom     DATETIME2(3) NOT NULL,
  ValidTo       DATETIME2(3) NULL,
  CONSTRAINT UQ_LineMgr UNIQUE(EmployeeUPN, ValidFrom)
);

-- 2. Dimension Source (from UMS/EDP)
CREATE TABLE imp.DimensionSource(
  DimensionSourceId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityDimensionId BIGINT NOT NULL,  -- FK added later
  NaturalKey        NVARCHAR(200) NOT NULL,
  ParentNaturalKey  NVARCHAR(200) NULL,
  LevelName         NVARCHAR(50) NULL,
  DisplayName       NVARCHAR(200) NOT NULL,
  ExtraJSON         NVARCHAR(MAX) NULL,
  ValidFrom         DATETIME2(3) NOT NULL,
  ValidTo           DATETIME2(3) NULL,
  UNIQUE(SecurityDimensionId, NaturalKey, ValidFrom)
);

CREATE INDEX IX_imp_DimensionSource_Parent 
  ON imp.DimensionSource(SecurityDimensionId, ParentNaturalKey, ValidFrom);
GO
```

---

### Phase 5: Security Schema

#### Step 7: Create Security Tables

```sql
-- 1. Security Models
CREATE TABLE sec.SecurityModels(
  SecurityModelId BIGINT IDENTITY(1,1) PRIMARY KEY,
  WorkspaceId     BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  SecurityModelCode VARCHAR(50) NOT NULL,
  SecurityModelName NVARCHAR(200) NOT NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UpdatedAt       DATETIME2(3) NULL,
  UNIQUE(WorkspaceId, SecurityModelCode)
);

-- 2. Security Dimensions
CREATE TABLE sec.SecurityDimensions(
  SecurityDimensionId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityDimensionCode VARCHAR(20) NOT NULL UNIQUE,
  SecurityDimensionName NVARCHAR(100) NOT NULL,
  IsHierarchical   BIT NOT NULL DEFAULT 0
);

-- 3. Security Type-Dimension Mapping
CREATE TABLE sec.SecurityTypeDimension(
  SecurityModelId     BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode    VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  SecurityDimensionId BIGINT NOT NULL REFERENCES sec.SecurityDimensions(SecurityDimensionId),
  StepOrder           TINYINT NOT NULL,
  PRIMARY KEY(SecurityModelId, SecurityTypeCode, SecurityDimensionId)
);

-- 4. Entity Hierarchy (helper table)
CREATE TABLE sec.EntityHierarchy(
  SecurityModelId BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  LevelName       NVARCHAR(50) NOT NULL,
  NaturalKey      NVARCHAR(200) NOT NULL,
  ParentNaturalKey NVARCHAR(200) NULL,
  PRIMARY KEY(SecurityModelId, LevelName, NaturalKey)
);

-- 5. OLS Approvers
CREATE TABLE sec.OLSApprovers(
  OLSApproverId   BIGINT IDENTITY(1,1) PRIMARY KEY,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId   BIGINT NOT NULL,
  ApproverUPN     NVARCHAR(256) NOT NULL,
  IsActive        BIT NOT NULL DEFAULT 1,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

-- 6. RLS Approver Scopes
CREATE TABLE sec.RLSApproverScopes(
  RLSApproverScopeId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SecurityModelId    BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode   VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  ApproverUPN        NVARCHAR(256) NOT NULL,
  ScopeJSON          NVARCHAR(MAX) NOT NULL,
  IsActive           BIT NOT NULL DEFAULT 1,
  CreatedAt          DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

-- 7. Object Security Binding
CREATE TABLE sec.ObjectSecurityBinding(
  BindingId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId    BIGINT NOT NULL,
  SecurityModelId  BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  IsActive         BIT NOT NULL DEFAULT 1,
  UNIQUE(CatalogItemTypeCode, CatalogItemId)
);

-- 8. Delegations
CREATE TABLE sec.Delegations(
  DelegationId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  ApproverUPN      NVARCHAR(256) NOT NULL,
  DelegateUPN      NVARCHAR(256) NOT NULL,
  StartsAt         DATETIME2(3) NOT NULL,
  EndsAt           DATETIME2(3) NOT NULL,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  UNIQUE(ApproverUPN, DelegateUPN, StartsAt)
);

-- Now add FK to imp.DimensionSource
ALTER TABLE imp.DimensionSource
ADD CONSTRAINT FK_DimensionSource_SecurityDimensions
FOREIGN KEY (SecurityDimensionId) REFERENCES sec.SecurityDimensions(SecurityDimensionId);
GO

-- Seed Security Dimensions
INSERT sec.SecurityDimensions(SecurityDimensionCode, SecurityDimensionName, IsHierarchical) VALUES
  ('ENT', 'Entity', 1),
  ('SL', 'Service Line', 1),
  ('CL', 'Client', 0),
  ('CC', 'Cost Center', 1),
  ('CTY', 'Country', 1),
  ('PC', 'Profit Center', 1),
  ('MSS', 'Master Service Set', 1),
  ('WFIAGG', 'WFI People Aggregator', 1);
GO
```

---

### Phase 6: Request Schema

#### Step 8: Create Request Tables

```sql
-- 1. Requests (header)
CREATE TABLE req.Requests(
  RequestId        BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestedByUPN   NVARCHAR(256) NOT NULL,
  RequestedForUPN  NVARCHAR(256) NOT NULL,
  WorkspaceId      BIGINT NOT NULL REFERENCES core.Workspaces(WorkspaceId),
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CurrentDecision  VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  ClosedAt         DATETIME2(3) NULL
);

-- 2. OLS Request
CREATE TABLE req.OLSRequest(
  OLSRequestId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  CatalogItemTypeCode VARCHAR(20) NOT NULL REFERENCES core.CatalogItemTypeLoV(CatalogItemTypeCode),
  CatalogItemId    BIGINT NOT NULL,
  ApproverList     NVARCHAR(MAX) NULL,
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecidedByUPN     NVARCHAR(256) NULL,
  DecidedAt        DATETIME2(3) NULL
);

-- 3. RLS Request
CREATE TABLE req.RLSRequest(
  RLSRequestId     BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  SecurityModelId  BIGINT NOT NULL REFERENCES sec.SecurityModels(SecurityModelId),
  SecurityTypeCode VARCHAR(20) NOT NULL REFERENCES sec.SecurityTypeLoV(SecurityTypeCode),
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecidedByUPN     NVARCHAR(256) NULL,
  DecidedAt        DATETIME2(3) NULL
);

-- 4. RLS Request Lines
CREATE TABLE req.RLSRequestLine(
  RLSRequestLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
  RLSRequestId     BIGINT NOT NULL REFERENCES req.RLSRequest(RLSRequestId) ON DELETE CASCADE,
  SecurityDimensionId BIGINT NOT NULL REFERENCES sec.SecurityDimensions(SecurityDimensionId),
  NaturalKey       NVARCHAR(200) NOT NULL,
  LevelName        NVARCHAR(50) NULL,
  SortOrder        SMALLINT NOT NULL DEFAULT 1
);

-- 5. Approvals
CREATE TABLE req.Approvals(
  ApprovalId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId        BIGINT NOT NULL REFERENCES req.Requests(RequestId) ON DELETE CASCADE,
  OLSRequestId     BIGINT NULL REFERENCES req.OLSRequest(OLSRequestId) ON DELETE CASCADE,
  RLSRequestId     BIGINT NULL REFERENCES req.RLSRequest(RLSRequestId) ON DELETE CASCADE,
  ApprovalStageCode VARCHAR(10) NOT NULL REFERENCES req.ApprovalStageLoV(ApprovalStageCode),
  ApproverUPN      NVARCHAR(256) NOT NULL,
  Decision         VARCHAR(12) NOT NULL DEFAULT 'Pending' REFERENCES req.DecisionLoV(DecisionCode),
  DecisionReason   NVARCHAR(1000) NULL,
  DecidedAt        DATETIME2(3) NULL,
  CreatedAt        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_req_Approvals_Pending 
  ON req.Approvals(ApproverUPN, Decision) 
  WHERE Decision='Pending';

-- 6. Revocations
CREATE TABLE req.Revocations(
  RevocationId  BIGINT IDENTITY(1,1) PRIMARY KEY,
  RequestId     BIGINT NOT NULL REFERENCES req.Requests(RequestId),
  Scope         VARCHAR(10) NOT NULL CHECK (Scope IN ('OLS','RLS')),
  ScopeId       BIGINT NOT NULL,
  Reason        NVARCHAR(1000) NOT NULL,
  RevokedByUPN  NVARCHAR(256) NOT NULL,
  RevokedAt     DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Additional indexes for performance
CREATE INDEX IX_req_Request_User 
  ON req.Requests(RequestedForUPN, CreatedAt DESC);

CREATE INDEX IX_req_OLSRequest_Item 
  ON req.OLSRequest(CatalogItemTypeCode, CatalogItemId);

CREATE INDEX IX_req_RLSRequest_ModelType 
  ON req.RLSRequest(SecurityModelId, SecurityTypeCode, Decision);
GO
```

---

### Phase 7: Admin & Logging

#### Step 9: Create Admin/Log Tables

```sql
-- ADMIN SCHEMA
-- 1. Email Settings
CREATE TABLE admin.EmailSettings(
  EmailSettingsId BIGINT IDENTITY(1,1) PRIMARY KEY,
  SendEnabled     BIT NOT NULL DEFAULT 1,
  SenderAddress   NVARCHAR(256) NOT NULL,
  SubjectPrefix   NVARCHAR(50) NULL,
  RetryCount      TINYINT NOT NULL DEFAULT 3,
  UpdatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

-- 2. Email Templates
CREATE TABLE admin.EmailTemplates(
  TemplateCode    VARCHAR(40) PRIMARY KEY,
  SubjectTemplate NVARCHAR(200) NOT NULL,
  BodyTemplate    NVARCHAR(MAX) NOT NULL
);

-- 3. Email Queue
CREATE TABLE admin.EmailQueue(
  EmailId         BIGINT IDENTITY(1,1) PRIMARY KEY,
  TemplateCode    VARCHAR(40) NOT NULL REFERENCES admin.EmailTemplates(TemplateCode),
  ToUPN           NVARCHAR(256) NOT NULL,
  CcUPN           NVARCHAR(MAX) NULL,
  PayloadJSON     NVARCHAR(MAX) NOT NULL,
  Status          VARCHAR(12) NOT NULL DEFAULT 'Pending',
  Attempts        TINYINT NOT NULL DEFAULT 0,
  CreatedAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  SentAt          DATETIME2(3) NULL,
  ErrorText       NVARCHAR(2000) NULL
);

-- 4. Help Bubbles
CREATE TABLE admin.HelpBubbles(
  HelpId       BIGINT IDENTITY(1,1) PRIMARY KEY,
  PageKey      VARCHAR(100) NOT NULL,
  ElementKey   VARCHAR(100) NOT NULL,
  HelpText     NVARCHAR(1000) NOT NULL,
  IsActive     BIT NOT NULL DEFAULT 1,
  UNIQUE(PageKey, ElementKey)
);

-- 5. System Settings
CREATE TABLE admin.SystemSettings(
  SettingKey   VARCHAR(100) PRIMARY KEY,
  SettingValue NVARCHAR(1000) NOT NULL,
  UpdatedAt    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);

-- LOG SCHEMA
-- 1. Audit Log
CREATE TABLE log.Audit(
  AuditId      BIGINT IDENTITY(1,1) PRIMARY KEY,
  ObjectType   VARCHAR(40) NOT NULL,
  ObjectId     BIGINT NULL,
  Action       VARCHAR(40) NOT NULL,
  WhoUPN       NVARCHAR(256) NOT NULL,
  WhenAt       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  BeforeJSON   NVARCHAR(MAX) NULL,
  AfterJSON    NVARCHAR(MAX) NULL
);

CREATE INDEX IX_log_Audit_Object 
  ON log.Audit(ObjectType, ObjectId, WhenAt DESC);
GO
```

---

### Phase 8: Sharing Views

#### Step 10: Create Sharing Views

```sql
-- 1. RLS User Grants View
CREATE VIEW shr.RLS_UserGrants AS
SELECT
  rr.RLSRequestId,
  r.RequestedForUPN              AS RequestedFor,
  r.CreatedAt                    AS RequestDate,
  rr.SecurityModelId,
  sm.SecurityModelName,
  rr.SecurityTypeCode            AS SecurityType,
  a.DecidedAt                    AS ApprovalDate,
  a.ApproverUPN                  AS ApprovedBy,
  JSON_QUERY((
    SELECT 
      sd.SecurityDimensionName AS Dimension,
      rl.NaturalKey,
      rl.LevelName,
      ds.DisplayName
    FROM req.RLSRequestLine rl
    JOIN sec.SecurityDimensions sd ON sd.SecurityDimensionId = rl.SecurityDimensionId
    LEFT JOIN imp.DimensionSource ds 
      ON ds.SecurityDimensionId = rl.SecurityDimensionId 
      AND ds.NaturalKey = rl.NaturalKey
      AND ds.ValidTo IS NULL
    WHERE rl.RLSRequestId = rr.RLSRequestId
    ORDER BY rl.SortOrder
    FOR JSON PATH
  ))                             AS DimensionSelectionsJSON
FROM req.RLSRequest rr
JOIN req.Requests r       ON r.RequestId = rr.RequestId
JOIN sec.SecurityModels sm ON sm.SecurityModelId = rr.SecurityModelId
JOIN req.Approvals a      ON a.RLSRequestId = rr.RLSRequestId 
                           AND a.Decision = 'Approved'
                           AND a.ApprovalStageCode = 'RLS'
WHERE rr.Decision = 'Approved';
GO

-- 2. OLS User Access View
CREATE VIEW shr.OLS_UserAccess AS
SELECT
  o.OLSRequestId,
  r.RequestedForUPN         AS RequestedFor,
  r.CreatedAt               AS RequestDate,
  o.CatalogItemTypeCode     AS CatalogueItemType,
  o.CatalogItemId           AS CatalogueItemId,
  CASE o.CatalogItemTypeCode
    WHEN 'Report' THEN rep.ReportName
    WHEN 'App' THEN app.AppName
    WHEN 'Audience' THEN aud.AudienceName
  END                       AS CatalogueItemName,
  ap.DecidedAt              AS ApprovalDate,
  ap.ApproverUPN            AS ApprovedBy
FROM req.OLSRequest o
JOIN req.Requests r ON r.RequestId = o.RequestId
JOIN req.Approvals ap ON ap.OLSRequestId = o.OLSRequestId 
                      AND ap.Decision = 'Approved'
                      AND ap.ApprovalStageCode = 'OLS'
LEFT JOIN core.Reports rep ON o.CatalogItemTypeCode = 'Report' AND rep.ReportId = o.CatalogItemId
LEFT JOIN core.WorkspaceApps app ON o.CatalogItemTypeCode = 'App' AND app.AppId = o.CatalogItemId
LEFT JOIN core.AppAudiences aud ON o.CatalogItemTypeCode = 'Audience' AND aud.AudienceId = o.CatalogItemId
WHERE o.Decision = 'Approved';
GO
```

---

### Phase 9: Security Roles

#### Step 11: Create Database Roles

```sql
-- 1. Admin role
CREATE ROLE sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::sec TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::req TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::admin TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::log TO sakura_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::imp TO sakura_admin;
GRANT SELECT ON SCHEMA::shr TO sakura_admin;

-- 2. Support role
CREATE ROLE sakura_support;
GRANT SELECT ON SCHEMA::core TO sakura_support;
GRANT SELECT ON SCHEMA::sec TO sakura_support;
GRANT SELECT ON SCHEMA::req TO sakura_support;
GRANT SELECT ON SCHEMA::admin TO sakura_support;
GRANT SELECT ON SCHEMA::log TO sakura_support;
GRANT SELECT ON SCHEMA::imp TO sakura_support;
GRANT SELECT ON SCHEMA::shr TO sakura_support;

-- 3. Import role
CREATE ROLE sakura_import;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::imp TO sakura_import;
GRANT SELECT ON SCHEMA::sec TO sakura_import;

-- 4. Sharing role
CREATE ROLE sakura_sharing;
GRANT SELECT ON SCHEMA::shr TO sakura_sharing;

-- 5. Application role
CREATE ROLE sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::core TO sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::sec TO sakura_app;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::req TO sakura_app;
GRANT SELECT ON SCHEMA::admin TO sakura_app;
GRANT INSERT ON SCHEMA::log TO sakura_app;
GRANT SELECT ON SCHEMA::imp TO sakura_app;
GRANT SELECT ON SCHEMA::shr TO sakura_app;
GO
```

---

### Best Practices

#### 1. Always Use Transactions

```sql
-- When creating requests, wrap in transaction
BEGIN TRANSACTION;
BEGIN TRY
  -- Insert request
  INSERT INTO req.Requests (RequestedByUPN, RequestedForUPN, WorkspaceId) 
  VALUES ('user@dentsu.com', 'user@dentsu.com', 1);
  
  DECLARE @RequestId BIGINT = SCOPE_IDENTITY();
  
  -- Insert OLS
  INSERT INTO req.OLSRequest (RequestId, CatalogItemTypeCode, CatalogItemId) 
  VALUES (@RequestId, 'Report', 789);
  
  -- Insert RLS
  -- ... more inserts ...
  
  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  ROLLBACK TRANSACTION;
  THROW;
END CATCH;
```

#### 2. Always Audit Changes

```sql
-- After any significant change
INSERT INTO log.Audit (ObjectType, ObjectId, Action, WhoUPN, AfterJSON)
VALUES ('Request', @RequestId, 'Create', @CurrentUserUPN, @RequestJSON);
```

#### 3. Use Proper Indexes

```sql
-- Already created in Step 8, but here's why they matter:
-- ✓ Speeds up "My Pending Approvals" queries
-- ✓ Speeds up "User's Access History" queries
-- ✓ Speeds up "Find Approver" queries
```

#### 4. Regular Maintenance

```sql
-- Weekly: Rebuild fragmented indexes
ALTER INDEX ALL ON req.Approvals REBUILD;

-- Monthly: Update statistics
UPDATE STATISTICS req.Requests WITH FULLSCAN;
UPDATE STATISTICS req.Approvals WITH FULLSCAN;

-- Quarterly: Archive old completed requests (older than 2 years)
-- Move to archive table instead of deleting
```

#### 5. Monitoring Queries

```sql
-- 1. Check for stuck approvals (pending > 30 days)
SELECT r.RequestId, r.RequestedForUPN, a.ApprovalStageCode, 
       DATEDIFF(DAY, a.CreatedAt, GETUTCDATE()) AS DaysPending
FROM req.Requests r
JOIN req.Approvals a ON a.RequestId = r.RequestId
WHERE a.Decision = 'Pending'
  AND DATEDIFF(DAY, a.CreatedAt, GETUTCDATE()) > 30;

-- 2. Check email queue health
SELECT Status, COUNT(*) AS Count
FROM admin.EmailQueue
GROUP BY Status;

-- 3. Most requested reports
SELECT TOP 10 
  rep.ReportName,
  COUNT(*) AS RequestCount
FROM req.OLSRequest o
JOIN core.Reports rep ON rep.ReportId = o.CatalogItemId
WHERE o.CatalogItemTypeCode = 'Report'
GROUP BY rep.ReportName
ORDER BY COUNT(*) DESC;
```

---

## Summary & Quick Reference

### Database Object Count

```
Schemas: 7 (core, sec, req, admin, log, imp, shr)
Tables: 32
Views: 2
Indexes: 6
Roles: 5
```

### Key Tables Reference

| **Purpose** | **Table** | **Schema** |
|------------|-----------|------------|
| User requests access | `req.Requests` | req |
| Object-level request | `req.OLSRequest` | req |
| Row-level request | `req.RLSRequest` | req |
| Approval chain | `req.Approvals` | req |
| Workspaces | `core.Workspaces` | core |
| Reports | `core.Reports` | core |
| Security models | `sec.SecurityModels` | sec |
| OLS approvers | `sec.OLSApprovers` | sec |
| RLS approvers | `sec.RLSApproverScopes` | sec |
| Audit trail | `log.Audit` | log |
| Email queue | `admin.EmailQueue` | admin |
| Dimension data | `imp.DimensionSource` | imp |
| User access (export) | `shr.OLS_UserAccess` | shr |
| RLS grants (export) | `shr.RLS_UserGrants` | shr |

---

## Congratulations! 🎉

You now have a complete understanding of the Sakura V2.0 SQL Server database design from top to bottom.

**Key Takeaways:**
1. **3-Stage Approval**: LM → OLS → RLS (sequential, strict)
2. **Flexibility**: Supports SAR/AUR, multiple RLS types, delegations
3. **Audit Trail**: Every action is logged with before/after snapshots
4. **Scalability**: Historized dimensions, proper indexes, modular design
5. **Real-World Ready**: Email notifications, revocations, on-behalf requests

**Next Steps:**
- Build the application layer (C# / .NET / Node.js)
- Create the UI (React / Angular / Blazor)
- Set up ETL jobs for imp.LineManager and imp.DimensionSource
- Configure SMTP for email queue processor
- Create Power BI reports using shr views

**Need Help?**
- Review the real-world scenarios in the "End-to-End Flow Examples" section
- Use the implementation guide as a checklist
- Reference the database design document for specific table details

---

**Document Version:** 1.0  
**Last Updated:** October 11, 2024  
**Database:** Sakura V2.0 for SQL Server


