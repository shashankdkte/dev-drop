# Sakura V2 — AMER (Americas) Domain Demo

This document explains how Sakura works **in the AMER (Americas) domain**, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md).

---

## Table of Contents

1. [AMER Domain at a Glance](#1-amer-domain-at-a-glance)
2. [Key Terms and Concepts (AMER)](#2-key-terms-and-concepts-amer)
3. [Security Types and Dimensions in AMER](#3-security-types-and-dimensions-in-amer)
4. [Who Can Create Permission Requests (AMER)](#4-who-can-create-permission-requests-amer)
5. [Approval Process (AMER)](#5-approval-process-amer)
6. [Rejection, Revocation, Cancellation (AMER)](#6-rejection-revocation-cancellation-amer)
7. [Practical Use Cases (AMER)](#7-practical-use-cases-amer)

---

## 1. AMER Domain at a Glance

| Item | AMER (Americas) |
|------|------------------|
| **WorkspaceCode** | AMER |
| **Purpose** | Americas regional reporting; org, client, CC, PC, PA, MSS |
| **Security Types** | **AMER-ORGA**, **AMER-CLIENT**, **AMER-CC**, **AMER-PC**, **AMER-PA**, **AMER-MSS** |
| **Key Dimensions** | Entity, SL, Client, CC, PC, PA, MSS |
| **RLS Detail Table** | `dbo.RLSPermissionAMERDetails` |
| **RLS Approver Table** | `dbo.RLSAMERApprovers` |
| **Share Views** | `ShareAMER.OLS`, `ShareAMER.RLS` |

---

## 2. Key Terms and Concepts (AMER)

- **Entity / Organisation level:** Global, Region, Cluster, Market, Entity, or N/A. Same hierarchy as other domains (e.g. **North America**, **LATAM** clusters).
- **Orga (AMER-ORGA):** Organisation + Service Line. Broad org/SL visibility.
- **Client (AMER-CLIENT):** Organisation + Client + Service Line. Client-centric Americas reporting.
- **CC (Cost Centre) (AMER-CC):** Organisation + Cost Centre + Service Line. **CC/PC are typically at Legal Entity level**; higher org may show warning or restrict. Use for cost-centre reporting.
- **PC (Profit Center) (AMER-PC):** Organisation + Client + **Profit Center** + Service Line. Includes All PCs, Specific Brand (BPCBrand), or Specific PC. Use for profit-center and brand-level Americas reporting.
- **PA (Practice Area) (AMER-PA):** Organisation + **People Aggregator** (Business Area or Business Function) + Service Line. Use for practice-area workforce/view.
- **MSS (AMER-MSS):** Organisation + MSS only. Use for MSS-level Americas view.

---

## 3. Security Types and Dimensions in AMER

| Security Type | Wizard Steps | Dimensions / RLS Detail |
|---------------|--------------|-------------------------|
| **Orga** | 1 → 2 → 7 | Entity level → Entity → Service Line |
| **PA** | 1 → 2 → 3 → 7 | Entity → Entity → People Aggregator → Service Line |
| **Client** | 1 → 2 → 4 → 7 | Entity → Entity → Client → Service Line |
| **CC** | 1 → 2 → 5 → 7 | Entity → Entity → Cost Centre → Service Line |
| **MSS** | 1 → 2 → 6 | Entity → Entity → MSS |
| **PC** | 1 → 2 → 4 → 8 → 7 | Entity → Entity → Client → Profit Center → Service Line |

**Note:** CC and PC are only at **Legal Entity** level; selecting org above Entity may show “CC/PC available at Legal Entity level only” and grey out or remove higher-level options.

---

## 4. Who Can Create Permission Requests (AMER)

- **Any authenticated user** can create an AMER permission request (Report Catalogue or Advanced → workspace **AMER**).
- **On-behalf-of:** Supported; LM from **RequestedFor**.
- **AMER-specific:** User picks **one** of the six security types; wizard shows the correct dimension steps. An **RLS approver** must exist for that type and dimension combination (in **RLSAMERApprovers** or via hierarchy); otherwise submission is blocked.

---

## 5. Approval Process (AMER)

- **LM:** From **RequestedFor**. Approve/Reject.
- **OLS Approver:** From AMER App/Audience or SAR report.
- **RLS Approver:** From **RLSAMERApprovers**; matched by **security type** and dimension values (Entity, SL, Client, CC, PC, PA, MSS as applicable), with **hierarchy traversal**. On approval, request **Approved**; row in **RLSPermissionAMERDetails** and **ShareAMER.RLS**.

---

## 6. Rejection, Revocation, Cancellation (AMER)

- **Rejection:** LM, OLS, or RLS approver rejects with reason → Rejected.
- **Revocation:** OLS/RLS approver or WSO revokes → Revoked; Managed OLS: user removed from Entra; row removed from **ShareAMER.RLS**.
- **Cancellation:** Requester cancels while pending → Cancelled.

---

## 7. Practical Use Cases (AMER)

### Use Case 1: Orga — North America and service line

- User selects **Orga**, **Cluster North America**, **SL Overall**. Full approval. User sees AMER org/SL data for North America; **ShareAMER.RLS** has Entity + SL.

### Use Case 2: Client — LATAM and specific client

- User selects **Client**, **Cluster LATAM**, **Specific Client 57**, **SL CRTV**. RLS approver for LATAM + client 57 + CRTV approves. User sees Americas client data for that combination.

### Use Case 3: PA — cluster and business function

- User selects **PA**, **Cluster LATAM**, **People Aggregator Finance (Business Functions)**, **SL CXM**. RLS approver for LATAM + Finance + CXM approves. User sees Americas practice-area data for Finance, CXM.

### Use Case 4: PC — cluster, client, brand, service line

- User selects **PC**, **Cluster North America**, **Client All Clients**, **Profit Center BR_MERKLE (BPCBrand)**, **SL CXM**. RLS approver for that entity/PC/SL approves. User sees Americas profit-center/brand data for Merkle, CXM.

### Use Case 5: CC — legal entity and cost centre

- User selects **CC**, **Entity** level, specific legal entity, **Cost Centre** (e.g. BPC Rollup 110), **SL CXM**. RLS approver for that entity/CC/SL approves. User sees Americas cost-centre data for that entity.

### Use Case 6: MSS — cluster and practice

- User selects **MSS**, **Cluster North America**, **MSS CREATIVE (L1)**. No Service Line step. RLS approver for North America + CREATIVE approves. User sees AMER MSS-level data.

### Use Case 7: On-behalf-of for Americas joiner

- Manager submits AMER request for new joiner: **Cluster North America**, **Orga**, **SL Overall**. New joiner’s LM and AMER OLS/RLS approvers approve. **RequestedFor** gets AMER access for North America, overall SL.

### Use Case 8: Revocation when brand responsibility changes

- User had **PC** access for brand BR_MERKLE; responsibility is reassigned. **RLS Approver** or **WSO** revokes with reason “Brand responsibility reassigned.” User loses that AMER data on next refresh.

---

*For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
