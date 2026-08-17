-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- The whole layout is COMPUTED from DP-1's scale so the monitors always stay
-- seamless: DP-2 flush right of DP-1 (bottom edges aligned at y=1920), DP-3
-- below DP-2 (right-aligned), tablet left of DP-1 (top-aligned).
--
-- Change DP-1's scale with scripts/dp1-scale.sh <scale> — changing the scale
-- alone would overlap the pinned neighbors, which Hyprland rejects.
-- scripts/monitor-watcher.sh mirrors this math to detect drift.

hl.env("GDK_SCALE", "1")

local DP1_W, DP1_H = 3440, 1440

-- DP-1 scale precedence: state file (written by dp1-scale.sh) > currently
-- applied scale (so reloads never stomp a manual change) > 1.25 default.
local function state_scale()
  local f = io.open((os.getenv("HOME") or "") .. "/.local/state/hypr-dp1-scale", "r")
  if not f then return nil end
  local v = tonumber(f:read("*l") or "")
  f:close()
  return v
end

local live = hl.get_monitor("DP-1")
local dp1_scale = state_scale() or (live and live.scale) or 1.25

local w = math.floor(DP1_W / dp1_scale + 0.5)  -- DP-1 logical width
local h = math.floor(DP1_H / dp1_scale + 0.5)  -- DP-1 logical height
local dp1_y = 1920 - h                         -- bottom-aligned with DP-2

-- Fallback for any monitor not matched below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 1 })

hl.monitor({ output = "DP-1", mode = "3440x1440@160", position = "0x" .. dp1_y, scale = dp1_scale, vrr = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = w .. "x0", scale = 1, transform = 3 })
hl.monitor({ output = "DP-3", mode = "preferred", position = (w + 1080 - 1920) .. "x1920", scale = 1, transform = 3 })

-- Headless output for the tablet-as-second-screen setup — created on demand by
-- ~/.config/hypr/scripts/tablet-monitor.sh. Ignored while it doesn't exist.
hl.monitor({ output = "tablet", mode = "1920x1200@60", position = "-1920x" .. dp1_y, scale = 1 })
