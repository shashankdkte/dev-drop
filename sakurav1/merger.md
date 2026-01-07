# Sakura Domain Response: CEE/DACH Merger Stakeholder Questions

**Date:** 2025-01-XX  
**Domain:** Sakura Portal (EDP)  
**Change:** CEE & DACH Cluster Merger to Central Europe  
**Respondent:** Sakura Team

---

## Question 1: What is the Impact and Risks to Each Domain?

### Sakura Domain Impact Summary

**Impact Level:** MEDIUM to HIGH  
**Affected Components:** 4 major areas  
**Estimated Effort:** 50-100 hours  
**Timeline:** 3-4 weeks

### Detailed Impact Breakdown

#### 1.1 Entity Hierarchy (HIGH Impact)

**What Changes:**
- Create new "Central Europe" cluster in `dbo.Entity` table
- Create 5 new subclusters (CASH, Germany, Poland, SEE, Switzerland)
- Update all market records from CEE and DACH to point to new Central Europe cluster
- Recalculate `SakuraPath` for affected entities

**Affected Objects:**
- `dbo.Entity` table (1,497 rows total, ~50-100 rows affected)
- `staging.Entity` table (ETL staging)
- `history.Entity` table (temporal tracking)

**Risk Level:** HIGH
- Entity table is referenced by 2,074+ permission requests
- Changes affect approver resolution logic
- Changes affect permission request scoping

**Business Impact:**
- Users with CEE/DACH permissions may need updates (if Entity codes change)
- Approver rules need updates
- New permission requests will use new hierarchy

---

#### 1.2 Permission Requests (MEDIUM Impact)

**What Changes:**
- Depends on Entity code strategy:
  - **If codes stay same:** No changes needed (LOW impact)
  - **If codes change:** Bulk updates required (HIGH impact)

**Affected Objects:**
- `dbo.PermissionHeader` (2,280 rows total)
- `dbo.PermissionOrgaDetail` (2,074 rows - most affected)
- `dbo.PermissionCPDetail` (109 rows)
- `dbo.PermissionMSSDetail` (20 rows)

**Risk Level:** MEDIUM (if codes stay same) / HIGH (if codes change)

**Business Impact:**
- If codes change: 2,000+ permission requests may need updates
- Users may temporarily lose access if updates not done correctly
- Historical audit trail must be preserved

---

#### 1.3 Approver Rules (HIGH Impact)

**What Changes:**
- Update approver rules scoped to CEE cluster
- Update approver rules scoped to DACH cluster
- Map approvers to new Central Europe cluster

**Affected Objects:**
- `dbo.ApproversOrga` (449 rows, ~20-50 affected)
- `dbo.ApproversCP` (33 rows, ~5-10 affected)
- `dbo.ApproversMSS` (8 rows, ~2-5 affected)

**Risk Level:** HIGH

**Business Impact:**
- Incorrect approver rules = requests routed to wrong approvers
- May cause approval delays
- May cause requests to be rejected incorrectly
- Critical for business operations

---

#### 1.4 RLS (Row-Level Security) Rules (HIGH Impact - If Applicable)

**What Changes:**
- Update RLS rules that reference CEE cluster
- Update RLS rules that reference DACH cluster
- Map rules to new Central Europe cluster

**Affected Objects:**
- Location TBD (may be in `ApplicationSettings` or separate RLS table)
- PowerBI dataset RLS rules (if managed in Sakura)

**Risk Level:** HIGH (if RLS exists)

**Business Impact:**
- Incorrect RLS = users see wrong data or lose access
- Critical for data security and compliance
- May cause data visibility issues in PowerBI reports

**Note:** Need to confirm if RLS is implemented in Sakura

---

### Risk Summary Table

| Component | Impact Level | Risk Level | Effort (Hours) | Business Impact |
|-----------|-------------|------------|----------------|-----------------|
| Entity Hierarchy | HIGH | HIGH | 8-12 | Affects all new requests |
| Permission Requests | MEDIUM/HIGH | MEDIUM/HIGH | 0-20 | Depends on code strategy |
| Approver Rules | HIGH | HIGH | 6-10 | Approval workflow disruption |
| RLS Rules | HIGH | HIGH | 8-12 | Data access issues |
| **Total** | **HIGH** | **HIGH** | **22-54** | **Multiple business impacts** |

