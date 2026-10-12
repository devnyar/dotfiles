#!/bin/bash
# Show a headphone glyph in the audio bar widget when the active output is a
# headset/earbuds, including Bluetooth devices (e.g. Sony WH-1000XM5) whose
# PipeWire *node* properties carry no form-factor hint -- device.form-factor and
# device.icon-name live on the BlueZ device, which Quickshell's PwNode does not
# expose, so the sink is matched back to it by MAC address.
#
# Idempotent: safe to run repeatedly. Re-applied after Omarchy upgrades by
# ~/.config/omarchy/hooks/post-update.d/.

set -euo pipefail

PLUGIN_DIR="${OMARCHY_AUDIO_PLUGIN_DIR:-/usr/share/omarchy/shell/plugins/panels/audio}"
MODEL="$PLUGIN_DIR/Model.js"
PANEL="$PLUGIN_DIR/Panel.qml"
MARKER="omarchy-patch:headphone-icon"

[[ -f $MODEL && -f $PANEL ]] || { echo "audio plugin not found at $PLUGIN_DIR" >&2; exit 1; }

if grep -q "$MARKER" "$MODEL" && grep -q "$MARKER" "$PANEL"; then
  echo "audio headphone-icon patch already applied"
  exit 0
fi

SUDO=()
[[ -w $MODEL ]] || SUDO=(sudo)

tmp_model=$(mktemp) tmp_panel=$(mktemp)
trap 'rm -f "$tmp_model" "$tmp_panel"' EXIT

python3 - "$MODEL" "$tmp_model" <<'PY'
import re, sys

SPEAKER    = "\U000f04c3"
HEADPHONES = "\U000f02cb"
HEADPHONES_OFF = "\U000f07ce"
BLUETOOTH  = "\U000f00af"
DISPLAY    = "\U000f0379"
MIC        = "\U000f036c"
CAMERA     = "\U000f0100"

src = open(sys.argv[1], encoding="utf-8").read()

helpers = '''// omarchy-patch:headphone-icon
// A bluez sink's node properties carry the MAC but no form factor:
// device.form-factor / device.icon-name sit on the *device* object, which
// Quickshell's PwNode does not expose. Pull the address out so the panel can
// match the sink against the BlueZ device and borrow its icon.
function bluetoothAddress(node) {
  if (!node) return ""
  var p = nodeProps(node)
  var addr = String(p["api.bluez5.address"] || "").trim()
  if (addr) return addr.toLowerCase()
  var m = String(node.name || "").match(/bluez_(?:output|input)\\.([0-9A-Fa-f]{2}(?:_[0-9A-Fa-f]{2}){5})/)
  return m ? m[1].replace(/_/g, ":").toLowerCase() : ""
}

function isBluetooth(node) {
  if (!node) return false
  var p = nodeProps(node)
  if (String(p["device.api"] || "").toLowerCase() === "bluez5") return true
  if (bluetoothAddress(node)) return true
  var blob = deviceBlob(node)
  return blob.indexOf("bluetooth") !== -1 || blob.indexOf("bluez") !== -1
}

// Everything that might name the hardware, lowercased. `hint` is the BlueZ
// device icon (e.g. "audio-headset") when the caller could resolve one.
function deviceBlob(node, hint) {
  if (!node) return String(hint || "").toLowerCase()
  var p = nodeProps(node)
  return String([
    node.name, node.description, node.nickname,
    p["device.icon-name"] || "", p["device.icon_name"] || "",
    p["device.form-factor"] || "", p["device.form_factor"] || "",
    p["device.product.name"] || "",
    p["node.description"] || "", p["node.nick"] || "",
    p["api.bluez5.icon"] || "",
    hint || ""
  ].join(" ")).toLowerCase()
}

'''

new_is_headphones = '''function isHeadphones(node, hint) {
  if (!node) return false
  var blob = deviceBlob(node, hint)
  return blob.indexOf("headphone") !== -1
    || blob.indexOf("headset") !== -1
    || blob.indexOf("earbud") !== -1
    || blob.indexOf("earphone") !== -1
    || blob.indexOf("airpod") !== -1
}
'''

new_sink_glyph = '''function sinkGlyph(node, hint) {
  if (!node) return "%(SPEAKER)s"
  if (isHeadphones(node, hint)) return "%(HEADPHONES)s"
  if (isBluetooth(node)) return "%(BLUETOOTH)s"
  var blob = deviceBlob(node, hint)
  if (blob.indexOf("hdmi") !== -1 || blob.indexOf("display") !== -1) return "%(DISPLAY)s"
  return "%(SPEAKER)s"
}
''' % dict(SPEAKER=SPEAKER, HEADPHONES=HEADPHONES, BLUETOOTH=BLUETOOTH, DISPLAY=DISPLAY)

