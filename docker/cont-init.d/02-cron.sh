#!/bin/sh

mkdir -p /etc/crontabs

cat > /etc/crontabs/root << EOF
# Update root hints weekly
0 0 * * 0 curl -o /etc/bind/named.root https://www.internic.net/domain/named.root && chown named:named /etc/bind/named.root

# DNSSEC zone re-signing weekly
0 2 * * 0 /etc/cont-init.d/04-dnssec-sign.sh && rndc reload

# DNSSEC key rollover check monthly
0 3 1 * * /etc/cont-init.d/05-dnssec-rollover.sh

EOF
