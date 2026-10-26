# Hyprland Ubuntu 26.04 LTS setup

Bộ cài này tạo một desktop Hyprland tối giản, dark/glass, có blur, animation,
Waybar, Wofi, Dunst, Kitty và SDDM làm login manager.

## Cài đặt

```bash
cd hyprland
chmod +x setup.sh
./setup.sh
```

Sau khi script hoàn tất, hãy reboot và chọn **Hyprland** ở màn hình đăng nhập.
Script tự tạo bản sao lưu các file cũ trong `~/.config/hyprland-backups/<timestamp>`.

### Tuỳ chọn

```bash
./setup.sh --dry-run       # Chỉ xem các lệnh, không thay đổi hệ thống
./setup.sh --no-sddm       # Không cài/đổi display manager
./setup.sh --no-packages   # Chỉ triển khai file cấu hình
./setup.sh --no-wallpapers # Không tải bộ wallpaper mặc định
```

Để gỡ cấu hình người dùng và khôi phục backup gần nhất:

```bash
./uninstall.sh
./uninstall.sh --no-restore
```

`uninstall.sh` không tự gỡ package và không tắt SDDM, nhằm tránh làm mất display
manager đang dùng cho hệ thống.

## Phím tắt chính

| Phím | Tác vụ |
|---|---|
| `Super + Enter` | Mở Kitty |
| `Super + D` | Mở Wofi |
| `Super + E` | Mở Thunar file manager |
| `Super + B` | Mở trình duyệt |
| `Super + Q` | Đóng cửa sổ |
| `Super + Shift + Q` | Thoát Hyprland |
| `Super + 1..9` | Chuyển workspace |
| `Super + Shift + 1..9` | Chuyển cửa sổ sang workspace |
| `Super + V` | Float/unfloat cửa sổ |
| `Super + F` | Fullscreen |
| `Super + W` | Mở trình chọn hình nền |
| `Super + Shift + W` | Đổi hình nền ngẫu nhiên |
| `Super + N` | Chuyển sang hình nền kế tiếp |
| `Print` | Chụp vùng màn hình |

## Wallpaper

Thêm ảnh vào `~/.config/hypr/wallpapers/` với định dạng JPG, JPEG, PNG hoặc
WebP. Wallpaper được chọn ngẫu nhiên khi Hyprland khởi động. Module wallpaper
trên Waybar hỗ trợ click trái để mở Wofi chọn ảnh, click phải để random và
cuộn chuột để chuyển sang ảnh kế tiếp.

Khi cài đặt, bộ script tự tải tối đa 12 wallpaper chất lượng cao từ bộ
[Catppuccin Wallpapers](https://github.com/zhichaoh/catppuccin-wallpapers) vào
thư mục này. Bộ ảnh được phát hành theo MIT License và nguồn/license được lưu
ở `~/.config/hypr/wallpapers/SOURCE.txt`. Nếu thư mục đã có ảnh, installer
không tải đè ảnh của người dùng. Có thể chạy lại thủ công bằng:

```bash
~/.config/hypr/scripts/download-wallpapers.sh
```

Nếu `swww` khả dụng, script dùng hiệu ứng fade, grow, wipe hoặc wave ngẫu
nhiên trong 1,2 giây. Khi không có `swww`, script fallback sang `hyprpaper`.

## File manager

Bộ cài sử dụng **Thunar** vì nhẹ, ổn định và phù hợp với desktop Hyprland.
Installer cài thêm `gvfs`/`gvfs-backends` để truy cập USB, network share và
thùng rác; `tumbler` để tạo thumbnail; cùng `thunar-archive-plugin` để thao
tác file nén.

Thunar dùng `Adwaita-dark`, icon `Papirus-Dark`, font Inter và animation GTK
giống phần còn lại của desktop. Các thiết lập GTK nằm trong
`config/gtk-3.0/settings.ini` và `config/gtk-4.0/settings.ini`. Thư mục được
đặt làm ứng dụng mặc định cho MIME type `inode/directory`.

## Ghi chú phần cứng

- Hyprland cần phiên Wayland và driver đồ họa hoạt động. Với NVIDIA, nên dùng
  driver proprietary tương thích Ubuntu và kiểm tra `nvidia-smi` trước khi đăng nhập.
- Cấu hình dùng `monitor = , preferred, auto, 1`. Có thể chỉnh trong
  `config/hypr/hyprland.conf` nếu cần nhiều màn hình hoặc scaling.
- SDDM không được bật tự động nếu dùng `--no-sddm`. Nếu máy đang dùng GDM,
  script không gỡ GDM và chỉ đặt SDDM làm display manager mặc định khi bạn
  xác nhận ở bước cài đặt.
