/*
================================================================================
CDI — Step by step: (1) LM, (2) OLS, (3) RLS only
================================================================================
3 result sets. CDI RLS has ONE security type only (LoV Value = CDI, SecurityTypeLoVId in RLSCDIApprovers).

  STEP 1 = LM approvers for ALL 16 requests
  STEP 2 = OLS only for the 4 OLS_only requests (ReqId 1-4): OLS info + OLS approver
  STEP 3 = RLS only for the 7 RLS_only requests (ReqId 5-11): RLSCDIApprovers match on SecurityTypeLoVId (CDI only), Entity/Client/SL; Entity-only traversal (exact → parent → Global).

Requires: 0-Global, 1-CDI Script run first.
================================================================================
*/
SET NOCOUNT ON;

DECLARE @WorkspaceCode NVARCHAR(100) = N'CDI';
DECLARE @WorkspaceId INT = (SELECT Id FROM dbo.Workspaces WHERE WorkspaceCode = @WorkspaceCode AND IsActive = 1);

DROP TABLE IF EXISTS #TestRequests;
CREATE TABLE #TestRequests (
    ReqId INT NOT NULL PRIMARY KEY,
    RequestedFor NVARCHAR(255) NOT NULL,
    RequestType VARCHAR(20) NOT NULL,
    ReportCode NVARCHAR(100) NULL,
    AppCode NVARCHAR(100) NULL,
    AudienceCode NVARCHAR(100) NULL,
    EntityKey NVARCHAR(100) NULL,
    EntityHierarchy NVARCHAR(50) NULL,
    ClientKey NVARCHAR(100) NULL,
    ClientHierarchy NVARCHAR(50) NULL,
    SLKey NVARCHAR(100) NULL,
    SLHierarchy NVARCHAR(50) NULL
);

