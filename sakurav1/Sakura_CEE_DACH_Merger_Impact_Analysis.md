# Sakura Impact Analysis: CEE & DACH Merger to Central Europe

**Change Request:** Merger of CEE (Central and Eastern Europe) and DACH (Germany, Austria, Switzerland) clusters into new "Central Europe" cluster  
**Effective Date:** 1st week of February 2026  
**Document Version:** 1.0  
**Date:** 2025-01-XX

---

## Executive Summary

This document provides a comprehensive analysis of changes required in Sakura Portal to support the organizational restructuring that merges CEE and DACH clusters into a new "Central Europe" cluster. The analysis covers database changes, permission impact, RLS updates, bulk operations, and testing requirements.

**Estimated Total Effort:** 40-60 hours  
**Estimated Timeline:** 3-4 weeks (including testing and validation)

---

## 1. Change Overview

### 1.1 Organizational Hierarchy Change

**Current State:**
- **CEE Cluster:** Contains markets: Czech Republic, Austria, Slovakia, Hungary, Poland, Bulgaria, Croatia, Romania, Dentsu Balkans
- **DACH Cluster:** Contains markets: Germany, Austria, Switzerland

**Target State:**
- **Central Europe Cluster:** Contains all markets from both CEE and DACH
  - **CASH Subcluster:** Czech Republic, Austria, Slovakia, Hungary
  - **Germany Subcluster:** Germany
  - **Poland Subcluster:** Poland
  - **SEE Subcluster:** Bulgaria, Croatia, Dentsu Balkans, Romania
  - **Switzerland Subcluster:** Switzerland

### 1.2 Sakura Impact Areas

1. **Entity Table Updates** - Reference data changes
2. **Permission Request Impact** - Existing permissions may need updates
3. **Approver Rules Updates** - Approver mappings may change
4. **RLS Rules** - Row-level security rules need updating (if implemented)
5. **Bulk Permission Updates** - Mass updates for affected users
6. **Reporting Views** - May need validation
7. **Group Mapping** - No changes expected (group mapping is ServiceLine-based)

---

## 2. Detailed Change Analysis

### 2.1 Entity Table Changes

**Table:** `dbo.Entity` (1,497 rows)

**Changes Required:**

1. **Create New Cluster Record:**
   - Insert new "Central Europe" cluster entity
   - Set `EntityLevel = 'Cluster'`
   - Set `RegionKey` to appropriate EMEA region
   - Generate new `EntityKey`, `EntityCode`
   - Set `SakuraPath` to include new cluster in hierarchy

2. **Create New Subcluster Records:**
   - Insert 5 subcluster entities:
     - CASH (Czech Republic, Austria, Slovakia, Hungary)
     - Germany
     - Poland
     - SEE (South Eastern Europe)
     - Switzerland
   - Set `EntityLevel = 'Subcluster'` (or appropriate level)
   - Set `ClusterKey` to new Central Europe cluster key

3. **Update Market Records:**
   - Update all market records that currently reference CEE or DACH clusters
   - Change `ClusterKey` to new Central Europe cluster key
   - Update `MarketKey` to point to appropriate subcluster
   - Update `SakuraPath` to reflect new hierarchy

4. **Update Entity Hierarchy Paths:**
   - Recalculate `SakuraPath` for all affected entities
   - Ensure path format: `|Global|Region|Cluster|Market|Entity|`

**Estimated Effort:** 8-12 hours
- Data preparation: 2-3 hours
- ETL script development: 3-4 hours
- Testing: 2-3 hours
- Production execution: 1-2 hours

**ETL Process:**
- Load new hierarchy into `staging.Entity` table
- Run `sp_Load_Entity` procedure
- Verify `history.Entity` table captures changes
- Validate `SakuraPath` calculations

**Risk Level:** **HIGH**
- Entity table is referenced by 2,074+ permission requests
- Changes affect approver resolution logic
- Changes affect `RDSecurityGroupPermission` view (indirectly via EntityCode matching)

---

### 2.2 Permission Request Impact Analysis

**Affected Tables:**
- `PermissionHeader` (2,280 rows)
- `PermissionOrgaDetail` (2,074 rows)
- `PermissionCPDetail` (109 rows)
- `PermissionMSSDetail` (20 rows)

