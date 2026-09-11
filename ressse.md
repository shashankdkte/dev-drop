# Sakura V2 — Host List

## 60-second picture

```
User (browser)
  → Frontend SWA  (private today via PE + VPN)
  → Backend API   (public App Service + Entra JWT)
  → Azure SQL     (SakuraV2 DB)
  → Key Vault     (secrets)

Windows VM (automation)
  → EmailDispatcher (~5 min) → SMTP  [runs on Test + Prod]
  → SakuraV2ADSync.ps1 (nightly) → Entra Graph  [Prod only — NOT on Test]
```

- **Scope:** **Sakura V2 only**  
- **Cloud:** Azure PaaS + Windows VM(s) for V2 email / AD sync  
  

---

## Subscriptions (start here)

| # | Env | Subscription ID | Name / note |
|---|-----|-----------------|-------------|
| S1 | Dev + UAT | `7a659c18-04dd-412f-9cff-4b2d4e41e937` | NonProd `VDC000006-…` |
| S2 | Prod | `15039875-d735-4154-b944-f25aa3db1327` | Prod `VDC000007-…` |

---

## Identity (Entra) — check first

| # | Item | Value |
|---|------|--------|
| I1 | Tenant | `6e8992ec-76d5-4ea5-8eae-b0c5e558749a` |
| I2 | App name | **Sakura** |
| I3 | Client ID | `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` |
| I4 | Service principal | `faeacbe2-e6f7-453d-81b4-c0f1d691b565` |
| I5 | API scope | `api://e73f4528-2ceb-40e3-8e4a-d72287adb4c5/access_as_user` |

---

## Network shared

| # | Item | Value |
|---|------|--------|
| N1 | VNet | `AZ-VDC000006-EUW1-NET-CORE` |
| N2 | Subnet | `AZ-VDC000006-EUW1-SNET-LZ-CORE-INTERNALSUBNET1` |
| N3 | Networking RG | `AZ-VDC000006-EUW1-RG-LZ-NETWORKING` |
| N4 | SMTP relay (emails) | `internalsmtprelay.media.global.loc` port **25** |

---

## Windows VM — V2 emails + nightly AD sync

| # | Hostname | FQDN | Env | What runs (V2) | OS |
|---|----------|------|-----|----------------|----|
| VM1 | **`AZEUW1PRONM01`** | `AZEUW1PRONM01.emea.media.global.loc` | Production | **EmailDispatcher** (~5 min) **and** **SakuraV2ADSync.ps1** (nightly ~20:31) | **Windows Server 2019** (NT 10.0.17763) |
| VM-Test | Test automation VM (confirm name in portal if not same host) | confirm | **UAT / Test** | **EmailDispatcher only** (~5 min) | Windows Server (confirm) |

| V2 job | Test | Prod | Tech | Depends on |
|--------|------|------|------|------------|
| **EmailDispatcher** | **Yes — runs** | **Yes — runs** | .NET / Task Scheduler | SMTP `internalsmtprelay.media.global.loc:25` |
| **SakuraV2ADSync.ps1** (nightly) | **No — does not run on Test** | **Yes — runs** | PowerShell / Task Scheduler | Microsoft Graph + SakuraV2 SQL |


---

## Walk the stack — Development

