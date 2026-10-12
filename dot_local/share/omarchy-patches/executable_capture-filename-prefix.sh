#!/bin/bash
# Make the capture filename prefixes configurable so screenshots can be named
# "ss_<timestamp>.png" instead of the hardcoded "screenshot-<timestamp>.png".
#
# Upstream hardcodes the prefix in the filename, so the only knob is the output
# directory. This rewrites the two filename lines to honour
# OMARCHY_SCREENSHOT_PREFIX / OMARCHY_SCREENRECORD_PREFIX, defaulting to the
# stock names when unset (so unpatched behaviour is preserved).
#
# The actual values are exported from ~/.config/hypr/hyprland.lua via hl.env.
#
# Idempotent: safe to run repeatedly. Re-applied after Omarchy upgrades by
# ~/.config/omarchy/hooks/post-update.d/.

set -euo pipefail

SHOT="${OMARCHY_SCREENSHOT_BIN:-/usr/bin/omarchy-capture-screenshot}"
REC="${OMARCHY_SCREENRECORD_BIN:-/usr/bin/omarchy-capture-screenrecording}"
MARKER="omarchy-patch:capture-filename-prefix"

[[ -f $SHOT ]] || { echo "not found: $SHOT" >&2; exit 1; }
[[ -f $REC ]] || { echo "not found: $REC" >&2; exit 1; }

if grep -q "$MARKER" "$SHOT" && grep -q "$MARKER" "$REC"; then
  echo "capture filename-prefix patch already applied"
  exit 0
fi

SUDO=()
[[ -w $SHOT && -w $REC ]] || SUDO=(sudo)

patch_file() {
  local file=$1 old=$2 new=$3 tmp
  grep -q "$MARKER" "$file" && return 0
  grep -qF "$old" "$file" || { echo "pattern not found in $file: $old" >&2; return 1; }

  tmp=$(mktemp)
  # Literal (non-regex) replacement of the first matching line, with a marker
  # comment above it so re-runs are no-ops.
  awk -v old="$old" -v new="$new" -v marker="# $MARKER" '
    !done && (at = index($0, old)) {
      match($0, /^[[:space:]]*/)
      print substr($0, 1, RLENGTH) marker
      $0 = substr($0, 1, at - 1) new substr($0, at + length(old))
      done = 1
    }
    { print }
  ' "$file" >"$tmp"

  "${SUDO[@]}" cp "$tmp" "$file"
  "${SUDO[@]}" chmod 755 "$file"
  rm -f "$tmp"
}

patch_file "$SHOT" \
  'FILENAME="screenshot-$(date' \
  'FILENAME="${OMARCHY_SCREENSHOT_PREFIX:-screenshot-}$(date'

patch_file "$REC" \
  'local filename="$OUTPUT_DIR/screenrecording-$(date' \
  'local filename="$OUTPUT_DIR/${OMARCHY_SCREENRECORD_PREFIX:-screenrecording-}$(date'

echo "capture filename-prefix patch applied"
