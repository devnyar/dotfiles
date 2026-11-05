#!/bin/bash
# Put a second Zed window on the AOC's workspace 4 at login. The first one goes
# to workspace 4 on the LG through the window rule in hyprland.lua.
#
# Workspace ids are global, and the AOC owns 11-20, so its workspace 4 is 14.
# Zed restores its last session, which may already include a second window, so
# one is only opened when it didn't come back.

WORKSPACE=14

zed_windows() {
  hyprctl clients -j | jq -r '.[] | select(.class == "dev.zed.Zed") | .address'
}

# Zed starts alongside everything else at login, so give it time to appear.
for _ in {1..60}; do
  [[ -n $(zed_windows) ]] && break
  sleep 1
done
[[ -n $(zed_windows) ]] || exit 1

# Restored windows arrive one after another.
sleep 3

hyprctl monitors -j | jq -e 'any(.[]; .description | startswith("AOC 24G4"))' >/dev/null || exit 0
hyprctl clients -j | jq -e --argjson ws "$WORKSPACE" \
  'any(.[]; .class == "dev.zed.Zed" and .workspace.id == $ws)' >/dev/null && exit 0

before=$(zed_windows)
window=$(sed -n 2p <<<"$before")
focused=$(hyprctl activewindow -j | jq -r '.address // ""')

if [[ -z $window ]]; then
  zeditor -n
  for _ in {1..30}; do
    window=$(zed_windows | grep -vxF "$before" | head -n 1)
    [[ -n $window ]] && break
    sleep 1
  done
fi
[[ -n $window ]] || exit 1

hyprctl dispatch "hl.dsp.window.move({ workspace = \"$WORKSPACE\", follow = false, window = \"address:$window\" })" >/dev/null

# The new window takes focus when it opens, and focus then falls to the Zed
# window left on the LG. Hand it back, unless focus has since moved elsewhere.
active_class=$(hyprctl activewindow -j | jq -r '.class // ""')
if [[ -n $focused && $active_class == "dev.zed.Zed" ]]; then
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$focused\" })" >/dev/null
fi
