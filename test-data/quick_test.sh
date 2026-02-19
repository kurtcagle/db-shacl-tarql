#!/bin/bash
# ============================================================
# Quick Test Script for HR Database TARQL Transformation
# ============================================================
# This script runs the TARQL transformation using the test data
# ============================================================

echo "============================================================"
echo "HR Database TARQL Transformation - Quick Test"
echo "============================================================"
echo ""

# Configuration
TEST_DATA_DIR="./test_data"
TARQL_QUERIES_DIR="."
OUTPUT_DIR="./test_output"
TARQL_BIN="tarql"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if TARQL is available
if ! command -v $TARQL_BIN &> /dev/null; then
    echo "❌ ERROR: TARQL not found in PATH"
    echo "Please install TARQL from: https://github.com/tarql/tarql"
    exit 1
fi

# Check if test data exists
if [ ! -d "$TEST_DATA_DIR" ]; then
    echo "❌ ERROR: Test data directory not found"
    echo "Expected: $TEST_DATA_DIR"
    exit 1
fi

echo "✓ TARQL found"
echo "✓ Test data directory found"
echo ""

# Function to run a single transformation
run_test() {
    local csv_file="$1"
    local sparql_file="$2"
    local output_file="$3"
    local label="$4"
    
    if [ ! -f "$csv_file" ]; then
        echo "  ⚠️  CSV not found: $csv_file"
        return
    fi
    
    if [ ! -f "$sparql_file" ]; then
        echo "  ⚠️  SPARQL not found: $sparql_file"
        return
    fi
    
    echo "  Processing: $label"
    $TARQL_BIN "$sparql_file" "$csv_file" > "$output_file" 2>&1
    
    if [ $? -eq 0 ]; then
        local count=$(grep -c "\\." "$output_file" 2>/dev/null || echo "0")
        echo "  ✓ $count triples"
    else
        echo "  ✗ FAILED"
    fi
}

echo "Starting transformations..."
echo ""

# Run all transformations
run_test "$TEST_DATA_DIR/departments.csv" \
         "tarql_departments.sparql" \
         "$OUTPUT_DIR/departments.ttl" \
         "Departments"

run_test "$TEST_DATA_DIR/positions.csv" \
         "tarql_positions.sparql" \
         "$OUTPUT_DIR/positions.ttl" \
         "Positions"

run_test "$TEST_DATA_DIR/employees.csv" \
         "tarql_employees.sparql" \
         "$OUTPUT_DIR/employees.ttl" \
         "Employees"

run_test "$TEST_DATA_DIR/employeepositions.csv" \
         "tarql_employeepositions.sparql" \
         "$OUTPUT_DIR/employeepositions.ttl" \
         "EmployeePositions"

run_test "$TEST_DATA_DIR/salaries.csv" \
         "tarql_salaries.sparql" \
         "$OUTPUT_DIR/salaries.ttl" \
         "Salaries"

run_test "$TEST_DATA_DIR/benefits.csv" \
         "tarql_benefits.sparql" \
         "$OUTPUT_DIR/benefits.ttl" \
         "Benefits"

run_test "$TEST_DATA_DIR/employeebenefits.csv" \
         "tarql_benefits.sparql" \
         "$OUTPUT_DIR/employeebenefits.ttl" \
         "EmployeeBenefits"

run_test "$TEST_DATA_DIR/timeoffrequests.csv" \
         "tarql_timeoffrequests.sparql" \
         "$OUTPUT_DIR/timeoffrequests.ttl" \
         "TimeOffRequests"

run_test "$TEST_DATA_DIR/performancereviews.csv" \
         "tarql_performancereviews.sparql" \
         "$OUTPUT_DIR/performancereviews.ttl" \
         "PerformanceReviews"

run_test "$TEST_DATA_DIR/trainingcourses.csv" \
         "tarql_training.sparql" \
         "$OUTPUT_DIR/trainingcourses.ttl" \
         "TrainingCourses"

run_test "$TEST_DATA_DIR/employeetraining.csv" \
         "tarql_training.sparql" \
         "$OUTPUT_DIR/employeetraining.ttl" \
         "EmployeeTraining"

echo ""
echo "============================================================"
echo "Summary"
echo "============================================================"

# Count total triples
total=0
for file in "$OUTPUT_DIR"/*.ttl; do
    if [ -f "$file" ]; then
        count=$(grep -c "\\." "$file" 2>/dev/null || echo "0")
        total=$((total + count))
        echo "$(basename "$file"): $count triples"
    fi
done

echo ""
echo "Total triples generated: $total"
echo "Expected range: 2,200 - 2,400"
echo ""

if [ $total -ge 2200 ] && [ $total -le 2400 ]; then
    echo "✅ Triple count is within expected range!"
else
    echo "⚠️  Triple count is outside expected range"
fi

echo ""
echo "Output location: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. Validate RDF syntax: rapper --input turtle --count $OUTPUT_DIR/*.ttl"
echo "  2. Validate SHACL: pyshacl -s hr_database_shacl.ttl -d $OUTPUT_DIR/*.ttl"
echo "  3. Load into triple store"
echo ""
echo "Test complete! 🎉"