---

## Question 2: What is the Risk Mitigation Plan of Each Domain?

### Sakura Domain Risk Mitigation Plan

#### 2.1 Pre-Implementation Mitigation

**Risk:** Incorrect Entity hierarchy structure

**Mitigation:**
1. Get official hierarchy data from RCoE team
2. Validate structure against Ronin system
3. Review with business stakeholders before implementation
4. Test in non-production environment first

**Owner:** Sakura Team + RCoE Team  
**Timeline:** Week 1

---

**Risk:** Entity codes change causing bulk updates

**Mitigation:**
1. **Decision Point:** Confirm Entity code strategy early
2. **If codes stay same:** No bulk updates needed (preferred)
3. **If codes must change:**
   - Create new requests + revoke old (preserves audit trail)
   - Do NOT update existing requests directly
   - Test bulk process in non-production first

**Owner:** Sakura Team + Data Team  
**Timeline:** Week 1 (decision), Week 2-3 (if needed)

---

**Risk:** Approver rules incorrectly mapped

**Mitigation:**
1. Extract current CEE/DACH approver rules
2. Map to new Central Europe cluster with business validation
3. Test approver resolution with test requests
4. Validate with approvers before production

**Owner:** Sakura Team + Business Approvers  
**Timeline:** Week 2

---

**Risk:** RLS rules incorrectly updated (if applicable)

**Mitigation:**
1. **Discovery:** Confirm if RLS exists and where stored
2. Extract current RLS rules for CEE/DACH
3. Map to new Central Europe cluster
4. Test with sample users before production
5. Validate data visibility in PowerBI reports

**Owner:** Sakura Team + PowerBI Team  
**Timeline:** Week 1 (discovery), Week 2 (updates)

---

#### 2.2 Implementation Mitigation

**Risk:** Database corruption or data loss

**Mitigation:**
1. **Full database backup** before any changes
2. Test all scripts in non-production first
3. Use transactions for all updates
4. Verify data integrity after each step
5. Keep backup for 30 days minimum

**Owner:** Sakura Team + DBA  
**Timeline:** Before implementation

---

**Risk:** Users lose access during transition

**Mitigation:**
1. If Entity codes stay same: No access loss expected
2. If codes change: Coordinate bulk updates with sync schedule
3. Monitor `RDSecurityGroupPermission` view after changes
4. Verify Azure AD sync runs successfully
5. Have rollback plan ready

**Owner:** Sakura Team  
**Timeline:** During implementation

---

**Risk:** Approval workflow disruption

**Mitigation:**
1. Test approver resolution before production
2. Have backup approvers identified
3. Monitor approval times after changes
4. Quick response plan if approvers not found

**Owner:** Sakura Team + Business Approvers  
**Timeline:** Week 2-3

---

#### 2.3 Post-Implementation Mitigation

**Risk:** Issues discovered after production deployment

**Mitigation:**
1. **Monitoring:** Check EventLog for errors daily for 1 week
2. **User Support:** Quick response team for access issues
3. **Rollback Plan:** Documented and tested
4. **Communication:** User communication plan ready

**Owner:** Sakura Team  
**Timeline:** Week 4+

---

### Risk Mitigation Summary

| Risk | Mitigation Strategy | Owner | Timeline |
|------|-------------------|-------|----------|
| Incorrect hierarchy | Validate with RCoE, test in non-prod | Sakura + RCoE | Week 1 |
| Entity code changes | Early decision, bulk process tested | Sakura + Data | Week 1-3 |
| Approver mapping errors | Extract, map, test, validate | Sakura + Business | Week 2 |
| RLS errors | Discovery, extract, map, test | Sakura + PowerBI | Week 1-2 |
| Data loss | Full backup, transactions, verify | Sakura + DBA | Before impl |
| Access loss | Coordinate with sync, monitor | Sakura | During impl |
| Approval disruption | Test resolution, backup approvers | Sakura + Business | Week 2-3 |
| Post-deployment issues | Monitor, support, rollback ready | Sakura | Week 4+ |

---

## Question 3: What will be the Roll-out and Communication Tasks for Each Domain Stakeholder?

### Sakura Domain Roll-out Plan

#### 3.1 Pre-Rollout Communication (Week 1)

**Stakeholder:** All Sakura Users with CEE/DACH Permissions

