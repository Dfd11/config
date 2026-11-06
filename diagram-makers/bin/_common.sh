# shellcheck shell=bash
# Shared by render-diagram, render-plot and render-manim (sourced, not run).
#
# Layout:  TOOLS_DIR  the diagram-makers folder (scripts, kit): tracked in the config repo
#          ENV_DIR    the generated environment (venv, node_modules): never tracked
# Output:  ./diagrams unless --out <dir> or $DIAGRAM_OUT says otherwise.

TOOLS_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")/.." && pwd)"
ENV_DIR="${DIAGRAM_MAKERS_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/diagram-makers}"

die() { echo "$*" >&2; exit 1; }

# Sets POSITIONAL (array), SLUG (--save), OUT (--out), KIT (--kit). Calls usage() for -h.
parse_flags() {
  POSITIONAL=(); SLUG=""; OUT=""; KIT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --save) [[ -n "${2:-}" ]] || die "--save needs a name"; SLUG="$2"; shift 2 ;;
      --out)  [[ -n "${2:-}" ]] || die "--out needs a folder"; OUT="$2"; shift 2 ;;
      --kit)  KIT=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) POSITIONAL+=("$1"); shift ;;
    esac
  done
}

slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }

# publish <slug> <artifact-file> <artifact-ext> <source-file> <source-ext>
# Copies the result and its source side by side into the output folder under a stable name
# (<slug>.<ext>), so a document can link to it and a later run with the same slug updates it.
publish() {
  local slug clean dest replaced=no
  slug="$1"; clean="$(slugify "$slug")"; clean="${clean:-diagram}"
  local dir="${OUT:-${DIAGRAM_OUT:-./diagrams}}"
  mkdir -p "$dir"; dir="$(cd "$dir" && pwd)"
  dest="$dir/$clean.$3"
  [[ -e "$dest" ]] && replaced=yes
  cp "$2" "$dest"
  cp "$4" "$dir/$clean.$5"
  echo "filename: $clean.$3"
  echo "path: $dest"
  echo "source: $dir/$clean.$5"
  echo "replaced: $replaced"
}

# Print the helper docs of a kit directory (used by --kit) so an agent can find them anywhere.
print_kit() {
  echo "kit: $1"
  echo "examples: $1/examples"
  echo "----"
  cat "$1/README.md"
}
