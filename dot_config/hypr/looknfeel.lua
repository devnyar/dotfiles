-- Ported from pre-4.0 looknfeel.conf.

-- Tighter spacing than the Omarchy 4 defaults (were 6 in / 8 out).
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 4,
  },
})

-- Own copy of the x-1632 theme's easing curve, so this stays valid on any theme.
hl.curve("mech", { type = "bezier", points = { { 0.30, 0.98 }, { 0.8, 1.03 } } })

-- Override vertical workspace switching with a horizontal slide.
-- (Omarchy 4 disables workspace animations by default, so re-enable here.)
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "mech", style = "slide" })
