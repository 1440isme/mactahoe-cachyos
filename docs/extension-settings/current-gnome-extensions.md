# GNOME extensions đang bật trên máy

Snapshot được đọc từ cấu hình hiện tại. Bộ cài cần cài/copy các extension và đặt các giá trị bên dưới để tái tạo giao diện. Không bật Conky tự động lúc đăng nhập.

## Blur My Shell

Extension: `blur-my-shell@aunetx`.

- Bật blur: `overview` và `appfolder`.
- Tắt blur: `applications`, `coverflow-alt-tab`, `dash-to-dock`, `lockscreen`, `panel`, `popup`, `screenshot`, `window-list`.
- Pipeline đang dùng: `pipeline_default`, Dual Kawase, radius 30, brightness 0.6.
- Ứng dụng `Plank` và `Conky` có trong danh sách loại trừ.
- `dash-to-dock` có `static-blur=true` nhưng `blur=false`, nên blur dock hiện không hoạt động.

## Global Menu for GNOME

Extension: `globalmenu@ShiroOSL.github.io`, version 15. Cấu hình hiện có bật thanh menu và nút System Menu. Các mục App, File, Edit, View, Go, Window, Help đều bật; các lối tắt System Menu như Settings, Terminal, Software Center, Force Quit, System Monitor, khóa/đăng xuất/tắt máy cũng bật.

Các giá trị chính: `show-indicator=true`, `show-logo-menu=true`, `hide-overview-button=true`, `logo-distro-icon-symbolic=true`, kích thước icon 16.

## Extension khác đang bật

- `just-perfection-desktop@just-perfection`, version 37: đồng hồ bên phải (`clock-menu-position=1`), offset 20; ẩn nút Overview.

## Extension hệ thống liên quan

Tài liệu cấu hình cũng dùng `user-theme@gnome-shell-extensions.gcampax.github.com` và `ubuntu-dock@ubuntu.com`. Đây là extension đi kèm Ubuntu/gói hệ thống, không phải thư mục extension riêng trong repo này.
