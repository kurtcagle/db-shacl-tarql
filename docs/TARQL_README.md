# HR Database CSV to RDF - TARQL Transformation Guide

## Overview

This package contains TARQL transformations to convert SQL Server HR database CSV exports into RDF triples conforming to the HR Database SHACL specification.

## Prerequisites

### Required Software
1. **TARQL** - Install from https://github.com/tarql/tarql
   ```bash
   # Download and extract TARQL
   wget https://github.com/tarql/tarql/releases/download/v1.2/tarql-1.2.tar.gz
   tar xzf tarql-1.2.tar.gz
   export PATH=$PATH:$PWD/tarql-1.2/bin
   ```

2. **Java** - TARQL requires Java 8 or later
   ```bash
   java -version  # Check if Java is installed
   ```

### Optional Software (for validation/loading)
- **Apache Jena Riot** - For RDF validation
- **pySHACL** - For SHACL validation
- **Apache Jena Fuseki** or **GraphDB** - For triple store

## Directory Structure

```
.
├── csv_exports/              # SQL Server CSV exports (source data)
│   ├── departments.csv
│   ├── employees.csv
│   ├── positions.csv
│   └── ...
├── tarql_queries/            # TARQL SPARQL queries
│   ├── tarql_departments.sparql
│   ├── tarql_employees.sparql
│   ├── tarql_positions.sparql
│   └── ...
├── rdf_output/               # Generated RDF files (output)
│   ├── departments.ttl
│   ├── employees.ttl
│   └── hr_complete.ttl
├── hr_database_shacl.ttl     # SHACL specification
└── run_tarql_transformations.sh  # Master execution script
```

## Step-by-Step Guide

### Step 1: Export CSV Files from SQL Server

Use the provided SQL export procedures:

```sql
-- Export all tables to CSV
EXEC dbo.sp_ExportAllTablesToCSV 
    @ExportPath = 'C:\exports\hr\';
```

Or use BCP:
```bash
bcp "SELECT * FROM HumanResources.dbo.Employees" queryout employees.csv -c -t, -T -S localhost
```

