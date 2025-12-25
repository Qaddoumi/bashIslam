#!/bin/bash

# ==============================================================================
# Ported from https://webspace.science.uu.nl/~gent0113/islam/addfiles/ummalqura_calendar.js
# ==============================================================================

# Load the table data
source "$(dirname "$0")/islamcalendar_dat.sh"

# We define the math logic in an AWK variable to reuse it across functions.
AWK_LIB='
BEGIN {
    PI = 3.141592653589793
    OFMT = "%.17g"
}

function floor(x) {
    return (x == int(x)) ? x : (x < 0) ? int(x) - 1 : int(x)
}
'

# ------------------------------------------------------------------------------
# UmmAlQuraCalendar - Main conversion function
# Python equivalent: UmmAlQuraCalendar class __init__
#
# Usage: UmmAlQura year month day
# Outputs (one per line):
#   GREG_DATE: year month day
#   WEEK_DAY: weekday (1=Sunday, 7=Saturday)
#   JULIAN_DAY: cjdn
#   HIJRI_DATE: year month day
#   SOLAR_HIJRI_DATE: year month day
#   ISLAMIC_LUNATION_NUM: lunation number
#   ISLAMIC_MONTH_LENGTH: month length
# ------------------------------------------------------------------------------
CalculateDate() {
    local year=$1
    local month=$2
    local day=$3
    local table=$4
    
    # Pass table as a string joined by spaces for awk to parse
    local table_str="${table[*]}"
    local table_len="${#table[@]}"
    
    awk -v y="$year" -v m="$month" -v d="$day" \
        -v table_str="$table_str" -v table_len="$table_len" \
        "$AWK_LIB"'
    BEGIN {
        # Parse the table into an array (1-indexed for convenience, matching Python 0-indexed)
        n = split(table_str, table, " ")
    }
    {
        # Read calendar data
        year = y + 0
        month = m + 0
        day = d + 0
        
        # Append January and February to the previous year
        if (month < 3) {
            year -= 1
            month += 12
        }
        
        # Compute offset between Julian and Gregorian calendar
        a = floor(year / 100.0)
        jgc = a - floor(a / 4.0) - 2
        
        # Compute Chronological Julian Day Number (CJDN)
        cjdn = floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day - jgc - 1524
        
        # Compute Gregorian date from CJDN
        a2 = floor((cjdn - 1867216.25) / 36524.25)
        jgc2 = a2 - floor(a2 / 4.0) + 1
        b = cjdn + jgc2 + 1524
        c = floor((b - 122.1) / 365.25)
        d_val = floor(365.25 * c)
        out_month = floor((b - d_val) / 30.6001)
        out_day = (b - d_val) - floor(30.6001 * out_month)
        
        if (out_month > 13) {
            c += 1
            out_month -= 12
        }
        
        out_month -= 1
        out_year = c - 4716
        
        # Compute weekday (1=Sunday, 7=Saturday)
        wd = ((cjdn + 1) % 7) + 1
        
        # Output Gregorian date and weekday
        print "GREG_DATE:", out_year, out_month, int(out_day)
        print "WEEK_DAY:", wd
        print "JULIAN_DAY:", cjdn
        
        # Compute Modified Chronological Julian Day Number (MCJDN)
        mcjdn = cjdn - 2400000
        
        # Find the lunation index in the table (match Python index i)
        i = 0
        for (k = 0; k < table_len; k++) {
            i = k
            if (table[k + 1] > mcjdn) {
                break
            }
        }
        
        # Compute Umm al-Qura calendar date
        iln = i + 16260
        ii = floor((iln - 1) / 12)
        iy = ii + 1
        im = iln - 12 * ii
        
        # Handle index for id/ml (Python i matches Bash 0..N-1, or 1..N in table)
        # Python uses UMMALQURA_TABLE[i-1]. If i=1, it is index 0. Bash table[1].
        # If i=0, it is index -1. Bash table[table_len].
        t1 = (i == 0 ? table_len : i)
        id = mcjdn - table[t1] + 1
        ml = table[i + 1] - table[t1]
        
        print "HIJRI_DATE:", iy, im, int(id)
        
        # Compute solar Hijri date
        epoch = 450947 + jgc
        
        sy = floor((mcjdn + epoch) / 365.25)
        sd = (mcjdn + epoch) - floor(365.25 * sy)
        
        if (sd < 186.5) {
            sm = floor(sd / 31.0001)
            sd = sd - floor(31.0001 * sm)
            sm = sm + 6
        } else {
            sy = sy + 1
            sm = floor((sd - 186) / 30.0001)
            sd = (sd - 186) - floor(30.0001 * sm)
        }
        
        # Fix for leap day in Gregorian leap year
        if (sd == 0 && sm == 6) {
            sd = 30
            sm = 5
        }
        
        print "SOLAR_HIJRI_DATE:", (sy + 2), sm, int(sd)
        print "ISLAMIC_LUNATION_NUM:", iln
        print "ISLAMIC_MONTH_LENGTH:", ml
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# Helper functions to extract specific values
# ------------------------------------------------------------------------------

# Get Gregorian date from CalculateDate output
get_greg_date() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^GREG_DATE:" | awk '{print $2, $3, $4}'
}

# Get weekday from CalculateDate output
get_week_day() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^WEEK_DAY:" | awk '{print $2}'
}

# Get Julian day from CalculateDate output
get_julian_day() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^JULIAN_DAY:" | awk '{print $2}'
}

# Get Hijri date from CalculateDate output
get_hijri_date() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^HIJRI_DATE:" | awk '{print $2, $3, $4}'
}

# Get solar Hijri date from CalculateDate output
get_solar_hijri_date() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^SOLAR_HIJRI_DATE:" | awk '{print $2, $3, $4}'
}

# Get Islamic lunation number from CalculateDate output
get_islamic_lunation_num() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^ISLAMIC_LUNATION_NUM:" | awk '{print $2}'
}

# Get Islamic month length from CalculateDate output
get_islamic_month_length() {
    CalculateDate "$1" "$2" "$3" "$4" | grep "^ISLAMIC_MONTH_LENGTH:" | awk '{print $2}'
}
