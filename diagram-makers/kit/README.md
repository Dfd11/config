# Kit for manim-maker

Mechanics only: style, checks and a few reusable pieces. The equation and parameters always come
from the brief. Read this file once, then **read at most one example** (in `examples/` next to this file) that is closest to the brief,
and write your own script (do not copy an example's physics).

## manimkit — `from manimkit import *`

Skeleton: header comment (equation, parameters) → `class MyScene(Scene)` → build objects →
drive motion from a `ValueTracker` clock → `check(...)`s at the end of `construct`.

| Helper | Use |
|---|---|
| `check` / `check_close` | as above, run while the scene is built |
| `run_clock(scene, clock, duration, start=0)` | advance a time tracker in real time |
| `sweep(scene, tracker, to, duration)` | move a parameter tracker at constant speed |
| `Pendulum(length, pivot, …)` + `.set_angle(theta)` | pivot, rod, bob. Drive with `add_updater`. |
| `swing_counter(clock, period, position)` | live count of completed cycles |
| `param_label(name, tracker, decimals, position)` | live `name = value` label |
| `tracked_curve(axes, f(x, value), tracker)` | curve that redraws as the parameter moves |
| `caption(text)` | caption along the bottom |

| Example | Closest to a brief about… |
|---|---|
| `manim_param_sweep.py` | a parameter sweeping through a graph |
| `manim_two_pendulums.py` | two systems on one clock (exact ODE motion, counters) |
| `manim_step_build.py` | a derivation revealed one step at a time |

Preview renders are small and fast; the published render is 720p. Make all the fixes you can
see in one pass instead of re-rendering for each tweak (aim for at most 3 previews).
