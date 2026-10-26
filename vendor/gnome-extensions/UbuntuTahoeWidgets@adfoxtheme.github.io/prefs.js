import { ExtensionPreferences } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';
import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';

export default class UbuntuTahoeWidgetsPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        const page = new Adw.PreferencesPage({
            title: 'Cài đặt Widget',
            icon_name: 'preferences-desktop-theme-symbolic',
        });
        window.add(page);

        // Group 1: Bật / Tắt từng Widget
        const widgetGroup = new Adw.PreferencesGroup({
            title: 'Bật / Tắt Widget',
            description: 'Tùy chỉnh các widget bạn muốn hiển thị trên màn hình desktop',
        });
        page.add(widgetGroup);

        const addSwitch = (title, subtitle, key) => {
            const row = new Adw.SwitchRow({
                title,
                subtitle,
            });
            settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
            widgetGroup.add(row);
        };

        addSwitch('Đồng hồ lớn', 'Hiển thị đồng hồ số kính mờ bên trái màn hình', 'show-clock');
        addSwitch('Thời tiết', 'Dự báo nhiệt độ và thời tiết với icon MacTahoe', 'show-weather');
        addSwitch('Hệ thống', 'Giám sát CPU, GPU, RAM, SSD và mạng', 'show-system');
        addSwitch('Âm lịch', 'Lịch âm Việt Nam và can chi hôm nay', 'show-lunar');
        addSwitch('Nhắc nghỉ', 'Theo dõi thời gian và nhắc nhở nghỉ ngơi', 'show-rest');

        // Group 2: Chọn màn hình hiển thị
        const monitorGroup = new Adw.PreferencesGroup({
            title: 'Màn hình hiển thị Widget',
            description: 'Tùy chọn hiển thị widget trên màn hình chính hoặc màn hình thứ 2',
        });
        page.add(monitorGroup);

        const monitorModel = new Gtk.StringList();
        monitorModel.append('Màn hình chính (Primary Monitor)'); // 0 -> -1
        monitorModel.append('Màn hình thứ hai (Second Monitor)'); // 1 -> 1
        monitorModel.append('Màn hình 1 (Monitor 0)');           // 2 -> 0
        monitorModel.append('Màn hình 2 (Monitor 1)');           // 3 -> 1
        monitorModel.append('Màn hình 3 (Monitor 2)');           // 4 -> 2

        const monitorRow = new Adw.ComboRow({
            title: 'Màn hình hiển thị',
            subtitle: 'Chọn màn hình đặt đồng hồ lớn và cụm widget',
            model: monitorModel,
        });

        const curTarget = settings.get_int('target-monitor');
        if (curTarget === -1) monitorRow.selected = 0;
        else if (curTarget === 1) monitorRow.selected = 1;
        else if (curTarget === 0) monitorRow.selected = 2;
        else if (curTarget === 2) monitorRow.selected = 4;
        else monitorRow.selected = 0;

        monitorRow.connect('notify::selected', () => {
            let val;
            switch (monitorRow.selected) {
                case 0: val = -1; break; // Primary
                case 1: val = 1; break;  // 2nd monitor
                case 2: val = 0; break;  // Monitor 0
                case 3: val = 1; break;  // Monitor 1
                case 4: val = 2; break;  // Monitor 2
                default: val = -1; break;
            }
            settings.set_int('target-monitor', val);
        });
        monitorGroup.add(monitorRow);

        // Group 3: Cấu hình thời tiết OpenWeather
        const weatherGroup = new Adw.PreferencesGroup({
            title: 'Thời tiết (OpenWeatherMap)',
            description: 'Cấu hình API OpenWeather (để trống sẽ dùng Open-Meteo miễn phí)',
        });
        page.add(weatherGroup);

        const apiKeyRow = new Adw.EntryRow({
            title: 'OpenWeather API Key',
            show_apply_button: true,
        });
        apiKeyRow.text = settings.get_string('weather-api-key');
        apiKeyRow.connect('apply', () => {
            settings.set_string('weather-api-key', apiKeyRow.text.trim());
        });
        weatherGroup.add(apiKeyRow);

        const cityRow = new Adw.EntryRow({
            title: 'Tên thành phố',
            show_apply_button: true,
        });
        cityRow.text = settings.get_string('weather-city');
        cityRow.connect('apply', () => {
            settings.set_string('weather-city', cityRow.text.trim());
        });
        weatherGroup.add(cityRow);

        const intervalRow = new Adw.SpinRow({
            title: 'Chu kỳ cập nhật (phút)',
            subtitle: 'Thời gian tự động làm mới dữ liệu thời tiết',
            adjustment: new Gtk.Adjustment({
                lower: 5,
                upper: 120,
                step_increment: 5,
                value: settings.get_int('weather-update-interval'),
            }),
        });
        settings.bind('weather-update-interval', intervalRow, 'value', Gio.SettingsBindFlags.DEFAULT);
        weatherGroup.add(intervalRow);

        // Group 3: Vị trí và Căn lề
        const posGroup = new Adw.PreferencesGroup({
            title: 'Vị trí và Căn lề',
            description: 'Khoảng cách hiển thị widget trên màn hình desktop',
        });
        page.add(posGroup);

        const addSpin = (title, key, lower, upper, step) => {
            const row = new Adw.SpinRow({
                title,
                adjustment: new Gtk.Adjustment({
                    lower,
                    upper,
                    step_increment: step,
                    value: settings.get_int(key),
                }),
            });
            settings.bind(key, row, 'value', Gio.SettingsBindFlags.DEFAULT);
            posGroup.add(row);
        };

        addSpin('Lề trái Đồng hồ (px)', 'clock-gap-x', 0, 500, 10);
        addSpin('Lề trên Đồng hồ (px)', 'clock-gap-y', 0, 500, 10);
        addSpin('Lề phải Cụm widget (px)', 'stack-gap-x', 0, 500, 10);
        addSpin('Lề trên Cụm widget (px)', 'stack-gap-y', 0, 500, 10);
    }
}