**Communication:**
- **What:** Inform about upcoming cluster merger
- **When:** 2 weeks before implementation
- **How:** Email notification
- **Content:**
  - What is changing (CEE + DACH → Central Europe)
  - When it's happening (1st week of February 2026)
  - What users need to do (nothing, if codes stay same)
  - Who to contact for issues

**Owner:** Sakura Team + Communications Team  
**Timeline:** Week 1

---

**Stakeholder:** Approvers for CEE/DACH Clusters

**Communication:**
- **What:** Inform about approver rule updates
- **When:** 1 week before implementation
- **How:** Email + meeting if needed
- **Content:**
  - Approver rules will be updated
  - New cluster structure
  - Test approval workflow
  - Contact for questions

**Owner:** Sakura Team + Business Approvers  
**Timeline:** Week 1

---

**Stakeholder:** PowerBI Report Owners

**Communication:**
- **What:** Inform about RLS rule updates (if applicable)
- **When:** 1 week before implementation
- **How:** Email
- **Content:**
  - RLS rules may need updates
  - Test reports after changes
  - Contact for issues

**Owner:** Sakura Team + PowerBI Team  
**Timeline:** Week 1

---

#### 3.2 During Rollout Communication (Week 2-3)

**Stakeholder:** Sakura Team

**Tasks:**
- Execute Entity hierarchy updates
- Execute approver rule updates
- Execute RLS updates (if applicable)
- Execute bulk permission updates (if needed)
- Monitor for errors
- Provide status updates

**Communication:**
- Daily status updates to project team
- Issue escalation if problems found

**Owner:** Sakura Team  
**Timeline:** Week 2-3

---

**Stakeholder:** Test Users

**Communication:**
- **What:** Request UAT testing
- **When:** Week 3
- **How:** Email with test scenarios
- **Content:**
  - Test creating permission request
  - Test accessing reports
  - Test approval workflow
  - Report any issues

**Owner:** Sakura Team  
**Timeline:** Week 3

---

#### 3.3 Post-Rollout Communication (Week 4+)

**Stakeholder:** All Users

**Communication:**
- **What:** Confirm successful deployment
- **When:** Day 1 after production deployment
- **How:** Email notification
- **Content:**
  - Changes completed successfully
  - Central Europe cluster now active
  - Contact support if issues

**Owner:** Sakura Team  
**Timeline:** Week 4

---

**Stakeholder:** Support Team

**Communication:**
- **What:** Provide support documentation
- **When:** Before production deployment
- **How:** Documentation + training
- **Content:**
  - What changed
  - Common issues and solutions
  - Escalation path

**Owner:** Sakura Team  
**Timeline:** Week 3

---

### Communication Timeline

| Week | Stakeholder | Communication Type | Owner |
|------|------------|-------------------|-------|
| Week 1 | All Users | Email: Upcoming changes | Sakura + Comm |
| Week 1 | Approvers | Email: Approver updates | Sakura + Business |
| Week 1 | PowerBI Team | Email: RLS updates | Sakura + PowerBI |
| Week 2-3 | Project Team | Daily: Status updates | Sakura |
| Week 3 | Test Users | Email: UAT request | Sakura |
| Week 3 | Support Team | Training: Support docs | Sakura |
| Week 4 | All Users | Email: Deployment complete | Sakura |
| Week 4+ | Users with Issues | Support: Issue resolution | Sakura + Support |

---

## Question 4: Who is Responsible for UAT Testing RLS on Each Domain?

### Sakura Domain RLS UAT Responsibility

#### 4.1 RLS Testing Responsibility Matrix

**Primary Responsibility:** Sakura Team + PowerBI Team

**Sakura Team Responsibilities:**
1. Update RLS rules in Sakura database (if RLS stored in Sakura)
2. Verify RLS rules updated correctly
3. Test RLS rule logic with sample data
4. Coordinate with PowerBI team for dataset RLS

**PowerBI Team Responsibilities:**
1. Update RLS rules in PowerBI datasets (if RLS in PowerBI)
2. Test data visibility in reports
3. Validate users see correct data
4. Test with sample users from each subcluster

**Business Users Responsibilities:**
1. UAT testing with real user accounts
2. Verify correct data visibility
3. Report any access issues
4. Sign off on UAT completion

---

#### 4.2 UAT Testing Scenarios

