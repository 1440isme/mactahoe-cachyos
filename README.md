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
- `apps/`: trình quản lý icon MacTahoe, cùng mã nguồn và test cho **Âm lịch Việt Nam** (`apps/am-lich-viet-nam/`) và **Nén ảnh** (`apps/image-compressor/`).
- `desktop/`: launcher ứng dụng.
- `vendor/gnome-extensions/`: các tiện ích độc quyền gồm giao diện hợp nhất **UbuntuTahoe**, thanh dock macOS **UbuntuTahoeDock** (có sẵn icon Launchpad) và bộ widget desktop Native **UbuntuTahoeWidgets** (thay thế hoàn toàn Conky, tích hợp OpenWeather).
- `docs/extension-settings/current-gnome-extensions.md`: các extension đang bật và cấu hình Blur/My Shell, Global Menu trên máy.
- `docs/skin-tahoe-source.md`: hướng dẫn cấu hình ban đầu.
- `config/gsettings.tsv`: tùy chọn GNOME, dock và extension được áp dụng.
- `config/firefox-user.js`: tùy chọn cần cho CSS theme Firefox.

## Thành phần giao diện

- Theme GTK/GNOME Shell, bộ icon MacTahoe, con trỏ, font SF và wallpaper tạo phần giao diện nền.
- Topbar dùng kiểu trong suốt vĩnh viễn (`#panel` trong CSS); không cần bật blur để có nền trong suốt.
- Firefox bo góc 10 px khi cửa sổ ở trạng thái thường và bỏ bo góc khi phóng tối đa; CSS ghi đè bán kính CSD dự phòng của theme để hiển thị nhất quán hơn.
- **UbuntuTahoe** là tiện ích giao diện hợp nhất độc quyền cho bộ theme, tích hợp sẵn Global Menu, chuyển đồng hồ sang góc phải, hiệu ứng mờ kính Overview & thư mục ứng dụng và bộ gõ. Người dùng chỉ cần một công tắc bật duy nhất mà không cần cài đặt nhiều extension riêng rẽ.
- **UbuntuTahoeDock** là tiện ích Dock độc quyền chuẩn phong cách macOS Tahoe (nổi ở đáy màn hình, bo cong kính mờ, đèn báo 1 chấm tròn DOT, tự ẩn thông minh, có thanh trượt chỉnh kích thước icon). Nhờ có UbuntuTahoeDock, bộ giao diện hoàn toàn độc lập và không phụ thuộc vào Ubuntu Dock của hệ thống, tương thích mượt mà trên mọi bản phân phối Linux dùng GNOME.
- GNOME Tweaks và Extension Manager là ứng dụng quản lý tùy chọn/extension, không phải thành phần tạo giao diện. Trình quản lý icon MacTahoe, launcher widget, **Âm lịch Việt Nam** và **Nén ảnh** được đóng gói trong repo.
- Bộ cài cài hai ứng dụng vào menu GNOME, kèm icon và launcher; Âm lịch chạy offline, còn Nén ảnh xử lý tệp cục bộ bằng Pillow.
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

Nếu muốn màn hình đăng nhập (login) cũng đồng bộ giao diện Ubuntu Tahoe thì chạy tiếp lệnh dưới:

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

Bộ widget desktop được tích hợp trực tiếp qua tiện ích mở rộng **UbuntuTahoeWidgets**, hoàn toàn không cần cài đặt Conky hay chạy tiến trình nền bên ngoài. Người dùng có thể tùy chỉnh bật/tắt từng widget (Đồng hồ lớn, Thời tiết OpenWeather, Hệ thống, Âm lịch, Nhắc nghỉ), nhập API Key và căn lề ngay trong ứng dụng **Tiện ích mở rộng (Extension Manager)**.

### Sau khi cài

1. Chờ Terminal báo `Installed`, sau đó đăng xuất rồi đăng nhập lại để GNOME nạp theme và các extension. Sau khi cài riêng GDM bằng `install-gdm.sh`, khởi động lại máy.
2. Mở **Tiện ích mở rộng (Extension Manager)**, bật tiện ích **UbuntuTahoeWidgets** để hiển thị bộ widget desktop và vào phần Cài đặt để tùy chỉnh theo ý muốn.
3. Mở **Quản lý icon MacTahoe** trong danh sách ứng dụng để chọn icon riêng cho ứng dụng. Font, con trỏ, bộ icon/theme tổng thể và tiện ích **UbuntuTahoe**, **UbuntuTahoeDock** đã được tự động cài đặt và kích hoạt sẵn trọn bộ giao diện macOS Tahoe.
4. **Âm lịch Việt Nam** và **Nén ảnh** được cài thành ứng dụng riêng, có thể mở từ danh sách ứng dụng GNOME hoặc chạy `am-lich-viet-nam` và `image-compressor` trong Terminal.
5. Nếu không thấy thay đổi, kiểm tra Terminal đã hiện thông báo `Installed` chưa; nếu có, thử đăng xuất/đăng nhập lại một lần nữa.

