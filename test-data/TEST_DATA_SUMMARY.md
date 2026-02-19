# HR Database Test Data - Complete Summary

## Quick Statistics

| Metric | Value |
|--------|-------|
| **Total CSV Files** | 11 |
| **Total Records** | 210+ |
| **Date Range** | 2012-2025 |
| **Employees** | 20 |
| **Departments** | 8 |
| **Positions** | 20 (levels 2-7) |
| **Salary Range** | $42,000 - $148,000 |
| **Expected RDF Triples** | ~2,300 |

## Employee Roster

| ID | Name | Department | Position | Status | Hire Date |
|----|------|------------|----------|--------|-----------|
| 1 | Alice Johnson | IT | Senior Software Developer | Active | 2018-06-01 |
| 2 | Robert Chen | HR | HR Manager | Active | 2015-03-15 |
| 3 | Maria Garcia | IT | Junior Software Developer | Active | 2019-09-10 |
| 4 | James Smith | IT | Software Developer | Active | 2017-02-20 |
| 5 | Sarah Williams | IT | Engineering Manager | Active | 2014-11-05 |
| 6 | Michael Brown | IT | Software Developer | Active | 2020-01-15 |
| 7 | Jennifer Davis | HR | HR Specialist | Active | 2021-04-01 |
| 8 | David Martinez | Finance | Finance Director | Active | 2012-07-20 |
| 9 | Linda Anderson | Finance | Financial Analyst | Active | 2019-10-10 |
| 10 | Paul Taylor | Finance | Financial Analyst | Active | 2018-03-01 |
| 11 | Emily Thomas | Sales | Sales Representative | Active | 2020-08-15 |
| 12 | John White | Sales | Sales Manager | Active | 2016-05-10 |
| 13 | Mary Harris | Sales | Sales Representative | Active | 2019-02-01 |
| 14 | Richard Clark | Sales | Senior Sales Representative | Active | 2017-11-20 |
| 15 | Susan Lewis | Marketing | Marketing Manager | Active | 2020-06-01 |
| 16 | Thomas Walker | Marketing | Marketing Specialist | Active | 2017-09-15 |
| 17 | Nancy Hall | Customer Support | CS Specialist | Active | 2021-07-01 |
| 18 | Steven Allen | Operations | Operations Manager | Active | 2013-04-10 |
| 19 | Karen Young | R&D | Research Scientist | **OnLeave** | 2019-12-01 |
| 20 | Brian King | IT | Senior Software Developer | **Terminated** | 2018-08-20 |

## Department Structure

```
├── Information Technology (IT) - Budget: $500K - Manager: Sarah Williams (#5)
│   ├── 6 employees
│   └── Positions: Junior Dev → Senior Dev → Lead → Manager
│
├── Human Resources (HR) - Budget: $250K - Manager: Robert Chen (#2)
│   ├── 2 employees
│   └── Positions: Specialist → Manager
│
├── Finance (FIN) - Budget: $350K - Manager: David Martinez (#8)
│   ├── 3 employees
│   └── Positions: Analyst → Senior Analyst → Director
│
├── Sales (SALES) - Budget: $600K - Manager: John White (#12)
│   ├── 4 employees
│   └── Positions: Rep → Senior Rep → Manager
│
├── Marketing (MKT) - Budget: $400K - Manager: Susan Lewis (#15)
│   ├── 2 employees
│   └── Positions: Specialist → Manager
│
├── Operations (OPS) - Budget: $450K - Manager: Steven Allen (#18)
│   ├── 1 employee
│   └── Positions: Coordinator → Manager
│
├── Customer Support (CS) - Budget: $200K - Manager: NONE
│   ├── 1 employee
│   └── Positions: Specialist
│
└── Research & Development (RND) - Budget: $550K - Manager: NONE
    ├── 1 employee
    └── Positions: Research Scientist
```

## Data Completeness Matrix

| Table | Required Fields | Optional Fields | NULL Values Present |
|-------|----------------|-----------------|---------------------|
| Departments | 100% | Budget: 100% | ManagerEmployeeID: 2 |
| Positions | 100% | Description: 100% | None |
| Employees | 100% | Various | MiddleName: 10, TerminationDate: 1 |
| EmployeePositions | 100% | EndDate: 21/25 | ReasonForChange: 0 |
| Salaries | 100% | EndDate: 23/32 | ChangeReason: 0, ApprovedBy: 4 |
| Benefits | 100% | Various | Description: 0, Costs: 0 |
| EmployeeBenefits | 100% | Coverage: 17/20 | TerminationDate: 20 |
| TimeOffRequests | 100% | Comments: 14/20 | ApprovedBy: 3, ApprovalDate: 3 |
| PerformanceReviews | 100% | Comments: 13/20 | ImprovementComments: 6, Goals: 0 |
| TrainingCourses | 100% | Various | Provider: 0, Description: 0 |
| EmployeeTraining | 100% | Various | CompletionDate: 2, Score: 2 |

## Test Coverage

### ✅ Constraint Testing
- [x] PRIMARY KEY constraints
- [x] FOREIGN KEY relationships
- [x] UNIQUE constraints (Email, SSN, DepartmentCode, etc.)
- [x] NOT NULL constraints
- [x] CHECK constraints (Status enums, Date ranges)
- [x] DEFAULT values (CreatedDate, Status flags)

### ✅ Data Type Testing
- [x] Integers (IDs, counts)
- [x] Decimals (Salaries, costs, ratings)
- [x] Strings (Names, addresses, comments)
- [x] Dates (YYYY-MM-DD format)
- [x] DateTimes (ISO 8601 format)
- [x] Booleans (Bit flags as 0/1)

