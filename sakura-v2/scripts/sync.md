# Sakura V2 — Entra Group Sync Strategy Comparison
> Covers all 4 combinations: Full Replace vs Diff-Based × PowerShell Script vs Power Automate.  
> Includes real-world scenarios, pros, cons, and a final recommendation.

---

## What We Are Syncing

Every night, Sakura V2 needs to ensure that the Azure AD / Entra security groups contain exactly the right members — no more, no less.

The **source of truth** is:

```sql
SELECT RequestedFor, EntraGroupUID, LastChangeDate
FROM [Auto].[OLSGroupMemberships]
```

This view returns all currently-approved OLS permissions for Managed apps.  
The sync job must make Azure AD match this view.

---

## The Four Approaches

| # | Strategy | Tool |
|---|----------|------|
| 1 | Full Replace | PowerShell Script |
| 2 | Full Replace | Power Automate Flow |
| 3 | Diff-Based | PowerShell Script |
| 4 | Diff-Based | Power Automate Flow |

---

## Approach 1 — Full Replace via PowerShell Script

### What it does

```
1. Connect to SQL Server
2. SELECT * FROM [Auto].[OLSGroupMemberships]
3. Connect to Microsoft Graph (service principal)
4. For each distinct Entra group GUID:
   a. List ALL current members from Azure AD
   b. Remove EVERY member from the group (one by one)
   c. Add ALL desired members from the SQL result (in batches of 20)
5. Log results
6. Send email
```

There is no comparison step. Every run wipes the group and refills it from scratch.

### Real-World Scenario

- **100 members in the group, 100 in desired state, 0 changes today.**
- The script removes all 100 and adds all 100 back.
- Total Graph API calls: 100 removes + 5 batch adds = 105 calls.
- Net change to Azure AD: zero — but 105 calls were made unnecessarily.

- **Scenario: script fails halfway through removes (e.g. network drop after 50 removes).**
- The group now has 50 members instead of 100.
- Users who were removed but not yet re-added **lose access** until the next successful run.

### Pros

| Pro | Why |
|-----|-----|
| Simple to implement | No comparison logic — just remove all, add all. |
| Always consistent | After a successful run, group is guaranteed to match the view. |
| Good for initial setup | When building from scratch with no existing members. |
| Easy to reason about | No hashtables, no diff logic. Everyone knows what it does. |

### Cons

| Con | Why it matters |
|-----|----------------|
| **Dangerous if run fails mid-way** | Group can end up empty or partially filled. Users lose access. |
| **Unnecessary API calls** | Even if nothing changed, every member is removed and re-added. |
| **Graph throttling risk** | At 5,000+ members: 5,000 removes + 5,000 adds = 10,000+ calls per group. High risk of hitting Graph rate limits (429). |
| **No meaningful audit trail** | You can log "all members replaced" but you can't say "user X was added because their request was approved on date Y." |
| **Temporary access disruption** | The window between "remove all" and "add all completed" is a real window where legitimate users have no group access. |
| **Scale: 50,000 members** | 50,000 removes + 50,000 adds = 100,000 calls. Hours of runtime, near-certain throttling. |

### When to use it

Only acceptable for **very small groups** (< 200 members) during **initial setup** or in a **dev/test environment** where temporary access gaps don't matter.

---

## Approach 2 — Full Replace via Power Automate

### What it does

This is the current "Sakura 2.0 User Import" Power Automate flow as seen in the screenshots:

```
1. Manually trigger (or scheduled trigger)
2. Initialize variable: GroupId (string)
3. Initialize variable: UserList (string)
4. Execute SQL query → SELECT RequestedFor, EntraGroupUID, LastChangeDate
   FROM [Auto].[OLSGroupMemberships]
5. Get Group ID → (foreach over SQL results, sets GroupId variable)
6. List group members → uses @variables('GroupId')
7. Remove all users from group → foreach over @outputs('List_group_members')?['body/value']
   → RemoveMemberFromGroup for each current member
8. Apply to each → foreach over SQL results
   → Compose: User_Email = @items('Apply_to_each')?['RequestedFor']
   → Add member to group: groupId = @items('Apply_to_each')?['EntraGroupUID']
     userUpn = @items('Apply_to_each')?['RequestedFor']
9. Send an email (V2): "Successfully add all users to group"
   Body lists all added users
```

