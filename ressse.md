# Sakura V2 — Vulnerability Assessment Host Inventory

**Purpose:** Host / cloud asset list for Microsoft Defender and Wiz coverage validation.  
**Application:** Sakura V2 (access management — OLS / RLS request & approval)  
**Cloud provider:** Azure only (no AWS / GCP)  
**Asset type:** Azure PaaS **+ Windows VMs** (email dispatcher / nightly AD sync)  
**Last updated:** 2026-09-11  
**Evidence:** Azure Portal JSON — SQL Dev/UAT; App Service Dev/UAT/Prod; Prod Key Vault; VM docs (`Complete_Setup_and_Access_Guide`, `Sakura_Email_System_Complete_Explanation`, `ARCHITECTURE.md`)

---

## 1. How to read this list

| Field | Notes |
|-------|--------|
| **Hostname** | Azure resource name |
| **FQDN** | Public or service DNS name |
| **IP address(es)** | Private Endpoint IP where known; App Service / SQL public IPs via portal if needed |
| **OS and version** | PaaS — Microsoft-managed host; runtime shown where known (.NET 8, Angular 20, Azure SQL v12) |
| **Asset Owner** | From Azure resource `Owner` tag where confirmed |

**Subscriptions**

| Env | Subscription name (where known) | Subscription ID |
|-----|----------------------------------|-----------------|
| Dev / UAT (NonProd) | `VDC000006-EMEA-UK207-DenstuAegisTecUk-NetNewNonProd` | `7a659c18-04dd-412f-9cff-4b2d4e41e937` |
| Production | (VDC000007 Prod) | `15039875-d735-4154-b944-f25aa3db1327` |

**Entra (identity context — not a host)**

| Item | Value |
|------|--------|
| Tenant ID | `6e8992ec-76d5-4ea5-8eae-b0c5e558749a` |
| App display name | Sakura |
| Application (client) ID | `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` |
| Service principal object ID | `faeacbe2-e6f7-453d-81b4-c0f1d691b565` |

---

## 1A. Windows VMs — emails + nightly scripts

| Hostname | FQDN | IP address(es) | Environment | Application / Service | Asset Owner | OS / Runtime | Cloud | Subscription ID | Resource Group | VM / Instance / Resource ID |
|----------|------|----------------|-------------|------------------------|-------------|--------------|-------|-----------------|----------------|-----------------------------|
| **`AZEUW1PRONM01`** | `AZEUW1PRONM01.emea.media.global.loc` | Confirm in portal | **Production** | GAPTEQ IIS portal · **EmailDispatcher** (~5 min) · **SakuraADSync.ps1** nightly (~20:31) | Confirm portal tags | **Windows Server 2019** (NT 10.0.17763) | Azure | Confirm (Prod / EMEA) | Confirm in portal | `AZEUW1PRONM01` · script `C:\Installations\SakuraADSyncer\SakuraADSync.ps1` |
| `AZEUW1DSENM01` | `azeuw1dsenm01` / corp FQDN | Confirm | Development | Sensei Dev node; V1 portal URL `https://azeuw1dsenm01/GAPTEQForms/Sakura/` | Confirm | Windows Server (confirm) | Azure | Likely NonProd `7a659c18-…` | Confirm | `AZEUW1DSENM01` |
| `AZEUW1DSENM02` | Confirm | Private **`10.19.54.140`** (no public IP) | Development | Sensei Dev node in `AZ-VDC000006-EUW1-NET-CORE` | Confirm | Windows Server (confirm) | Azure | `7a659c18-…` | Confirm | `AZEUW1DSENM02` |
| `AZEUW1TRONM01` | Confirm | Confirm | Test / Dev | Ronin MDM test node (same NET-CORE VNet) | Confirm | Windows Server (confirm) | Azure | `7a659c18-…` | Confirm | `AZEUW1TRONM01` |
| `AZEUW1GTTESTM01` | Confirm | Public **`51.124.122.213`** | Development (old VNet) | Test VM on SENSEI-DEV-vnet | Confirm | Windows Server (confirm) | Azure | Confirm | Confirm | `AZEUW1GTTESTM01` |

