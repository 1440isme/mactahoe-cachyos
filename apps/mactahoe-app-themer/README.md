# Giao diện ứng dụng (MacTahoe App Themer)

Ứng dụng đồ họa viết bằng Python + GTK4 / Libadwaita, dùng để áp dụng và đồng bộ giao diện macOS Tahoe cho các ứng dụng phổ biến như **Mozilla Firefox** và **Brave Browser**.

## Chức năng

- **Mozilla Firefox (Safari macOS Tahoe)**:
  - Tự động nhận diện mọi hồ sơ (profile) của Firefox trên máy bất kể cài qua **Snap** (Ubuntu), **Native** (APT/DNF/Pacman) hay **Flatpak**.
  - **Áp dụng**: Tự động cài đặt skin Safari Tahoe (nút tròn đỏ vàng xanh, thanh địa chỉ bo tròn giữa, thiết kế tab phẳng Safari) và kích hoạt cờ hỗ trợ CSS trong `user.js`.
  - **Khôi phục**: Đưa Firefox trở về giao diện mặc định ban đầu của Mozilla.

- **Brave Browser (Đồng bộ GTK & Con trỏ chuột macOS)**:
  - Tự động nhận diện cài đặt dạng **Snap** (Ubuntu), **Native** hoặc **Flatpak**.
  - **Áp dụng**: Đồng bộ bộ theme `MacTahoe-Dark`, con trỏ chuột và kích hoạt chế độ nạp GTK (`system_theme: 1`).
  - **Khôi phục**: Trả Brave về giao diện mặc định.

## Khởi chạy

```bash
cd "$HOME/mactahoe-ubuntu/apps/mactahoe-app-themer"
python3 main.py
```

Hoặc bấm biểu tượng **Giao diện ứng dụng** trong danh sách ứng dụng GNOME, hoặc chạy từ Terminal:

```bash
mactahoe-app-themer
```

## Cấu trúc

- `main.py` — Giao diện đồ họa chính chuẩn Libadwaita (`Adw.PreferencesWindow`).
- `themer_firefox.py` — Module quét hồ sơ và nạp skin Safari Tahoe cho Firefox.
- `themer_brave.py` — Module đồng bộ GTK theme và con trỏ cho Brave.
- `assets/firefox/` — Bộ mã nguồn CSS Safari Tahoe độc lập đi kèm.
- `assets/io.github.adfoxtheme.MacTahoeAppThemer.svg` — Biểu tượng ứng dụng.
