# A derivation revealed one step at a time. Each line follows from the previous one;
# the caption says WHY (the motivated step), the equation shows WHAT.
from manimkit import *


class Derivation(Scene):
    def construct(self):
        steps = [
            (r"F = ma", "Newton's second law"),
            (r"mg = ma", "the only force is gravity: F = mg"),
            (r"g = a", "m appears on both sides, so it cancels"),
        ]
        shown = None
        for tex, why in steps:
            eq = MathTex(tex, font_size=72)
            note = caption(why)
            if shown is None:
                self.play(Write(eq), FadeIn(note))
            else:
                self.play(TransformMatchingTex(shown[0], eq), FadeOut(shown[1]), FadeIn(note))
            shown = (eq, note)
            self.wait(1.5)
        check("three steps shown", len(steps) == 3)
