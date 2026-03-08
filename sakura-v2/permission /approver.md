**1️⃣ Normalization Rule**

Before comparison:

"" → NULL  
" " → NULL

So the system effectively compares only:

NULL  
All Clients  
Nike  
Adidas  
Dentsu stakeholders  
etc.

**2️⃣ Hybrid Behaviour Rules**

| DB Value | Meaning |
| --- | --- |
| NULL | Unspecified rule (only matches NULL request) |
| All Clients | Wildcard rule |
| Specific client | Exact match rule |

Matching priority:

1️⃣ Exact match  
2️⃣ Wildcard (All Clients)  
3️⃣ Unspecified (NULL)

**3️⃣ Example Configuration Rows**

Assume the DB has these rows:

| Id | Entity | SL | ClientKey | Approver |
| --- | --- | --- | --- | --- |
| 1 | LATAM | CXM | Nike | Approver_Nike |
| 2 | LATAM | CXM | All Clients | Approver_AllClients |
| 3 | LATAM | CXM | NULL | Approver_Default |

**4️⃣ Request Scenarios**

**Case A — Exact Client**

Request

Client = Nike

Matching rows

| Row | Match |
| --- | --- |
| Nike | ✅ exact |
| All Clients | ✅ wildcard |
| NULL | ❌ (NULL means unspecified only) |

Result

Row 1  
Approver\_Nike

**Case B — Another Client**

Request

Client = Adidas

Matching rows

| Row | Match |
| --- | --- |
| Nike | ❌ |
| All Clients | ✅ wildcard |
| NULL | ❌ |

Result

Row 2  
Approver\_AllClients

**Case C — Request Client NULL**

Request

Client = NULL

Matching rows

| Row | Match |
| --- | --- |
| Nike | ❌ |
| All Clients | ❌ |
| NULL | ✅ |

Result

Row 3  
Approver\_Default

**5️⃣ Empty String Cases**

Because of normalization:

"" → NULL

These are identical:

Client = ""  
Client = NULL  
Client = " "

So they behave like **Case C**.

Result

Row 3  
Approver\_Default

**6️⃣ Full Hybrid Behaviour Table**

| Request Value | DB NULL | DB All Clients | DB Nike |
| --- | --- | --- | --- |
| NULL | ✅ | ❌ | ❌ |
| "" | ✅ | ❌ | ❌ |
| Nike | ❌ | ✅ | ✅ (preferred) |
| Adidas | ❌ | ✅ | ❌ |
| Dentsu | ❌ | ✅ | ❌ |

Selection priority:

Exact > All Clients > NULL

**7️⃣ Real Example**

DB rows:

| Id | Entity | SL | ClientKey | Approver |
| --- | --- | --- | --- | --- |
| 3 | LATAM | CXM | NULL | Appr1@email.com |
| 44 | LATAM | CXM | All Clients | Appr2@email.com |

Request

Client = Nike

Resolver sees:

Exact = none  
Wildcard = Row 44  
Default = Row 3

Result

Row 44  
Appr2@email.com

**8️⃣ Why Hybrid Behaviour Is Popular**

It allows business to define:

specific rule  
↓  
client family rule  
↓  
default rule

Example:

Nike → Nike approver  
Other clients → regional approver  
No client specified → fallback approver

For client dimension matching, which rule should the system follow?

Option A — Strict matching only  
Option B — DB NULL acts as wildcard  
Option C — Hybrid matching

Hybrid example:

Priority:

Exact Client → "All Clients" → NULL

---

**9️⃣ Five Examples: Option A vs B vs C — Why C Is Best**

Same DB config for all examples:

| Id | Entity | SL | ClientKey | Approver |
| --- | --- | --- | --- | --- |
| 1 | LATAM | CXM | Nike | Approver_Nike |
| 2 | LATAM | CXM | All Clients | Approver_AllClients |
| 3 | LATAM | CXM | NULL | Approver_Default |

---

**Example 1 — Request: Client = Nike**

| Option | Behaviour | Result | Why |
| --- | --- | --- | --- |
| **A (Strict)** | Only row where ClientKey = Nike. | Row 1 → Approver_Nike | ✅ Correct. |
| **B (NULL = wildcard)** | Matches Nike, All Clients, or NULL (any). Picks one (e.g. first). | Could be Row 1, 2, or 3 | ❌ Non-deterministic; might give wrong approver. |
| **C (Hybrid)** | Exact (Nike) wins over All Clients and NULL. | Row 1 → Approver_Nike | ✅ Correct and deterministic. |

---

**Example 2 — Request: Client = Adidas**

