"""manimkit: shared pieces for manim-maker scenes.

    from manimkit import *       # also gives you `from manim import *` and numpy as np

Mechanics only. The equations and parameters always come from the brief, and motion
is always driven by a ValueTracker (the clock), never positioned by eye.
"""

from manim import *
import numpy as np

BLUE_C, RED_C, GREEN_C, ORANGE_C = "#5aa9ff", "#ff6b81", "#4cd47a", "#ffb347"


def check(name, ok, detail=""):
    """Print and enforce a sanity check while the scene is built. A failure aborts the render."""
    print(f"CHECK {'ok  ' if ok else 'FAIL'} {name}" + (f": {detail}" if detail else ""))
    if not ok:
        raise SystemExit(f"check failed: {name} {detail}")


def check_close(name, got, want, rtol=1e-3, atol=0.0):
    check(name, bool(np.isclose(got, want, rtol=rtol, atol=atol)), f"got {got:.6g}, expected {want:.6g}")


def run_clock(scene, clock, duration, start=0.0):
    """Advance `clock` (a ValueTracker of time) from `start` to `start + duration` in real time."""
    clock.set_value(start)
    scene.play(clock.animate.set_value(start + duration), run_time=duration, rate_func=linear)


def sweep(scene, tracker, to, duration):
    """Move a parameter tracker to `to` at constant speed over `duration` seconds."""
    scene.play(tracker.animate.set_value(to), run_time=duration, rate_func=linear)


def caption(text, font_size=30):
    """Short caption along the bottom edge."""
    return Text(text, font_size=font_size).to_edge(DOWN)


def param_label(name, tracker, decimals=1, position=UL, unit=""):
    """Live label `name = value unit` that follows a ValueTracker."""
    return always_redraw(
        lambda: MathTex(rf"{name} = {tracker.get_value():.{decimals}f}\,{unit}").to_corner(position)
    )


def swing_counter(clock, period, position, label="swings", font_size=26):
    """Live count of completed cycles, floor(t / period), shown at `position`."""
    return always_redraw(
        lambda: VGroup(
            Text(label, font_size=font_size),
            Text(str(int(clock.get_value() // period)), font_size=font_size),
        ).arrange(RIGHT, buff=0.2).move_to(position)
    )


def tracked_curve(axes, f, tracker, color=BLUE_C, **plot_kw):
    """Curve y = f(x, tracker value) that redraws as the tracker changes."""
    return always_redraw(lambda: axes.plot(lambda x: f(x, tracker.get_value()), color=color, **plot_kw))


class Pendulum(VGroup):
    """Pivot, rod and bob. `set_angle(theta)` (radians from straight down) moves it.

    Drive it from a clock:  p.add_updater(lambda m: m.set_angle(theta_of_t(clock.get_value())))
    """

    def __init__(self, length=2.5, pivot=ORIGIN, angle=0.0, bob_radius=0.18, color=BLUE_C, **kw):
        super().__init__(**kw)
        self.length, self.pivot = length, np.array(pivot, dtype=float)
        self.rod = Line(self.pivot, self.pivot + DOWN * length, color=GREY_B, stroke_width=3)
        self.bob = Circle(radius=bob_radius, color=color, fill_opacity=1)
        self.mount = Dot(self.pivot, radius=0.05, color=WHITE)
        self.add(self.rod, self.bob, self.mount)
        self.set_angle(angle)

    def set_angle(self, theta):
        end = self.pivot + self.length * np.array([np.sin(theta), -np.cos(theta), 0.0])
        self.rod.put_start_and_end_on(self.pivot, end)
        self.bob.move_to(end)
        return self
