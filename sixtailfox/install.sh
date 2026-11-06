#!/usr/bin/env bash
# Interactive checklist over setup.sh's stages. Picking a stage auto-includes
# whatever it depends on (see STAGE_DEPS in setup.sh) - you only ever choose
# from the big items. Renders inline in the terminal via fzf, no GUI/whiptail box.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$DIR/setup.sh"

fzf_bin="$(command -v fzf || true)"
[ -z "$fzf_bin" ] && [ -x "$HOME/.fzf/bin/fzf" ] && fzf_bin="$HOME/.fzf/bin/fzf"
if [ -z "$fzf_bin" ]; then
  echo "fzf is required for the menu (it's part of the 'shell' stage)." >&2
  echo "Install it first, or run setup.sh directly, e.g.: $SETUP nvim shell" >&2
  exit 1
fi

rows="$("$SETUP" --list | column -t -s $'\t')"

selection="$(printf '%s\n' "$rows" | "$fzf_bin" \
  --multi --cycle --no-preview \
  --prompt='install> ' \
  --header='TAB select, TAB again to deselect, ENTER to confirm, ESC to cancel' \
  --header-first)"

[ -z "$selection" ] && { echo "nothing selected"; exit 0; }

stages=()
while IFS= read -r line; do
  stages+=("${line%% *}")
done <<<"$selection"

extra_args=()
for s in "${stages[@]}"; do
  if [ "$s" = "vscode" ]; then
    ext_rows="$("$SETUP" --list-vscode-ext | column -t -s $'\t')"
    ext_selection="$(printf '%s\n' "$ext_rows" | "$fzf_bin" \
      --multi --cycle --no-preview \
      --prompt='vscode ext> ' \
      --header='TAB select, ENTER to confirm - none selected keeps defaults (markdown, python, github)' \
      --header-first)"
    if [ -n "$ext_selection" ]; then
      ext_groups=()
      while IFS= read -r line; do
        ext_groups+=("${line%% *}")
      done <<<"$ext_selection"
      extra_args+=("--vscode-ext=$(IFS=,; echo "${ext_groups[*]}")")
    fi
    break
  fi
done

# The diagram makers have optional extras (all off by default). The first row is "skip", so a plain
# ENTER, or ESC, adds nothing; TAB marks an extra, then ENTER.
for s in "${stages[@]}"; do
  if [ "$s" = "diagrams" ]; then
    opt_rows="$(printf 'none\tSkip - just the diagram makers\n'; "$SETUP" --list-diagrams-opt)"
    opt_rows="$(printf '%s\n' "$opt_rows" | column -t -s $'\t')"
    opt_selection="$(printf '%s\n' "$opt_rows" | "$fzf_bin" \
      --multi --cycle --no-preview \
      --prompt='diagrams extras> ' \
      --header='ENTER alone adds nothing. TAB marks an extra, then ENTER. ESC also skips.' \
      --header-first || true)"
    if [ -n "$opt_selection" ]; then
      opts=()
      while IFS= read -r line; do
        id="${line%% *}"
        [ "$id" != "none" ] && opts+=("$id")
      done <<<"$opt_selection"
      if [ ${#opts[@]} -gt 0 ]; then
        extra_args+=("--diagrams-opt=$(IFS=,; echo "${opts[*]}")")
      fi
    fi
    break
  fi
done

exec "$SETUP" "${stages[@]}" "${extra_args[@]}"
