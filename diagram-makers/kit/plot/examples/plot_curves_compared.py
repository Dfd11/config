# Two solutions of the same system compared: damped vs undamped oscillator.
# x'' + 2*gamma*x' + w0^2 x = 0,  x(0) = A, x'(0) = 0
# Params: A = 1 m, w0 = 2*pi rad/s, gamma = 0.4 1/s
from plotkit import *
from scipy.integrate import solve_ivp

A, w0, gamma = 1.0, 2 * np.pi, 0.4
t = np.linspace(0, 6, 1500)
sol = solve_ivp(lambda t, y: [y[1], -2 * gamma * y[1] - w0**2 * y[0]], [0, 6], [A, 0], t_eval=t, rtol=1e-10, atol=1e-12)
damped, undamped = sol.y[0], A * np.cos(w0 * t)

wd = np.sqrt(w0**2 - gamma**2)
check_close("matches closed form", damped[-1], A * np.exp(-gamma * 6) * (np.cos(wd * 6) + gamma / wd * np.sin(wd * 6)), rtol=1e-5)
check("amplitude only decays", bool(np.all(np.abs(damped) <= A + 1e-9)))

fig, ax = new_fig()
ax.plot(t, undamped, color=GREY, ls="--", label="undamped")
ax.plot(t, damped, color=BLUE, label=r"damped, $\gamma=0.4\ \mathrm{s^{-1}}$")
label_axes(ax, "time $t$ (s)", "displacement $x$ (m)")
ax.legend()
save(fig)