It is a **full replace** — it lists all current members, removes every one, then adds everyone from the SQL result.

### Real-World Scenario

- **Group has 1,000 members. 2 new users approved today.**
- The flow removes all 1,000 members (1,000 "Apply to each" iterations with one action each).
- Then adds all 1,002 users from the SQL result (1,002 more iterations).
- Total iterations: 2,002.
- **If the flow hits Power Automate's action limit mid-way through "remove all"**, it stops.
- Result: group has ~400 members left (partial removal), run stops, no re-add happens.
- **Net effect: 600 users lose access until next run.**

- **Scenario: 10,000 member group.**
- 10,000 remove iterations + 10,000 add iterations = 20,000 iterations.
- Power Automate default "Apply to each" concurrency: sequential.
- At ~1–2 seconds per iteration: 10,000 removes = ~5–10 hours just for removes.
- Power Automate **max flow run duration** for most plans: 30 minutes (standard) to a few hours (premium).
- The flow will **time out before finishing**.

### Pros

| Pro | Why |
|-----|-----|
| No code | Anyone can open and read the flow in the browser. |
| Visual | Each step is visible with a friendly UI — easy to demo and explain to non-technical stakeholders. |
| Integrated connectors | SQL Server and Office 365 connectors handle auth for you — no service principal setup needed. |
| Email built-in | The "Send email" step is trivial. |
| Good for proof of concept | Easy to build and test quickly with a small group. |

### Cons

| Con | Why it matters |
|-----|----------------|
| **Action/iteration limits** | Power Automate caps iterations per loop. At scale, you hit the limit. |
| **Run time limits** | Flows can time out. Large groups will not complete within allowed run time. |
| **No retry logic** | If Graph returns a 429 (throttle), you'd need to build retry manually using scope + condition + delay — very complex in flow designer. |
| **Not in version control** | The flow lives in Power Automate. Unless exported and stored in git, you have no history of who changed what. |
| **Licensing cost** | Premium Power Automate license required for SQL Server (non-Azure) and custom Graph connectors. |
| **Same "group empty" risk** | Fails halfway through removes = group partially empty = users lose access. |
| **Hard to debug at scale** | Flow run history shows each action's I/O but diagnosing 10,000 iterations is very tedious. |
| **No EventLog** | Adding per-user audit to `dbo.EventLog` requires adding SQL insert steps in the loop — more complexity and more actions (already at limit). |

### When to use it

Only for **very small groups** (< 500 members), **manual/one-off runs**, or when the team has **no ability to run scripts** and the group is too small to hit limits.  
**Not suitable for production Sakura V2 at any real scale.**

---

## Approach 3 — Diff-Based via PowerShell Script

### What it does

```
1. Connect to SQL Server
2. SELECT * FROM [Auto].[OLSGroupMemberships]  ← desired state
3. Build $userIdMap: resolve all user emails to Azure AD Object IDs
   (Get-MgUser per distinct email)
4. Get distinct group GUIDs from the desired state
5. Connect to Microsoft Graph (service principal — non-interactive)
6. For each group GUID:
   a. Get-MgGroup → fetch group display name
   b. Get-MgGroupMemberAsUser -All → fetch ALL current Azure AD members
   c. Build $currentADMap hashtable (ObjectId → member)
   d. Build $desiredMap hashtable (ObjectId → desired entry)
   e. Compute TO REMOVE = current members NOT in desired map
   f. Compute TO ADD = desired members NOT in current map (and with resolved ObjectId)
   g. Log users not found in AD (GroupMemberNotAdded)
   h. Remove each member in TO REMOVE:
      → Remove-MgGroupMemberByRef (one at a time)
      → Write-EventLogEntry: GroupMemberRemoved
   i. Add members in TO ADD in batches of 20:
      → Update-MgGroup -BodyParameter { members@odata.bind: [...] }
      → Write-EventLogEntry: GroupMemberAdded per member
7. Log summary
8. Send email: groups processed, errors
```