**Impact Assessment:**

**Option 1: No Changes to Existing Requests (Recommended)**
- Existing permission requests reference `EntityCode` values
- If Entity codes remain the same (only hierarchy changes), no updates needed
- Requests continue to work with new hierarchy

**Option 2: Update Existing Requests**
- If Entity codes change, update all affected `PermissionOrgaDetail` records
- Update `PermissionCPDetail` records that reference affected entities
- Update `PermissionMSSDetail` records if applicable

**Analysis Required:**

```sql
-- Identify affected permission requests
SELECT 
    H.RequestId,
    H.RequestCode,
    H.RequestedFor,
    H.RequestType,
    H.ApprovalStatus,
    D.EntityCode,
    D.EntityLevel,
    D.ServiceLineCode,
    D.CostCenterCode
FROM PermissionHeader H
INNER JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
WHERE D.EntityCode IN (
    -- CEE cluster entities
    SELECT EntityCode FROM Entity WHERE ClusterKey = <CEE_ClusterKey>
    UNION
    -- DACH cluster entities
    SELECT EntityCode FROM Entity WHERE ClusterKey = <DACH_ClusterKey>
)
AND H.ApprovalStatus IN (0, 1)  -- Pending or Approved
```

**Estimated Effort:** 4-8 hours
- Impact analysis query: 1 hour
- Decision on update strategy: 1 hour
- Update script development (if needed): 2-4 hours
- Testing: 1-2 hours

**Risk Level:** **MEDIUM**
- Depends on whether Entity codes change
- If codes remain same, risk is LOW
- If codes change, risk is HIGH (requires bulk updates)

---

### 2.3 Approver Rules Updates

**Affected Tables:**
- `ApproversOrga` (449 rows)
- `ApproversCP` (33 rows)
- `ApproversMSS` (8 rows)

**Changes Required:**

1. **Identify Approver Rules Scoped to CEE/DACH:**
   ```sql
   -- Find approver rules for CEE cluster
   SELECT * FROM ApproversOrga
   WHERE EntityCode IN (
       SELECT EntityCode FROM Entity 
       WHERE ClusterKey = <CEE_ClusterKey>
   )
   
   -- Find approver rules for DACH cluster
   SELECT * FROM ApproversOrga
   WHERE EntityCode IN (
       SELECT EntityCode FROM Entity 
       WHERE ClusterKey = <DACH_ClusterKey>
   )
   ```

2. **Update Approver Rules:**
   - Update `EntityCode` references to new Central Europe cluster codes
   - Update `EntityLevel` if approvers are scoped at cluster level
   - Maintain approver assignments (same approvers, new scope)

3. **Validate Approver Resolution:**
   - Test `FindOrgaApprovers` procedure with new hierarchy
   - Test `FindCPApprovers` procedure
   - Test `FindMSSApprovers` procedure

**Estimated Effort:** 6-10 hours
- Analysis: 2 hours
- Update script: 2-3 hours
- Testing: 2-3 hours
- Validation: 1-2 hours

**Risk Level:** **HIGH**
- Incorrect approver rules = requests routed to wrong approvers
- May cause approval delays or rejections
- Critical for business operations

---

### 2.4 RLS (Row-Level Security) Rules

**Note:** RLS rules are not explicitly documented in the architecture documents, but if implemented, they would likely be:

1. **PowerBI RLS Rules** (if managed in Sakura):
   - Rules that filter data based on Entity hierarchy
   - May be stored in `ApplicationSettings` or separate RLS table
   - Need to update rules to reference new Central Europe cluster

2. **Database-Level RLS** (if implemented):
   - SQL Server Row-Level Security policies
   - Would need to update policy definitions

**Changes Required (if RLS exists):**

1. **Identify RLS Rules:**
   - Query for RLS-related configuration
   - Identify rules scoped to CEE/DACH clusters

2. **Update RLS Rules:**
   - Update cluster references to Central Europe
   - Update subcluster mappings
   - Validate rule logic

**Estimated Effort:** 8-12 hours (if RLS exists)
- Discovery: 2-3 hours
- Update script: 3-4 hours
- Testing: 2-3 hours
- Validation: 1-2 hours

