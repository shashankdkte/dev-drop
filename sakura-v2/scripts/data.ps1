# ============================================================
# Export-Sakura-DB-Metadata.ps1
# Exports Sakura database metadata to CSV files (00-21)
# matching exactly the files present in SakuraV1/Sakura_DB_Metadata
# ============================================================

param(
    [string]$ServerName   = "azeuw1senmastersvrdb01.database.windows.net",
    [string]$DatabaseName = "SakuraV2",
    [string]$Username     = "SakuraAppAdmin",
    [string]$OutputPath   = "C:\Sakura_DB_Metadata_V2"
)

$SecurePassword = Read-Host "Enter SQL Password" -AsSecureString
if (-not $SecurePassword -or $SecurePassword.Length -eq 0) {
    Write-Error "Password cannot be empty."
    exit 1
}
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
try {
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
$ConnStr = "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;"

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

function Export-Q {
    param([string]$Query, [string]$FileName)
    try {
        Invoke-Sqlcmd -ConnectionString $ConnStr -Query $Query -QueryTimeout 120 |
            Export-Csv "$OutputPath\$FileName" -NoTypeInformation -Encoding UTF8
        Write-Host "  [OK] $FileName"
    }
    catch {
        Write-Warning "  [FAIL] $FileName - $_"
    }
}

Write-Host ""
Write-Host "=== Sakura DB Metadata Export ===" -ForegroundColor Cyan
Write-Host "Server : $ServerName"
Write-Host "DB     : $DatabaseName"
Write-Host "Output : $OutputPath"
Write-Host ""

# ============================================================
# 00 — Database Info
# ============================================================
Export-Q "
SELECT
    DB_NAME()                                              AS database_name,
    @@SERVERNAME                                           AS server_name,
    DATABASEPROPERTYEX(DB_NAME(),'Collation')              AS collation,
    DATABASEPROPERTYEX(DB_NAME(),'Recovery')               AS recovery_model,
    DATABASEPROPERTYEX(DB_NAME(),'Status')                 AS status,
    DATABASEPROPERTYEX(DB_NAME(),'Updateability')          AS updateability
" "00_DatabaseInfo.csv"

# ============================================================
# 01 — Schemas
# ============================================================
Export-Q "
SELECT schema_id, name AS schema_name
FROM sys.schemas
ORDER BY schema_id
" "01_Schemas.csv"

# ============================================================
# 02 — Tables  (schema_name, table_name, create_date, modify_date, row_count)
# ============================================================
Export-Q "
SELECT
    s.name          AS schema_name,
    t.name          AS table_name,
    t.create_date,
    t.modify_date,
    p.rows          AS row_count
FROM sys.tables t
INNER JOIN sys.schemas    s ON t.schema_id = s.schema_id
LEFT  JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name
" "02_Tables.csv"

# ============================================================
# 03 — Table Columns (full — matches V1 03_TableColumns.csv)
# ============================================================
Export-Q "
SELECT
    s.name                                         AS schema_name,
    t.name                                         AS table_name,
    c.column_id,
    c.name                                         AS column_name,
    ty.name                                        AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    OBJECT_DEFINITION(c.default_object_id)         AS computed_definition,
    dc.definition                                  AS default_definition,
    c.collation_name
FROM sys.tables  t
INNER JOIN sys.schemas  s  ON t.schema_id       = s.schema_id
INNER JOIN sys.columns  c  ON t.object_id       = c.object_id
INNER JOIN sys.types    ty ON c.user_type_id    = ty.user_type_id
LEFT  JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name, c.column_id
" "03_TableColumns.csv"

# ============================================================
# 04 — Primary Keys  (schema_name, table_name, pk_name, key_ordinal, column_name)
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    t.name      AS table_name,
    pk.name     AS pk_name,
    ic.key_ordinal,
    c.name      AS column_name
FROM sys.key_constraints pk
INNER JOIN sys.tables         t  ON pk.parent_object_id = t.object_id
INNER JOIN sys.schemas        s  ON t.schema_id          = s.schema_id
INNER JOIN sys.index_columns  ic ON pk.parent_object_id  = ic.object_id
                                 AND pk.unique_index_id   = ic.index_id
INNER JOIN sys.columns        c  ON ic.object_id = c.object_id
                                 AND ic.column_id = c.column_id
WHERE pk.type = 'PK'
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name, ic.key_ordinal
" "04_PrimaryKeys.csv"

# ============================================================
# 05 — Foreign Keys
# ============================================================
Export-Q "
SELECT
    s.name   AS schema_name,
    t.name   AS table_name,
    fk.name  AS fk_name,
    fkc.constraint_column_id AS ordinal,
    c.name   AS column_name,
    rs.name  AS ref_schema,
    rt.name  AS ref_table,
    rc.name  AS ref_column,
    CASE fk.delete_referential_action
        WHEN 0 THEN 'NO_ACTION' WHEN 1 THEN 'CASCADE'
        WHEN 2 THEN 'SET_NULL'  WHEN 3 THEN 'SET_DEFAULT' END AS on_delete,
    CASE fk.update_referential_action
        WHEN 0 THEN 'NO_ACTION' WHEN 1 THEN 'CASCADE'
        WHEN 2 THEN 'SET_NULL'  WHEN 3 THEN 'SET_DEFAULT' END AS on_update
FROM sys.foreign_keys         fk
INNER JOIN sys.tables             t   ON fk.parent_object_id        = t.object_id
INNER JOIN sys.schemas            s   ON t.schema_id                = s.schema_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id             = fkc.constraint_object_id
INNER JOIN sys.columns             c   ON fkc.parent_object_id      = c.object_id
                                       AND fkc.parent_column_id     = c.column_id
INNER JOIN sys.tables              rt  ON fkc.referenced_object_id  = rt.object_id
INNER JOIN sys.schemas             rs  ON rt.schema_id              = rs.schema_id
INNER JOIN sys.columns             rc  ON fkc.referenced_object_id  = rc.object_id
                                       AND fkc.referenced_column_id = rc.column_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name, fk.name, fkc.constraint_column_id
" "05_ForeignKeys.csv"

# ============================================================
# 06 — Indexes  (schema_name, table_name, index_name, type_desc, is_unique, is_primary_key, is_disabled, fill_factor)
# ============================================================
Export-Q "
SELECT
    s.name          AS schema_name,
    t.name          AS table_name,
    i.name          AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_disabled,
    i.fill_factor
FROM sys.indexes i
INNER JOIN sys.tables  t ON i.object_id  = t.object_id
INNER JOIN sys.schemas s ON t.schema_id  = s.schema_id
WHERE i.type > 0
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name, i.name
" "06_Indexes.csv"

# ============================================================
# 07 — Index Columns  (schema_name, table_name, index_name, key_ordinal, index_column_id, column_name, is_descending_key, is_included_column)
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    t.name      AS table_name,
    i.name      AS index_name,
    ic.key_ordinal,
    ic.index_column_id,
    c.name      AS column_name,
    ic.is_descending_key,
    ic.is_included_column
FROM sys.index_columns ic
INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN sys.tables  t ON i.object_id  = t.object_id
INNER JOIN sys.schemas s ON t.schema_id  = s.schema_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.type > 0
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, t.name, i.name, ic.key_ordinal
" "07_IndexColumns.csv"

# ============================================================
# 08 — Views
# ============================================================
Export-Q "
SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.create_date,
    v.modify_date
FROM sys.views   v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, v.name
" "08_Views.csv"

# ============================================================
# 09 — View Columns  (schema_name, view_name, column_id, column_name, data_type, max_length, precision, scale, is_nullable)
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    v.name      AS view_name,
    c.column_id,
    c.name      AS column_name,
    ty.name     AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.views   v
INNER JOIN sys.schemas s  ON v.schema_id     = s.schema_id
INNER JOIN sys.columns c  ON v.object_id     = c.object_id
INNER JOIN sys.types   ty ON c.user_type_id  = ty.user_type_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, v.name, c.column_id
" "09_ViewColumns.csv"

# ============================================================
# 10 — View Definitions
# ============================================================
Export-Q "
SELECT
    s.name                             AS schema_name,
    v.name                             AS view_name,
    OBJECT_DEFINITION(v.object_id)    AS definition
FROM sys.views   v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, v.name
" "10_ViewDefinitions.csv"

# ============================================================
# 11 — Stored Procedures
# ============================================================
Export-Q "
SELECT
    s.name AS schema_name,
    p.name AS procedure_name,
    p.create_date,
    p.modify_date
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, p.name
" "11_StoredProcedures.csv"

# ============================================================
# 12 — Stored Procedure Parameters  (schema_name, procedure_name, parameter_name, data_type, max_length, is_output)
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    p.name      AS procedure_name,
    pr.name     AS parameter_name,
    ty.name     AS data_type,
    pr.max_length,
    pr.is_output
FROM sys.parameters  pr
INNER JOIN sys.procedures p  ON pr.object_id     = p.object_id
INNER JOIN sys.schemas    s  ON p.schema_id      = s.schema_id
INNER JOIN sys.types      ty ON pr.user_type_id  = ty.user_type_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, p.name, pr.parameter_id
" "12_StoredProcedureParameters.csv"

# ============================================================
# 13 — Stored Procedure Definitions
# ============================================================
Export-Q "
SELECT
    s.name                             AS schema_name,
    p.name                             AS procedure_name,
    OBJECT_DEFINITION(p.object_id)    AS definition
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE s.name NOT IN ('sys','information_schema')
ORDER BY s.name, p.name
" "13_StoredProcedureDefinitions.csv"

# ============================================================
# 14 — Functions
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    o.name      AS function_name,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects o
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('FN','IF','TF')
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, o.name
" "14_Functions.csv"

# ============================================================
# 15 — Function Parameters  (schema_name, function_name, parameter_id, parameter_name, data_type, max_length, precision, scale)
# ============================================================
Export-Q "
SELECT
    s.name      AS schema_name,
    o.name      AS function_name,
    pr.parameter_id,
    pr.name     AS parameter_name,
    ty.name     AS data_type,
    pr.max_length,
    pr.precision,
    pr.scale
FROM sys.parameters pr
INNER JOIN sys.objects o  ON pr.object_id     = o.object_id
INNER JOIN sys.schemas s  ON o.schema_id      = s.schema_id
INNER JOIN sys.types   ty ON pr.user_type_id  = ty.user_type_id
WHERE o.type IN ('FN','IF','TF')
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, o.name, pr.parameter_id
" "15_FunctionParameters.csv"

# ============================================================
# 16 — Function Definitions
# ============================================================
Export-Q "
SELECT
    s.name                             AS schema_name,
    o.name                             AS function_name,
    OBJECT_DEFINITION(o.object_id)    AS definition
FROM sys.objects o
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('FN','IF','TF')
  AND s.name NOT IN ('sys','information_schema')
ORDER BY s.name, o.name
" "16_FunctionDefinitions.csv"

# ============================================================
# 17 — Triggers  (trigger_schema, trigger_name, parent_schema, parent_object, create_date, modify_date, is_disabled, is_instead_of_trigger, parent_class_desc)
# ============================================================
Export-Q "
SELECT
    s.name          AS trigger_schema,
    tr.name         AS trigger_name,
    ps.name         AS parent_schema,
    po.name         AS parent_object,
    tr.create_date,
    tr.modify_date,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    tr.parent_class_desc
FROM sys.triggers tr
INNER JOIN sys.objects po   ON tr.parent_id   = po.object_id
INNER JOIN sys.schemas ps   ON po.schema_id   = ps.schema_id
INNER JOIN sys.objects o_tr ON tr.object_id  = o_tr.object_id
INNER JOIN sys.schemas s   ON o_tr.schema_id = s.schema_id
WHERE tr.parent_class_desc = 'OBJECT_OR_COLUMN'
ORDER BY s.name, tr.name
" "17_Triggers.csv"

# ============================================================
# 18 — Trigger Definitions
# ============================================================
Export-Q "
SELECT
    s.name                              AS trigger_schema,
    tr.name                             AS trigger_name,
    OBJECT_DEFINITION(tr.object_id)    AS definition
FROM sys.triggers tr
INNER JOIN sys.objects po   ON tr.parent_id   = po.object_id
INNER JOIN sys.objects o_tr ON tr.object_id  = o_tr.object_id
INNER JOIN sys.schemas s   ON o_tr.schema_id = s.schema_id
WHERE tr.parent_class_desc = 'OBJECT_OR_COLUMN'
ORDER BY s.name, tr.name
" "18_TriggerDefinitions.csv"

# ============================================================
# 19 — Synonyms
# ============================================================
Export-Q "
SELECT
    s.name          AS schema_name,
    sy.name         AS synonym_name,
    sy.base_object_name,
    sy.create_date,
    sy.modify_date
FROM sys.synonyms sy
INNER JOIN sys.schemas s ON sy.schema_id = s.schema_id
ORDER BY s.name, sy.name
" "19_Synonyms.csv"

# ============================================================
# 20 — User Defined Types
# ============================================================
Export-Q "
SELECT
    s.name          AS schema_name,
    t.name          AS type_name,
    bt.name         AS base_type,
    t.max_length,
    t.precision,
    t.scale,
    t.is_nullable,
    t.is_user_defined,
    t.is_assembly_type
FROM sys.types t
INNER JOIN sys.schemas s  ON t.schema_id      = s.schema_id
INNER JOIN sys.types   bt ON t.system_type_id = bt.user_type_id
WHERE t.is_user_defined = 1
ORDER BY s.name, t.name
" "20_UserDefinedTypes.csv"

# ============================================================
# 21 — Sequences  (schema_name, sequence_name, data_type, start_value, increment, minimum_value, maximum_value, is_cycling)
# ============================================================
Export-Q "
SELECT
    s.name          AS schema_name,
    seq.name        AS sequence_name,
    t.name          AS data_type,
    seq.start_value,
    seq.increment,
    seq.minimum_value,
    seq.maximum_value,
    seq.is_cycling
FROM sys.sequences seq
INNER JOIN sys.schemas s ON seq.schema_id    = s.schema_id
INNER JOIN sys.types   t ON seq.user_type_id = t.user_type_id
ORDER BY s.name, seq.name
" "21_Sequences.csv"

# ============================================================
Write-Host ""
Write-Host "=== Export complete ===" -ForegroundColor Green
Write-Host "Files written to: $OutputPath"
Write-Host ""
Write-Host "Files produced (00-21, matching SakuraV1/Sakura_DB_Metadata):"
Get-ChildItem "$OutputPath\*.csv" | Sort-Object Name | ForEach-Object {
    $rows = (Import-Csv $_.FullName | Measure-Object).Count
    Write-Host ("  {0,-40} {1,6} rows" -f $_.Name, $rows)
}
