-- Ported from pre-4.0 bindings.conf. Bindings whose Omarchy 4 default is
-- already identical (terminal, tmux, browser, editor, webapps, lazydocker,
-- Google Messages/Photos, X, ChatGPT, Grok, Calendar, Email, YouTube) are not
-- repeated here — only overrides and additions.

local home = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts"

-- App overrides ---------------------------------------------------------------

-- Obsidian with GPU workaround + Wayland IME (default launches plain obsidian).
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Obsidian", { focus = "^obsidian$", launch = "obsidian -disable-gpu --enable-wayland-ime" })

-- Typora instead of Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", { launch = "typora --enable-wayland-ime" })

-- Glance instead of Signal.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Glance", { webapp = "https://glance.banyar.app/", focus = true })

-- Special workspaces ----------------------------------------------------------
-- Scratchpad lives on SUPER+U here; SUPER+S (the 4.x default) becomes the app
-- launcher below.
hl.unbind("SUPER + S")     -- was: toggle scratchpad
hl.unbind("SUPER + ALT + S") -- was: move window to scratchpad
o.bind("SUPER + U", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + U", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

o.bind("SUPER + R", "Toggle ROM", hl.dsp.workspace.toggle_special("rom"))
o.bind("SUPER + SHIFT + R", "Move to ROM", hl.dsp.window.move({ workspace = "special:rom", follow = false }))

o.bind("SUPER + B", "Toggle communication", hl.dsp.workspace.toggle_special("communication"))
o.bind("SUPER + SHIFT + G", "Move to communication", hl.dsp.window.move({ workspace = "special:communication", follow = false }))

o.bind("SUPER + M", "Toggle music", hl.dsp.workspace.toggle_special("music"))
hl.workspace_rule({ workspace = "special:music", on_created_empty = "uwsm-app -- xdg-terminal-exec cliamp" })

-- SUPER+W: close window — but confirm first when it's the Zen browser (it
-- otherwise closes instantly with no warning, unlike Ctrl+Q).
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", scripts .. "/close-window.sh")

-- SUPER+E: file manager, SUPER+Q: system menu.
o.bind("SUPER + E", "File manager", { launch = "nautilus --new-window" })
o.bind("SUPER + Q", "Omarchy menu", "omarchy-menu toggle")

-- App launcher on SUPER+S (freed from scratchpad above); SUPER+SPACE stays free.
hl.unbind("SUPER + SPACE")
o.bind("SUPER + S", "Launch apps", "omarchy-menu toggle apps")

-- Numpad workspace switching — bind by keycode so it fires regardless of
-- NumLock state. xkb keycode = evdev keycode + 8.
local numpad_codes = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
for workspace, code in ipairs(numpad_codes) do
  local key = "code:" .. tostring(code)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

-- MX Master 3s gesture button targets (triggered by logid / logiops) ----------
hl.unbind("SUPER + CTRL + LEFT")   -- was: grouped window focus left
hl.unbind("SUPER + CTRL + RIGHT")  -- was: grouped window focus right
hl.unbind("SUPER + CTRL + RETURN") -- was: Herdr
o.bind("SUPER + CTRL + RIGHT", "Next workspace (mouse gesture)", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + CTRL + LEFT", "Previous workspace (mouse gesture)", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + UP", "Fullscreen (mouse gesture)", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + CTRL + RETURN", "Omarchy menu (mouse click)", "omarchy-menu toggle")

-- External monitor brightness (DDC/CI) ----------------------------------------
-- This desktop has no laptop backlight, so omarchy's default XF86MonBrightness
-- handler is a no-op (OSD shows but nothing changes). Unbind the defaults and
-- point the keys at brightness-ddc.sh, which drives the LG + AOC via ddcutil.
local ddc = scripts .. "/brightness-ddc.sh"
for _, mod in ipairs({ "", "SHIFT + ", "ALT + " }) do
  hl.unbind(mod .. "XF86MonBrightnessUp")
  hl.unbind(mod .. "XF86MonBrightnessDown")
end
o.bind("XF86MonBrightnessUp", "Brightness up", ddc .. " +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", ddc .. " 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness max", ddc .. " 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness min", ddc .. " 1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", ddc .. " +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", ddc .. " 1%-", { locked = true, repeating = true })