**Risk Level:** **HIGH** (if RLS exists)
- Incorrect RLS = users see wrong data or lose access
- Critical for data security and compliance

**Action Required:**
- **Confirm if RLS is implemented in Sakura**
- **Identify where RLS rules are stored**
- **Document RLS rule structure**

---

### 2.5 Bulk Permission Updates

**Scenario:** If Entity codes change, bulk updates may be required for existing permissions.

**Bulk Update Process:**

1. **Identify Users Requiring Updates:**
   ```sql
   -- Users with CEE/DACH permissions
   SELECT DISTINCT H.RequestedFor
   FROM PermissionHeader H
   INNER JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
   WHERE D.EntityCode IN (
       SELECT EntityCode FROM Entity 
       WHERE ClusterKey IN (<CEE_ClusterKey>, <DACH_ClusterKey>)
   )
   AND H.ApprovalStatus = 1  -- Approved only
   ```

2. **Bulk Update Strategy:**

   **Option A: Update Existing Requests (Not Recommended)**
   - Update `PermissionOrgaDetail.EntityCode` for affected requests
   - Risk: Loses audit trail of original request scope
   - Risk: May break historical reporting

   **Option B: Create New Requests + Revoke Old (Recommended)**
   - Create new permission requests with new Entity codes
   - Auto-approve if same user/scope/application
   - Revoke old requests (sets `ApprovalStatus = 3`)
   - Maintains audit trail

3. **Bulk Import Process:**
   - Use `BulkImportRecords` table
   - Use `ProcessBulkImportRecords` procedure
   - Or use `BatchChangeStatusPermissionRequests` for revocations

**Estimated Effort:** 12-20 hours (if bulk updates required)
- Analysis: 2-3 hours
- Script development: 4-6 hours
- Testing: 3-4 hours
- Execution: 2-4 hours
- Validation: 1-3 hours

**Risk Level:** **HIGH** (if bulk updates required)
- Mass changes to permissions
- Requires careful testing
- May require user communication

**Decision Point:**
- **If Entity codes remain same:** No bulk updates needed (0 hours)
- **If Entity codes change:** Bulk updates required (12-20 hours)

---

### 2.6 Reporting Views Validation

**Affected Views:**
- `EntityCluster`
- `EntityClusterRegion`
- `EntityClusterRegionMarket`
- `EntityMarket`
- `EntityRegion`
- `PermissionHeaderList`
- `SakuraReportforAllEnviroments`

**Changes Required:**

1. **Validate View Output:**
   - Views should automatically reflect new hierarchy (if based on Entity table)
   - Verify views return correct data for Central Europe cluster
   - Verify subcluster hierarchies appear correctly

2. **Update View Definitions (if needed):**
   - Only if views have hardcoded cluster references
   - Unlikely, but needs validation

**Estimated Effort:** 2-4 hours
- Validation queries: 1-2 hours
- View definition review: 1 hour
- Testing: 1 hour

**Risk Level:** **LOW**
- Views are derived from base tables
- Should automatically reflect hierarchy changes
- Low risk of breaking changes

---

### 2.7 Group Mapping Impact

**Table:** `ReportingDeckSecurityGroups` (85 rows)

**Analysis:**
- Group mapping is **ServiceLine-based**, not Entity-based
- Group names contain ServiceLine codes (e.g., "#SG-UN-SAKURA-{ServiceLineCode}")
- Entity hierarchy changes should **NOT** affect group mappings
- No changes expected

**Estimated Effort:** 0 hours (validation only: 1 hour)

**Risk Level:** **LOW**
- Group mapping logic is independent of Entity hierarchy
- No changes required

---

## 3. Testing Requirements

### 3.1 Test Environment Setup

**Prerequisites:**
1. Test environment with representative data
2. Copy of production Entity hierarchy
3. Test users with CEE/DACH permissions
4. Test approver rules

**Test Data Requirements:**
- Sample permission requests for CEE cluster
- Sample permission requests for DACH cluster
- Sample approver rules scoped to CEE/DACH
- Sample users with active permissions

### 3.2 Test Scenarios

