#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
INSTALL_SDDM=1
INSTALL_PACKAGES=1
DOWNLOAD_WALLPAPERS=1
BACKUP_DIR="${HOME}/.config/hyprland-backups/$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--dry-run] [--no-sddm] [--no-packages] [--no-wallpapers]
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-sddm) INSTALL_SDDM=0 ;;
    --no-packages) INSTALL_PACKAGES=0 ;;
    --no-wallpapers) DOWNLOAD_WALLPAPERS=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

log() { printf '\033[1;36m[hyprland]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warning]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

(( EUID == 0 )) && die "Không chạy script bằng root; hãy chạy bằng user thường để cài vào HOME."
[[ -r /etc/os-release ]] || die "Không xác định được hệ điều hành."
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "Bộ cài này dành cho Ubuntu."

if [[ "${VERSION_ID:-}" != "26.04" ]]; then
  warn "Đang chạy Ubuntu ${VERSION_ID:-unknown}; bộ cài được thiết kế cho Ubuntu 26.04 LTS."
fi

if (( INSTALL_PACKAGES )); then
  command -v sudo >/dev/null 2>&1 || die "Cần sudo để cài package hệ thống."
  packages=(
    hyprland hyprpaper waybar wofi dunst kitty swaybg grim slurp wl-clipboard curl
    brightnessctl playerctl pavucontrol network-manager-gnome xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk polkit-kde-agent-1 fonts-inter fonts-jetbrains-mono
    thunar thunar-archive-plugin thunar-volman gvfs gvfs-backends tumbler
    papirus-icon-theme
  )
  (( INSTALL_SDDM )) && packages+=(sddm sddm-theme-breeze qt6-wayland)

  log "Cập nhật package index và cài các thành phần desktop."
  run sudo apt-get update
  run sudo apt-get install -y --no-install-recommends "${packages[@]}"
  if apt-cache show swww >/dev/null 2>&1; then
    run sudo apt-get install -y --no-install-recommends swww
  else
    warn "Không tìm thấy package swww; wallpaper vẫn hoạt động qua hyprpaper."
  fi
fi

if ! command -v hyprland >/dev/null 2>&1 && (( ! DRY_RUN )); then
  die "Không tìm thấy lệnh hyprland sau khi cài. Hãy kiểm tra package repository Ubuntu."
fi

if (( ! DRY_RUN )); then
  mkdir -p "$BACKUP_DIR"
  log "Backup cấu hình hiện tại vào $BACKUP_DIR"
  for path in "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/wofi" \
              "$HOME/.config/dunst" "$HOME/.config/kitty" "$HOME/.config/gtk-3.0" \
              "$HOME/.config/gtk-4.0"; do
    [[ -e "$path" ]] || continue
    run mv "$path" "$BACKUP_DIR/"
  done
fi

log "Triển khai cấu hình người dùng."
run mkdir -p "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/wallpapers" \
  "$HOME/.config/waybar" "$HOME/.config/wofi" "$HOME/.config/dunst" "$HOME/.config/kitty" \
  "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
run cp "$SCRIPT_DIR/config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
run cp "$SCRIPT_DIR/config/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
run cp "$SCRIPT_DIR/config/hypr/scripts/wallpaper.sh" "$HOME/.config/hypr/scripts/wallpaper.sh"
run cp "$SCRIPT_DIR/config/hypr/scripts/download-wallpapers.sh" \
  "$HOME/.config/hypr/scripts/download-wallpapers.sh"
run cp -r "$SCRIPT_DIR/config/hypr/wallpapers/." "$HOME/.config/hypr/wallpapers/"
run cp "$SCRIPT_DIR/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
run cp "$SCRIPT_DIR/config/waybar/style.css" "$HOME/.config/waybar/style.css"
run cp "$SCRIPT_DIR/config/wofi/style.css" "$HOME/.config/wofi/style.css"
run cp "$SCRIPT_DIR/config/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
run cp "$SCRIPT_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
run cp "$SCRIPT_DIR/config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
run cp "$SCRIPT_DIR/config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
run chmod 700 "$HOME/.config/hypr/scripts/wallpaper.sh"
run chmod 700 "$HOME/.config/hypr/scripts/download-wallpapers.sh"
run chmod 700 "$HOME/.config"

if (( DOWNLOAD_WALLPAPERS )); then
  if (( DRY_RUN )); then
    log "Sẽ tải bộ wallpaper Catppuccin MIT vào ~/.config/hypr/wallpapers."
  else
    "$HOME/.config/hypr/scripts/download-wallpapers.sh" ||
      warn "Không tải được wallpaper; bạn có thể chạy lại download-wallpapers.sh sau."
  fi
fi

if (( ! DRY_RUN )) && command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default thunar.desktop inode/directory
fi

if (( INSTALL_SDDM )); then
  log "Cấu hình SDDM. SDDM không bị gỡ bỏ nếu máy đã có display manager khác."
  run sudo install -Dm644 "$SCRIPT_DIR/system/sddm.conf" \
    /etc/sddm.conf.d/10-hyprland.conf
  if (( ! DRY_RUN )); then
    if command -v debconf-set-selections >/dev/null 2>&1; then
      printf 'sddm shared/default-display-manager select /usr/bin/sddm\n' |
        sudo debconf-set-selections
    fi
    run sudo systemctl enable sddm
  fi
fi

log "Hoàn tất. Reboot để vào Hyprland qua SDDM."
