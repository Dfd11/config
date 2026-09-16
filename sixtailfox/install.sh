#!/usr/bin/env bash
# Interactive checklist over setup.sh's stages. Picking a stage auto-includes
# whatever it depends on (see STAGE_DEPS in setup.sh) - you only ever choose
# from the big items.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$DIR/setup.sh"

if ! command -v whiptail >/dev/null 2>&1; then
  echo "whiptail is required for the menu. Install it (sudo apt-get install -y whiptail)" >&2
  echo "or run setup.sh directly, e.g.: $SETUP nvim shell" >&2
  exit 1
fi

args=()
while IFS=$'\t' read -r id desc; do
  args+=("$id" "$desc" OFF)
done < <("$SETUP" --list)

selection="$(whiptail --title "sixtailfox setup" --checklist \
  "Select what to install (space to toggle, enter to confirm).\nDependencies are pulled in automatically." \
  24 90 14 "${args[@]}" 3>&1 1>&2 2>&3)" || { echo "cancelled"; exit 1; }

[ -z "$selection" ] && { echo "nothing selected"; exit 0; }

eval "stages=($selection)"
exec "$SETUP" "${stages[@]}"