### ✅ Relationship Testing
- [x] One-to-Many (Department → Employees)
- [x] Many-to-One (Employees → Department)
- [x] Self-referential (Employee → Manager)
- [x] Historical tracking (Position history, Salary history)
- [x] Optional relationships (NULL foreign keys)

### ✅ Business Logic Testing
- [x] Career progression (Promotions)
- [x] Salary increases (Merit, Promotion)
- [x] Benefit enrollment
- [x] Time-off approvals
- [x] Performance review cycles
- [x] Training completion

### ✅ Edge Cases
- [x] NULL in optional fields
- [x] Empty string values
- [x] Future dated records
- [x] Historical records with EndDate
- [x] Records spanning multiple years
- [x] Employees without full benefits
- [x] Departments without managers

## Key Relationships to Verify in RDF

### 1. Manager Relationships
```sparql
# Should find 6 departments with managers
SELECT ?dept ?manager WHERE {
  ?dept hr:hasManager ?manager .
}
```

### 2. Current Positions
```sparql
# Should find 19 current positions (20 employees - 1 terminated)
SELECT ?emp ?pos WHERE {
  ?emp hr:currentPosition ?pos .
}
```

### 3. Salary History
```sparql
# Employees with multiple salaries (history)
# Expected: #1 (3), #2 (3), #8 (3), #10 (2), #12 (3)
SELECT ?emp (COUNT(?sal) as ?count) WHERE {
  ?emp hr:hasSalaryRecord ?sal .
}
GROUP BY ?emp
HAVING (COUNT(?sal) > 1)
```

### 4. Benefit Enrollment
```sparql
# Most enrolled benefit (should be health insurance)
SELECT ?benefit (COUNT(?enroll) as ?count) WHERE {
  ?benefit ^hr:benefit ?enroll .
}
GROUP BY ?benefit
ORDER BY DESC(?count)
```

### 5. Training Completion
```sparql
# Completed training records (should be 18 out of 20)
SELECT (COUNT(?training) as ?completed) WHERE {
  ?training hr:status "Completed" .
}
```

## Performance Metrics

### Expected Processing Times
| Operation | Time | Notes |
|-----------|------|-------|
| Single table transformation | < 1 sec | Small dataset |
| All table transformations | < 10 sec | Sequential processing |
| RDF validation | < 5 sec | Syntax check |
| SHACL validation | < 30 sec | Full constraint checking |
| Triple store loading | < 10 sec | Fuseki/GraphDB |

### Expected File Sizes
| File Type | Approximate Size |
|-----------|------------------|
| Individual CSV | 1-10 KB |
| Individual TTL | 5-50 KB |
| Combined TTL | ~150 KB |
| All CSVs | ~30 KB |
| All TTLs | ~200 KB |

## Validation Checklist

Use this checklist after running the transformation:

- [ ] All 11 CSV files processed without errors
- [ ] Total triples between 2,200 and 2,400
- [ ] No RDF syntax errors (rapper validation)
- [ ] All SHACL constraints pass
- [ ] All 20 employees present in RDF
- [ ] All 8 departments present
- [ ] Manager relationships correct (6 departments)
- [ ] Current position links correct (19 active employees)
- [ ] Salary history preserved
- [ ] FOAF properties present for all employees
- [ ] vCard properties present where applicable
- [ ] Foreign key relationships as object properties
- [ ] No broken URI references

## Common Issues and Solutions

### Issue: Missing Triples
**Symptom**: Triple count significantly below 2,200  
**Cause**: TARQL query error or CSV parsing issue  
**Solution**: Check TARQL logs, verify CSV format

### Issue: Invalid Foreign Keys
**Symptom**: SHACL validation errors on relationships  
**Cause**: URI construction mismatch  
**Solution**: Verify URI patterns in TARQL queries match

### Issue: NULL Handling
**Symptom**: Unexpected triples with "NULL" literal values  
**Cause**: BOUND() check not working  
**Solution**: Verify NULL represented as empty string or "NULL"

### Issue: Date Format Errors
**Symptom**: XSD datatype validation failures  
**Cause**: Date not in ISO 8601 format  
**Solution**: All dates already in correct format in test data

## Next Steps After Successful Test

1. **Scale Up**: Try with larger datasets (100-1000 employees)
2. **Customize**: Modify data to match your organization
3. **Extend**: Add additional tables or relationships
4. **Integrate**: Connect to your triple store
5. **Query**: Build SPARQL queries for your use cases
6. **Visualize**: Create dashboards from RDF data
7. **API**: Expose data via SPARQL endpoint

## File Manifest

```
test_data/
├── README.md                    # Comprehensive documentation
├── quick_test.sh               # Quick test runner script
├── departments.csv             # 8 departments
├── positions.csv               # 20 positions
├── employees.csv               # 20 employees
├── employeepositions.csv       # 25 assignments
├── salaries.csv                # 32 salary records
├── benefits.csv                # 10 benefit programs
├── employeebenefits.csv        # 20 enrollments
├── timeoffrequests.csv         # 20 time-off requests
├── performancereviews.csv      # 20 performance reviews
├── trainingcourses.csv         # 15 training courses
└── employeetraining.csv        # 20 training records
```

## Credits

- **Test Data Version**: 1.0
- **Created**: 2026-02-19
- **Format**: CSV (UTF-8, comma-delimited)
- **Compatible With**: HR Database SHACL v1.0
- **Total Development Time**: Optimized for comprehensive testing

---

**Ready to test!** Run `./quick_test.sh` to start the transformation.
