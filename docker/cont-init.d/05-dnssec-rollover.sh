#!/bin/sh

# DNSSEC key rollover script for BIND 9.20 - DISABLED DURING STARTUP
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

log "Checking DNSSEC key rollover for zones: $ZONES"
warn "Rollover disabled during initial startup to prevent timeouts"
exit 0

for zone in $ZONES; do
    log "Checking keys for zone: $zone"

    if [ -d "$KEYS_DIR/$zone" ]; then
        cd $KEYS_DIR/$zone

        # Check if keys are close to expiration (30 days)
        for keyfile in K${zone}.+008+*.key; do
            if [ -f "$keyfile" ]; then
                # Get key expiration
                expiration=$(dnssec-settime -p all $keyfile | grep "Delete:" | cut -d: -f2- | xargs)

                if [ ! -z "$expiration" ]; then
                    exp_timestamp=$(date -d "$expiration" +%s 2>/dev/null)
                    current_timestamp=$(date +%s)

                    # 30 days in seconds
                    thirty_days=$((30 * 24 * 60 * 60))

                    if [ $((exp_timestamp - current_timestamp)) -lt $thirty_days ]; then
                        warn "Key $keyfile for $zone expires soon, initiating rollover"

                        # Generate new ZSK or KSK
                        if [[ $keyfile == *"+KSK"* ]]; then
                            warn "Rolling over KSK for $zone"
                            dnssec-keygen -a RSASHA256 -b 2048 -f KSK -n ZONE $zone
                        else
                            warn "Rolling over ZSK for $zone"
                            dnssec-keygen -a RSASHA256 -b 1280 -n ZONE $zone
                        fi

                        # Set proper permissions
                        chown named:named K${zone}.*
                        chmod 640 K${zone}.*

                        log "New key generated for $zone, re-signing required"
                        /etc/cont-init.d/04-dnssec-sign.sh
                        if command -v rndc >/dev/null 2>&1; then
                            rndc reload || warn "rndc reload failed"
                        fi
                    else
                        log "Key $keyfile for $zone is valid for more than 30 days"
                    fi
                fi
            fi
        done
    else
        warn "DNSSEC keys directory for $zone not found"
    fi
done

log "DNSSEC key rollover check completed"

log "Checking DNSSEC key rollover for zones: $ZONES"

# Exit if no zones found
if [ -z "$ZONES" ]; then
    warn "No zones found in $DNSSEC_ZONES_DIR"
    exit 0
fi

for zone in $ZONES; do
    log "Checking keys for zone: $zone"

    if [ -d "$KEYS_DIR/$zone" ]; then
        cd $KEYS_DIR/$zone

        # Check if keys are close to expiration (30 days)
        for keyfile in K${zone}.+008+*.key; do
            if [ -f "$keyfile" ]; then
                # Get key expiration
                expiration=$(dnssec-settime -p all $keyfile | grep "Delete:" | cut -d: -f2- | xargs)

                if [ ! -z "$expiration" ]; then
                    exp_timestamp=$(date -d "$expiration" +%s 2>/dev/null)
                    current_timestamp=$(date +%s)

                    # 30 days in seconds
                    thirty_days=$((30 * 24 * 60 * 60))

                    if [ $((exp_timestamp - current_timestamp)) -lt $thirty_days ]; then
                        warn "Key $keyfile for $zone expires soon, initiating rollover"

                        # Generate new ZSK or KSK
                        if [[ $keyfile == *"+KSK"* ]]; then
                            warn "Rolling over KSK for $zone"
                            dnssec-keygen -a RSASHA256 -b 2048 -f KSK -n ZONE $zone
                        else
                            warn "Rolling over ZSK for $zone"
                            dnssec-keygen -a RSASHA256 -b 1280 -n ZONE $zone
                        fi

                        # Set proper permissions
                        chown named:named K${zone}.*
                        chmod 640 K${zone}.*

                        log "New key generated for $zone, re-signing required"
                        /etc/cont-init.d/04-dnssec-sign.sh
                        if command -v rndc >/dev/null 2>&1; then
                            rndc reload || warn "rndc reload failed"
                        fi
                    else
                        log "Key $keyfile for $zone is valid for more than 30 days"
                    fi
                fi
            fi
        done
    else
        warn "DNSSEC keys directory for $zone not found"
    fi
done

log "DNSSEC key rollover check completed"
