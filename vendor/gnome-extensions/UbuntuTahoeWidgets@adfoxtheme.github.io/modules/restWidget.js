import St from 'gi://St';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import * as Drawing from './drawing.js';

function readUptimeSeconds() {
    try {
        const [ok, bytes] = GLib.file_get_contents('/proc/uptime');
        if (ok) {
            const raw = new TextDecoder('utf-8').decode(bytes);
            return parseFloat(raw.split(' ')[0]) || 0;
        }
    } catch (e) {
        // ignore
    }
    return 0;
}

function formatClockText(seconds) {
    seconds = Math.max(0, Math.floor(seconds));
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

export const RestWidget = GObject.registerClass(
class RestWidget extends St.DrawingArea {
    _init() {
        super._init({
            width: 340,
            height: 165,
            reactive: true,
            track_hover: true,
        });

        this.connect('repaint', this._onRepaint.bind(this));

        // 1-second timer to update progress bar and rest countdown
        this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this.queue_repaint();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _onRepaint(area) {
        const cr = area.get_context();
        const width = 340;
        const height = 165;

        const uptime = readUptimeSeconds();
        const cycle = Math.floor(uptime) % 3300;
        const onBreak = cycle >= 3000;

        let accent, top, bottom;
        if (onBreak) {
            accent = Drawing.COLORS.green;
            top = [0.08, 0.34, 0.28, 0.97];
            bottom = [0.045, 0.15, 0.16, 0.98];
        } else if (cycle >= 2700) {
            accent = Drawing.COLORS.orange;
            top = [0.39, 0.20, 0.10, 0.97];
            bottom = [0.17, 0.09, 0.08, 0.98];
        } else if (cycle >= 2100) {
            accent = Drawing.COLORS.gold;
            top = [0.34, 0.27, 0.10, 0.97];
            bottom = [0.15, 0.12, 0.07, 0.98];
        } else {
            accent = Drawing.COLORS.cyan;
            top = [0.10, 0.25, 0.38, 0.97];
            bottom = [0.055, 0.10, 0.18, 0.98];
        }

        // Card background
        Drawing.drawCard(cr, 0, 0, width, height, 24, top, bottom, 0.22);

        // Watermark clock in top right
        Drawing.drawRestClockWatermark(cr, width - 40, 42, 30);

        // Uptime label
        const days = Math.floor(uptime / 86400);
        const hours = Math.floor(uptime / 3600) % 24;
        const minutes = Math.floor(uptime / 60) % 60;
        let uptimeLabel;
        if (days > 0) {
            uptimeLabel = `${days} ngày ${hours}h`;
        } else if (hours > 0) {
            uptimeLabel = `${hours}h ${String(minutes).padStart(2, '0')}m`;
        } else {
            uptimeLabel = `${minutes} phút`;
        }

        // Header: 'Nhắc nghỉ'
        Drawing.drawText(cr, 22, 29, 'Nhắc nghỉ', 14, Drawing.COLORS.sysText, true, 'left', 'SF Pro Display');
        Drawing.drawText(cr, 22, 64, uptimeLabel, 25, accent, true, 'left', 'SF Pro Display');
        Drawing.drawText(cr, 22, 83, 'Máy hoạt động', 8.5, Drawing.COLORS.sysSub, false);

        let progress, status, hint;
        if (onBreak) {
            const remaining = 3300 - cycle;
            progress = ((cycle - 3000) / 300) * 100;
            status = `Nghỉ ngắn · còn ${formatClockText(remaining)}`;
            hint = 'Đi lại nhẹ nhàng, rời màn hình.';
        } else {
            const remaining = 3000 - cycle;
            progress = (cycle / 3000) * 100;
            status = `Còn ${formatClockText(remaining)} đến giờ nghỉ`;
            hint = cycle >= 2700
                ? 'Sắp đến lúc đứng dậy, vươn vai.'
                : 'Đổi tư thế, chớp mắt và nhìn xa.';
        }

        // Progress bar
        Drawing.drawProgressBar(cr, 22, 96, width - 44, 7, progress, accent);

        Drawing.drawText(cr, 22, 120, status, 9.2, Drawing.COLORS.sysText, true);
        Drawing.drawText(cr, 22, 139, hint, 8.5, Drawing.COLORS.sysSub, false);
    }

    destroy() {
        if (this._timerId) {
            GLib.source_remove(this._timerId);
            this._timerId = null;
        }
        super.destroy();
    }
});
