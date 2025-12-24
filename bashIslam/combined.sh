#!/bin/bash

# ==============================================================================
# SECTION 1: BASE LIBRARY (Math & Date Engine)
# ==============================================================================

# logic: Centralized math functions (including equation_of_time) to avoid duplicates.
AWK_LIB='
BEGIN {
    PI = 3.141592653589793
    OFMT = "%.17g"
}

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

# Moved here so it is not defined twice
function equation_of_time(jd) {
    n = jd - 2451544.5
    g = 357.528 + 0.9856003 * n
    c = 1.9148 * dsin(g) + 0.02 * dsin(2 * g) + 0.0003 * dsin(3 * g)
    lamda = 280.47 + 0.9856003 * n + c
    r = (-2.468 * dsin(2 * lamda) + 0.053 * dsin(4 * lamda) + 0.0014 * dsin(6 * lamda))
    return (c + r) * 4
}
'

# Shell wrapper: References the awk function above instead of rewriting logic
equation_of_time() {
    local jd=$1
    awk -v jd="$jd" "$AWK_LIB"' { print equation_of_time(jd) }' <<< "run"
}

hijri_to_julian() {
    local year=$1 month=$2 day=$3
    awk -v y="$year" -v m="$month" -v d="$day" "$AWK_LIB"'
    {
        val = floor((11 * y + 3) / 30) + floor(354 * y) + floor(30 * m) - floor((m - 1) / 2) + d + 1948440 - 385
        print val
    }' <<< "run"
}

gregorian_to_julian() {
    local year=${1} month=${2} day=${3}
    local hour=${4:-0} minute=${5:-0} second=${6:-0}

    # Defaults to current time if empty
    if [ -z "$1" ]; then
        year=$(date -u +%Y); month=$(date -u +%m); day=$(date -u +%d)
        hour=$(date -u +%H); minute=$(date -u +%M); second=$(date -u +%S)
    fi

    awk -v y="$year" -v m="$month" -v d="$day" \
        -v h="$hour" -v min="$minute" -v s="$second" "$AWK_LIB"'
    {
        year = y + 0; month = m + 0; day = d + 0;
        hour = h + 0; minute = min + 0; second = s + 0;
        day += (hour + (minute + (second / 60)) / 60.0) / 24.0

        if (month <= 2) { month += 12; year -= 1 }

        a = floor(year / 100)
        b = 0
        if (year > 1582 || (year == 1582 && (month > 10 || (month == 10 && day > 15)))) {
            b = 2 - a + floor(a / 4)
        }
        print floor(365.25 * (year + 4716)) + floor(30.60 * (month + 1)) + day + b - 1524.5
    }' <<< "run"
}

julian_to_hijri() {
    local jd=$1 correction=${2:-0}
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

julian_to_gregorian() {
    local jd=$1
    awk -v jd="$jd" "$AWK_LIB"'
    {
        jd = jd + 5
        z = floor(jd)
        f = jd - z
        if (z < 2299161) { a = z } 
        else { alpha = floor((z - 1867216.25) / 36524.25); a = z + 1 + alpha - floor((alpha / 4)) }

        b = a + 1524
        c = floor((b - 122.1) / 365.25)
        d = floor(365.25 * c)
        e = floor((b - d) / 30.6001)

        day = b - d - floor(30.6001 * e) + f
        month = e - (e < 14 ? 1 : 13)
        year = c - (month > 2 ? 4716 : 4715)
        print year, month, day
    }' <<< "run"
}

# ==============================================================================
# SECTION 2: HIJRI LOGIC
# ==============================================================================

_validate_hijri() {
    local y=$1 m=$2 d=$3
    if [[ ! "$y" =~ ^[0-9]+$ ]]; then echo "year must be an int"; return 1; fi
    if (( m < 1 || m > 12 )); then echo "month should be between 1 and 12"; return 1; fi
    if (( d < 1 || d > 30 )); then echo "day should be between 1 and 30"; return 1; fi
}

hijri_to_gregorian_date() {
    local y=$1 m=$2 d=$3
    _validate_hijri "$y" "$m" "$d" || return 1
    local jd=$(hijri_to_julian "$y" "$m" "$d")
    julian_to_gregorian "$jd"
}

gregorian_to_hijri_date() {
    local y=$1 m=$2 d=$3 corr=${4:-0}
    local jd=$(gregorian_to_julian "$y" "$m" "$d")
    julian_to_hijri "$jd" "$corr"
}

format_hijri() {
    local y=$1 m=$2 d=$3 lang=$4
    local -a ar_months=("محرم" "صفر" "ربيع الأول" "ربيع الثاني" "جمادى الأولى" "جمادى الثانية" "رجب" "شعبان" "رمضان" "شوال" "ذو القعدة" "ذو الحجة")
    local -a en_months=("Moharram" "Safar" "Rabie-I" "Rabie-II" "Jumada-I" "Jumada-II" "Rajab" "Shaban" "Ramadan" "Shawwal" "Delqada" "Delhijja")

    if [[ "$lang" == "1" ]]; then echo "$d ${ar_months[$((m-1))]} $y"
    elif [[ "$lang" == "2" ]]; then echo "$d ${en_months[$((m-1))]} $y"
    else printf "%02d-%02d-%04d\n" "$d" "$m" "$y"; fi
}

# ==============================================================================
# SECTION 3: PRAYER TIMES CALCULATION
# ==============================================================================

FULL_PRAYER_LIB="$AWK_LIB"'
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

function elevation_angle(elevation_meters) {
    return 0.0347 * sqrt(elevation_meters)
}
'

get_method_params() {
    case $1 in
        1) echo "18.0 0 18.0 0" ;;      # Karachi
        2) echo "18.0 0 17.0 0" ;;      # MWL
        3) echo "19.5 0 17.5 0" ;;      # Egypt
        4) echo "18.5 1 90 120" ;;      # Makkah
        5) echo "15.0 0 15.0 0" ;;      # ISNA
        6) echo "12.0 0 12.0 0" ;;      # France
        7) echo "20.0 0 18.0 0" ;;      # MUIS/JAKIM
        8) echo "16.0 0 15.0 0" ;;      # Russia
        9) echo "19.5 1 90 90" ;;       # Fixed 90
        10) echo "17.7 0 14.0 0" ;;     # Tehran
        11) echo "16.0 0 14.0 0" ;;     # Jafari
        12) echo "18.0 0 17.5 0" ;;     # Kuwait
        13) echo "18.0 1 90 90" ;;      # Qatar
        14) echo "18.0 0 17.0 0" ;;     # Turkey
        15) echo "18.2 0 18.2 0" ;;     # Dubai
        16) echo "18.0 0 18.0 0" ;;     # Tunisia
        17) echo "18.0 0 17.0 0" ;;     # Algeria
        18) echo "19.0 0 17.0 0" ;;     # Morocco
        19) echo "18.0 1 77 77" ;;      # Portugal
        20) echo "18.0 0 18.0 0" ;;     # Jordan
        *) echo "18.0 0 17.0 0" ;;      # Default
    esac
}