**SMTP (not a Sakura VM — network dependency for email):** `internalsmtprelay.media.global.loc:25`

**Jobs on `AZEUW1PRONM01`**

| Job | Schedule | Purpose |
|-----|----------|---------|
| `Sakura.Toolbox.EmailDispatcher.exe` | ~every 5 min (Task Scheduler) | Send queued user notification emails |
| `SakuraADSync.ps1` | Daily ~20:31 (Task Scheduler) | Nightly Entra group sync + admin email |
| GAPTEQ / IIS | Always on | V1 Sakura portal |

**V2:** `SakuraV2ADSync.ps1` / `SakuraV2EmailDispatcher` are Task Scheduler–ready; confirm whether they already run on `AZEUW1PRONM01` or another host.

---

## 2. Core hosts in scope (Frontend / API / SQL)

### 2.1 Development

| Hostname | FQDN | IP address(es) | Environment | Application / Service | Asset Owner | OS / Runtime | Cloud | Subscription ID | Resource Group | VM / Instance / Resource ID |
|----------|------|----------------|-------------|------------------------|-------------|--------------|-------|-----------------|----------------|-----------------------------|
| `azeuw1dswasakura` | `orange-sand-03a59b103.3.azurestaticapps.net` | Private Endpoint `10.19.54.134` | Development | Sakura Frontend (Static Web App) | `Ebad.Uddin@dentsu.com` (PE tag pattern) | PaaS — Angular 20 SPA; Microsoft-managed | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | `azeuw1dswasakura` · PE `azeuw1dswasakura_privateendpoint` |
| `azeuw1dweb01sakura` | `azeuw1dweb01sakura.azurewebsites.net` | Inbound **`20.105.232.38`**, **`20.105.224.52`** (public; no PE) | Development | Sakura Backend API (App Service Linux, Basic) | **`Ebad.Uddin@dentsu.com`** | **Linux** App Service — `DOTNETCORE\|8.0`; platform `109.0.7.36` | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | `azeuw1dweb01sakura` · plan `azeuw1dasp01sakura` · MI `6e9c2076-399f-47e3-a640-d3ed6b808489` |
| `azeuw1senmastersvrdb01` | `azeuw1senmastersvrdb01.database.windows.net` | Private Endpoints approved (see §3); NIC IPs via portal | Development | Azure SQL logical server — database `SakuraV2` | **`patrick.sura@dentsu.com`** | Azure SQL **v12.0** (kind `v12.0`); TLS min **1.2**; Microsoft-managed | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | **`AZ-VDC000006-EUW1-RG-SENSEI-DEV`** | `azeuw1senmastersvrdb01` · SystemAssigned MI `6ad3cfff-4297-4191-8de6-bc9b3bedc0bf` |

### 2.2 UAT / Test

| Hostname | FQDN | IP address(es) | Environment | Application / Service | Asset Owner | OS / Runtime | Cloud | Subscription ID | Resource Group | VM / Instance / Resource ID |
|----------|------|----------------|-------------|------------------------|-------------|--------------|-------|-----------------|----------------|-----------------------------|
| `azeuw1tswasakura` | `lemon-wave-07fa68003.2.azurestaticapps.net` | Private Endpoint `10.19.54.136` | UAT / Test | Sakura Frontend (Static Web App) | `Ebad.Uddin@dentsu.com` (tag pattern) | PaaS — Angular 20 SPA; Microsoft-managed | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | `azeuw1tswasakura` · PE `azeuw1tswasakura_privateendpoint` |
| `azeuw1tweb01sakura` | `azeuw1tweb01sakura.azurewebsites.net` | Inbound **`20.105.216.32`**, **`20.105.243.12`** (public; no PE) | UAT / Test | Sakura Backend API (App Service Linux, Basic) | **`Toniann.Tuson@dentsu.com`** | **Linux** App Service — `DOTNETCORE\|8.0`; platform `109.0.7.36` | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | `azeuw1tweb01sakura` · plan `azeuw1tasp01sakura` · MI `6ab7da21-e32a-48f5-a954-4c908bb62184` |
| `azeuw1tsenmastersvrdb01` | `azeuw1tsenmastersvrdb01.database.windows.net` | Private Endpoint approved (see §3); NIC IP via portal | UAT / Test | Azure SQL logical server — database `SakuraV2` | **`patrick.sura@dentsu.com`** | Azure SQL **v12.0**; TLS min **1.2**; Microsoft-managed | Azure | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | **`AZ-VDC000006-EUW1-RG-SENSEI-TEST`** | `azeuw1tsenmastersvrdb01` · SystemAssigned MI `f42a2df2-bd6d-41eb-ad0f-f9debdf581d3` |

