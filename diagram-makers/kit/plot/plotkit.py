"""plotkit: shared style, saving and checking helpers for plot-maker scripts.

    from plotkit import *

Everything here is mechanics. The equation and parameters always come from the brief.
"""

import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ACCENT, BLUE, GREEN, ORANGE, GREY, DARK = "#d1495b", "#2f6feb", "#1a7f37", "#e08e0b", "#8a8a90", "#1c1c1e"
PALETTE = [BLUE, ACCENT, GREEN, ORANGE]

plt.rcParams.update({
    "figure.figsize": (8, 4.5), "figure.facecolor": "white", "axes.facecolor": "white",
    "font.size": 12, "axes.labelsize": 14, "legend.fontsize": 12, "lines.linewidth": 2.2,
    "axes.grid": True, "grid.alpha": 0.3, "axes.spines.top": False, "axes.spines.right": False,
})


def new_fig(**kw):
    """Figure and axes in the project style. Pass nrows/ncols/figsize as for plt.subplots."""
    return plt.subplots(**kw)


def save(fig):
    """Write the figure where render-plot expects it. Always the last line of a script."""
    fig.savefig(os.environ["PLOT_OUT"], dpi=int(os.environ.get("PLOT_DPI", "200")), bbox_inches="tight")
    plt.close(fig)


def check(name, ok, detail=""):
    """Print and enforce a sanity check. A failed check aborts the render."""
    print(f"CHECK {'ok  ' if ok else 'FAIL'} {name}" + (f": {detail}" if detail else ""))
    if not ok:
        raise SystemExit(f"check failed: {name} {detail}")


def check_close(name, got, want, rtol=1e-3, atol=0.0):
    """check() that two numbers agree; prints both."""
    check(name, bool(np.isclose(got, want, rtol=rtol, atol=atol)), f"got {got:.6g}, expected {want:.6g}")


def label_axes(ax, xlabel, ylabel, title=None):
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    if title:
        ax.set_title(title)


def reference_line(ax, y=None, x=None, label=None, color=GREY):
    """Dashed grey guide (a model value, an asymptote, an equilibrium)."""
    (ax.axhline(y, ls="--", color=color, label=label) if y is not None else ax.axvline(x, ls="--", color=color, label=label))


def mark_points(ax, xs, ys, labels, color=ACCENT, offset=(10, 10)):
    """Dots with text labels (points offset from the dot, in screen points)."""
    ax.plot(xs, ys, "o", color=color, zorder=5)
    for x, y, text in zip(xs, ys, labels):
        ax.annotate(text, (x, y), textcoords="offset points", xytext=offset, fontsize=12, color=color)


def blank_canvas(xlim, ylim, figsize=(6, 5)):
    """Equal-aspect axes with no grid or frame, for sketches and free-body diagrams."""
    fig, ax = plt.subplots(figsize=figsize)
    ax.set_xlim(*xlim), ax.set_ylim(*ylim), ax.set_aspect("equal"), ax.axis("off")
    return fig, ax


def arrow(ax, start, vector, label=None, color=ACCENT, label_offset=(0.12, 0.12)):
    """Arrow from `start` along `vector`, with its label near the tip. Lengths are data units."""
    start, vector = np.asarray(start, float), np.asarray(vector, float)
    ax.annotate("", xy=start + vector, xytext=start, arrowprops=dict(arrowstyle="-|>", color=color, lw=2.5, mutation_scale=18))
    if label:
        tip = start + vector + np.asarray(label_offset)
        ax.text(*tip, label, color=color, fontsize=14)
