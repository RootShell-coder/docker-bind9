#!/bin/sh

log() {
    echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

log "Generate TSIG key for DDNS"
tsig-keygen ddns-key > /etc/bind/ddns.key
chown named:named /etc/bind/ddns.key
cat  /etc/bind/ddns.key

log "Generate rndc key for remote control"
rndc-confgen -a -c /etc/bind/rndc.key
chown named:named /etc/bind/rndc.key
cat /etc/bind/rndc.key

log "Download root hints"
curl -SsL --max-time 30 https://www.internic.net/domain/named.root -o /etc/bind/named.root
chown named:named /etc/bind/named.root

log "Create cache directories"
mkdir -p /var/cache/bind/slaves
mkdir -p /var/cache/bind/managed-keys
chown -R named:named /var/cache/bind
chown named:named /etc/bind/

log "Set permissions"
chmod 700 /var/cache/bind
chmod 700 /etc/bind/
chmod 600 /etc/bind/ddns.key
chmod 640 /etc/bind/rndc.key

log "TLS Dot"
mkdir -p /etc/ssl/bind/
chown -R named:named /etc/ssl/bind
chmod 644 "/etc/ssl/bind/server.crt"
chmod 640 "/etc/ssl/bind/server.key"

log "Check configuration before starting"
named-checkconf /etc/bind/named.conf
