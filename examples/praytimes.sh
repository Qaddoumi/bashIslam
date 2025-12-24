#!/bin/bash

# ==============================================================================
# BashIslam Usage Example
# Demonstrates all major features of the bash port:
# - Prayer times (Raw, Formatted, JSON)
# - Hijri date (Current, Format, Conversion)
# - Qiblah direction
# ==============================================================================

# Important: Use absolute path or relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Based on project structure, pyIslam is in the parent or same dir
# Assuming this is run from the project root or examples dir
if [ -f "$SCRIPT_DIR/../pyIslam/praytimes.sh" ]; then
    LIB_DIR="$SCRIPT_DIR/../pyIslam"
elif [ -f "$SCRIPT_DIR/pyIslam/praytimes.sh" ]; then
    LIB_DIR="$SCRIPT_DIR/pyIslam"
else
    # Fallback to current directory if not found
    LIB_DIR="."
fi

source "$LIB_DIR/praytimes.sh"
source "$LIB_DIR/hijri.sh"
source "$LIB_DIR/qiblah.sh"

echo "-------------------------------------"
echo "   Usage example of BashIslam"
echo "-------------------------------------"

# 1. Coordinate Input
read -p "1. Enter longitude (default Cairo 31.2357): " LON
LON=${LON:-31.2357}
read -p "2. Enter latitude (default Cairo 30.0444): " LAT
LAT=${LAT:-30.0444}
read -p "3. Enter timezone (GMT+n, default 2): " TZ
TZ=${TZ:-2}

# 2. Method Selection
echo -e "\n4. Choose calculation method:"
echo "-------------------------------------"
for i in {1..20}; do
    # This is a bit hacky since we don't have a name-list function, 
    # but we can call get_method_params and look at the comment
    line=$(grep -E "^\s*${i}\)" "$LIB_DIR/praytimes.sh")
    name=$(echo "$line" | cut -d'#' -f2- | sed 's/^ //')
    if [ -n "$name" ]; then
        printf "%2d) %s\n" "$i" "$name"
    fi
done
read -p "Enter choice (default 2): " METHOD
METHOD=${METHOD:-2}

# 3. Madhab Selection
echo -e "\n5. Choose Asr Madhab:"
echo "1 = Shafi'i, Maliki, Hanbali (Standard)"
echo "2 = Hanafi"
read -p "Enter choice (default 1): " MADHAB
MADHAB=${MADHAB:-1}

# 4. Elevation (Optional feature added earlier)
read -p "6. Enter elevation in meters (optional, default 0): " ELEV
ELEV=${ELEV:-0}

# --- Calculations ---

# Current Date
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)

# Raw decimal values
RAW_TIMES=$(calculate_prayer_times "$LON" "$LAT" "$TZ" "$YEAR" "$MONTH" "$DAY" "$METHOD" "$MADHAB" 0 "$ELEV")
read fajr sun dhuhr asr magh isha mid last <<< "$RAW_TIMES"

# Hijri Date
HIJRI_RAW=$(get_today_hijri)
HIJRI_FMT=$(format_hijri "$HIJRI_RAW" 2)

# Qiblah
QIBLAH_DEG=$(get_qiblah_direction "$LON" "$LAT")
QIBLAH_FMT=$(format_qiblah_dms "$QIBLAH_DEG")

# --- Display Results ---

echo -e "\n====================================="
echo "        CALCULATION RESULTS"
echo "====================================="
echo "Location:  $LAT, $LON (TZ: $TZ)"
echo "Date:      $(date +%F) / $HIJRI_FMT"
echo "Elevation: ${ELEV}m"
echo "-------------------------------------"

# Standard Formatted Output
print_prayer_times "$LON" "$LAT" "$TZ" "$YEAR" "$MONTH" "$DAY" "$METHOD" "$MADHAB" 0 "$ELEV"

echo "-------------------------------------"
echo "Midnight:  $(format_time $mid)"
echo "LastThird: $(format_time $last)"
echo "Qiblah:    $QIBLAH_FMT ($QIBLAH_DEG° from North)"
echo "-------------------------------------"

# Demonstration of JSON output
echo -e "\nJSON Format Example:"
print_prayer_times_json "$LON" "$LAT" "$TZ" "$YEAR" "$MONTH" "$DAY" "$METHOD" "$MADHAB" 0 "$ELEV"

echo -e "\n-------------------------------------"

echo -e "Example for Jordan"
print_prayer_times 35.898 31.986 3 2025 12 24 20 1 0 950

echo -e "\n-------------------------------------"
echo "Done."
