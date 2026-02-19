-- ============================================================
-- Human Resources Database - SQL Server DDL
-- ============================================================
-- Created: 2026-02-18
-- Description: Complete HR database schema with employee management,
--              departments, positions, salaries, benefits, and training
-- ============================================================

USE master;
GO

-- Drop database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'HumanResources')
BEGIN
    ALTER DATABASE HumanResources SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HumanResources;
END
GO

-- Create database
CREATE DATABASE HumanResources;
GO

USE HumanResources;
GO

-- ============================================================
-- TABLE: Departments
-- ============================================================
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
    DepartmentCode NVARCHAR(10) NOT NULL UNIQUE,
    ManagerEmployeeID INT NULL,
    Budget DECIMAL(15,2) NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================
-- TABLE: Positions
-- ============================================================
CREATE TABLE Positions (
    PositionID INT IDENTITY(1,1) PRIMARY KEY,
    PositionTitle NVARCHAR(100) NOT NULL,
    PositionCode NVARCHAR(20) NOT NULL UNIQUE,
    JobLevel INT NOT NULL CHECK (JobLevel BETWEEN 1 AND 10),
    MinSalary DECIMAL(12,2) NOT NULL,
    MaxSalary DECIMAL(12,2) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT CHK_Salary_Range CHECK (MaxSalary > MinSalary)
);
GO

-- ============================================================
-- TABLE: Employees
-- ============================================================
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    DateOfBirth DATE NOT NULL,
    HireDate DATE NOT NULL,
    TerminationDate DATE NULL,
    EmployeeStatus NVARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (EmployeeStatus IN ('Active', 'Inactive', 'OnLeave', 'Terminated')),
    SSN NVARCHAR(11) NULL UNIQUE,
    Address NVARCHAR(200) NULL,
    City NVARCHAR(50) NULL,
    State NVARCHAR(2) NULL,
    ZipCode NVARCHAR(10) NULL,
    EmergencyContactName NVARCHAR(100) NULL,
    EmergencyContactPhone NVARCHAR(20) NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================
-- TABLE: EmployeePositions (Current and Historical Assignments)
-- ============================================================
CREATE TABLE EmployeePositions (
    EmployeePositionID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    DepartmentID INT NOT NULL,
    PositionID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,
    ReasonForChange NVARCHAR(200) NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_EmpPos_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_EmpPos_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_EmpPos_Position FOREIGN KEY (PositionID) 
        REFERENCES Positions(PositionID),
    CONSTRAINT CHK_EndDate CHECK (EndDate IS NULL OR EndDate >= StartDate)
);
GO

-- ============================================================
-- TABLE: Salaries (Salary History)
-- ============================================================
CREATE TABLE Salaries (
    SalaryID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    SalaryAmount DECIMAL(12,2) NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NULL,
    SalaryType NVARCHAR(20) NOT NULL DEFAULT 'Annual' 
        CHECK (SalaryType IN ('Annual', 'Hourly', 'Contract')),
    ChangeReason NVARCHAR(200) NULL,
    ApprovedBy INT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Salary_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_Salary_Approver FOREIGN KEY (ApprovedBy) 
        REFERENCES Employees(EmployeeID)
);
GO

