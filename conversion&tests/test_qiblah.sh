#!/bin/bash

# Source the bash library
source "./qiblah.sh"

compare() {
    test_name=$1; py_out=$2; bash_out=$3
    # Trim leading/trailing whitespace using sed instead of xargs to avoid quote interpretation issues
    py_out=$(echo "$py_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    bash_out=$(echo "$bash_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # Allow small floating point differences for degree calculation
    # Only if both inputs look like numbers
    if [[ "$py_out" =~ ^[0-9.]+$ ]] && [[ "$bash_out" =~ ^[0-9.]+$ ]]; then
        diff=$(awk -v a="$py_out" -v b="$bash_out" 'BEGIN { d=a-b; if(d<0) d=-d; print (d<0.01) ? 1 : 0 }')
        if [[ "$diff" == "1" ]]; then
             echo -e "Result: $py_out vs $bash_out"
             echo -e "[\033[32mPASS\033[0m] $test_name"
             return
        fi
    fi

    if [[ "$py_out" == "$bash_out" ]]; then
        echo -e "Result: $py_out vs $bash_out"
        echo -e "[\033[32mPASS\033[0m] $test_name"
    else
        echo -e "Result: $py_out vs $bash_out"
        echo -e "[\033[31mFAIL\033[0m] $test_name | Py: [$py_out] | Bash: [$bash_out]"
    fi
}

# Python helper
get_python_qiblah() {
    export PYTHONPATH=$PYTHONPATH:.
    python3 -c "
try:
    from qiblah import Qiblah
    
    class MockConf:
        def __init__(self, lat, lon):
            self.latitude = lat
            self.longitude = lon
            
    $1
except Exception as e:
    print(f'PYTHON_ERROR: {e}')
"
}

echo "Starting Qiblah Direction Tests..."
echo "--------------------------------"

run_qiblah_test() {
    local city=$1
    local lat=$2
    local lon=$3
    
    echo "Test: $city ($lat, $lon)"
    
    # 1. Decimal Direction
    PY_RES=$(get_python_qiblah "conf = MockConf($lat, $lon); q = Qiblah(conf); print(q.direction())")
    BASH_RES=$(get_qiblah_direction $lon $lat)
    compare "  Decimal Direction" "$PY_RES" "$BASH_RES"
    
    # 2. DMS Format
    # Note: Python's sixty() method modifies internal state, so we must be careful or just use a fresh instance/call
    PY_RES=$(get_python_qiblah "conf = MockConf($lat, $lon); q = Qiblah(conf); print(q.sixty())")
    BASH_RES=$(format_qiblah_dms $(get_qiblah_direction $lon $lat))
    compare "  DMS Format" "$PY_RES" "$BASH_RES"
    echo ""
}

# --- Test Cases ---

# 1. Amman, Jordan
run_qiblah_test "Amman" 31.9555 35.9435

# 2. New York, USA
run_qiblah_test "New York" 40.7128 -74.0060

# 3. Tokyo, Japan
run_qiblah_test "Tokyo" 35.6762 139.6503

# 4. Mecca (Ideally should be 0 or undefined, let's see)
# Close to Mecca
run_qiblah_test "Realis Test (Jeddah)" 21.5433 39.1728

# 5. Rio de Janeiro (Western Hemisphere)
run_qiblah_test "Rio de Janeiro" -22.9068 -43.1729

echo "--------------------------------"
echo "Tests Complete."
