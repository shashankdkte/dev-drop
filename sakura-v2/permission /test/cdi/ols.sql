/*
================================================================================
CDI — Step by step: (1) LM for all, (2) OLS for the 4 OLS-only requests only
================================================================================
Only 2 result sets. Nothing else.

  STEP 1 = LM approvers for ALL 15 requests (only ReqId, RequestedFor, LMApprover)
  STEP 2 = OLS only for the 4 OLS_only requests (ReqId 1,2,3,4): OLS info + OLS approver

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

-- 6 RLS_only
INSERT INTO #TestRequests (ReqId, RequestedFor, RequestType, ReportCode, AppCode, AudienceCode, EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy) VALUES
(5, 'Amit.Ambure@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default'),
(6, 'Andre.Andrade@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Americas', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(7, 'Angel.Dolla@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'EMEA', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(8, 'Angela.Johnson@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'APAC', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(9, 'Ben.Bartl@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default'),
(10, 'nitin.menon@dentsu.com', 'RLS_only', NULL, NULL, NULL, N'Americas', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default');

-- 5 Both
INSERT INTO #TestRequests (ReqId, RequestedFor, RequestType, ReportCode, AppCode, AudienceCode, EntityKey, EntityHierarchy, ClientKey, ClientHierarchy, SLKey, SLHierarchy) VALUES
(11, 'Abhinav.Gaurav@dentsu.com', 'Both', 'e571df46-5941-4339-b843-a76b6dcbae33', NULL, NULL, N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default'),
(12, 'Aditya.Singh2@dentsu.com', 'Both', NULL, 'CDIAPP', NULL, N'Americas', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(13, 'Aidan.Kennedy@dentsu.com', 'Both', NULL, NULL, 'CDIAPP-Test', N'EMEA', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(14, 'akansha.kothari@dentsu.com', 'Both', '006add22-eca6-4e0f-9a2b-0fac1fcda851', NULL, NULL, N'APAC', N'Region', N'All Clients', N'All Clients', N'Overall', N'Default'),
(15, 'Amit.Ambure@dentsu.com', 'Both', NULL, NULL, 'CDIAPP-CDI', N'Global', N'Global', N'All Clients', N'All Clients', N'Overall', N'Default');


-- =============================================================================
-- STEP 1 — LM approvers for ALL 15 requests. Only this. Nothing else.
-- =============================================================================
PRINT 'STEP 1: LM approvers (all 15 requests)';

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
    OLS.OLSApprovers
FROM #TestRequests r
OUTER APPLY (
    SELECT TOP (1) Approvers AS OLSApprovers, Source AS OLSSource, ItemCode AS OLSItemCode, ItemName AS OLSItemName FROM (
        -- Report: use report approvers; if null/empty, use approvers from linked audience (report -> ReportAppAudienceMap -> AppAudiences)
        SELECT COALESCE(NULLIF(RTRIM(wr.Approvers), N''),
            (SELECT TOP (1) au.Approvers FROM dbo.ReportAppAudienceMap raam INNER JOIN dbo.AppAudiences au ON raam.AppAudienceId = au.Id WHERE raam.ReportId = wr.Id AND au.IsActive = 1 AND au.Approvers IS NOT NULL AND RTRIM(au.Approvers) <> N'')) AS Approvers,
            'Report' AS Source, wr.ReportCode AS ItemCode, wr.ReportName AS ItemName
        FROM dbo.WorkspaceReports wr
        WHERE wr.WorkspaceId = @WorkspaceId AND wr.IsActive = 1 AND wr.ReportCode = r.ReportCode AND r.ReportCode IS NOT NULL
        UNION ALL
        SELECT wa.Approvers, 'App', wa.AppCode, wa.AppName
        FROM dbo.WorkspaceApps wa
        WHERE wa.WorkspaceId = @WorkspaceId AND wa.IsActive = 1 AND wa.AppCode = r.AppCode AND r.AppCode IS NOT NULL
        UNION ALL
        SELECT au.Approvers, 'Audience', au.AudienceCode, au.AudienceName
        FROM dbo.AppAudiences au
        INNER JOIN dbo.WorkspaceApps wa ON au.AppId = wa.Id AND wa.WorkspaceId = @WorkspaceId AND wa.IsActive = 1
        WHERE au.AudienceCode = r.AudienceCode AND au.IsActive = 1 AND r.AudienceCode IS NOT NULL
    ) u
) OLS
WHERE r.RequestType = 'OLS_only'
ORDER BY r.ReqId;

DROP TABLE IF EXISTS #TestRequests;
PRINT 'Done. 2 result sets: 1=LM all, 2=OLS 4 requests only.';
