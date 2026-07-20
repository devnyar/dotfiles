#!/bin/bash

# Brightness control for the FOCUSED external monitor.
#
# This desktop has no /sys/class/backlight device, so omarchy's default
# XF86MonBrightness handler is a no-op. This is the replacement bound to those
# keys in bindings.conf. It adjusts whichever monitor currently has focus,
# using whichever control path that monitor supports:
#
#   * DDC/CI monitors (LG DP-1, AOC DP-2) -> real backlight via `ddcutil --bus`.
#     `-d N` / `ddcutil detect` force a full i2c enumeration on every call
#     (~7s here, worsened by the DDC-less strip on bus 5 forcing retries);
#     `--bus` skips the scan (~0.3s). The connector->bus map is cached per boot
#     (warmed at login) and refreshed only when a lookup/read fails.
#
#   * Non-DDC monitors (ZeroMOD strip DP-3) -> software gamma dimming via
#     wl-gammarelay-rs over D-Bus (object /outputs/<CONNECTOR>). This only
#     scales pixel values (the backlight stays full), so it is floored at
#     GAMMA_FLOOR% to avoid a near-black strip you can't see to recover.
#
# Mirrors omarchy-brightness-display's argument style.
# args: <+N%|N%-|N%>   e.g.  +5% | 5%- | 50%    (or `warmup` to prime the cache)

step="${1:-+5%}"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/brightness-ddc-map"
GAMMA_FLOOR=20   # lowest gamma-dim % allowed for non-DDC monitors

# Emit "CONNECTOR BUS" for every display: the i2c bus number for DDC-capable
# ones (e.g. "DP-1 3"), or "-" for non-DDC panels (e.g. "DP-3 -"). Recording
# the non-DDC ones too means a focused strip resolves from cache instead of
# re-running the ~7s enumeration on every keypress.
detect_map() {
  ddcutil detect 2>/dev/null | awk '
    /^Display /  { state="ddc";  bus="" }
    /^Invalid /  { state="nodc"; bus="" }
    state=="ddc" && /I2C bus:/ { b=$NF; sub(/.*i2c-/, "", b); bus=b }
    /DRM_connector:/ {
      c=$NF; sub(/^card[0-9]+-/, "", c)
      if (state=="ddc" && bus != "") print c, bus
      else if (state=="nodc")        print c, "-"
    }
  '
}

bus_for() { awk -v n="$1" '$1==n {print $2; exit}' "$CACHE" 2>/dev/null; }

# Build the cache and exit — run once at login so the first real keypress is
# instant instead of paying the ~7s enumeration.
if [[ $step == warmup ]]; then
  detect_map > "$CACHE"
  exit 0
fi

# Resolve $step into an absolute target given the current value, clamped to
# [floor, 100].  Args: <current> <floor>.
resolve_target() {
  local cur="$1" floor="$2" t
  if [[ $step == +*% ]]; then
    (( t = cur + ${step//[+%]/} ))
  elif [[ $step == *%- ]]; then
    (( t = cur - ${step//[%-]/} ))
  else
    t=${step//%/}
  fi
  (( t > 100 )) && t=100
  (( t < floor )) && t=$floor
  echo "$t"
}

# The focused monitor = the one with the active workspace / keyboard focus.
focused="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
[[ -z $focused ]] && exit 0

# --- Path selection: numeric bus -> DDC; "-" -> gamma; absent -> re-detect. ---
[[ -s "$CACHE" ]] || detect_map > "$CACHE"
bus="$(bus_for "$focused")"
# Only re-scan if the monitor is entirely absent from the cache (new/replugged);
# a cached "-" already tells us it's a known non-DDC panel, so don't rescan.
[[ -z $bus ]] && { detect_map > "$CACHE"; bus="$(bus_for "$focused")"; }
[[ -z $bus ]] && exit 0   # monitor not present at all — nothing to do

if [[ $bus != "-" ]]; then
  # ---- DDC/CI path (real backlight) ----
  read_current() { ddcutil --bus "$1" getvcp 10 2>/dev/null | grep -oP 'current value =\s*\K[0-9]+'; }
  current="$(read_current "$bus")"
  if [[ -z $current ]]; then
    # Stale cache (bus renumbered / monitor replugged) — re-detect once.
    detect_map > "$CACHE"
    bus="$(bus_for "$focused")"
    [[ -z $bus ]] && exit 0
    current="$(read_current "$bus")"
    [[ -z $current ]] && current=50
  fi
  target="$(resolve_target "$current" 1)"
  ddcutil --bus "$bus" setvcp 10 "$target" >/dev/null 2>&1
else
  # ---- Software gamma path (non-DDC monitor, e.g. the strip) ----
  obj="/outputs/${focused//-/_}"
  raw="$(busctl --user get-property rs.wl-gammarelay "$obj" rs.wl.gammarelay Brightness 2>/dev/null | awk '{print $2}')"
  # No daemon / unknown output — nothing we can do for this monitor.
  [[ -z $raw ]] && exit 0
  current="$(awk -v x="$raw" 'BEGIN{printf "%d", x*100 + 0.5}')"
  target="$(resolve_target "$current" "$GAMMA_FLOOR")"
  frac="$(awk -v p="$target" 'BEGIN{printf "%.2f", p/100}')"
  busctl --user set-property rs.wl-gammarelay "$obj" rs.wl.gammarelay Brightness d "$frac" >/dev/null 2>&1
fi

# Show the on-screen brightness popup (appears on the focused monitor).
omarchy-swayosd-brightness "$target"
