#!/bin/bash
# Omarchy upgrades replace /usr/share/omarchy/shell, so re-apply the local
# headphone-icon patch for the audio bar widget.
exec "$HOME/.local/share/omarchy-patches/audio-headphone-icon.sh"
