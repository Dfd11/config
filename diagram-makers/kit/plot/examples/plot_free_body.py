# Free-body diagram: block on a frictionless incline of angle 30 deg. Forces: weight mg (down),
# normal N (perpendicular to the surface). Net force mg sin(theta) down the slope.
from plotkit import *

th = np.radians(30)
m, g = 1.0, 9.81
W = np.array([0, -m * g]); N = m * g * np.cos(th) * np.array([np.sin(th), np.cos(th)])  # outward normal of the surface
net = W + N
check_close("net force = mg sin(theta)", np.linalg.norm(net), m * g * np.sin(th))
check("net force points down the slope", bool(net @ np.array([np.cos(th), -np.sin(th)]) > 0))

fig, ax = blank_canvas((-1, 8), (-1, 6))
ax.plot([0, 7 * np.cos(th)], [7 * np.sin(th), 0], color=DARK, lw=3, zorder=1)  # incline
c = np.array([3.5 * np.cos(th), 3.5 * np.sin(th)]) + 0.6 * np.array([np.sin(th), np.cos(th)])  # block centre: on the surface
s = 0.15 * np.array([[-1, -1], [1, -1], [1, 1], [-1, 1]]) * 4
rot = np.array([[np.cos(-th), -np.sin(-th)], [np.sin(-th), np.cos(-th)]])
ax.fill(*(c[:, None] + rot @ s.T), color="#dde6f7", ec=DARK)
s_ = 0.1
arrow(ax, c, s_ * W, "$mg$", color=ACCENT, label_offset=(0.1, -0.25))
arrow(ax, c, s_ * N, "$N$", color=BLUE, label_offset=(0.1, 0.05))
save(fig)