new_source_glyph = '''function sourceGlyph(node, hint) {
  if (!node) return "%(MIC)s"
  var blob = deviceBlob(node, hint)
  if (blob.indexOf("headset") !== -1 || blob.indexOf("headphone") !== -1
    || blob.indexOf("earbud") !== -1 || blob.indexOf("airpod") !== -1) return "%(HEADPHONES)s"
  if (isBluetooth(node)) return "%(BLUETOOTH)s"
  if (blob.indexOf("webcam") !== -1 || blob.indexOf("camera") !== -1) return "%(CAMERA)s"
  return "%(MIC)s"
}
''' % dict(MIC=MIC, HEADPHONES=HEADPHONES, BLUETOOTH=BLUETOOTH, CAMERA=CAMERA)

def swap(src, header, replacement, prefix=""):
    m = re.search(r"function %s\(node\) \{.*?\n\}\n" % header, src, re.S)
    assert m, "%s() not found" % header
    return src[:m.start()] + prefix + replacement + src[m.end():]

src = swap(src, "isHeadphones", new_is_headphones, helpers)
src = swap(src, "sinkGlyph", new_sink_glyph)
src = swap(src, "sourceGlyph", new_source_glyph)

assert "    isHeadphones: isHeadphones," in src, "module.exports block not found"
src = src.replace(
  "    isHeadphones: isHeadphones,",
  "    isHeadphones: isHeadphones,\n"
  "    isBluetooth: isBluetooth,\n"
  "    bluetoothAddress: bluetoothAddress,\n"
  "    deviceBlob: deviceBlob,", 1)

open(sys.argv[2], "w", encoding="utf-8").write(src)
PY

python3 - "$PANEL" "$tmp_panel" <<'PY'
import re, sys

HEADPHONES = "\U000f02cb"
HEADPHONES_OFF = "\U000f07ce"

src = open(sys.argv[1], encoding="utf-8").read()

assert "import Quickshell.Bluetooth" not in src, "Bluetooth already imported"
src = src.replace("import Quickshell.Services.Mpris",
                  "import Quickshell.Bluetooth\nimport Quickshell.Services.Mpris", 1)

assert "  readonly property var mprisPlayers:" in src, "mprisPlayers property not found"
src = src.replace(
  "  readonly property var mprisPlayers:",
  "  // omarchy-patch:headphone-icon - a bluez sink only knows its MAC, so the\n"
  "  // matching BlueZ device supplies the form factor the node lacks.\n"
  "  readonly property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []\n"
  "  readonly property var mprisPlayers:", 1)

old = re.search(
  r"  function isHeadphones\(node\) \{\n.*?\n  \}\n\n  function sinkGlyph\(node\) \{\n.*?\n  \}\n",
  src, re.S)
assert old, "isHeadphones/sinkGlyph wrappers not found"
new = '''  function btIconFor(node) {
    var address = Model.bluetoothAddress(node)
    if (!address) return ""
    for (var i = 0; i < btDevices.length; i++) {
      var device = btDevices[i]
      if (device && String(device.address || "").toLowerCase() === address)
        return String(device.icon || "")
    }
    return ""
  }

  function isHeadphones(node) {
    return Model.isHeadphones(node, btIconFor(node))
  }

  function sinkGlyph(node) {
    return Model.sinkGlyph(node, btIconFor(node))
  }
'''
src = src[:old.start()] + new + src[old.end():]

old_source = """  function sourceGlyph(node) {
    return Model.sourceGlyph(node)
  }"""
assert old_source in src, "sourceGlyph wrapper not found"
src = src.replace(old_source, """  function sourceGlyph(node) {
    return Model.sourceGlyph(node, btIconFor(node))
  }""", 1)

# Keep mute state legible on headphones instead of always showing the plain
# headphone glyph.
old_icon = '    if (isHeadphones(sink)) return "%s"\n' % HEADPHONES
assert old_icon in src, "outputIcon() headphone branch not found"
src = src.replace(
  old_icon,
  '    if (isHeadphones(sink)) return outputMuted ? "%s" : "%s"\n' % (HEADPHONES_OFF, HEADPHONES),
  1)

open(sys.argv[2], "w", encoding="utf-8").write(src)
PY

"${SUDO[@]}" install -m 0644 "$tmp_model" "$MODEL"
"${SUDO[@]}" install -m 0644 "$tmp_panel" "$PANEL"
echo "audio headphone-icon patch applied to $PLUGIN_DIR"