get_prayer_times() {
    local lat=$1 lon=$2 timezone=$3 jd=$4 madhab=${5:-1} fajr_angle=${6:-18.0} ishaa_param=${7:-18.0} elevation=${8:-0}
    
    awk -v lat="$lat" -v lon="$lon" -v timezone="$timezone" -v jd="$jd" \
        -v madhab="$madhab" -v fa="$fajr_angle" -v ip="$ishaa_param" -v elev="$elevation" \
        "$FULL_PRAYER_LIB"'
    BEGIN {
        elev_correction = elevation_angle(elev)
        sunrise_angle = 90.83333 + elev_correction
        
        ld = (timezone * 15 - lon) / 15
        time_eq = equation_of_time(jd)
        dhuhr = 12 + ld + (time_eq / 60)
        
        fajr = dhuhr - get_time_for_angle(fa + 90, lat, jd)
        sunrise = dhuhr - get_time_for_angle(sunrise_angle, lat, jd)
        asr = dhuhr + get_time_for_angle(get_asr_angle(madhab, lat, jd), lat, jd)
        maghreb = dhuhr + get_time_for_angle(sunrise_angle, lat, jd)
        
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
    local f=$1 m=$2
    awk -v f="$f" -v m="$m" 'BEGIN {
        diff = (24.0 - (m - f))
        print m + (diff / 2.0), m + (2 * diff / 3.0)
    }'
}

format_time() {
    local val=$1
    awk -v val="$val" 'BEGIN {
        hours = val % 24; if (hours < 0) hours += 24
        h = int(hours); m = int((hours - h) * 60 + 0.5)
        if (m == 60) { h = (h + 1) % 24; m = 0; }
        printf "%02d:%02d:00\n", h, m
    }'
}