### Tùy chỉnh Widget Desktop (UbuntuTahoeWidgets)

Toàn bộ widget desktop được quản lý tập trung và trực quan ngay trong phần Cài đặt của tiện ích mở rộng **UbuntuTahoeWidgets**:

- **Cách mở bảng tùy chỉnh:**
  - **Cách 1 (Giao diện):** Mở ứng dụng **Trình quản lý tiện ích (Extension Manager)** hoặc **Tiện ích (Extensions)** từ danh sách ứng dụng > tìm tiện ích **UbuntuTahoeWidgets** > bấm vào nút **Bánh răng (Cài đặt)**.
  - **Cách 2 (Terminal):** Mở Terminal và chạy lệnh:
    ```bash
    gnome-extensions prefs UbuntuTahoeWidgets@adfoxtheme.github.io
    ```

- **Các tính năng có thể tùy chỉnh:**
  - **Bật / Tắt từng widget:** Có công tắc bật/tắt độc lập cho từng widget:
    - *Đồng hồ lớn (Clock):* Đồng hồ số viền kính phong cách macOS Tahoe đặt bên trái.
    - *Thời tiết (Weather):* Thông tin thời tiết chi tiết, nhiệt độ, độ ẩm và gió.
    - *Giám sát hệ thống (System Metrics):* Trực quan hóa tải CPU, GPU, RAM, ổ cứng SSD và tốc độ mạng.
    - *Âm lịch Việt Nam (Lunar Calendar):* Lịch âm truyền thống Việt Nam.
    - *Nhắc nhở nghỉ ngơi (Rest Reminder):* Theo dõi thời gian làm việc và nhắc nhở nghỉ ngơi.
    *(Khi tắt một widget bên phải, các widget còn lại sẽ tự động dồn lên, không để lại khoảng trống trên màn hình).*
  - **Cấu hình thời tiết OpenWeather:**
    - Nhập **API Key OpenWeather** cá nhân (nếu để trống, tiện ích sẽ tự động dùng nguồn dữ liệu Open-Meteo miễn phí).
    - Đặt **Tên thành phố** (ví dụ: `Hà Nội`, `Hồ Chí Minh`, `Đà Nẵng`...).
    - Điều chỉnh chu kỳ làm mới dữ liệu (mặc định 15 phút).
  - **Căn chỉnh vị trí & lề màn hình:**
    - Tùy chỉnh khoảng cách lề trái và lề trên của Đồng hồ lớn.
    - Tùy chỉnh khoảng cách lề phải và lề trên của Cụm widget để vừa vặn hoàn hảo với mọi độ phân giải màn hình.

### Gỡ cài đặt

Để gỡ giao diện, tiện ích và khôi phục các file đã sao lưu (giữ lại thư mục repo để có thể cài lại), mở Terminal ở bất kỳ vị trí nào và chạy:

```bash
cd "$HOME/mactahoe-ubuntu" && ./uninstall.sh
```

Chạy bằng tài khoản thường, không thêm `sudo`; trình gỡ sẽ hỏi xác nhận trước khi khôi phục bản sao cấu hình GNOME. Nếu đã cài theme màn hình đăng nhập, lệnh này cũng sẽ yêu cầu mật khẩu sudo để khôi phục. Các gói hệ thống được giữ lại.

`install.sh` hỗ trợ Ubuntu và Debian 13 (GNOME 48 trở lên). `install-gdm.sh` hiện chỉ hỗ trợ Ubuntu (do cần theme Yaru của Ubuntu). Bộ cài GDM kiểm tra GDM3 đang có, cài các công cụ biên dịch/Yaru nếu thiếu, kiểm tra resource theme trước khi áp dụng giao diện Tahoe. Bước này thay đổi resource màn hình đăng nhập hệ thống; chạy riêng và reboot sau khi cài.

## Nguồn và phiên bản theme

- MacTahoe GTK: commit `1e45e19` theo tài liệu cấu hình.
- MacTahoe icons: commit `839848b9` theo tài liệu cấu hình.
- Theme gốc có hướng dẫn và thông tin giấy phép bên trong từng thư mục `vendor/`.

Font SF Pro được đưa kèm trong repo. Hãy kiểm tra điều khoản giấy phép trước khi phân phối lại.