**Scenario 1: User with CASH Subcluster Access**
- **Test User:** User from Czech Republic, Austria, Slovakia, or Hungary
- **Expected:** User sees data for CASH subcluster only
- **Test:** Access PowerBI reports, verify data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 2: User with Germany Subcluster Access**
- **Test User:** User from Germany
- **Expected:** User sees data for Germany subcluster only
- **Test:** Access PowerBI reports, verify data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 3: User with Poland Subcluster Access**
- **Test User:** User from Poland
- **Expected:** User sees data for Poland subcluster only
- **Test:** Access PowerBI reports, verify data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 4: User with SEE Subcluster Access**
- **Test User:** User from Bulgaria, Croatia, Romania, or Dentsu Balkans
- **Expected:** User sees data for SEE subcluster only
- **Test:** Access PowerBI reports, verify data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 5: User with Switzerland Subcluster Access**
- **Test User:** User from Switzerland
- **Expected:** User sees data for Switzerland subcluster only
- **Test:** Access PowerBI reports, verify data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 6: User with Multiple Subcluster Access**
- **Test User:** User with permissions for multiple subclusters
- **Expected:** User sees data for all authorized subclusters
- **Test:** Access PowerBI reports, verify combined data scope
- **Responsible:** PowerBI Team + Business User

---

**Scenario 7: Approver Resolution with New Cluster**
- **Test:** Create permission request for Central Europe cluster
- **Expected:** Correct approvers assigned
- **Test:** Create test request, verify approvers
- **Responsible:** Sakura Team + Business Approver

---

#### 4.3 UAT Sign-off Process

**Step 1: Technical Testing (Sakura Team)**
- [ ] RLS rules updated correctly
- [ ] Approver resolution works
- [ ] Permission requests work with new cluster
- [ ] No errors in EventLog

**Step 2: PowerBI Testing (PowerBI Team)**
- [ ] RLS rules updated in datasets
- [ ] Data visibility correct for each subcluster
- [ ] Reports load correctly
- [ ] No access errors

**Step 3: Business UAT (Business Users)**
- [ ] Test users can access reports
- [ ] Data visibility is correct
- [ ] Approval workflow works
- [ ] No issues reported

**Step 4: Sign-off**
- [ ] Sakura Team sign-off
- [ ] PowerBI Team sign-off
- [ ] Business User sign-off
- [ ] Project Manager sign-off

---

### UAT Responsibility Summary

| Test Scenario | Primary Owner | Secondary Owner | Sign-off Required |
|--------------|---------------|-----------------|-------------------|
| RLS Rule Updates | Sakura Team | PowerBI Team | Both |
| Data Visibility (CASH) | PowerBI Team | Business User | Business User |
| Data Visibility (Germany) | PowerBI Team | Business User | Business User |
| Data Visibility (Poland) | PowerBI Team | Business User | Business User |
| Data Visibility (SEE) | PowerBI Team | Business User | Business User |
| Data Visibility (Switzerland) | PowerBI Team | Business User | Business User |
| Multi-Subcluster Access | PowerBI Team | Business User | Business User |
| Approver Resolution | Sakura Team | Business Approver | Both |

---

## Question 5: What Support is Required from EDP Sakura and Ronin Teams?

### Support Required from Ronin Team

#### 5.1 Pre-Implementation Support

**Support Needed:**
1. **Entity Hierarchy Data**
   - Provide new Central Europe cluster structure
   - Provide subcluster codes and names
   - Provide market to subcluster mappings
   - Validate structure before Sakura implementation

**Timeline:** Week 1  
**Owner:** Ronin Team (RCoE)  
**Priority:** CRITICAL (blocking)

---

2. **Cluster Validation**
   - Confirm Central Europe cluster created in Ronin
   - Confirm all subclusters created
   - Confirm all markets mapped correctly
   - Provide cluster keys/codes for Sakura

**Timeline:** Week 1  
**Owner:** Ronin Team  
**Priority:** CRITICAL (blocking)

---

3. **Entity Code Strategy**
   - Confirm if Entity codes will change or stay same
   - If changing, provide mapping: Old Code → New Code
   - This determines if bulk updates needed in Sakura

**Timeline:** Week 1  
**Owner:** Ronin Team + Data Team  
**Priority:** CRITICAL (blocking)

---

#### 5.2 During Implementation Support

