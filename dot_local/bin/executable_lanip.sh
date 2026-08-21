#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }

# Resolve the default-route interface and its address. Linux uses iproute2;
# macOS has neither `ip` nor iproute2, so fall back to route(8)/ipconfig(8).
if command -v ip >/dev/null 2>&1; then
    default_iface=$(ip -4 route show default 2>/dev/null | awk '/default/ { print $5; exit }')
else
    default_iface=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }')
fi

if [[ -z "$default_iface" ]]; then
    warn "No default route found. Listing all LAN IPs:"
    if command -v ip >/dev/null 2>&1; then
        ip -4 addr show | awk '/inet / && !/127\.0\.0\.1/ { print $2 }' | cut -d/ -f1
    else
        ifconfig | awk '/inet / && !/127\.0\.0\.1/ { print $2 }'
    fi
    exit 0
fi

if command -v ip >/dev/null 2>&1; then
    ip=$(ip -4 addr show "$default_iface" 2>/dev/null | awk '/inet / { print $2 }' | cut -d/ -f1)
else
    ip=$(ipconfig getifaddr "$default_iface" 2>/dev/null || true)
fi

if [[ -z "$ip" ]]; then
    error "Could not determine LAN IP for interface: $default_iface"
    exit 1
fi

echo -e "${BLUE}Interface:${NC} $default_iface"
info "LAN IP: $ip"
