#!/bin/bash

# Load base libraries
source "./baselib.sh"

# ==============================================================================
# Qiblah Direction Calculation
# ==============================================================================

# Function to calculate Qiblah direction in decimal degrees from North
# Usage: get_qiblah_direction <longitude> <latitude>
get_qiblah_direction() {
    local longitude=$1
    local latitude=$2
    
    awk -v lon="$longitude" -v lat="$latitude" "$AWK_LIB"'
    BEGIN {
        MAKKAH_LATI = 21.42249
        MAKKAH_LONG = 39.826174
        
        lamda = MAKKAH_LONG - lon
        num = dcos(MAKKAH_LATI) * dsin(lamda)
        denom = (dsin(MAKKAH_LATI) * dcos(lat) - dcos(MAKKAH_LATI) * dsin(lat) * dcos(lamda))
        
        qiblah_dir = (180 / PI) * atan2(num, denom)
        
        # Adjust for 0-360 range
        if (qiblah_dir < 0) {
            qiblah_dir += 360
        }
        
        print qiblah_dir
    }'
}

# Function to format degrees into DMS (Degrees, Minutes, Seconds)
# Usage: format_qiblah_dms <decimal_degrees>
format_qiblah_dms() {
    local deg=$1
    awk -v d="$deg" 'BEGIN {
        h = int(d)
        m_float = (d - h) * 60
        m = int(m_float)
        s_float = (m_float - m) * 60
        s = int(s_float)
        
        printf "%d° %d'\'' %d'\'\''\n", h, m, s
    }'
}
