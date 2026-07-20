#!/usr/bin/env bash
# Relaunch the LINE Chromium app with remote debugging enabled.
# The default Chromium profile is reused, so the LINE session/login persists.
set -euo pipefail

PORT="${1:-9222}"
LINE_EXT_ID="ophjlpahpchlmihnnnihgmmeilfjmjjc"
APP_URL="chrome-extension://${LINE_EXT_ID}/index.html"

# Kill any running LINE app process (the one holding the profile lock).
# Only matches the LINE --app, not other chromium windows.
pkill -f -- "--app=${APP_URL}" 2>/dev/null || true
sleep 1

setsid /usr/lib/chromium/chromium \
  --ozone-platform=wayland \
  --ozone-platform-hint=wayland \
  --remote-debugging-port="${PORT}" \
  --remote-allow-origins=* \
  --app="${APP_URL}" \
  >/dev/null 2>&1 < /dev/null &

disown
echo "LINE relaunched with remote debugging on port ${PORT}"
echo "DevTools targets: http://127.0.0.1:${PORT}/json"