| # | Type | Name | FQDN / endpoint | IP / access | RG | Owner | OS / runtime |
|---|------|------|-----------------|-------------|----|-------|--------------|
| D1 | Frontend SWA | `azeuw1dswasakura` | `orange-sand-03a59b103.3.azurestaticapps.net` | PE `10.19.54.134` | `…-RG-BI-DEV-CENTRAL` | Ebad (PE tag) | Angular 20 PaaS |
| D2 | FE Private Endpoint | `azeuw1dswasakura_privateendpoint` | — | `10.19.54.134` | `…-RG-BI-DEV-CENTRAL` | Ebad | N/A |
| D3 | Backend API | `azeuw1dweb01sakura` | `azeuw1dweb01sakura.azurewebsites.net` | Public inbound `20.105.232.38`, `20.105.224.52` | `…-RG-BI-DEV-CENTRAL` | **Ebad.Uddin@dentsu.com** | **Linux · DOTNETCORE\|8.0** |
| D4 | App Service Plan | `azeuw1dasp01sakura` | — | — | `…-RG-BI-DEV-CENTRAL` | — | Linux Basic |
| D5 | API MI | SystemAssigned | — | principal `6e9c2076-399f-47e3-a640-d3ed6b808489` | same as D3 | — | — |
| D6 | SQL server | `azeuw1senmastersvrdb01` | `azeuw1senmastersvrdb01.database.windows.net` | PEs yes · **publicNetworkAccess=Enabled** | **`…-RG-SENSEI-DEV`** | **patrick.sura@dentsu.com** | Azure SQL **v12.0** · TLS 1.2 |
| D7 | SQL DB | `SakuraV2` | on D6 | — | same as D6 | same | — |
| D8 | SQL PE | `sensei-dbpvtendpoint` | — | NIC IP in portal | `…-RG-SENSEI-DEV` | — | — |
| D9 | SQL PE (cross-sub) | `azeuw1tsenadf01.ASQL_PE_Masterdata` | — | sub `769612ff-…` | `vnet-769612ff-WestEurope-34-rg` | — | — |
| D10 | SQL PE (cross-sub) | `VDH-ProcessDB-Collibra-Dev` | — | sub `f9eae7ae-…` | `vdhdev-collibra-aks-rg` | — | — |
| D11 | Key Vault | `azeuw1dkvsakura` | `azeuw1dkvsakura.vault.azure.net` | confirm ACL | `…-RG-BI-DEV-CENTRAL` | confirm | Key Vault |
| D12 | ADF | `azeuw1dadfsakura` | — | — | `…-RG-BI-DEV-CENTRAL` | — | ADF PaaS |
| D13 | SQL AAD admin | `UG-GLO-BI-ADMIN` | — | sid `38777532-…` | — | — | Entra group |



---

## Walk the stack — UAT / Test

| # | Type | Name | FQDN / endpoint | IP / access | RG | Owner | OS / runtime |
|---|------|------|-----------------|-------------|----|-------|--------------|
| U1 | Frontend SWA | `azeuw1tswasakura` | `lemon-wave-07fa68003.2.azurestaticapps.net` | PE `10.19.54.136` | `…-RG-BI-TEST-CENTRAL` | Ebad (tag pattern) | Angular 20 PaaS |
| U2 | FE Private Endpoint | `azeuw1tswasakura_privateendpoint` | — | `10.19.54.136` | `…-RG-BI-TEST-CENTRAL` | — | N/A |
| U3 | Backend API | `azeuw1tweb01sakura` | `azeuw1tweb01sakura.azurewebsites.net` | Public inbound `20.105.216.32`, `20.105.243.12` | `…-RG-BI-TEST-CENTRAL` | **Toniann.Tuson@dentsu.com** | **Linux · DOTNETCORE\|8.0** |
| U4 | App Service Plan | `azeuw1tasp01sakura` | — | — | `…-RG-BI-TEST-CENTRAL` | — | Linux Basic |
| U5 | API MI | SystemAssigned | — | principal `6ab7da21-e32a-48f5-a954-4c908bb62184` | same as U3 | — | — |
| U6 | SQL server | `azeuw1tsenmastersvrdb01` | `azeuw1tsenmastersvrdb01.database.windows.net` | PE yes · **publicNetworkAccess=Enabled** | **`…-RG-SENSEI-TEST`** | **patrick.sura@dentsu.com** | Azure SQL **v12.0** · TLS 1.2 |
| U7 | SQL DB | `SakuraV2` | on U6 | — | same as U6 | same | — |
| U8 | SQL PE | `sensei-test-dbpvtendpoint` | — | NIC IP in portal | `…-RG-SENSEI-TEST` | — | — |
| U9 | Key Vault | `azeuw1tkvcentral` | `azeuw1tkvcentral.vault.azure.net` | confirm ACL | `…-RG-BI-TEST-CENTRAL` | confirm | Key Vault |
| U10 | ADF | `azeuw1tadfsakura` / `azeuw1tadfcentral` | — | — | `…-RG-BI-TEST-CENTRAL` | — | ADF PaaS |
| U11 | VPN gate SWA (temp) | `azeuw1tswasakuragate` | `ambitious-sand-04a627c03.7.azurestaticapps.net` | **Public** (no PE) | `…-RG-BI-TEST-CENTRAL` | — | SWA PaaS |
| U12 | SQL AAD admin | `#UG-DE-FinanceBi-ADM-USR` | — | sid `23d5d560-…` | — | — | Entra group |
| U13 | App Insights | `azeuw1tweb01sakura` | — | — | `…-RG-BI-TEST-CENTRAL` | — | — |




---

## Walk the stack — Production