#### Test 1: Entity Hierarchy Update
- [ ] Load new Central Europe cluster into test
- [ ] Verify cluster created correctly
- [ ] Verify subclusters created correctly
- [ ] Verify markets mapped to correct subclusters
- [ ] Verify `SakuraPath` calculated correctly
- [ ] Verify `history.Entity` table updated

#### Test 2: Permission Request Validation
- [ ] Verify existing permission requests still valid
- [ ] Create new permission request for Central Europe cluster
- [ ] Verify request appears in `RDSecurityGroupPermission` view
- [ ] Verify group membership determination works

#### Test 3: Approver Resolution
- [ ] Test `FindOrgaApprovers` with new cluster
- [ ] Test `FindCPApprovers` with new cluster
- [ ] Test `FindMSSApprovers` with new cluster
- [ ] Verify approvers resolved correctly

#### Test 4: RLS Rules (if applicable)
- [ ] Test RLS rules with new cluster
- [ ] Verify users see correct data
- [ ] Verify access restrictions work

#### Test 5: Reporting Views
- [ ] Query `EntityCluster` view - verify Central Europe appears
- [ ] Query `PermissionHeaderList` - verify requests display correctly
- [ ] Query `SakuraReportforAllEnviroments` - verify metrics correct

#### Test 6: Bulk Operations (if required)
- [ ] Test bulk import process
- [ ] Test bulk revocation process
- [ ] Verify audit trail maintained

### 3.3 User Acceptance Testing

**UAT Scenarios:**
1. **User Access Validation:**
   - Extract list of CEE & DACH users from Sakura
   - Verify users can access reports
   - Verify correct data visibility
   - Document any access issues

2. **Approval Workflow Validation:**
   - Create test permission request for Central Europe
   - Verify approvers resolved correctly
   - Verify approval workflow completes
   - Verify group membership updated

**Estimated Effort:** 8-12 hours
- Test execution: 4-6 hours
- Issue resolution: 2-4 hours
- Documentation: 2 hours

---

## 4. Implementation Plan

### 4.1 Phase 1: Preparation (Week 1)

**Tasks:**
1. **Entity Hierarchy Analysis** (4 hours)
   - Extract current CEE/DACH hierarchy
   - Map markets to new subclusters
   - Prepare new hierarchy data

2. **Impact Analysis** (4 hours)
   - Run queries to identify affected permission requests
   - Identify affected approver rules
   - Determine if Entity codes change

3. **RLS Discovery** (4 hours)
   - Confirm if RLS is implemented
   - Identify RLS rule locations
   - Document RLS structure

4. **User Impact Analysis** (4 hours)
   - Extract list of CEE & DACH users
   - Identify users whose access will change
   - Prepare communication list

**Deliverables:**
- Entity hierarchy mapping document
- Impact analysis report
- User impact list
- RLS documentation (if applicable)

**Estimated Effort:** 16 hours

---

### 4.2 Phase 2: Development (Week 2)

**Tasks:**
1. **ETL Script Development** (8 hours)
   - Develop `staging.Entity` load script
   - Create Central Europe cluster records
   - Create subcluster records
   - Update market mappings
   - Test `sp_Load_Entity` procedure

2. **Approver Rules Update Script** (6 hours)
   - Develop script to update approver rules
   - Map old cluster approvers to new cluster
   - Test approver resolution

3. **RLS Update Script** (8 hours, if applicable)
   - Develop RLS rule update script
   - Test RLS rule logic

4. **Bulk Update Script** (12 hours, if required)
   - Develop bulk permission update script
   - Test bulk import/revocation process

**Deliverables:**
- ETL scripts
- Approver update scripts
- RLS update scripts (if applicable)
- Bulk update scripts (if required)

**Estimated Effort:** 26-34 hours (depending on RLS and bulk updates)

---

### 4.3 Phase 3: Testing (Week 3)

**Tasks:**
1. **Test Environment Setup** (4 hours)
   - Load test data
   - Configure test environment

2. **Test Execution** (12 hours)
   - Execute all test scenarios
   - Document test results
   - Log issues

3. **Issue Resolution** (8 hours)
   - Fix identified issues
   - Re-test fixes
   - Validate solutions

