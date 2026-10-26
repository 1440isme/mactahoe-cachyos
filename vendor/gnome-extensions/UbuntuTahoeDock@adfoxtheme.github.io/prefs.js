import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';
import { ExtensionPreferences } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class UbuntuTahoeDockPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        const page = new Adw.PreferencesPage({
            title: 'Cài đặt UbuntuTahoe Dock',
            icon_name: 'preferences-desktop-display-symbolic',
        });
        window.add(page);

        const group = new Adw.PreferencesGroup({
            title: 'Kích thước Dock',
            description: 'Kéo thanh trượt qua lại để tùy chỉnh độ lớn biểu tượng trên thanh Dock',
        });
        page.add(group);

        const iconSizeRow = new Adw.ActionRow({
            title: 'Kích thước biểu tượng',
            subtitle: 'Mặc định chuẩn macOS Tahoe là 45px',
        });

        const scale = new Gtk.Scale({
            orientation: Gtk.Orientation.HORIZONTAL,
            adjustment: new Gtk.Adjustment({
                lower: 24,
                upper: 96,
                step_increment: 1,
                page_increment: 5,
                value: settings.get_int('dash-max-icon-size') || 45,
            }),
            digits: 0,
            draw_value: true,
            hexpand: true,
            valign: Gtk.Align.CENTER,
        });

        scale.set_size_request(240, -1);

        scale.connect('value-changed', () => {
            const val = Math.round(scale.get_value());
            if (settings.get_int('dash-max-icon-size') !== val) {
                settings.set_int('dash-max-icon-size', val);
            }
        });

        settings.connect('changed::dash-max-icon-size', () => {
            const val = settings.get_int('dash-max-icon-size');
            if (scale.get_value() !== val) {
                scale.set_value(val);
            }
        });

        iconSizeRow.add_suffix(scale);
        group.add(iconSizeRow);

        // Group 2: Màn hình hiển thị Dock (Multi-monitor)
        const monitorGroup = new Adw.PreferencesGroup({
            title: 'Màn hình hiển thị Dock',
            description: 'Tùy chọn hiển thị thanh Dock trên màn hình chính, màn hình phụ hoặc cả 2 màn hình',
        });
        page.add(monitorGroup);

        const multiMonitorRow = new Adw.SwitchRow({
            title: 'Hiển thị Dock trên tất cả màn hình (Multi-monitor)',
            subtitle: 'Bật để hiện thanh Dock trên cả màn hình chính và màn hình thứ 2',
        });
        settings.bind('multi-monitor', multiMonitorRow, 'active', Gio.SettingsBindFlags.DEFAULT);
        monitorGroup.add(multiMonitorRow);

        const monitorModel = new Gtk.StringList();
        monitorModel.append('Màn hình chính (Primary Monitor)'); // -1
        monitorModel.append('Màn hình 1');                        // 0
        monitorModel.append('Màn hình 2 (Second Monitor)');      // 1

        const dockMonitorRow = new Adw.ComboRow({
            title: 'Màn hình chỉ định (nếu không hiện tất cả)',
            subtitle: 'Chọn màn hình đặt Dock khi tắt chế độ hiện trên tất cả màn hình',
            model: monitorModel,
        });

        const curDockMon = settings.get_int('preferred-monitor');
        if (curDockMon === 0) dockMonitorRow.selected = 1;
        else if (curDockMon === 1) dockMonitorRow.selected = 2;
        else dockMonitorRow.selected = 0;

        dockMonitorRow.connect('notify::selected', () => {
            let val;
            switch (dockMonitorRow.selected) {
                case 1: val = 0; break;
                case 2: val = 1; break;
                default: val = -1; break;
            }
            settings.set_int('preferred-monitor', val);
        });
        monitorGroup.add(dockMonitorRow);

        const isolateRow = new Adw.SwitchRow({
            title: 'Tách biệt ứng dụng theo màn hình (Isolate Monitors)',
            subtitle: 'Chỉ hiển thị trên Dock các cửa sổ ứng dụng đang mở trên màn hình đó',
        });
        settings.bind('isolate-monitors', isolateRow, 'active', Gio.SettingsBindFlags.DEFAULT);
        monitorGroup.add(isolateRow);
    }
}