| Option | Behaviour | Result | Why |
| --- | --- | --- | --- |
| **A (Strict)** | No row has ClientKey = Adidas. | No match / null | ❌ Business wants “other clients” to use regional approver (All Clients), not no approver. |
| **B (NULL = wildcard)** | NULL matches any; might return Approver_Default. | Row 3 → Approver_Default | ❌ Wrong: Adidas is a real client; should get Approver_AllClients, not “unspecified” default. |
| **C (Hybrid)** | No exact match; use wildcard All Clients. | Row 2 → Approver_AllClients | ✅ Correct: “any other client” goes to regional approver. |

---

**Example 3 — Request: Client = NULL (not specified)**

| Option | Behaviour | Result | Why |
| --- | --- | --- | --- |
| **A (Strict)** | Only match where ClientKey IS NULL. | Row 3 → Approver_Default | ✅ Correct. |
| **B (NULL = wildcard)** | NULL matches everything; could return any row. | Non-deterministic | ❌ Might give Nike or All Clients approver when no client was chosen. |
| **C (Hybrid)** | Only DB NULL matches request NULL. | Row 3 → Approver_Default | ✅ Correct: “no client specified” → default rule only. |

---

**Example 4 — Request: Client = "" or " " (empty)**

After normalization ("" and " " → NULL):

| Option | Behaviour | Result | Why |
| --- | --- | --- | --- |
| **A (Strict)** | Treated as NULL; match only DB NULL. | Row 3 → Approver_Default | ✅ Correct. |
| **B (NULL = wildcard)** | Treated as NULL; matches any. | Non-deterministic | ❌ Same problem as Example 3. |
| **C (Hybrid)** | Same as request NULL. | Row 3 → Approver_Default | ✅ Correct and consistent with Example 3. |

---

**Example 5 — Request: Client = Dentsu (DB has no “Dentsu” row)**

| Option | Behaviour | Result | Why |
| --- | --- | --- | --- |
| **A (Strict)** | No exact match. | No match / null | ❌ Real client with no specific rule should fall back to “All Clients”, not fail. |
| **B (NULL = wildcard)** | NULL matches; returns Approver_Default. | Row 3 → Approver_Default | ❌ Dentsu is a specific client; should get Approver_AllClients (regional), not “unspecified” default. |
| **C (Hybrid)** | No exact match; use wildcard All Clients. | Row 2 → Approver_AllClients | ✅ Correct: specific client without its own rule → regional/All Clients approver. |

---

**Why Option C (Hybrid) Is Best**

| Criterion | A (Strict) | B (NULL = wildcard) | C (Hybrid) |
| --- | --- | --- | --- |
| **Exact client (e.g. Nike)** | ✅ Correct | ❌ Unpredictable | ✅ Correct |
| **Other clients (e.g. Adidas, Dentsu)** | ❌ No match | ❌ Wrong (default used) | ✅ Regional/All Clients |
| **No client specified (NULL/empty)** | ✅ Correct | ❌ Unpredictable | ✅ Default only |
| **Priority (specific → regional → default)** | ❌ No fallback | ❌ No clear priority | ✅ Exact → All Clients → NULL |
| **Deterministic** | ✅ Yes | ❌ No | ✅ Yes |

**Summary:** Option C gives you **deterministic**, **business-friendly** behaviour: specific clients get their approver, other clients get the “All Clients” approver, and only when the client is truly unspecified do you use the NULL/default rule. That is why C is the best choice and what the backend implements.

---

**🔟 Examples from Populate Scripts (Script_Populate)**

The following use **real rows** from `Script_Populate/1-AMER Script.sql`, `1-DFI Script.sql`, and `1-CDI Script.sql`. They show how Option C (Hybrid) behaves with the actual RLS approver data.

---

**Source: 1-AMER Script.sql — RLSAMERApprovers**

Typical rows (simplified):

| EntityKey | EntityHierarchy | SLKey | ClientKey | Approvers |
| --- | --- | --- | --- | --- |
| Canada | Market | Overall | NULL | Desiree.Benson@dentsu.com |
| Americas | Region | FIN | All Clients | Desiree.Benson@dentsu.com |
| LATAM | Cluster | CXM | NULL | Desiree.Benson@dentsu.com |

So we have **NULL** (org-level, no client) and **All Clients** (wildcard for FIN at Region).

**Example A — Request: AMER-ORGA, Entity=Canada, SL=Overall, Client=NULL**

- **Option A (Strict):** Match only where ClientKey IS NULL → row Canada/Market/Overall/NULL → **Desiree.Benson@dentsu.com**. ✅  
- **Option B:** NULL could match any; result non-deterministic. ❌  
- **Option C (Hybrid):** Request NULL matches only DB NULL → same row → **Desiree.Benson@dentsu.com**. ✅  

