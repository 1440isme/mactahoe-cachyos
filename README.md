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
- Topbar dùng kiểu trong suốt của chính MacTahoe GNOME Shell theme (`#panel` trong CSS); Blur My Shell cho panel vẫn tắt, không cần bật blur để có nền trong suốt.
- Firefox bật bo góc cửa sổ tối đa hóa 16 px bằng CSS của theme; cấu hình `user.js` cũng bật góc CSD GTK.
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

Lệnh trên cài GNOME Tweaks, Extension Manager, theme GTK/Shell, icon/cursor, font, wallpaper, cấu hình GNOME/dock, các extension giao diện, Firefox, widget và trình quản lý icon. GDM được cài riêng, không chạy lại toàn bộ installer. Sau khi đã tải repo về `~/mactahoe-ubuntu`, mở Terminal ở bất kỳ thư mục nào và chạy lệnh này để chỉ cài màn hình đăng nhập:

```bash
cd "$HOME/mactahoe-ubuntu" && ./install-gdm.sh
```

> [!CAUTION]
> **CÀI GDM CÓ THỂ LÀM HỎNG MÀN HÌNH ĐĂNG NHẬP.** Đây là màn hình đăng nhập của hệ thống (GDM), không phải màn hình khóa trong phiên GNOME. Bước này thay resource Yaru của Ubuntu bằng resource theme đã biên dịch. Nếu resource không tương thích hoặc có lỗi ngoài bước kiểm tra, GDM có thể hiện màn hình đen hoặc không cho đăng nhập; điều này có thể trông giống GNOME bị treo.
>
> Chỉ chạy nếu bạn chấp nhận rủi ro và biết cách vào TTY/khôi phục máy; nên tạo snapshot máy ảo hoặc bản sao lưu trước. Không chạy bằng `sudo ./install-gdm.sh` — script sẽ tự yêu cầu quyền quản trị khi cần.
>
> Nếu GDM lỗi, chuyển sang TTY (`Ctrl`+`Alt`+`F3`; trong VirtualBox dùng **Host key** + `F3`, thường là `Right Ctrl` + `F3`), đăng nhập tài khoản thường rồi khôi phục resource GDM:
>
> ```bash
> sudo "$HOME/mactahoe-ubuntu/vendor/MacTahoe-gtk-theme/tweaks.sh" -g -r
> sudo reboot
> ```
>
> Lệnh khôi phục trên giả định repo nằm ở `~/mactahoe-ubuntu`; nếu lưu ở chỗ khác, thay bằng đường dẫn repo thực tế. Nếu lần chạy dừng ở bước kiểm tra/biên dịch trước khi áp dụng, GDM chưa bị thay đổi.

Widget chỉ chạy khi mở launcher, không tự bật lúc đăng nhập.

### Sau khi cài

1. Chờ Terminal báo `Installed`, sau đó đăng xuất rồi đăng nhập lại để GNOME nạp theme và extension. Sau khi cài riêng GDM bằng `install-gdm.sh`, khởi động lại máy.
2. Widget không tự chạy khi đăng nhập. Mở ứng dụng **Widget MacTahoe** trong danh sách ứng dụng, hoặc chạy `mactahoe-widgets start` trong Terminal. Tắt widget bằng `mactahoe-widgets stop`.
3. Mở **Quản lý icon MacTahoe** trong danh sách ứng dụng để chọn icon riêng cho ứng dụng. Font và bộ icon/theme tổng thể đã được cài tự động. Muốn bật hiệu ứng Blur My Shell, mở Extension Manager và bật extension; cấu hình Tahoe đã được nạp sẵn.
4. Nếu không thấy thay đổi, kiểm tra Terminal đã hiện thông báo `Installed` chưa; nếu có, thử đăng xuất/đăng nhập lại một lần nữa.

### Gỡ cài đặt

Để gỡ giao diện, tiện ích và khôi phục các file đã sao lưu (giữ lại thư mục repo để có thể cài lại), mở Terminal ở bất kỳ vị trí nào và chạy:

```bash
cd "$HOME/mactahoe-ubuntu" && ./uninstall.sh
```

Chạy bằng tài khoản thường, không thêm `sudo`; trình gỡ sẽ hỏi xác nhận trước khi khôi phục bản sao cấu hình GNOME. Nếu đã cài theme màn hình đăng nhập, lệnh này cũng sẽ yêu cầu mật khẩu sudo để khôi phục. Các gói hệ thống được giữ lại.

`install.sh` và `install-gdm.sh` hiện chỉ hỗ trợ Ubuntu. Bộ cài GDM kiểm tra GDM3 đang có, cài các công cụ biên dịch/Yaru nếu thiếu, kiểm tra resource theme trước khi áp dụng giao diện Tahoe. Bước này thay đổi resource màn hình đăng nhập hệ thống; chạy riêng và reboot sau khi cài.

## Nguồn và phiên bản theme

- MacTahoe GTK: commit `1e45e19` theo tài liệu cấu hình.
- MacTahoe icons: commit `839848b9` theo tài liệu cấu hình.
- Theme gốc có hướng dẫn và thông tin giấy phép bên trong từng thư mục `vendor/`.

Font SF Pro được đưa kèm trong repo. Hãy kiểm tra điều khoản giấy phép trước khi phân phối lại.