Only **actual changes** are sent to Graph API. If nothing changed, zero Graph calls are made for that group.

### Real-World Scenario

**Day 1 (initial run):**
- Group is empty in Azure AD. 500 users in desired state.
- TO REMOVE = 0, TO ADD = 500.
- 25 batch add calls (500 / 20 = 25 batches).
- EventLog: 500 `GroupMemberAdded` entries.

**Day 2 (typical run):**
- 500 users in group. 3 new approvals today, 1 revocation.
- TO REMOVE = 1, TO ADD = 3.
- 1 remove call + 1 batch add call = 2 Graph calls total.
- Group is never empty. No access disruption.
- EventLog: 3 `GroupMemberAdded`, 1 `GroupMemberRemoved`.

**Day 3 (no changes):**
- 502 users in group. 502 in desired state. Exact match.
- TO REMOVE = 0, TO ADD = 0.
- Zero Graph API calls. Script finishes in seconds.

**Failure scenario:**
- Script fails after removing 1 of 3 members to remove (e.g. network issue).
- 2 members who should have been removed are still in the group (they have slightly more access than they should for one day).
- 3 members who should have been added were not added yet.
- Next run picks up exactly where it left off — removing the 2 remaining + adding the 3.
- **No user loses access** because of the failure; at worst, some users keep access slightly longer than intended.

### Pros

| Pro | Why |
|-----|-----|
| **Safe** | Group is never emptied. A partial failure leaves the group in a consistent-ish state. |
| **Efficient** | Minimal API calls. On quiet days: near-zero calls. On busy days: only what changed. |
| **Scale: 50,000 members** | If only 5 changes per day: 5 API calls. The group size doesn't matter to the daily diff. |
| **Audit trail** | Per-user EventLog entries: who was added/removed, when, by what. Matches V2's existing design. |
| **Version controlled** | Lives in the git repo alongside the backend. Code review, PR, history. |
| **Service principal auth** | Fully automated. No human needed. Works in Task Scheduler, Azure DevOps pipeline, Azure Function. |
| **Retry control** | Can add `Start-Sleep` and retry loops around Graph calls for 429 handling. Full control. |
| **No licensing cost** | Only needs a machine/pipeline to run on. No per-run Power Automate license. |
| **Testable** | Can add a `-DryRun` flag to log adds/removes without calling Graph. Safe for testing. |

### Cons

| Con | Why it matters |
|-----|----------------|
| **More complex code** | Requires hashtable comparison logic vs simple "remove all, add all". |
| **Initial user resolution** | Must call `Get-MgUser` once per distinct email — at 50,000 unique users this takes time (but only needed once per run, not per group). |
| **Requires a PowerShell runtime** | Needs a Windows machine, Azure DevOps agent, or Azure Automation account. Not purely cloud-based. |
| **Harder to visualize** | Non-technical stakeholders can't open it in a browser like a flow. |

### When to use it

**Always — for production Sakura V2 at any scale.** This is the correct approach.

---

## Approach 4 — Diff-Based via Power Automate

### What it does

```
1. SQL: SELECT RequestedFor, EntraGroupUID FROM [Auto].[OLSGroupMemberships]
   → desired state collection
2. For each distinct EntraGroupUID:
   a. List group members → current state collection
   b. Filter array: TO REMOVE = current members where UPN NOT IN desired RequestedFor list
   c. For each TO REMOVE member: RemoveMemberFromGroup
   d. Filter array: TO ADD = desired members where RequestedFor NOT IN current member UPNs
   e. For each TO ADD member: AddMemberToGroup
3. Send email summary
```

This IS technically achievable in Power Automate using Filter Array actions and Apply to Each loops.

### Real-World Scenario

