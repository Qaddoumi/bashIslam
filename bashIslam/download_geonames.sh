#!/bin/bash

# ==============================================================================
# GeoNames World Cities Database Downloader
# Creates a searchable database of cities worldwide with elevations
# ==============================================================================

GEONAMES_URL="http://download.geonames.org/export/dump"
OUTPUT_DIR="./geonames_data"
DB_FILE="$OUTPUT_DIR/world_cities.txt"

# ==============================================================================
# Download Options
# ==============================================================================

download_all_cities() {
    echo "Downloading all cities worldwide (cities15000 - 23MB)..."
    echo "This includes cities with population > 15,000"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Download cities with population > 15,000 (good balance of size/coverage)
    wget -O "$OUTPUT_DIR/cities15000.zip" "$GEONAMES_URL/cities15000.zip"
    
    echo "Extracting..."
    unzip -o "$OUTPUT_DIR/cities15000.zip" -d "$OUTPUT_DIR"
    
    echo "Processing data..."
    # Extract: name, latitude, longitude, country, admin1, population, elevation
    awk -F'\t' '{
        printf "%s|%s|%s|%s|%s|%s|%s\n", $2, $5, $6, $9, $11, $15, $16
    }' "$OUTPUT_DIR/cities15000.txt" > "$DB_FILE"
    
    echo "Done! Database saved to: $DB_FILE"
    echo "Total cities: $(wc -l < "$DB_FILE")"
}

download_specific_country() {
    local country_code=$1
    
    echo "Downloading data for country: $country_code"
    mkdir -p "$OUTPUT_DIR"
    
    wget -O "$OUTPUT_DIR/${country_code}.zip" "$GEONAMES_URL/${country_code}.zip"
    unzip -o "$OUTPUT_DIR/${country_code}.zip" -d "$OUTPUT_DIR"
    
    # Process and filter cities only
    awk -F'\t' '$7 ~ /^PPL/ {
        printf "%s|%s|%s|%s|%s|%s|%s\n", $2, $5, $6, $9, $11, $15, $16
    }' "$OUTPUT_DIR/${country_code}.txt" > "$OUTPUT_DIR/${country_code}_cities.txt"
    
    echo "Done! Cities saved to: $OUTPUT_DIR/${country_code}_cities.txt"
}

# ==============================================================================
# Search Functions
# ==============================================================================

search_city() {
    local city_name=$1
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo "Error: Database not found. Run: $0 download" >&2
        return 1
    fi
    
    echo "Searching for: $city_name"
    echo "Format: Name|Lat|Lon|Country|Region|Population|Elevation"
    echo "---"
    
    grep -i "$city_name" "$DB_FILE" | head -20
}

get_elevation() {
    local city_name=$1
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo "Error: Database not found. Run: $0 download" >&2
        return 1
    fi
    
    # Get first match and extract elevation (7th field)
    local result=$(grep -i "^${city_name}|" "$DB_FILE" | head -1)
    
    if [[ -z "$result" ]]; then
        echo "City not found: $city_name" >&2
        return 1
    fi
    
    local elevation=$(echo "$result" | cut -d'|' -f7)
    local lat=$(echo "$result" | cut -d'|' -f2)
    local lon=$(echo "$result" | cut -d'|' -f3)
    local country=$(echo "$result" | cut -d'|' -f4)
    
    echo "City: $city_name"
    echo "Country: $country"
    echo "Coordinates: $lat, $lon"
    echo "Elevation: ${elevation}m"
}

# ==============================================================================
# Create Bash Lookup Function
# ==============================================================================

