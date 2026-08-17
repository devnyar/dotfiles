#!/bin/bash
# Safely change DP-1's scale. Writes the scale to a state file and reloads
# Hyprland, so monitors.lua recomputes ALL monitor positions together —
# changing the scale alone makes the pinned neighbors overlap, which
# Hyprland rejects.
#
# Usage: dp1-scale.sh <scale>     e.g. 1 | 1.25 | 1.6 | 2
#        dp1-scale.sh reset       (forget the override; keep current scale)

set -euo pipefail

W=3440; H=1440
STATE="$HOME/.local/state/hypr-dp1-scale"

scale="${1:?usage: dp1-scale.sh <scale>|reset}"

if [[ $scale == reset ]]; then
  rm -f "$STATE"
  echo "override cleared (current scale kept until next change)"
  exit 0
fi

# Hyprland silently ignores scales that don't divide the mode into (nearly)
# whole logical pixels — catch that here with a clear message instead.
awk -v s="$scale" -v W="$W" -v H="$H" 'BEGIN {
  if (s + 0 <= 0) exit 1
  w = W / s; h = H / s
  dw = w - int(w + 0.5); dh = h - int(h + 0.5)
  if (dw < 0) dw = -dw; if (dh < 0) dh = -dh
  exit (dw < 0.01 && dh < 0.01) ? 0 : 1
}' || {
  echo "invalid scale for ${W}x${H}: $scale (try 1, 1.25, 1.6, 2)" >&2
  exit 1
}

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$scale" >"$STATE"
hyprctl reload >/dev/null

sleep 0.5
hyprctl -j monitors | jq -r '.[] | "\(.name)\t\(.width)x\(.height) at \(.x)x\(.y) scale=\(.scale)"'