4. **UAT Support** (8 hours)
   - Support user acceptance testing
   - Resolve UAT issues
   - Validate user access

**Deliverables:**
- Test results document
- Issue log
- UAT sign-off

**Estimated Effort:** 32 hours

---

### 4.4 Phase 4: Production Deployment (Week 4)

**Tasks:**
1. **Production Preparation** (4 hours)
   - Final validation of scripts
   - Backup production data
   - Prepare rollback plan

2. **Production Deployment** (4 hours)
   - Execute Entity hierarchy update
   - Execute approver rules update
   - Execute RLS update (if applicable)
   - Execute bulk updates (if required)

3. **Post-Deployment Validation** (4 hours)
   - Verify Entity hierarchy correct
   - Verify permission requests valid
   - Verify approver resolution works
   - Verify reporting views correct
   - Connect reports and validate access

4. **Monitoring** (2 hours)
   - Monitor for issues
   - Resolve any immediate problems

**Deliverables:**
- Deployment log
- Post-deployment validation report
- Production sign-off

**Estimated Effort:** 14 hours

---

## 5. Effort Summary

### 5.1 Effort Breakdown by Component

| Component | Effort (Hours) | Risk Level |
|-----------|---------------|------------|
| Entity Table Updates | 8-12 | HIGH |
| Permission Request Analysis | 4-8 | MEDIUM |
| Approver Rules Updates | 6-10 | HIGH |
| RLS Rules Updates | 8-12 (if exists) | HIGH |
| Bulk Permission Updates | 12-20 (if required) | HIGH |
| Reporting Views Validation | 2-4 | LOW |
| Group Mapping Validation | 1 | LOW |
| Testing | 32 | MEDIUM |
| **Total (Minimum)** | **59-77** | |
| **Total (Maximum)** | **99-117** | |

### 5.2 Effort by Scenario

**Scenario A: Entity Codes Remain Same (Best Case)**
- Entity updates: 8 hours
- Approver updates: 6 hours
- RLS updates: 8 hours (if exists)
- Testing: 32 hours
- **Total: 54-58 hours**

**Scenario B: Entity Codes Change (Worst Case)**
- Entity updates: 12 hours
- Permission updates: 8 hours
- Approver updates: 10 hours
- RLS updates: 12 hours (if exists)
- Bulk updates: 20 hours
- Testing: 32 hours
- **Total: 94-102 hours**

**Scenario C: No RLS, Entity Codes Same (Most Likely)**
- Entity updates: 10 hours
- Approver updates: 8 hours
- Testing: 32 hours
- **Total: 50 hours**

### 5.3 Timeline Estimate

**Minimum Timeline:** 3 weeks
- Week 1: Preparation (16 hours)
- Week 2: Development (26 hours)
- Week 3: Testing (32 hours)
- Week 4: Production (14 hours)

**Maximum Timeline:** 4-5 weeks
- Week 1: Preparation (16 hours)
- Week 2-3: Development (34-60 hours)
- Week 4: Testing (32 hours)
- Week 5: Production (14 hours)

**Recommended Timeline:** **3-4 weeks**

---

## 6. Risk Assessment

### 6.1 High-Risk Areas

1. **Entity Hierarchy Changes**
   - **Risk:** Breaking existing permission requests
   - **Mitigation:** Maintain Entity codes if possible, thorough testing

2. **Approver Rules Updates**
   - **Risk:** Requests routed to wrong approvers
   - **Mitigation:** Comprehensive testing of approver resolution

3. **RLS Rules (if applicable)**
   - **Risk:** Users lose access or see wrong data
   - **Mitigation:** Early discovery, thorough testing

4. **Bulk Permission Updates**
   - **Risk:** Mass changes to user access
   - **Mitigation:** Careful planning, rollback plan, user communication

### 6.2 Medium-Risk Areas

1. **Permission Request Updates**
   - **Risk:** Historical data integrity
   - **Mitigation:** Prefer creating new requests over updating existing

2. **Testing Coverage**
   - **Risk:** Missing edge cases
   - **Mitigation:** Comprehensive test scenarios, UAT

### 6.3 Low-Risk Areas

1. **Reporting Views**
   - **Risk:** Views may need minor adjustments
   - **Mitigation:** Validation queries, view review

