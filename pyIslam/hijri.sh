#!/bin/bash

# Load the math engine
source "./baselib.sh"

# ------------------------------------------------------------------------------
# HijriDate "Constructor" (Internal logic)
# Python equivalent: __init__
# ------------------------------------------------------------------------------
_validate_hijri() {
    local y=$1 m=$2 d=$3
    if [[ ! "$y" =~ ^[0-9]+$ ]]; then echo "year must be an int"; return 1; fi
    if (( m < 1 || m > 12 )); then echo "month should be between 1 and 12"; return 1; fi
    if (( d < 1 || d > 30 )); then echo "day should be between 1 and 30"; return 1; fi
}

# ------------------------------------------------------------------------------
# Hijri to Gregorian
# Python equivalent: HijriDate.to_gregorian()
# ------------------------------------------------------------------------------
hijri_to_gregorian_date() {
    local y=$1 m=$2 d=$3
    _validate_hijri "$y" "$m" "$d" || return 1
    
    # Get Julian Day from Hijri
    local jd=$(hijri_to_julian "$y" "$m" "$d")
    # Convert Julian to Gregorian
    julian_to_gregorian "$jd"
}

# ------------------------------------------------------------------------------
# Gregorian to Hijri
# Python equivalent: HijriDate.get_hijri()
# ------------------------------------------------------------------------------
gregorian_to_hijri_date() {
    local y=$1 m=$2 d=$3
    local corr=${4:-0}
    
    local jd=$(gregorian_to_julian "$y" "$m" "$d")
    julian_to_hijri "$jd" "$corr"
}

# ------------------------------------------------------------------------------
# Formatting
# Python equivalent: HijriDate.format()
# ------------------------------------------------------------------------------
format_hijri() {
    local y=$1 m=$2 d=$3 lang=$4
    
    local -a ar_months=("محرم" "صفر" "ربيع الأول" "ربيع الثاني" "جمادى الأولى" "جمادى الثانية" "رجب" "شعبان" "رمضان" "شوال" "ذو القعدة" "ذو الحجة")
    local -a en_months=("Moharram" "Safar" "Rabie-I" "Rabie-II" "Jumada-I" "Jumada-II" "Rajab" "Shaban" "Ramadan" "Shawwal" "Delqada" "Delhijja")

    if [[ "$lang" == "1" ]]; then
        echo "$d ${ar_months[$((m-1))]} $y"
    elif [[ "$lang" == "2" ]]; then
        echo "$d ${en_months[$((m-1))]} $y"
    else
        # Numeric Format: DD-MM-YYYY
        printf "%02d-%02d-%04d\n" "$d" "$m" "$y"
    fi
}

# ------------------------------------------------------------------------------
# Next Date & Last Day Check
# Python equivalent: next_date() and is_last()
# ------------------------------------------------------------------------------
is_last_hijri_day() {
    local y=$1 m=$2 d=$3
    local jd=$(hijri_to_julian "$y" "$m" "$d")
    
    # Get the month of the next day
    local next_month=$(julian_to_hijri "$((jd + 1))" | awk '{print $2}')
    
    if [[ "$m" != "$next_month" ]]; then
        echo "True"
    else
        echo "False"
    fi
}