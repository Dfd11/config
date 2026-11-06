---
name: diagrams
description: Make a diagram, figure, plot or animation for documentation (a README, design doc, wiki page, blog post) by delegating to the maker agents, or update one that already exists. Use when the user asks for an architecture or flow diagram, sequence diagram, state machine, chart or plot, geometric figure or an animation to put in a document, or wants an existing diagram in ./diagrams changed.
---

# Diagrams for documentation

Four maker agents draw one picture each, render it, look at it, and save the image together with its editable source. This skill is how to use them well.

## 1. Decide whether to draw, and whether you need a maker

- **If a sentence or a short list says it as well, say that instead.** A decorative diagram that repeats the text adds noise and a chance of being wrong.
- **A simple relationship diagram in Markdown that GitHub, GitLab or Obsidian renders:** write a fenced ```` ```mermaid ```` block yourself, directly in the document. It is cheapest, shows up in diffs and stays editable. Use `mermaid-maker` only when an image file is wanted, when the diagram is complex enough that a checked render matters, or when the target cannot render Mermaid.
- **Anything else (images, plots, exact geometry, animation):** use a maker.

## 2. Pick the maker

| Idea | Maker | Saves |
|---|---|---|
| Structure or relationships: architecture, dependencies, flows, sequences, state machines, trees, ER, timelines | `mermaid-maker` | `<name>.png` + `<name>.mmd` |
| Numbers: function plots, benchmarks and data, distributions, physics, curves compared, force and vector sketches | `plot-maker` | `<name>.png` + `<name>.py` |
| Exact placement: geometry, coordinate sketches, number lines, labelled schematics | `svg-maker` | `<name>.png` + `<name>.svg` |
| Motion is the idea: a parameter sweep, a build-up in steps, a wave | `manim-maker` (slow and costly; last resort) | `<name>.mp4` + `<name>.scene.py` |

## 3. Brief the maker

Give it, in a few lines:
- **the one idea** the picture must show (one idea per picture),
- **the concrete elements**: for diagrams the nodes and edges (at most 5 to 7 nodes), for geometry each element with its position or relation,
- **for plots and animations: the equation or data, parameters, units and ranges.** The maker checks that the picture matches them; it cannot tell whether they are the right ones, so verify them first,
- optionally `name:` (a short kebab-case file name) and `out:` (a folder).

A vague topic ("a diagram about our auth") gives a bad picture. A good brief: "Flow: browser sends credentials to API; API checks the user store; on success it issues a token to the browser; on failure it returns 401. Name: auth-flow."

## 4. Where things go

- Output goes to **`./diagrams`** in the current project, unless the brief or the user names another folder (`out:`).
- Names are **stable** (`<name>.png`), and **the source is saved beside the image**. To change a diagram, brief the maker with `name:` of the existing one and say what to change: it reads the saved source and edits it instead of redrawing. Commit the image and the source together.
- Embed with a path relative to the document, with alt text that states the idea: `![Login flow: browser, API, user store](diagrams/auth-flow.png)`.

## 5. Use them efficiently

- Independent diagrams can be made in parallel: several agent calls in one message.
- Each maker run costs real tokens (several renders and image reads). Don't ask for decoration, and don't request a figure the text already carries.
- When a maker returns, read its `RESULT:` block: `path` and `source`. For plots check `plotted` and `checks`, and confirm the picture matches what the user asked before you embed it. If it returns `NONE`, take its reason seriously: simplify the brief or choose another maker. Never fake or hand-draw the image yourself.
- If a maker reports a missing tool (Chrome, mermaid-cli, the Python environment, ffmpeg), pass its message on. The fix is the `diagram-makers` setup (the install menu's diagrams stage, or `~/.config/diagram-makers/setup.sh`).
