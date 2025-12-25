#!/bin/bash

# Source the bash library
source "./hijri.sh"

compare() {
    test_name=$1; py_out=$2; bash_out=$3
    # Trim and normalize whitespace
    py_out=$(echo $py_out | xargs)
    bash_out=$(echo $bash_out | xargs)
    
    if [[ "$py_out" == "$bash_out" ]]; then
        echo -e "[\033[32mPASS\033[0m] $test_name"
    else
        echo -e "[\033[31mFAIL\033[0m] $test_name | Py: [$py_out] | Bash: [$bash_out]"
    fi
}

# This helper sets PYTHONPATH to current dir so 'import baselib' works
get_python_hijri() {
    export PYTHONPATH=$PYTHONPATH:.
    python3 -c "
try:
    from hijri import HijriDate
    from datetime import date
    $1
except Exception as e:
    print(f'PYTHON_ERROR: {e}')
"
}

echo "Starting Hijri Class Tests..."
echo "----------------------------"

# Test 1: Gregorian to Hijri Conversion (Noon to avoid day-boundary issues)
# Python: HijriDate.get_hijri(date(2023, 10, 25))
PY_RES=$(get_python_hijri "h = HijriDate.get_hijri(date(2023, 10, 25)); print(f'{h.year} {h.month} {h.day}')")
BASH_RES=$(gregorian_to_hijri_date 2023 10 25)
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Gregorian to Hijri (2023-10-25)" "$PY_RES" "$BASH_RES"

PY_RES=$(get_python_hijri "h = HijriDate.get_hijri(date(2025, 12, 24)); print(f'{h.year} {h.month} {h.day}')")
BASH_RES=$(gregorian_to_hijri_date 2025 12 24)
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Gregorian to Hijri (2025-12-24)" "$PY_RES" "$BASH_RES"

# Test 2: Format Numeric (lang=0)
PY_RES=$(get_python_hijri "h = HijriDate(1445, 4, 10); print(h.format(0))")
BASH_RES=$(format_hijri 1445 4 10 0)
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Format Numeric (1445-04-10)" "$PY_RES" "$BASH_RES"

# Test 3: Format English (lang=2)
PY_RES=$(get_python_hijri "h = HijriDate(1445, 9, 1); print(h.format(2))")
BASH_RES=$(format_hijri 1445 9 1 2)
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Format English (Ramadan)" "$PY_RES" "$BASH_RES"

# Test 4: Check if Last Day of Month
PY_RES=$(get_python_hijri "h = HijriDate(1445, 8, 30); print(h.is_last())")
BASH_RES=$(is_last_hijri_day 1445 8 30)
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Is Last Day (1445-08-30)" "$PY_RES" "$BASH_RES"

# Test 5: Hijri to Gregorian Conversion
# Note: Bash output includes decimal, Python date object is integers. 
# We normalize them for comparison.
PY_RES=$(get_python_hijri "h = HijriDate(1445, 4, 10); g = h.to_gregorian(); print(f'{g.year} {g.month} {g.day}')")
BASH_RES=$(hijri_to_gregorian_date 1445 4 10 | awk '{print $1, $2, int($3)}')
echo "BASH: $BASH_RES | PY: $PY_RES"
compare "Hijri to Gregorian" "$PY_RES" "$BASH_RES"

echo "----------------------------"
echo "Tests Complete."