**Example B — Request: AMER-ORGA, Entity=Americas, SL=FIN, Client=Nike**

- **Option A (Strict):** No row has ClientKey = Nike → **no match**. ❌ (We want regional approver for "any client" under FIN.)  
- **Option B:** Could match NULL row and return wrong approver. ❌  
- **Option C (Hybrid):** No exact Nike row; use **All Clients** row (Americas/Region/FIN/All Clients) → **Desiree.Benson@dentsu.com**. ✅  

So with **populate data**, Option C gives the right approver for "no client" (NULL) and "a specific client under FIN" (All Clients).

---

**Source: 1-DFI Script.sql — RLSFUMApprovers**

Typical rows:

| EntityKey | EntityHierarchy | ClientKey | MSSKey | ProfitCenterKey | Approvers |
| --- | --- | --- | --- | --- | --- |
| Canada | Market | All Clients | Overall | BR_TOTAL | patrick.renard@dentsu.com |
| UK&I | Cluster | All Clients | Overall | BR_TOTAL | nick.storey@dentsu.com; James.Sallows@dentsu.com |
| Global | Global | All Clients | Overall | BR_TOTAL | Terry.Newell@dentsu.com; Kate.Rudwick@dentsu.com |

All rows use **ClientKey = All Clients** (no NULL, no specific client in script).

**Example C — Request: DFI/FUM, Entity=Canada, Client=Adidas, MSS=Overall, PC=BR_TOTAL**

- **Option A (Strict):** No row has ClientKey = Adidas → **no match**. ❌  
- **Option B:** No NULL row in script; if there were, NULL-as-wildcard could pick wrong row. ❌  
- **Option C (Hybrid):** No exact Adidas; use **All Clients** → Canada/Market/All Clients/Overall/BR_TOTAL → **patrick.renard@dentsu.com**. ✅  

So with **DFI populate data**, Option C correctly routes "any client" (e.g. Adidas) to the market approver via the All Clients row.

---

**Source: 1-CDI Script.sql — RLSCDIApprovers & RLSPermissionCDIDetails**

RLSCDIApprovers has only **All Clients** rows:

| EntityKey | EntityHierarchy | ClientKey | SLKey | Approvers |
| --- | --- | --- | --- | --- |
| Global | Global | All Clients | Overall | ben.bartl@dentsu.com; stephen.byrne@dentsu.com; nitin.menon@dentsu.com |
| Americas | Region | All Clients | Overall | desiree.benson@dentsu.com |
| EMEA | Region | All Clients | Overall | gianluca.gualtieri@dentsu.com |
| APAC | Region | All Clients | Overall | dennis.yip@dentsu.com |

Permission requests in the script use **specific clients** (e.g. NESTLE GROUP, TOYOTA, SUBWAY, All Clients).

**Example D — Request: CDI, Entity=EMEA, Client=NESTLE GROUP, SL=Overall**

- **Option A (Strict):** No row has ClientKey = NESTLE GROUP → **no match**. ❌  
- **Option C (Hybrid):** No exact NESTLE GROUP row; use **All Clients** → EMEA/Region/All Clients/Overall → **gianluca.gualtieri@dentsu.com**. ✅  

**Example E — Request: CDI, Entity=Global, Client=All Clients, SL=Overall**

- **Option A (Strict):** Exact match on Global/Global/All Clients/Overall → **ben.bartl@dentsu.com; stephen.byrne@dentsu.com; nitin.menon@dentsu.com**. ✅  
- **Option C (Hybrid):** Same (exact match) → same approvers. ✅  

So with **CDI populate data**, Option C gives the right regional/global approver for both "All Clients" and specific clients (NESTLE, TOYOTA, etc.) that have no dedicated row.

---

**Summary (from populate scripts)**

| Script | Option A | Option C (Hybrid) |
| --- | --- | --- |
| **1-AMER** | Fails when request has a client (e.g. Nike) but DB has only NULL + All Clients. | NULL request → NULL row; client request → All Clients row. ✅ |
| **1-DFI** | Fails for any specific client (e.g. Adidas) because all approver rows are All Clients. | Any client → All Clients row (e.g. Canada → patrick.renard@). ✅ |
| **1-CDI** | Fails for specific clients (NESTLE, TOYOTA) since RLSCDIApprovers has only All Clients. | Specific client → All Clients row by region/global. ✅ |

**Conclusion:** The populate scripts are built for **Hybrid (Option C)**. Strict (A) would break real requests that have a client but no client-specific approver row; NULL-as-wildcard (B) would be non-deterministic. Option C matches how the data is designed and how the backend resolves approvers.
