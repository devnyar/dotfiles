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
  -- TEMP diagnostic (2026-09-17): 100Hz to test if the DP link drops are
  -- bandwidth-related. If stable, replace the DP cable and restore @160.
  { output = "DP-1", mode = "3440x1440@144", position = "0x288", scale = 1.25, transform = 0, vrr = 1 },
  { output = "DP-2", mode = "1920x1080@60", position = "2752x0", scale = 1, transform = 3 },
  { output = "DP-3", mode = "preferred", position = "832x1440", scale = 1, transform = 3 },
  -- Virtual VNC screen, created on demand by `vnc-monitor` (~/.local/bin).
  -- Ignored while the output doesn't exist.
  { output = "vnc", mode = "1920x1080@60", position = "-1920x288", scale = 1 },
}

-- Fallback for any monitor not matched below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 1 })

-- Outputs started by `vnc-monitor` have a pidfile in its state dir. Their mode
-- is set at runtime (--mode), so a reload keeps it along with the position.
local vnc_state = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/vnc-monitor/"
local function is_vnc_output(name)
  local f = io.open(vnc_state .. name .. ".pid", "r")
  if f then f:close() end
  return f ~= nil
end

local function preserve_live(cfg, live)
  -- Preserve runtime-configured geometry (wdisplays, hyprctl, …).
  cfg.position = tostring(live.x) .. "x" .. tostring(live.y)
  cfg.scale = live.scale
  cfg.transform = live.transform
  if is_vnc_output(cfg.output) then
    cfg.mode = string.format("%dx%d@%d", live.width, live.height, math.floor(live.refresh_rate))
  end
end

local known = {}
for _, cfg in ipairs(defaults) do
  known[cfg.output] = true
  local live = hl.get_monitor(cfg.output)
  if live then preserve_live(cfg, live) end
  hl.monitor(cfg)
end

-- Extra vnc-monitor outputs (custom --name) have no entry above.
for _, live in ipairs(hl.get_monitors()) do
  if not known[live.name] and is_vnc_output(live.name) then
    local cfg = { output = live.name }
    preserve_live(cfg, live)
    hl.monitor(cfg)
  end
end

-- Workspaces a vnc-monitor screen takes over while it exists. Applied from
-- events, not as plain rules, so they win over the static assignments loaded
-- later (hyprland.lua, hyprmoncfg-monitors.lua) and fall back to those once
-- the screen is gone (`vnc-monitor stop` reloads the config).
local vnc_workspaces = {
  vnc = { 10 },
}

local function claim_workspaces(name)
  for _, ws in ipairs(vnc_workspaces[name] or {}) do
    ws = tostring(ws)
    hl.workspace_rule({ workspace = ws, monitor = name })
    if hl.get_workspace(ws) then
      hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = name }))
    end
  end
end

hl.on("monitor.added", function(mon)
  if mon then claim_workspaces(mon.name) end
end)

hl.on("config.reloaded", function()
  for name in pairs(vnc_workspaces) do
    if hl.get_monitor(name) then claim_workspaces(name) end
  end
end)
