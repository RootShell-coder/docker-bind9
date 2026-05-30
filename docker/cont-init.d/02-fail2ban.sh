#!/bin/sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

[ "${FAIL2BAN_ENABLED:-false}" = "true" ] || { log "fail2ban disabled, skipping setup"; exit 0; }

log "Create fail2ban runtime directories"
mkdir -p /run/fail2ban /var/lib/fail2ban /var/log/fail2ban
