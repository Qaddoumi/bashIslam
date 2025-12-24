#!/bin/bash

# Load base libraries
source "./baselib.sh"
source "./hijri.sh"

# Combine all mathematical logic into one string for AWK
# This includes the base math, Hijri logic, and solar position functions
FULL_PRAYER_LIB="$AWK_LIB"'
function equation_of_time(jd) {
    n = jd - 2451544.5
    g = 357.528 + 0.9856003 * n
    c = 1.9148 * dsin(g) + 0.02 * dsin(2 * g) + 0.0003 * dsin(3 * g)
    lamda = 280.47 + 0.9856003 * n + c
    r = (-2.468 * dsin(2 * lamda) + 0.053 * dsin(4 * lamda) + 0.0014 * dsin(6 * lamda))
    return (c + r) * 4
}

function sun_declination(jd) {
    n = jd - 2451544.5
    epsilon = 23.44 - 0.0000004 * n
    l = 280.466 + 0.9856474 * n
    g = 357.528 + 0.9856003 * n
    lamda = l + 1.9148 * dsin(g) + 0.02 * dsin(2 * g)
    x = dsin(epsilon) * dsin(lamda)
    return (180 / (4 * atan2(1,1))) * atan2(x, sqrt(-x * x + 1))
}

function get_time_for_angle(angle, lat, jd) {
    delta = sun_declination(jd)
    s = ((dcos(angle) - dsin(lat) * dsin(delta)) / (dcos(lat) * dcos(delta)))
    if (s > 1) return 0
    if (s < -1) return 0
    return (180 / PI * (atan2(-s, sqrt(-s * s + 1)) + PI / 2)) / 15
}

function get_asr_angle(madhab, lat, jd) {
    delta = sun_declination(jd)
    x_val = (dsin(lat) * dsin(delta) + dcos(lat) * dcos(delta))
    a = atan2(x_val, sqrt(1 - x_val * x_val))
    target = madhab + (1 / tan(a))
    return 90 - (180 / PI) * (atan2(target, 1) + 2 * atan2(1, 1))
}

# NEW: Calculate elevation-adjusted angle for sunset/sunrise
function elevation_angle(elevation_meters) {
    # Formula: additional angle = arccos(R / (R + h))
    # Where R = Earth radius (6371000 m), h = elevation
    # Simplified approximation: 0.0347 * sqrt(elevation)
    return 0.0347 * sqrt(elevation_meters)
}
'

# ==============================================================================
# Method Parameters Lookup
# Format: "fajr_angle ishaa_type ishaa_val1 ishaa_val2"
# ishaa_type: 0 = angle-based, 1 = fixed minutes after Maghreb
# For type 0: ishaa_val1 is the angle, ishaa_val2 is unused
# For type 1: ishaa_val1 is all-year minutes, ishaa_val2 is Ramadan minutes
# ==============================================================================
get_method_params() {
    local id=$1
    case $id in
        1) echo "18.0 0 18.0 0" ;;      # University of Islamic Sciences, Karachi
        2) echo "18.0 0 17.0 0" ;;      # Muslim World League (MWL)
        3) echo "19.5 0 17.5 0" ;;      # Egyptian General Authority of Survey
        4) echo "18.5 1 90 120" ;;      # Umm Al-Qura University, Makkah
        5) echo "15.0 0 15.0 0" ;;      # ISNA
        6) echo "12.0 0 12.0 0" ;;      # France (UOIF)
        7) echo "20.0 0 18.0 0" ;;      # MUIS Singapore / JAKIM Malaysia / KEMENAG Indonesia
        8) echo "16.0 0 15.0 0" ;;      # Russia (SAMR)
        9) echo "19.5 1 90 90" ;;       # Fixed Ishaa 90min
        10) echo "17.7 0 14.0 0" ;;     # Institute of Geophysics, University of Tehran
        11) echo "16.0 0 14.0 0" ;;     # Shia Ithna-Ashari (Jafari)
        12) echo "18.0 0 17.5 0" ;;     # Kuwait
        13) echo "18.0 1 90 90" ;;      # Qatar
        14) echo "18.0 0 17.0 0" ;;     # Turkey (Diyanet)
        15) echo "18.2 0 18.2 0" ;;     # Dubai
        16) echo "18.0 0 18.0 0" ;;     # Tunisia
        17) echo "18.0 0 17.0 0" ;;     # Algeria
        18) echo "19.0 0 17.0 0" ;;     # Morocco
        19) echo "18.0 1 77 77" ;;      # Portugal (Lisbon - 77 min Isha)
        20) echo "18.0 0 18.0 0" ;;     # Jordan
        *) echo "18.0 0 17.0 0" ;;      # Default (MWL)
    esac
}