**Day 2 (typical — 3 adds, 1 remove, 500-member group):**
- Fetch 500 desired from SQL → OK
- List 500 current members from Graph → OK
- Filter array (TO REMOVE): produces 1 result
- Remove 1 member: 1 action
- Filter array (TO ADD): produces 3 results
- Add 3 members: 3 actions
- Total actions: manageable. **This works fine for small groups.**

**Day 1 (initial — 500-member group, group currently empty):**
- Desired = 500, Current = 0
- TO ADD = 500
- Apply to each over 500: 500 "Add member" iterations
- Still within limits for most plans. **Works.**

**Scale: 50,000-member group (initial run):**
- List current members: `Get-MgGroupMember` returns up to 999 per page in Graph.
- Power Automate "List group members" returns paginated results — you'd need to handle pagination (not automatic in flow).
- TO ADD = 50,000 members.
- Apply to each over 50,000: **will hit iteration and action limits, time out.**

**Scale: 50,000-member group (steady state, 5 changes/day):**
- Desired = 50,000 rows fetched from SQL.
- Filter Array over 50,000 rows to find 5 changes.
- This is a large in-memory array operation inside Power Automate — may be slow or hit expression size limits.
- Then only 5 actual add/remove calls — that part is fine.
- **The bottleneck is the array filtering step, not the Graph calls.**

### Pros

| Pro | Why |
|-----|-----|
| **No "group empty" risk** | Same safety as the diff script — group never emptied. |
| **Visual** | Non-technical stakeholders can see the logic in the flow designer. |
| **No script runtime needed** | Runs entirely in Power Automate cloud. |
| **Fewer API calls than full replace** | Only changed members are added/removed. |
| **Email and connectors built-in** | Less setup than a script for notification. |

### Cons

| Con | Why it matters |
|-----|----------------|
| **Array filter over large datasets** | Filtering 50,000-row desired array against 50,000-row current array in Power Automate expressions is very slow and can exceed expression/memory limits. |
| **Pagination not automatic** | "List group members" in Power Automate does NOT auto-paginate like the PowerShell `-All` flag. You need additional logic for groups > 999 members. |
| **Still subject to iteration limits** | On initial run or when large additions are needed, "Apply to each" can still time out. |
| **Retry on 429 is hard** | Building proper exponential backoff in a flow is complex (scope + condition + delay + loop). |
| **Not in version control** | Same issue as approach 2. |
| **Licensing** | Premium connectors still required. |
| **No EventLog without extra actions** | Each add/remove needs a SQL insert action, adding more actions to an already complex flow. |

### When to use it

Acceptable as a **low-scale backup option** (< ~2,000 members, stable group, few daily changes) when the team:
- Cannot run PowerShell anywhere
- Has Power Automate Premium already
- Accepts the limitations and manual pagination handling

**Not recommended as the primary mechanism for Sakura V2.**

---

## Side-by-Side Comparison

| Factor | Full Replace Script | Full Replace Flow | Diff Script | Diff Flow |
|--------|--------------------|--------------------|-------------|-----------|
| **Group ever emptied?** | Yes — every run | Yes — every run | No | No |
| **Safe on partial failure?** | No | No | Yes | Partial |
| **API calls (no change day)** | All members × 2 | All members × 2 | 0 | ~0 (but large filter) |
| **API calls (5 changes day)** | All members × 2 | All members × 2 | 5 + user resolution | 5 + large filter |
| **Scale: 50k members** | Fails/slow | Fails (timeout) | Works with retry | Fails (filter/timeout) |
| **Audit per user** | No | No | Yes (EventLog) | With extra steps |
| **Version control** | Yes | No | Yes | No |
| **Auth (unattended)** | Service principal | Connector (delegated or app) | Service principal | Connector |
| **Retry on throttle** | Add in code | Very hard | Add in code | Very hard |
| **Pagination (50k members)** | Automatic (`-All`) | Manual (extra steps needed) | Automatic (`-All`) | Manual |
| **Licensing** | Free | Power Automate Premium | Free | Power Automate Premium |
| **Maintainability** | Code, git | Flow UI, no git | Code, git | Flow UI, no git |