| # | Type | Name | FQDN / endpoint | IP / access | RG | Owner | OS / runtime |
|---|------|------|-----------------|-------------|----|-------|--------------|
| P1 | Frontend SWA | `azeuw1pswasakura` | `green-stone-0e7ff2e03.2.azurestaticapps.net` | PE `10.19.50.132` | `…-RG-BI-PROD-CENTRAL` | Ebad (tag pattern) | Angular 20 PaaS |
| P2 | FE Private Endpoint | `azeuw1pswasakura_Privateendpoint` | — | `10.19.50.132` | `…-RG-BI-PROD-CENTRAL` | — | N/A |
| P3 | Backend API | `azeuw1pweb01sakura` | `azeuw1pweb01sakura-awfefugdgubjhygd.westeurope-01.azurewebsites.net` | Public inbound `20.105.216.55`, `20.105.224.134` | `…-RG-BI-PROD-CENTRAL` | **Toniann.Tuson@dentsu.com** | **Linux · DOTNETCORE\|8.0** |
| P4 | App Service Plan | `azeuw1pasp01sakura` | — | — | `…-RG-BI-PROD-CENTRAL` | — | Linux Basic |
| P5 | API MI | SystemAssigned | — | principal `2c574314-a14a-4dbd-b99b-325905ed5afc` | same as P3 | — | — |
| P6 | SQL server | `azeuw1psenmastersvrdb01` | `azeuw1psenmastersvrdb01.database.windows.net` | **** | **** | **** | Azure SQL (confirm) |
| P7 | SQL DB | `SakuraV2` | on P6 | — | same as P6 | — | — |
| P8 | Key Vault | `azeuw1pkvsakura` | `azeuw1pkvsakura.vault.azure.net` | | `…-RG-BI-PROD-CENTRAL` | **Toniann.Tuson@dentsu.com** | Key Vault Standard |
| P9 | App Insights | `azeuw1pweb01sakura` | — | — | `…-RG-BI-PROD-CENTRAL` | — | — |
| P10 | ADF MI (DB grants) | `azeuw1padfsakura` | — | name in DB scripts; confirm ADF resource | — | — | — |

**Prod subscription:** S2 · **Prod app RG:** `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL`

---

## Who owns what (quick)

| Area | Owner email |
|------|-------------|
| Dev API | `Ebad.Uddin@dentsu.com` |
| UAT API / Prod API / Prod KV | `Toniann.Tuson@dentsu.com` |
| Dev SQL / UAT SQL | `patrick.sura@dentsu.com` |
| Finance contact (UAT/Prod API + Prod KV) | `Ebad.Uddin@dentsu.com` |
| Prod SQL | TBD |

---

## Security / Network / Identity — what to do

| Team | Walk these IDs | Check |
|------|----------------|-------|
| **Identity** | I1–I5, D13, U12, D5, U5, P5, **VM1** | Entra app Sakura, CA, assignment, MIs, Graph perms for V2 AD sync on VM |
| **Network** | N1–N4, D1–D2, U1–U2, P1–P2, D8–D10, U8, API inbound IPs, **VM1** | PE coverage, public API exposure, SQL PEs, VNet, SMTP from VM |
| **Security / Wiz / Defender** | All D*, U*, P*, **VM1** + S1/S2 | PaaS + **Windows Server VM** (OS patches); flag public APIs, SQL public access, Prod KV ACL Allow |

---

## Exposure flags (do not miss)

1. **APIs are public** in Dev, UAT, Prod (no PE).  
2. **Dev + UAT SQL** have PEs but `publicNetworkAccess = Enabled`.  
3. **Prod KV** `azeuw1pkvsakura` has network ACL **Allow** with no IP/VNet rules.  
4. **FE** is private today (PE + VPN).  
5. **Prod SQL** details still outstanding.  
6. **EmailDispatcher** runs on **Test and Prod**. **Nightly AD sync does not run on Test** — Prod only (`AZEUW1PRONM01`).  
7. SMTP dependency: `internalsmtprelay.media.global.loc:25` (corp relay, not a Sakura-owned host

> Sakura **V2** VA scope: Azure PaaS (FE SWA, public Linux .NET 8 APIs, Azure SQL SakuraV2, Key Vault) plus Windows automation host(s). **EmailDispatcher runs on Test and Prod**; **nightly SakuraV2ADSync runs on Prod only** (not on Test) — Prod VM **`AZEUW1PRONM01.emea.media.global.loc`** (Windows Server 2019). NonProd sub `7a659c18-…`, Prod sub `15039875-…`. Entra app Sakura `e73f4528-…`. Prod SQL portal export pending.