### 2.3 Production

| Hostname | FQDN | IP address(es) | Environment | Application / Service | Asset Owner | OS / Runtime | Cloud | Subscription ID | Resource Group | VM / Instance / Resource ID |
|----------|------|----------------|-------------|------------------------|-------------|--------------|-------|-----------------|----------------|-----------------------------|
| `azeuw1pswasakura` | `green-stone-0e7ff2e03.2.azurestaticapps.net` | Private Endpoint `10.19.50.132` | Production | Sakura Frontend (Static Web App) | `Ebad.Uddin@dentsu.com` (tag pattern) | PaaS — Angular 20 SPA; Microsoft-managed | Azure | `15039875-d735-4154-b944-f25aa3db1327` | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` | `azeuw1pswasakura` · PE `azeuw1pswasakura_Privateendpoint` |
| `azeuw1pweb01sakura` | `azeuw1pweb01sakura-awfefugdgubjhygd.westeurope-01.azurewebsites.net` | Inbound **`20.105.216.55`**, **`20.105.224.134`** (public; no PE) | Production | Sakura Backend API (App Service Linux, Basic) | **`Toniann.Tuson@dentsu.com`** | **Linux** App Service — `DOTNETCORE\|8.0`; platform `109.0.7.36` | Azure | `15039875-d735-4154-b944-f25aa3db1327` | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` | `azeuw1pweb01sakura` · plan `azeuw1pasp01sakura` · MI `2c574314-a14a-4dbd-b99b-325905ed5afc` |
| `azeuw1psenmastersvrdb01` | `azeuw1psenmastersvrdb01.database.windows.net` | **TBD — need Prod portal JSON** | Production | Azure SQL — database `SakuraV2` | **TBD** (expected Sensei pattern) | Azure SQL PaaS (confirm version) | Azure | Confirm (likely Prod sub) | **TBD** (likely `…-RG-SENSEI-PROD` pattern) | `azeuw1psenmastersvrdb01` |

---

## 3. Azure SQL — portal-confirmed detail (Dev & UAT)

### 3.1 Dev — `azeuw1senmastersvrdb01`

| Field | Value |
|-------|--------|
| Resource ID | `/subscriptions/7a659c18-04dd-412f-9cff-4b2d4e41e937/resourceGroups/AZ-VDC000006-EUW1-RG-SENSEI-DEV/providers/Microsoft.Sql/servers/azeuw1senmastersvrdb01` |
| Location | West Europe |
| Kind / version | `v12.0` / `12.0` |
| State | Ready |
| FQDN | `azeuw1senmastersvrdb01.database.windows.net` |
| `publicNetworkAccess` | **Enabled** |
| `minimalTlsVersion` | **1.2** |
| `restrictOutboundNetworkAccess` | Disabled |
| Azure AD admin | Group `UG-GLO-BI-ADMIN` (`38777532-1309-4416-847d-a8462a564a4c`) |
| SQL admin login (name only) | `sqladminuser` |
| System-assigned identity | `6ad3cfff-4297-4191-8de6-bc9b3bedc0bf` |
| Owner tag | `patrick.sura@dentsu.com` |
| FinanceContact tag | `patrick.sura@dentsu.com` |
| Environment tag | Development |
| Criticality tag | Tier3-Non-Critical |
| Project tag | Finance Project SENSEI |
| DataClassification | Internal |

**Approved private endpoint connections**