---

## Real-World Production Scenarios

### Scenario A — Small team, 300 users, early-stage launch
**Recommended: Full Replace Script or Diff Script**  
Both work fine. Diff is still better practice but full replace is acceptable at this scale as a starting point. Power Automate could work but adds unnecessary licensing cost.

### Scenario B — Global rollout, 5,000+ users, 20+ groups
**Recommended: Diff Script only**  
Full replace script starts to become slow and risks throttling. Flow approaches fail at this scale. Diff script is the only viable option. Run nightly via Azure DevOps pipeline.

### Scenario C — 50,000 users, multiple groups, high daily approval volume
**Recommended: Diff Script with retry and delay**  
Only the diff script handles this reliably. Add exponential backoff on 429 responses, configurable delay between removes, and a summary EventLog entry per group. Runtime may be 1–3 hours; schedule accordingly (e.g. 11 PM).

### Scenario D — Team has no DevOps/pipeline experience, wants no-code
**Recommended: Diff Flow (with awareness of limits)**  
If the team truly cannot run any script anywhere and group sizes stay small (< 2,000), the diff-based flow is the pragmatic choice. Accept the limitations. Plan to migrate to the script as the system grows.

### Scenario E — Audit compliance required (who approved, when was access granted)
**Recommended: Diff Script**  
The script writes per-user `GroupMemberAdded`/`GroupMemberRemoved` events to `dbo.EventLog`. This directly links sync actions to approved permission requests. No other approach gives you this out of the box.

---

## Timing Estimates

### Batching Logic — Script vs Power Automate

#### Script — batching

| Operation | Batching | Details |
|-----------|-----------|---------|
| **Add members** | **Yes — fixed batch size** | One Graph API call adds **up to 20 members** via `Update-MgGroup` with `members@odata.bind` (array of directory object URLs). The script loops in chunks of 20. So 100 adds = 5 API calls, not 100. |
| **Remove members** | **No** | Graph API has no bulk-remove endpoint. One `Remove-MgGroupMemberByRef` call per user. 100 removes = 100 API calls. Optional: add a small delay between removes to avoid throttling (e.g. 100 ms). |
| **List group members** | **Yes — automatic pagination** | `Get-MgGroupMemberAsUser -All` pages through all results (typically 100 per page). One logical operation; the module handles pagination. No explicit batching in your code. |
| **User resolution (email → Object ID)** | **No** | One `Get-MgUser` call per distinct email. Could be optimized later with batch request (JSON batching) if needed. |

**Net effect:** Adds are fast at scale (20× fewer calls). Removes and user resolution are linear in member count.

#### Power Automate — batching

| Operation | Batching | Details |
|-----------|----------|---------|
| **Add members** | **No** | Each "Add member to group" action = one connector call = one Graph API call. 100 adds = 100 flow iterations and 100 API calls. There is no built-in "add up to 20" action. |
| **Remove members** | **No** | Each "Remove member from group" action = one connector call. 100 removes = 100 iterations. |
| **List group members** | **Depends** | The Office 365 Groups "List group members" action returns one response. Graph typically returns a **single page** (e.g. first 100–999 members). To get all members for large groups you must implement **pagination** yourself (e.g. "Do until" loop, nextLink, append to array). No automatic "-All" equivalent. |
| **Filter / compare (diff)** | **N/A** | "Filter array" runs in the flow engine on in-memory arrays. No batching; large arrays (e.g. 10,000+ items) can be slow or hit expression size limits. |

**Net effect:** Every add and every remove is one action and one API call. At scale, flow run length and iteration count grow linearly with member count. List members for large groups requires custom pagination logic.

---

### Power Automate — Time per User

Each **remove** and each **add** in Power Automate is one flow action that calls the Graph/Office 365 connector. Measured in real runs and typical connector latency:

