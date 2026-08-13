# Sakura V2 — Azure Portal Click-by-Click: Move Frontend Outside VPN

**Goal:** Users open the Sakura **website** without Dentsu VPN.  
**Main Azure change:** Remove the Static Web App **Private Endpoint**.  
**Do not change:** SQL database public exposure; do not “fix” the API for VPN (API is already public).

**Portals you will use:**
1. [Azure Portal](https://portal.azure.com) — network resources  
2. [Microsoft Entra admin center](https://entra.microsoft.com) — login / MFA / who can sign in  
3. Your PC — `nslookup` and browser tests  

**Order (do not skip):** Step 0 → Step 1 → Step 2 (UAT) → Step 3 (Prod) → Step 4 (docs).

---

## Names (copy exactly)

| Role | Exact name |
|------|------------|
| Prod subscription | `15039875-d735-4154-b944-f25aa3db1327` |
| Prod resource group | `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL` |
| Prod website (SWA) | `azeuw1pswasakura` |
| Prod website URL | `https://green-stone-0e7ff2e03.2.azurestaticapps.net` |
| Prod private endpoint | `azeuw1pswasakura_Privateendpoint` (IP `10.19.50.132`) |
| Prod API | `azeuw1pweb01sakura` |
| Prod API URL | `https://azeuw1pweb01sakura-awfefugdgubjhygd.westeurope-01.azurewebsites.net` |
| Prod SQL server | `azeuw1psenmastersvrdb01` |
| UAT website (SWA) | `azeuw1tswasakura` |
| UAT website URL | `https://lemon-wave-07fa68003.2.azurestaticapps.net` |
| UAT PE IP | `10.19.54.136` |
| UAT API | `azeuw1tweb01sakura` |
| Entra app name | `Sakura` |
| Entra App ID | `e73f4528-2ceb-40e3-8e4a-d72287adb4c5` |

---

## STEP 0 — Permission (not Azure clicks)

### 0.1 Email / ticket InfoSec

1. Open your IT ticketing tool (ServiceNow / email).  
2. Create ticket to InfoSec (e.g. Ebad).  
3. Paste:

> Request approval to make Sakura V2 **frontend** public (no VPN).  
> Resource: Static Web App `azeuw1pswasakura` (remove Private Endpoint `azeuw1pswasakura_Privateendpoint`).  
> API `azeuw1pweb01sakura` is already public.  
> SQL `azeuw1psenmastersvrdb01` will stay locked.  
> Pilot on UAT `azeuw1tswasakura` first.

4. Wait for **Approved**.  
5. **Save:** ticket number + approval screenshot/PDF.

**Stop if not approved.**

---

## STEP 1 — Entra + evidence (before any PE delete)

### 1.1 Open the Enterprise Application “Sakura”

1. Open browser → go to `https://entra.microsoft.com`.  
2. Sign in with an account that can read Enterprise Apps (or ask Entra admin to do this with you).  
3. Left menu: click **Identity**.  
4. Click **Applications**.  
5. Click **Enterprise applications**.  
6. In the search box at the top of the list, type: `Sakura`.  
7. Click the app whose **Application ID** is `e73f4528-2ceb-40e3-8e4a-d72287adb4c5`.  
8. **Screenshot** the Overview page. Save as `01-enterprise-app-overview.png`.

**Why:** This is the login gate after VPN is gone.

---

### 1.2 Check “Assignment required”

1. Still on Enterprise application **Sakura**.  
2. Left menu under **Manage**: click **Properties**.  
3. Find **Assignment required?**  
4. It should be **Yes**.  
   - If it is **No**: do **not** make FE public until InfoSec agrees; set to **Yes** only if InfoSec says so.  
5. Find **Visible to users?** (My Apps tile). Leave as-is unless Product asks to turn **Yes** later.  
6. **Screenshot** Properties. Save as `02-assignment-required.png`.

**Why:** Stops every employee from using Sakura just because the URL is public.

---

### 1.3 Check / add who can sign in (Users and groups)

1. Left menu: click **Users and groups**.  
2. Note who is listed today.  
3. Click **+ Add user/group**.  
4. Click **None Selected** under Users or Groups.  
5. Search and select the real Sakura security groups (ask Product/owner for group names).  
6. Click **Select**.  
7. Click **Assign**.  
8. **Screenshot** the final Users and groups list. Save as `03-users-and-groups.png`.

**Why:** Public website + empty assignment = wrong people blocked or right people missing.

---

### 1.4 Conditional Access (or ask InfoSec)

1. On Enterprise application **Sakura**, left menu under **Security**: click **Conditional Access**.  
2. If the blade is greyed out / you have no rights:  
   - Forward ticket to InfoSec: *“List CA policies for app e73f4528-2ceb-40e3-8e4a-d72287adb4c5”*.  
   - Save their reply as `04-conditional-access-infosec.pdf`.  
3. If you can open it:  
   - Click each policy that includes Sakura.  
   - Note: MFA? Compliant device? Locations?  
   - **Screenshot** each. Save as `04-ca-policy-1.png`, etc.

**Why:** After VPN removal, CA is a main security control for assessment.

---

### 1.5 App registration — redirect URIs

1. In Entra admin center left menu: **Identity** → **Applications** → **App registrations**.  
2. Click **All applications**.  
3. Search `Sakura` → open the one with Application (client) ID `e73f4528-2ceb-40e3-8e4a-d72287adb4c5`.  
4. Left menu: click **Authentication**.  
5. Under **Single-page application** → **Redirect URIs**, confirm these exist (add if missing):  
   - `https://green-stone-0e7ff2e03.2.azurestaticapps.net/`  
   - `https://lemon-wave-07fa68003.2.azurestaticapps.net/` (for UAT test)  
6. Scroll to **Implicit grant and hybrid flows**.  
7. Note if Access/ID tokens checkboxes are ticked (security debt).  
8. Click **Save** only if you added URIs.  
9. **Screenshot** Authentication page. Save as `05-authentication-redirects.png`.

**Why:** Wrong redirect = login error after users reach the site.

---

### 1.6 Azure Portal — confirm Prod API is public (do not change)

1. Go to `https://portal.azure.com`.  
2. Top bar: open **Directories + subscriptions** (filter icon) → select subscription `15039875-d735-4154-b944-f25aa3db1327` → click **Apply**.  
3. Top search box: type `azeuw1pweb01sakura` → Enter.  
4. Click App Service **azeuw1pweb01sakura**.  
5. Left menu: click **Networking**.  
6. Under **Inbound traffic**:  
   - **Public network access** should show **Enabled** (or similar).  
   - **Private endpoints** should show **0** or empty.  
7. **Do not click** Disable public access.  
8. **Screenshot** Networking. Save as `06-api-networking.png`.

**Why:** Proof for security that API was already public; you are not “opening API” in this project.

---

### 1.7 Azure Portal — check API CORS

1. Still on App Service **azeuw1pweb01sakura**.  
2. Left menu: scroll to **API** → click **CORS**.  
3. In **Allowed Origins**, confirm you see:  
   - `https://green-stone-0e7ff2e03.2.azurestaticapps.net`  
4. If missing:  
   - Type the URL in the box.  
   - Click **Add**.  
   - Click **Save** at the top.  
5. Repeat for UAT App Service **azeuw1tweb01sakura** with origin:  
   - `https://lemon-wave-07fa68003.2.azurestaticapps.net`  
   (Switch subscription/RG if UAT is under a different subscription.)  
6. **Screenshot** CORS. Save as `07-cors-prod.png` / `07-cors-uat.png`.

**Why:** Without CORS, website loads but API calls fail in the browser.

---

### 1.8 Azure Portal — SQL evidence (ask admin if no access)

1. Portal search: `azeuw1psenmastersvrdb01`.  
2. Open the **SQL server** (not only the database).  
3. Left menu: click **Networking** (or **Security** → **Networking**).  
4. Note:  
   - Public network access On/Off  
   - Firewall rules  
   - Private endpoint connections  
5. **Do not** turn public access On for the whole internet.  
6. **Screenshot**. Save as `08-sql-networking.png`.

**Why:** Security assessment asks “Did you open the database?” — answer must be No, with proof.

---

## STEP 2 — UAT pilot (Azure Portal clicks to remove PE)

Do this on **UAT** first: Static Web App **`azeuw1tswasakura`**.

### 2.1 Record BEFORE (PC + Portal)

**On your PC (VPN connected):**

1. Open **Command Prompt**.  
2. Run:

```text
nslookup lemon-wave-07fa68003.2.azurestaticapps.net
```

3. Expect address like `10.19.54.136`.  
4. Copy output to file `09-uat-nslookup-vpn-on.txt`.

**In Azure Portal:**

1. Portal search: `azeuw1tswasakura` → open Static Web App.  
2. Left menu: click **Private Endpoints** (sometimes labelled under **Networking** / **Private endpoint connections**).  
3. Confirm a private endpoint is listed and **Approved** / **Succeeded**.  
4. Click the endpoint name → note **Private IP** `10.19.54.136`.  
5. **Screenshot**. Save as `10-uat-pe-before.png`.

---

### 2.2 Raise Cloud / EUC ticket (if you cannot delete PE yourself)

Paste:

> Please disconnect/delete the Private Endpoint on Static Web App `azeuw1tswasakura` (PE IP `10.19.54.136`) so URL `https://lemon-wave-07fa68003.2.azurestaticapps.net` works without VPN.  
> Also update corporate DNS / privatelink so the hostname no longer resolves only to `10.19.54.136` for VPN users if that breaks public access.  
> Do not change SQL or App Service API networking.

Save ticket ID as `11-uat-cloud-ticket.txt`.

---

### 2.3 Delete / disconnect UAT Private Endpoint (Portal clicks)

> Only if you have **Contributor/Owner** on the SWA or RG. Otherwise Cloud team does this using the same clicks.

1. Azure Portal → open Static Web App **`azeuw1tswasakura`**.  
2. Left menu: click **Private Endpoints**.  
3. Tick the checkbox next to the private endpoint (the one for IP `10.19.54.136`).  
4. Click **Delete** (top toolbar).  
   - If Delete is not on SWA blade: click the **private endpoint name** → it opens the Private Endpoint resource → click **Delete** → type the name to confirm → **Delete**.  
5. Wait until the Private Endpoints list is **empty** (refresh with F5).  
6. **Screenshot** empty list. Save as `12-uat-pe-after.png`.

**Optional check — Public network access (if the blade shows it):**

1. Still on SWA **`azeuw1tswasakura`**.  
2. Left menu: **Networking** (if present) or Overview.  
3. If you see **Public network access**, set to **Enabled** / allow public.  
4. Click **Save** if shown.  
5. Screenshot as `13-uat-public-network-access.png`.

**Why:** Removing PE is what unlocks the website from VPN.

---

### 2.4 DNS check after UAT PE removal

**PC — VPN OFF (disconnect Ivanti first):**

1. Command Prompt:

```text
nslookup lemon-wave-07fa68003.2.azurestaticapps.net
```

2. Result must **not** be only `10.19.54.136`.  
3. Save as `14-uat-nslookup-vpn-off.txt`.  
4. If it still shows `10.19.54.136` with VPN off: corporate DNS is wrong → EUC must fix privatelink override. Do not proceed to Prod.

**PC — browser VPN OFF:**

1. Open Chrome/Edge.  
2. Go to `https://lemon-wave-07fa68003.2.azurestaticapps.net`.  
3. Site should load (login page OK).  
4. Screenshot as `15-uat-browser-no-vpn.png`.

---

### 2.5 Full UAT test without VPN

1. VPN **disconnected**.  
2. Open UAT URL.  
3. Click Sign in → complete Entra + MFA.  
4. Press **F12** → **Network** tab.  
5. Do one normal action (open a request list).  
6. Find calls to `azeuw1tweb01sakura` — status should be **200** (or expected API status), not CORS error.  
7. Screenshot Network tab as `16-uat-api-ok.png`.  
8. Sign out. Try a user **not** in assigned groups → should fail. Screenshot `17-uat-denied-user.png`.

**Pass criteria:** Steps 2.4–2.5 OK. Then go to Prod.

---

## STEP 3 — Production (exact Portal clicks)

Resource: **`azeuw1pswasakura`** · PE **`azeuw1pswasakura_Privateendpoint`** · IP **`10.19.50.132`** · RG **`AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL`**.

### 3.1 BEFORE proof

**PC — VPN ON:**

```text
nslookup green-stone-0e7ff2e03.2.azurestaticapps.net
```

Expect `10.19.50.132`. Save `18-prod-nslookup-vpn-on.txt`.

**Portal:**

1. Switch subscription to `15039875-d735-4154-b944-f25aa3db1327`.  
2. Search `azeuw1pswasakura` → open it.  
3. Left: **Private Endpoints**.  
4. Confirm **`azeuw1pswasakura_Privateendpoint`** · Approved · IP `10.19.50.132`.  
5. Screenshot `19-prod-pe-before.png`.

---

### 3.2 Send user communication

1. Email users: short outage possible; after change **VPN not required** for Sakura website.  
2. Save email as `20-prod-comms.pdf`.

---

### 3.3 Cloud ticket for Prod (if needed)

> Disconnect/delete Private Endpoint `azeuw1pswasakura_Privateendpoint` (IP `10.19.50.132`) on Static Web App `azeuw1pswasakura` in resource group `AZ-VDC000007-EUW1-RG-BI-PROD-CENTRAL`, subscription `15039875-d735-4154-b944-f25aa3db1327`.  
> Update DNS so `green-stone-0e7ff2e03.2.azurestaticapps.net` works without VPN.  
> Do **not** change App Service `azeuw1pweb01sakura` or SQL `azeuw1psenmastersvrdb01`.

Save ticket `21-prod-cloud-ticket.txt`.

---

### 3.4 Delete Prod Private Endpoint (Portal clicks)

1. `https://portal.azure.com`  
2. Subscription filter → `15039875-d735-4154-b944-f25aa3db1327` → **Apply**.  
3. Top search → `azeuw1pswasakura` → Enter.  
4. Click Static Web App **azeuw1pswasakura**.  
5. Left menu → **Private Endpoints**.  
6. Select **`azeuw1pswasakura_Privateendpoint`** (or the connection showing IP `10.19.50.132`).  
7. Click **Delete**.  
   - Or open the endpoint resource → top **Delete** → confirm by typing the name → **Delete**.  
8. Refresh until Private Endpoints list is empty.  
9. Screenshot `22-prod-pe-after.png`.  
10. If **Public network access** setting exists on the SWA: set **Enabled** → **Save**. Screenshot `23-prod-public-access.png`.

---

### 3.5 DNS + browser after Prod PE removal

**VPN OFF:**

```text
nslookup green-stone-0e7ff2e03.2.azurestaticapps.net
```

Save `24-prod-nslookup-vpn-off.txt` (must not require `10.19.50.132` only).

Browser VPN OFF:

1. Open `https://green-stone-0e7ff2e03.2.azurestaticapps.net`  
2. Sign in + MFA  
3. F12 → Network → confirm calls to  
   `azeuw1pweb01sakura-awfefugdgubjhygd.westeurope-01.azurewebsites.net` succeed  
4. Screenshots `25-prod-login-ok.png`, `26-prod-api-ok.png`

---

### 3.6 Confirm you did not open SQL

1. Portal → SQL server `azeuw1psenmastersvrdb01` → **Networking**.  
2. Confirm still restricted (same as Step 1.8).  
3. Screenshot `27-sql-still-locked.png`.

---

## STEP 4 — Docs after cutover

### 4.1 User guide files (repo)

1. Open repo files:  
   - `userguide/Latest_Today/Test/VPN.md`  
   - `userguide/Latest_Today/Test/SakuraUserGuide.md`  
2. Change text from “VPN required” to “VPN not required for Sakura V2 website” (after Prod is done).  
3. Commit / PR. Save link as `28-userguide-pr.txt`.

### 4.2 Evidence folder for future security assessment

Put all `01-…` to `28-…` files in one share folder named:

`Sakura-V2-FE-Public-Access-Evidence-YYYYMMDD`

Include a one-page `README.txt`:

```text
Change: Removed SWA Private Endpoint to allow FE without VPN
Prod SWA: azeuw1pswasakura
PE removed: azeuw1pswasakura_Privateendpoint (was 10.19.50.132)
API unchanged: azeuw1pweb01sakura (already public)
SQL unchanged: azeuw1psenmastersvrdb01
InfoSec ticket: ________
Cloud ticket: ________
UAT pass date: ________
Prod pass date: ________
```

---

## Quick “where do I click?” map

| Task | Portal | Clicks |
|------|--------|--------|
| Remove website VPN lock | Azure Portal | Search SWA → **Private Endpoints** → select PE → **Delete** |
| Who can log in | Entra | Enterprise applications → **Sakura** → **Users and groups** |
| Assignment required | Entra | Enterprise applications → **Sakura** → **Properties** |
| Redirect URLs | Entra | App registrations → **Sakura** → **Authentication** |
| CORS | Azure Portal | App Service → **CORS** → add FE URL → **Save** |
| Prove API public | Azure Portal | App Service → **Networking** |
| Prove SQL not opened | Azure Portal | SQL server → **Networking** |
| Prove DNS | Your PC | `nslookup <swa-hostname>` VPN on/off |

---

## Do not click these for this project

| Do not | Where |
|--------|--------|
| Delete App Service `azeuw1pweb01sakura` | App Service Overview |
| Set SQL public network access to allow all internet | SQL server → Networking |
| Turn off MFA in Conditional Access | Entra CA policies |
| Remove Prod PE before UAT succeeds | SWA `azeuw1pswasakura` |

---

## Done when

| Check | Evidence file |
|-------|----------------|
| InfoSec approved | Step 0 ticket |
| PE gone on Prod SWA | `22-prod-pe-after.png` |
| Site works without VPN | `25-prod-login-ok.png` |
| API still works | `26-prod-api-ok.png` |
| SQL still locked | `27-sql-still-locked.png` |
| Guides updated | `28-userguide-pr.txt` |
