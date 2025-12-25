#!/bin/bash

# ==============================================================================
# TEST_UMMALQURA.SH - Tests for ummalqura.sh
# Compares Bash output against Python reference implementation
# ==============================================================================

# Source the bash library
source "./ummalqura.sh"

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

# Helper to get Python UmmAlQura output
get_python_ummalqura() {
    export PYTHONPATH=$PYTHONPATH:.
    python3 -c "
try:
    from ummalqura import UmmAlQuraCalendar
    $1
except Exception as e:
    print(f'PYTHON_ERROR: {e}')
"
}

echo "Starting UmmAlQura Tests..."
echo "----------------------------"

# Test 1: Basic conversion for 2023-10-25
echo ""
echo "Test 1: UmmAlQura(2023, 10, 25)"
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2023, 10, 25); print(f'{u.hijri_date[0]} {u.hijri_date[1]} {u.hijri_date[2]}')")
BASH_RES=$(get_hijri_date 2023 10 25)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Hijri Date (2023-10-25)" "$PY_RES" "$BASH_RES"

# Test 2: Gregorian date output
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2023, 10, 25); print(f'{u.greg_date[0]} {u.greg_date[1]} {u.greg_date[2]}')")
BASH_RES=$(get_greg_date 2023 10 25)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Gregorian Date (2023-10-25)" "$PY_RES" "$BASH_RES"

# Test 3: Week day
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2023, 10, 25); print(u.week_day)")
BASH_RES=$(get_week_day 2023 10 25)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Week Day (2023-10-25)" "$PY_RES" "$BASH_RES"

# Test 4: Julian Day
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2023, 10, 25); print(u.julian_day)")
BASH_RES=$(get_julian_day 2023 10 25)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Julian Day (2023-10-25)" "$PY_RES" "$BASH_RES"

# Test 5: Current date (2025-12-24)
echo ""
echo "Test 5: UmmAlQura(2025, 12, 24)"
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2025, 12, 24); print(f'{u.hijri_date[0]} {u.hijri_date[1]} {u.hijri_date[2]}')")
BASH_RES=$(get_hijri_date 2025 12 24)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Hijri Date (2025-12-24)" "$PY_RES" "$BASH_RES"

# Test 6: Solar Hijri Date
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2025, 12, 24); print(f'{u.solar_hijri_date[0]} {u.solar_hijri_date[1]} {int(u.solar_hijri_date[2])}')")
BASH_RES=$(get_solar_hijri_date 2025 12 24)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Solar Hijri Date (2025-12-24)" "$PY_RES" "$BASH_RES"

# Test 7: Islamic Lunation Number
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2025, 12, 24); print(u.islamic_lunation_num)")
BASH_RES=$(get_islamic_lunation_num 2025 12 24)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Islamic Lunation Num (2025-12-24)" "$PY_RES" "$BASH_RES"

# Test 8: Islamic Month Length
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2025, 12, 24); print(u.islamic_month_length)")
BASH_RES=$(get_islamic_month_length 2025 12 24)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Islamic Month Length (2025-12-24)" "$PY_RES" "$BASH_RES"

# Test 9: Edge case - Start of year (2024-01-01)
echo ""
echo "Test 9: UmmAlQura(2024, 1, 1)"
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2024, 1, 1); print(f'{u.hijri_date[0]} {u.hijri_date[1]} {u.hijri_date[2]}')")
BASH_RES=$(get_hijri_date 2024 1 1)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Hijri Date (2024-01-01)" "$PY_RES" "$BASH_RES"

# Test 10: February date (2024-02-29 - leap year)
echo ""
echo "Test 10: UmmAlQura(2024, 2, 29)"
PY_RES=$(get_python_ummalqura "u = UmmAlQuraCalendar(2024, 2, 29); print(f'{u.hijri_date[0]} {u.hijri_date[1]} {u.hijri_date[2]}')")
BASH_RES=$(get_hijri_date 2024 2 29)
echo "  BASH: $BASH_RES | PY: $PY_RES"
compare "Hijri Date (2024-02-29)" "$PY_RES" "$BASH_RES"

echo ""
echo "----------------------------"
echo "Tests Complete."