| Operation | Time per user (typical) | Notes |
|-----------|--------------------------|--------|
| **Remove member from group** | **1.0 – 2.5 s** | One "RemoveMemberFromGroup" action per user. Connector + Graph API. |
| **Add member to group** | **1.0 – 2.5 s** | One "AddMemberToGroup" action per user. Connector + Graph API. |

**Rough rule of thumb:** **~1.5 seconds per user** per operation (remove or add).  
So for **1,000 users**: remove all ≈ **25 min**, add all ≈ **25 min** → **~50 min** total for full replace.  
At **10,000 users**: **~8+ hours** (often hits flow run timeout).

---

### Power Automate — Diff-Based Time per Group (1% change)

Same ~1.5 s per user for each remove/add. Plus: "List group members" (one or more actions; pagination may be needed) and "Filter array" to compute to-add / to-remove. Filter time grows with group size (large arrays = slower).

| Members in group | List + filter (est.) | Removes (1%) | Adds (1%) | **Total per group** |
|------------------|----------------------|--------------|-----------|----------------------|
| 10 | ~5 s | ~2 s | ~2 s | **~9 s** |
| 50 | ~15 s | ~8 s | ~8 s | **~31 s** |
| 100 | ~30 s | ~15 s | ~15 s | **~1 min** |
| 500 | ~2 min | ~1.3 min | ~1.3 min | **~4.5 min** |
| 1,000 | ~4 min | ~2.5 min | ~2.5 min | **~9 min** |
| 5,000 | ~15 min (pagination + filter) | ~12 min | ~12 min | **~39 min** (timeout risk) |
| 10,000 | **Pagination + large filter** | ~25 min | ~25 min | **Timeout / limit** |
| 50,000 | **Not practical** | — | — | **Timeout / limit** |

*Diff-based in Power Automate still does one action per add and per remove; only the *count* of adds/removes is lower. List and filter at 5k+ become slow or hit limits.*

---

### Script — Time per Group (Table)

Assumptions:

- **Graph API:** ~0.4 – 0.8 s per call (average **~0.6 s**).
- **Script:** Removes = 1 call per user; Adds = 1 call per **20 users** (batch of 20). List members = paginated, ~0.6 s per 100 members.
- **User resolution:** Done once per run (all distinct emails). ~0.5 s per distinct user. Not repeated per group.
- **Diff-based:** "Typical day" = only the delta (e.g. 1% of members change). "Worst day" = initial load (all members added).

Times below are **per group** for that group size (one group with N members). User resolution time is **once per run** (all distinct users across all groups), not per group.

#### Full replace (script): remove all + add all

| Members in group | Remove all | Add all (batches of 20) | **Total per group** |
|------------------|------------|--------------------------|----------------------|
| 10 | ~6 s | ~1 s | **~7 s** |
| 50 | ~30 s | ~2 s | **~32 s** |
| 100 | ~1 min | ~3 s | **~1.1 min** |
| 500 | ~5 min | ~15 s | **~5.3 min** |
| 1,000 | ~10 min | ~30 s | **~11 min** |
| 5,000 | ~50 min | ~2.5 min | **~53 min** |
| 10,000 | ~1.7 h | ~5 min | **~2 h** |
| 50,000 | ~8.3 h | ~25 min | **~8.8 h** |

#### Diff-based (script): typical day (e.g. 1% change)

Assume **1% of members** change (to remove or to add). So 100 members → 1 remove + 1 add; 10,000 → 100 removes + 100 adds.

| Members in group | List current | Removes (1%) | Adds (1%, batched) | **Total per group** |
|------------------|--------------|--------------|--------------------|----------------------|
| 10 | &lt;1 s | ~1 s | &lt;1 s | **~2 s** |
| 50 | ~1 s | ~3 s | ~1 s | **~5 s** |
| 100 | ~1 s | ~6 s | ~2 s | **~9 s** |
| 500 | ~3 s | ~30 s | ~2 s | **~35 s** |
| 1,000 | ~6 s | ~1 min | ~3 s | **~1.2 min** |
| 5,000 | ~30 s | ~5 min | ~3 s | **~6 min** |
| 10,000 | ~1 min | ~10 min | ~3 s | **~11 min** |
| 50,000 | ~5 min | ~50 min | ~15 s | **~56 min** |

