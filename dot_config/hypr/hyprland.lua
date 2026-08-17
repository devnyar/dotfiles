-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- (Ported from pre-4.0 hyprland.conf.)

-- App workspace assignments.
o.window("^(zen)$", { workspace = "3 silent", tile = true })
o.window("^(jetbrains-studio)$", { workspace = "5 silent" })
o.window("^(dev.zed.Zed)$", { workspace = "4 silent" })

-- Startup terminals (autostart.lua launches ghostty with these custom classes).
o.window("^(org\\.banyar\\.startup-term1)$", { workspace = "1 silent" })
o.window("^(org\\.banyar\\.startup-term2)$", { workspace = "2 silent" })
o.window("^(org\\.banyar\\.startup-term6)$", { workspace = "6 silent" })

-- Special-workspace apps.
o.window("^(chrome-discord\\.com__channels_@me-Default)$", { workspace = "special:rom silent" })
o.window("^(chrome-ophjlpahpchlmihnnnihgmmeilfjmjjc__index\\.html-Default)$", { workspace = "special:communication silent" })

-- Workspace to monitor assignments.
for _, ws in ipairs({ 1, 2, 3, 4, 5, 7, 8 }) do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-1" })
end
hl.workspace_rule({ workspace = "6", monitor = "DP-2" })
hl.workspace_rule({ workspace = "9", monitor = "DP-3" })

-- Override floating window default size (omarchy default is 875x600).
o.window({ tag = "floating-window" }, { size = { 1200, 800 } })

-- Per-app size overrides.
o.window("(org.omarchy.terminal)", { size = { 1200, 800 } })

-- Small centered confirm dialog spawned by scripts/close-window.sh (SUPER+W on Zen).
o.window("^(org\\.banyar\\.close-confirm)$", { float = true, center = true, size = { 460, 160 }, stay_focused = true })
