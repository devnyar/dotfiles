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

wan_ip=""

# Try dig via OpenDNS first (fast, no HTTP overhead)
if command -v dig &>/dev/null; then
    wan_ip=$(dig +short +time=3 myip.opendns.com @resolver1.opendns.com 2>/dev/null || true)
    if [[ -z "$wan_ip" ]]; then
        warn "dig returned no result, falling back to curl..."
    fi
fi

# Fallback: curl-based services
if [[ -z "$wan_ip" ]]; then
    for url in "https://api4.my-ip.io/ip" "https://ipv4.icanhazip.com" "https://api.ipify.org"; do
        wan_ip=$(curl -s --max-time 5 "$url" 2>/dev/null || true)
        [[ -n "$wan_ip" ]] && break
    done
fi

if [[ -z "$wan_ip" ]]; then
    error "Could not determine WAN IP. Check your internet connection."
    exit 1
fi

info "WAN IP: $wan_ip"