#### Diff-based (script): no changes (0% delta)

| Members in group | List current + compare | Removes | Adds | **Total per group** |
|------------------|------------------------|----------|------|----------------------|
| Any size | ~1–5 min (list + in-memory diff) | 0 | 0 | **~1–5 min** (no Graph writes) |

#### User resolution (script, once per run)

Resolving emails to Azure AD Object IDs: **one `Get-MgUser` per distinct user** across the whole run.

| Distinct users (across all groups) | Time (sequential, ~0.5 s per user) |
|------------------------------------|------------------------------------|
| 10 | ~5 s |
| 50 | ~25 s |
| 100 | ~50 s |
| 500 | ~4 min |
| 1,000 | ~8 min |
| 5,000 | ~42 min |
| 10,000 | ~1.4 h |
| 50,000 | ~7 h |

So for **one group of 10,000 members** with **diff-based** sync:

- **User resolution:** 10,000 distinct users ≈ **1.4 h** (once).
- **Per group:** list + 1% diff ≈ **~11 min**.
- **Total run (one group):** **~1.5 – 2 h**.  
For **multiple groups**, add per-group time; user resolution stays once per run.

---

### Summary: Script vs Power Automate (time)

All four approaches, with member counts 10 through 50,000. Times are per group (single group of that size). **Power Automate (diff)** still uses one action per add/remove, so time scales with 1% of members; list + filter time grows with full group size.

| Members | Power Automate (full replace) | Power Automate (diff, 1% change) | Script (full replace) | Script (diff, 1% change) |
|---------|-------------------------------|----------------------------------|------------------------|--------------------------|
| 10 | ~30 s | ~9 s | ~7 s | ~2 s |
| 50 | ~2.5 min | ~31 s | ~32 s | ~5 s |
| 100 | ~5 min | ~1 min | ~1.1 min | ~9 s |
| 500 | ~25 min | ~4.5 min | ~5.3 min | ~35 s |
| 1,000 | ~50 min (timeout risk) | ~9 min | ~11 min | ~1.2 min |
| 5,000 | **Timeout** (4+ h) | ~39 min (timeout risk) | ~53 min | ~6 min |
| 10,000 | **Timeout** | **Timeout / limit** | ~2 h | ~11 min |
| 50,000 | **Timeout** | **Timeout / limit** | ~9 h | ~56 min (+ user resolution) |

- **Power Automate full replace:** 1.5 s × 2 (remove + add) per member → linear growth; runs hit timeout at ~1k–5k.
- **Power Automate diff:** Same per-add/remove time for only 1% of members; list + filter and iteration limits become the bottleneck at 5k+.
- **Script full replace:** Removes 1 call per user; adds batched (20 per call) → add phase stays short.
- **Script diff:** Only 1% add/remove calls; list + in-memory diff; adds batched → stays fast even at 50k.

---

## Final Recommendation for Sakura V2

**Use the Diff-Based PowerShell Script (`SakuraV2ADSync.ps1`).** Always.

Here is why in one paragraph:

> Sakura V2 is a production permission management system. Its users depend on correct, timely, and auditable access control. The diff-based script never empties a group, makes minimal Graph API calls, handles any group size with retry logic, writes per-user audit entries to `dbo.EventLog`, lives in the git repository with full change history, runs unattended via service principal, and costs nothing beyond a pipeline or VM to run on. Power Automate flows — whether full replace or diff-based — are not designed for this workload at production scale: they time out, hit iteration limits, can't paginate large groups automatically, can't retry Graph throttling properly, and are not version-controlled. The only time a flow is acceptable is as a temporary, small-scale, non-critical proof-of-concept run by a team with no access to run scripts.

---

*Document created: Sakura V2 Sync Strategy Comparison*  
*Covers: Full Replace (Script & Flow) + Diff-Based (Script & Flow)*
