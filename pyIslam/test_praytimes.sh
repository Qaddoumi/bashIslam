#!/bin/bash
source "./praytimes.sh"

# ==============================================================================
# Prayer Times Test Suite
# Tests the Bash implementation against the Python original across multiple
# locations, dates, and calculation methods.
# ==============================================================================

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

# Helper: Get Python prayer times
get_python_prayer() {
    local lat=$1 lon=$2 timezone=$3 year=$4 month=$5 day=$6 method=${7:-2} madhab=${8:-1}
    export PYTHONPATH=$PYTHONPATH:.
    python3 -c "
from praytimes import Prayer, PrayerConf
from datetime import datetime
conf = PrayerConf($lon, $lat, $timezone, angle_ref=$method, asr_madhab=$madhab)
p = Prayer(conf, datetime($year, $month, $day))
print(f'{p._fajr_time} {p._sherook_time} {p._dohr_time} {p._asr_time} {p._maghreb_time} {p._ishaa_time} {p._midnight} {p._last_third_of_night}')
" 2>/dev/null
}

# Helper: Get Bash prayer times
get_bash_prayer() {
    local lat=$1 lon=$2 timezone=$3 year=$4 month=$5 day=$6 fajr_angle=${7:-18.0} ishaa_angle=${8:-17.0} madhab=${9:-1}
    local jd=$(gregorian_to_julian $year $month $day 12 0 0)
    local raw=$(get_prayer_times $lat $lon $timezone $jd $madhab $fajr_angle $ishaa_angle)
    read -r f s d a m i <<< "$raw"
    local night=$(get_night_times "$f" "$m")
    read -r mid lt <<< "$night"
    echo "$f $s $d $a $m $i $mid $lt"
}

# Method angles lookup - uses get_method_params from praytimes.sh
# Returns: fajr_angle ishaa_angle (extracted from method params)
get_method_angles() {
    local params=$(get_method_params $1)
    read fajr_a ishaa_type ishaa_v1 ishaa_v2 <<< "$params"
    # For simplicity in tests, just return fajr and ishaa angles
    # (ishaa_type handling is done in get_prayer_times)
    echo "$fajr_a $ishaa_v1"
}

