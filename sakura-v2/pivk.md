# Backend pre-commit change summary (git review)

Source: `git status` / `git diff` under `BE_Main/Sakura_Backend`. **No commit was performed.**

---

## `GetUserProfileRequest.cs`

Adds boolean `IncludeHistorical` so clients can request profile/access data that includes revoked headers and related history, not only “active” approved paths. Default `false` preserves the previous strict filtering behaviour for existing callers. Property includes an XML summary for API documentation.

## `UserAccessResponse.cs`

OLS and RLS DTOs now carry approval/revoke timestamps and actors, request/header status enums, `ReportDeliveryMethod` on standalone report rows, and `SecurityModelName` on RLS rows. Imports `static Dentsu.Sakura.Domain.Enums` for those enum types. Leading UTF-8 BOM removed (encoding-only change on first line).

## `UserProfileService.cs`

`GetApprovedAccessAsync` branches on `IncludeHistorical` for which permission requests and headers are included (revoked included only when historical is requested; cancelled stays out). Populates the new response fields from loaded entities and post-queries workspace objects to fill report/audience/app names, delivery method, and security model names. Deduplication/grouping logic remains after enrichment so list shape stays stable.

## `IEventLogService.cs`

Declares `GetWorkspaceEventLogsAsync(int workspaceId, CancellationToken)` returning the same list wrapper type as existing event-log queries. XML summary documents which entity tables are scoped to the workspace. BOM removed from file start.

## `EventLogService.cs`

Implements workspace-scoped audit: collects IDs for permission requests, reports, apps, and security models in that workspace, then filters `RomvEventLog` by `TableName`/`RecordId` plus workspace row itself. Orders by `EventTriggeredAt` descending and projects to `RomvEventLogResponse`. BOM removed from file start.

## `CommonController.cs` (`EventLogController`)

Adds `GET api/EventLog/workspace/{workspaceId}` calling `GetWorkspaceEventLogsAsync` with cancellation token support. Swagger operation id `Get[controller]ByWorkspace` follows existing attribute style. No change to `GET api/EventLog/{recordId}/{tablename}`.

## `IocContainerConfiguration.cs`

Adds `using Dentsu.Sakura.Application.Services.Catalogue` and `services.AddScoped<ICatalogueService, CatalogueService>()`. Required so `CatalogueController` resolves at runtime. No other services altered in this diff.

## `ReportAppAudienceMapResponse.cs`

No functional change in the reviewed diff. UTF-8 BOM removed at the first line only.

## `ReportAppAudienceMapService.cs`

No functional change in the reviewed diff. UTF-8 BOM removed at the first line only.

## `CatalogueSearchResponse.cs` (untracked)

New response type for catalogue listing: ids, workspace context, report metadata, `ReportDeliveryMethod`, keywords, `IsActive`. Maps directly from joined `WorkspaceReport` and `Workspace` query in the service. File must be `git add`’d with the catalogue feature.

## `ICatalogueService.cs` (untracked)

Defines `SearchAsync(keyword, workspaceId, deliveryMethod)` returning `IApiListResult<CatalogueSearchResponse>`. Documents keyword and filter semantics in interface comments. Lives under `Services/Catalogue`.

## `CatalogueService.cs` (untracked)

Queries active reports in active workspaces; optional case-insensitive keyword across name, description, keywords, and workspace name. Applies optional workspace and delivery-method filters, orders by workspace then report name, returns `ApiListResult`. Uses `ISakuraUnitOfWork` repositories only—no new infrastructure types.

## `CatalogueController.cs` (untracked)

`GET api/Catalogue/search` with query params `keyword`, `workspaceId`, `deliveryMethod` and Swagger summary for the report catalogue use case. Delegates to `ICatalogueService.SearchAsync`. Untracked until staged.

---

## Parent repo `BE_Main/` at Sakura root (separate from nested backend repo)

`git status` at repo root also shows new AD sync scripts, log files, and `Sakura_Backend` / `Sakura_Backend - Copy`—treat as ops/artefacts unless you intend them in the same commit as the API. Confirm `.gitignore` for `*.log` and duplicate backend folders before committing the monorepo.
