#!/bin/bash

# ==============================================================================
# TEST_LUNAR_PHASE.SH - Comparison tests for lunar_phase.sh vs lunar_phase.js
# ==============================================================================

# Source the bash library
source "./lunar_phase.sh"

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0


# ------------------------------------------------------------------------------
# gmod: Generalized modulo function (n mod m) also valid for negative values
# Usage: gmod <n> <m>
# ------------------------------------------------------------------------------
gmod() {
    local n=$1
    local m=$2
    awk -v n="$n" -v m="$m" "$AWK_LIB"'
    {
        print gmod(n, m)
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# cosd: Cosine of an angle in degrees
# Usage: cosd <degrees>
# ------------------------------------------------------------------------------
cosd() {
    local x=$1
    awk -v x="$x" "$AWK_LIB"'
    {
        print cosd(x)
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# sind: Sine of an angle in degrees
# Usage: sind <degrees>
# ------------------------------------------------------------------------------
sind() {
    local x=$1
    awk -v x="$x" "$AWK_LIB"'
    {
        print sind(x)
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# acosd: Inverse cosine with angle in degrees
# Usage: acosd <value>
# ------------------------------------------------------------------------------
acosd() {
    local x=$1
    awk -v x="$x" "$AWK_LIB"'
    {
        print acosd(x)
    }' <<< "run"
}

# Comparison function with tolerance for floating point
compare() {
    local test_name=$1
    local js_out=$2
    local bash_out=$3
    local tolerance=${4:-0.01}
    
    # Trim whitespace
    js_out=$(echo "$js_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    bash_out=$(echo "$bash_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # Check for errors
    if [[ "$js_out" == *"Error"* ]] || [[ "$bash_out" == *"Error"* ]]; then
        echo -e "  JS:   $js_out"
        echo -e "  Bash: $bash_out"
        echo -e "  [${RED}FAIL${NC}] $test_name (Error in output)"
        ((FAIL_COUNT++))
        return
    fi
    
    # Allow small floating point differences
    if [[ "$js_out" =~ ^-?[0-9.]+$ ]] && [[ "$bash_out" =~ ^-?[0-9.]+$ ]]; then
        local diff=$(awk -v a="$js_out" -v b="$bash_out" -v tol="$tolerance" '
            BEGIN { 
                d = a - b
                if (d < 0) d = -d
                print (d < tol) ? 1 : 0 
            }')
        if [[ "$diff" == "1" ]]; then
            echo -e "  JS:   $js_out"
            echo -e "  Bash: $bash_out"
            echo -e "  [${GREEN}PASS${NC}] $test_name"
            ((PASS_COUNT++))
            return
        fi
    fi
    
    # Exact match comparison
    if [[ "$js_out" == "$bash_out" ]]; then
        echo -e "  JS:   $js_out"
        echo -e "  Bash: $bash_out"
        echo -e "  [${GREEN}PASS${NC}] $test_name"
        ((PASS_COUNT++))
    else
        echo -e "  JS:   $js_out"
        echo -e "  Bash: $bash_out"
        echo -e "  [${RED}FAIL${NC}] $test_name"
        ((FAIL_COUNT++))
    fi
}

# Compare multi-value outputs (space-separated)
compare_multi() {
    local test_name=$1
    local js_out=$2
    local bash_out=$3
    local tolerance=${4:-0.01}
    
    # Trim whitespace
    js_out=$(echo "$js_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    bash_out=$(echo "$bash_out" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    echo -e "  JS:   $js_out"
    echo -e "  Bash: $bash_out"
    
    # Split into arrays
    read -ra js_arr <<< "$js_out"
    read -ra bash_arr <<< "$bash_out"
    
    # Check array lengths
    if [[ ${#js_arr[@]} -ne ${#bash_arr[@]} ]]; then
        echo -e "  [${RED}FAIL${NC}] $test_name (Different number of values: JS=${#js_arr[@]} vs Bash=${#bash_arr[@]})"
        ((FAIL_COUNT++))
        return
    fi
    
    # Compare each value
    local all_pass=1
    for i in "${!js_arr[@]}"; do
        local diff=$(awk -v a="${js_arr[$i]}" -v b="${bash_arr[$i]}" -v tol="$tolerance" '
            BEGIN { 
                d = a - b
                if (d < 0) d = -d
                print (d < tol) ? 1 : 0 
            }')
        if [[ "$diff" != "1" ]]; then
            all_pass=0
            echo -e "  ${YELLOW}Value $i differs: ${js_arr[$i]} vs ${bash_arr[$i]}${NC}"
        fi
    done
    
    if [[ "$all_pass" == "1" ]]; then
        echo -e "  [${GREEN}PASS${NC}] $test_name"
        ((PASS_COUNT++))
    else
        echo -e "  [${RED}FAIL${NC}] $test_name"
        ((FAIL_COUNT++))
    fi
}

# JavaScript helper function
run_js() {
    node -e "$1" 2>/dev/null
}

echo "=============================================="
echo " Lunar Phase Tests: JavaScript vs Bash"
echo "=============================================="
echo ""

# ------------------------------------------------------------------------------
# Test 1: gmod function
# ------------------------------------------------------------------------------
echo "Test Group: gmod (generalized modulo)"
echo "--------------------------------------"

# Test positive values
JS_RES=$(run_js "console.log(((10 % 3) + 3) % 3)")
BASH_RES=$(gmod 10 3)
compare "gmod(10, 3)" "$JS_RES" "$BASH_RES"

# Test negative values  
JS_RES=$(run_js "console.log(((-10 % 3) + 3) % 3)")
BASH_RES=$(gmod -10 3)
compare "gmod(-10, 3)" "$JS_RES" "$BASH_RES"

# Test with 360
JS_RES=$(run_js "console.log(((450 % 360) + 360) % 360)")
BASH_RES=$(gmod 450 360)
compare "gmod(450, 360)" "$JS_RES" "$BASH_RES"

JS_RES=$(run_js "console.log(((-90 % 360) + 360) % 360)")
BASH_RES=$(gmod -90 360)
compare "gmod(-90, 360)" "$JS_RES" "$BASH_RES"

echo ""

# ------------------------------------------------------------------------------
# Test 2: Trigonometric functions
# ------------------------------------------------------------------------------
echo "Test Group: Trigonometric Functions"
echo "------------------------------------"

# cosd tests
JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(Math.cos(((45 % 360) + 360) % 360 / rr))")
BASH_RES=$(cosd 45)
compare "cosd(45)" "$JS_RES" "$BASH_RES" 0.0001

JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(Math.cos(((90 % 360) + 360) % 360 / rr))")
BASH_RES=$(cosd 90)
compare "cosd(90)" "$JS_RES" "$BASH_RES" 0.0001

JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(Math.cos(((180 % 360) + 360) % 360 / rr))")
BASH_RES=$(cosd 180)
compare "cosd(180)" "$JS_RES" "$BASH_RES" 0.0001

# sind tests
JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(Math.sin(((45 % 360) + 360) % 360 / rr))")
BASH_RES=$(sind 45)
compare "sind(45)" "$JS_RES" "$BASH_RES" 0.0001

JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(Math.sin(((90 % 360) + 360) % 360 / rr))")
BASH_RES=$(sind 90)
compare "sind(90)" "$JS_RES" "$BASH_RES" 0.0001

# acosd tests
JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(rr * Math.acos(0.5))")
BASH_RES=$(acosd 0.5)
compare "acosd(0.5)" "$JS_RES" "$BASH_RES" 0.0001

JS_RES=$(run_js "const rr = 180 / Math.PI; console.log(rr * Math.acos(0))")
BASH_RES=$(acosd 0)
compare "acosd(0)" "$JS_RES" "$BASH_RES" 0.0001

echo ""

# ------------------------------------------------------------------------------
# Test 3: Julian Day calculation for fixed dates
# ------------------------------------------------------------------------------
echo "Test Group: Julian Day (tjd_from_date)"
echo "---------------------------------------"

# Test date: 2024-01-01 12:00:00 UTC
# Note: JavaScript months are 0-indexed, our bash takes normal months
JS_RES=$(run_js "
var rr = 180 / Math.PI;
function gmod(n, m) { return ((n % m) + m) % m; }
function tjd_from_date(year, month, day, hours, minutes, seconds) {
    var m = month + 1;
    var y = year;
    if (m < 3) { y -= 1; m += 12; }
    var c = Math.floor(y / 100);
    var jgc = c - Math.floor(c / 4) - 2;
    var cjdn = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day - jgc - 1524;
    return cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24;
}
console.log(tjd_from_date(2024, 0, 1, 12, 0, 0));
")
BASH_RES=$(tjd_from_date 2024 1 1 12 0 0)
compare "tjd_from_date(2024-01-01 12:00:00)" "$JS_RES" "$BASH_RES" 0.001

# Test date: 2023-06-15 00:00:00 UTC
JS_RES=$(run_js "
function tjd_from_date(year, month, day, hours, minutes, seconds) {
    var m = month + 1;
    var y = year;
    if (m < 3) { y -= 1; m += 12; }
    var c = Math.floor(y / 100);
    var jgc = c - Math.floor(c / 4) - 2;
    var cjdn = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day - jgc - 1524;
    return cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24;
}
console.log(tjd_from_date(2023, 5, 15, 0, 0, 0));
")
BASH_RES=$(tjd_from_date 2023 6 15 0 0 0)
compare "tjd_from_date(2023-06-15 00:00:00)" "$JS_RES" "$BASH_RES" 0.001

# Test date: 2025-12-25 13:55:00 UTC (current approx)
JS_RES=$(run_js "
function tjd_from_date(year, month, day, hours, minutes, seconds) {
    var m = month + 1;
    var y = year;
    if (m < 3) { y -= 1; m += 12; }
    var c = Math.floor(y / 100);
    var jgc = c - Math.floor(c / 4) - 2;
    var cjdn = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day - jgc - 1524;
    return cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24;
}
console.log(tjd_from_date(2025, 11, 25, 10, 55, 0));
")
BASH_RES=$(tjd_from_date 2025 12 25 10 55 0)
compare "tjd_from_date(2025-12-25 10:55:00 UTC)" "$JS_RES" "$BASH_RES" 0.001

echo ""

# ------------------------------------------------------------------------------
# Test 4: moonpos function  
# ------------------------------------------------------------------------------
echo "Test Group: moonpos (Lunar Position)"
echo "-------------------------------------"

# Test with specific Julian Day (2024-01-01 12:00)
TJD_TEST="2460311.0"

JS_RES=$(run_js "
var rr = 180 / Math.PI;
function gmod(n, m) { return ((n % m) + m) % m; }
function cosd(x) { return Math.cos(gmod(x, 360) / rr); }
function sind(x) { return Math.sin(gmod(x, 360) / rr); }

function moonpos(tjd) {
    var t = (tjd - 2451545) / 36525;
    var lm0 = gmod(218.3164 + 481267.8812 * t, 360);
    var ls0 = gmod(280.4665 + 36000.7698 * t, 360);
    var d = gmod(297.8502 + 445267.1114 * t, 360);
    var f = gmod(93.2721 + 483202.0175 * t, 360);
    var ml = gmod(134.9634 + 477198.8675 * t, 360);
    var nl = gmod(125.0445 - 1934.1363 * t, 360);
    var ms = gmod(357.5291 + 35999.0503 * t, 360);
    
    var bmoon = 5.128 * sind(f) + 0.281 * sind(ml + f) + 0.278 * sind(ml - f) + 0.173 * sind(2 * d - f) + 0.055 * sind(2 * d - ml + f) + 0.046 * sind(2 * d - ml - f) + 0.033 * sind(2 * d + f);
    var lmoon = lm0 + 6.289 * sind(ml) + 1.274 * sind(2 * d - ml) + 0.658 * sind(2 * d) + 0.214 * sind(2 * ml) - 0.185 * sind(ms) - 0.114 * sind(2 * f) + 0.059 * sind(2 * d - 2 * ml) + 0.057 * sind(2 * d - ms - ml) + 0.053 * sind(2 * d + ml) + 0.046 * sind(2 * d - ms) - 0.041 * sind(ms - ml) - 0.035 * sind(d) - 0.030 * sind(ms + ml);
    var lsun = ls0 - 0.0057 + 1.915 * sind(ms) + 0.020 * sind(2 * ms) - 0.0048 * sind(nl);
    var rmoon = (385000.6 - 20905.4 * cosd(ml) - 3699.1 * cosd(2 * d - ml) - 2956.0 * cosd(2 * d) - 569.9 * cosd(2 * ml)) / 149597870;
    var rsun = 1.00014 - 0.01671 * cosd(ms) - 0.00014 * cosd(2 * ms);
    
    return [lmoon, bmoon, rmoon, lsun, rsun];
}
var res = moonpos($TJD_TEST);
console.log(res.join(' '));
")
BASH_RES=$(moonpos "$TJD_TEST")
compare_multi "moonpos($TJD_TEST)" "$JS_RES" "$BASH_RES" 0.01

# Another test date
TJD_TEST2="2460200.5"
JS_RES=$(run_js "
var rr = 180 / Math.PI;
function gmod(n, m) { return ((n % m) + m) % m; }
function cosd(x) { return Math.cos(gmod(x, 360) / rr); }
function sind(x) { return Math.sin(gmod(x, 360) / rr); }

function moonpos(tjd) {
    var t = (tjd - 2451545) / 36525;
    var lm0 = gmod(218.3164 + 481267.8812 * t, 360);
    var ls0 = gmod(280.4665 + 36000.7698 * t, 360);
    var d = gmod(297.8502 + 445267.1114 * t, 360);
    var f = gmod(93.2721 + 483202.0175 * t, 360);
    var ml = gmod(134.9634 + 477198.8675 * t, 360);
    var nl = gmod(125.0445 - 1934.1363 * t, 360);
    var ms = gmod(357.5291 + 35999.0503 * t, 360);
    
    var bmoon = 5.128 * sind(f) + 0.281 * sind(ml + f) + 0.278 * sind(ml - f) + 0.173 * sind(2 * d - f) + 0.055 * sind(2 * d - ml + f) + 0.046 * sind(2 * d - ml - f) + 0.033 * sind(2 * d + f);
    var lmoon = lm0 + 6.289 * sind(ml) + 1.274 * sind(2 * d - ml) + 0.658 * sind(2 * d) + 0.214 * sind(2 * ml) - 0.185 * sind(ms) - 0.114 * sind(2 * f) + 0.059 * sind(2 * d - 2 * ml) + 0.057 * sind(2 * d - ms - ml) + 0.053 * sind(2 * d + ml) + 0.046 * sind(2 * d - ms) - 0.041 * sind(ms - ml) - 0.035 * sind(d) - 0.030 * sind(ms + ml);
    var lsun = ls0 - 0.0057 + 1.915 * sind(ms) + 0.020 * sind(2 * ms) - 0.0048 * sind(nl);
    var rmoon = (385000.6 - 20905.4 * cosd(ml) - 3699.1 * cosd(2 * d - ml) - 2956.0 * cosd(2 * d) - 569.9 * cosd(2 * ml)) / 149597870;
    var rsun = 1.00014 - 0.01671 * cosd(ms) - 0.00014 * cosd(2 * ms);
    
    return [lmoon, bmoon, rmoon, lsun, rsun];
}
var res = moonpos($TJD_TEST2);
console.log(res.join(' '));
")
BASH_RES=$(moonpos "$TJD_TEST2")
compare_multi "moonpos($TJD_TEST2)" "$JS_RES" "$BASH_RES" 0.01

echo ""

# ------------------------------------------------------------------------------
# Test 5: lunarphase function
# ------------------------------------------------------------------------------
echo "Test Group: lunarphase (elongation, phase angle)"
echo "-------------------------------------------------"

# Full JS implementation for testing
JS_LUNAR_LIB="
var rr = 180 / Math.PI;
function gmod(n, m) { return ((n % m) + m) % m; }
function cosd(x) { return Math.cos(gmod(x, 360) / rr); }
function sind(x) { return Math.sin(gmod(x, 360) / rr); }
function acosd(x) { return rr * Math.acos(x); }

function moonpos(tjd) {
    var t = (tjd - 2451545) / 36525;
    var lm0 = gmod(218.3164 + 481267.8812 * t, 360);
    var ls0 = gmod(280.4665 + 36000.7698 * t, 360);
    var d = gmod(297.8502 + 445267.1114 * t, 360);
    var f = gmod(93.2721 + 483202.0175 * t, 360);
    var ml = gmod(134.9634 + 477198.8675 * t, 360);
    var nl = gmod(125.0445 - 1934.1363 * t, 360);
    var ms = gmod(357.5291 + 35999.0503 * t, 360);
    
    var bmoon = 5.128 * sind(f) + 0.281 * sind(ml + f) + 0.278 * sind(ml - f) + 0.173 * sind(2 * d - f) + 0.055 * sind(2 * d - ml + f) + 0.046 * sind(2 * d - ml - f) + 0.033 * sind(2 * d + f);
    var lmoon = lm0 + 6.289 * sind(ml) + 1.274 * sind(2 * d - ml) + 0.658 * sind(2 * d) + 0.214 * sind(2 * ml) - 0.185 * sind(ms) - 0.114 * sind(2 * f) + 0.059 * sind(2 * d - 2 * ml) + 0.057 * sind(2 * d - ms - ml) + 0.053 * sind(2 * d + ml) + 0.046 * sind(2 * d - ms) - 0.041 * sind(ms - ml) - 0.035 * sind(d) - 0.030 * sind(ms + ml);
    var lsun = ls0 - 0.0057 + 1.915 * sind(ms) + 0.020 * sind(2 * ms) - 0.0048 * sind(nl);
    var rmoon = (385000.6 - 20905.4 * cosd(ml) - 3699.1 * cosd(2 * d - ml) - 2956.0 * cosd(2 * d) - 569.9 * cosd(2 * ml)) / 149597870;
    var rsun = 1.00014 - 0.01671 * cosd(ms) - 0.00014 * cosd(2 * ms);
    return [lmoon, bmoon, rmoon, lsun, rsun];
}

function lunarphase(tjd) {
    var lunpos = moonpos(tjd);
    var lmoon = lunpos[0], bmoon = lunpos[1], rmoon = lunpos[2], lsun = lunpos[3], rsun = lunpos[4];
    var elone = gmod(lmoon - lsun, 360);
    var xm = rmoon * cosd(bmoon) * cosd(lmoon);
    var ym = rmoon * cosd(bmoon) * sind(lmoon);
    var zm = rmoon * sind(bmoon);
    var xs = rsun * cosd(lsun);
    var ys = rsun * sind(lsun);
    var xms = xm - xs, yms = ym - ys, zms = zm;
    var rms = Math.sqrt(xms * xms + yms * yms + zms * zms);
    var phase = acosd((xm * xms + ym * yms + zm * zms) / (rmoon * rms));
    return [elone, phase];
}
"

TJD_TEST="2460311.0"
JS_RES=$(run_js "$JS_LUNAR_LIB
var res = lunarphase($TJD_TEST);
console.log(res.join(' '));
")
BASH_RES=$(lunarphase "$TJD_TEST")
compare_multi "lunarphase($TJD_TEST)" "$JS_RES" "$BASH_RES" 0.1

TJD_TEST2="2460200.5"
JS_RES=$(run_js "$JS_LUNAR_LIB
var res = lunarphase($TJD_TEST2);
console.log(res.join(' '));
")
BASH_RES=$(lunarphase "$TJD_TEST2")
compare_multi "lunarphase($TJD_TEST2)" "$JS_RES" "$BASH_RES" 0.1

# Test a full moon date approximately
TJD_FULL="2460350.0"
JS_RES=$(run_js "$JS_LUNAR_LIB
var res = lunarphase($TJD_FULL);
console.log(res.join(' '));
")
BASH_RES=$(lunarphase "$TJD_FULL")
compare_multi "lunarphase($TJD_FULL)" "$JS_RES" "$BASH_RES" 0.1

echo ""

# ------------------------------------------------------------------------------
# Test 6: moon_flum (illuminated fraction)
# ------------------------------------------------------------------------------
echo "Test Group: moon_flum (illuminated fraction)"
echo "---------------------------------------------"

JS_FLUM_LIB="$JS_LUNAR_LIB
function moon_flum(tjd) {
    var mphase = lunarphase(tjd);
    var k = (1 + cosd(mphase[1])) / 2;
    k = Math.floor(1000 * k + 0.5);
    if (k < 10) return '0.00' + k;
    if (k < 100) return '0.0' + k;
    if (k < 1000) return '0.' + k;
    if (k == 1000) return '1.000';
}
"

TJD_TEST="2460311.0"
JS_RES=$(run_js "$JS_FLUM_LIB
console.log(moon_flum($TJD_TEST));
")
BASH_RES=$(moon_flum "$TJD_TEST")
compare "moon_flum($TJD_TEST)" "$JS_RES" "$BASH_RES"

TJD_TEST2="2460200.5"
JS_RES=$(run_js "$JS_FLUM_LIB
console.log(moon_flum($TJD_TEST2));
")
BASH_RES=$(moon_flum "$TJD_TEST2")
compare "moon_flum($TJD_TEST2)" "$JS_RES" "$BASH_RES"

TJD_FULL="2460350.0"
JS_RES=$(run_js "$JS_FLUM_LIB
console.log(moon_flum($TJD_FULL));
")
BASH_RES=$(moon_flum "$TJD_FULL")
compare "moon_flum($TJD_FULL)" "$JS_RES" "$BASH_RES"

# New moon test
TJD_NEW="2460330.0"
JS_RES=$(run_js "$JS_FLUM_LIB
console.log(moon_flum($TJD_NEW));
")
BASH_RES=$(moon_flum "$TJD_NEW")
compare "moon_flum($TJD_NEW)" "$JS_RES" "$BASH_RES"

echo ""

# ------------------------------------------------------------------------------
# Test 7: Real-time test (current date/time)
# ------------------------------------------------------------------------------
echo "Test Group: Current Date/Time"
echo "-----------------------------"

# Get current tjd from bash
CURRENT_TJD=$(tjd_now)
echo "Current Julian Day (Bash): $CURRENT_TJD"

echo "Testing moonpos with current JD..."
BASH_MOONPOS=$(moonpos "$CURRENT_TJD")
echo "  Bash moonpos: $BASH_MOONPOS"

echo "Testing lunarphase with current JD..."
BASH_PHASE=$(lunarphase "$CURRENT_TJD")
echo "  Bash lunarphase: $BASH_PHASE"

echo "Testing moon_flum with current JD..."
BASH_FLUM=$(moon_flum "$CURRENT_TJD")
echo "  Bash moon_flum: $BASH_FLUM"

ELONE=$(echo "$BASH_PHASE" | awk '{print $1}')
echo "  Moon emoji: $(get_moon_phase_emoji "$ELONE")"

echo ""

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo "=============================================="
echo " Test Summary"
echo "=============================================="
echo -e " ${GREEN}Passed${NC}: $PASS_COUNT"
echo -e " ${RED}Failed${NC}: $FAIL_COUNT"
echo "=============================================="

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e " ${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e " ${RED}Some tests failed.${NC}"
    exit 1
fi