**Support Needed:**
1. **Data Validation**
   - Validate Sakura Entity hierarchy matches Ronin
   - Confirm market mappings are correct
   - Verify subcluster structure matches

**Timeline:** Week 2  
**Owner:** Ronin Team  
**Priority:** HIGH

---

2. **Issue Resolution**
   - Help resolve any data discrepancies
   - Clarify hierarchy questions
   - Provide additional data if needed

**Timeline:** Week 2-3  
**Owner:** Ronin Team  
**Priority:** MEDIUM

---

#### 5.3 Post-Implementation Support

**Support Needed:**
1. **Final Validation**
   - Confirm Sakura hierarchy matches Ronin
   - Verify reports connect correctly
   - Validate data consistency

**Timeline:** Week 4  
**Owner:** Ronin Team  
**Priority:** HIGH

---

### Support Required from Other Teams

#### 5.4 PowerBI Team Support

**Support Needed:**
1. **RLS Rule Updates** (if RLS in PowerBI)
   - Update RLS rules for new Central Europe cluster
   - Test data visibility
   - Validate report access

**Timeline:** Week 2-3  
**Owner:** PowerBI Team  
**Priority:** HIGH (if RLS exists)

---

2. **Report Testing**
   - Test reports with new cluster structure
   - Validate data visibility
   - Confirm no access issues

**Timeline:** Week 3-4  
**Owner:** PowerBI Team  
**Priority:** HIGH

---

#### 5.5 Business Approvers Support

**Support Needed:**
1. **Approver Mapping**
   - Confirm approver assignments for new cluster
   - Validate approver rules
   - Test approval workflow

**Timeline:** Week 2  
**Owner:** Business Approvers  
**Priority:** HIGH

---

2. **UAT Testing**
   - Test with real user accounts
   - Verify approval workflow
   - Sign off on UAT

**Timeline:** Week 3  
**Owner:** Business Approvers  
**Priority:** HIGH

---

#### 5.6 Data Team Support

**Support Needed:**
1. **Entity Code Strategy**
   - Confirm Entity code change strategy
   - Provide code mapping if codes change
   - Validate code changes

**Timeline:** Week 1  
**Owner:** Data Team  
**Priority:** CRITICAL (if codes change)

---

### Support Dependency Summary

| Support Type | Provider | Timeline | Priority | Blocking? |
|-------------|----------|----------|----------|-----------|
| Entity Hierarchy Data | Ronin (RCoE) | Week 1 | CRITICAL | YES |
| Cluster Validation | Ronin | Week 1 | CRITICAL | YES |
| Entity Code Strategy | Ronin + Data | Week 1 | CRITICAL | YES |
| Data Validation | Ronin | Week 2 | HIGH | NO |
| RLS Updates | PowerBI | Week 2-3 | HIGH | NO (if RLS exists) |
| Report Testing | PowerBI | Week 3-4 | HIGH | NO |
| Approver Mapping | Business | Week 2 | HIGH | NO |
| UAT Testing | Business | Week 3 | HIGH | NO |
| Issue Resolution | Ronin | Week 2-3 | MEDIUM | NO |

---

## Summary: Sakura Domain Response

### Impact Summary
- **Impact Level:** HIGH
- **Effort:** 50-100 hours
- **Timeline:** 3-4 weeks
- **Risk Level:** HIGH (mitigated with proper planning)

### Key Dependencies
1. **Ronin Team:** Entity hierarchy data (CRITICAL, blocking)
2. **Data Team:** Entity code strategy (CRITICAL, blocking)
3. **PowerBI Team:** RLS updates and testing (HIGH)
4. **Business Approvers:** Approver mapping and UAT (HIGH)

### Critical Success Factors
1. Early decision on Entity code strategy
2. Complete Entity hierarchy data from Ronin
3. Thorough testing in non-production
4. Clear communication to all stakeholders
5. Quick response plan for issues

### Next Steps
1. **Week 1:** Get Entity hierarchy data from Ronin, decide on code strategy
2. **Week 2:** Develop and test update scripts
3. **Week 3:** Execute in test, conduct UAT
4. **Week 4:** Deploy to production, monitor, support

---

**Document Owner:** Sakura Team  
**Last Updated:** 2025-01-XX  
**Status:** Ready for Stakeholder Review

---

**End of Document**

