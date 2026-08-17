#!/bin/bash
# close-window.sh — handler for SUPER+W.
#
# SUPER+W closes the focused window instantly. For Zen browser that means the
# whole browser can vanish with no warning — unlike Ctrl+Q, which Zen guards.
# The browser's own quit dialog can't be triggered from a window-manager close,
# so we add a confirmation step here instead: gum in a small floating terminal
# (walker's dmenu mode is gone in Omarchy 4; hyprctl dispatch is Lua now).
#
# Zen  -> ask for confirmation, then close.
# else -> close immediately (unchanged behaviour).

close_by_addr() {
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null
  hyprctl dispatch 'hl.dsp.window.close()' >/dev/null
}

# Second invocation, running inside the confirm terminal.
if [ "${1:-}" = "--confirm" ]; then
  source omarchy-restart-gum 2>/dev/null || true
  if gum confirm "Close Zen browser?"; then
    close_by_addr "$2"
  fi
  exit 0
fi

win=$(hyprctl activewindow -j)
class=$(jq -r '.class // empty' <<<"$win")
addr=$(jq -r '.address // empty' <<<"$win")

if [ "$class" = "zen" ]; then
  exec setsid uwsm-app -- xdg-terminal-exec --app-id=org.banyar.close-confirm --title=Confirm -e "$0" --confirm "$addr"
else
  hyprctl dispatch 'hl.dsp.window.close()' >/dev/null
fi
