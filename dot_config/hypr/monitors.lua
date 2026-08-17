-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Monitor arrangement is managed with wdisplays at runtime. This config:
--   1. Provides boot defaults (the arrangement captured below).
--   2. On reload, re-applies whatever is CURRENTLY live, so config reloads
--      (theme switches, edits) never revert wdisplays adjustments.
-- After rearranging in wdisplays, update the defaults below if the new layout
-- should survive a reboot.

hl.env("GDK_SCALE", "1")

local defaults = {
  { output = "DP-1", mode = "3440x1440@160", position = "0x288", scale = 1.25, transform = 0, vrr = 1 },
  { output = "DP-2", mode = "1920x1080@60", position = "2752x0", scale = 1, transform = 3 },
  { output = "DP-3", mode = "preferred", position = "832x1440", scale = 1, transform = 3 },
  -- Headless tablet output, created on demand by scripts/tablet-monitor.sh.
  -- Ignored while the output doesn't exist.
  { output = "tablet", mode = "1920x1200@60", position = "-1920x288", scale = 1 },
}

-- Fallback for any monitor not matched below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 1 })

for _, cfg in ipairs(defaults) do
  local live = hl.get_monitor(cfg.output)
  if live then
    -- Preserve runtime-configured geometry (wdisplays, hyprctl, …).
    cfg.position = tostring(live.x) .. "x" .. tostring(live.y)
    cfg.scale = live.scale
    cfg.transform = live.transform
  end
  hl.monitor(cfg)
end
