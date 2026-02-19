-- ============================================================
-- Stored Procedure: sp_GetEmployeeList
-- ============================================================
-- Description: Retrieves a comprehensive list of employees with 
--              their manager, job title, department, and current salary
-- Created: 2026-02-18
-- Based on: HR Database SHACL Specification
-- ============================================================

USE HumanResources;
GO

-- Drop if exists
IF OBJECT_ID('dbo.sp_GetEmployeeList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEmployeeList;
GO

CREATE PROCEDURE dbo.sp_GetEmployeeList
    @EmployeeStatus NVARCHAR(20) = 'Active',  -- Filter by status (NULL for all)
    @DepartmentID INT = NULL,                 -- Filter by department (NULL for all)
    @IncludeTerminated BIT = 0,               -- Include terminated employees
    @OrderBy NVARCHAR(50) = 'LastName'        -- Sort order: LastName, Department, Salary
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables for dynamic sorting
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @OrderByClause NVARCHAR(200);
    
    -- Validate OrderBy parameter
    IF @OrderBy NOT IN ('LastName', 'Department', 'Salary', 'HireDate')
        SET @OrderBy = 'LastName';
    
    -- Build ORDER BY clause
    SET @OrderByClause = CASE @OrderBy
        WHEN 'LastName' THEN 'e.LastName, e.FirstName'
        WHEN 'Department' THEN 'd.DepartmentName, e.LastName'
        WHEN 'Salary' THEN 's.SalaryAmount DESC, e.LastName'
        WHEN 'HireDate' THEN 'e.HireDate DESC, e.LastName'
        ELSE 'e.LastName, e.FirstName'
    END;
    
    -- Main query using static SQL for better performance
    ;WITH EmployeeData AS (
        SELECT 
            -- Employee Information
            e.EmployeeID,
            e.FirstName,
            e.LastName,
            e.MiddleName,
            e.Email,
            e.Phone,
            e.HireDate,
            e.EmployeeStatus,
            
            -- Department Information
            d.DepartmentID,
            d.DepartmentName,
            d.DepartmentCode,
            
            -- Position Information
            p.PositionID,
            p.PositionTitle,
            p.PositionCode,
            p.JobLevel,
            ep.StartDate AS PositionStartDate,
            
            -- Manager Information (via Department Manager)
            mgr.EmployeeID AS ManagerEmployeeID,
            mgr.FirstName AS ManagerFirstName,
            mgr.LastName AS ManagerLastName,
            CONCAT(mgr.FirstName, ' ', mgr.LastName) AS ManagerFullName,
            
            -- Salary Information
            s.SalaryID,
            s.SalaryAmount,
            s.SalaryType,
            s.EffectiveDate AS SalaryEffectiveDate,
            
            -- Calculated Fields
            CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName,
            CONCAT(e.FirstName, ' ', 
                   CASE WHEN e.MiddleName IS NOT NULL 
                        THEN e.MiddleName + ' ' 
                        ELSE '' END, 
                   e.LastName) AS EmployeeFullNameWithMiddle,
            DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsOfService,
            DATEDIFF(DAY, e.HireDate, GETDATE()) AS DaysEmployed
            
        FROM Employees e
        
        -- Get current position assignment
        LEFT JOIN EmployeePositions ep 
            ON e.EmployeeID = ep.EmployeeID 
            AND ep.IsCurrent = 1
        
        -- Get department information
        LEFT JOIN Departments d 
            ON ep.DepartmentID = d.DepartmentID
        
        -- Get position information
        LEFT JOIN Positions p 
            ON ep.PositionID = p.PositionID
        
        -- Get manager information (via department manager)
        LEFT JOIN Employees mgr 
            ON d.ManagerEmployeeID = mgr.EmployeeID
        
        -- Get current salary
        LEFT JOIN Salaries s 
            ON e.EmployeeID = s.EmployeeID
            AND s.EffectiveDate <= GETDATE()
            AND (s.EndDate IS NULL OR s.EndDate >= GETDATE())
        
        WHERE 
            -- Apply status filter
            (@EmployeeStatus IS NULL OR e.EmployeeStatus = @EmployeeStatus)
            -- Apply department filter
            AND (@DepartmentID IS NULL OR d.DepartmentID = @DepartmentID)
            -- Include/exclude terminated employees
            AND (@IncludeTerminated = 1 OR e.EmployeeStatus <> 'Terminated')
    )
    
    -- Return results
    SELECT 
        EmployeeID,
        EmployeeFullName,
        FirstName,
        LastName,
        MiddleName,
        Email,
        Phone,
        
        -- Department & Position
        DepartmentID,
        DepartmentName,
        DepartmentCode,
        PositionID,
        PositionTitle,
        PositionCode,
        JobLevel,
        PositionStartDate,
        
        -- Manager
        ManagerEmployeeID,
        ManagerFullName,
        ManagerFirstName,
        ManagerLastName,
        
        -- Salary
        SalaryAmount,
        SalaryType,
        SalaryEffectiveDate,
        
        -- Employment
        HireDate,
        EmployeeStatus,
        YearsOfService,
        DaysEmployed,
        
        -- Formatted Display Fields
        FORMAT(SalaryAmount, 'C', 'en-US') AS SalaryFormatted,
        FORMAT(HireDate, 'yyyy-MM-dd') AS HireDateFormatted,
        CASE 
            WHEN YearsOfService = 0 THEN '< 1 year'
            WHEN YearsOfService = 1 THEN '1 year'
            ELSE CAST(YearsOfService AS NVARCHAR) + ' years'
        END AS YearsOfServiceDisplay
        
    FROM EmployeeData
    ORDER BY 
        CASE WHEN @OrderBy = 'LastName' THEN LastName END,
        CASE WHEN @OrderBy = 'LastName' THEN FirstName END,
        CASE WHEN @OrderBy = 'Department' THEN DepartmentName END,
        CASE WHEN @OrderBy = 'Salary' THEN SalaryAmount END DESC,
        CASE WHEN @OrderBy = 'HireDate' THEN HireDate END DESC,
        LastName, FirstName;
    
    -- Return summary statistics
    SELECT 
        COUNT(*) AS TotalEmployees,
        COUNT(DISTINCT DepartmentID) AS TotalDepartments,
        AVG(SalaryAmount) AS AverageSalary,
        MIN(SalaryAmount) AS MinimumSalary,
        MAX(SalaryAmount) AS MaximumSalary,
        SUM(SalaryAmount) AS TotalSalaryExpense,
        AVG(YearsOfService) AS AverageYearsOfService
    FROM EmployeeData;
    
END
GO

-- ============================================================
-- Grant execute permissions (adjust as needed)
-- ============================================================
-- GRANT EXECUTE ON dbo.sp_GetEmployeeList TO [YourRoleName];
-- GO

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================

-- Example 1: Get all active employees
EXEC dbo.sp_GetEmployeeList;

-- Example 2: Get all employees (including inactive)
EXEC dbo.sp_GetEmployeeList 
    @EmployeeStatus = NULL,
    @IncludeTerminated = 1;

-- Example 3: Get active employees in a specific department
EXEC dbo.sp_GetEmployeeList 
    @DepartmentID = 1,
    @EmployeeStatus = 'Active';

-- Example 4: Get all employees sorted by salary
EXEC dbo.sp_GetEmployeeList 
    @EmployeeStatus = NULL,
    @IncludeTerminated = 1,
    @OrderBy = 'Salary';

-- Example 5: Get all active employees sorted by department
EXEC dbo.sp_GetEmployeeList 
    @OrderBy = 'Department';

-- Example 6: Get employees on leave
EXEC dbo.sp_GetEmployeeList 
    @EmployeeStatus = 'OnLeave';

-- ============================================================
-- ALTERNATIVE VERSION: Simplified with Direct Manager
-- ============================================================
-- This version also includes the employee's direct reporting manager
-- (via ManagerEmployeeID in EmployeePositions if that relationship exists)
-- ============================================================

IF OBJECT_ID('dbo.sp_GetEmployeeListWithDirectManager', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEmployeeListWithDirectManager;
GO

CREATE PROCEDURE dbo.sp_GetEmployeeListWithDirectManager
    @EmployeeStatus NVARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        -- Employee Information
        e.EmployeeID,
        CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
        e.FirstName,
        e.LastName,
        e.Email,
        e.Phone,
        
        -- Department & Position
        d.DepartmentName,
        d.DepartmentCode,
        p.PositionTitle,
        p.JobLevel,
        
        -- Department Manager (organizational hierarchy)
        CONCAT(deptMgr.FirstName, ' ', deptMgr.LastName) AS DepartmentManager,
        
        -- Salary
        s.SalaryAmount AS CurrentSalary,
        s.SalaryType,
        FORMAT(s.SalaryAmount, 'C', 'en-US') AS CurrentSalaryFormatted,
        
        -- Employment Details
        e.HireDate,
        e.EmployeeStatus,
        DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsOfService,
        
        -- Metadata
        ep.StartDate AS CurrentPositionStartDate,
        s.EffectiveDate AS SalaryEffectiveDate
        
    FROM Employees e
    
    LEFT JOIN EmployeePositions ep 
        ON e.EmployeeID = ep.EmployeeID 
        AND ep.IsCurrent = 1
    
    LEFT JOIN Departments d 
        ON ep.DepartmentID = d.DepartmentID
    
    LEFT JOIN Positions p 
        ON ep.PositionID = p.PositionID
    
    LEFT JOIN Employees deptMgr 
        ON d.ManagerEmployeeID = deptMgr.EmployeeID
    
    LEFT JOIN Salaries s 
        ON e.EmployeeID = s.EmployeeID
        AND s.EffectiveDate <= GETDATE()
        AND (s.EndDate IS NULL OR s.EndDate >= GETDATE())
    
    WHERE 
        (@EmployeeStatus IS NULL OR e.EmployeeStatus = @EmployeeStatus)
    
    ORDER BY 
        d.DepartmentName,
        p.JobLevel DESC,
        e.LastName,
        e.FirstName;
        
END
GO

-- ============================================================
-- BONUS: Export-Friendly Version (CSV-ready)
-- ============================================================

IF OBJECT_ID('dbo.sp_GetEmployeeListExport', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEmployeeListExport;
GO

CREATE PROCEDURE dbo.sp_GetEmployeeListExport
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Single result set optimized for CSV export
    SELECT 
        e.EmployeeID AS 'Employee ID',
        CONCAT(e.LastName, ', ', e.FirstName) AS 'Employee Name',
        e.Email AS 'Email Address',
        e.Phone AS 'Phone Number',
        d.DepartmentName AS 'Department',
        p.PositionTitle AS 'Job Title',
        p.JobLevel AS 'Job Level',
        ISNULL(CONCAT(mgr.LastName, ', ', mgr.FirstName), 'N/A') AS 'Department Manager',
        ISNULL(s.SalaryAmount, 0) AS 'Current Salary',
        s.SalaryType AS 'Salary Type',
        e.HireDate AS 'Hire Date',
        DATEDIFF(YEAR, e.HireDate, GETDATE()) AS 'Years of Service',
        e.EmployeeStatus AS 'Status'
        
    FROM Employees e
    
    LEFT JOIN EmployeePositions ep 
        ON e.EmployeeID = ep.EmployeeID AND ep.IsCurrent = 1
    
    LEFT JOIN Departments d 
        ON ep.DepartmentID = d.DepartmentID
    
    LEFT JOIN Positions p 
        ON ep.PositionID = p.PositionID
    
    LEFT JOIN Employees mgr 
        ON d.ManagerEmployeeID = mgr.EmployeeID
    
    LEFT JOIN Salaries s 
        ON e.EmployeeID = s.EmployeeID
        AND s.EffectiveDate <= GETDATE()
        AND (s.EndDate IS NULL OR s.EndDate >= GETDATE())
    
    WHERE e.EmployeeStatus IN ('Active', 'OnLeave')
    
    ORDER BY 
        d.DepartmentName,
        e.LastName,
        e.FirstName;
        
END
GO

PRINT 'Employee List Stored Procedures created successfully!';
PRINT 'Available procedures:';
PRINT '  - sp_GetEmployeeList (full featured with parameters)';
PRINT '  - sp_GetEmployeeListWithDirectManager (simplified)';
PRINT '  - sp_GetEmployeeListExport (CSV export ready)';
GO
