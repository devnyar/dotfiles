#!/usr/bin/env bash
# Use a tablet as a wireless secondary monitor: create a headless Hyprland
# output, position it, and expose it over VNC with wayvnc.
#
# The output is created with a fixed name ("tablet") instead of letting
# Hyprland auto-number it HEADLESS-N. That matters for two reasons:
#   1. The `hl.monitor` "tablet" rule in monitors.lua matches every time,
#      so geometry survives a hyprctl reload.
#   2. monitor-watcher.sh re-applies that same line on monitoradded events,
#      so the tablet gets the same drift protection as DP-1/DP-2/DP-3.
#
# wayvnc reads ~/.config/wayvnc/config for address/port/auth — this script
# only passes the flags that depend on the output.
#
# Usage: tablet-monitor.sh [toggle|start|stop|status]

set -uo pipefail

OUTPUT="${TABLET_OUTPUT:-tablet}"
MODE="${TABLET_MODE:-1920x1200@60}"
POSITION="${TABLET_POSITION:--1920x480}" # left of DP-1, top edges aligned
SCALE="${TABLET_SCALE:-1}"

# wayvnc resizes the captured output to match the connecting client by default.
# That would silently override MODE and shift the layout, so it's off unless
# you opt in with TABLET_ALLOW_RESIZE=1.
ALLOW_RESIZE="${TABLET_ALLOW_RESIZE:-0}"
# GPU-accelerated encoding. Off by default because it depends on working
# DMA-BUF capture; set TABLET_GPU=1 if the stream feels sluggish.
USE_GPU="${TABLET_GPU:-0}"

VNC_CONF="$HOME/.config/wayvnc/config"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/tablet-monitor.pid"
LOG="$RUNTIME/tablet-monitor.log"

log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"; }

notify() {
  local title="$1" body="${2:-}"
  log "$title${body:+ — $body}"
  command -v notify-send >/dev/null && notify-send -a "Tablet monitor" "$title" "$body"
}

die() {
  notify "Tablet monitor failed" "$*"
  echo "$*" >&2
  exit 1
}

# Read a key from the wayvnc config, falling back to wayvnc's own default.
vnc_setting() {
  local key="$1" fallback="$2" value=""
  [[ -f "$VNC_CONF" ]] &&
    value="$(grep -E "^\s*$key\s*=" "$VNC_CONF" | tail -1 | cut -d= -f2- | tr -d ' ')"
  echo "${value:-$fallback}"
}

lan_ip() {
  local iface
  iface="$(ip -4 route show default 2>/dev/null | awk '/default/ { print $5; exit }')"
  [[ -n "$iface" ]] || return 1
  ip -4 addr show "$iface" 2>/dev/null | awk '/inet / { print $2; exit }' | cut -d/ -f1
}

output_exists() {
  hyprctl -j monitors all 2>/dev/null |
    jq -e --arg n "$OUTPUT" 'map(select(.name == $n)) | length > 0' >/dev/null
}

server_pid() {
  local pid
  [[ -f "$PIDFILE" ]] || return 1
  pid="$(<"$PIDFILE")"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null || return 1
  echo "$pid"
}

running() { server_pid >/dev/null; }

start() {
  if running; then
    notify "Tablet monitor already on" "$OUTPUT @ $MODE"
    return 0
  fi

  command -v wayvnc >/dev/null || die "wayvnc is not installed"

  if ! output_exists; then
    hyprctl output create headless "$OUTPUT" >/dev/null ||
      die "could not create headless output"
    # Creation is async — wait for the compositor to register it.
    for _ in {1..20}; do
      output_exists && break
      sleep 0.1
    done
    output_exists || die "headless output '$OUTPUT' never appeared"
  fi

  # hyprctl keyword is gone in Hyprland 0.56 (Lua config) — apply via eval.
  hyprctl eval "hl.monitor({ output = \"$OUTPUT\", mode = \"$MODE\", position = \"$POSITION\", scale = $SCALE })" >/dev/null ||
    die "could not apply monitor rule for $OUTPUT"

  local args=(--output="$OUTPUT" --render-cursor)
  [[ "$ALLOW_RESIZE" == 1 ]] || args+=(--disable-resizing)
  [[ "$USE_GPU" == 1 ]] && args+=(--gpu)

  wayvnc "${args[@]}" >>"$LOG" 2>&1 &
  local pid=$!
  disown "$pid" 2>/dev/null
  echo "$pid" >"$PIDFILE"

  # wayvnc exits early on a bad config or a port already in use — catch that
  # instead of reporting success and leaving a stray headless output behind.
  sleep 0.5
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PIDFILE"
    hyprctl output remove "$OUTPUT" >/dev/null 2>&1
    die "wayvnc exited immediately — see $LOG"
  fi

  local port host
  port="$(vnc_setting port 5900)"
  host="$(lan_ip)" || host="$(vnc_setting address localhost)"
  notify "Tablet monitor on" "Connect to $host:$port  ·  $MODE at $POSITION"
}

stop() {
  local pid
  if pid="$(server_pid)"; then
    kill "$pid" 2>/dev/null
    for _ in {1..20}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -9 "$pid" 2>/dev/null
  else
    # No usable pidfile (killed by hand, or a reboot cleared $XDG_RUNTIME_DIR),
    # but a wayvnc may still be holding the output. This session runs no other
    # wayvnc, so matching by name is safe here.
    pkill -x wayvnc 2>/dev/null
  fi
  rm -f "$PIDFILE"

  if output_exists; then
    # Hyprland relocates any workspaces living on the output as it goes away.
    hyprctl output remove "$OUTPUT" >/dev/null ||
      die "could not remove output $OUTPUT"
  fi

  notify "Tablet monitor off"
}

status() {
  local pid port
  port="$(vnc_setting port 5900)"
  if pid="$(server_pid)"; then
    echo "wayvnc:  running (pid $pid), port $port"
  else
    echo "wayvnc:  stopped"
  fi
  if output_exists; then
    hyprctl -j monitors all | jq -r --arg n "$OUTPUT" \
      '.[] | select(.name == $n) |
       "output:  \(.name) \(.width)x\(.height)@\(.refreshRate | floor) at \(.x)x\(.y), scale \(.scale)"'
  else
    echo "output:  absent"
  fi
}

case "${1:-toggle}" in
toggle)
  if running; then stop; else start; fi
  ;;
start) start ;;
stop) stop ;;
status) status ;;
*)
  echo "usage: ${0##*/} [toggle|start|stop|status]" >&2
  exit 1
  ;;
esac
