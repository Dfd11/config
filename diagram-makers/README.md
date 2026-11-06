# diagram-makers

Four Claude Code agents that draw one picture each for documentation, plus the commands they use.
Ask Claude for "a diagram of ..." in any project and it delegates to the right one.

| Maker | Draws | Library |
|---|---|---|
| `mermaid-maker` | structure and relationships (architecture, flows, sequences, state machines, trees) | Mermaid + Chrome |
| `plot-maker` | numbers (plots, data, physics) | matplotlib |
| `svg-maker` | exact geometry and schematics | hand-written SVG |
| `manim-maker` | animation (MP4), only when motion is the idea | Manim + ffmpeg |

Each maker writes the source, renders it, **looks at the result and fixes it**, then saves the image
and its source side by side (`./diagrams` by default, stable names, so a later run updates in place).

## Install

From the install menu (`sixtailfox/install.sh`, choose *diagrams*), or directly:

```sh
~/.config/diagram-makers/setup.sh            # prints the apt line for anything missing
~/.config/diagram-makers/setup.sh --apt      # installs the missing system packages (sudo)
~/.config/diagram-makers/setup.sh --latex    # also requires LaTeX for formulas in Manim (about 770 MB)
```

Safe to re-run. It does not touch your own Python or Node libraries: the venv and `node_modules` live in
`~/.local/share/diagram-makers`. Chrome or Chromium is not installed for you; if none is found, setup
prints how to get one (mermaid needs it).

## What goes where

| Piece | Lives in the repo | Linked or generated at |
|---|---|---|
| agents (`agents/*.md`) | yes | `~/.claude/agents/<name>.md` (symlinks) |
| skill (`skills/diagrams`) | yes | `~/.claude/skills/diagrams` (symlink) |
| commands (`bin/render-*`) | yes | `~/.local/bin/render-*` (symlinks) |
| helper libraries (`kit/`) | yes | used in place |
| venv, `node_modules` | no | `~/.local/share/diagram-makers/` |
| permission rules for the commands | no | `~/.claude/settings.json` (merged, backup kept) |

## Using the commands by hand

```sh
render-diagram mermaid arch.mmd --save architecture   # -> ./diagrams/architecture.png + architecture.mmd
render-diagram svg figure.svg --save figure --out docs/img
render-plot plot.py --save latency                    # script writes its figure to $PLOT_OUT
render-manim scene.py MyScene --save sweep            # -> sweep.mp4 + sweep.scene.py
```

Without `--save` they render a small preview next to the source and print its path. `--help` on each
command has the details. `render-plot --kit` and `render-manim --kit` print the optional helper docs.

## Environment variables

`DIAGRAM_OUT` default output folder (instead of `./diagrams`), `DIAGRAM_MAKERS_HOME` where the venv and
`node_modules` live, `CHROME` Chrome binary, `CLAUDE_CONFIG_DIR` Claude Code's config folder,
`DIAGRAM_BIN_DIR` where the commands are linked.

## Remove

Delete the symlinks (`~/.local/bin/render-*`, `~/.claude/agents/*-maker.md`, `~/.claude/skills/diagrams`),
the five rules this added to `permissions.allow` in `~/.claude/settings.json`, and
`~/.local/share/diagram-makers`.
