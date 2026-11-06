#!/usr/bin/env bash
# Set up the diagram makers on this machine. Safe to re-run.
#
#   setup.sh [--apt] [--latex] [--no-link]
#
#   --apt      install the missing system packages with sudo (default: only print the command)
#   --latex    also require LaTeX, for formulas inside Manim animations (large: about 770 MB)
#   --no-link  skip the symlinks and the Claude settings change (environment only)
#
# What it does:
#   1. checks the system packages (and installs them with --apt)
#   2. creates the Python venv and installs requirements.txt      -> $ENV_DIR/venv
#   3. installs mermaid-cli from package.json                      -> $ENV_DIR/node_modules
#   4. links the three render commands into ~/.local/bin, the agents into ~/.claude/agents and the
#      skill into ~/.claude/skills, and allows the render commands in ~/.claude/settings.json
#   5. renders one tiny diagram of each kind to prove it works
#
# Environment (all optional):
#   DIAGRAM_MAKERS_HOME  where the venv and node_modules go (default ~/.local/share/diagram-makers)
#   CLAUDE_CONFIG_DIR    Claude Code's config folder (default ~/.claude)
#   DIAGRAM_BIN_DIR      where the render commands are linked (default ~/.local/bin)
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ENV_DIR="${DIAGRAM_MAKERS_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/diagram-makers}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BIN_DIR="${DIAGRAM_BIN_DIR:-$HOME/.local/bin}"

INSTALL_APT=0; WANT_LATEX=0; LINK=1
for arg in "$@"; do
  case "$arg" in
    --apt) INSTALL_APT=1 ;;
    --latex) WANT_LATEX=1 ;;
    --no-link) LINK=0 ;;
    -h|--help) sed -n '2,/^set -e/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

WARNINGS=0
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m  %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------------------------------------------
# 1. System packages
# ------------------------------------------------------------------------------------------------
info "system packages"
apt_pkgs=()
need_cmd() { # <command> <apt package>
  if have "$1"; then ok "$1"; else warn "$1 not found"; apt_pkgs+=("$2"); fi
}
need_lib() { # <pkg-config name> <apt package>
  if pkg-config --exists "$1" 2>/dev/null; then ok "$1 development files"
  else warn "$1 development files missing (needed to build Manim's dependencies)"; apt_pkgs+=("$2"); fi
}

need_cmd python3 python3
if python3 -c 'import venv, ensurepip' 2>/dev/null; then ok "python3 venv"; else warn "python3 venv missing"; apt_pkgs+=(python3-venv); fi
need_cmd node nodejs
need_cmd npm npm
need_cmd ffmpeg ffmpeg
need_cmd ffprobe ffmpeg
need_cmd pkg-config pkg-config
need_cmd gcc build-essential
if have pkg-config; then
  need_lib cairo libcairo2-dev
  need_lib pangocairo libpango1.0-dev
fi
if python3 -c 'import sysconfig,os,sys; sys.exit(0 if os.path.exists(os.path.join(sysconfig.get_paths()["include"], "Python.h")) else 1)' 2>/dev/null; then
  ok "python3 headers"; else warn "python3 headers missing"; apt_pkgs+=(python3-dev); fi
if have rsvg-convert; then ok "rsvg-convert (SVG text rendering)"; else warn "rsvg-convert not found (SVGs fall back to ImageMagick, slightly worse text)"; apt_pkgs+=(librsvg2-bin); fi
if ! have rsvg-convert && ! have convert; then apt_pkgs+=(imagemagick); fi

if have node; then
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$node_major" -ge 18 ]; then ok "node $(node -v)"; else warn "node $(node -v) is too old for mermaid-cli (needs 18 or newer)"; fi
fi

if [ "$WANT_LATEX" = 1 ]; then
  if have latex; then ok "latex"; else warn "latex not found (needed for formulas in Manim)"; apt_pkgs+=(texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-science dvisvgm cm-super); fi
fi

# Chrome is not installed here: print what to do instead.
if [ -n "${CHROME:-}" ] || have google-chrome || have google-chrome-stable || have chromium || have chromium-browser; then
  ok "Chrome/Chromium"
else
  warn "Chrome or Chromium not found. Mermaid needs one: install Google Chrome from https://www.google.com/chrome/ (or Chromium), or set CHROME=/path/to/chrome."
fi

