#!/usr/bin/env bash
# Launch LINE with remote debugging and start the Thai->English translator.
set -euo pipefail
cd "$(dirname "$0")"

PORT="${1:-9222}"

./launch-line.sh "$PORT"
echo "Waiting for LINE to come up…"
for i in $(seq 1 20); do
  if curl -s "http://127.0.0.1:${PORT}/json" >/dev/null 2>&1; then break; fi
  sleep 0.5
done

CDP_PORT="$PORT" exec node driver.js
