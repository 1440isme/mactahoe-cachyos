// Cairo drawing helpers identical to MacTahoe Cairo Lua implementation
import cairo from 'gi://cairo';
import Pango from 'gi://Pango';
import PangoCairo from 'gi://PangoCairo';
import Rsvg from 'gi://Rsvg?version=2.0';

export const COLORS = {
    white: [1.00, 1.00, 1.00, 1.00],
    weatherSub: [0.84, 0.91, 1.00, 0.88],
    weatherMuted: [0.72, 0.83, 0.98, 0.70],
    sysText: [0.96, 0.97, 1.00, 1.00],
    sysSub: [0.66, 0.70, 0.78, 0.90],
    sysMuted: [0.56, 0.60, 0.68, 0.80],
    blue: [0.30, 0.64, 1.00, 1.00],
    green: [0.19, 0.82, 0.35, 1.00],
    purple: [0.75, 0.35, 0.95, 1.00],
    orange: [1.00, 0.62, 0.04, 1.00],
    cyan: [0.25, 0.78, 0.92, 1.00],
    gold: [1.00, 0.84, 0.30, 1.00],
};

export function roundedPath(cr, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    cr.newSubPath();
    cr.arc(x + w - r, y + r, r, -Math.PI / 2, 0);
    cr.arc(x + w - r, y + h - r, r, 0, Math.PI / 2);
    cr.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI);
    cr.arc(x + r, y + r, r, Math.PI, 3 * Math.PI / 2);
    cr.closePath();
}

export function drawCard(cr, x, y, w, h, r, top, bottom, border) {
    const pattern = new cairo.LinearGradient(x, y, x, y + h);
    pattern.addColorStopRGBA(0, top[0], top[1], top[2], (top[3] || 1) * 0.96);
    pattern.addColorStopRGBA(1, bottom[0], bottom[1], bottom[2], (bottom[3] || 1) * 0.96);
    cr.setSource(pattern);
    roundedPath(cr, x, y, w, h, r);
    cr.fill();

    // Top sheen reflection
    cr.save();
    roundedPath(cr, x, y, w, h, r);
    cr.clip();
    const sheen = new cairo.LinearGradient(x, y, x, y + h * 0.62);
    sheen.addColorStopRGBA(0, 1, 1, 1, 0.13);
    sheen.addColorStopRGBA(1, 1, 1, 1, 0);
    cr.setSource(sheen);
    cr.paint();
    cr.restore();

    if (border) {
        const edgeAlpha = Math.min(0.24, border + 0.06);
        cr.setSourceRGBA(
            top[0] * 0.45 + 0.55,
            top[1] * 0.45 + 0.55,
            top[2] * 0.45 + 0.55,
            edgeAlpha
        );
        cr.setLineWidth(1);
        roundedPath(cr, x + 0.5, y + 0.5, w - 1, h - 1, r - 0.5);
        cr.stroke();
    }
}

export function drawText(cr, x, y, str, size, color, bold = false, align = 'left', family = 'SF Pro Text') {
    if (!str) return;
    cr.save();
    const layout = PangoCairo.create_layout(cr);
    const desc = Pango.FontDescription.from_string(`${family} ${bold ? 'Bold' : ''} ${size}px`);
    layout.set_font_description(desc);
    layout.set_text(String(str), -1);

    const [pWidth, pHeight] = layout.get_pixel_size();
    let drawX = x;
    if (align === 'right') {
        drawX = x - pWidth;
    } else if (align === 'center') {
        drawX = x - pWidth / 2;
    }

    cr.setSourceRGBA(color[0], color[1], color[2], color[3] !== undefined ? color[3] : 1.0);
    cr.moveTo(drawX, y - pHeight * 0.8);
    PangoCairo.show_layout(cr, layout);
    cr.restore();
}

export function drawGlassText(cr, x, y, str, size, family = 'SF Pro Rounded', weight = 'Semibold') {
    if (!str) return;
    cr.save();
    const layout = PangoCairo.create_layout(cr);
    const desc = Pango.FontDescription.from_string(`${family} ${weight} ${size}px`);
    layout.set_font_description(desc);
    layout.set_text(String(str), -1);

    const baseline = layout.get_baseline() / Pango.SCALE;
    const [pWidth, pHeight] = layout.get_pixel_size();
    const drawY = y - baseline;

    // Fill with glass gradient: bên trên trắng nhẹ (0.48), bên dưới trong luôn (0.00)
    cr.moveTo(x, drawY);
    PangoCairo.layout_path(cr, layout);

    const gradient = new cairo.LinearGradient(x, drawY, x, drawY + pHeight);
    gradient.addColorStopRGBA(0.00, 1.00, 1.00, 1.00, 0.48);
    gradient.addColorStopRGBA(0.50, 1.00, 1.00, 1.00, 0.18);
    gradient.addColorStopRGBA(1.00, 1.00, 1.00, 1.00, 0.00);
    cr.setSource(gradient);
    cr.fillPreserve();

    // Outline stroke: đường viền trong hơn 1 chút (0.65)
    cr.setSourceRGBA(1.00, 1.00, 1.00, 0.65);
    cr.setLineWidth(1.1);
    cr.stroke();
    cr.restore();
}

export function drawProgressBar(cr, x, y, w, h, percent, color) {
    percent = Math.max(0, Math.min(100, Number(percent) || 0));
    cr.setSourceRGBA(1, 1, 1, 0.11);
    roundedPath(cr, x, y, w, h, h / 2);
    cr.fill();
    if (percent <= 0) return;
    const fillWidth = Math.max(h, (w * percent) / 100);
    cr.setSourceRGBA(color[0], color[1], color[2], color[3] !== undefined ? color[3] : 1);
    roundedPath(cr, x, y, fillWidth, h, h / 2);
    cr.fill();
}

