# Sakura V2 — Solution Security Classification (SSC)

**Framework:** SCF-GRP-001-EN v1.5 — Solution Security Classification Framework  
**Source PDF:** `Docs/network-architecture/scf-grp-001-en-solution-security-classification-framework-v1-5_20250922123447353.pdf`  
**Evidence:** Azure portal tags in `Docs/SAKURA_VA_HOST_INVENTORY.md` (2026-09-11)  
**Status:** Draft for Solution Owner confirmation  

---

## 1. Verdict (recommended)

| Item | Value |
|------|--------|
| **Solution** | Sakura V2 (access management — OLS / RLS request & approval) |
| **Information classification (most important data)** | **Confidential** |
| **Service Transition Tier** | **Tier 2** (Operational) |
| **Solution Security Classification (SSC)** | **Gold** |
| **How derived** | SCF matrix: Confidential × Tier 2 → **Gold** |
| **Aligns to** | Prod API + Prod Key Vault portal tags |

Record **Gold** with design / implementation artefacts and in CMDB (SCF §5.3).  
Solution Owner confirms; Data Owner / IT may support (SCF §6).

---

## 2. How SCF works (reminder)

1. Pick **Information Classification** from the most important data in the solution → Public / Private / Confidential / Secret  
2. Pick **Service Transition Tier** → Tier 0 (highest) … Tier 3 (lowest)  
3. Look up the intersection → Bronze / Silver / Gold / Platinum  

| Tier ↓ / Data → | Public | Private | Confidential | Secret |
|-----------------|--------|---------|--------------|--------|
| **Tier 0** | Silver | Gold | Platinum | Platinum |
| **Tier 1** | Silver | Gold | Gold | Platinum |
| **Tier 2** | Bronze | Silver | **Gold** | Platinum |
| **Tier 3** | Bronze | Bronze | Silver | Gold |

---

## 3. Tag → SCF mapping used here

Azure resource tags do not use the exact SCF labels. This worksheet uses:

| Azure tag | Mapped to SCF |
|-----------|----------------|
| `DataClassification = Confidential` | **Confidential** |
| `DataClassification = Internal` | **Private** (closest SCF column; not Public, not Confidential) |
| `Criticality = Tier2-Operational` | **Tier 2** |
| `Criticality = Tier3-Non-Critical` | **Tier 3** |

If Security / Data Owner maps `Internal` differently, recalculate the SSC.

---

## 4. Why Confidential + Tier 2 for Sakura V2

| Input | Rationale |
|-------|-----------|
| **Confidential** | Solution governs **who gets OLS/RLS access** to BI / Fabric reporting. Prod API and Prod Key Vault are already tagged **Confidential**. Access decisions, identities, and group memberships are business-sensitive even when resource `PII` tag is `No` (Prod KV). |
| **Tier 2** | Prod API and Prod KV tagged **Tier2-Operational**. UAT API same. Failure impacts operational access workflows, not Tier 0/1 enterprise-critical platforms. |

**Matrix result:** Confidential + Tier 2 → **Gold**.

---

## 5. Per-environment check (from portal tags)

Resource tags vary by env. SSC for the **solution** should follow the **highest** data sensitivity that the solution handles (Prod), not the softest NonProd label.

| Env | Resource | `DataClassification` | `Criticality` | Mapped SCF axes | Implied SSC (if classified alone) |
|-----|----------|----------------------|---------------|-----------------|-----------------------------------|
| Dev | API `azeuw1dweb01sakura` | Internal | Tier3-Non-Critical | Private × Tier 3 | **Bronze** |
| Dev | SQL `azeuw1senmastersvrdb01` | Internal | Tier3-Non-Critical | Private × Tier 3 | **Bronze** |
| UAT | API `azeuw1tweb01sakura` | Confidential | Tier2-Operational | Confidential × Tier 2 | **Gold** |
| UAT | SQL `azeuw1tsenmastersvrdb01` | Internal | Tier2-Operational | Private × Tier 2 | **Silver** |
| Prod | API `azeuw1pweb01sakura` | Confidential | Tier2-Operational | Confidential × Tier 2 | **Gold** |
| Prod | KV `azeuw1pkvsakura` | Confidential | Tier2-Operational | Confidential × Tier 2 | **Gold** |
| Prod | SQL `azeuw1psenmastersvrdb01` | **TBD** | **TBD** | — | Confirm portal JSON |

**Solution-level SSC to record:** **Gold** (driven by Prod Confidential + Tier 2).

### Tag consistency to fix

1. **Dev** is Internal / Tier3 while **UAT/Prod API** are Confidential / Tier2 — expected for NonProd softening, or update Dev if NonProd holds prod-like access data.  
2. **UAT SQL** still Internal while **UAT API** is Confidential — Data Owner should align SQL tag with the data actually stored in `SakuraV2`.  
3. **Prod SQL** tags still missing — should match Prod Confidential / Tier2 if it holds the same access data.

---

## 6. Ownership (SCF §6)

| Role | Who (from inventory) | Responsibility |
|------|----------------------|----------------|
| **Solution Owner** | Confirm (candidates: `Toniann.Tuson@dentsu.com` Prod API/KV Owner; Finance contact `Ebad.Uddin@dentsu.com`) | **Define and own** SSC = Gold |
| **Data Owner** | Confirm with BI / Fabric data owners | Support data classification (Confidential) |
| **IT / Cloud** | Platform + app teams | Implement controls required for **Gold**; keep tags / CMDB in sync |

Exceptions to baseline Gold controls → security risk management process (regional / practice security director) — SCF §4.

---

## 7. What Gold means for Sakura V2 (practical)

SSC itself does not list every control; it selects the control depth in other dentsu standards. For Sakura V2 Gold, treat these as in-scope control themes (already flagged in VA inventory):

| Theme | Current V2 note |
|-------|-----------------|
| Network exposure | Public APIs (Dev/UAT/Prod); FE private via PE; Dev/UAT SQL `publicNetworkAccess=Enabled`; Prod KV ACL default Allow |
| Identity | Entra app Sakura + JWT; CA / assignment hardening (see network-architecture Entra page) |
| Secrets | Prod KV Confidential — network restriction + RBAC still under review |
| Host / VA | Defender + Wiz on PaaS + Windows automation VM `AZEUW1PRONM01` |
| Review | Re-run SSC if data class or criticality tags change (SCF §5.4) |

---

## 8. Copy/paste for Solution Owner / InfoSec

> Per **SCF-GRP-001-EN v1.5**, Sakura V2 Solution Security Classification is proposed as **Gold**.  
> Inputs: Information Classification **Confidential** (most important data = access / OLS-RLS governance; matches Prod API + Prod Key Vault tags) × Service Transition Tier **Tier 2** (Operational; matches Prod Criticality tags).  
> Matrix intersection: Confidential × Tier 2 → **Gold**.  
> Please confirm as Solution Owner and record in CMDB / design artefacts. Prod SQL portal tags still pending alignment.

---

## Related

- `Docs/SAKURA_VA_HOST_INVENTORY.md`
- `Docs/SAKURA_VA_HOST_LIST_SHORT.md`
- `Docs/network-architecture/` (current / recommended network options)
- SCF PDF: `Docs/network-architecture/scf-grp-001-en-solution-security-classification-framework-v1-5_20250922123447353.pdf`