# Compare with 1-minute tolerance
compare() {
    local name=$1 py_val=$2 bash_val=$3
    local py_fmt=$(format_time $py_val)
    local ba_fmt=$(format_time $bash_val)
    
    # Extract hours and minutes for comparison
    local py_h=${py_fmt:0:2} py_m=${py_fmt:3:2}
    local ba_h=${ba_fmt:0:2} ba_m=${ba_fmt:3:2}
    
    # Convert to total minutes
    local py_total=$((10#$py_h * 60 + 10#$py_m))
    local ba_total=$((10#$ba_h * 60 + 10#$ba_m))
    
    local diff=$((py_total - ba_total))
    diff=${diff#-}  # Absolute value
    
    if [ $diff -le 1 ]; then
        echo -e "  ${GREEN}[PASS]${NC} $name: $ba_fmt"
        ((PASS_COUNT++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name | Py: $py_fmt | Bash: $ba_fmt (diff: ${diff}min)"
        ((FAIL_COUNT++))
    fi
}

run_test() {
    local name=$1 lat=$2 lon=$3 timezone=$4 year=$5 month=$6 day=$7 method=${8:-2} madhab=${9:-1}
    
    echo -e "\n${YELLOW}Test: $name${NC}"
    echo "  Location: Lat=$lat, Lon=$lon, TimeZone=$timezone"
    echo "  Date: $year-$month-$day, Method=$method, Madhab=$madhab"
    
    # Get method angles
    read fajr_a ishaa_a <<< $(get_method_angles $method)
    
    # Get Python results
    local py_raw=$(get_python_prayer $lat $lon $timezone $year $month $day $method $madhab)
    if [ -z "$py_raw" ]; then
        echo -e "  ${RED}[ERROR]${NC} Python execution failed"
        return
    fi
    read -r py_f py_s py_d py_a py_m py_i py_mid py_lt <<< "$py_raw"
    
    # Get Bash results
    local ba_raw=$(get_bash_prayer $lat $lon $timezone $year $month $day $fajr_a $ishaa_a $madhab)
    read -r ba_f ba_s ba_d ba_a ba_m ba_i ba_mid ba_lt <<< "$ba_raw"
    
    # Compare each prayer time
    compare "Fajr" "$py_f" "$ba_f"
    compare "Sunrise" "$py_s" "$ba_s"
    compare "Dhuhr" "$py_d" "$ba_d"
    compare "Asr" "$py_a" "$ba_a"
    compare "Maghreb" "$py_m" "$ba_m"
    compare "Ishaa" "$py_i" "$ba_i"
    compare "Midnight" "$py_mid" "$ba_mid"
    compare "LastThird" "$py_lt" "$ba_lt"
}

# ==============================================================================
# TEST CASES
# ==============================================================================

echo "=============================================="
echo "Prayer Times Test Suite"
echo "Python vs Bash Implementation"
echo "=============================================="

# --- Test 1: Cairo, Egypt (MWL) ---
run_test "Cairo, Egypt (MWL)" 30.0444 31.2357 2 2023 10 25 2 1

# --- Test 2: Mecca, Saudi Arabia (Umm Al-Qura) ---
run_test "Mecca, Saudi Arabia (UMQ)" 21.4225 39.8262 3 2023 10 25 2 1

# --- Test 3: New York, USA (ISNA) ---
run_test "New York, USA (ISNA)" 40.7128 -74.0060 -5 2023 10 25 5 1

# --- Test 4: London, UK (MWL) ---
run_test "London, UK (MWL)" 51.5074 -0.1278 0 2023 10 25 2 1

# --- Test 5: Singapore (MUIS) ---
run_test "Singapore (MUIS)" 1.3521 103.8198 8 2023 10 25 7 1

# --- Test 6: Jakarta, Indonesia (KEMENAG) ---
run_test "Jakarta, Indonesia" -6.2088 106.8456 7 2023 10 25 7 1

# --- Test 7: Moscow, Russia ---
run_test "Moscow, Russia" 55.7558 37.6173 3 2023 10 25 8 1

# --- Test 8: Paris, France (UOIF) ---
run_test "Paris, France (UOIF)" 48.8566 2.3522 1 2023 10 25 6 1

# --- Test 9: Summer Solstice (London) ---
run_test "London Summer Solstice" 51.5074 -0.1278 1 2023 6 21 2 1

# --- Test 10: Winter Solstice (London) ---
run_test "London Winter Solstice" 51.5074 -0.1278 0 2023 12 21 2 1

# --- Test 11: Hanafi Asr (Cairo) ---
run_test "Cairo Hanafi Asr" 30.0444 31.2357 2 2023 10 25 2 2

# --- Test 12: Ramadan (Mecca 2024) ---
run_test "Mecca Ramadan 2024" 21.4225 39.8262 3 2024 3 15 2 1

# --- Test 13: Sydney, Australia ---
run_test "Sydney, Australia" -33.8688 151.2093 11 2023 10 25 2 1

# --- Test 14: Tokyo, Japan ---
run_test "Tokyo, Japan" 35.6762 139.6503 9 2023 10 25 2 1

# --- Test 15: Karachi, Pakistan ---
run_test "Karachi, Pakistan" 24.8607 67.0011 5 2023 10 25 1 1

# --- Test 16: Amman, Jordan ---
run_test "Amman, Jordan" 31.986 35.898 3 2025 12 24 20 1

# ==============================================================================
# SUMMARY
# ==============================================================================

echo ""
echo "=============================================="
echo "SUMMARY"
echo "=============================================="
echo -e "Total Tests: $((PASS_COUNT + FAIL_COUNT))"
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    pct=$((PASS_COUNT * 100 / (PASS_COUNT + FAIL_COUNT)))
    echo -e "\n${YELLOW}Success rate: ${pct}%${NC}"
    exit 1
fi