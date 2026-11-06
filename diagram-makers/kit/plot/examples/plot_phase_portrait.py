# Phase portrait of a system: x' = y, y' = -(g/L) sin x  (pendulum, g/L = 9.81)
# Closed orbits = swinging, wavy lines = rotating, separatrix through x = +-pi.
from plotkit import *

w2 = 9.81
X, Y = np.meshgrid(np.linspace(-2 * np.pi, 2 * np.pi, 400), np.linspace(-8, 8, 300))
U, V = Y, -w2 * np.sin(X)
check_close("equilibria at 0 and pi (y' = 0)", abs(w2 * np.sin(0)) + abs(w2 * np.sin(np.pi)), 0, atol=1e-9)

fig, ax = new_fig()
ax.streamplot(X, Y, U, V, color=BLUE, density=1.4, linewidth=1)
mark_points(ax, [0, np.pi], [0, 0], ["stable", "unstable"], offset=(8, 10))
label_axes(ax, r"angle $\theta$ (rad)", r"angular velocity $\dot\theta$ (rad/s)")
ax.set_xticks([-2 * np.pi, -np.pi, 0, np.pi, 2 * np.pi], [r"$-2\pi$", r"$-\pi$", "0", r"$\pi$", r"$2\pi$"])
save(fig)
