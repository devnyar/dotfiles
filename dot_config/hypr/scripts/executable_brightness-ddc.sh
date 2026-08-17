#!/bin/bash

# Brightness control for the FOCUSED external monitor.
#
# Omarchy 4's stock `omarchy-brightness-display` now covers DDC/CI monitors
# natively (focused-monitor detection, per-monitor i2c bus caching, OSD,
# concurrency locking), so this script only adds what stock can't do:
# software gamma dimming for DDC-less panels via wl-gammarelay-rs over D-Bus
# (object /outputs/<CONNECTOR>). Gamma dimming only scales pixel values (the
# backlight stays full), so it is floored at GAMMA_FLOOR% to avoid a
# near-black strip you can't see to recover.
#
# args: <+N%|N%-|N%>   e.g.  +5% | 5%- | 50%    (or `warmup` to prime caches)

step="${1:-+5%}"

# Monitors with no DDC/CI support, handled by gamma dimming instead.
GAMMA_OUTPUTS="DP-3"
GAMMA_FLOOR=20   # lowest gamma-dim % allowed

is_gamma_output() {
  local out
  for out in $GAMMA_OUTPUTS; do
    [[ "$1" == "$out" ]] && return 0
  done
  return 1
}

# Prime the stock DDC bus caches at login so the first keypress is instant.
if [[ $step == warmup ]]; then
  for m in $(hyprctl -j monitors 2>/dev/null | jq -r '.[].name'); do
    is_gamma_output "$m" && continue
    omarchy-brightness-display-ddc "$m" >/dev/null 2>&1
  done
  exit 0
fi

focused="$(omarchy-hyprland-monitor-focused 2>/dev/null)"
[[ -z $focused ]] && exit 0

if ! is_gamma_output "$focused"; then
  # ---- DDC/CI path: stock omarchy handles everything, OSD included ----
  exec omarchy-brightness-display "$step"
fi

# ---- Software gamma path (non-DDC monitor, e.g. the ZeroMOD strip) ----
obj="/outputs/${focused//-/_}"
raw="$(busctl --user get-property rs.wl-gammarelay "$obj" rs.wl.gammarelay Brightness 2>/dev/null | awk '{print $2}')"
# No daemon / unknown output — nothing we can do for this monitor.
[[ -z $raw ]] && exit 0
current="$(awk -v x="$raw" 'BEGIN{printf "%d", x*100 + 0.5}')"

if [[ $step == +*% ]]; then
  (( target = current + ${step//[+%]/} ))
elif [[ $step == *%- ]]; then
  (( target = current - ${step//[%-]/} ))
else
  target=${step//%/}
fi
(( target > 100 )) && target=100
(( target < GAMMA_FLOOR )) && target=$GAMMA_FLOOR

frac="$(awk -v p="$target" 'BEGIN{printf "%.2f", p/100}')"
busctl --user set-property rs.wl-gammarelay "$obj" rs.wl.gammarelay Brightness d "$frac" >/dev/null 2>&1

# Show the on-screen brightness popup (appears on the focused monitor).
omarchy-osd -i brightness -p "$target"
