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

# Get the default route interface
default_iface=$(ip -4 route show default 2>/dev/null | awk '/default/ { print $5; exit }')

if [[ -z "$default_iface" ]]; then
    warn "No default route found. Listing all LAN IPs:"
    ip -4 addr show | awk '/inet / && !/127\.0\.0\.1/ { print $2 }' | cut -d/ -f1
    exit 0
fi

ip=$(ip -4 addr show "$default_iface" 2>/dev/null | awk '/inet / { print $2 }' | cut -d/ -f1)

if [[ -z "$ip" ]]; then
    error "Could not determine LAN IP for interface: $default_iface"
    exit 1
fi

echo -e "${BLUE}Interface:${NC} $default_iface"
info "LAN IP: $ip"