generate_bash_db() {
    local country_filter=$1
    local output_file=${2:-"city_elevations_db.sh"}
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo "Error: Database not found. Run: $0 download" >&2
        return 1
    fi
    
    echo "Generating Bash lookup script: $output_file"
    
    cat > "$output_file" << 'EOF'
#!/bin/bash

# Auto-generated city elevation lookup database
# Format: city_name:lat:lon:elevation:country

declare -A CITY_DATA=(
EOF
    
    # Add city data
    if [[ -n "$country_filter" ]]; then
        awk -F'|' -v country="$country_filter" '
        $4 == country {
            gsub(/"/, "\\\"", $1)  # Escape quotes in names
            printf "    [\"%s\"]=\"%s:%s:%s:%s\"\n", tolower($1), $2, $3, $7, $4
        }' "$DB_FILE" >> "$output_file"
    else
        awk -F'|' '
        {
            gsub(/"/, "\\\"", $1)
            printf "    [\"%s\"]=\"%s:%s:%s:%s\"\n", tolower($1), $2, $3, $7, $4
        }' "$DB_FILE" | head -10000 >> "$output_file"  # Limit to 10k cities
    fi
    
    cat >> "$output_file" << 'EOF'
)

get_city_elevation() {
    local city=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    if [[ -z "${CITY_DATA[$city]}" ]]; then
        echo "City not found: $1" >&2
        return 1
    fi
    
    IFS=':' read -r lat lon elev country <<< "${CITY_DATA[$city]}"
    echo "$elev"
}

get_city_info() {
    local city=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    if [[ -z "${CITY_DATA[$city]}" ]]; then
        echo "City not found: $1" >&2
        return 1
    fi
    
    IFS=':' read -r lat lon elev country <<< "${CITY_DATA[$city]}"
    echo "Latitude: $lat"
    echo "Longitude: $lon"
    echo "Elevation: ${elev}m"
    echo "Country: $country"
}

# If script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -z "$1" ]]; then
        echo "Usage: $0 <city_name>"
        echo "Example: $0 Amman"
        exit 1
    fi
    get_city_info "$1"
fi
EOF
    
    chmod +x "$output_file"
    echo "Done! Use: ./$output_file <city_name>"
}

# ==============================================================================
# Country Codes Reference
# ==============================================================================

show_country_codes() {
    cat << 'EOF'
Common Country Codes:
  JO = Jordan
  SA = Saudi Arabia
  AE = United Arab Emirates
  EG = Egypt
  US = United States
  GB = United Kingdom
  FR = France
  DE = Germany
  CN = China
  IN = India
  JP = Japan
  BR = Brazil
  AU = Australia

Full list: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
EOF
}

# ==============================================================================
# Main Script
# ==============================================================================

case "$1" in
    download)
        download_all_cities
        ;;
    country)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 country <country_code>"
            echo "Example: $0 country JO"
            show_country_codes
            exit 1
        fi
        download_specific_country "$2"
        ;;
    search)
        search_city "$2"
        ;;
    elevation)
        get_elevation "$2"
        ;;
    generate)
        generate_bash_db "$2" "$3"
        ;;
    codes)
        show_country_codes
        ;;
    *)
        cat << EOF
GeoNames World Cities Database Tool

Usage:
  $0 download                      - Download all major cities (pop > 15k)
  $0 country <CODE>                - Download specific country (e.g., JO for Jordan)
  $0 search <name>                 - Search for cities
  $0 elevation <name>              - Get elevation for specific city
  $0 generate [country] [output]   - Generate Bash lookup script
  $0 codes                         - Show country codes

Examples:
  $0 download                      # Download global database
  $0 country JO                    # Download all Jordan locations
  $0 search Amman                  # Search for Amman
  $0 elevation Amman               # Get Amman's elevation
  $0 generate JO jordan_cities.sh  # Create Jordan-only lookup script
  $0 generate                      # Create global lookup (10k cities max)

After downloading, integrate with prayer times:
  source ./jordan_cities.sh
  elev=\$(get_city_elevation "Amman")
  ./praytimes.sh print_prayer_times 35.9435 31.9555 3 2025 12 24 20 1 0 "\$elev"
EOF
        ;;
esac