get_prayer_times() {
    local lat=$1
    local lon=$2
    local timezone=$3
    local jd=$4
    local asr_madhab=${5:-1}
    local fajr_angle=${6:-18.0}
    local ishaa_param=${7:-18.0}
    local elevation=${8:-0}  # NEW: elevation parameter
    
    # We pass FULL_PRAYER_LIB to ensure equation_of_time is defined
    awk -v lat="$lat" -v lon="$lon" -v timezone="$timezone" -v jd="$jd" \
        -v madhab="$asr_madhab" -v fa="$fajr_angle" -v ip="$ishaa_param" \
        -v elev="$elevation" \
        "$FULL_PRAYER_LIB"'
    BEGIN {
        # Calculate elevation adjustment
        elev_correction = elevation_angle(elev)
        sunrise_angle = 90.83333 + elev_correction
        
        # Dhuhr calculation
        ld = (timezone * 15 - lon) / 15
        time_eq = equation_of_time(jd)
        dhuhr = 12 + ld + (time_eq / 60)
        
        fajr = dhuhr - get_time_for_angle(fa + 90, lat, jd)
        sunrise = dhuhr - get_time_for_angle(sunrise_angle, lat, jd)
        asr = dhuhr + get_time_for_angle(get_asr_angle(madhab, lat, jd), lat, jd)
        maghreb = dhuhr + get_time_for_angle(sunrise_angle, lat, jd)  # Use same angle as sunrise
        
        if (ip ~ /FIXED/) {
            split(ip, parts, ":")
            ishaa = maghreb + (parts[2] / 60)
        } else {
            ishaa = dhuhr + get_time_for_angle(ip + 90, lat, jd)
        }
        print fajr, sunrise, dhuhr, asr, maghreb, ishaa
    }'
}

get_night_times() {
    local f_time=$1
    local m_time=$2
    
    # Logic for Midnight and Thirds of Night
    awk -v f="$f_time" -v m="$m_time" 'BEGIN {
        # Duration of night is from Maghreb to Fajr of the next day
        diff = (24.0 - (m - f))
        midnight = m + (diff / 2.0)
        last_third = m + (2 * diff / 3.0)
        print midnight, last_third
    }'
}

format_time() {
    local decimal_hours=$1
    awk -v val="$decimal_hours" 'BEGIN {
        # Handle day wrapping (e.g. 25:30 becomes 01:30)
        hours = val % 24
        if (hours < 0) hours += 24
        
        h = int(hours)
        m = int((hours - h) * 60 + 0.5) # Round to nearest minute
        if (m == 60) { h = (h + 1) % 24; m = 0; }
        printf "%02d:%02d:00\n", h, m
    }'
}

