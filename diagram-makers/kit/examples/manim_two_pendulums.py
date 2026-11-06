# Two systems on one clock: the same pendulum released from two amplitudes, exact motion.
# theta'' = -(g/L) sin(theta); exact period T = 4 sqrt(L/g) K(sin^2(theta0/2)) (scipy ellipk takes m = k^2).
# Params: g = 9.81 m/s^2, L = 2.0 m, theta0 = 10 deg and 60 deg, 9 s of real time.
from manimkit import *
from scipy.integrate import solve_ivp
from scipy.optimize import brentq
from scipy.special import ellipk

g, L, DURATION = 9.81, 2.0, 9.0
w2 = g / L


def solve(th0):
    return solve_ivp(lambda t, y: [y[1], -w2 * np.sin(y[0])], [0, DURATION], [th0, 0], dense_output=True, rtol=1e-10, atol=1e-12).sol


class TwoPendulums(Scene):
    def construct(self):
        cases = [(np.radians(10), -3.0), (np.radians(60), 3.0)]
        clock, group = ValueTracker(0), Group()
        for th0, x in cases:
            sol, T = solve(th0), 4 / np.sqrt(w2) * ellipk(np.sin(th0 / 2) ** 2)
            t_quarter = brentq(lambda t: sol(t)[0], 0.1, T / 2)                       # first time theta = 0
            check_close(f"exact period at {np.degrees(th0):.0f} deg", 4 * t_quarter, T, rtol=1e-6)
            bob = Pendulum(length=L, pivot=np.array([x, 1.5, 0]))
            bob.add_updater(lambda m, sol=sol: m.set_angle(sol(clock.get_value())[0]))
            count = swing_counter(clock, T, np.array([x, -1.4, 0]))
            label = MathTex(rf"\theta_0 = {np.degrees(th0):.0f}^\circ").move_to(np.array([x, 2.6, 0]))
            self.add(bob, count, label)
        self.wait(0.5)
        run_clock(self, clock, DURATION)
        self.wait(1)