if [ ${#apt_pkgs[@]} -gt 0 ]; then
  unique="$(printf '%s\n' "${apt_pkgs[@]}" | sort -u | tr '\n' ' ')"
  if ! have apt-get; then
    warn "no apt-get here: install the equivalents of: $unique"
  elif [ "$INSTALL_APT" = 1 ]; then
    info "installing system packages (sudo): $unique"
    # shellcheck disable=SC2086
    sudo apt-get update -qq && sudo apt-get install -y $unique || warn "apt install failed"
  else
    printf '\n  To install what is missing:\n    sudo apt install -y %s\n  (or re-run with --apt)\n\n' "$unique"
  fi
fi

# ------------------------------------------------------------------------------------------------
# 2. Python venv (isolated from your own Python libraries)
# ------------------------------------------------------------------------------------------------
info "python environment ($ENV_DIR/venv)"
mkdir -p "$ENV_DIR"
req_hash="$(sha256sum "$HERE/requirements.txt" | cut -d' ' -f1)"
if [ ! -x "$ENV_DIR/venv/bin/python" ]; then
  python3 -m venv "$ENV_DIR/venv" || warn "could not create the venv"
fi
if [ -x "$ENV_DIR/venv/bin/pip" ]; then
  if [ "$(cat "$ENV_DIR/.requirements.sha" 2>/dev/null || true)" = "$req_hash" ]; then
    ok "requirements.txt already installed"
  else
    if "$ENV_DIR/venv/bin/pip" install -q --disable-pip-version-check -r "$HERE/requirements.txt"; then
      echo "$req_hash" > "$ENV_DIR/.requirements.sha"; ok "requirements.txt installed"
    else
      warn "pip install failed (Manim needs the system packages above); fix those and re-run"
    fi
  fi
fi

# ------------------------------------------------------------------------------------------------
# 3. mermaid-cli
# ------------------------------------------------------------------------------------------------
info "mermaid-cli ($ENV_DIR/node_modules)"
if have npm; then
  pkg_hash="$(sha256sum "$HERE/package.json" | cut -d' ' -f1)"
  if [ -x "$ENV_DIR/node_modules/.bin/mmdc" ] && [ "$(cat "$ENV_DIR/.package.sha" 2>/dev/null || true)" = "$pkg_hash" ]; then
    ok "mermaid-cli already installed"
  else
    cp "$HERE/package.json" "$ENV_DIR/package.json"
    # Chrome comes from the system (see above), so do not download a bundled one.
    if (cd "$ENV_DIR" && PUPPETEER_SKIP_DOWNLOAD=1 npm install --no-audit --no-fund --silent); then
      echo "$pkg_hash" > "$ENV_DIR/.package.sha"; ok "mermaid-cli installed"
    else
      warn "npm install failed"
    fi
  fi
else
  warn "npm not found: skipping mermaid-cli"
fi

# ------------------------------------------------------------------------------------------------
# 4. Links and permissions
# ------------------------------------------------------------------------------------------------
link() { # <source> <dest>: idempotent symlink; an existing different file is backed up
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then ok "already linked: $dest"; return; fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "backing up $dest -> $dest.backup"
    mv "$dest" "$dest.backup"
  fi
  ln -s "$src" "$dest"
  ok "linked $dest"
}

if [ "$LINK" = 1 ]; then
  info "linking into place"
  mkdir -p "$BIN_DIR" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"
  for cmd in render-diagram render-plot render-manim; do link "$HERE/bin/$cmd" "$BIN_DIR/$cmd"; done
  for agent in "$HERE"/agents/*.md; do link "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"; done
  link "$HERE/skills/diagrams" "$CLAUDE_DIR/skills/diagrams"
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "$BIN_DIR is not on your PATH: the makers call render-diagram, render-plot and render-manim by name" ;; esac

  info "allowing the render commands in $CLAUDE_DIR/settings.json"
  rules=('Bash(render-diagram:*)' 'Bash(render-plot:*)' 'Bash(render-manim:*)' 'Bash(mktemp -d)' 'Bash(which latex)')
  settings="$CLAUDE_DIR/settings.json"
  if ! have jq; then
    warn "jq not found: add these to permissions.allow in $settings yourself: ${rules[*]}"
  else
    [ -f "$settings" ] || echo '{}' > "$settings"
    rules_json="$(printf '%s\n' "${rules[@]}" | jq -R . | jq -s .)"
    updated="$(jq --argjson r "$rules_json" '.permissions.allow = ((.permissions.allow // []) as $a | $a + ($r - $a))' "$settings")"
    if [ "$(jq -S . <<<"$updated")" = "$(jq -S . "$settings")" ]; then
      ok "permission rules already present"
    else
      [ -e "$settings.pre-diagram-makers" ] || cp "$settings" "$settings.pre-diagram-makers"
      printf '%s\n' "$updated" > "$settings.tmp" && mv "$settings.tmp" "$settings"
      ok "added the render commands to permissions.allow (backup: settings.json.pre-diagram-makers)"
    fi
  fi
fi

# ------------------------------------------------------------------------------------------------
# 5. Smoke test: one tiny diagram of each kind, in a throwaway folder
# ------------------------------------------------------------------------------------------------
info "smoke test"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export DIAGRAM_MAKERS_HOME="$ENV_DIR"
printf 'graph TD\n  a[Start] --> b[End]\n' > "$tmp/t.mmd"
printf '<svg xmlns="http://www.w3.org/2000/svg" width="60" height="40"><rect width="60" height="40" fill="#69c"/></svg>\n' > "$tmp/t.svg"
printf 'import os\nimport matplotlib.pyplot as plt\nfig, ax = plt.subplots()\nax.plot([0, 1], [0, 1])\nfig.savefig(os.environ["PLOT_OUT"])\n' > "$tmp/t.py"
smoke() { # <label> <command...>
  local label="$1"; shift
  if "$@" >"$tmp/out.log" 2>&1; then ok "$label"; else warn "$label failed: $(tail -1 "$tmp/out.log")"; fi
}
smoke "svg"     "$HERE/bin/render-diagram" svg "$tmp/t.svg"
smoke "mermaid" "$HERE/bin/render-diagram" mermaid "$tmp/t.mmd"
smoke "plot"    "$HERE/bin/render-plot" "$tmp/t.py"
if [ -x "$ENV_DIR/venv/bin/manim" ]; then ok "manim installed (render not smoke-tested: it is slow)"; else warn "manim not installed"; fi

echo
if [ "$WARNINGS" -eq 0 ]; then
  echo "Diagram makers ready."
else
  echo "Done with $WARNINGS warning(s); see above. Re-run this script after fixing them."
fi