# ==============================================================================
# High-Level API: calculate_prayer_times
# This is the main entry point, matching Python's PrayerConf + Prayer usage
# Usage: calculate_prayer_times <lon> <lat> <timezone> <year> <month> <day> [method] [madhab] [summer_time] [elevation]
# Returns: Fajr Sunrise Dhuhr Asr Maghreb Ishaa Midnight LastThird (as decimal hours)
# ==============================================================================
calculate_prayer_times() {
    local lon=$1
    local lat=$2
    local timezone=$3
    local year=$4
    local month=$5
    local day=$6
    local method_id=${7:-2}
    local asr_madhab=${8:-1}
    local summer_time=${9:-0}
    local elevation=${10:-0}  # elevation parameter (meters)
    
    # Get method parameters (like Python's LIST_FAJR_ISHA_METHODS lookup)
    local params=$(get_method_params "$method_id")
    read fajr_angle ishaa_type ishaa_v1 ishaa_v2 <<< "$params"
    
    # Handle fixed Ishaa time (check for Ramadan if type=1)
    local ishaa_param="$ishaa_v1"
    if (( ishaa_type == 1 )); then
        # Check if current month is Ramadan
        local hijri=$(gregorian_to_hijri_date "$year" "$month" "$day")
        read h_year h_month h_day <<< "$hijri"
        if (( h_month == 9 )); then
            ishaa_param="FIXED:$ishaa_v2"  # Ramadan minutes
        else
            ishaa_param="FIXED:$ishaa_v1"  # All-year minutes
        fi
    fi
    
    # Calculate Julian Day
    local jd=$(gregorian_to_julian "$year" "$month" "$day" 12 0 0)
    
    # Get prayer times with elevation
    local raw=$(get_prayer_times "$lat" "$lon" "$timezone" "$jd" "$asr_madhab" "$fajr_angle" "$ishaa_param" "$elevation")
    read fajr sunrise dhuhr asr maghreb ishaa <<< "$raw"
    
    # Apply summer time adjustment if enabled
    if (( summer_time == 1 )); then
        fajr=$(awk -v t="$fajr" 'BEGIN { print t + 1 }')
        sunrise=$(awk -v t="$sunrise" 'BEGIN { print t + 1 }')
        dhuhr=$(awk -v t="$dhuhr" 'BEGIN { print t + 1 }')
        asr=$(awk -v t="$asr" 'BEGIN { print t + 1 }')
        maghreb=$(awk -v t="$maghreb" 'BEGIN { print t + 1 }')
        ishaa=$(awk -v t="$ishaa" 'BEGIN { print t + 1 }')
    fi
    
    # Get night times
    local night=$(get_night_times "$fajr" "$maghreb")
    read midnight last_third <<< "$night"
    
    # Output all times
    echo "$fajr $sunrise $dhuhr $asr $maghreb $ishaa $midnight $last_third"
}

# ==============================================================================
# Formatted Output: print_prayer_times
# Usage: print_prayer_times <lon> <lat> <timezone> <year> <month> <day> [method] [madhab] [summer_time] [elevation]
# ==============================================================================
print_prayer_times() {
    local raw=$(calculate_prayer_times "$@")
    read fajr sunrise dhuhr asr maghreb ishaa midnight last_third <<< "$raw"
    
    echo "Fajr:      $(format_time $fajr)"
    echo "Sunrise:   $(format_time $sunrise)"
    echo "Dhuhr:     $(format_time $dhuhr)"
    echo "Asr:       $(format_time $asr)"
    echo "Maghreb:   $(format_time $maghreb)"
    echo "Ishaa:     $(format_time $ishaa)"
    echo "Midnight:  $(format_time $midnight)"
    echo "LastThird: $(format_time $last_third)"
}

# ==============================================================================
# JSON Output: print_prayer_times_json
# Usage: print_prayer_times_json <lon> <lat> <timezone> <year> <month> <day> [method] [madhab] [summer_time] [elevation]
# ==============================================================================
print_prayer_times_json() {
    local raw=$(calculate_prayer_times "$@")
    read fajr sunrise dhuhr asr maghreb ishaa midnight last_third <<< "$raw"
    
    printf '{\n'
    printf '  "fajr": "%s",\n'      "$(format_time $fajr)"
    printf '  "sunrise": "%s",\n'   "$(format_time $sunrise)"
    printf '  "dhuhr": "%s",\n'     "$(format_time $dhuhr)"
    printf '  "asr": "%s",\n'       "$(format_time $asr)"
    printf '  "maghreb": "%s",\n'   "$(format_time $maghreb)"
    printf '  "ishaa": "%s",\n'     "$(format_time $ishaa)"
    printf '  "midnight": "%s",\n'  "$(format_time $midnight)"
    printf '  "last_third": "%s"\n' "$(format_time $last_third)"
    printf '}\n'
}