| Connection name | Private Endpoint resource | Endpoint subscription |
|-----------------|---------------------------|------------------------|
| `azeuw1tsenadf01.ASQL_PE_Masterdata-…` | `azeuw1tsenadf01.ASQL_PE_Masterdata` in `vnet-769612ff-WestEurope-34-rg` | `769612ff-d354-45f7-ae62-a2a1f39bac12` |
| `sensei-dbpvtendpoint-…` | `sensei-dbpvtendpoint` in `AZ-VDC000006-EUW1-RG-SENSEI-DEV` | `7a659c18-04dd-412f-9cff-4b2d4e41e937` |
| `VDH-ProcessDB-Collibra-Dev-…` | `VDH-ProcessDB-Collibra-Dev` in `vdhdev-collibra-aks-rg` | `f9eae7ae-abbb-4786-81cc-8df24d7b6bf9` |

### 3.2 UAT / Test — `azeuw1tsenmastersvrdb01`

| Field | Value |
|-------|--------|
| Resource ID | `/subscriptions/7a659c18-04dd-412f-9cff-4b2d4e41e937/resourceGroups/AZ-VDC000006-EUW1-RG-SENSEI-TEST/providers/Microsoft.Sql/servers/azeuw1tsenmastersvrdb01` |
| Location | West Europe |
| Kind / version | `v12.0` / `12.0` |
| State | Ready |
| FQDN | `azeuw1tsenmastersvrdb01.database.windows.net` |
| `publicNetworkAccess` | **Enabled** |
| `minimalTlsVersion` | **1.2** |
| `restrictOutboundNetworkAccess` | Disabled |
| Azure AD admin | Group `#UG-DE-FinanceBi-ADM-USR` (`23d5d560-9590-4010-8ec8-745b476c5a30`) |
| SQL admin login (name only) | `sqladminuser` |
| System-assigned identity | `f42a2df2-bd6d-41eb-ad0f-f9debdf581d3` |
| Owner tag | `patrick.sura@dentsu.com` |
| FinanceContact tag | `patrick.sura@dentsu.com` |
| Environment tag | Test |
| Criticality tag | Tier2-Operational |
| Project tag | Finance Project SENSEI |
| DataClassification | Internal |

**Approved private endpoint connections**

| Connection name | Private Endpoint resource | Endpoint subscription |
|-----------------|---------------------------|------------------------|
| `sensei-test-dbpvtendpoint-…` | `sensei-test-dbpvtendpoint` in `AZ-VDC000006-EUW1-RG-SENSEI-TEST` | `7a659c18-04dd-412f-9cff-4b2d4e41e937` |

### 3.3 Exposure note for Defender / Wiz

Both Dev and UAT SQL servers show **`publicNetworkAccess: Enabled`** even though private endpoints exist. For VA purposes:

1. Treat SQL as **in scope** for cloud vulnerability / exposure review.
2. Validate **firewall rules** / “Deny public network access” effective state in portal (not assumed from PE alone).
3. Browser never connects to SQL; Sakura App Service APIs are the intended application path.

---

## 4. App Service APIs — portal-confirmed detail (Dev / UAT / Prod)

All three are **Linux** App Services (`kind: app,linux`), runtime **`DOTNETCORE|8.0`**, SKU **Basic**, **`publicNetworkAccess: Enabled`**, **no private endpoints**, **`httpsOnly: true`**.

