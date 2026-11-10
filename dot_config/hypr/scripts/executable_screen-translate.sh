#!/bin/bash
# Google-Lens-style screen translate: select a region, OCR it (Thai + English),
# translate it with Google Translate (translate-shell) and show the original and
# the translation in a floating window. The translation is also copied to the
# clipboard.
#
# Bound to SHIFT+PRINT in bindings.lua. Override the languages with
#   SCREEN_TRANSLATE_OCR   tesseract languages (default: tha+eng)
#   SCREEN_TRANSLATE_TO    target language code (default: en)

OCR_LANGS="${SCREEN_TRANSLATE_OCR:-tha+eng}"
TARGET="${SCREEN_TRANSLATE_TO:-en}"
APP_ID="org.banyar.screen-translate"

notify() { notify-send -a "Screen translate" -i accessories-dictionary "$@"; }

workdir=$(mktemp -d)
freeze_pid=""
cleanup() {
  [[ -n $freeze_pid ]] && kill "$freeze_pid" 2>/dev/null
  rm -rf "$workdir"
}
trap cleanup EXIT

# Freeze the screen while selecting, like `omarchy capture text`.
hyprpicker -r -z >/dev/null 2>&1 &
freeze_pid=$!
sleep .1
selection=$(slurp 2>/dev/null)
[[ -z $selection ]] && exit 0

grim -g "$selection" "$workdir/shot.png" || exit 1
kill "$freeze_pid" 2>/dev/null
freeze_pid=""

# Upscale (screen text is small for tesseract), OCR, then drop the spaces
# tesseract puts between Thai characters and squeeze blank lines.
original=$(
  magick "$workdir/shot.png" -resize 200% -colorspace gray png:- |
    tesseract stdin stdout --oem 1 --psm 6 -l "$OCR_LANGS" 2>/dev/null |
    perl -CSD -pe 's/(?<=\p{Thai}) +(?=\p{Thai})//g; s/[ \t]+$//' |
    cat -s
)
original=$(printf '%s' "$original" | sed -e '/./,$!d')

if [[ -z ${original//[[:space:]]/} ]]; then
  notify "No text found" "Try selecting a larger or clearer area."
  exit 1
fi

if ! translated=$(printf '%s' "$original" | trans -b -no-autocorrect ":$TARGET" 2>/dev/null) ||
  [[ -z ${translated//[[:space:]]/} ]]; then
  printf '%s' "$original" | wl-copy
  notify "Translation failed" "Google Translate didn't answer. The recognized text was copied instead."
  exit 1
fi

printf '%s' "$translated" | wl-copy

{
  printf '\e[2mOriginal\e[0m\n%s\n\n' "$original"
  printf '\e[1mTranslation\e[0m  \e[2m(copied to clipboard)\e[0m\n%s\n\n' "$translated"
  printf '\e[2mPress any key to close\e[0m'
} >"$workdir/result.txt"

foot --app-id="$APP_ID" --title="Screen translate" \
  bash -c 'cat "$1"; read -rsn1' _ "$workdir/result.txt"
