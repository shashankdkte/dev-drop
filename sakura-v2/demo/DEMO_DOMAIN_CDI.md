# Sakura V2 — CDI (Client Data Insights) Domain Demo

This document explains how Sakura works **in the CDI (Client Data Insights) domain**, with domain-specific terms, use cases, and permission/approval flows.

**Prerequisite:** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md).

---

## Table of Contents

1. [CDI Domain at a Glance](#1-cdi-domain-at-a-glance)
2. [Key Terms and Concepts (CDI)](#2-key-terms-and-concepts-cdi)
3. [Security Type and Dimensions in CDI](#3-security-type-and-dimensions-in-cdi)
4. [Who Can Create Permission Requests (CDI)](#4-who-can-create-permission-requests-cdi)
5. [Approval Process (CDI)](#5-approval-process-cdi)
6. [Rejection, Revocation, Cancellation (CDI)](#6-rejection-revocation-cancellation-cdi)
7. [Practical Use Cases (CDI)](#7-practical-use-cases-cdi)

---

## 1. CDI Domain at a Glance

| Item | CDI (Client Data Insights) |
|------|-----------------------------|
| **WorkspaceCode** | CDI |
| **Purpose** | Client-centric reporting and analytics |
| **Security Types** | **CDI** (single type: Entity + Client + SL) |
| **Key Dimensions** | Entity, Client, SL (Service Line) |
| **RLS Detail Table** | `dbo.RLSPermissionCDIDetails` |
| **RLS Approver Table** | `dbo.RLSCDIApprovers` |
| **Share Views** | `ShareCDI.OLS`, `ShareCDI.RLS` |

---

## 2. Key Terms and Concepts (CDI)

- **Entity / Organisation level:** Same hierarchy as GI (Global, Region, Cluster, Market, Entity). **Global** = all entities; otherwise user selects a specific entity level (e.g. Cluster DACH).
- **Client:** **All Clients** or **Specific Client** (Dentsu Stakeholder). CDI is client-centric; RLS often restricts by client portfolio.
- **SL (Service Line):** P&L service unit (e.g. Media, Creative, CXM). **TOTALPA** or “Overall” = all service lines in scope.

CDI does **not** use MSS in its core security type; dimensions are Organisation → Entity (if not Global) → Client → Service Line.

---

## 3. Security Type and Dimensions in CDI

| Security Type | Dimensions | RLS Detail Columns |
|---------------|------------|---------------------|
| **CDI** | Organisation level → Entity (if not Global) → Client → Service Line | EntityKey/EntityHierarchy, ClientKey/ClientHierarchy, SLKey/SLHierarchy |

**Examples:** Entity = DACH (Cluster), Client = All Clients or specific client 57, SL = TOTALPA or CRTV.

---

## 4. Who Can Create Permission Requests (CDI)

- **Any authenticated user** can create a CDI permission request (Report Catalogue or Advanced → workspace **CDI**).
- **On-behalf-of:** Allowed; **RequestedFor** user’s LM is used for the first approval step.
- **CDI-specific:** An **RLS approver** must exist for the chosen dimension combination (in **RLSCDIApprovers** or via hierarchy traversal); otherwise the wizard cannot submit.

---

## 5. Approval Process (CDI)

- **LM:** Resolved from **RequestedFor** (ref.Employees). Approve/Reject → next step or Rejected.
- **OLS Approver:** From CDI App (AppBased) or Audience (AudienceBased), or from the report (SAR). Approve/Reject.
- **RLS Approver:** From **RLSCDIApprovers** by Entity + Client + SL (and hierarchy traversal). Approve/Reject. On approval, request is **Approved**; row written to **RLSPermissionCDIDetails** and exposed in **ShareCDI.RLS**.

---

## 6. Rejection, Revocation, Cancellation (CDI)

- **Rejection:** LM, OLS, or RLS approver rejects with mandatory reason → RequestStatus = Rejected; no CDI access.
- **Revocation:** OLS/RLS approver or WSO revokes with reason → header Revoked; for Managed OLS user is removed from Entra group; row drops from **ShareCDI.RLS**.
- **Cancellation:** Requester cancels only while Pending LM/OLS/RLS → RequestStatus = Cancelled.

---

## 7. Practical Use Cases (CDI)

### Use Case 1: Client lead — specific client and entity

- User requests CDI report/audience, dimensions: **Cluster DACH**, **Specific Client 57**, **SL TOTALPA**. LM → OLS → RLS approver (for DACH + client 57) approve. User sees only client 57 data within DACH in CDI reports; **ShareCDI.RLS** has one row with that Entity/Client/SL.

### Use Case 2: Global client view (minimal RLS)

- User requests **Global**, **All Clients**, **TOTALPA**. Approvers for global scope approve. User sees all clients and all service lines in CDI (broad access).

### Use Case 3: On-behalf-of for new account manager

- Manager submits CDI request for new joiner with **Market UK**, **Specific Client 99**, **SL CRTV**. LM is new joiner’s manager; after full approval, **RequestedFor** (new joiner) gets access; **ShareCDI.RLS** shows that user with UK, client 99, CRTV.

### Use Case 4: RLS approver rejects — wrong client

- User requests client 57; RLS approver rejects: “You are not authorised for client 57; request client 99.” Requester creates a **new** request with client 99.

### Use Case 5: Revocation when client responsibility changes

- User had CDI access for client 57. They hand over the client; **RLS Approver** or **WSO** revokes with reason “Client reassigned.” User loses that data in CDI on next Power BI refresh.

---

*For shared concepts and other domains, see [DEMO_INDEX.md](DEMO_INDEX.md). Last updated: March 2026.*
