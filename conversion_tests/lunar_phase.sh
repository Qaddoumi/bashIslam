#!/bin/bash

# ==============================================================================
# LUNAR_PHASE.SH - Bash port of lunar_phase.js
# Computes the lunar position, phase, and illuminated fraction of the Moon.
# Uses awk to replicate JavaScript's float arithmetic and trigonometric functions.
# ==============================================================================

# AWK library with math functions
AWK_LUNAR_LIB='
BEGIN {
    PI = 3.141592653589793
    RR = 180 / PI  # degrees in a radian
    OFMT = "%.17g"
}

# Generalized modulo function (n mod m) also valid for negative values of n
function gmod(n, m) {
    return ((n % m) + m) % m
}

# Cosine of an angle in degrees
function cosd(x) {
    return cos(gmod(x, 360) / RR)
}

# Sine of an angle in degrees  
function sind(x) {
    return sin(gmod(x, 360) / RR)
}

# Inverse cosine with angle in degrees
function acosd(x) {
    return RR * atan2(sqrt(1 - x*x), x)
}

# Square root
function sqrt_val(x) {
    return sqrt(x)
}
'

# ------------------------------------------------------------------------------
# gmod: Generalized modulo function (n mod m) also valid for negative values
# Usage: gmod <n> <m>
# ------------------------------------------------------------------------------
gmod() {
    local n=$1
    local m=$2
    awk -v n="$n" -v m="$m" "$AWK_LUNAR_LIB"'
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
    awk -v x="$x" "$AWK_LUNAR_LIB"'
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
    awk -v x="$x" "$AWK_LUNAR_LIB"'
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
    awk -v x="$x" "$AWK_LUNAR_LIB"'
    {
        print acosd(x)
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# tjd_now: Computes the current Julian Day Number
# Usage: tjd_now
# Returns: Julian Day Number as a floating point
# ------------------------------------------------------------------------------
tjd_now() {
    local year=$(date -u +%Y)
    local month=$(date -u +%-m)  # No leading zero
    local day=$(date -u +%-d)    # No leading zero
    local hours=$(date -u +%-H)  # No leading zero
    local minutes=$(date -u +%-M) # No leading zero
    local seconds=$(date -u +%-S) # No leading zero
    
    # Add 1 minute for approximate correction to TAI (as in JS)
    minutes=$((minutes + 1))
    
    awk -v year="$year" -v month="$month" -v day="$day" \
        -v hours="$hours" -v minutes="$minutes" -v seconds="$seconds" "$AWK_LUNAR_LIB"'
    BEGIN {
        OFMT = "%.17g"
    }
    {
        m = month + 1
        y = year
        
        if (m < 3) {
            y = y - 1
            m = m + 12
        }
        
        c = int(y / 100)
        jgc = c - int(c / 4) - 2
        
        cjdn = int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + day - jgc - 1524
        
        tjd = cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24
        print tjd
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# tjd_from_date: Computes Julian Day Number from specific date/time
# Usage: tjd_from_date <year> <month> <day> <hours> <minutes> <seconds>
# Returns: Julian Day Number as a floating point
# ------------------------------------------------------------------------------
tjd_from_date() {
    local year=$1
    local month=$2
    local day=$3
    local hours=${4:-12}
    local minutes=${5:-0}
    local seconds=${6:-0}
    
    awk -v year="$year" -v month="$month" -v day="$day" \
        -v hours="$hours" -v minutes="$minutes" -v seconds="$seconds" "$AWK_LUNAR_LIB"'
    BEGIN {
        OFMT = "%.17g"
    }
    {
        m = month + 1
        y = year
        
        if (m < 3) {
            y = y - 1
            m = m + 12
        }
        
        c = int(y / 100)
        jgc = c - int(c / 4) - 2
        
        cjdn = int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + day - jgc - 1524
        
        tjd = cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24
        print tjd
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# moonpos: Computes the lunar position and distance
# Usage: moonpos <tjd>
# Returns: lmoon bmoon rmoon lsun rsun (space-separated)
# ------------------------------------------------------------------------------
moonpos() {
    local tjd=$1
    
    awk -v tjd="$tjd" "$AWK_LUNAR_LIB"'
    BEGIN {
        OFMT = "%.17g"
    }
    {
        t = (tjd - 2451545) / 36525
        
        # Mean lunar longitude
        lm0 = gmod(218.3164 + 481267.8812 * t, 360)
        # Mean solar longitude
        ls0 = gmod(280.4665 + 36000.7698 * t, 360)
        
        # Mean luni-solar elongation
        d = gmod(297.8502 + 445267.1114 * t, 360)
        # Argument of lunar latitude
        f = gmod(93.2721 + 483202.0175 * t, 360)
        # Mean lunar anomaly
        ml = gmod(134.9634 + 477198.8675 * t, 360)
        # Lunar node
        nl = gmod(125.0445 - 1934.1363 * t, 360)
        # Mean solar anomaly
        ms = gmod(357.5291 + 35999.0503 * t, 360)
        
        # Lunar latitude (bmoon)
        bmoon = 5.128 * sind(f) + 0.281 * sind(ml + f) + 0.278 * sind(ml - f) + \
                0.173 * sind(2 * d - f) + 0.055 * sind(2 * d - ml + f) + \
                0.046 * sind(2 * d - ml - f) + 0.033 * sind(2 * d + f)
        
        # Lunar longitude (lmoon)
        lmoon = lm0 + 6.289 * sind(ml) + 1.274 * sind(2 * d - ml) + 0.658 * sind(2 * d) + \
                0.214 * sind(2 * ml) - 0.185 * sind(ms) - 0.114 * sind(2 * f) + \
                0.059 * sind(2 * d - 2 * ml) + 0.057 * sind(2 * d - ms - ml) + \
                0.053 * sind(2 * d + ml) + 0.046 * sind(2 * d - ms) - 0.041 * sind(ms - ml) - \
                0.035 * sind(d) - 0.030 * sind(ms + ml)
        
        # Solar longitude
        lsun = ls0 - 0.0057 + 1.915 * sind(ms) + 0.020 * sind(2 * ms) - 0.0048 * sind(nl)
        
        # Lunar distance (in AU)
        rmoon = (385000.6 - 20905.4 * cosd(ml) - 3699.1 * cosd(2 * d - ml) - \
                 2956.0 * cosd(2 * d) - 569.9 * cosd(2 * ml)) / 149597870
        
        # Solar distance (in AU)
        rsun = 1.00014 - 0.01671 * cosd(ms) - 0.00014 * cosd(2 * ms)
        
        print lmoon, bmoon, rmoon, lsun, rsun
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# lunarphase: Computes luni-solar elongation and phase angle
# Usage: lunarphase <tjd>
# Returns: elone phase (space-separated, both in degrees)
# ------------------------------------------------------------------------------
lunarphase() {
    local tjd=$1
    
    # Get moon position
    local lunpos=$(moonpos "$tjd")
    local lmoon=$(echo "$lunpos" | awk '{print $1}')
    local bmoon=$(echo "$lunpos" | awk '{print $2}')
    local rmoon=$(echo "$lunpos" | awk '{print $3}')
    local lsun=$(echo "$lunpos" | awk '{print $4}')
    local rsun=$(echo "$lunpos" | awk '{print $5}')
    
    awk -v lmoon="$lmoon" -v bmoon="$bmoon" -v rmoon="$rmoon" \
        -v lsun="$lsun" -v rsun="$rsun" "$AWK_LUNAR_LIB"'
    BEGIN {
        OFMT = "%.17g"
    }
    {
        # Luni-solar elongation (measured along the ecliptic)
        elone = gmod(lmoon - lsun, 360)
        
        # Moon position in 3D
        xm = rmoon * cosd(bmoon) * cosd(lmoon)
        ym = rmoon * cosd(bmoon) * sind(lmoon)
        zm = rmoon * sind(bmoon)
        
        # Sun position in 3D (on ecliptic, so z = 0)
        xs = rsun * cosd(lsun)
        ys = rsun * sind(lsun)
        
        # Vector from Sun to Moon
        xms = xm - xs
        yms = ym - ys
        zms = zm
        
        # Distance Moon-Sun
        rms = sqrt(xms * xms + yms * yms + zms * zms)
        
        # Phase angle
        dot_product = xm * xms + ym * yms + zm * zms
        phase = acosd(dot_product / (rmoon * rms))
        
        print elone, phase
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# moon_flum_now: Computes the illuminated fraction of the lunar disk (current)
# Usage: moon_flum_now
# Returns: Illuminated fraction as decimal (e.g., "0.523")
# ------------------------------------------------------------------------------
moon_flum_now() {
    local tjd=$(tjd_now)
    moon_flum "$tjd"
}

# ------------------------------------------------------------------------------
# moon_flum: Computes the illuminated fraction of the lunar disk
# Usage: moon_flum <tjd>
# Returns: Illuminated fraction as decimal (e.g., "0.523")
# ------------------------------------------------------------------------------
moon_flum() {
    local tjd=$1
    
    # Get phase info
    local phase_info=$(lunarphase "$tjd")
    local phase=$(echo "$phase_info" | awk '{print $2}')
    
    awk -v phase="$phase" "$AWK_LUNAR_LIB"'
    BEGIN {
        OFMT = "%.17g"
    }
    {
        # Illuminated fraction
        k = (1 + cosd(phase)) / 2
        
        # Round to 3 decimal places
        k = int(1000 * k + 0.5)
        
        # Format output
        if (k < 10) {
            printf "0.00%d\n", k
        } else if (k < 100) {
            printf "0.0%d\n", k
        } else if (k < 1000) {
            printf "0.%d\n", k
        } else {
            print "1.000"
        }
    }' <<< "run"
}

# ------------------------------------------------------------------------------
# get_moon_phase_name: Get the name of the moon phase based on illumination
# Usage: get_moon_phase_name <illumination>
# Returns: Name of the moon phase
# ------------------------------------------------------------------------------
get_moon_phase_name() {
    local illumination=$1
    
    awk -v illum="$illumination" '
    BEGIN {
        k = illum + 0
        if (k < 0.03) {
            print "New Moon"
        } else if (k < 0.25) {
            print "Waxing Crescent"
        } else if (k < 0.50) {
            print "First Quarter"
        } else if (k < 0.75) {
            print "Waxing Gibbous"
        } else if (k < 0.97) {
            print "Full Moon"
        } else {
            print "Full Moon"
        }
    }'
}

# ------------------------------------------------------------------------------
# get_moon_phase_emoji: Get emoji for the moon phase
# Usage: get_moon_phase_emoji <elongation>
# Returns: Moon phase emoji
# ------------------------------------------------------------------------------
get_moon_phase_emoji() {
    local elone=$1
    
    awk -v e="$elone" '
    BEGIN {
        e = e + 0
        # Normalize elongation to 0-360
        while (e < 0) e += 360
        while (e >= 360) e -= 360
        
        if (e < 22.5)        print "🌑"  # New Moon
        else if (e < 67.5)   print "🌒"  # Waxing Crescent
        else if (e < 112.5)  print "🌓"  # First Quarter
        else if (e < 157.5)  print "🌔"  # Waxing Gibbous
        else if (e < 202.5)  print "🌕"  # Full Moon
        else if (e < 247.5)  print "🌖"  # Waning Gibbous
        else if (e < 292.5)  print "🌗"  # Last Quarter
        else if (e < 337.5)  print "🌘"  # Waning Crescent
        else                 print "🌑"  # New Moon
    }'
}

# ==============================================================================
# If sourced, export functions. If run directly, show demo output.
# ==============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Lunar Phase Calculator (Bash) ==="
    echo ""
    
    tjd=$(tjd_now)
    echo "Current Julian Day: $tjd"
    echo ""
    
    echo "Moon Position:"
    moonpos "$tjd"
    echo ""
    
    echo "Lunar Phase (elongation, phase angle):"
    phase_info=$(lunarphase "$tjd")
    echo "$phase_info"
    echo ""
    
    elone=$(echo "$phase_info" | awk '{print $1}')
    echo "Illuminated Fraction:"
    illum=$(moon_flum "$tjd")
    echo "$illum"
    echo ""
    
    echo "Moon Phase Emoji: $(get_moon_phase_emoji "$elone")"
fi