2. **Group Mapping**
   - **Risk:** No changes expected
   - **Mitigation:** Validation only

---

## 7. Dependencies

### 7.1 External Dependencies

1. **Ronin System:**
   - Central Europe cluster must be created in Ronin first
   - Subclusters must be created in Ronin
   - Market mappings must be complete in Ronin
   - **Blocking:** Yes - Sakura changes depend on Ronin completion

2. **RCoE Team:**
   - Must provide Entity hierarchy data
   - Must validate market mappings
   - **Blocking:** Yes - Need hierarchy data to proceed

### 7.2 Internal Dependencies

1. **Database Access:**
   - Need access to staging tables
   - Need permissions to run ETL procedures
   - **Blocking:** Yes

2. **Test Environment:**
   - Need test environment with representative data
   - **Blocking:** Yes

3. **User Communication:**
   - Need user list for communication
   - **Blocking:** No (can proceed in parallel)

---

## 8. Rollback Plan

### 8.1 Rollback Scenarios

**Scenario 1: Entity Hierarchy Rollback**
- Restore Entity table from backup
- Restore `history.Entity` table
- Re-run `sp_Load_Entity` with old hierarchy

**Scenario 2: Approver Rules Rollback**
- Restore `ApproversOrga`, `ApproversCP`, `ApproversMSS` from backup
- Or update rules back to old cluster references

**Scenario 3: Permission Request Rollback**
- If bulk updates performed, revoke new requests and restore old
- Use `RevokePermissionRequest` procedure
- Re-approve old requests if needed

### 8.2 Rollback Procedures

1. **Immediate Rollback (< 24 hours):**
   - Restore from database backup
   - Revert Entity hierarchy
   - Revert approver rules
   - Notify users

2. **Delayed Rollback (> 24 hours):**
   - May need to create new requests to restore access
   - Cannot simply restore (audit trail considerations)
   - More complex process

**Recommendation:** Test rollback procedures in test environment before production deployment.

---

## 9. Communication Plan

### 9.1 Stakeholder Communication

**Before Deployment:**
- Notify affected users of upcoming changes
- Provide timeline and expected impact
- Set expectations for access changes

**During Deployment:**
- Provide status updates
- Communicate any issues

**After Deployment:**
- Confirm successful deployment
- Provide user support
- Collect feedback

### 9.2 User Impact Communication

**Users to Notify:**
- All users with CEE cluster permissions
- All users with DACH cluster permissions
- Approvers for CEE/DACH clusters
- Administrators

**Communication Content:**
- What is changing (cluster merger)
- When it's happening (timeline)
- What users need to do (nothing, if Entity codes remain same)
- Who to contact for issues

---

## 10. Success Criteria

### 10.1 Technical Success Criteria

- [ ] Central Europe cluster created in Entity table
- [ ] All subclusters created and mapped correctly
- [ ] All markets mapped to correct subclusters
- [ ] Existing permission requests remain valid
- [ ] Approver resolution works correctly
- [ ] RLS rules updated (if applicable)
- [ ] Reporting views return correct data
- [ ] No errors in EventLog
- [ ] All tests pass

### 10.2 Business Success Criteria

- [ ] Users can access reports correctly
- [ ] Users see correct data (RLS working)
- [ ] Approval workflows function correctly
- [ ] No user access issues reported
- [ ] UAT sign-off received
- [ ] Production sign-off received

---

## 11. Open Questions & Decisions Required

### 11.1 Critical Decisions

1. **Entity Code Strategy:**
   - [ ] Will Entity codes remain the same?
   - [ ] Or will new codes be assigned?
   - **Impact:** Determines if bulk updates needed

2. **RLS Implementation:**
   - [ ] Is RLS implemented in Sakura?
   - [ ] Where are RLS rules stored?
   - **Impact:** Determines if RLS updates needed

3. **Permission Request Strategy:**
   - [ ] Update existing requests?
   - [ ] Or create new + revoke old?
   - **Impact:** Affects audit trail and effort

### 11.2 Information Needed

1. **Entity Hierarchy Data:**
   - [ ] New Central Europe cluster code
   - [ ] Subcluster codes and structure
   - [ ] Market to subcluster mappings
   - [ ] Entity code mapping (old to new)

