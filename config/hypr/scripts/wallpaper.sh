#!/usr/bin/env bash
set -Eeuo pipefail

WALLPAPER_DIR="${HOME}/.config/hypr/wallpapers"
STATE_FILE="${XDG_STATE_HOME:-${HOME}/.local/state}/hyprland-wallpaper"
mkdir -p "$(dirname "$STATE_FILE")" "$WALLPAPER_DIR"

mapfile -d '' WALLPAPERS < <(
  find "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print0
)

status() {
  if [[ -s "$STATE_FILE" ]]; then
    basename -- "$(cat "$STATE_FILE")"
  else
    printf 'wallpaper'
  fi
}

choose_random() {
  ((${#WALLPAPERS[@]} > 0)) || return 1
  printf '%s' "${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
}

apply_wallpaper() {
  local image="$1"
  printf '%s' "$image" > "$STATE_FILE"
  if command -v swww >/dev/null 2>&1; then
    pgrep -x swww-daemon >/dev/null 2>&1 || swww-daemon >/dev/null 2>&1 &
    sleep 0.3
    local transitions=(simple fade grow center wipe wave outer inner)
    local transition="${transitions[RANDOM % ${#transitions[@]}]}"
    swww img "$image" --transition-type "$transition" --transition-duration 1.2 \
      --transition-fps 60 --transition-pos 0.5,0.5
  elif command -v hyprctl >/dev/null 2>&1; then
    hyprctl hyprpaper wallpaper ",$image"
  else
    printf 'Không tìm thấy swww hoặc hyprctl để đặt wallpaper.\n' >&2
    return 1
  fi
}

pick() {
  ((${#WALLPAPERS[@]} > 0)) || {
    notify-send "Hyprland wallpaper" "Hãy thêm ảnh vào $WALLPAPER_DIR" 2>/dev/null || true
    return 1
  }
  local selected
  selected="$(printf '%s\n' "${WALLPAPERS[@]}" | sed "s#^${WALLPAPER_DIR}/##" |
    wofi --dmenu --prompt "Wallpaper" --cache-file /dev/null)"
  [[ -n "$selected" ]] && apply_wallpaper "$WALLPAPER_DIR/$selected"
}

next() {
  ((${#WALLPAPERS[@]} > 0)) || return 1
  local current next_index=0 i
  current="$(cat "$STATE_FILE" 2>/dev/null || true)"
  for i in "${!WALLPAPERS[@]}"; do
    [[ "${WALLPAPERS[$i]}" == "$current" ]] && next_index=$(( (i + 1) % ${#WALLPAPERS[@]} ))
  done
  apply_wallpaper "${WALLPAPERS[$next_index]}"
}

case "${1:---random}" in
  --start)
    if image="$(choose_random)"; then
      apply_wallpaper "$image"
    else
      hyprpaper >/dev/null 2>&1 &
    fi
    ;;
  --random)
    image="$(choose_random)" && apply_wallpaper "$image"
    ;;
  --next) next ;;
  --pick) pick ;;
  --status) status ;;
  *) printf 'Usage: %s [--start|--random|--next|--pick|--status]\n' "$0" >&2; exit 2 ;;
esac
