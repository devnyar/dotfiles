-- Ported from pre-4.0 bindings.conf. Bindings whose Omarchy 4 default is
-- already identical (terminal, tmux, browser, editor, webapps, lazydocker,
-- Google Messages/Photos, X, Grok, Calendar, Email, YouTube) are not
-- repeated here — only overrides and additions.

local home = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts"

-- App overrides ---------------------------------------------------------------

-- Obsidian is uninstalled; drop the default SUPER+SHIFT+O launcher.
hl.unbind("SUPER + SHIFT + O")

-- Typora instead of Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", { launch = "typora --enable-wayland-ime" })

-- Glance instead of Signal.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Glance", { webapp = "https://glance.banyar.app/", focus = true })

-- Special workspaces ----------------------------------------------------------
-- Scratchpad lives on SUPER+U here; SUPER+S (the 4.x default) is left unbound.
hl.unbind("SUPER + S")     -- was: toggle scratchpad
hl.unbind("SUPER + ALT + S") -- was: move window to scratchpad
o.bind("SUPER + U", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + U", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

o.bind("SUPER + D", "Toggle Discord", hl.dsp.workspace.toggle_special("discord"))

-- Spotify on its own special workspace so SUPER+R shows and hides it
-- (the omarchy default is launch-or-focus only, with no way to hide it again).
o.bind("SUPER + R", "Toggle Spotify", hl.dsp.workspace.toggle_special("spotify"))
hl.workspace_rule({ workspace = "special:spotify", on_created_empty = "uwsm-app -- spotify" })

o.bind("SUPER + B", "Toggle communication", hl.dsp.workspace.toggle_special("communication"))

hl.unbind("SUPER + SHIFT + A") -- was: ChatGPT webapp
hl.unbind("SUPER + SHIFT + ALT + A") -- was: Grok webapp
hl.unbind("SUPER + SHIFT + CTRL + A") -- was: omarchy-agent --pick
hl.unbind("SUPER + A") -- was: select all (sends CTRL+A)
o.bind("SUPER + A", "Toggle game", hl.dsp.workspace.toggle_special("game"))
o.bind("SUPER + SHIFT + A", "Move to game", hl.dsp.window.move({ workspace = "special:game", follow = false }))

-- SUPER+W: close window — but confirm first when it's the Zen browser (it
-- otherwise closes instantly with no warning, unlike Ctrl+Q).
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", scripts .. "/close-window.sh")

-- SHIFT+PRINT: select an area, OCR it (Thai + English) and translate to English.
o.bind("SHIFT + PRINT", "Translate screen area", scripts .. "/screen-translate.sh")

-- SUPER+E: file manager (Strata). SUPER+Q left unbound (SUPER+W closes);
-- the Omarchy menu stays on its default SUPER+SPACE, apps on SUPER+ALT+SPACE.
o.bind("SUPER + E", "File manager", { launch = "strata" })
hl.unbind("SUPER + Q") -- was: close window

-- Numpad workspace switching — bind by keycode so it fires regardless of
-- NumLock state. xkb keycode = evdev keycode + 8. Like SUPER + 1-0, these act on
-- the focused monitor's own workspaces.
local numpad_codes = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
for workspace, code in ipairs(numpad_codes) do
  local key = "code:" .. tostring(code)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, o.workspaces.focus(workspace))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, o.workspaces.move_window(workspace))
end

-- SUPER+N: jump to the next monitor. Same action as the default CTRL+ALT+TAB.
o.bind("SUPER + N", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))

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

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
