# A parameter sweep on a graph: y = sin(k x) on [0, 2*pi], k from 1 to 3.
# Over (0, 2*pi) the curve has 2k - 1 interior zero crossings.
from manimkit import *


class Sweep(Scene):
    def construct(self):
        axes = Axes(x_range=[0, 2 * PI, PI / 2], y_range=[-1.5, 1.5, 1], x_length=9, y_length=4, tips=False)
        k = ValueTracker(1)
        curve = tracked_curve(axes, lambda x, kv: np.sin(kv * x), k, x_range=[0, 2 * PI])
        formula = MathTex(r"y = \sin(kx)").to_corner(UL)
        k_label = param_label("k", k, position=UL).next_to(formula, DOWN, aligned_edge=LEFT)

        self.play(Create(axes), Write(formula))
        self.add(curve, k_label)
        self.wait(1)
        sweep(self, k, 3, 4)
        self.wait(1)

        xs = np.linspace(1e-6, 2 * PI - 1e-6, 20001)
        crossings = int(np.sum(np.sign(np.sin(k.get_value() * xs)[:-1]) != np.sign(np.sin(k.get_value() * xs)[1:])))
        check_close("k reached its target", k.get_value(), 3)
        check("zero crossings = 2k - 1", crossings == 2 * round(k.get_value()) - 1, f"{crossings}")
