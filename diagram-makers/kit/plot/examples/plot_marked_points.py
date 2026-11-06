# One curve with labelled points and a reference line: projectile range vs launch angle.
# R(theta) = v0^2 sin(2 theta) / g,  maximum at 45 degrees.  v0 = 20 m/s, g = 9.81 m/s^2
from plotkit import *

v0, g = 20.0, 9.81
theta = np.linspace(0, 90, 500)
R = v0**2 * np.sin(np.radians(2 * theta)) / g
check_close("peak at 45 deg", theta[np.argmax(R)], 45, atol=0.5)
check_close("max range v0^2/g", R.max(), v0**2 / g, rtol=1e-4)

fig, ax = new_fig()
ax.plot(theta, R, color=BLUE)
reference_line(ax, y=v0**2 / g, label=r"$v_0^2/g$")
pts = [15, 30, 45, 60]
vals = [v0**2 * np.sin(np.radians(2 * p)) / g for p in pts]
mark_points(ax, pts, vals, [f"{p}°: {v:.1f} m" for p, v in zip(pts, vals)], offset=(-10, -22))
label_axes(ax, r"launch angle $\theta$ (degrees)", "range $R$ (m)")
ax.legend(loc="lower center")
save(fig)
