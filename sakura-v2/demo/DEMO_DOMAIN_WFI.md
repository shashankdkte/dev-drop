# Sakura V2 — WFI (Workforce Insights) Domain Demo

This document explains how Sakura works **in the WFI (Workforce Insights) domain**, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md).

---

## Table of Contents

1. [WFI Domain at a Glance](#1-wfi-domain-at-a-glance)
2. [Key Terms and Concepts (WFI)](#2-key-terms-and-concepts-wfi)
3. [Security Type and Dimensions in WFI](#3-security-type-and-dimensions-in-wfi)
4. [Who Can Create Permission Requests (WFI)](#4-who-can-create-permission-requests-wfi)
5. [Approval Process (WFI)](#5-approval-process-wfi)
6. [Rejection, Revocation, Cancellation (WFI)](#6-rejection-revocation-cancellation-wfi)
7. [Practical Use Cases (WFI)](#7-practical-use-cases-wfi)

---

## 1. WFI Domain at a Glance

| Item | WFI (Workforce Insights) |
|------|---------------------------|
| **WorkspaceCode** | WFI |
| **Purpose** | Workforce and headcount reporting; HR/people analytics |
| **Security Types** | **WFI** (People Aggregator / PA) |
| **Key Dimensions** | Entity, PA (People Aggregator) |
| **RLS Detail Table** | `dbo.RLSPermissionWFIDetails` |
| **RLS Approver Table** | `dbo.RLSWFIApprovers` |
| **Share Views** | `ShareWFI.OLS`, `ShareWFI.RLS` |

---

## 2. Key Terms and Concepts (WFI)

- **Entity / Organisation level:** Same hierarchy as other domains (Global, Region, Cluster, Market, Entity). **Global** = all entities; otherwise user selects e.g. Cluster DACH or Market UK.
- **PA (People Aggregator):** Workforce dimension grouping employees (e.g. by function or business area). Options typically include:
  - **Overall** — all PAs in scope
  - **Business Areas** — e.g. CXM, Technology
  - **Business Functions** — e.g. Finance, HR, Delivery Management

WFI has **no** Client or MSS in its core security type; only **Entity** and **PA**. The wizard is short: Organisation → Entity (if not Global) → People Aggregator.

---

## 3. Security Type and Dimensions in WFI

| Security Type | Dimensions | RLS Detail Columns |
|---------------|------------|---------------------|
| **WFI** | Organisation level → Entity (if not Global) → People Aggregator | EntityKey/EntityHierarchy, PAKey/PAHierarchy |

**Examples:** Entity = DACH, PA = Overall; or Entity = UK, PA = Finance (Business Functions).

---

## 4. Who Can Create Permission Requests (WFI)

- **Any authenticated user** can create a WFI permission request (Report Catalogue or Advanced → workspace **WFI**).
- **On-behalf-of:** Supported; LM is resolved for **RequestedFor**.
- **WFI-specific:** **RLS approver** must exist for the chosen Entity + PA combination (or parent in hierarchy) in **RLSWFIApprovers**; otherwise submission is blocked.

---

## 5. Approval Process (WFI)

- **LM:** From **RequestedFor**. Approve/Reject.
- **OLS Approver:** From WFI App/Audience or SAR report.
- **RLS Approver:** From **RLSWFIApprovers** (Entity + PA, with hierarchy traversal). On approval, request **Approved**; row in **RLSPermissionWFIDetails** and **ShareWFI.RLS**.

---

## 6. Rejection, Revocation, Cancellation (WFI)

- **Rejection:** Any approver rejects with reason → Rejected; no WFI access.
- **Revocation:** OLS/RLS approver or WSO revokes → Revoked; user removed from Entra (Managed); row removed from **ShareWFI.RLS**.
- **Cancellation:** Requester cancels while pending → Cancelled.

---

## 7. Practical Use Cases (WFI)

### Use Case 1: HR analyst — cluster and business function

- User requests WFI report, dimensions: **Cluster DACH**, **PA = Finance (Business Functions)**. Full approval chain. User sees workforce data for DACH, Finance function only; **ShareWFI.RLS** has EntityKey/PAKey for DACH and Finance.

### Use Case 2: Global workforce view

- User requests **Global**, **PA = Overall**. Approvers for global scope approve. User sees all workforce data across entities and PAs.

### Use Case 3: Market-level HR lead

- User requests **Market UK**, **PA = Delivery Management (Business Functions)**. RLS approver for UK + that PA approves. User sees UK delivery workforce only.

### Use Case 4: On-behalf-of for new HR joiner

- HR manager submits WFI request for new joiner: **Cluster DACH**, **PA = Overall**. New joiner’s LM approves; then OLS and RLS approvers. **RequestedFor** (new joiner) gets WFI access for DACH overall.

### Use Case 5: Revocation when role changes

- User moved from HR to Finance; no longer needs WFI. **RLS Approver** or **WSO** revokes with reason “Role change.” User loses WFI data access on next refresh.

---

*For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
