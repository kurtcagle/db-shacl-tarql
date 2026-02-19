# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-19

### Added
- Complete SQL Server HR database schema with 10 tables
- SHACL 1.2 specification with 128 property constraints
- 9 TARQL transformation queries for CSV-to-RDF conversion
- Comprehensive test dataset with 210+ records across 11 CSV files
- Automated transformation script (run_tarql_transformations.sh)
- Complete documentation including README, TARQL guide, and validation report
- Sample RDF output files (positions and employees)
- SQL export strategy for generating CSV from SQL Server
- SHACL validation using pyshacl
- Mermaid diagrams for architecture visualization

### Documentation
- README.md with complete setup and usage instructions
- TARQL_README.md explaining transformation process
- TARQL_PACKAGE_SUMMARY.md as quick reference
- TRANSFORMATION_RESULTS.md showing actual outputs
- SHACL_VALIDATION_REPORT.md with validation statistics
- TEST_DATA_SUMMARY.md documenting test data coverage

### Features
- URI pattern: http://example.com/hr/resource/{type}/{id}
- FOAF vocabulary integration for person information
- vCard vocabulary integration for contact details
- Proper NULL value handling in transformations
- Temporal data support (current vs. historical positions)
- Email and SSN pattern validation
- Employee status enumeration (Active, OnLeave, Terminated)
- Salary range validation
- Job level constraints (1-10)

### Validation
- 100% SHACL conformance on all test data
- Zero violations across 974 generated triples
- Datatype validation for 12 XSD types
- Cardinality constraint validation
- Pattern matching for emails and SSNs
- Value range validation for numeric fields

## [Unreleased]

### Planned
- Real-time CDC (Change Data Capture) integration
- Named graphs for temporal versioning
- W3C PROV-O provenance tracking
- RDFS/OWL inference rules
- GraphQL API layer
- REST API endpoints
- Authentication and authorization
- Multi-tenancy support
- Docker containerization
- CI/CD pipeline configuration
- Performance benchmarks at scale
- Integration with Neo4j (LPG)

---

## Version History

### Version 1.0.0 (2026-02-19)
Initial public release with complete transformation pipeline, validation, and documentation.
