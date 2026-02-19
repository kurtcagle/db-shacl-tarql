# Contributing to HR Database RDF

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the problem
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: OS, Java version, TARQL version, Python version
- **Sample Data**: Minimal CSV data that demonstrates the issue
- **Error Messages**: Full error messages and stack traces

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title**: Descriptive title for the enhancement
- **Use case**: Why this enhancement would be useful
- **Proposed solution**: How you envision the enhancement working
- **Alternatives**: Alternative solutions you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow existing code style** and conventions
3. **Add tests** for new functionality
4. **Update documentation** including README and inline comments
5. **Validate RDF output** with SHACL before submitting
6. **Update CHANGELOG.md** with your changes

## Development Process

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/yourusername/hr-database-rdf.git
cd hr-database-rdf

# Install dependencies
pip install pyshacl rdflib

# Download TARQL
wget https://github.com/tarql/tarql/releases/download/v1.2/tarql-1.2.tar.gz
tar xzf tarql-1.2.tar.gz
export PATH=$PATH:$(pwd)/tarql-1.2/bin
```

### Testing Your Changes

Before submitting a pull request:

```bash
# Run transformations
cd tarql
./run_tarql_transformations.sh

# Validate output
pyshacl -s ../shacl/hr_database_shacl.ttl \
        -d ../output/hr_complete.ttl \
        -f human

# Check for SHACL violations
# Expected: "Conforms: True"
```

### Code Style Guidelines

#### SPARQL/TARQL

- Use 2-space indentation
- Uppercase SPARQL keywords (SELECT, WHERE, CONSTRUCT)
- Use descriptive variable names (?employeeURI not ?e)
- Comment complex transformations
- Group related BIND statements together

```sparql
# Good
CONSTRUCT {
  ?employeeURI a hr:Employee ;
    hr:employeeID ?employeeID ;
    hr:firstName ?firstName .
}
WHERE {
  BIND(URI(CONCAT("http://example.com/hr/resource/employee/", 
       ?EmployeeID)) AS ?employeeURI)
  BIND(xsd:integer(?EmployeeID) AS ?employeeID)
}

# Avoid
CONSTRUCT { ?e a hr:Employee ; hr:employeeID ?id . }
WHERE { BIND(URI(CONCAT("http://example.com/hr/resource/employee/",?EmployeeID)) AS ?e) }
```

#### SQL

- Use uppercase for SQL keywords
- Use meaningful table and column names
- Include comments for complex logic
- Use proper indentation

#### Documentation

- Update README.md for new features
- Add examples for new transformations
- Document any breaking changes
- Keep CHANGELOG.md current

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(tarql): add support for multi-valued properties

Add TARQL transformation support for properties that can have
multiple values (e.g., multiple phone numbers).

Closes #123
```

```
fix(shacl): correct email pattern regex

The previous regex didn't handle plus signs in email addresses.
Updated to support RFC 5322 compliant addresses.
```

## Project Structure

```
hr-database-rdf/
├── sql/              # SQL Server schema and procedures
├── shacl/            # SHACL validation specifications
├── tarql/            # TARQL transformation queries
├── test-data/        # Sample CSV data for testing
├── output/           # Generated RDF (gitignored)
└── docs/             # Additional documentation
```

## Adding New Transformations

When adding support for a new table:

1. **Create SQL export** in `sql/sql_export_strategy.sql`
2. **Add test CSV** in `test-data/`
3. **Write TARQL query** in `tarql/tarql_newtable.sparql`
4. **Add SHACL shape** in `shacl/hr_database_shacl.ttl`
5. **Update run script** in `tarql/run_tarql_transformations.sh`
6. **Add documentation** in `docs/`
7. **Test thoroughly** with various data scenarios

### TARQL Template

```sparql
PREFIX hr: <http://example.com/hr/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

CONSTRUCT {
  ?resourceURI a hr:YourClass ;
    hr:propertyName ?propertyValue ;
    rdfs:label ?label .
}
WHERE {
  # URI construction
  BIND(URI(CONCAT("http://example.com/hr/resource/yourtype/", 
       ?YourID)) AS ?resourceURI)
  
  # Type casting
  BIND(xsd:integer(?YourID) AS ?propertyValue)
  
  # NULL handling
  BIND(IF(BOUND(?OptionalField) && ?OptionalField != "" && 
          ?OptionalField != "NULL",
          xsd:string(?OptionalField),
          ?UNDEF) AS ?optionalValue)
  
  # Label generation
  BIND(CONCAT("Your Class: ", ?YourName) AS ?label)
}
```

### SHACL Template

```turtle
hr:YourClassShape a sh:NodeShape ;
    sh:targetClass hr:YourClass ;
    sh:property [
        sh:path hr:yourID ;
        sh:name "Your ID" ;
        sh:description "Primary identifier" ;
        sh:datatype xsd:integer ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:minInclusive 1 ;
    ] ;
    sh:property [
        sh:path hr:yourName ;
        sh:name "Your Name" ;
        sh:datatype xsd:string ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:maxLength 100 ;
    ] .
```

## Testing Guidelines

### Unit Tests

Test individual transformations:

```bash
# Test single transformation
tarql tarql/tarql_employees.sparql test-data/employees.csv > test_output.ttl

# Validate against SHACL
pyshacl -s shacl/hr_database_shacl.ttl -d test_output.ttl
```

### Integration Tests

Test complete workflow:

```bash
# Run all transformations
cd tarql
./run_tarql_transformations.sh

# Validate combined output
pyshacl -s ../shacl/hr_database_shacl.ttl -d ../output/hr_complete.ttl
```

### Edge Cases to Test

- NULL values
- Empty strings
- Special characters (Unicode, quotes, commas)
- Maximum field lengths
- Boundary dates (leap years, time zones)
- Duplicate records
- Missing foreign keys
- Invalid email formats
- Out-of-range numeric values

## Documentation Standards

### Inline Comments

```sparql
# Purpose: Transform employee CSV to RDF with FOAF integration
# Input: employees.csv (UTF-8 encoded)
# Output: RDF triples in Turtle format
# Dependencies: None (independent table)
```

### README Updates

When adding features, update:
- Overview section if architecture changes
- Quick Start if setup changes
- Examples section with new use cases
- Troubleshooting for common issues

## Versioning

We use [SemVer](https://semver.org/) for versioning:

- **Major**: Breaking changes to URI patterns or SHACL shapes
- **Minor**: New features (new tables, vocabularies)
- **Patch**: Bug fixes, documentation updates

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Open an issue for questions about contributing
- Tag with `question` label
- Maintainers will respond within 48 hours

## Recognition

Contributors will be recognized in:
- README.md Contributors section
- CHANGELOG.md for significant contributions
- GitHub insights and statistics

---

Thank you for contributing to the semantic web! 🎉
