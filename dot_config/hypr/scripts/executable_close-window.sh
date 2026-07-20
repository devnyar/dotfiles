#!/bin/bash
# close-window.sh — handler for SUPER+W.
#
# SUPER+W (killactive) closes the focused window instantly. For Zen browser
# that means the whole browser can vanish with no warning — unlike Ctrl+Q,
# which Zen guards. The browser's own quit dialog can't be triggered from a
# window-manager close, so we add a confirmation step here instead.
#
# Zen  -> ask for confirmation, then close.
# else -> close immediately (unchanged behaviour).

class=$(hyprctl activewindow -j | jq -r '.class // empty')

if [ "$class" = "zen" ]; then
  choice=$(printf 'Cancel\nClose Zen\n' | walker --dmenu -p 'Close Zen browser?')
  [ "$choice" = "Close Zen" ] && hyprctl dispatch killactive
else
  hyprctl dispatch killactive
fi
