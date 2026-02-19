-- ============================================================
-- SQL SERVER TO RDF EXPORT STRATEGY
-- ============================================================
-- Optimized for TARQL/SPARQL-ANYWHERE conversion
-- Based on HR Database SHACL specification
-- ============================================================

USE HumanResources;
GO

-- ============================================================
-- OPTION 1: CSV EXPORT (RECOMMENDED FOR TARQL)
-- ============================================================
-- Most efficient for row-by-row transformation
-- Smallest file size, fastest parsing

-- Enable xp_cmdshell (if needed - requires sysadmin)
-- sp_configure 'show advanced options', 1;
-- RECONFIGURE;
-- sp_configure 'xp_cmdshell', 1;
-- RECONFIGURE;

-- Export script for all tables
DECLARE @ExportPath NVARCHAR(500) = 'C:\exports\hr\';
DECLARE @SQL NVARCHAR(MAX);

-- Export Departments
SET @SQL = 'bcp "SELECT 
    DepartmentID,
    DepartmentName,
    DepartmentCode,
    ManagerEmployeeID,
    Budget,
    CONVERT(VARCHAR(23), CreatedDate, 126) AS CreatedDate,
    CONVERT(VARCHAR(23), ModifiedDate, 126) AS ModifiedDate
FROM HumanResources.dbo.Departments" queryout "' + @ExportPath + 'departments.csv" -c -t, -T -S ' + @@SERVERNAME;
EXEC xp_cmdshell @SQL;

-- Export Employees (with ISO date formatting)
SET @SQL = 'bcp "SELECT 
    EmployeeID,
    FirstName,
    LastName,
    MiddleName,
    Email,
    Phone,
    CONVERT(VARCHAR(10), DateOfBirth, 23) AS DateOfBirth,
    CONVERT(VARCHAR(10), HireDate, 23) AS HireDate,
    CONVERT(VARCHAR(10), TerminationDate, 23) AS TerminationDate,
    EmployeeStatus,
    SSN,
    Address,
    City,
    State,
    ZipCode,
    EmergencyContactName,
    EmergencyContactPhone,
    CONVERT(VARCHAR(23), CreatedDate, 126) AS CreatedDate,
    CONVERT(VARCHAR(23), ModifiedDate, 126) AS ModifiedDate
FROM HumanResources.dbo.Employees" queryout "' + @ExportPath + 'employees.csv" -c -t, -T -S ' + @@SERVERNAME;
EXEC xp_cmdshell @SQL;

PRINT 'CSV exports completed to: ' + @ExportPath;

-- ============================================================
-- OPTION 2: JSON EXPORT (FOR NESTED STRUCTURES)
-- ============================================================
-- Better for related data, hierarchical structures
-- SPARQL-ANYWHERE can consume directly

-- Export with relationships (JSON)
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.Email,
    e.HireDate,
    (
        SELECT 
            ep.EmployeePositionID,
            ep.StartDate,
            ep.EndDate,
            ep.IsCurrent,
            (
                SELECT 
                    d.DepartmentID,
                    d.DepartmentName,
                    d.DepartmentCode
                FROM Departments d
                WHERE d.DepartmentID = ep.DepartmentID
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) AS Department,
            (
                SELECT 
                    p.PositionID,
                    p.PositionTitle,
                    p.PositionCode,
                    p.JobLevel
                FROM Positions p
                WHERE p.PositionID = ep.PositionID
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) AS Position
        FROM EmployeePositions ep
        WHERE ep.EmployeeID = e.EmployeeID
        FOR JSON PATH
    ) AS Positions,
    (
        SELECT 
            s.SalaryID,
            s.SalaryAmount,
            s.SalaryType,
            s.EffectiveDate,
            s.EndDate
        FROM Salaries s
        WHERE s.EmployeeID = e.EmployeeID
        FOR JSON PATH
    ) AS SalaryHistory
FROM Employees e
WHERE e.EmployeeStatus = 'Active'
FOR JSON PATH, ROOT('employees');

-- ============================================================
-- OPTION 3: STORED PROCEDURE FOR BATCH EXPORT
-- ============================================================