2. **Approver Mapping:**
   - [ ] Current CEE approvers
   - [ ] Current DACH approvers
   - [ ] New Central Europe approvers
   - [ ] Approver assignment strategy

3. **User List:**
   - [ ] List of CEE users
   - [ ] List of DACH users
   - [ ] User communication preferences

---

## 12. Next Steps

### 12.1 Immediate Actions

1. **Confirm Entity Code Strategy** (Decision required)
   - Will Entity codes change or remain same?
   - This determines bulk update requirements

2. **Confirm RLS Implementation** (Discovery required)
   - Is RLS implemented?
   - Where are rules stored?

3. **Obtain Entity Hierarchy Data** (Data required)
   - Get new Central Europe cluster structure from RCoE
   - Get market mappings

4. **Extract User Impact List** (Analysis required)
   - Run queries to identify affected users
   - Prepare communication list

### 12.2 Week 1 Deliverables

- [ ] Entity hierarchy mapping document
- [ ] Impact analysis report
- [ ] User impact list
- [ ] RLS documentation (if applicable)
- [ ] Decision on Entity code strategy
- [ ] Decision on permission request update strategy

---

## Appendix A: SQL Queries for Impact Analysis

### A.1 Identify Affected Permission Requests

```sql
-- CEE Cluster Requests
SELECT 
    H.RequestId,
    H.RequestCode,
    H.RequestedFor,
    H.RequestType,
    H.ApprovalStatus,
    D.EntityCode,
    D.EntityLevel,
    D.ServiceLineCode
FROM PermissionHeader H
INNER JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
INNER JOIN Entity E ON D.EntityCode = E.EntityCode
WHERE E.ClusterKey = <CEE_ClusterKey>
AND H.ApprovalStatus IN (0, 1)  -- Pending or Approved

-- DACH Cluster Requests
SELECT 
    H.RequestId,
    H.RequestCode,
    H.RequestedFor,
    H.RequestType,
    H.ApprovalStatus,
    D.EntityCode,
    D.EntityLevel,
    D.ServiceLineCode
FROM PermissionHeader H
INNER JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
INNER JOIN Entity E ON D.EntityCode = E.EntityCode
WHERE E.ClusterKey = <DACH_ClusterKey>
AND H.ApprovalStatus IN (0, 1)  -- Pending or Approved
```

### A.2 Identify Affected Users

```sql
-- Users with CEE/DACH Permissions
SELECT DISTINCT 
    H.RequestedFor,
    COUNT(*) AS RequestCount,
    STRING_AGG(DISTINCT D.EntityCode, ', ') AS EntityCodes
FROM PermissionHeader H
INNER JOIN PermissionOrgaDetail D ON H.RequestId = D.RequestId
INNER JOIN Entity E ON D.EntityCode = E.EntityCode
WHERE E.ClusterKey IN (<CEE_ClusterKey>, <DACH_ClusterKey>)
AND H.ApprovalStatus = 1  -- Approved only
GROUP BY H.RequestedFor
ORDER BY RequestCount DESC
```

### A.3 Identify Affected Approver Rules

```sql
-- Approver Rules for CEE/DACH
SELECT 
    'Orga' AS ApproverType,
    ApproverId,
    EntityLevel,
    EntityCode,
    ServiceLineCode,
    ApproverUserName
FROM ApproversOrga
WHERE EntityCode IN (
    SELECT EntityCode FROM Entity 
    WHERE ClusterKey IN (<CEE_ClusterKey>, <DACH_ClusterKey>)
)
UNION ALL
SELECT 
    'CP' AS ApproverType,
    ApproverId,
    EntityLevel,
    EntityCode,
    ServiceLineCode,
    ApproverUserName
FROM ApproversCP
WHERE EntityCode IN (
    SELECT EntityCode FROM Entity 
    WHERE ClusterKey IN (<CEE_ClusterKey>, <DACH_ClusterKey>)
)
```

---

## Document Maintenance

**Last Updated:** 2025-01-XX  
**Next Review:** After decisions on open questions  
**Owner:** Sakura Team  
**Status:** Draft - Pending Decisions

---

**End of Document**