-- ============================================================
-- TABLE: Benefits
-- ============================================================
CREATE TABLE Benefits (
    BenefitID INT IDENTITY(1,1) PRIMARY KEY,
    BenefitName NVARCHAR(100) NOT NULL,
    BenefitType NVARCHAR(50) NOT NULL 
        CHECK (BenefitType IN ('Health', 'Dental', 'Vision', 'Retirement', 'Life', 'Other')),
    Description NVARCHAR(MAX) NULL,
    EmployerCost DECIMAL(10,2) NULL,
    EmployeeCost DECIMAL(10,2) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================
-- TABLE: EmployeeBenefits
-- ============================================================
CREATE TABLE EmployeeBenefits (
    EmployeeBenefitID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    BenefitID INT NOT NULL,
    EnrollmentDate DATE NOT NULL,
    TerminationDate DATE NULL,
    CoverageLevel NVARCHAR(20) NULL 
        CHECK (CoverageLevel IN ('Individual', 'Family', 'Employee+Spouse', 'Employee+Children')),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_EmpBenefit_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_EmpBenefit_Benefit FOREIGN KEY (BenefitID) 
        REFERENCES Benefits(BenefitID)
);
GO

-- ============================================================
-- TABLE: TimeOffRequests
-- ============================================================
CREATE TABLE TimeOffRequests (
    TimeOffRequestID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    RequestType NVARCHAR(30) NOT NULL 
        CHECK (RequestType IN ('Vacation', 'Sick', 'Personal', 'Bereavement', 'Unpaid', 'Other')),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    TotalDays DECIMAL(4,1) NOT NULL,
    RequestStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending' 
        CHECK (RequestStatus IN ('Pending', 'Approved', 'Denied', 'Cancelled')),
    RequestDate DATETIME2 DEFAULT GETDATE(),
    ApprovedBy INT NULL,
    ApprovalDate DATETIME2 NULL,
    Comments NVARCHAR(500) NULL,
    CONSTRAINT FK_TimeOff_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_TimeOff_Approver FOREIGN KEY (ApprovedBy) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT CHK_TimeOff_Dates CHECK (EndDate >= StartDate)
);
GO

-- ============================================================
-- TABLE: PerformanceReviews
-- ============================================================
CREATE TABLE PerformanceReviews (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ReviewerID INT NOT NULL,
    ReviewDate DATE NOT NULL,
    ReviewPeriodStart DATE NOT NULL,
    ReviewPeriodEnd DATE NOT NULL,
    OverallRating DECIMAL(3,2) NOT NULL CHECK (OverallRating BETWEEN 1.00 AND 5.00),
    StrengthsComments NVARCHAR(MAX) NULL,
    ImprovementComments NVARCHAR(MAX) NULL,
    Goals NVARCHAR(MAX) NULL,
    EmployeeAcknowledged BIT DEFAULT 0,
    AcknowledgedDate DATETIME2 NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Review_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_Review_Reviewer FOREIGN KEY (ReviewerID) 
        REFERENCES Employees(EmployeeID)
);
GO

-- ============================================================
-- TABLE: TrainingCourses
-- ============================================================
CREATE TABLE TrainingCourses (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName NVARCHAR(100) NOT NULL,
    CourseCode NVARCHAR(20) NOT NULL UNIQUE,
    Provider NVARCHAR(100) NULL,
    Description NVARCHAR(MAX) NULL,
    DurationHours DECIMAL(5,2) NOT NULL,
    Cost DECIMAL(10,2) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================
-- TABLE: EmployeeTraining
-- ============================================================
CREATE TABLE EmployeeTraining (
    EmployeeTrainingID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATE NOT NULL,
    CompletionDate DATE NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Enrolled' 
        CHECK (Status IN ('Enrolled', 'InProgress', 'Completed', 'Failed', 'Cancelled')),
    Score DECIMAL(5,2) NULL,
    CertificationNumber NVARCHAR(50) NULL,
    ExpirationDate DATE NULL,
    Comments NVARCHAR(500) NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_EmpTraining_Employee FOREIGN KEY (EmployeeID) 
        REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_EmpTraining_Course FOREIGN KEY (CourseID) 
        REFERENCES TrainingCourses(CourseID)
);
GO

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IX_Employees_Status ON Employees(EmployeeStatus);
CREATE INDEX IX_Employees_HireDate ON Employees(HireDate);
CREATE INDEX IX_Employees_Name ON Employees(LastName, FirstName);
CREATE INDEX IX_EmployeePositions_Current ON EmployeePositions(EmployeeID, IsCurrent);
CREATE INDEX IX_Salaries_Employee_Effective ON Salaries(EmployeeID, EffectiveDate DESC);
CREATE INDEX IX_TimeOff_Status ON TimeOffRequests(RequestStatus, EmployeeID);
CREATE INDEX IX_Reviews_Employee_Date ON PerformanceReviews(EmployeeID, ReviewDate DESC);

GO

-- ============================================================
-- STORED PROCEDURE: sp_GetEmployeeDetails
-- Description: Retrieves comprehensive employee information
-- ============================================================
CREATE PROCEDURE sp_GetEmployeeDetails
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Basic Employee Information
    SELECT 
        e.EmployeeID,
        e.FirstName,
        e.LastName,
        e.Email,
        e.Phone,
        e.HireDate,
        e.EmployeeStatus,
        d.DepartmentName,
        p.PositionTitle,
        ep.StartDate AS CurrentPositionStartDate,
        s.SalaryAmount AS CurrentSalary,
        s.SalaryType
    FROM Employees e
    LEFT JOIN EmployeePositions ep ON e.EmployeeID = ep.EmployeeID AND ep.IsCurrent = 1
    LEFT JOIN Departments d ON ep.DepartmentID = d.DepartmentID
    LEFT JOIN Positions p ON ep.PositionID = p.PositionID
    LEFT JOIN Salaries s ON e.EmployeeID = s.EmployeeID 
        AND s.EffectiveDate <= GETDATE() 
        AND (s.EndDate IS NULL OR s.EndDate >= GETDATE())
    WHERE e.EmployeeID = @EmployeeID;
    
    -- Employee Benefits
    SELECT 
        b.BenefitName,
        b.BenefitType,
        eb.EnrollmentDate,
        eb.CoverageLevel,
        eb.IsActive
    FROM EmployeeBenefits eb
    INNER JOIN Benefits b ON eb.BenefitID = b.BenefitID
    WHERE eb.EmployeeID = @EmployeeID
    ORDER BY b.BenefitType;
    
    -- Recent Performance Reviews
    SELECT TOP 5
        pr.ReviewDate,
        pr.OverallRating,
        CONCAT(reviewer.FirstName, ' ', reviewer.LastName) AS ReviewerName,
        pr.StrengthsComments,
        pr.ImprovementComments
    FROM PerformanceReviews pr
    INNER JOIN Employees reviewer ON pr.ReviewerID = reviewer.EmployeeID
    WHERE pr.EmployeeID = @EmployeeID
    ORDER BY pr.ReviewDate DESC;
END
GO

-- ============================================================
-- STORED PROCEDURE: sp_AddNewEmployee
-- Description: Adds a new employee with initial position and salary
-- ============================================================
CREATE PROCEDURE sp_AddNewEmployee
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @DateOfBirth DATE,
    @HireDate DATE,
    @DepartmentID INT,
    @PositionID INT,
    @SalaryAmount DECIMAL(12,2),
    @NewEmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Insert Employee
        INSERT INTO Employees (FirstName, LastName, Email, Phone, DateOfBirth, HireDate, EmployeeStatus)
        VALUES (@FirstName, @LastName, @Email, @Phone, @DateOfBirth, @HireDate, 'Active');
        
        SET @NewEmployeeID = SCOPE_IDENTITY();
        
        -- Assign Position
        INSERT INTO EmployeePositions (EmployeeID, DepartmentID, PositionID, StartDate, IsCurrent)
        VALUES (@NewEmployeeID, @DepartmentID, @PositionID, @HireDate, 1);
        
        -- Set Initial Salary
        INSERT INTO Salaries (EmployeeID, SalaryAmount, EffectiveDate, SalaryType, ChangeReason)
        VALUES (@NewEmployeeID, @SalaryAmount, @HireDate, 'Annual', 'Initial Hire');
        
        COMMIT TRANSACTION;
        
        -- Return success message
        SELECT 'Employee added successfully' AS Result, @NewEmployeeID AS EmployeeID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Return error information
        SELECT 
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity;
    END CATCH
END
GO

-- ============================================================
-- STORED PROCEDURE: sp_UpdateEmployeeSalary
-- Description: Updates employee salary with history tracking
-- ============================================================
CREATE PROCEDURE sp_UpdateEmployeeSalary
    @EmployeeID INT,
    @NewSalaryAmount DECIMAL(12,2),
    @EffectiveDate DATE,
    @ChangeReason NVARCHAR(200),
    @ApprovedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- End current salary record
        UPDATE Salaries
        SET EndDate = DATEADD(DAY, -1, @EffectiveDate)
        WHERE EmployeeID = @EmployeeID 
            AND EndDate IS NULL 
            AND EffectiveDate < @EffectiveDate;
        
        -- Insert new salary record
        INSERT INTO Salaries (EmployeeID, SalaryAmount, EffectiveDate, SalaryType, ChangeReason, ApprovedBy)
        SELECT 
            @EmployeeID, 
            @NewSalaryAmount, 
            @EffectiveDate, 
            SalaryType,
            @ChangeReason,
            @ApprovedBy
        FROM Salaries
        WHERE EmployeeID = @EmployeeID 
            AND EndDate IS NULL;
        
        COMMIT TRANSACTION;
        
        -- Return confirmation
        SELECT 
            'Salary updated successfully' AS Result,
            @EmployeeID AS EmployeeID,
            @NewSalaryAmount AS NewSalary,
            @EffectiveDate AS EffectiveDate;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Return error information
        SELECT 
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity;
    END CATCH
END
GO

-- ============================================================
-- SAMPLE DATA INSERTS (Optional - for testing)
-- ============================================================

-- Insert sample departments
INSERT INTO Departments (DepartmentName, DepartmentCode, Budget)
VALUES 
    ('Information Technology', 'IT', 500000.00),
    ('Human Resources', 'HR', 250000.00),
    ('Finance', 'FIN', 350000.00),
    ('Sales', 'SALES', 600000.00);

-- Insert sample positions
INSERT INTO Positions (PositionTitle, PositionCode, JobLevel, MinSalary, MaxSalary, Description)
VALUES 
    ('Software Engineer', 'SWE', 3, 70000.00, 120000.00, 'Develops and maintains software applications'),
    ('Senior Software Engineer', 'SSWE', 5, 100000.00, 160000.00, 'Lead technical projects and mentor junior developers'),
    ('HR Manager', 'HRMGR', 6, 80000.00, 130000.00, 'Manages HR department and employee relations'),
    ('Accountant', 'ACCT', 3, 55000.00, 85000.00, 'Maintains financial records and reports'),
    ('Sales Representative', 'SALESREP', 2, 45000.00, 80000.00, 'Sells company products and services');

-- Insert sample benefits
INSERT INTO Benefits (BenefitName, BenefitType, Description, EmployerCost, EmployeeCost, IsActive)
VALUES 
    ('Premium Health Insurance', 'Health', 'Comprehensive health coverage', 450.00, 150.00, 1),
    ('Dental Plan', 'Dental', 'Full dental coverage', 75.00, 25.00, 1),
    ('Vision Plan', 'Vision', 'Vision care coverage', 25.00, 10.00, 1),
    ('401(k) Matching', 'Retirement', 'Company matches up to 6%', 0.00, 0.00, 1);

-- Insert sample training courses
INSERT INTO TrainingCourses (CourseName, CourseCode, Provider, DurationHours, Cost, IsActive)
VALUES 
    ('SQL Server Fundamentals', 'SQL101', 'Microsoft Learning', 24.0, 500.00, 1),
    ('Leadership Development', 'LEAD201', 'Corporate Training Inc', 16.0, 750.00, 1),
    ('Workplace Safety', 'SAFE100', 'OSHA Training', 8.0, 200.00, 1);

GO

PRINT 'Human Resources Database created successfully!';
PRINT 'Tables created: 10';
PRINT 'Stored Procedures created: 3';
PRINT '  - sp_GetEmployeeDetails';
PRINT '  - sp_AddNewEmployee';
PRINT '  - sp_UpdateEmployeeSalary';
GO
