# MacTahoe cho GNOME

Repo cá nhân để đóng gói lại bộ giao diện MacTahoe và các tiện ích đang dùng trên máy.

## Nội dung đã gom

- `vendor/MacTahoe-gtk-theme/` và `vendor/MacTahoe-icon-theme/`: snapshot nguồn theme, đã bỏ metadata Git lồng bên trong.
- `assets/fonts/SF-Pro/` và `assets/fonts/SF-Mono/`: font đang dùng.
- `assets/wallpapers/`: wallpaper ngày và đêm.
- `apps/`: launcher điều khiển widget, trình quản lý icon và script lấy dữ liệu.
- `conky/`: cấu hình và Lua cho widget.
- `desktop/`: launcher ứng dụng.
- `config/weather.conf`: vị trí thời tiết hiện tại; chỉnh lại trước khi dùng trên máy khác.
- `vendor/gnome-extensions/`: snapshot các extension người dùng hiện đang bật, gồm Blur My Shell, Global Menu, Just Perfection, Forward Keys và Kimpanel.
- `docs/extension-settings/current-gnome-extensions.md`: các extension đang bật và cấu hình Blur/My Shell, Global Menu trên máy.
- `docs/skin-tahoe-source.md`: hướng dẫn cấu hình ban đầu.
- `config/gsettings.tsv`: tùy chọn GNOME, dock và extension được áp dụng.
- `config/firefox-user.js`: tùy chọn cần cho CSS theme Firefox.

## Trạng thái

Repo hiện để riêng tư. Sau khi đăng nhập GitHub có quyền đọc repo, cài bằng một lệnh:

```bash
git clone https://github.com/adfoxtheme/mactahoe-ubuntu.git && cd mactahoe-ubuntu && ./install.sh
```

Lệnh trên cài GNOME Tweaks, Extension Manager, theme GTK/Shell, icon/cursor, font, wallpaper, cấu hình GNOME/dock, các extension, Firefox, widget và trình quản lý icon. GDM được áp dụng ở cuối và cần quyền quản trị; dùng `./install.sh --without-gdm` để bỏ riêng màn hình đăng nhập. Widget chỉ chạy khi mở launcher, không tự bật lúc đăng nhập.

Chạy `./uninstall.sh` để gỡ theme và ứng dụng, khôi phục file đã sao lưu; script hỏi trước khi khôi phục bản sao cấu hình GNOME. Các gói apt được giữ lại.

`install.sh` nhận diện Ubuntu/Debian (`apt`), Fedora (`dnf`) và Arch (`pacman`), yêu cầu GNOME Shell 48 trở lên. Thiết lập Dock/favorites và theme màn hình đăng nhập chỉ áp dụng cho Ubuntu; theme GDM dùng Yaru nên các hệ khác tự bỏ qua bước này. Trên Debian, Fedora và Arch, script cài phần giao diện/tiện ích chung nhưng chưa áp dụng cấu hình distro-specific. Extension có thể cần bản cập nhật tương thích với phiên bản GNOME đang dùng; GNOME có thể tự vô hiệu hóa extension không tương thích. Sau khi cài cần đăng xuất/đăng nhập lại để nạp extension; nếu cài GDM thì reboot để thấy thay đổi.

## Nguồn và phiên bản theme

- MacTahoe GTK: commit `1e45e19` theo tài liệu cấu hình.
- MacTahoe icons: commit `839848b9` theo tài liệu cấu hình.
- Theme gốc có hướng dẫn và thông tin giấy phép bên trong từng thư mục `vendor/`.

Font SF Pro được giữ trong repo cá nhân theo yêu cầu sử dụng cá nhân. Không công khai repo kèm font nếu chưa xác nhận quyền phân phối.
