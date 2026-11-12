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

-- Keep Zen rendering (at misc:render_unfocused_fps) while it sits on a hidden workspace.
-- Without frame callbacks the page stops ticking, so YouTube captions in the pinned
-- Picture-in-Picture window freeze until the main Zen window is visible again.
o.window("^(zen)$", { render_unfocused = true })

-- Startup terminals (autostart.lua launches ghostty with these custom classes).
-- Rules use Hyprland's global ids. Omarchy gives each monitor a block of ten
-- (see default/hypr/monitor-workspaces.lua): LG = 1-10, AOC = 11-20. So 11 is
-- workspace 1 on the AOC.
o.window("^(org\\.banyar\\.startup-term1)$", { workspace = "1 silent" })
o.window("^(org\\.banyar\\.startup-term2)$", { workspace = "2 silent" })
o.window("^(org\\.banyar\\.startup-term6)$", { workspace = "11 silent" })

-- Special-workspace apps.
o.window("^(chrome-discord\\.com__channels_@me-Default)$", { workspace = "special:discord silent" })
o.window("^(chrome-ophjlpahpchlmihnnnihgmmeilfjmjjc__index\\.html-Default)$", { workspace = "special:communication silent" })
o.window("^(Spotify)$", { workspace = "special:spotify silent" })

-- Override floating window default size (omarchy default is 875x600).
o.window({ tag = "floating-window" }, { size = { 1200, 800 } })

-- Per-app size overrides.
o.window("(org.omarchy.terminal)", { size = { 1200, 800 } })

-- Small centered confirm dialog spawned by scripts/close-window.sh (SUPER+W on Zen).
o.window("^(org\\.banyar\\.close-confirm)$", { float = true, center = true, size = { 460, 160 }, stay_focused = true })

-- Result window of scripts/screen-translate.sh (SHIFT+PRINT).
o.window("^(org\\.banyar\\.screen-translate)$", { float = true, center = true, size = { 900, 520 } })

-- Aniimo (Steam/Proton, app 4126040): ignore the game's fullscreen request and keep it
-- in a floating 1024x576 window at the left of DP-1 (the game itself is set to Windowed
-- 1024x576; DP-1 is at scale 1 and the game adopts the enforced window size). Size is locked with min/max:
-- SUPER + drag resizing fights the game's own resize under XWayland scaling and makes the
-- window run away. To change size, edit all three sizes here and W/H (+ HOME_Y) in
-- ~/.local/bin/aniimo-window-lock, keep 16:9. The game also takes sizes below its 1280x720 menu minimum.
-- Opens in the SUPER + A "game" special workspace. `move` is monitor-relative; keep it in
-- sync with HOME_X/HOME_Y (global coords) in aniimo-window-lock.
o.window("^(steam_app_4126040)$", {
  workspace = "special:game",
  suppress_event = "fullscreen",
  float = true,
  move = { 39, 403 },
  size = { 1024, 576 },
  min_size = { 1024, 576 },
  max_size = { 1024, 576 },
})

-- OpenLogi Actions Ring: a transparent popup, not a tiled app. Float it centred on
-- the cursor and pin it so it shows on whichever workspace is active. It needs focus
-- to take clicks, so app shortcuts go through ~/.local/bin/openlogi-ring-send.
o.window("^(openlogi-action-ring)$", {
  float = true,
  pin = true,
  move = { "(cursor_x-window_w*0.5)", "(cursor_y-window_h*0.5)" },
  border_size = 0,
  no_shadow = true,
  no_blur = true,
  no_anim = true,
  tag = "-default-opacity",
})

-- LINE (Chromium extension app): its Stickers/Emoji picker is a separate popup window
-- (popup.html) with the same class and title as the main window, so no static rule can
-- single it out. Tiled, it filled half the screen and LINE closed it straight away.
-- Float any LINE window that opens while another one already exists.
-- The picker closes itself on blur (window "blur" -> window.close()), and focus follows
-- the mouse, so it must open under the cursor: centred, the pointer crossed the main
-- LINE window on the way and the picker vanished. Put it with the cursor near its
-- bottom edge (the sticker button sits in the message bar), kept on the monitor.
-- Chromium sometimes misses Hyprland's resize of the fresh popup and keeps drawing at its
-- old size (picker in the corner, rest of the frame transparent, or blank). Floating it
-- before map (window.open_early + tag rule) made that worse, so it floats after map, and
-- the size is re-sent a few times over the first second (2px shrink, then back; 1px drifts it) so a
-- missed resize gets corrected.
local line_class = "chrome-ophjlpahpchlmihnnnihgmmeilfjmjjc__index.html-Default"
local line_popup_w, line_popup_h = 820, 1150
local function line_nudge(target)
  hl.dispatch(hl.dsp.window.resize({ x = line_popup_w - 2, y = line_popup_h, relative = false, window = target }))
  hl.dispatch(hl.dsp.window.resize({ x = line_popup_w, y = line_popup_h, relative = false, window = target }))
end
hl.on("window.open", function(window)
  if not window or window.class ~= line_class then return end
  local others = 0
  for _, other in ipairs(hl.get_windows()) do
    if other.class == line_class and other.address ~= window.address then others = others + 1 end
  end
  if others == 0 then return end
  local target = "address:" .. window.address
  hl.dispatch(hl.dsp.window.float({ action = "on", window = target }))
  hl.dispatch(hl.dsp.window.resize({ x = line_popup_w, y = line_popup_h, relative = false, window = target }))
  for _, delay in ipairs({ 150, 400, 900 }) do
    hl.timer(function()
      for _, w in ipairs(hl.get_windows()) do
        if w.address == window.address then line_nudge(target) end
      end
    end, { type = "oneshot", timeout = delay })
  end

  local ok, cursor = pcall(hl.get_cursor_pos)
  local cx = ok and cursor and (cursor.x or cursor[1])
  local cy = ok and cursor and (cursor.y or cursor[2])
  if not (cx and cy) then
    hl.dispatch(hl.dsp.window.center({ window = target }))
    return
  end
  local x, y = cx - line_popup_w / 2, cy - line_popup_h + 60
  for _, m in ipairs(hl.get_monitors()) do
    if cx >= m.x and cx < m.x + m.width and cy >= m.y and cy < m.y + m.height then
      x = math.max(m.x + 10, math.min(x, m.x + m.width - line_popup_w - 10))
      y = math.max(m.y + 40, math.min(y, m.y + m.height - line_popup_h - 10))
    end
  end
  hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), relative = false, window = target }))
end)

-- Capture output directories and filename prefixes.
-- Screenshots go to ~/Pictures/Screenshots as ss_<timestamp>.png; recordings to
-- ~/Videos/Screenrecordings as sr_<timestamp>.mp4. The prefix vars need the patch in
-- ~/.local/share/omarchy-patches/capture-filename-prefix.sh (upstream hardcodes
-- the prefix; the directory vars are stock).
local home = os.getenv("HOME")
hl.env("OMARCHY_SCREENSHOT_DIR", home .. "/Pictures/Screenshots")
hl.env("OMARCHY_SCREENSHOT_PREFIX", "ss_")
hl.env("OMARCHY_SCREENRECORD_DIR", home .. "/Videos/Screenrecordings")
hl.env("OMARCHY_SCREENRECORD_PREFIX", "sr_")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
