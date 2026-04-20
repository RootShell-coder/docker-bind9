#!/bin/sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Generate rndc key"
rndc-confgen -a -c /etc/bind/rndc.key

log "Create directories"
mkdir -p /var/cache/bind/keys
chown -R named:named /var/cache/bind /etc/bind

log "Check config"
named-checkconf /etc/bind/named.conf
