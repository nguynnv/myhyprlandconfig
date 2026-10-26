#!/usr/bin/env bash
set -Eeuo pipefail

DEST="${HOME}/.config/hypr/wallpapers"
SOURCE_URL="https://codeload.github.com/zhichaoh/catppuccin-wallpapers/tar.gz/refs/heads/main"
SOURCE_REPO="https://github.com/zhichaoh/catppuccin-wallpapers"
TEMP_DIR="$(mktemp -d)"
ARCHIVE="${TEMP_DIR}/wallpapers.tar.gz"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$DEST"

if find "$DEST" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) |
  grep -q .; then
  printf 'Đã có wallpaper trong %s; bỏ qua tải bộ mặc định.\n' "$DEST"
  exit 0
fi

command -v curl >/dev/null 2>&1 ||
  { printf 'Cần curl để tải wallpaper.\n' >&2; exit 1; }
command -v tar >/dev/null 2>&1 ||
  { printf 'Cần tar để giải nén wallpaper.\n' >&2; exit 1; }

printf 'Đang tải wallpaper chất lượng cao từ %s...\n' "$SOURCE_REPO"
curl --fail --location --silent --show-error --retry 3 --connect-timeout 15 \
  --max-time 180 "$SOURCE_URL" --output "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$TEMP_DIR"

count=0
while IFS= read -r -d '' image; do
  extension="${image##*.}"
  count=$((count + 1))
  cp -- "$image" "$DEST/catppuccin-${count}.${extension,,}"
  (( count >= 12 )) && break
done < <(
  find "$TEMP_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print0 | sort -z
)

if (( count == 0 )); then
  printf 'Nguồn wallpaper không chứa file ảnh hợp lệ.\n' >&2
  exit 1
fi

cat > "$DEST/SOURCE.txt" <<EOF
Wallpaper source: $SOURCE_REPO
License: MIT
Downloaded by the Hyprland Ubuntu setup.
EOF
printf 'Đã tải %d wallpaper vào %s.\n' "$count" "$DEST"