export function drawSystemIcon(cr, kind, x, y, color) {
    cr.save();
    cr.translate(x, y);
    cr.scale(0.80, 0.80);
    cr.translate(-x, -y);

    cr.setSourceRGBA(color[0], color[1], color[2], 0.13);
    cr.arc(x + 9, y + 8, 8.5, 0, 2 * Math.PI);
    cr.fill();

    cr.setSourceRGBA(color[0], color[1], color[2], 0.95);
    cr.setLineWidth(1.4);
    roundedPath(cr, x + 3, y + 2, 12, 12, 2);
    cr.stroke();

    if (kind === 'cpu') {
        roundedPath(cr, x + 7, y + 6, 4, 4, 1);
        cr.stroke();
        for (let offset = 0; offset <= 2; offset++) {
            const pin = x + 6 + offset * 3;
            cr.moveTo(pin, y + 1);
            cr.lineTo(pin, y + 3);
            cr.moveTo(pin, y + 13);
            cr.lineTo(pin, y + 15);
        }
        cr.stroke();
    } else if (kind === 'gpu') {
        cr.arc(x + 6, y + 8.5, 2.2, 0, 2 * Math.PI);
        cr.stroke();
        cr.moveTo(x + 10, y + 7);
        cr.lineTo(x + 13, y + 7);
        cr.moveTo(x + 10, y + 10);
        cr.lineTo(x + 13, y + 10);
        cr.moveTo(x + 5, y + 14);
        cr.lineTo(x + 5, y + 15);
        cr.stroke();
    } else if (kind === 'ram') {
        cr.moveTo(x + 5, y + 6);
        cr.lineTo(x + 13, y + 6);
        cr.moveTo(x + 5, y + 10);
        cr.lineTo(x + 13, y + 10);
        for (let pin = 0; pin <= 3; pin++) {
            const pinX = x + 6 + pin * 2;
            cr.moveTo(pinX, y + 6);
            cr.lineTo(pinX, y + 5);
            cr.moveTo(pinX, y + 10);
            cr.lineTo(pinX, y + 11);
        }
        cr.stroke();
    } else if (kind === 'ssd') {
        cr.arc(x + 5, y + 8, 1.5, 0, 2 * Math.PI);
        cr.fill();
        cr.moveTo(x + 9, y + 6);
        cr.lineTo(x + 13, y + 6);
        cr.moveTo(x + 9, y + 8);
        cr.lineTo(x + 13, y + 8);
        cr.moveTo(x + 9, y + 10);
        cr.lineTo(x + 13, y + 10);
        cr.stroke();
    } else if (kind === 'network') {
        cr.moveTo(x + 6, y + 6);
        cr.lineTo(x + 12, y + 6);
        cr.lineTo(x + 9, y + 12);
        cr.lineTo(x + 6, y + 6);
        cr.stroke();
        cr.arc(x + 6, y + 6, 1.7, 0, 2 * Math.PI);
        cr.fill();
        cr.arc(x + 12, y + 6, 1.7, 0, 2 * Math.PI);
        cr.fill();
        cr.arc(x + 9, y + 12, 1.7, 0, 2 * Math.PI);
        cr.fill();
    }
    cr.restore();
}

export function drawMoonWatermark(cr, x, y, r) {
    cr.save();
    cr.moveTo(x + r * 0.32, y - r * 0.92);
    cr.curveTo(
        x - r * 0.32, y - r * 1.02,
        x - r * 0.92, y - r * 0.48,
        x - r * 0.86, y + r * 0.08
    );
    cr.curveTo(
        x - r * 0.72, y + r * 0.88,
        x + r * 0.20, y + r * 1.04,
        x + r * 0.76, y + r * 0.50
    );
    cr.curveTo(
        x + r * 0.18, y + r * 0.72,
        x - r * 0.08, y + r * 0.10,
        x + r * 0.12, y - r * 0.38
    );
    cr.curveTo(
        x + r * 0.20, y - r * 0.62,
        x + r * 0.38, y - r * 0.78,
        x + r * 0.32, y - r * 0.92
    );
    cr.closePath();
    cr.setSourceRGBA(1, 0.84, 0.30, 0.11);
    cr.fill();

    cr.setSourceRGBA(1, 1, 1, 0.16);
    cr.arc(x - 33, y + 31, 2.2, 0, 2 * Math.PI);
    cr.fill();
    cr.arc(x - 76, y, 1.6, 0, 2 * Math.PI);
    cr.fill();
    cr.restore();
}

export function drawRestClockWatermark(cr, x, y, r) {
    cr.save();
    cr.setSourceRGBA(1, 1, 1, 0.08);
    cr.setLineWidth(6);
    cr.arc(x, y, r, 0, 2 * Math.PI);
    cr.stroke();

    cr.setLineWidth(6.5);
    cr.moveTo(x, y);
    cr.lineTo(x, y - 16);
    cr.moveTo(x, y);
    cr.lineTo(x + 12, y + 8);
    cr.stroke();

    cr.arc(x, y, 3, 0, 2 * Math.PI);
    cr.fill();
    cr.restore();
}

export function drawImage(cr, path, x, y, size) {
    if (!path) return;
    try {
        const handle = Rsvg.Handle.new_from_file(path);
        const dim = handle.get_dimensions();
        if (dim.width > 0 && dim.height > 0) {
            cr.save();
            cr.translate(x, y);
            cr.scale(size / dim.width, size / dim.height);
            handle.render_cairo(cr);
            cr.restore();
        }
    } catch (e) {
        // ignore
    }
}