**Important CSV Requirements:**
- UTF-8 encoding
- Comma-separated (`,`)
- First row must be column headers
- Dates in ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`
- NULL values as empty strings or literal "NULL"

### Step 2: Organize Files

Place CSV files in `csv_exports/` directory:
```bash
mkdir -p csv_exports
cp /path/to/exports/*.csv csv_exports/
```

Place TARQL queries in `tarql_queries/` directory:
```bash
mkdir -p tarql_queries
cp tarql_*.sparql tarql_queries/
```

### Step 3: Run Transformations

Execute the master script:
```bash
chmod +x run_tarql_transformations.sh
./run_tarql_transformations.sh
```

Or run individual transformations:
```bash
tarql tarql_queries/tarql_employees.sparql csv_exports/employees.csv > rdf_output/employees.ttl
```

### Step 4: Validate Output

Validate RDF syntax:
```bash
rapper --input turtle --count rdf_output/hr_complete.ttl
```

Validate against SHACL:
```bash
pyshacl -s hr_database_shacl.ttl -d rdf_output/hr_complete.ttl -f human
```

### Step 5: Load into Triple Store

**Apache Jena Fuseki:**
```bash
curl -X POST -H "Content-Type: text/turtle" \
     --data-binary "@rdf_output/hr_complete.ttl" \
     "http://localhost:3030/hr/data"
```

**GraphDB:**
```bash
curl -X POST -H "Content-Type: text/turtle" \
     --data-binary "@rdf_output/hr_complete.ttl" \
     "http://localhost:7200/repositories/hr/statements"
```

## TARQL Query Files

### Core Tables
- `tarql_departments.sparql` - Organizational departments
- `tarql_positions.sparql` - Job positions
- `tarql_employees.sparql` - Employee master data

### Relationship Tables
- `tarql_employeepositions.sparql` - Employee-Position-Department assignments
- `tarql_salaries.sparql` - Salary history
- `tarql_benefits.sparql` - Benefits catalog and enrollments
- `tarql_performancereviews.sparql` - Performance reviews
- `tarql_training.sparql` - Training courses and completions

## Generated RDF Structure

### URI Patterns

**Resources:**
- Employees: `http://example.com/hr/resource/employee/{EmployeeID}`
- Departments: `http://example.com/hr/resource/department/{DepartmentID}`
- Positions: `http://example.com/hr/resource/position/{PositionID}`
- Salaries: `http://example.com/hr/resource/salary/{SalaryID}`
- etc.

**Properties:**
- Namespace: `http://example.com/hr/`
- Example: `hr:firstName`, `hr:departmentName`, `hr:salaryAmount`

### Example RDF Output

```turtle
@prefix hr: <http://example.com/hr/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.com/hr/resource/employee/1> a hr:Employee, foaf:Person ;
    hr:employeeID "1"^^xsd:integer ;
    hr:firstName "Alice" ;
    hr:lastName "Smith" ;
    hr:email "alice.smith@example.com" ;
    hr:hireDate "2020-01-15"^^xsd:date ;
    hr:employeeStatus "Active" ;
    hr:currentDepartment <http://example.com/hr/resource/department/1> ;
    hr:currentPosition <http://example.com/hr/resource/position/3> ;
    hr:currentSalaryAmount "85000.00"^^xsd:decimal ;
    foaf:name "Alice Smith" ;
    foaf:mbox <mailto:alice.smith@example.com> .

<http://example.com/hr/resource/department/1> a hr:Department ;
    hr:departmentID "1"^^xsd:integer ;
    hr:departmentName "Information Technology" ;
    hr:departmentCode "IT" ;
    hr:budget "500000.00"^^xsd:decimal .
```

## SPARQL Query Examples

Once loaded into a triple store, you can query the data:

### Query 1: List all employees with their departments
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?name ?department ?position ?salary
WHERE {
  ?emp a hr:Employee ;
       hr:firstName ?fname ;
       hr:lastName ?lname ;
       hr:currentDepartment/hr:departmentName ?department ;
       hr:currentPosition/hr:positionTitle ?position ;
       hr:currentSalaryAmount ?salary .
  
  BIND(CONCAT(?fname, " ", ?lname) AS ?name)
}
ORDER BY ?department ?name
```

### Query 2: Find employees with salaries above threshold
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?name ?salary ?position
WHERE {
  ?emp a hr:Employee ;
       hr:firstName ?fname ;
       hr:lastName ?lname ;
       hr:currentSalaryAmount ?salary ;
       hr:currentPosition/hr:positionTitle ?position .
  
  FILTER(?salary > 100000)
  BIND(CONCAT(?fname, " ", ?lname) AS ?name)
}
ORDER BY DESC(?salary)
```

### Query 3: Department hierarchy with managers
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?deptName ?managerName
WHERE {
  ?dept a hr:Department ;
        hr:departmentName ?deptName ;
        hr:hasManager ?mgr .
  
  ?mgr hr:firstName ?mgrFirst ;
       hr:lastName ?mgrLast .
  
  BIND(CONCAT(?mgrFirst, " ", ?mgrLast) AS ?managerName)
}
ORDER BY ?deptName
```

### Query 4: Training completion status
```sparql
PREFIX hr: <http://example.com/hr/>

SELECT ?empName ?courseName ?status ?completionDate
WHERE {
  ?training a hr:EmployeeTraining ;
            hr:trainee ?emp ;
            hr:course ?course ;
            hr:status ?status ;
            hr:completionDate ?completionDate .
  
  ?emp hr:firstName ?fname ;
       hr:lastName ?lname .
  
  ?course hr:courseName ?courseName .
  
  BIND(CONCAT(?fname, " ", ?lname) AS ?empName)
}
ORDER BY ?empName ?completionDate
```

## Troubleshooting

### Common Issues

**1. TARQL not found**
```
Solution: Ensure TARQL is in your PATH or set TARQL_BIN variable
```

**2. Java not found**
```
Solution: Install Java 8 or later
sudo apt-get install default-jre  # Ubuntu/Debian
brew install openjdk              # macOS
```

**3. CSV parsing errors**
```
Cause: Special characters, quotes, or encoding issues
Solution: 
  - Ensure UTF-8 encoding
  - Properly escape commas in values
  - Check for unmatched quotes
```

**4. NULL value handling**
```
Cause: TARQL sees empty strings differently than NULL
Solution: Use BOUND() and check for "NULL" string:
  BIND(IF(BOUND(?Field) && ?Field != "" && ?Field != "NULL",
          xsd:string(?Field),
          ?UNDEF) AS ?fieldValue)
```

**5. Date format errors**
```
Cause: Dates not in ISO 8601 format
Solution: Export dates as YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS:
  CONVERT(VARCHAR(10), DateField, 23)  -- For dates
  CONVERT(VARCHAR(23), DateTimeField, 126)  -- For datetimes
```

**6. Memory issues with large files**
```
Solution: Increase Java heap size:
  export JAVA_OPTS="-Xmx4G"
  tarql -m 4G query.sparql data.csv
```

## Data Type Mappings

| SQL Server Type | XSD Type | Notes |
|----------------|----------|-------|
| INT | xsd:integer | Integer values |
| DECIMAL(p,s) | xsd:decimal | Decimal numbers |
| NVARCHAR(n) | xsd:string | Text strings |
| DATE | xsd:date | Format: YYYY-MM-DD |
| DATETIME2 | xsd:dateTime | Format: YYYY-MM-DDTHH:MM:SS |
| BIT | xsd:boolean | true/false |

## Performance Tips

1. **Split large CSV files** - Process in batches if > 100MB
2. **Use appropriate memory** - Set Java heap size for large datasets
3. **Validate incrementally** - Test with small samples first
4. **Index triple store** - Create appropriate indexes after loading
5. **Monitor progress** - Use verbose mode: `tarql --verbose`

## Next Steps

After successful transformation:

1. ✅ Validate RDF syntax
2. ✅ Validate against SHACL specification
3. ✅ Load into triple store
4. ✅ Create sample SPARQL queries
5. ✅ Set up API endpoints (if needed)
6. ✅ Integrate with applications

## Support & References

- **TARQL Documentation**: https://tarql.github.io/
- **SPARQL 1.1**: https://www.w3.org/TR/sparql11-query/
- **RDF 1.2**: https://www.w3.org/TR/rdf12-concepts/
- **SHACL**: https://www.w3.org/TR/shacl/
- **Apache Jena**: https://jena.apache.org/
- **GraphDB**: https://graphdb.ontotext.com/

## License

[Specify your license here]

## Contact

[Your contact information]
