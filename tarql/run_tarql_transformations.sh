#!/bin/bash
# ============================================================
# HR Database TARQL Transformation - Master Execution Script
# ============================================================
# This script executes all TARQL transformations to convert
# CSV exports from SQL Server HR database to RDF
# ============================================================

# Configuration
CSV_DIR="./csv_exports"
TARQL_DIR="./tarql_queries"
OUTPUT_DIR="./rdf_output"
TARQL_BIN="tarql"  # Assumes TARQL is in PATH

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "HR Database CSV to RDF Conversion"
echo "============================================================"
echo "CSV Source: $CSV_DIR"
echo "TARQL Queries: $TARQL_DIR"
echo "RDF Output: $OUTPUT_DIR"
echo ""

# Check if TARQL is available
if ! command -v $TARQL_BIN &> /dev/null; then
    echo "ERROR: TARQL not found in PATH"
    echo "Please install TARQL from: https://github.com/tarql/tarql"
    echo "Or set TARQL_BIN variable to the tarql executable path"
    exit 1
fi

# Function to run TARQL transformation
run_tarql() {
    local csv_file="$1"
    local sparql_file="$2"
    local output_file="$3"
    local table_name="$4"
    
    echo "Processing: $table_name"
    echo "  CSV: $csv_file"
    echo "  Query: $sparql_file"
    echo "  Output: $output_file"
    
    if [ ! -f "$csv_file" ]; then
        echo "  WARNING: CSV file not found - skipping"
        return
    fi
    
    if [ ! -f "$sparql_file" ]; then
        echo "  ERROR: SPARQL query file not found - skipping"
        return
    fi
    
    # Run TARQL transformation
    $TARQL_BIN "$sparql_file" "$csv_file" > "$output_file" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ SUCCESS - $(wc -l < "$output_file") triples generated"
    else
        echo "  ✗ FAILED - check error log"
    fi
    echo ""
}

# ============================================================
# Execute transformations in dependency order
# ============================================================

echo "Starting transformations..."
echo ""

# 1. Independent tables (no foreign keys)
run_tarql \
    "$CSV_DIR/departments.csv" \
    "$TARQL_DIR/tarql_departments.sparql" \
    "$OUTPUT_DIR/departments.ttl" \
    "Departments"

run_tarql \
    "$CSV_DIR/positions.csv" \
    "$TARQL_DIR/tarql_positions.sparql" \
    "$OUTPUT_DIR/positions.ttl" \
    "Positions"

run_tarql \
    "$CSV_DIR/benefits.csv" \
    "$TARQL_DIR/tarql_benefits.sparql" \
    "$OUTPUT_DIR/benefits.ttl" \
    "Benefits"

run_tarql \
    "$CSV_DIR/trainingcourses.csv" \
    "$TARQL_DIR/tarql_training.sparql" \
    "$OUTPUT_DIR/trainingcourses.ttl" \
    "TrainingCourses"

# 2. Employees (depends on nothing, but is referenced by many)
run_tarql \
    "$CSV_DIR/employees.csv" \
    "$TARQL_DIR/tarql_employees.sparql" \
    "$OUTPUT_DIR/employees.ttl" \
    "Employees"

# 3. Tables with foreign keys to above
run_tarql \
    "$CSV_DIR/employeepositions.csv" \
    "$TARQL_DIR/tarql_employeepositions.sparql" \
    "$OUTPUT_DIR/employeepositions.ttl" \
    "EmployeePositions"

run_tarql \
    "$CSV_DIR/salaries.csv" \
    "$TARQL_DIR/tarql_salaries.sparql" \
    "$OUTPUT_DIR/salaries.ttl" \
    "Salaries"

run_tarql \
    "$CSV_DIR/employeebenefits.csv" \
    "$TARQL_DIR/tarql_benefits.sparql" \
    "$OUTPUT_DIR/employeebenefits.ttl" \
    "EmployeeBenefits"

run_tarql \
    "$CSV_DIR/performancereviews.csv" \
    "$TARQL_DIR/tarql_performancereviews.sparql" \
    "$OUTPUT_DIR/performancereviews.ttl" \
    "PerformanceReviews"

run_tarql \
    "$CSV_DIR/employeetraining.csv" \
    "$TARQL_DIR/tarql_training.sparql" \
    "$OUTPUT_DIR/employeetraining.ttl" \
    "EmployeeTraining"

# Note: TimeOffRequests not included - add if CSV exists

echo "============================================================"
echo "Transformation Complete!"
echo "============================================================"
echo ""

# Combine all RDF files into a single dataset
COMBINED_FILE="$OUTPUT_DIR/hr_complete.ttl"
echo "Combining all RDF files into: $COMBINED_FILE"

# Write header
cat > "$COMBINED_FILE" << 'EOF'
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix vcard: <http://www.w3.org/2006/vcard/ns#> .
@prefix hr: <http://example.com/hr/> .
@prefix hrres: <http://example.com/hr/resource/> .

# ============================================================
# Combined HR Database RDF Dataset
# Generated: $(date)
# ============================================================

EOF

# Append all turtle files (skip prefix declarations)
for file in "$OUTPUT_DIR"/*.ttl; do
    if [ "$file" != "$COMBINED_FILE" ]; then
        echo "# From: $(basename "$file")" >> "$COMBINED_FILE"
        grep -v "^@prefix" "$file" | grep -v "^PREFIX" | grep -v "^#" >> "$COMBINED_FILE"
        echo "" >> "$COMBINED_FILE"
    fi
done

echo "✓ Combined dataset created: $COMBINED_FILE"
echo ""

# Statistics
echo "============================================================"
echo "Statistics"
echo "============================================================"
total_triples=$(grep -c "\." "$COMBINED_FILE")
echo "Total triples: $total_triples"
echo ""
echo "Individual files:"
for file in "$OUTPUT_DIR"/*.ttl; do
    if [ "$file" != "$COMBINED_FILE" ]; then
        count=$(wc -l < "$file")
        echo "  $(basename "$file"): $count lines"
    fi
done
echo ""

# Optional: Load into triple store
# Uncomment and configure for your triple store
# echo "============================================================"
# echo "Optional: Load into Triple Store"
# echo "============================================================"
# 
# # Example for Apache Jena Fuseki
# FUSEKI_URL="http://localhost:3030/hr/data"
# curl -X POST -H "Content-Type: text/turtle" \
#      --data-binary "@$COMBINED_FILE" \
#      "$FUSEKI_URL"
# 
# # Example for GraphDB
# GRAPHDB_URL="http://localhost:7200/repositories/hr/statements"
# curl -X POST -H "Content-Type: text/turtle" \
#      --data-binary "@$COMBINED_FILE" \
#      "$GRAPHDB_URL"

echo "All done! 🎉"
echo ""
echo "Next steps:"
echo "  1. Validate RDF: rapper --input turtle --count $COMBINED_FILE"
echo "  2. Load into triple store (see commented code above)"
echo "  3. Query with SPARQL"
echo "  4. Validate against SHACL: pyshacl -s hr_database_shacl.ttl -d $COMBINED_FILE"
