import St from 'gi://St';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import Clutter from 'gi://Clutter';
import * as Drawing from './drawing.js';
import { readSystemMetrics } from './systemMetrics.js';

export const SystemWidget = GObject.registerClass(
class SystemWidget extends St.DrawingArea {
    _init() {
        super._init({
            width: 340,
            height: 300,
            reactive: true,
            track_hover: true,
        });

        this._metrics = readSystemMetrics();

        this.connect('repaint', this._onRepaint.bind(this));

        // Click to open GNOME System Monitor
        this.connect('button-press-event', (actor, event) => {
            if (event.get_button() === 1) {
                try {
                    const app = Gio.AppInfo.create_from_commandline('gnome-system-monitor', null, Gio.AppInfoCreateFlags.NONE);
                    if (app) app.launch([], null);
                } catch (e) {
                    // ignore
                }
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        });

        // 2-second update interval for responsive resource graphs
        this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, () => {
            this._metrics = readSystemMetrics();
            this.queue_repaint();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _onRepaint(area) {
        const cr = area.get_context();
        const width = 340;
        const height = 300;
        const m = this._metrics;

        // Card Background
        Drawing.drawCard(
            cr, 0, 0, width, height, 26,
            [0.13, 0.13, 0.16, 0.95],
            [0.065, 0.065, 0.085, 0.97],
            0.15
        );

        // Header: 'Hệ thống' & Uptime
        Drawing.drawText(cr, 22, 33, 'Hệ thống', 14, Drawing.COLORS.sysText, true, 'left', 'SF Pro Display');
        Drawing.drawText(cr, width - 22, 33, m.uptime, 8.2, Drawing.COLORS.sysMuted, false, 'right');

        // 1. CPU
        const cpuSub = m.cpu.model + (m.cpu.temp !== null ? `  •  ${m.cpu.temp}°C` : '');
        Drawing.drawSystemIcon(cr, 'cpu', 22, 51, Drawing.COLORS.blue);
        Drawing.drawText(cr, 44, 61, 'CPU', 9.5, Drawing.COLORS.sysSub, false);
        Drawing.drawText(cr, width - 22, 61, `${m.cpu.percent}%`, 10, Drawing.COLORS.sysText, true, 'right');
        Drawing.drawProgressBar(cr, 22, 69, width - 44, 6, m.cpu.percent, Drawing.COLORS.blue);
        Drawing.drawText(cr, 22, 86, cpuSub, 8.0, Drawing.COLORS.sysMuted, false);

        // 2. GPU
        let gpuVal = `${m.gpu.util}%`;
        if (m.gpu.temp !== null) gpuVal += `  •  ${m.gpu.temp}°C`;
        let gpuSub = m.gpu.model || 'GPU';
        if (m.gpu.used && m.gpu.total) {
            gpuSub += `  •  ${m.gpu.used}/${m.gpu.total} MB`;
        }
        Drawing.drawSystemIcon(cr, 'gpu', 22, 93, Drawing.COLORS.green);
        Drawing.drawText(cr, 44, 103, 'GPU', 9.5, Drawing.COLORS.sysSub, false);
        Drawing.drawText(cr, width - 22, 103, gpuVal, 10, Drawing.COLORS.sysText, true, 'right');
        Drawing.drawProgressBar(cr, 22, 111, width - 44, 6, m.gpu.util, Drawing.COLORS.green);
        Drawing.drawText(cr, 22, 128, gpuSub, 8.0, Drawing.COLORS.sysMuted, false);

        // 3. RAM
        const ramSub = `${m.ram.text}  •  Swap ${m.ram.swapPercent}%`;
        Drawing.drawSystemIcon(cr, 'ram', 22, 135, Drawing.COLORS.purple);
        Drawing.drawText(cr, 44, 145, 'RAM', 9.5, Drawing.COLORS.sysSub, false);
        Drawing.drawText(cr, width - 22, 145, `${m.ram.percent}%`, 10, Drawing.COLORS.sysText, true, 'right');
        Drawing.drawProgressBar(cr, 22, 153, width - 44, 6, m.ram.percent, Drawing.COLORS.purple);
        Drawing.drawText(cr, 22, 170, ramSub, 8.0, Drawing.COLORS.sysMuted, false);

        // 4. SSD
        Drawing.drawSystemIcon(cr, 'ssd', 22, 177, Drawing.COLORS.orange);
        Drawing.drawText(cr, 44, 187, 'SSD', 9.5, Drawing.COLORS.sysSub, false);
        Drawing.drawText(cr, width - 22, 187, `${m.disk.percent}%`, 10, Drawing.COLORS.sysText, true, 'right');
        Drawing.drawProgressBar(cr, 22, 195, width - 44, 6, m.disk.percent, Drawing.COLORS.orange);
        Drawing.drawText(cr, 22, 212, m.disk.text, 8.0, Drawing.COLORS.sysMuted, false);

        // Separator
        cr.setSourceRGBA(1, 1, 1, 0.08);
        cr.setLineWidth(1);
        cr.moveTo(22, 226);
        cr.lineTo(width - 22, 226);
        cr.stroke();

        // 5. Network
        Drawing.drawSystemIcon(cr, 'network', 22, 235, Drawing.COLORS.cyan);
        Drawing.drawText(cr, 44, 245, 'Mạng', 9.5, Drawing.COLORS.sysSub, false);
        Drawing.drawText(cr, width - 22, 245, `↓ ${m.net.downText}    ↑ ${m.net.upText}`, 9.0, Drawing.COLORS.sysText, true, 'right');
        Drawing.drawText(cr, 22, 262, m.net.interface, 8.0, Drawing.COLORS.sysMuted, false);
    }

    destroy() {
        if (this._timerId) {
            GLib.source_remove(this._timerId);
            this._timerId = null;
        }
        super.destroy();
    }
});
