# Sakura V2 — DFI (Dentsu Finance Insights) Domain Demo

This document explains how Sakura works **in the DFI (Dentsu Finance Insights) domain** using the **FUM (Finance Unified Model)** security type, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md).

---

## Table of Contents

1. [DFI Domain at a Glance](#1-dfi-domain-at-a-glance)
2. [Key Terms and Concepts (DFI/FUM)](#2-key-terms-and-concepts-dfifum)
3. [Security Type and Dimensions in DFI](#3-security-type-and-dimensions-in-dfi)
4. [Who Can Create Permission Requests (DFI)](#4-who-can-create-permission-requests-dfi)
5. [Approval Process (DFI)](#5-approval-process-dfi)
6. [Rejection, Revocation, Cancellation (DFI)](#6-rejection-revocation-cancellation-dfi)
7. [Practical Use Cases (DFI)](#7-practical-use-cases-dfi)

---

## 1. DFI Domain at a Glance

| Item | DFI (Dentsu Finance Insights) |
|------|--------------------------------|
| **WorkspaceCode** | DFI |
| **Purpose** | Finance reporting; entity, country, client, MSS, profit center |
| **Security Types** | **FUM** (Finance Unified Model) |
| **Key Dimensions** | Entity, Country, Client, MSS, ProfitCenter |
| **RLS Detail Table** | `dbo.RLSPermissionFUMDetails` |
| **RLS Approver Table** | `dbo.RLSFUMApprovers` |
| **Share Views** | `ShareFUM.OLS`, `ShareFUM.RLS` |

*(Share schema may be ShareDFI depending on implementation; FUM is the security type name.)*

---

## 2. Key Terms and Concepts (DFI/FUM)

- **Entity / Organisation level:** Global, Region, Cluster, Market, Entity, or **N/A**. **N/A** triggers **Geo-based** flow where **Country** is required instead of Entity.
- **Country:** For **Geo** flow (Entity = N/A): user selects Global or specific country (e.g. DEU). For **Market** flow: Country can be optional (Global, specific, or N/A).
- **Client:** All Clients or Specific Client (Dentsu Stakeholder).
- **MSS (Master Service Set):** Overall, Practice (L1), or Specific (L0–L4).
- **ProfitCenter:** All PCs, Specific Brand (BPCBrand), or Specific PC. Used for profit-center-level finance visibility.

**Two bases:** **Market** (entity-based) and **Geo** (country-based). Access on a country can imply entity access for that geography; access on an entity does not automatically grant country-level access.

---

## 3. Security Type and Dimensions in DFI

| Security Type | Dimensions | RLS Detail Columns |
|---------------|------------|---------------------|
| **FUM** | Organisation (or N/A) → Entity or Country → Client → MSS → ProfitCenter | EntityKey/EntityHierarchy, CountryKey/CountryHierarchy, ClientKey/ClientHierarchy, MSSKey/MSSHierarchy, ProfitCenterKey/ProfitCenterHierarchy |

**Examples:** Market flow: Cluster DACH, Country N/A, Client 57, MSS CREATIVE (L1), All PCs. Geo flow: Entity N/A, Country DEU, All Clients, Overall MSS, All PCs.

---

## 4. Who Can Create Permission Requests (DFI)

- **Any authenticated user** can create a DFI permission request (Report Catalogue or Advanced → workspace **DFI**).
- **On-behalf-of:** Supported; LM from **RequestedFor**.
- **DFI-specific:** **RLS approver** must exist for the chosen FUM dimension combination (or hierarchy parent) in **RLSFUMApprovers**; otherwise submission is blocked.

---

## 5. Approval Process (DFI)

- **LM:** From **RequestedFor**. Approve/Reject.
- **OLS Approver:** From DFI App/Audience or SAR report.
- **RLS Approver:** From **RLSFUMApprovers** (Entity/Country + Client + MSS + ProfitCenter, with hierarchy traversal). On approval, request **Approved**; row in **RLSPermissionFUMDetails** and **ShareFUM.RLS** (or ShareDFI.RLS).

---

## 6. Rejection, Revocation, Cancellation (DFI)

- **Rejection:** LM, OLS, or RLS approver rejects with reason → Rejected.
- **Revocation:** OLS/RLS approver or WSO revokes → Revoked; Managed OLS: user removed from Entra; row removed from Share RLS.
- **Cancellation:** Requester cancels while pending → Cancelled.

---

## 7. Practical Use Cases (DFI)

### Use Case 1: Finance analyst — cluster, client, practice, all PCs

- User requests DFI report, **Market flow:** **Cluster DACH**, Country N/A, **Client 57**, **MSS Practice CREATIVE**, **All PCs**. Full approval. User sees finance data for DACH, client 57, CREATIVE practice, all profit centers; **ShareFUM.RLS** has that dimension set.

### Use Case 2: Geo-based country access

- User requests **Geo flow:** Entity level **N/A**, **Country DEU**, All Clients, Overall MSS, All PCs. RLS approver for country DEU approves. User sees German finance data (country-based), not entity-based.

### Use Case 3: Most granular — entity, client, practice, specific PC

- User requests **Entity** level, specific entity, **Specific Client 224555**, **MSS Practice CREATIVE**, **Specific PC**. Approvers for that entity/client/MSS/PC approve. User sees only that narrow slice in DFI reports.

### Use Case 4: On-behalf-of for new finance joiner

- Manager submits DFI for new joiner: **Cluster DACH**, All Clients, **Overall** MSS, **All PCs**. New joiner’s LM and DFI OLS/RLS approvers approve. **RequestedFor** gets DFI access for DACH, all clients, all MSS, all PCs.

### Use Case 5: Revocation when profit center responsibility changes

- User had FUM access for a specific brand/PC; responsibility is reassigned. **RLS Approver** or **WSO** revokes with reason “PC responsibility reassigned.” User loses that finance data on next refresh.

---

*For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
