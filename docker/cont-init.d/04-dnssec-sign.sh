#!/bin/sh

# DNSSEC signing script for master zones
# Automatically discover zones from /etc/bind/dnssec directory
KEYS_DIR="/etc/bind/dnssec-keys"
DNSSEC_ZONES_DIR="/etc/bind/dnssec"

log()   { echo "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
warn()  { echo "\033[1;33m[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1\033[0m"; }
error() { echo "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"; }

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

log "Signing DNSSEC zones: $ZONES"

for zone in $ZONES; do
    log "Signing zone: $zone"
    ZONE_KEYS_DIR="$KEYS_DIR/$zone"
    cd $ZONE_KEYS_DIR

    # Find all keys for the zone
    KEYS=$(ls K${zone}.+*.private)

    # Sign the zone for each available view
    ZONE_SIGNED=false

    # Check main dnssec zone file first
    MAIN_ZONE_FILE="$DNSSEC_ZONES_DIR/db.$zone"
    if [ -f "$MAIN_ZONE_FILE" ]; then
        SIGNED_ZONE_FILE="${MAIN_ZONE_FILE}.signed"
        log "Signing $MAIN_ZONE_FILE -> $SIGNED_ZONE_FILE"
        dnssec-signzone -A -N INCREMENT -o $zone -t -f $SIGNED_ZONE_FILE $MAIN_ZONE_FILE $KEYS
        chown named:named $SIGNED_ZONE_FILE
        [ -f "$SIGNED_ZONE_FILE.jnl" ] && chown named:named "$SIGNED_ZONE_FILE.jnl"
        ZONE_SIGNED=true
    fi

    # Also sign zone files in other view directories
    for view_dir in "/etc/bind/ext" "/etc/bind/int" "/etc/bind/q0s"; do
        if [ -d "$view_dir" ]; then
            VIEW_ZONE_FILE="$view_dir/db.$zone"
            if [ -f "$VIEW_ZONE_FILE" ]; then
                SIGNED_ZONE_FILE="${VIEW_ZONE_FILE}.signed"
                log "Signing $VIEW_ZONE_FILE -> $SIGNED_ZONE_FILE"
                dnssec-signzone -A -N INCREMENT -o $zone -t -f $SIGNED_ZONE_FILE $VIEW_ZONE_FILE $KEYS
                chown named:named $SIGNED_ZONE_FILE
                [ -f "$SIGNED_ZONE_FILE.jnl" ] && chown named:named "$SIGNED_ZONE_FILE.jnl"
                ZONE_SIGNED=true
            fi
        fi
    done

    if [ "$ZONE_SIGNED" = false ]; then
        warn "No zone file found for $zone"
    fi
done

log "DNSSEC zone signing completed"
