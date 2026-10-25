import St from 'gi://St';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Pango from 'gi://Pango';
import PangoCairo from 'gi://PangoCairo';
import * as Drawing from './drawing.js';

export const ClockWidget = GObject.registerClass(
class ClockWidget extends St.DrawingArea {
    _init() {
        super._init({
            width: 760,
            height: 300,
            reactive: true,
        });

        this.connect('repaint', this._onRepaint.bind(this));

        this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this.queue_repaint();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _onRepaint(area) {
        const cr = area.get_context();
        const now = new Date();
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = now.getSeconds();

        const size = 200;
        const startX = 10;
        const baselineY = 220;

        // Measure hours width using Pango
        const layout = PangoCairo.create_layout(cr);
        const desc = Pango.FontDescription.from_string(`SF Pro Rounded 600 ${size}px`);
        layout.set_font_description(desc);
        layout.set_text(hours, -1);
        const [hoursWidth] = layout.get_pixel_size();

        const colonWidth = Math.round(size * 0.32);

        // 1. Draw Hours
        Drawing.drawGlassText(cr, startX, baselineY, hours, size, 'SF Pro Rounded');

        // 2. Draw Colon Dots (proportional vertical spacing)
        const colonX = startX + hoursWidth + colonWidth / 2;
        const colonAlpha = (seconds % 2 === 0) ? 0.96 : 0.58;
        cr.setSourceRGBA(0.96, 0.99, 1.00, colonAlpha);

        // Upper dot (at ~38% of digit height)
        cr.arc(colonX, baselineY - 105, 9, 0, 2 * Math.PI);
        cr.fill();

        // Lower dot (at ~72% of digit height)
        cr.arc(colonX, baselineY - 35, 9, 0, 2 * Math.PI);
        cr.fill();

        // 3. Draw Minutes
        const minutesX = startX + hoursWidth + colonWidth;
        Drawing.drawGlassText(cr, minutesX, baselineY, minutes, size, 'SF Pro Rounded');
    }

    destroy() {
        if (this._timerId) {
            GLib.source_remove(this._timerId);
            this._timerId = null;
        }
        super.destroy();
    }
});