-- 4 OLS_only (ReqId 1-4)
INSERT INTO #TestRequests (ReqId, RequestedFor, RequestType, ReportCode, AppCode, AudienceCode, EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy) VALUES
(1, 'Abhinav.Gaurav@dentsu.com', 'OLS_only', 'e571df46-5941-4339-b843-a76b6dcbae33', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(2, 'Aditya.Singh2@dentsu.com', 'OLS_only', '006add22-eca6-4e0f-9a2b-0fac1fcda851', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 'Aidan.Kennedy@dentsu.com', 'OLS_only', NULL, 'CDIAPP', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(4, 'akansha.kothari@dentsu.com', 'OLS_only', NULL, NULL, 'CDIAPP-CDI', NULL, NULL, NULL, NULL, NULL, NULL);

-- 7 RLS_only: CDI has one security type (CDI). Varied Entity/Client/SL; Entity-only traversal.
INSERT INTO #TestRequests (ReqId, RequestedFor, RequestType, ReportCode, AppCode, AudienceCode, EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy) VALUES
(5, 'Amit.Ambure@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default'),
(6, 'Andre.Andrade@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Americas', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(7, 'Angel.Dolla@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'EMEA', N'Region', N'All Clients', N'All Clients', N'TotalPA', N'Default'),
(8, 'Angela.Johnson@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'APAC', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(9, 'Ben.Bartl@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Iberia', N'Cluster', N'All Clients', N'All Clients', N'Overall', N'Default'),
(10, 'nitin.menon@dentsu.com', 'RLS_only', NULL, NULL, NULL, NULL, NULL, N'All Clients', N'All Clients', N'Overall', N'Default'),
(11, 'Carol.McSwiney@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Global', N'Global', N'AJINOMOTO', N'Dentsu Stakeholder', N'TotalPA', N'Default');

-- 5 Both
INSERT INTO #TestRequests (ReqId, RequestedFor, RequestType, ReportCode, AppCode, AudienceCode, EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy) VALUES
(12, 'Abhinav.Gaurav@dentsu.com', 'Both', 'e571df46-5941-4339-b843-a76b6dcbae33', NULL, NULL, N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default'),
(13, 'Aditya.Singh2@dentsu.com', 'Both', NULL, 'CDIAPP', NULL, N'Americas', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(14, 'Aidan.Kennedy@dentsu.com', 'Both', NULL, NULL, 'CDIAPP-Test', N'EMEA', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(15, 'akansha.kothari@dentsu.com', 'Both', '006add22-eca6-4e0f-9a2b-0fac1fcda851', NULL, NULL, N'APAC', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(16, 'Amit.Ambure@dentsu.com', 'Both', NULL, NULL, 'CDIAPP-CDI', N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default');


-- =============================================================================
-- STEP 1 — LM approvers for ALL 16 requests. Only this. Nothing else.
-- =============================================================================
PRINT 'STEP 1: LM approvers (all 16 requests)';

SELECT
    r.ReqId,
    r.RequestedFor,
    r.RequestType,
    E.EmployeeParentEmail AS LMApprover
FROM #TestRequests r
LEFT JOIN refv.Employees E ON E.EmployeeEmail = r.RequestedFor
ORDER BY r.ReqId;


-- =============================================================================
-- STEP 2 — OLS only: just the 4 OLS_only requests (ReqId 1,2,3,4). Which report/app/audience + OLS approver.
-- For Report: if WorkspaceReports.Approvers is null/empty, use approvers from linked audience (ReportAppAudienceMap -> AppAudiences).
-- =============================================================================
PRINT 'STEP 2: OLS only — 4 requests; which Report/App/Audience + OLS approver (report uses linked-audience approvers if report has none)';

SELECT
    r.ReqId,
    r.RequestedFor,
    OLS.OLSSource,
    OLS.OLSItemCode,
    OLS.OLSItemName,
    OLS.OLSApprovers,
    COALESCE(OLS.OLSTraversal, N'Not found (no Report/App/Audience match for request)') AS OLSTraversal
FROM #TestRequests r
OUTER APPLY (
    SELECT TOP (1) Approvers AS OLSApprovers, Source AS OLSSource, ItemCode AS OLSItemCode, ItemName AS OLSItemName, Traversal AS OLSTraversal FROM (
        -- Report: use report approvers; if null/empty, use approvers from linked audience
        SELECT COALESCE(NULLIF(RTRIM(wr.Approvers), N''),
            (SELECT TOP (1) au.Approvers FROM dbo.ReportAppAudienceMap raam INNER JOIN dbo.AppAudiences au ON raam.AppAudienceId = au.Id WHERE raam.ReportId = wr.Id AND au.IsActive = 1 AND au.Approvers IS NOT NULL AND RTRIM(au.Approvers) <> N'')) AS Approvers,
            'Report' AS Source, wr.ReportCode AS ItemCode, wr.ReportName AS ItemName,
            CASE WHEN NULLIF(RTRIM(wr.Approvers), N'') IS NOT NULL THEN N'Report (direct)' ELSE N'Report (via linked audience)' END AS Traversal
        FROM dbo.WorkspaceReports wr
        WHERE wr.WorkspaceId = @WorkspaceId AND wr.IsActive = 1 AND wr.ReportCode = r.ReportCode AND r.ReportCode IS NOT NULL
        UNION ALL
        SELECT wa.Approvers, 'App', wa.AppCode, wa.AppName, N'App' AS Traversal
        FROM dbo.WorkspaceApps wa
        WHERE wa.WorkspaceId = @WorkspaceId AND wa.IsActive = 1 AND wa.AppCode = r.AppCode AND r.AppCode IS NOT NULL
        UNION ALL
        SELECT au.Approvers, 'Audience', au.AudienceCode, au.AudienceName, N'Audience' AS Traversal
        FROM dbo.AppAudiences au
        INNER JOIN dbo.WorkspaceApps wa ON au.AppId = wa.Id AND wa.WorkspaceId = @WorkspaceId AND wa.IsActive = 1
        WHERE au.AudienceCode = r.AudienceCode AND au.IsActive = 1 AND r.AudienceCode IS NOT NULL
    ) u
) OLS
WHERE r.RequestType = 'OLS_only'
ORDER BY r.ReqId;


-- =============================================================================
-- STEP 3 — RLS only: just the 7 RLS_only requests (ReqId 5-11). Varied Entity/Client/SL; one without entity.
-- Resolve: 1) Exact  2) Same Entity+Client, SL=Overall  3) Parent entity (traversal)  4) Parent entity SL=Overall
--          5) Global same Client/SL  6) Global same Client SL=Overall  7) Global All Clients+Overall (so EMEA/TotalPA and Global/AJINOMOTO/TotalPA get approvers).
-- =============================================================================
PRINT 'STEP 3: RLS only — 7 requests (Entity traversal + SL/Client fallback to Overall/All Clients)';

-- CDI Entity parent map: Market→Cluster→Region→Global (traversal keeps Client/SL; we also try SL=Overall and at Global try All Clients).
DROP TABLE IF EXISTS #CDIEntityParent;
CREATE TABLE #CDIEntityParent (
    EntityKey NVARCHAR(100) NOT NULL,
    EntityHierarchy NVARCHAR(50) NOT NULL,
    ParentEntityKey NVARCHAR(100) NOT NULL,
    ParentEntityHierarchy NVARCHAR(50) NOT NULL,
    PRIMARY KEY (EntityKey, EntityHierarchy)
);
INSERT INTO #CDIEntityParent (EntityKey, EntityHierarchy, ParentEntityKey, ParentEntityHierarchy) VALUES
(N'Iberia', N'Cluster', N'EMEA', N'Region'),
(N'Spain', N'Market', N'EMEA', N'Region'),
(N'Americas', N'Region', N'Global', N'Global'),
(N'EMEA', N'Region', N'Global', N'Global'),
(N'APAC', N'Region', N'Global', N'Global');

SELECT
    r.ReqId,
    r.RequestedFor,
    r.EntityKey,
    r.EntityHierarchy,
    r.ClientKey,
    r.ClientHierarchy,
    r.SLKey,
    RLS.RLSApprovers,
    COALESCE(RLS.RLSTraversal,
        CASE WHEN r.EntityKey IS NULL THEN N'Not found (no entity on request)'
             ELSE N'Not found (no row in RLSCDIApprovers for this Entity/Client/SL or fallbacks)' END) AS RLSTraversal
FROM #TestRequests r
OUTER APPLY (
    -- CDI RLS: one security type (CDI). Order: 1) Exact  2) Same Entity+Client, SL=Overall  ... 7) Global All Clients+Overall.
    SELECT TOP (1) x.Approvers AS RLSApprovers, x.Traversal AS RLSTraversal
    FROM (
        SELECT 1 AS ord, a.Approvers, N'Exact' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND (a.EntityKey = r.EntityKey OR (a.EntityKey IS NULL AND r.EntityKey IS NULL))
          AND (a.EntityHierarchy = r.EntityHierarchy OR (a.EntityHierarchy IS NULL AND r.EntityHierarchy IS NULL))
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = r.SLKey OR (a.SLKey IS NULL AND r.SLKey IS NULL))
          AND (a.SLHierarchy = r.SLHierarchy OR (a.SLHierarchy IS NULL AND r.SLHierarchy IS NULL))
        UNION ALL
        -- Same Entity+Client, SL = Overall (table has mostly Overall; e.g. EMEA/Region/TotalPA -> EMEA/Region/Overall)
        SELECT 2 AS ord, a.Approvers, N'Same Entity+Client, SL=Overall' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND r.EntityKey IS NOT NULL AND r.EntityHierarchy IS NOT NULL
          AND (a.EntityKey = r.EntityKey OR (a.EntityKey IS NULL AND r.EntityKey IS NULL))
          AND (a.EntityHierarchy = r.EntityHierarchy OR (a.EntityHierarchy IS NULL AND r.EntityHierarchy IS NULL))
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = N'Overall' OR (a.SLKey IS NULL)) AND (a.SLHierarchy = N'Default' OR (a.SLHierarchy IS NULL))
        UNION ALL
        -- Traversal: parent entity (same Client/SL)
        SELECT 3 AS ord, a.Approvers, N'Parent entity (traversal)' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        INNER JOIN #CDIEntityParent p ON p.EntityKey = r.EntityKey AND p.EntityHierarchy = r.EntityHierarchy
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND a.EntityKey = p.ParentEntityKey AND a.EntityHierarchy = p.ParentEntityHierarchy
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = r.SLKey OR (a.SLKey IS NULL AND r.SLKey IS NULL))
          AND (a.SLHierarchy = r.SLHierarchy OR (a.SLHierarchy IS NULL AND r.SLHierarchy IS NULL))
        UNION ALL
        -- Parent entity, same Client, SL = Overall
        SELECT 4 AS ord, a.Approvers, N'Parent entity, SL=Overall' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        INNER JOIN #CDIEntityParent p ON p.EntityKey = r.EntityKey AND p.EntityHierarchy = r.EntityHierarchy
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND a.EntityKey = p.ParentEntityKey AND a.EntityHierarchy = p.ParentEntityHierarchy
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = N'Overall' OR (a.SLKey IS NULL)) AND (a.SLHierarchy = N'Default' OR (a.SLHierarchy IS NULL))
        UNION ALL
        -- Global/Global same Client/SL
        SELECT 5 AS ord, a.Approvers, N'Global same Client/SL' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND r.EntityKey IS NOT NULL AND r.EntityHierarchy IS NOT NULL
          AND a.EntityKey = N'Global' AND a.EntityHierarchy = N'Global'
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = r.SLKey OR (a.SLKey IS NULL AND r.SLKey IS NULL))
          AND (a.SLHierarchy = r.SLHierarchy OR (a.SLHierarchy IS NULL AND r.SLHierarchy IS NULL))
        UNION ALL
        -- Global/Global same Client, SL = Overall
        SELECT 6 AS ord, a.Approvers, N'Global same Client, SL=Overall' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND r.EntityKey IS NOT NULL AND r.EntityHierarchy IS NOT NULL
          AND a.EntityKey = N'Global' AND a.EntityHierarchy = N'Global'
          AND (a.ClientKey = r.ClientKey OR (a.ClientKey IS NULL AND r.ClientKey IS NULL))
          AND (a.ClientHierarchy = r.ClientHierarchy OR (a.ClientHierarchy IS NULL AND r.ClientHierarchy IS NULL))
          AND (a.SLKey = N'Overall' OR (a.SLKey IS NULL)) AND (a.SLHierarchy = N'Default' OR (a.SLHierarchy IS NULL))
        UNION ALL
        -- Global/Global All Clients, Overall (final fallback when request has specific Client/SL not in table, e.g. AJINOMOTO/TotalPA)
        SELECT 7 AS ord, a.Approvers, N'Global All Clients+Overall' AS Traversal
        FROM dbo.RLSCDIApprovers a
        INNER JOIN dbo.WorkspaceSecurityModels SM ON a.SecurityModelId = SM.Id
        INNER JOIN dbo.LoVs L ON a.SecurityTypeLoVId = L.Id AND L.LoVType = 'SecurityType' AND L.LoVValue = N'CDI'
        WHERE SM.SecurityModelCode = 'CDI-Default'
          AND r.EntityKey IS NOT NULL AND r.EntityHierarchy IS NOT NULL
          AND a.EntityKey = N'Global' AND a.EntityHierarchy = N'Global'
          AND (a.ClientKey = N'All Clients' OR (a.ClientKey IS NULL)) AND (a.ClientHierarchy = N'All Clients' OR (a.ClientHierarchy IS NULL))
          AND (a.SLKey = N'Overall' OR (a.SLKey IS NULL)) AND (a.SLHierarchy = N'Default' OR (a.SLHierarchy IS NULL))
    ) x
    ORDER BY x.ord
) RLS
WHERE r.RequestType = 'RLS_only'
ORDER BY r.ReqId;


DROP TABLE IF EXISTS #TestRequests;
DROP TABLE IF EXISTS #CDIEntityParent;
PRINT 'Done. 3 result sets: 1=LM all (16), 2=OLS 4, 3=RLS 7 (CDI single security type + Entity traversal).';