get_elevation() {
    local lat=$1 lon=$2
    elevation=$(curl -s "https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lon" | \
        sed 's/.*\[\([^]]*\)\].*/\1/')
    [[ "$elevation" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && echo "$elevation" || echo 0
}

calculate_prayer_times() {
    local lon=$1 lat=$2 timezone=$3 year=$4 month=$5 day=$6
    local method_id=${7:-2} madhab=${8:-1} summer_time=${9:-0} elevation=${10:-0}

    (( elevation == 0 )) && elevation=$(get_elevation "$lat" "$lon")

    local params=$(get_method_params "$method_id")
    read f_ang i_type i_v1 i_v2 <<< "$params"
    
    local ishaa_param="$i_v1"
    if (( i_type == 1 )); then
        local hijri=$(gregorian_to_hijri_date "$year" "$month" "$day")
        read hy hm hd <<< "$hijri"
        (( hm == 9 )) && ishaa_param="FIXED:$i_v2" || ishaa_param="FIXED:$i_v1"
    fi
    
    local jd=$(gregorian_to_julian "$year" "$month" "$day" 12 0 0)
    local raw=$(get_prayer_times "$lat" "$lon" "$timezone" "$jd" "$madhab" "$f_ang" "$ishaa_param" "$elevation")
    read fajr sunrise dhuhr asr maghreb ishaa <<< "$raw"
    
    if (( summer_time == 1 )); then
        fajr=$(awk -v t="$fajr" 'BEGIN { print t + 1 }')
        sunrise=$(awk -v t="$sunrise" 'BEGIN { print t + 1 }')
        dhuhr=$(awk -v t="$dhuhr" 'BEGIN { print t + 1 }')
        asr=$(awk -v t="$asr" 'BEGIN { print t + 1 }')
        maghreb=$(awk -v t="$maghreb" 'BEGIN { print t + 1 }')
        ishaa=$(awk -v t="$ishaa" 'BEGIN { print t + 1 }')
    fi
    
    local night=$(get_night_times "$fajr" "$maghreb")
    read midnight last_third <<< "$night"
    
    echo "$fajr $sunrise $dhuhr $asr $maghreb $ishaa $midnight $last_third"
}

print_prayer_times_json() {
    local raw=$(calculate_prayer_times "$@")
    read fajr sunrise dhuhr asr maghreb ishaa midnight last_third <<< "$raw"
    
    local year=$4 month=$5 day=$6
    local hijri_raw=$(gregorian_to_hijri_date "$year" "$month" "$day")
    read h_year h_month h_day <<< "$hijri_raw"

    local -a ar_months=("محرم" "صفر" "ربيع الأول" "ربيع الثاني" "جمادى الأولى" "جمادى الثانية" "رجب" "شعبان" "رمضان" "شوال" "ذو القعدة" "ذو الحجة")
    local -a en_months=("Moharram" "Safar" "Rabie-I" "Rabie-II" "Jumada-I" "Jumada-II" "Rajab" "Shaban" "Ramadan" "Shawwal" "Delqada" "Delhijja")
    
    local m_ar=${ar_months[$((h_month-1))]}
    local m_en=${en_months[$((h_month-1))]}

    printf '{\n'
    printf '  "prayers": {\n'
    printf '    "fajr": "%s",\n'      "$(format_time $fajr)"
    printf '    "sunrise": "%s",\n'   "$(format_time $sunrise)"
    printf '    "dhuhr": "%s",\n'     "$(format_time $dhuhr)"
    printf '    "asr": "%s",\n'       "$(format_time $asr)"
    printf '    "maghreb": "%s",\n'   "$(format_time $maghreb)"
    printf '    "ishaa": "%s",\n'     "$(format_time $ishaa)"
    printf '    "midnight": "%s",\n'  "$(format_time $midnight)"
    printf '    "last_third": "%s"\n' "$(format_time $last_third)"
    printf '  },\n'
    printf '  "hijri": {\n'
    printf '    "day": %d,\n'          "$h_day"
    printf '    "month": %d,\n'        "$h_month"
    printf '    "month_name_ar": "%s",\n' "$m_ar"
    printf '    "month_name_en": "%s",\n' "$m_en"
    printf '    "year": %d,\n'         "$h_year"
    printf '    "full_ar": "%d %s %d",\n' "$h_day" "$m_ar" "$h_year"
    printf '    "full_en": "%d %s %d"\n'  "$h_day" "$m_en" "$h_year"
    printf '  }\n'
    printf '}\n'
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lat) shift; LAT="$1" ;;
        --lon) shift; LON="$1" ;;
        --timezone) shift; TIMEZONE="$1" ;;
        --year) shift; YEAR="$1" ;;
        --month) shift; MONTH="$1" ;;
        --day) shift; DAY="$1" ;;
        --method) shift; METHOD="$1" ;;
        --madhab) shift; MADHAB="$1" ;;
        --summer-time) shift; SUMMER_TIME="$1" ;;
        --elevation) shift; ELEV="$1" ;;
        -h|--help) echo "Usage: $0 --lat <lat> --lon <lon> ..."; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$LAT" || -z "$LON" ]]; then
    echo "Error: --lat and --lon are required."
    exit 1
fi

# Set defaults for date if not provided
YEAR=${YEAR:-$(date +%Y)}
MONTH=${MONTH:-$(date +%m)}
DAY=${DAY:-$(date +%d)}
TIMEZONE=${TIMEZONE:-0}
METHOD=${METHOD:-2}
MADHAB=${MADHAB:-1}
SUMMER_TIME=${SUMMER_TIME:-0}
ELEV=${ELEV:-0}

# example : ./combined.sh --lat 31.986 --lon 35.898 --timezone 3 --year 2025 --month 12 --day 24 --method 20 --madhab 1 --summer-time 0 --elevation 950
print_prayer_times_json $LON $LAT $TIMEZONE $YEAR $MONTH $DAY $METHOD $MADHAB $SUMMER_TIME $ELEV