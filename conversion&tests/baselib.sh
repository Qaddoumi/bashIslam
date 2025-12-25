#!/bin/bash

# ==============================================================================
# BASELIB.SH - Bash port of baselib.py
# Uses awk to replicate Python's float arithmetic and trigonometric precision.
# ==============================================================================

# We define the math logic in an AWK variable to reuse it across functions.
# UPDATE: Added OFMT="%.17g" to force high precision output (matching Python).
AWK_LIB='
BEGIN {
    PI = 3.141592653589793
    OFMT = "%.17g"  # Fixes scientific notation and rounding issues
}

# Python-style floor (handles negatives correctly: floor(-3.1) -> -4)
function floor(x) {
    return (x == int(x)) ? x : (x < 0) ? int(x) - 1 : int(x)
}

function dcos(deg) {
    return cos((deg * PI) / 180)
}

function dsin(deg) {
    return sin((deg * PI) / 180)
}

function tan(x) {
    return sin(x) / cos(x)
}
'

# ------------------------------------------------------------------------------
# 1. Equation of Time
# ------------------------------------------------------------------------------
equation_of_time() {
    local jd=$1
    awk -v jd="$jd" "$AWK_LIB"'
    {
        n = jd - 2451544.5
        g = 357.528 + 0.9856003 * n
        c = 1.9148 * dsin(g) + 0.02 * dsin(2 * g) + 0.0003 * dsin(3 * g)
        lamda = 280.47 + 0.9856003 * n + c
        r = (-2.468 * dsin(2 * lamda) + 0.053 * dsin(4 * lamda) + 0.0014 * dsin(6 * lamda))
        print (c + r) * 4
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# 2. Hijri to Julian
# ------------------------------------------------------------------------------
hijri_to_julian() {
    local year=$1
    local month=$2
    local day=$3
    
    awk -v y="$year" -v m="$month" -v d="$day" "$AWK_LIB"'
    {
        val = floor((11 * y + 3) / 30) + floor(354 * y) + floor(30 * m) - floor((m - 1) / 2) + d + 1948440 - 385
        print val
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# 3. Gregorian to Julian
# Usage: gregorian_to_julian YYYY MM DD [HH MM SS]
# ------------------------------------------------------------------------------
gregorian_to_julian() {
    # Set defaults for optional time args
    local year=${1}
    local month=${2}
    local day=${3}
    local hour=${4:-0}
    local minute=${5:-0}
    local second=${6:-0}

    # If no arguments provided, use current UTC time (mimicking datetime.now())
    if [ -z "$1" ]; then
        year=$(date -u +%Y)
        month=$(date -u +%m)
        day=$(date -u +%d)
        hour=$(date -u +%H)
        minute=$(date -u +%M)
        second=$(date -u +%S)
    fi

    awk -v y="$year" -v m="$month" -v d="$day" \
        -v h="$hour" -v min="$minute" -v s="$second" "$AWK_LIB"'
    {
        # Convert inputs to numbers
        year = y + 0; month = m + 0; day = d + 0;
        hour = h + 0; minute = min + 0; second = s + 0;

        # Handle time fraction of day
        day += (hour + (minute + (second / 60)) / 60.0) / 24.0

        if (month <= 2) {
            month = month + 12
            year = year - 1
        }

        a = floor(year / 100)

        # Gregorian calendar reform check
        b = 0
        if (year > 1582 || (year == 1582 && (month > 10 || (month == 10 && day > 15)))) {
            b = 2 - a + floor(a / 4)
        }

        jd = floor(365.25 * (year + 4716)) + floor(30.60 * (month + 1)) + day + b - 1524.5
        print jd
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# 4. Julian to Hijri
# ------------------------------------------------------------------------------
julian_to_hijri() {
    local jd=$1
    local correction=${2:-0}

    awk -v jd="$jd" -v corr="$correction" "$AWK_LIB"'
    {
        l = floor(jd + corr) - 1948440 + 10632
        n = floor((l - 1) / 10631)
        l = l - 10631 * n + 354
        j = (floor((10985 - l) / 5316) * floor((50 * l) / 17719) + floor(l / 5670) * floor((43 * l) / 15238))
        l = (l - floor((30 - j) / 15) * floor((17719 * j) / 50) - floor(j / 16) * floor((15238 * j) / 43) + 29)
        
        month = floor((24 * l) / 709)
        day = l - floor((709 * month) / 24)
        year = floor(30 * n + j - 30)
        
        print year, month, day
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# 5. Julian to Gregorian
# ------------------------------------------------------------------------------
julian_to_gregorian() {
    local jd=$1

    awk -v jd="$jd" "$AWK_LIB"'
    {
        jd = jd + 5
        z = floor(jd)
        f = jd - z

        if (z < 2299161) {
            a = z
        } else {
            alpha = floor((z - 1867216.25) / 36524.25)
            a = z + 1 + alpha - floor((alpha / 4))
        }

        b = a + 1524
        c = floor((b - 122.1) / 365.25)
        d = floor(365.25 * c)
        e = floor((b - d) / 30.6001)

        day_val = b - d - floor(30.6001 * e) + f
        
        month_val = e - (e < 14 ? 1 : 13)
        year_val = c - (month_val > 2 ? 4716 : 4715)

        # Print as Year Month Day (Day includes fraction)
        print year_val, month_val, day_val
    }' <<< "run"
}