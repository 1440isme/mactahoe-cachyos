# MacTahoe cho GNOME

Repo cá nhân để đóng gói lại bộ giao diện MacTahoe và các tiện ích đang dùng trên máy.

## Hình ảnh

<p align="center"><img src="assets/screenshots/mactahoe-desktop.png" alt="Desktop MacTahoe trên GNOME với widget và dock" width="100%"></p>

<table>
  <tr>
    <td><img src="assets/screenshots/mactahoe-overview.png" alt="GNOME Overview với giao diện MacTahoe" width="100%"></td>
    <td><img src="assets/screenshots/mactahoe-settings.png" alt="GNOME Settings và Files theo giao diện MacTahoe" width="100%"></td>
  </tr>
</table>

## Nội dung đã gom

- `vendor/MacTahoe-gtk-theme/` và `vendor/MacTahoe-icon-theme/`: snapshot nguồn theme, đã bỏ metadata Git lồng bên trong.
- `assets/fonts/SF-Pro/` và `assets/fonts/SF-Mono/`: font đang dùng.
- `assets/wallpapers/`: wallpaper ngày và đêm.
- `assets/screenshots/`: ảnh giới thiệu desktop, Overview và giao diện ứng dụng.
- `apps/`: launcher điều khiển widget, trình quản lý icon và script lấy dữ liệu.
- `conky/`: cấu hình và Lua cho widget.
- `desktop/`: launcher ứng dụng.
- `config/weather.conf`: vị trí thời tiết hiện tại; chỉnh lại trước khi dùng trên máy khác.
- `vendor/gnome-extensions/`: snapshot các extension giao diện được cài, gồm Blur My Shell, Global Menu và Just Perfection.
- `docs/extension-settings/current-gnome-extensions.md`: các extension đang bật và cấu hình Blur/My Shell, Global Menu trên máy.
- `docs/skin-tahoe-source.md`: hướng dẫn cấu hình ban đầu.
- `config/gsettings.tsv`: tùy chọn GNOME, dock và extension được áp dụng.
- `config/firefox-user.js`: tùy chọn cần cho CSS theme Firefox.

## Thành phần giao diện

- Theme GTK/GNOME Shell, bộ icon MacTahoe, con trỏ, font SF và wallpaper tạo phần giao diện nền.
- Blur My Shell, Global Menu và Just Perfection là ba extension giao diện được cài từ repo; User Themes là extension hệ thống hỗ trợ theme GNOME Shell. Blur My Shell được cài sẵn cấu hình nhưng mặc định tắt; có thể bật sau trong Extension Manager.
- Trên Ubuntu, thanh dock là Ubuntu Dock có sẵn của hệ thống; repo chỉ cấu hình nó, không cài Plank hay Docky.
- GNOME Tweaks và Extension Manager là ứng dụng quản lý tùy chọn/extension, không phải thành phần tạo giao diện. Trình quản lý icon MacTahoe và launcher widget là tiện ích riêng của repo.
- Extension được kiểm tra theo phiên bản GNOME Shell khai báo trong metadata và chỉ được bật cho lần đăng nhập tiếp theo.

## Trạng thái

Mở Terminal ở bất kỳ thư mục nào, dán nguyên lệnh này để tải/cập nhật repo rồi cài:

```bash
cd "$HOME" && if [ -d mactahoe-ubuntu/.git ]; then git -C mactahoe-ubuntu pull --ff-only; else git clone https://github.com/adfoxtheme/mactahoe-ubuntu.git mactahoe-ubuntu; fi && cd "$HOME/mactahoe-ubuntu" && ./install.sh
```

Nếu repo đã có trong `~/mactahoe-ubuntu` và chỉ muốn chạy lại cài đặt từ bất kỳ thư mục nào:

```bash
cd "$HOME/mactahoe-ubuntu" && ./install.sh
```

Lệnh trên cài GNOME Tweaks, Extension Manager, theme GTK/Shell, icon/cursor, font, wallpaper, cấu hình GNOME/dock, các extension giao diện, Firefox, widget và trình quản lý icon. Theme màn hình đăng nhập GDM **không cài mặc định** vì có thể làm hỏng màn hình đăng nhập khi không tương thích; chỉ chạy `./install.sh --with-gdm` nếu bạn chủ động muốn thử trên máy Ubuntu của mình. Widget chỉ chạy khi mở launcher, không tự bật lúc đăng nhập.

### Sau khi cài

1. Chờ Terminal báo `Installed`, sau đó đăng xuất rồi đăng nhập lại để GNOME nạp theme và extension. Nếu đã chủ động cài theme màn hình đăng nhập bằng `--with-gdm`, khởi động lại máy.
2. Widget không tự chạy khi đăng nhập. Mở ứng dụng **Widget MacTahoe** trong danh sách ứng dụng, hoặc chạy `mactahoe-widgets start` trong Terminal. Tắt widget bằng `mactahoe-widgets stop`.
3. Mở **Quản lý icon MacTahoe** trong danh sách ứng dụng để chọn icon riêng cho ứng dụng. Font và bộ icon/theme tổng thể đã được cài tự động. Muốn bật hiệu ứng Blur My Shell, mở Extension Manager và bật extension; cấu hình Tahoe đã được nạp sẵn.
4. Nếu không thấy thay đổi, kiểm tra Terminal đã hiện thông báo `Installed` chưa; nếu có, thử đăng xuất/đăng nhập lại một lần nữa.

Chạy `./uninstall.sh` để gỡ theme và ứng dụng, khôi phục file đã sao lưu; script hỏi trước khi khôi phục bản sao cấu hình GNOME. Các gói hệ thống được giữ lại.

`install.sh` hiện chỉ hỗ trợ Ubuntu và yêu cầu GNOME Shell 48 trở lên. GDM là bước tùy chọn, không chạy trong lệnh cài mặc định; khi được yêu cầu bằng `--with-gdm`, script cài `yaru-theme-gnome-shell` làm nền rồi áp dụng theme Tahoe lên resource GDM và sao lưu resource gốc. Extension có thể cần bản cập nhật tương thích với phiên bản GNOME đang dùng; GNOME có thể tự vô hiệu hóa extension không tương thích. Sau khi cài cần đăng xuất/đăng nhập lại để nạp extension; nếu cài GDM thì reboot để thấy thay đổi.

## Nguồn và phiên bản theme

- MacTahoe GTK: commit `1e45e19` theo tài liệu cấu hình.
- MacTahoe icons: commit `839848b9` theo tài liệu cấu hình.
- Theme gốc có hướng dẫn và thông tin giấy phép bên trong từng thư mục `vendor/`.

Font SF Pro được đưa kèm trong repo. Hãy kiểm tra điều khoản giấy phép trước khi phân phối lại.
