#!/bin/bash
# Omarchy upgrades replace /usr/bin/omarchy-capture-*, so re-apply the local
# configurable-filename-prefix patch.
exec "$HOME/.local/share/omarchy-patches/capture-filename-prefix.sh"
