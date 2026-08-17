-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- Ported from pre-4.0 monitors.conf.
-- NOTE: keep each hl.monitor(...) on one line — scripts/monitor-watcher.sh
-- greps output/position/transform out of this file to detect drift.

hl.env("GDK_SCALE", "1")

-- Fallback for any monitor not matched below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 1 })

-- DP-1 (LG ULTRAWIDE) left, DP-2 (AOC portrait) right, DP-3 (ZeroMOD strip) below DP-2.
-- Positions assume DP-1 at ~1.25 (logical 2752x1152, bottom-aligned with DP-2);
-- DP-2 sits flush right of DP-1; DP-3 below, right-aligned with DP-2's right edge.

-- DP-1 scale is user-adjusted at runtime — no fixed value here. Preserve the
-- currently applied scale across config reloads (so the watcher and theme
-- switches don't stomp manual changes); fall back to auto at session start.
local dp1 = hl.get_monitor("DP-1")
local dp1_scale = (dp1 and dp1.scale) or "auto"
hl.monitor({ output = "DP-1", mode = "3440x1440@160", position = "0x768", scale = dp1_scale, vrr = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "2752x0", scale = 1, transform = 3 })
hl.monitor({ output = "DP-3", mode = "preferred", position = "1912x1920", scale = 1, transform = 3 })

-- Headless output for the tablet-as-second-screen setup — created on demand by
-- ~/.config/hypr/scripts/tablet-monitor.sh, which names it "tablet" so this rule
-- matches. Ignored while the output doesn't exist. Declared here so the geometry
-- survives a reload and monitor-watcher.sh re-pins it like the physical monitors.
hl.monitor({ output = "tablet", mode = "1920x1200@60", position = "-1920x480", scale = 1 })