| Field | Dev `azeuw1dweb01sakura` | UAT `azeuw1tweb01sakura` | Prod `azeuw1pweb01sakura` |
|-------|--------------------------|--------------------------|---------------------------|
| FQDN | `azeuw1dweb01sakura.azurewebsites.net` | `azeuw1tweb01sakura.azurewebsites.net` | `azeuw1pweb01sakura-awfefugdgubjhygd.westeurope-01.azurewebsites.net` |
| Subscription | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | same | `15039875-d735-4154-b944-f25aa3db1327` |
| Resource Group | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` |
| App Service Plan | `azeuw1dasp01sakura` | `azeuw1tasp01sakura` | `azeuw1pasp01sakura` |
| State | Running | Running | Running |
| OS / runtime | Linux · `DOTNETCORE\|8.0` | Linux · `DOTNETCORE\|8.0` | Linux · `DOTNETCORE\|8.0` |
| Platform version | `109.0.7.36` | `109.0.7.36` | `109.0.7.36` |
| Inbound IPv4 | `20.105.232.38`, `20.105.224.52` | `20.105.216.32`, `20.105.243.12` | `20.105.216.55`, `20.105.224.134` |
| Inbound IPv6 | `2603:1020:206:6::24` | `2603:1020:206:8::1d` | `2603:1020:206:5::67` |
| System-assigned MI | `6e9c2076-399f-47e3-a640-d3ed6b808489` | `6ab7da21-e32a-48f5-a954-4c908bb62184` | `2c574314-a14a-4dbd-b99b-325905ed5afc` |
| Owner tag | `Ebad.Uddin@dentsu.com` | `Toniann.Tuson@dentsu.com` | `Toniann.Tuson@dentsu.com` |
| FinanceContact tag | `Pralay.Mistry@dentsu.com` | `Ebad.Uddin@dentsu.com` | `Ebad.Uddin@dentsu.com` |
| Criticality | Tier3-Non-Critical | Tier2-Operational | Tier2-Operational |
| DataClassification | Internal | Confidential | Confidential |
| sshEnabled | true | true | null (not set) |
| alwaysOn | true | true | false |
| App Insights | — | `azeuw1tweb01sakura` | `azeuw1pweb01sakura` |

**Outbound IPs:** each App Service has a large Microsoft-managed outbound pool (see portal `outboundIpAddresses` / `possibleOutboundIpAddresses`). Primary inbound IPs above are the ones to match first in Defender/Wiz for public exposure.

---

## 5. Prod Key Vault — portal-confirmed

| Field | Value |
|-------|--------|
| Name | `azeuw1pkvsakura` |
| Vault URI | `https://azeuw1pkvsakura.vault.azure.net/` |
| Subscription | `15039875-d735-4154-b944-f25aa3db1327` |
| Resource Group | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` |
| Location | West Europe |
| SKU | Standard |
| Owner tag | **`Toniann.Tuson@dentsu.com`** |
| FinanceContact | `Ebad.Uddin@dentsu.com` |
| Environment | Production |
| Criticality | Tier2-Operational |
| DataClassification | **Confidential** |
| Soft delete | Enabled · 90 days |
| RBAC authorization | `enableRbacAuthorization: true` |
| Network ACLs | `defaultAction: Allow`, `bypass: None`, **no IP rules**, **no VNet rules** |

**Wiz / Defender note:** network ACL default Allow with empty IP/VNet rules means the vault is **not network-restricted** at the firewall layer (access still depends on RBAC / access policies). Flag for exposure review.

---

## 6. Supporting cloud assets (recommended for Wiz)

| Hostname / Name | FQDN / Notes | Environment | Service | Cloud | Subscription ID | Resource Group | Owner (where known) |
|-----------------|--------------|-------------|---------|-------|-----------------|----------------|---------------------|
| `azeuw1dswasakura_privateendpoint` | IP `10.19.54.134` | Development | Private Endpoint (FE) | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | — |
| `azeuw1tswasakura_privateendpoint` | IP `10.19.54.136` | UAT | Private Endpoint (FE) | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | — |
| `azeuw1pswasakura_Privateendpoint` | IP `10.19.50.132` | Production | Private Endpoint (FE) | Azure | `15039875-…` | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` | — |
| `sensei-dbpvtendpoint` | PE for Dev SQL | Development | Private Endpoint (SQL) | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-SENSEI-DEV` | — |
| `sensei-test-dbpvtendpoint` | PE for UAT SQL | UAT | Private Endpoint (SQL) | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-SENSEI-TEST` | — |
| `azeuw1dkvsakura` | `azeuw1dkvsakura.vault.azure.net` | Development | Key Vault | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | Confirm portal |
| `azeuw1tkvcentral` | Key Vault | UAT | Key Vault | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | Confirm portal |
| **`azeuw1pkvsakura`** | `azeuw1pkvsakura.vault.azure.net` | Production | Key Vault | Azure | `15039875-…` | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` | **`Toniann.Tuson@dentsu.com`** |
| `azeuw1dadfsakura` | Data Factory | Development | ADF (V2 ref imports) | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-DEV-CENTRAL` | — |
| `azeuw1tadfsakura` / `azeuw1tadfcentral` | Data Factory | UAT | ADF | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | — |
| `azeuw1tswasakuragate` | `ambitious-sand-04a627c03.7.azurestaticapps.net` | UAT | Temporary public VPN-check SWA | Azure | `7a659c18-…` | `AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL` | — |

