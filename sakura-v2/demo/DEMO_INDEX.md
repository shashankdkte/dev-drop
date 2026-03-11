# Sakura V2 — Demo Documentation Index

This folder contains **domain-specific demo documentation** for the Sakura V2 application. Each document explains key terms, end-to-end flows, security model, and permission/approval workflows with **practical use cases** for that domain.

---

## Document Map

| Document | Domain | Description |
|----------|--------|-------------|
| [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md) | All | Cross-cutting concepts: Apps, Audiences, Reports, Security Model, Security Types, Mapping, Dimensions, Share OLS/RLS, Power BI consumption, Managed vs Unmanaged OLS, who can create requests, approval flow (LM → OLS → RLS), Rejection, Revocation, Cancellation |
| [DEMO_DOMAIN_GI.md](DEMO_DOMAIN_GI.md) | **GI** (Growth Insights) | Entity + Client + MSS + SL dimensions; MSS and SL/PA security types; GI-specific use cases and approval examples |
| [DEMO_DOMAIN_CDI.md](DEMO_DOMAIN_CDI.md) | **CDI** (Client Data Insights) | Entity + Client + SL dimensions; CDI security type; client-centric use cases |
| [DEMO_DOMAIN_WFI.md](DEMO_DOMAIN_WFI.md) | **WFI** (Workforce Insights) | Entity + PA (People Aggregator) dimensions; workforce use cases |
| [DEMO_DOMAIN_DFI.md](DEMO_DOMAIN_DFI.md) | **DFI** (Dentsu Finance Insights) | FUM security type: Entity + Country + Client + MSS + ProfitCenter; finance use cases |
| [DEMO_DOMAIN_EMEA.md](DEMO_DOMAIN_EMEA.md) | **EMEA** | Five security types: ORGA, CLIENT, CC, COUNTRY, MSS; EMEA-specific flows |
| [DEMO_DOMAIN_AMER.md](DEMO_DOMAIN_AMER.md) | **AMER** (Americas) | Six security types: ORGA, CLIENT, CC, PC, PA, MSS; Americas-specific flows |

---

## How to Use These Documents

1. **Start with** [DEMO_00_SHARED_CONCEPTS.md](DEMO_00_SHARED_CONCEPTS.md) for a complete picture of how Sakura works, how security flows, and how Power BI consumes it.
2. **Then open** the domain document relevant to your audience (e.g. GI for Growth Insights teams, CDI for Client Data teams).
3. Each domain doc includes:
   - Domain-specific key terms and dimensions
   - How components interact in that domain
   - Who can create permission requests (and how)
   - Approval process (Line Manager → OLS Approver → RLS Approver)
   - Rejection, Revocation, Cancellation — with domain examples
   - Practical use cases and demo scenarios

---

## Quick Reference — Domains and Security Types

| Domain | Security Types | Key Dimensions |
|--------|----------------|----------------|
| GI | MSS, SL/PA | Entity, Client, MSS, SL |
| CDI | CDI | Entity, Client, SL |
| WFI | WFI (PA) | Entity, PA |
| DFI | FUM | Entity, Country, Client, MSS, ProfitCenter |
| EMEA | ORGA, CLIENT, CC, COUNTRY, MSS | Entity, SL, Client, CC, Country, MSS |
| AMER | ORGA, CLIENT, CC, PC, PA, MSS | Entity, SL, Client, CC, PC, PA, MSS |

---

*Part of Sakura V2 demo documentation. Last updated: March 2026.*
