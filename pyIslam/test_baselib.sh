#!/bin/bash

# ==============================================================================
# TEST SUITE: baselib.py vs baselib.sh
# Verifies that the Bash port produces identical output to the Python original.
# ==============================================================================

PY_FILE="baselib.py"
BASH_FILE="baselib.sh"

# Ensure files exist
if [[ ! -f "$PY_FILE" ]] || [[ ! -f "$BASH_FILE" ]]; then
    echo "Error: Could not find $PY_FILE or $BASH_FILE in the current directory."
    exit 1
fi

# Source the Bash library
source "./$BASH_FILE"

# Python wrapper to call functions dynamically
# We use this to get the "Truth" from the Python file
get_python_output() {
    func_name=$1
    shift
    args="$@"
    
    # We construct a small python script that imports baselib and runs the requested function
    python3 -c "
import sys
from baselib import $func_name
from datetime import datetime

# Parse args based on function requirements
args = '$args'.split()
final_args = []

# Simple arg parsing logic for the test wrapper
if '$func_name' == 'gregorian_to_julian':
    # Convert args to integers
    y, m, d = int(args[0]), int(args[1]), int(args[2])
    h, min, s = int(args[3]), int(args[4]), int(args[5])
    # Pass as explicit arguments (matching the bash script input style)
    # The python lib expects a datetime object or date object usually, 
    # but the function signature in baselib.py is: gregorian_to_julian(dat)
    # So we construct a datetime
    dt = datetime(y, m, d, h, min, s)
    print($func_name(dt))

elif '$func_name' == 'julian_to_gregorian':
    jd = float(args[0])
    # Returns tuple (y, m, d)
    res = $func_name(jd)
    # Format to match space-separated bash output
    print(f'{res[0]} {res[1]} {res[2]}')

elif '$func_name' == 'julian_to_hijri':
    jd = float(args[0])
    res = $func_name(jd)
    print(f'{res[0]} {res[1]} {res[2]}')

elif '$func_name' == 'hijri_to_julian':
    # hijri_to_julian takes a 'dat' object in python (assumed to have year/month/day attributes)
    # We need to mock a simple object or change how we call it. 
    # Looking at baselib.py, it accesses dat.year, dat.month, dat.day.
    class DateObj:
        def __init__(self, y, m, d):
            self.year = int(y)
            self.month = int(m)
            self.day = int(d)
    
    dt = DateObj(args[0], args[1], args[2])
    print($func_name(dt))

else:
    # Default for single numeric arg (equation_of_time)
    print($func_name(float(args[0])))
"
}

# Comparison function
compare() {
    test_name="$1"
    py_out=$(echo "$2" | awk '{$1=$1};1') # trim whitespace
    bash_out=$(echo "$3" | awk '{$1=$1};1') # trim whitespace

    # Formatting Check:
    # Python often prints "2023.0", Bash awk often prints "2023" for whole floats.
    # We normalize "X.0" to "X" for string comparison, OR we use small epsilon for float comparison.
    
    # Simple strategy: If they match exactly, PASS. If not, try float comparison.
    
    if [ "$py_out" == "$bash_out" ]; then
        echo -e "[\033[32mPASS\033[0m] $test_name"
    else
        # Try float precision difference check (awk)
        # If difference < 0.0000001, we count it as pass
        is_close=$(awk -v a="$py_out" -v b="$bash_out" 'BEGIN { diff = (a>b?a-b:b-a); if(diff < 1e-9) print "yes"; else print "no" }' 2>/dev/null)
        
        if [ "$is_close" == "yes" ]; then
             echo -e "[\033[32mPASS\033[0m] $test_name (Float approx)"
        else
            echo -e "[\033[31mFAIL\033[0m] $test_name"
            echo "      Python: [$py_out]"
            echo "      Bash:   [$bash_out]"
        fi
    fi
}

echo "Starting Unit Tests..."
echo "----------------------"

# --------------------------
# Test 1: Gregorian to Julian
# --------------------------
# Case A: Modern Date
Y=2023; M=12; D=25; H=12; MI=0; S=0
TEST_NAME="Gregorian to Julian ($Y-$M-$D)"
PY_RES=$(get_python_output gregorian_to_julian $Y $M $D $H $MI $S)
BASH_RES=$(gregorian_to_julian $Y $M $D $H $MI $S)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

# Case B: Pre-1582 (Julian Calendar Era)
Y=1000; M=1; D=1; H=0; MI=0; S=0
TEST_NAME="Gregorian to Julian ($Y-$M-$D Ancient)"
PY_RES=$(get_python_output gregorian_to_julian $Y $M $D $H $MI $S)
BASH_RES=$(gregorian_to_julian $Y $M $D $H $MI $S)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

# --------------------------
# Test 2: Julian to Gregorian
# --------------------------
JD=2460304.0 # Approx Dec 25 2023
TEST_NAME="Julian to Gregorian ($JD)"
PY_RES=$(get_python_output julian_to_gregorian $JD)
BASH_RES=$(julian_to_gregorian $JD)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

# --------------------------
# Test 3: Hijri to Julian
# --------------------------
HY=1445; HM=6; HD=12
TEST_NAME="Hijri to Julian ($HY-$HM-$HD)"
PY_RES=$(get_python_output hijri_to_julian $HY $HM $HD)
BASH_RES=$(hijri_to_julian $HY $HM $HD)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

# --------------------------
# Test 4: Julian to Hijri
# --------------------------
JD=2460304.0
TEST_NAME="Julian to Hijri ($JD)"
PY_RES=$(get_python_output julian_to_hijri $JD)
BASH_RES=$(julian_to_hijri $JD)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

# --------------------------
# Test 5: Equation of Time
# --------------------------
JD=2460304.5
TEST_NAME="Equation of Time ($JD)"
PY_RES=$(get_python_output equation_of_time $JD)
BASH_RES=$(equation_of_time $JD)
compare "$TEST_NAME" "$PY_RES" "$BASH_RES"

echo "----------------------"
echo "Tests Complete."