**Shared networking**

| Item | Value |
|------|--------|
| VNet (FE PE pattern) | `AZ-VDC000006-EUW1-NET-CORE` |
| Subnet | `AZ-VDC000006-EUW1-SNET-LZ-CORE-INTERNALSUBNET1` |
| Networking RG | `AZ-VDC000006-EUW1-RG-LZ-NETWORKING` |

---

## 7. Optional same-RG assets (confirm if in VA boundary)

Present in Test BI central RG documentation — include only if InfoSec scopes the full RG:

- Storage `azeuw1tstrgcentral01`
- Service Bus `azeuw1tsbnscentral`
- Function Apps `azeuw1tfunc01coupa`, `azeuw1tfuncalert`
- Logic App `azeuw1tlgalert`

---

## 8. Outstanding for complete VA register

| Gap | Status |
|-----|--------|
| Prod SQL portal JSON (`azeuw1psenmastersvrdb01`) — RG, owner, PEs, `publicNetworkAccess` | **Open** |
| VM portal JSON for `AZEUW1PRONM01` (sub, RG, private IP, Owner tag) | Open — hostname/FQDN/OS confirmed from ops docs |
| Confirm V2 EmailDispatcher / AD sync Task Scheduler host | Open — V1 confirmed on `AZEUW1PRONM01` |
| SQL PE NIC private IP addresses | Open |
| SQL firewall / Deny public internet effective rules | Open (`publicNetworkAccess=Enabled` on Dev+UAT) |
| Dev / UAT Key Vault portal JSON (network ACLs) | Open — Prod KV confirmed |
| App Service inbound / outbound IPs | **Closed** for Dev/UAT/Prod (see §4) |
| Prod Key Vault | **Closed** — `azeuw1pkvsakura` |
| SWA portal JSON (Owner tags) | Open |
| Extra Entra SPA URI `delightful-sand-0e0eb7803.2.azurestaticapps.net` | Confirm if live SWA in scope |
| Legacy Gapteq / V1 hosts on same Entra app | **In scope via VM `AZEUW1PRONM01`** for email/sync |

---

## 9. Suggested reply text (copy for InfoSec)

> Please find the Sakura host inventory for vulnerability assessment / Defender + Wiz coverage.  
> Scope includes Azure PaaS (Static Web Apps, App Service Linux .NET 8, Azure SQL, Key Vault) **and Windows VMs** used for email + nightly AD sync.  
> Primary automation VM: **`AZEUW1PRONM01.emea.media.global.loc`** (Windows Server 2019) — GAPTEQ portal, EmailDispatcher (~5 min), SakuraADSync.ps1 (~20:31). Related Dev/test VMs: `AZEUW1DSENM01`, `AZEUW1DSENM02` (`10.19.54.140`), `AZEUW1TRONM01`, `AZEUW1GTTESTM01`.  
> SMTP relay: `internalsmtprelay.media.global.loc:25`.  
> APIs are public Linux App Services; Prod Key Vault `azeuw1pkvsakura` ACL default Allow. Prod SQL portal export still outstanding.

---

## Related internal references

- **`Docs/SAKURA_VA_HOST_LIST_SHORT.md`** — short linear checklist for Security / Network / Identity
- `Docs/network-architecture/06-resources.html`
- `Docs/SAKURA_NETWORK_OPTIONS_FE_API_MYAPPS.md`
- `ARCHITECTURE.md`
- `Docs/EUC-DNS-Request-Full-Ticket-Text.md`
- `Docs/Azure-Static-Web-App-Prod-Pipeline-Config.md`
