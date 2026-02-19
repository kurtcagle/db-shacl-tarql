# HR Database Test CSV Data

## Overview

This directory contains comprehensive test data for the HR Database TARQL transformation testing. The data includes 20 employees across 8 departments with complete employment history, salary records, benefits, performance reviews, and training records.

## Files Included

| File | Records | Description |
|------|---------|-------------|
| `departments.csv` | 8 | Organizational departments with budgets and managers |
| `positions.csv` | 20 | Job positions from junior to director level |
| `employees.csv` | 20 | Employee master records with full contact information |
| `employeepositions.csv` | 25 | Current and historical position assignments |
| `salaries.csv` | 32 | Complete salary history with raises and promotions |
| `benefits.csv` | 10 | Available benefit programs |
| `employeebenefits.csv` | 20 | Employee benefit enrollments |
| `timeoffrequests.csv` | 20 | Time-off requests with various statuses |
| `performancereviews.csv` | 20 | Performance review records over multiple years |
| `trainingcourses.csv` | 15 | Available training courses |
| `employeetraining.csv` | 20 | Training enrollment and completion records |

**Total Records: 200+ across 11 tables**

## Data Characteristics

### Realistic Scenarios

1. **Employee Lifecycle**
   - New hires (Employee #3, #6, #7, etc.)
   - Promotions with historical records (Employee #1, #2, #12)
   - One terminated employee (Employee #20)
   - One employee on leave (Employee #19)

2. **Salary History**
   - Initial hire salaries
   - Annual raises
   - Promotion-related increases
   - Salary ranges from $42K to $148K

3. **Organizational Structure**
   - 8 departments (IT, HR, Finance, Sales, Marketing, Operations, CS, R&D)
   - 6 departments with managers
   - 2 departments without managers (to test NULL handling)
   - Department budgets from $200K to $600K

4. **Foreign Key Relationships**
   - Managers referenced in Departments table
   - Approvers in Salaries and TimeOffRequests
   - Reviewers in PerformanceReviews
   - All properly linked with valid EmployeeIDs

5. **NULL Value Testing**
   - Optional fields: MiddleName, TerminationDate, ManagerEmployeeID
   - Some employees without all benefits
   - Some reviews without improvement comments
   - Some training without certification numbers

6. **Temporal Data**
   - Historical position assignments (ended assignments)
   - Historical salary records (with EndDate)
   - Multiple years of performance reviews
   - Time-off requests spanning past and future

7. **Status Variations**
   - TimeOffRequests: Pending, Approved, Denied, Cancelled
   - EmployeeStatus: Active (18), OnLeave (1), Terminated (1)
   - TrainingStatus: Completed (18), InProgress (2)
   - Benefit enrollment: All active

## Key Test Cases

### 1. Current vs Historical Data
- **Employee #1**: Has 2 positions (1 historical, 1 current)
- **Employee #2**: Has 2 positions (1 historical, 1 current)
- **Employee #12**: Has 2 positions (1 historical, 1 current)

### 2. Salary Progression
- **Employee #1**: 3 salary records showing progression
- **Employee #8**: 3 salary records showing significant promotion increase

### 3. NULL Handling
- **Departments 7 & 8**: No ManagerEmployeeID (NULL)
- **Employee #20**: Has TerminationDate
- **Several employees**: No MiddleName
- **Various records**: Optional fields are NULL

### 4. Foreign Key Relationships
- All department managers are valid employees
- All approvers/reviewers are valid employees
- All position/department assignments are valid

### 5. Date Ranges
- **Dates span**: 2012-07-20 to 2025-02-21
- **Current date reference**: 2024-12-01 (approximately)
- **Future records**: Some pending time-off requests

## Data Quality

### Constraints Met
✅ All CHECK constraints satisfied  
✅ All UNIQUE constraints satisfied  
✅ All NOT NULL constraints satisfied  
✅ All foreign keys valid  
✅ Date ranges logical (StartDate <= EndDate)  
✅ Salary ranges within position limits  
✅ Job levels 1-10  
✅ Rating scales 1.00-5.00  

### Realistic Values
✅ Names represent diverse backgrounds  
✅ Email addresses follow standard format  
✅ Phone numbers in consistent format  
✅ Addresses in Washington state  
✅ SSNs in proper format  
✅ Salaries appropriate for positions  

## Expected TARQL Output

### Approximate Triple Counts

| Table | CSV Rows | Expected Triples |
|-------|----------|------------------|
| Departments | 8 | ~80 |
| Positions | 20 | ~200 |
| Employees | 20 | ~400 (includes FOAF/vCard) |
| EmployeePositions | 25 | ~250 |
| Salaries | 32 | ~320 |
| Benefits | 10 | ~80 |
| EmployeeBenefits | 20 | ~160 |
| TimeOffRequests | 20 | ~220 |
| PerformanceReviews | 20 | ~240 |
| TrainingCourses | 15 | ~135 |
| EmployeeTraining | 20 | ~220 |
| **TOTAL** | **210** | **~2,305** |

## Using the Test Data

### 1. Copy to CSV Export Directory
```bash
mkdir -p csv_exports
cp test_data/*.csv csv_exports/
```

### 2. Run TARQL Transformations
```bash
./run_tarql_transformations.sh
```

### 3. Verify Output
```bash
# Count total triples
grep -c "\." rdf_output/hr_complete.ttl

# Validate RDF syntax
rapper --input turtle --count rdf_output/hr_complete.ttl

# Validate against SHACL
pyshacl -s hr_database_shacl.ttl -d rdf_output/hr_complete.ttl -f human
```

### 4. Load into Triple Store
```bash
# Fuseki
curl -X POST -H "Content-Type: text/turtle" \
     --data-binary "@rdf_output/hr_complete.ttl" \
     "http://localhost:3030/hr/data"

# GraphDB
curl -X POST -H "Content-Type: text/turtle" \
     --data-binary "@rdf_output/hr_complete.ttl" \
     "http://localhost:7200/repositories/hr/statements"
```

## Sample SPARQL Queries to Validate

### 1. Count Employees by Department
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?deptName (COUNT(?emp) AS ?count)
WHERE {
  ?emp a hr:Employee ;
       hr:currentDepartment/hr:departmentName ?deptName .
}
GROUP BY ?deptName
ORDER BY DESC(?count)
```

**Expected Results:** IT=6, Sales=4, Finance=3, etc.

### 2. Find Employees with Salary History
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?name (COUNT(?salary) AS ?salaryRecords)
WHERE {
  ?emp a hr:Employee ;
       hr:firstName ?fname ;
       hr:lastName ?lname ;
       hr:hasSalaryRecord ?salary .
  BIND(CONCAT(?fname, " ", ?lname) AS ?name)
}
GROUP BY ?name
HAVING (COUNT(?salary) > 1)
ORDER BY DESC(?salaryRecords)
```

**Expected Results:** Should find Employees #1, #2, #8, #10, #12

### 3. Find Departments Without Managers
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?deptName
WHERE {
  ?dept a hr:Department ;
        hr:departmentName ?deptName .
  FILTER NOT EXISTS { ?dept hr:hasManager ?mgr }
}
```

**Expected Results:** Customer Support, Research and Development

### 4. Find Employees on Leave
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?name ?status
WHERE {
  ?emp a hr:Employee ;
       hr:firstName ?fname ;
       hr:lastName ?lname ;
       hr:employeeStatus ?status .
  FILTER(?status = "OnLeave")
  BIND(CONCAT(?fname, " ", ?lname) AS ?name)
}
```

**Expected Results:** Karen Young

### 5. Training Completion Rate
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?courseName 
       (COUNT(?training) AS ?enrollments)
       (SUM(IF(?status = "Completed", 1, 0)) AS ?completed)
WHERE {
  ?training a hr:EmployeeTraining ;
            hr:course/hr:courseName ?courseName ;
            hr:status ?status .
}
GROUP BY ?courseName
```

## Data Relationships Map

```
Departments (8)
    ├── hasManager → Employees (6 of 8)
    └── ← EmployeePositions (current assignments)

Positions (20)
    └── ← EmployeePositions

Employees (20)
    ├── → EmployeePositions (current + historical)
    ├── → Salaries (32 total)
    ├── → EmployeeBenefits (20 enrollments)
    ├── → PerformanceReviews (20 reviews)
    ├── → TimeOffRequests (20 requests)
    └── → EmployeeTraining (20 records)

Benefits (10)
    └── ← EmployeeBenefits

TrainingCourses (15)
    └── ← EmployeeTraining
```

## Notes

1. **Date Format**: All dates are in ISO 8601 format as required by TARQL
   - Dates: `YYYY-MM-DD`
   - DateTimes: `YYYY-MM-DDTHH:MM:SS`

2. **NULL Representation**: Empty string or literal "NULL"

3. **Boolean Values**: Represented as `1` (true) or `0` (false)

4. **Encoding**: UTF-8 without BOM

5. **Delimiters**: Comma-separated, no quotes around values unless they contain commas

6. **Header Row**: First row contains column names matching SQL column names

## Troubleshooting

### Issue: Missing Foreign Key References
**Solution**: All foreign keys in test data are valid. If you see errors, check that all CSV files are present.

### Issue: Date Parsing Errors
**Solution**: Dates are in ISO 8601 format. Ensure TARQL queries use `xsd:date` or `xsd:dateTime` appropriately.

### Issue: NULL Value Handling
**Solution**: TARQL queries include proper NULL handling with `BOUND()` checks and comparison to "NULL" string.

### Issue: Triple Count Mismatch
**Solution**: Count may vary slightly based on NULL values and optional properties. Expected range: 2,200-2,400 triples.

## Extending the Test Data

To add more test records:

1. Maintain referential integrity (valid foreign keys)
2. Use sequential IDs
3. Keep date formats consistent
4. Ensure constraint compliance
5. Update this README with new counts

## Version

- **Created**: 2026-02-19
- **Test Data Version**: 1.0
- **Compatible with**: HR Database SHACL v1.0
