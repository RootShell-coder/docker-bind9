# docker bind9

[![bind9](https://github.com/RootShell-coder/docker-bind9/actions/workflows/docker_build.yml/badge.svg?branch=master)](https://github.com/RootShell-coder/docker-bind9/actions/workflows/docker_build.yml)

A Docker container for BIND9 DNS server.

## Quick Start

1. Clone the repository.
2. Run `docker-compose up -d` to start the BIND9 service.

## Configuration

**Important**: The files in `./bind/` are examples only. You must replace them with your own BIND9 configuration files before running the container.

- **Ports**: Exposes DNS on port 53 (UDP/TCP). Optional: DoT on 853, statistics on 8080, management on 953.
- **Volumes** (required replacements):
  - `./bind/dnssec/:/etc/bind/dnssec` - DNSSEC keys and zones (replace with your keys/zones)
  - `./bind/int/:/etc/bind/int` - Internal zones (replace with your internal zones)
  - `./bind/named.conf:/bind/named.conf` - Main configuration file (replace with your named.conf)
- **Environment**:
  - `S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0` - Service startup timeout

## Optional Features

Uncomment in `docker-compose.yml` for:

- **ADBLOCK**: Set `ADBLOCK="true"` and configure URLs for RPZ-based ad blocking.
- **SSL/TLS**: Mount SSL certificates to `/etc/ssl/bind/`.
- **Additional configs**: Mount `acl.conf` and `option.conf` if needed.
