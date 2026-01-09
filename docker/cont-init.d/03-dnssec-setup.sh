#!/bin/sh

# DNSSEC setup script for master zones (BIND 9.20 compatible)
# Automatically discover zones from /etc/bind/dnssec directory
KEYS_DIR="/etc/bind/dnssec-keys"
DNSSEC_ZONES_DIR="/etc/bind/dnssec"

log()   { echo "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
warn()  { echo "\033[1;33m[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1\033[0m"; }
error() { echo "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"; }

# Start haveged to provide entropy
haveged -w 1024 &
HAVEGED_PID=$!
sleep 1  # Give it a moment to start

# Function to discover zones from db.* files in dnssec directory
get_zones() {
    ZONES=""
    if [ -d "$DNSSEC_ZONES_DIR" ]; then
        for zone_file in "$DNSSEC_ZONES_DIR"/db.*; do
            if [ -f "$zone_file" ] && [[ ! "$zone_file" =~ \.signed$ ]]; then
                # Extract zone name from db.zonename format
                zone_name=$(basename "$zone_file" | sed 's/^db\.//')
                ZONES="$ZONES $zone_name"
            fi
        done
    fi
    echo $ZONES
}

ZONES=$(get_zones)

# Create directory for DNSSEC keys
mkdir -p $KEYS_DIR
chown named:named $KEYS_DIR
chmod 755 $KEYS_DIR

log "Setting up DNSSEC for zones: $ZONES"

for zone in $ZONES; do
    log "Processing zone: $zone"

    # Create zone-specific key directory
    ZONE_KEYS_DIR="$KEYS_DIR/$zone"
    mkdir -p $ZONE_KEYS_DIR
    cd $ZONE_KEYS_DIR

    # Generate ZSK (Zone Signing Key) if it doesn't exist
    if ! ls K${zone}.+*.key > /dev/null 2>&1; then
        log "Generating ZSK for $zone"
        dnssec-keygen -a RSASHA256 -b 2048 -n ZONE $zone >/dev/null
    else
        log "ZSK for $zone already exists"
    fi

    # Generate KSK (Key Signing Key) if it doesn't exist
    if ! ls K${zone}.+*+KSK.key > /dev/null 2>&1; then
        log "Generating KSK for $zone"
        dnssec-keygen -a RSASHA256 -b 4096 -f KSK -n ZONE $zone >/dev/null
    else
        log "KSK for $zone already exists"
    fi

    # Consolidate public keys into one file for inclusion
    KEYS_FILE="$ZONE_KEYS_DIR/keys.conf"
    log "Consolidating keys into $KEYS_FILE"
    # Clear the file to prevent duplicates
    > $KEYS_FILE
    for key in $(ls K${zone}.+*.key); do
        echo "\$INCLUDE $ZONE_KEYS_DIR/$key" >> $KEYS_FILE
    done
    chown named:named $KEYS_FILE

    # Add $INCLUDE to zone files if not already present
    # Check main dnssec zone file
    MAIN_ZONE_FILE="$DNSSEC_ZONES_DIR/db.$zone"
    if [ -f "$MAIN_ZONE_FILE" ] && ! grep -q "keys.conf" "$MAIN_ZONE_FILE"; then
        log "Adding \$INCLUDE to $MAIN_ZONE_FILE"
        echo "\$INCLUDE $KEYS_FILE" >> $MAIN_ZONE_FILE
    fi

    # Also check for zone files in ext, int, and other views
    for view_dir in "/etc/bind/ext" "/etc/bind/int" "/etc/bind/q0s"; do
        if [ -d "$view_dir" ]; then
            VIEW_ZONE_FILE="$view_dir/db.$zone"
            if [ -f "$VIEW_ZONE_FILE" ] && ! grep -q "keys.conf" "$VIEW_ZONE_FILE"; then
                log "Adding \$INCLUDE to $VIEW_ZONE_FILE"
                echo "\$INCLUDE $KEYS_FILE" >> $VIEW_ZONE_FILE
            fi
        fi
    done

    # Set proper permissions
    chown named:named $ZONE_KEYS_DIR/*
    chmod 640 $ZONE_KEYS_DIR/*.private
done

log "DNSSEC keys generation and inclusion completed"

# Stop haveged
kill $HAVEGED_PID
