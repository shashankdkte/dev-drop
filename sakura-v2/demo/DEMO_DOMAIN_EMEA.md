# Sakura V2 — EMEA Domain Demo

This document explains how Sakura works **in the EMEA (Europe, Middle East & Africa) domain**, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md).

---

## Table of Contents

1. [EMEA Domain at a Glance](#1-emea-domain-at-a-glance)
2. [Key Terms and Concepts (EMEA)](#2-key-terms-and-concepts-emea)
3. [Security Types and Dimensions in EMEA](#3-security-types-and-dimensions-in-emea)
4. [Who Can Create Permission Requests (EMEA)](#4-who-can-create-permission-requests-emea)
5. [Approval Process (EMEA)](#5-approval-process-emea)
6. [Rejection, Revocation, Cancellation (EMEA)](#6-rejection-revocation-cancellation-emea)
7. [Practical Use Cases (EMEA)](#7-practical-use-cases-emea)

---

## 1. EMEA Domain at a Glance

| Item | EMEA (Europe, Middle East & Africa) |
|------|-------------------------------------|
| **WorkspaceCode** | EMEA |
| **Purpose** | Regional reporting for EMEA; org, client, cost centre, country, MSS |
| **Security Types** | **EMEA-ORGA** (Orga-SL/PA), **EMEA-CLIENT**, **EMEA-CC**, **EMEA-COUNTRY**, **EMEA-MSS** |
| **Key Dimensions** | Entity, SL, Client, CC, Country, MSS |
| **RLS Detail Table** | `dbo.RLSPermissionEMEADetails` |
| **RLS Approver Table** | `dbo.RLSEMEAApprovers` |
| **Share Views** | `ShareEMEA.OLS`, `ShareEMEA.RLS` |

---

## 2. Key Terms and Concepts (EMEA)

- **Entity / Organisation level:** Global, Region, Cluster, Market, Entity, or **N/A**. **N/A** is used for **Country-based (Geo)** access where no entity is selected.
- **Orga-SL/PA (EMEA-ORGA):** Organisation + Service Line. No Client, CC, Country, or MSS. Use for broad org/service-line visibility.
- **Client (EMEA-CLIENT):** Organisation + Client + Service Line. Use for client-centric EMEA reporting.
- **CC (Cost Centre) (EMEA-CC):** Organisation + Cost Centre + Service Line. **CC is typically at Legal Entity level**; picking org above Entity may show a warning or restrict options. Use for cost-centre-level finance/ops.
- **Country (EMEA-COUNTRY):** Organisation (often N/A) + Country + Service Line. **Geo-based**; Entity and Country are mutually exclusive in the flow. Use for country-based EMEA reporting.
- **Orga-MSS (EMEA-MSS):** Organisation + MSS only (no Service Line step). Use for MSS-level EMEA view.

---

## 3. Security Types and Dimensions in EMEA

| Security Type | Wizard Steps | Dimensions / RLS Detail |
|---------------|--------------|-------------------------|
| **Orga-SL/PA** | 1 → 2 → 7 | Entity level → Entity (if not Global/N/A) → Service Line |
| **Client** | 1 → 2 → 4 → 7 | Entity → Entity → Client → Service Line |
| **CC** | 1 → 2 → 5 → 7 | Entity → Entity → Cost Centre → Service Line |
| **Country** | 1 → 2 → 3 → 7 (or 1 → 3 → 7 if N/A) | Entity (or N/A) → Country → Service Line |
| **Orga-MSS** | 1 → 2 → 6 | Entity → Entity → MSS |

**Note:** CC and PC (in AMER) are typically valid only at **Legal Entity** level; higher org levels may grey out or restrict these options.

---

## 4. Who Can Create Permission Requests (EMEA)

- **Any authenticated user** can create an EMEA permission request (Report Catalogue or Advanced → workspace **EMEA**).
- **On-behalf-of:** Supported; LM from **RequestedFor**.
- **EMEA-specific:** User must pick **one** of the five security types; the wizard then shows the correct dimension steps. An **RLS approver** must exist for the chosen type and dimension combination (in **RLSEMEAApprovers** or via hierarchy); otherwise submission is blocked.

---

## 5. Approval Process (EMEA)

- **LM:** From **RequestedFor**. Approve/Reject.
- **OLS Approver:** From EMEA App/Audience or SAR report.
- **RLS Approver:** From **RLSEMEAApprovers**; matched by **security type** and dimension values (Entity, SL, Client, CC, Country, or MSS as applicable), with **hierarchy traversal**. On approval, request **Approved**; row in **RLSPermissionEMEADetails** and **ShareEMEA.RLS**.

---

## 6. Rejection, Revocation, Cancellation (EMEA)

- **Rejection:** LM, OLS, or RLS approver rejects with reason → Rejected.
- **Revocation:** OLS/RLS approver or WSO revokes → Revoked; Managed OLS: user removed from Entra; row removed from **ShareEMEA.RLS**.
- **Cancellation:** Requester cancels while pending → Cancelled.

---

## 7. Practical Use Cases (EMEA)

### Use Case 1: Orga-SL/PA — cluster and service line

- User selects **Orga-SL/PA**, **Cluster DACH**, **Service Line Overall**. Full approval. User sees EMEA org/service-line data for DACH; **ShareEMEA.RLS** has Entity + SL dimensions.

### Use Case 2: Client — DACH and specific client

- User selects **Client**, **Cluster DACH**, **Specific Client 57**, **SL CRTV**. RLS approver for DACH + client 57 + CRTV approves. User sees EMEA client data for that combination only.

### Use Case 3: CC — legal entity and cost centre

- User selects **CC**, **Entity** level, specific legal entity (e.g. PT01), **Cost Centre** (e.g. BPC Rollup 110), **SL CXM**. RLS approver for that entity/CC/SL approves. User sees EMEA cost-centre data for that entity.

### Use Case 4: Country — geo-based access

- User selects **Country**, Entity level **N/A**, **Country DEU**, **SL CXM**. RLS approver for country DEU approves. User sees EMEA data by geography (Germany), not by entity hierarchy.

### Use Case 5: Orga-MSS — cluster and practice

- User selects **Orga-MSS**, **Cluster DACH**, **MSS CREATIVE (L1)**. No Service Line step. RLS approver for DACH + CREATIVE approves. User sees EMEA MSS-level data for DACH, CREATIVE.

### Use Case 6: Rejection and resubmission

- User requests **Client** type, **Cluster DACH**, **Client 57**, **SL CRTV**. RLS approver rejects: “Not authorised for client 57 in DACH.” Requester creates a **new** request with correct client or scope.

### Use Case 7: Revocation when region changes

- User had EMEA access for **Country DEU**. They move to Americas. **WSO** or **RLS Approver** revokes with reason “Region change.” User loses EMEA DEU data on next refresh.

---

*For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
