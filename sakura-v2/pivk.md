# Backend pre-commit change summary (git review)

Source: `git status` / `git diff` under `BE_Main/Sakura_Backend`. **No commit was performed.**

For backend developers: each section below has **What changed** (facts from the diff) and **Why** (intent, gaps in existing APIs, and who/what drove the change).

---

## `GetUserProfileRequest.cs`

**What changed:** Adds boolean `IncludeHistorical` so clients can request profile/access data that includes revoked headers and related history, not only “active” approved paths. Default `false` preserves the previous strict filtering behaviour for existing callers. Property includes an XML summary for API documentation.

**Why:** The user-access/profile surface already existed, but it only described *current* effective access. Product and support need a “what did this user have, including what was later revoked?” view without breaking existing consumers that expect the tighter filter. A single flag keeps one contract instead of duplicating an entire endpoint for “full history.”

---

## `UserAccessResponse.cs`

**What changed:** OLS and RLS DTOs now carry approval/revoke timestamps and actors, request/header status enums, `ReportDeliveryMethod` on standalone report rows, and `SecurityModelName` on RLS rows. Imports `static Dentsu.Sakura.Domain.Enums` for those enum types. Leading UTF-8 BOM removed (encoding-only change on first line).

**Why:** The old payload was too thin for the profile and object-access UIs: they could not show when access was granted/revoked, SAR vs AUR, or a readable security model name. Frontend was falling back to placeholders (e.g. “Report #n”). These fields align the API with what the UI already needs to render accurately and to honour `IncludeHistorical` when enabled.

---

## `UserProfileService.cs`

**What changed:** `GetApprovedAccessAsync` branches on `IncludeHistorical` for which permission requests and headers are included (revoked included only when historical is requested; cancelled stays out). Populates the new response fields from loaded entities and post-queries workspace objects to fill report/audience/app names, delivery method, and security model names. Deduplication/grouping logic remains after enrichment so list shape stays stable.

**Why:** Behaviour stays in the service layer so all callers of the same access-building path get consistent rules (who sees revoked rows, how headers are filtered). The extra lookups fix display gaps that raw OLS/RLS rows alone could not solve without N+1 or client-side guessing. This is the implementation behind the request/response extensions above—not a parallel code path.

---

## `IEventLogService.cs`

**What changed:** Declares `GetWorkspaceEventLogsAsync(int workspaceId, CancellationToken)` returning the same list wrapper type as existing event-log queries. XML summary documents which entity tables are scoped to the workspace. BOM removed from file start.

**Why:** The interface must expose the new capability so controllers and tests can depend on a clear contract, matching how `GetEventLogsAsync` is already abstracted.

---

## `EventLogService.cs`

**What changed:** Implements workspace-scoped audit: collects IDs for permission requests, reports, apps, and security models in that workspace, then filters `RomvEventLog` by `TableName`/`RecordId` plus workspace row itself. Orders by `EventTriggeredAt` descending and projects to `RomvEventLogResponse`. BOM removed from file start.

**Why:** Existing `GetEventLogsAsync(recordId, tablename)` only answers “what happened to *this one row* in *this table*.” A workspace-level activity view would otherwise require the client to discover every related record id and call the API many times, or to guess table names. One aggregated query matches a single workspace audit timeline in the product.

---

## `CommonController.cs` (`EventLogController`)

**What changed:** Adds `GET api/EventLog/workspace/{workspaceId}` calling `GetWorkspaceEventLogsAsync` with cancellation token support. Swagger operation id `Get[controller]ByWorkspace` follows existing attribute style. No change to `GET api/EventLog/{recordId}/{tablename}`.

**Why:** We deliberately **did not** replace the per-record endpoint—downstream tools and detail screens still need pinpoint logs by `recordId` + `tablename`. The new route is additive: same `RomvEventLog` data model, different slice (workspace-wide). That separation keeps backward compatibility and avoids overloading the old route with optional parameters that would be awkward and harder to secure or cache.

---

## `IocContainerConfiguration.cs`

**What changed:** Adds `using Dentsu.Sakura.Application.Services.Catalogue` and `services.AddScoped<ICatalogueService, CatalogueService>()`. Required so `CatalogueController` resolves at runtime. No other services altered in this diff.

**Why:** Any new controller-facing service must be registered; without this, the app fails at first request to `CatalogueController` with a DI resolution error.

---

## `ReportAppAudienceMapResponse.cs`

**What changed:** No functional change in the reviewed diff. UTF-8 BOM removed at the first line only.

**Why:** BOM-normalisation avoids inconsistent diffs across editors and keeps files aligned with typical .NET repo settings (often UTF-8 without BOM).

---

## `ReportAppAudienceMapService.cs`

**What changed:** No functional change in the reviewed diff. UTF-8 BOM removed at the first line only.

**Why:** Same as above—encoding consistency; no behavioural intent.

---

## `CatalogueSearchResponse.cs` (untracked)

**What changed:** New response type for catalogue listing: ids, workspace context, report metadata, `ReportDeliveryMethod`, keywords, `IsActive`. Maps directly from joined `WorkspaceReport` and `Workspace` query in the service. File must be `git add`’d with the catalogue feature.

**Why:** Dedicated DTO keeps the catalogue read model stable even if workspace/report entities grow; callers get only what the catalogue screen needs.

---

## `ICatalogueService.cs` (untracked)

**What changed:** Defines `SearchAsync(keyword, workspaceId, deliveryMethod)` returning `IApiListResult<CatalogueSearchResponse>`. Documents keyword and filter semantics in interface comments. Lives under `Services/Catalogue`.

**Why:** Follows the same pattern as other application services (interface + implementation + controller) for testability and Swashbuckle-friendly layering.

---

## `CatalogueService.cs` (untracked)

**What changed:** Queries active reports in active workspaces; optional case-insensitive keyword across name, description, keywords, and workspace name. Applies optional workspace and delivery-method filters, orders by workspace then report name, returns `ApiListResult`. Uses `ISakuraUnitOfWork` repositories only—no new infrastructure types.

**Why:** Report data already exists under per-workspace APIs, but a **report catalogue** needs a **cross-workspace** search and filter in one round trip (keyword + optional workspace + SAR/AUR). Reusing generic workspace-report endpoints would push heavy fan-out and merging to the client or BFF; a single query keeps paging/filter semantics server-side and simpler for the catalogue UI.

---

## `CatalogueController.cs` (untracked)

**What changed:** `GET api/Catalogue/search` with query params `keyword`, `workspaceId`, `deliveryMethod` and Swagger summary for the report catalogue use case. Delegates to `ICatalogueService.SearchAsync`. Untracked until staged.

**Why:** A distinct resource (`Catalogue`) signals a different product capability from “CRUD this workspace’s report”—clear routing, auth policies later if needed, and documentation that does not overload existing workspace controllers.

---

## Parent repo `BE_Main/` at Sakura root (separate from nested backend repo)

**What changed:** `git status` at repo root also shows new AD sync scripts, log files, and `Sakura_Backend` / `Sakura_Backend - Copy`—treat as ops/artefacts unless you intend them in the same commit as the API.

**Why:** Those paths are outside the nested `Sakura_Backend` git history; backend API reviewers can ignore them unless the monorepo commit intentionally bundles ops scripts (and should avoid committing noise logs or duplicate folders).
