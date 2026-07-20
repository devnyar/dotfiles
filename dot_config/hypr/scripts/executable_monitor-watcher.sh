#!/usr/bin/env bash
# Keep DP-1/DP-2 pinned to the positions declared in monitors.conf.
#
# Hyprland occasionally re-auto-places monitors after a mode renegotiation,
# DPMS cycle, or silent re-init — and these events aren't always signalled
# on the event socket. So we both:
#   1. Listen for monitoradded/removed events (cheap, instant reaction).
#   2. Poll every few seconds as a safety net for silent drifts.
#
# When a drift is detected, re-apply the exact monitor lines from
# monitors.conf via `hyprctl keyword monitor ...`.

set -u

CONF="$HOME/.config/hypr/monitors.conf"
LOG="${XDG_RUNTIME_DIR:-/tmp}/monitor-watcher.log"
POLL_INTERVAL=3

log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"; }

# Extract active `monitor = ...` lines from monitors.conf (skip comments/blanks).
declare -a MONITOR_LINES=()
while IFS= read -r line; do
  MONITOR_LINES+=("$line")
done < <(grep -E '^\s*monitor\s*=' "$CONF" | sed -E 's/^\s*monitor\s*=\s*//')

if (( ${#MONITOR_LINES[@]} == 0 )); then
  log "no monitor lines found in $CONF; exiting"
  exit 1
fi

# Parse expected positions/transforms: map port -> "POSX POSY" and port -> N.
declare -A EXPECT_POS
declare -A EXPECT_TRANSFORM
for spec in "${MONITOR_LINES[@]}"; do
  port="$(awk -F, '{gsub(/ /,"",$1); print $1}' <<<"$spec")"
  pos="$(awk -F, '{gsub(/ /,"",$3); print $3}' <<<"$spec")"
  # Skip the "catch-all" default line (empty port).
  [[ -z "$port" ]] && continue
  # Skip lines with non-literal positions (e.g. "auto").
  [[ "$pos" == *x* ]] || continue
  EXPECT_POS["$port"]="${pos/x/ }"
  # Capture an explicit "transform, N" if present in the spec.
  if [[ "$spec" =~ transform[[:space:]]*,[[:space:]]*([0-9]+) ]]; then
    EXPECT_TRANSFORM["$port"]="${BASH_REMATCH[1]}"
  fi
done

apply_all() {
  for spec in "${MONITOR_LINES[@]}"; do
    hyprctl keyword monitor "$spec" >/dev/null
  done
}

# Returns 0 if all tracked ports match expected position AND transform, else 1.
check_positions() {
  local json port want_x want_y got_x got_y want_t got_t
  json="$(hyprctl -j monitors)" || return 0  # hyprland not ready
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

log "started; tracking ports: ${!EXPECT_POS[*]}"

# Poll loop.
while sleep "$POLL_INTERVAL"; do
  if ! check_positions; then
    apply_all
  fi
done
