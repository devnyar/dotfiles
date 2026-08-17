-- Ported from pre-4.0 autostart.conf.

local home = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts"

-- App workspace assignments — window rules in hyprland.lua route these by class.
o.launch_on_start(home .. "/.local/share/JetBrains/Toolbox/apps/android-studio/bin/studio")
o.launch_on_start("zeditor")
o.launch_on_start("/opt/zen-browser-bin/zen-bin")

-- Day/night tint is handled by hyprsunset (profiles in hyprsunset.conf); it
-- applies through Hyprland's CTM, so it coexists with wl-gammarelay's gamma
-- LUT. wl-gammarelay-rs stays only for per-output gamma dimming of the
-- DDC-less DP-3 strip (see brightness-ddc.sh) — leave its Temperature at the
-- neutral 6500 default.
o.launch_on_start("hyprsunset")
o.exec_on_start("wl-gammarelay-rs")

-- Re-pin monitor layout after hotplug/DPMS drift.
o.exec_on_start(scripts .. "/monitor-watcher.sh")

-- Pre-build the DDC brightness bus cache so the first brightness keypress is instant.
o.exec_on_start(scripts .. "/brightness-ddc.sh warmup")

-- Startup terminals — disable gtk-single-instance so each gets its own process
-- and --class sticks, letting the window rules in hyprland.lua route them to
-- ws 1, 2, and 6.
o.launch_on_start("ghostty --gtk-single-instance=false --class=org.banyar.startup-term1")
o.launch_on_start("ghostty --gtk-single-instance=false --class=org.banyar.startup-term2")
o.launch_on_start("ghostty --gtk-single-instance=false --class=org.banyar.startup-term6")

-- Special-workspace apps (window rules in hyprland.lua send them silently to
-- special:rom / special:communication).
-- Discord uses its own --user-data-dir so it doesn't race with LINE on
-- chromium's default profile lock. (chromium auto-derives the WM class from the
-- --app URL → "chrome-discord.com__channels_@me-Default", matched in hyprland.lua)
o.launch_on_start("chromium --user-data-dir=" .. home .. "/.config/chromium-discord --app=https://discord.com/channels/@me")
o.launch_on_start("chromium --remote-debugging-port=9222 --remote-allow-origins=* --app=chrome-extension://ophjlpahpchlmihnnnihgmmeilfjmjjc/index.html")

-- LINE Thai->English translator: waits for LINE (with debug port) and attaches.
o.exec_on_start(home .. "/.local/share/line/autostart-driver.sh")
