#!/usr/bin/env bash
# Autostarted at login (from ~/.config/hypr/autostart.conf).
# Runs the LINE Thai->English translator driver. The driver waits for LINE to
# appear on the debug port, so it's fine to start before LINE is open — it
# attaches whenever LINE launches and survives LINE being closed/reopened.
cd "$(dirname "$0")" || exit 1

# Hyprland exec-once is not a login shell, so mise's node may not be on PATH.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Single instance: don't stack drivers across re-logins.
pgrep -f 'node driver.js' >/dev/null && exit 0

exec node driver.js >> driver.log 2>&1
