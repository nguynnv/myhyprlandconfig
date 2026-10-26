#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${HOME}/.config"
BACKUPS_DIR="${CONFIG_DIR}/hyprland-backups"
RESTORE_DIR=""
RESTORE=1

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--no-restore]

Xoá các cấu hình do bộ cài triển khai. Mặc định sẽ khôi phục backup gần nhất.
Script không tự gỡ package hoặc thay đổi display manager.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --no-restore) RESTORE=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

if (( RESTORE )) && [[ -d "$BACKUPS_DIR" ]]; then
  RESTORE_DIR="$(find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' |
    sort -nr | head -n1 | cut -d' ' -f2-)"
fi

if [[ -n "$RESTORE_DIR" && -d "$RESTORE_DIR" ]]; then
  echo "Khôi phục backup: $RESTORE_DIR"
  for name in hypr waybar wofi dunst kitty gtk-3.0 gtk-4.0; do
    target="$CONFIG_DIR/$name"
    [[ -e "$target" ]] && mv "$target" "${target}.hyprland-installed"
    [[ -e "$RESTORE_DIR/$name" ]] && mv "$RESTORE_DIR/$name" "$target"
  done
else
  echo "Không có backup để khôi phục; chỉ xoá cấu hình Hyprland đã cài."
  for name in hypr waybar wofi dunst kitty gtk-3.0 gtk-4.0; do
    rm -rf -- "$CONFIG_DIR/$name"
  done
fi

echo "Đã gỡ cấu hình người dùng. Package và SDDM vẫn được giữ nguyên."