IF OBJECT_ID('dbo.sp_ExportTableToCSV', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ExportTableToCSV;
GO

CREATE PROCEDURE dbo.sp_ExportTableToCSV
    @TableName NVARCHAR(128),
    @ExportPath NVARCHAR(500),
    @IncludeHeaders BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnList NVARCHAR(MAX);
    DECLARE @FileName NVARCHAR(500);
    
    -- Build column list with date formatting
    SELECT @ColumnList = STRING_AGG(
        CASE 
            WHEN DATA_TYPE IN ('datetime', 'datetime2', 'smalldatetime') 
                THEN 'CONVERT(VARCHAR(23), ' + COLUMN_NAME + ', 126) AS ' + COLUMN_NAME
            WHEN DATA_TYPE = 'date'
                THEN 'CONVERT(VARCHAR(10), ' + COLUMN_NAME + ', 23) AS ' + COLUMN_NAME
            WHEN DATA_TYPE IN ('decimal', 'numeric', 'money')
                THEN 'CAST(' + COLUMN_NAME + ' AS VARCHAR(50)) AS ' + COLUMN_NAME
            ELSE COLUMN_NAME
        END,
        ', '
    ) WITHIN GROUP (ORDER BY ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @TableName
        AND TABLE_SCHEMA = 'dbo';
    
    -- Set filename
    SET @FileName = @ExportPath + LOWER(@TableName) + '.csv';
    
    -- Build BCP command
    SET @SQL = 'bcp "SELECT ' + @ColumnList + 
               ' FROM HumanResources.dbo.' + @TableName + 
               '" queryout "' + @FileName + 
               '" -c -t, -T -S ' + @@SERVERNAME;
    
    PRINT 'Exporting: ' + @TableName + ' to ' + @FileName;
    EXEC xp_cmdshell @SQL;
    
END
GO

-- ============================================================
-- OPTION 4: EXPORT ALL TABLES
-- ============================================================

IF OBJECT_ID('dbo.sp_ExportAllTablesToCSV', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ExportAllTablesToCSV;
GO

CREATE PROCEDURE dbo.sp_ExportAllTablesToCSV
    @ExportPath NVARCHAR(500) = 'C:\exports\hr\'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TableName NVARCHAR(128);
    
    -- Ensure path ends with backslash
    IF RIGHT(@ExportPath, 1) <> '\'
        SET @ExportPath = @ExportPath + '\';
    
    -- Create cursor for all tables
    DECLARE table_cursor CURSOR FOR
        SELECT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
            AND TABLE_SCHEMA = 'dbo'
            AND TABLE_NAME NOT IN ('sysdiagrams') -- Exclude system tables
        ORDER BY TABLE_NAME;
    
    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @TableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_ExportTableToCSV 
            @TableName = @TableName,
            @ExportPath = @ExportPath;
        
        FETCH NEXT FROM table_cursor INTO @TableName;
    END
    
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    
    PRINT '';
    PRINT 'All tables exported successfully to: ' + @ExportPath;
END
GO

-- ============================================================
-- OPTION 5: POWERSHELL EXPORT (Most Flexible)
-- ============================================================
-- Save as Export-HRDatabase.ps1

/*
# PowerShell script for flexible export
$ServerInstance = "localhost"
$Database = "HumanResources"
$ExportPath = "C:\exports\hr"

# Create export directory
New-Item -ItemType Directory -Force -Path $ExportPath | Out-Null

# Get all tables
$tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query @"
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_TYPE = 'BASE TABLE' 
        AND TABLE_SCHEMA = 'dbo'
    ORDER BY TABLE_NAME
"@

foreach ($table in $tables) {
    $tableName = $table.TABLE_NAME
    $outputFile = Join-Path $ExportPath "$($tableName.ToLower()).csv"
    
    Write-Host "Exporting $tableName to $outputFile"
    
    # Export with proper formatting
    $query = "SELECT * FROM dbo.$tableName"
    
    Invoke-Sqlcmd -ServerInstance $ServerInstance `
                  -Database $Database `
                  -Query $query `
                  -MaxCharLength 8000 |
        Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
}

Write-Host "Export complete!"
*/

-- ============================================================
-- COMPARISON MATRIX
-- ============================================================

/*
FORMAT      | SIZE    | SPEED   | TARQL | SPARQL-ANY | TYPE SAFE | USE CASE
------------|---------|---------|-------|------------|-----------|------------------
CSV         | 1x      | Fast    | ★★★★★ | ★★★☆☆      | ★☆☆☆☆     | TARQL, Simple
JSON        | 2-3x    | Medium  | ★★☆☆☆ | ★★★★★      | ★★★★☆     | Nested, SPARQL-ANY
XML         | 5-8x    | Slow    | ★☆☆☆☆ | ★★★☆☆      | ★★★★★     | Enterprise
BCP Binary  | 0.5x    | Fastest | ☆☆☆☆☆ | ☆☆☆☆☆      | ★★★★★     | SQL Server only
Parquet     | 0.3x    | Fast    | ★☆☆☆☆ | ★★☆☆☆      | ★★★★★     | Big Data

RECOMMENDATION FOR YOUR PROJECT:
- Primary: CSV (one file per table) for TARQL
- Secondary: JSON (with relationships) for complex mappings
- Dates: ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)
- Nulls: Empty strings or explicit "NULL"
- Encoding: UTF-8 with BOM
*/

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================

-- Export all tables to CSV
EXEC dbo.sp_ExportAllTablesToCSV 
    @ExportPath = 'C:\exports\hr\';

-- Export single table
EXEC dbo.sp_ExportTableToCSV 
    @TableName = 'Employees',
    @ExportPath = 'C:\exports\hr\';

-- Verify exports
EXEC xp_cmdshell 'dir C:\exports\hr\*.csv';

GO

PRINT 'Export procedures created successfully!';
PRINT 'Use: EXEC dbo.sp_ExportAllTablesToCSV';
