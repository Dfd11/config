# plotkit (optional helpers for matplotlib scripts)

Not referenced by the plot-maker: in a timing test, plain matplotlib was faster and cheaper than
reading these helpers first. Import `plotkit` only if a particular helper is useful.
The examples are in `examples/` next to this file.

## plotkit (matplotlib) — `from plotkit import *`

Script skeleton: header comment (equation, parameters, units) → compute → `check(...)`s →
`fig, ax = new_fig()` → draw → `label_axes` → `save(fig)` (always last).

| Helper | Use |
|---|---|
| `new_fig(**plt.subplots kwargs)` | figure in the project style |
| `save(fig)` | write to `$PLOT_OUT` at the right resolution. Always the last line. |
| `check(name, ok, detail)` / `check_close(name, got, want, rtol, atol)` | printed + enforced sanity check. A failure aborts. |
| `label_axes(ax, xlabel, ylabel, title=None)` | axis labels with units, mathtext ok |
| `reference_line(ax, y=… or x=…, label=…)` | dashed grey guide (model value, asymptote, equilibrium) |
| `mark_points(ax, xs, ys, labels, offset=(10,10))` | dots with text labels |
| `blank_canvas(xlim, ylim)` | equal-aspect axes with no frame, for sketches |
| `arrow(ax, start, vector, label, color)` | labelled arrow (free-body diagrams, vectors) |
| `ACCENT, BLUE, GREEN, ORANGE, GREY, DARK, PALETTE` | colours |

| Example (`examples/`) | Closest to a brief about… |
|---|---|
| `plot_curves_compared.py` | two solutions of one system, an ODE solved with scipy |
| `plot_marked_points.py` | one curve with labelled points and a reference line |
| `plot_phase_portrait.py` | vector field / phase portrait with streamlines |
| `plot_free_body.py` | free-body or force diagram on a sketch |

