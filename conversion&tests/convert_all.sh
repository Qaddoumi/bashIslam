#!/bin/bash

# ==============================================================================
# Convert Hijri date using all Islamic calendar systems
# ==============================================================================

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <hijri_year> <hijri_month> <hijri_day>"
    echo "Example: $0 1446 6 22"
    exit 1
fi

YEAR=$1
MONTH=$2
DAY=$3

# Load the table data from islamcalendar_dat.sh
source "$(dirname "$0")/islamcalendar_dat.sh"

# AWK library for calculations
AWK_LIB='
BEGIN {
    PI = 3.141592653589793
    OFMT = "%.17g"
}

function floor(x) {
    return (x == int(x)) ? x : (x < 0) ? int(x) - 1 : int(x)
}
'

# Function to convert Hijri to Gregorian using a specific table
convert_hijri() {
    local year=$1
    local month=$2
    local day=$3
    local table_name=$4
    local table_str=$5
    local table_len=$6
    
    awk -v y="$year" -v m="$month" -v d="$day" \
        -v cal_name="$table_name" \
        -v table_str="$table_str" \
        -v table_len="$table_len" \
        "$AWK_LIB"'
    BEGIN {
        # Parse the table into an array
        n = split(table_str, table, " ")
        
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
        
        # Weekday names
        weekdays[1] = "Sunday"
        weekdays[2] = "Monday"
        weekdays[3] = "Tuesday"
        weekdays[4] = "Wednesday"
        weekdays[5] = "Thursday"
        weekdays[6] = "Friday"
        weekdays[7] = "Saturday"
        
        # Output result
        printf "%s: %04d-%02d-%02d (%s)\n", cal_name, out_year, out_month, int(out_day), weekdays[wd]
    }' <<< "run"
}

# Print header
echo "=========================================="
echo "Converting Hijri Date: $YEAR/$MONTH/$DAY"
echo "=========================================="
echo ""

# Convert using Arabian calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "Arabian     " "${arabian_dat[*]}" "${#arabian_dat[@]}"

# Convert using Diyanet calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "Diyanet     " "${diyanet_dat[*]}" "${#diyanet_dat[@]}"

# Convert using MABIMS Indonesia calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "MABIMS-ID   " "${mabims_id_dat[*]}" "${#mabims_id_dat[@]}"

# Convert using MABIMS Malaysia calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "MABIMS-MY   " "${mabims_my_dat[*]}" "${#mabims_my_dat[@]}"

# Convert using MABIMS Singapore calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "MABIMS-SI   " "${mabims_si_dat[*]}" "${#mabims_si_dat[@]}"

# Convert using Umm al-Qura calendar
convert_hijri "$YEAR" "$MONTH" "$DAY" "Umm al-Qura" "${ummalqura_dat[*]}" "${#ummalqura_dat[@]}"

echo ""