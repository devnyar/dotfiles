-- Ported from pre-4.0 input.conf.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    -- Switch between US and Burmese (Unicode) with Left Alt + Right Alt.
    kb_layout = "us,mm",
    kb_options = "compose:caps,grp:alts_toggle",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 600,

    -- Start with numlock on by default.
    numlock_by_default = true,

    touchpad = {
      -- Control the speed of your scrolling.
      scroll_factor = 0.4,
    },
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Monitor focus follows the KEYBOARD, not the mouse: moving the cursor onto
-- another monitor no longer switches the active monitor. Jump monitors with
-- workspace keys (ws 6 → DP-2, ws 9 → DP-3) or CTRL+ALT+TAB; the cursor
-- warps along (cursor:warp_on_change_workspace is on by default). Clicking
-- still focuses whatever you click.
hl.config({
  misc = {
    mouse_move_focuses_monitor = false,
  },
})
