#!/usr/bin/env bash
# Keep the monitor layout pinned to what monitors.lua declares.
#
# Hyprland occasionally re-auto-places monitors after a mode renegotiation,
# DPMS cycle, or silent re-init — and these events aren't always signalled
# on the event socket. So we both:
#   1. Listen for monitoradded/removed events (cheap, instant reaction).
#   2. Poll every few seconds as a safety net for silent drifts.
#
# On drift, re-apply with `hyprctl reload` (Hyprland 0.56+ uses the Lua
# config; `hyprctl keyword monitor` is gone). Expected positions are computed
# from DP-1's scale with the SAME math as monitors.lua — keep them in sync.

set -u

LOG="${XDG_RUNTIME_DIR:-/tmp}/monitor-watcher.log"
POLL_INTERVAL=3
DP1_W=3440
DP1_H=1440
SCALE_STATE="$HOME/.local/state/hypr-dp1-scale"

log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"; }

declare -A EXPECT_POS
declare -A EXPECT_TRANSFORM=([DP-2]=3 [DP-3]=3)

# Recompute expected positions from DP-1's scale (state file, else the live
# value). Called every cycle so a scale change needs no watcher restart.
compute_expected() {
  local scale="" w h y
  [[ -s $SCALE_STATE ]] && scale="$(<"$SCALE_STATE")"
  if [[ -z $scale ]]; then
    scale="$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.name=="DP-1") | .scale // empty')"
  fi
  [[ -z $scale ]] && scale=1.25
  w="$(awk -v s="$scale" -v W="$DP1_W" 'BEGIN{printf "%d", W/s + 0.5}')"
  h="$(awk -v s="$scale" -v H="$DP1_H" 'BEGIN{printf "%d", H/s + 0.5}')"
  y=$((1920 - h))
  EXPECT_POS=(
    [DP-1]="0 $y"
    [DP-2]="$w 0"
    [DP-3]="$((w + 1080 - 1920)) 1920"
    [tablet]="-1920 $y"
  )
}

apply_all() {
  hyprctl reload >/dev/null
}

# Returns 0 if all connected tracked ports match expected position AND
# transform, else 1.
check_positions() {
  local json port want_x want_y got_x got_y want_t got_t
  json="$(hyprctl -j monitors)" || return 0  # hyprland not ready
  compute_expected
  for port in "${!EXPECT_POS[@]}"; do
    read -r want_x want_y <<<"${EXPECT_POS[$port]}"
    # Skip if the monitor isn't currently connected.
    grep -q "\"name\": \"$port\"" <<<"$json" || continue
    got_x="$(jq -r --arg n "$port" '.[] | select(.name==$n) | .x' <<<"$json")"
    got_y="$(jq -r --arg n "$port" '.[] | select(.name==$n) | .y' <<<"$json")"
    if [[ "$got_x" != "$want_x" || "$got_y" != "$want_y" ]]; then
      log "drift: $port at ${got_x}x${got_y}, expected ${want_x}x${want_y}"
      return 1
    fi
    # Also verify rotation — Hyprland can silently drop the transform after an
    # unlock / DPMS re-init (this is what flips the portrait strip upside down).
    want_t="${EXPECT_TRANSFORM[$port]:-}"
    if [[ -n "$want_t" ]]; then
      got_t="$(jq -r --arg n "$port" '.[] | select(.name==$n) | .transform' <<<"$json")"
      if [[ "$got_t" != "$want_t" ]]; then
        log "drift: $port transform $got_t, expected $want_t"
        return 1
      fi
    fi
  done
  return 0
}

# Event-socket listener (runs in background).
listen_events() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  [[ -S "$socket" ]] || { log "event socket missing: $socket"; return; }
  nc -U "$socket" | while IFS= read -r line; do
    case "$line" in
      monitoradded\>\>*|monitoraddedv2\>\>*|monitorremoved\>\>*|monitorremovedv2\>\>*)
        log "event: $line -> re-applying"
        apply_all
        ;;
    esac
  done
}

listen_events &
LISTENER_PID=$!
trap 'kill "$LISTENER_PID" 2>/dev/null' EXIT

log "started; tracking ports: DP-1 DP-2 DP-3 tablet (positions derived from DP-1 scale)"

# Poll loop.
while sleep "$POLL_INTERVAL"; do
  if ! check_positions; then
    apply_all
  fi
done
