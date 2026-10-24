-- Widget MacTahoe cho Conky (Cairo)
-- Hai cửa sổ dùng chung file này: conky_weather() và conky_system().

require 'cairo'
require 'cairo_xlib'

local WEATHER_STATE = os.getenv('HOME') .. '/.cache/mactahoe-widgets/weather.state'
local LUNAR_STATE = os.getenv('HOME') .. '/.cache/mactahoe-widgets/lunar.state'
local THERMAL = '/sys/class/thermal/thermal_zone0/temp'

local C = {
    white = {1.00, 1.00, 1.00, 1.00},
    weather_sub = {0.84, 0.91, 1.00, 0.88},
    weather_muted = {0.72, 0.83, 0.98, 0.70},
    sys_text = {0.96, 0.97, 1.00, 1.00},
    sys_sub = {0.66, 0.70, 0.78, 0.90},
    sys_muted = {0.56, 0.60, 0.68, 0.80},
    blue = {0.30, 0.64, 1.00, 1.00},
    green = {0.19, 0.82, 0.35, 1.00},
    purple = {0.75, 0.35, 0.95, 1.00},
    orange = {1.00, 0.62, 0.04, 1.00},
    cyan = {0.25, 0.78, 0.92, 1.00},
    gold = {1.00, 0.84, 0.30, 1.00},
}

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function rounded_path(cr, x, y, w, h, r)
    r = math.min(r, w / 2, h / 2)
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)
    cairo_arc(cr, x + r, y + r, r, math.pi, 3 * math.pi / 2)
    cairo_close_path(cr)
end

local function card(cr, x, y, w, h, r, top, bottom, border)
    local pattern = cairo_pattern_create_linear(x, y, x, y + h)
    cairo_pattern_add_color_stop_rgba(
        pattern, 0, top[1], top[2], top[3], (top[4] or 1) * 0.96
    )
    cairo_pattern_add_color_stop_rgba(
        pattern, 1, bottom[1], bottom[2], bottom[3], (bottom[4] or 1) * 0.96
    )
    cairo_set_source(cr, pattern)
    rounded_path(cr, x, y, w, h, r)
    cairo_fill(cr)
    cairo_pattern_destroy(pattern)

    -- Lớp phản quang mỏng ở mép trên, như ánh sáng lướt trên kính.
    cairo_save(cr)
    rounded_path(cr, x, y, w, h, r)
    cairo_clip(cr)
    local sheen = cairo_pattern_create_linear(x, y, x, y + h * 0.62)
    cairo_pattern_add_color_stop_rgba(sheen, 0, 1, 1, 1, 0.13)
    cairo_pattern_add_color_stop_rgba(sheen, 1, 1, 1, 1, 0)
    cairo_set_source(cr, sheen)
    cairo_paint(cr)
    cairo_pattern_destroy(sheen)
    cairo_restore(cr)

    if border then
        -- Viền mảnh, pha sáng từ màu riêng của từng widget để hòa với nền.
        local edge_alpha = math.min(0.24, border + 0.06)
        cairo_set_source_rgba(
            cr,
            top[1] * 0.45 + 0.55,
            top[2] * 0.45 + 0.55,
            top[3] * 0.45 + 0.55,
            edge_alpha
        )
        cairo_set_line_width(cr, 1)
        rounded_path(cr, x + 0.5, y + 0.5, w - 1, h - 1, r - 0.5)
        cairo_stroke(cr)
    end
end

local function text_width(value, size, bold)
    -- Conky 1.22's cairo_text_extents() binding segfaults, nên ước lượng width.
    local units = 0
    for char in value:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        if char == ' ' or char == '.' or char == ',' or char == ':' or char == '•' then
            units = units + 0.30
        else
            units = units + 0.56
        end
    end
    return units * size * (bold and 1.03 or 1.0)
end

local function text(cr, x, y, value, size, color, bold, align, family)
    if value == nil or value == '' then return end
    cairo_select_font_face(
        cr,
        family or 'SF Pro Text',
        CAIRO_FONT_SLANT_NORMAL,
        bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    )
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, color[1], color[2], color[3], color[4] or 1)
    if align == 'right' then
        x = x - text_width(value, size, bold)
    elseif align == 'center' then
        x = x - text_width(value, size, bold) / 2
    end
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, value)
end

local function glass_text(cr, x, y, value, size, family)
    cairo_save(cr)
    cairo_select_font_face(cr, family, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)

    cairo_move_to(cr, x, y)
    cairo_text_path(cr, value)
    local gradient = cairo_pattern_create_linear(x, y - size * 0.82, x, y + size * 0.08)
    cairo_pattern_add_color_stop_rgba(gradient, 0, 1.00, 1.00, 1.00, 0.48)
    cairo_pattern_add_color_stop_rgba(gradient, 0.52, 1.00, 1.00, 1.00, 0.34)
    cairo_pattern_add_color_stop_rgba(gradient, 1, 1.00, 1.00, 1.00, 0.20)
    cairo_set_source(cr, gradient)
    cairo_fill_preserve(cr)
    cairo_pattern_destroy(gradient)

    cairo_set_source_rgba(cr, 1.00, 1.00, 1.00, 0.86)
    cairo_set_line_width(cr, 1.2)
    cairo_stroke(cr)
    cairo_restore(cr)
end

local function read_state(path)
    local state = {}
    local file = io.open(path or WEATHER_STATE, 'r')
    if not file then return state end
    for line in file:lines() do
        local key, value = line:match('^([^=]+)=(.*)$')
        if key then state[key] = value end
    end
    file:close()
    return state
end

local function image(cr, path, x, y, size)
    if path == nil or path == '' then return end
    local surface = cairo_image_surface_create_from_png(path)
    local status = cairo_surface_status(surface)
    if status ~= CAIRO_STATUS_SUCCESS then
        cairo_surface_destroy(surface)
        return
    end
    local width = cairo_image_surface_get_width(surface)
    local height = cairo_image_surface_get_height(surface)
    if width <= 0 or height <= 0 then
        cairo_surface_destroy(surface)
        return
    end
    cairo_save(cr)
    cairo_translate(cr, x, y)
    cairo_scale(cr, size / width, size / height)
    cairo_set_source_surface(cr, surface, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
    cairo_surface_destroy(surface)
end

local function bar(cr, x, y, w, h, percent, color)
    percent = clamp(tonumber(percent) or 0, 0, 100)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.11)
    rounded_path(cr, x, y, w, h, h / 2)
    cairo_fill(cr)
    if percent <= 0 then return end
    local fill_width = math.max(h, w * percent / 100)
    cairo_set_source_rgba(cr, color[1], color[2], color[3], color[4] or 1)
    rounded_path(cr, x, y, fill_width, h, h / 2)
    cairo_fill(cr)
end

local function clean(value)
    if value == nil then return '' end
    return (value:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function conky_value(variable)
    return clean(conky_parse(variable))
end

local function number(value)
    return tonumber(value) or 0
end

local function celsius_from_thermal()
    local file = io.open(THERMAL, 'r')
    if not file then return nil end
    local raw = file:read('*l')
    file:close()
    local value = tonumber(raw)
    if not value then return nil end
    return math.floor(value / 1000 + 0.5)
end

local function gpu_values()
    local raw = conky_value(
        '${execi 5 nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits}'
    )
    local util, used, total, temp = raw:match(
        '(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)'
    )
    return {
        util = tonumber(util),
        used = tonumber(used),
        total = tonumber(total),
        temp = tonumber(temp),
    }
end

local function speed_text(value)
    local speed = tonumber(value) or 0
    if speed >= 1024 then
        return string.format('%.1f MB/s', speed / 1024)
    end
    return string.format('%.0f KB/s', speed)
end

local function draw_weather(cr, width, height)
    card(
        cr, 10, 8, width - 20, height - 18, 26,
        {0.10, 0.30, 0.62, 0.97},
        {0.34, 0.63, 0.96, 0.97},
        0.20
    )

    -- Vòng sáng nhẹ sau icon
    cairo_set_source_rgba(cr, 1, 1, 1, 0.07)
    cairo_arc(cr, width - 82, 72, 52, 0, 2 * math.pi)
    cairo_fill(cr)

    local state = read_state()
    local temp = state.temp or '--'
    local high = state.high or '--'
    local low = state.low or '--'
    local feels = state.feels or '--'
    local humidity = state.humidity or '--'
    local wind = state.wind or '--'

    text(cr, 32, 41, state.city or 'Hà Nội', 14, C.white, true, 'left', 'SF Pro Display')
    text(cr, 32, 58, state.date or '', 9, C.weather_sub, false, 'left')

    text(cr, 32, 119, temp .. '°', 52, C.white, true, 'left', 'SF Pro Display')
    text(cr, 32, 140, state.condition or 'Đang tải…', 11.5, C.weather_sub, false)

    text(
        cr, 32, 162,
        'H:' .. high .. '°    L:' .. low .. '°',
        10, C.weather_sub, false
    )
    text(
        cr, 32, 182,
        'Cảm giác ' .. feels .. '°   •   Độ ẩm ' .. humidity .. '%   •   Gió ' .. wind .. ' km/h',
        8.2, C.weather_muted, false
    )

    image(cr, state.icon, width - 132, 24, 96)
end

local function system_icon(cr, kind, x, y, color)
    -- Uniform scaling keeps the metric icons compact and centered.
    cairo_save(cr)
    cairo_translate(cr, x, y)
    cairo_scale(cr, 0.80, 0.80)
    cairo_translate(cr, -x, -y)
    cairo_set_source_rgba(cr, color[1], color[2], color[3], 0.13)
    cairo_arc(cr, x + 9, y + 8, 8.5, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_set_source_rgba(cr, color[1], color[2], color[3], 0.95)
    cairo_set_line_width(cr, 1.4)
    rounded_path(cr, x + 3, y + 2, 12, 12, 2)
    cairo_stroke(cr)

    if kind == 'cpu' then
        rounded_path(cr, x + 7, y + 6, 4, 4, 1)
        cairo_stroke(cr)
        for offset = 0, 2 do
            local pin = x + 6 + offset * 3
            cairo_move_to(cr, pin, y + 1)
            cairo_line_to(cr, pin, y + 3)
            cairo_move_to(cr, pin, y + 13)
            cairo_line_to(cr, pin, y + 15)
        end
        cairo_stroke(cr)
    elseif kind == 'gpu' then
        cairo_arc(cr, x + 6, y + 8.5, 2.2, 0, 2 * math.pi)
        cairo_stroke(cr)
        cairo_move_to(cr, x + 10, y + 7)
        cairo_line_to(cr, x + 13, y + 7)
        cairo_move_to(cr, x + 10, y + 10)
        cairo_line_to(cr, x + 13, y + 10)
        cairo_move_to(cr, x + 5, y + 14)
        cairo_line_to(cr, x + 5, y + 15)
        cairo_stroke(cr)
    elseif kind == 'ram' then
        cairo_move_to(cr, x + 5, y + 6)
        cairo_line_to(cr, x + 13, y + 6)
        cairo_move_to(cr, x + 5, y + 10)
        cairo_line_to(cr, x + 13, y + 10)
        for pin = 0, 3 do
            local pin_x = x + 6 + pin * 2
            cairo_move_to(cr, pin_x, y + 6)
            cairo_line_to(cr, pin_x, y + 5)
            cairo_move_to(cr, pin_x, y + 10)
            cairo_line_to(cr, pin_x, y + 11)
        end
        cairo_stroke(cr)
    elseif kind == 'ssd' then
        cairo_arc(cr, x + 5, y + 8, 1.5, 0, 2 * math.pi)
        cairo_fill(cr)
        cairo_move_to(cr, x + 9, y + 6)
        cairo_line_to(cr, x + 13, y + 6)
        cairo_move_to(cr, x + 9, y + 8)
        cairo_line_to(cr, x + 13, y + 8)
        cairo_move_to(cr, x + 9, y + 10)
        cairo_line_to(cr, x + 13, y + 10)
        cairo_stroke(cr)
    elseif kind == 'network' then
        cairo_move_to(cr, x + 6, y + 6)
        cairo_line_to(cr, x + 12, y + 6)
        cairo_line_to(cr, x + 9, y + 12)
        cairo_line_to(cr, x + 6, y + 6)
        cairo_stroke(cr)
        cairo_arc(cr, x + 6, y + 6, 1.7, 0, 2 * math.pi)
        cairo_fill(cr)
        cairo_arc(cr, x + 12, y + 6, 1.7, 0, 2 * math.pi)
        cairo_fill(cr)
        cairo_arc(cr, x + 9, y + 12, 1.7, 0, 2 * math.pi)
        cairo_fill(cr)
    end
    cairo_restore(cr)
end

local function draw_system(cr, width, height)
    card(
        cr, 10, 8, width - 20, height - 18, 26,
        {0.13, 0.13, 0.16, 0.95},
        {0.065, 0.065, 0.085, 0.97},
        0.15
    )

    local uptime = conky_value('${uptime}')
    text(cr, 32, 41, 'Hệ thống', 14, C.sys_text, true, 'left', 'SF Pro Display')
    text(cr, width - 32, 41, uptime, 8.2, C.sys_muted, false, 'right')

    local cpu = number(conky_value('${cpu}'))
    local cpu_temp = celsius_from_thermal()
    local cpu_sub = 'Xeon E5-2680 v4'
    if cpu_temp then cpu_sub = cpu_sub .. '  •  ' .. cpu_temp .. '°C' end
    system_icon(cr, 'cpu', 32, 59, C.blue)
    text(cr, 54, 69, 'CPU', 9.5, C.sys_sub, false)
    text(cr, width - 32, 69, string.format('%.0f%%', cpu), 10, C.sys_text, true, 'right')
    bar(cr, 32, 77, width - 64, 6, cpu, C.blue)
    text(cr, 32, 94, cpu_sub, 8.0, C.sys_muted, false)

    local gpu = gpu_values()
    local gpu_util = gpu.util or 0
    local gpu_value = string.format('%.0f%%', gpu_util)
    local gpu_sub = 'GTX 960'
    if gpu.temp then gpu_value = gpu_value .. '  •  ' .. gpu.temp .. '°C' end
    if gpu.used and gpu.total then
        gpu_sub = gpu_sub .. string.format('  •  %d/%d MB', gpu.used, gpu.total)
    end
    system_icon(cr, 'gpu', 32, 101, C.green)
    text(cr, 54, 111, 'GPU', 9.5, C.sys_sub, false)
    text(cr, width - 32, 111, gpu_value, 10, C.sys_text, true, 'right')
    bar(cr, 32, 119, width - 64, 6, gpu_util, C.green)
    text(cr, 32, 136, gpu_sub, 8.0, C.sys_muted, false)

    local mem_percent = number(conky_value('${memperc}'))
    local mem = clean(conky_value('${mem}'))
    local mem_max = clean(conky_value('${memmax}'))
    local swap_percent = number(conky_value('${swapperc}'))
    system_icon(cr, 'ram', 32, 143, C.purple)
    text(cr, 54, 153, 'RAM', 9.5, C.sys_sub, false)
    text(cr, width - 32, 153, string.format('%.0f%%', mem_percent), 10, C.sys_text, true, 'right')
    bar(cr, 32, 161, width - 64, 6, mem_percent, C.purple)
    text(
        cr, 32, 178,
        mem .. ' / ' .. mem_max .. '  •  Swap ' .. string.format('%.0f%%', swap_percent),
        8.0, C.sys_muted, false
    )

    local disk_percent = number(conky_value('${fs_used_perc /}'))
    local disk_used = clean(conky_value('${fs_used /}'))
    local disk_size = clean(conky_value('${fs_size /}'))
    system_icon(cr, 'ssd', 32, 185, C.orange)
    text(cr, 54, 195, 'SSD', 9.5, C.sys_sub, false)
    text(cr, width - 32, 195, string.format('%.0f%%', disk_percent), 10, C.sys_text, true, 'right')
    bar(cr, 32, 203, width - 64, 6, disk_percent, C.orange)
    text(cr, 32, 220, disk_used .. ' / ' .. disk_size, 8.0, C.sys_muted, false)

    cairo_set_source_rgba(cr, 1, 1, 1, 0.08)
    cairo_set_line_width(cr, 1)
    cairo_move_to(cr, 32, 234)
    cairo_line_to(cr, width - 32, 234)
    cairo_stroke(cr)

    local down = speed_text(conky_value('${downspeedf enp6s0}'))
    local up = speed_text(conky_value('${upspeedf enp6s0}'))
    local ip = conky_value('${addr enp6s0}')
    system_icon(cr, 'network', 32, 243, C.cyan)
    text(cr, 54, 253, 'Mạng', 9.5, C.sys_sub, false)
    text(
        cr, width - 32, 253,
        '↓ ' .. down .. '    ↑ ' .. up,
        9.0, C.sys_text, true, 'right'
    )
    text(
        cr, 32, 270,
        'enp6s0' .. (ip ~= '' and ('  •  ' .. ip) or ''),
        8.0, C.sys_muted, false
    )
end

local function draw_lunar(cr, width, height)
    card(
        cr, 10, 8, width - 20, height - 18, 24,
        {0.19, 0.14, 0.31, 0.97},
        {0.075, 0.065, 0.12, 0.98},
        0.16
    )

    -- Trăng lưỡi liềm watermark ở góc phải trên, cắt theo đường bo của card.
    cairo_save(cr)
    rounded_path(cr, 10, 8, width - 20, height - 18, 24)
    cairo_clip(cr)
    local moon_x, moon_y, moon_r = width - 40, 47, 30
    cairo_move_to(cr, moon_x + moon_r * 0.32, moon_y - moon_r * 0.92)
    cairo_curve_to(
        cr,
        moon_x - moon_r * 0.32, moon_y - moon_r * 1.02,
        moon_x - moon_r * 0.92, moon_y - moon_r * 0.48,
        moon_x - moon_r * 0.86, moon_y + moon_r * 0.08
    )
    cairo_curve_to(
        cr,
        moon_x - moon_r * 0.72, moon_y + moon_r * 0.88,
        moon_x + moon_r * 0.20, moon_y + moon_r * 1.04,
        moon_x + moon_r * 0.76, moon_y + moon_r * 0.50
    )
    cairo_curve_to(
        cr,
        moon_x + moon_r * 0.18, moon_y + moon_r * 0.72,
        moon_x - moon_r * 0.08, moon_y + moon_r * 0.10,
        moon_x + moon_r * 0.12, moon_y - moon_r * 0.38
    )
    cairo_curve_to(
        cr,
        moon_x + moon_r * 0.20, moon_y - moon_r * 0.62,
        moon_x + moon_r * 0.38, moon_y - moon_r * 0.78,
        moon_x + moon_r * 0.32, moon_y - moon_r * 0.92
    )
    cairo_close_path(cr)
    cairo_set_source_rgba(cr, 1, 0.84, 0.30, 0.11)
    cairo_fill(cr)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.16)
    cairo_arc(cr, width - 73, 78, 2.2, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_arc(cr, width - 116, 47, 1.6, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_restore(cr)

    local state = read_state(LUNAR_STATE)
    local solar_day = state.solar_day or '--'
    local solar_month = state.solar_month or '--'
    local solar_year = state.solar_year or '----'
    local weekday = state.weekday or ''
    local lunar_day = state.lunar_day or '--'
    local lunar_month = state.lunar_month or '--'
    local lunar_year = state.lunar_year_name or ''
    local lunar_leap = state.lunar_leap == '1'
    local lunar_month_label = 'Tháng ' .. lunar_month
    if lunar_leap then
        lunar_month_label = lunar_month_label .. ' nhuận'
    end
    local solar_date = string.format(
        '%02d/%02d/%s',
        tonumber(solar_day) or 0,
        tonumber(solar_month) or 0,
        solar_year
    )

    text(cr, 32, 37, 'Âm lịch', 14, C.sys_text, true, 'left', 'SF Pro Display')
    text(cr, width - 32, 37, 'Hôm nay', 8.5, C.sys_muted, false, 'right')

    -- Ngày Âm lịch là thông tin chính
    text(cr, 32, 95, lunar_day, 44, C.gold, true, 'left', 'SF Pro Display')
    text(
        cr, 104, 67,
        lunar_month_label .. ' · ' .. lunar_year,
        13, C.sys_text, true, 'left', 'SF Pro Display'
    )
    text(cr, 104, 86, 'Âm lịch hôm nay', 9, C.sys_sub, false)

    cairo_set_source_rgba(cr, 1, 1, 1, 0.10)
    cairo_set_line_width(cr, 1)
    cairo_move_to(cr, 32, 101)
    cairo_line_to(cr, width - 32, 101)
    cairo_stroke(cr)

    -- Dương lịch chỉ là dòng phụ
    text(cr, 32, 120, 'Dương lịch', 8.5, C.sys_muted, false)
    text(
        cr, 104, 120,
        solar_date .. '  ·  ' .. weekday,
        9.2, C.sys_sub, false
    )
end

local function read_uptime_seconds()
    local file = io.open('/proc/uptime', 'r')
    if not file then return 0 end
    local raw = file:read('*l')
    file:close()
    return tonumber(raw and raw:match('^(%d+%.?%d*)')) or 0
end

local function clock_text(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format('%02d:%02d', math.floor(seconds / 60), seconds % 60)
end

local function draw_rest(cr, width, height)
    local uptime = read_uptime_seconds()
    local cycle = math.floor(uptime) % 3300 -- 50 phút làm việc + 5 phút nghỉ gợi ý
    local on_break = cycle >= 3000
    local accent, top, bottom

    if on_break then
        accent = C.green
        top = {0.08, 0.34, 0.28, 0.97}
        bottom = {0.045, 0.15, 0.16, 0.98}
    elseif cycle >= 2700 then
        accent = C.orange
        top = {0.39, 0.20, 0.10, 0.97}
        bottom = {0.17, 0.09, 0.08, 0.98}
    elseif cycle >= 2100 then
        accent = C.gold
        top = {0.34, 0.27, 0.10, 0.97}
        bottom = {0.15, 0.12, 0.07, 0.98}
    else
        accent = C.cyan
        top = {0.10, 0.25, 0.38, 0.97}
        bottom = {0.055, 0.10, 0.18, 0.98}
    end

    card(cr, 10, 8, width - 20, height - 18, 24, top, bottom, 0.22)

    -- Đồng hồ watermark tràn qua góc trên phải, được cắt theo mép card.
    cairo_save(cr)
    rounded_path(cr, 10, 8, width - 20, height - 18, 24)
    cairo_clip(cr)
    local icon_x, icon_y, icon_r = width - 50, 50, 30
    cairo_set_source_rgba(cr, 1, 1, 1, 0.08)
    cairo_set_line_width(cr, 6)
    cairo_arc(cr, icon_x, icon_y, icon_r, 0, 2 * math.pi)
    cairo_stroke(cr)
    cairo_set_line_width(cr, 6.5)
    cairo_move_to(cr, icon_x, icon_y)
    cairo_line_to(cr, icon_x, icon_y - 16)
    cairo_move_to(cr, icon_x, icon_y)
    cairo_line_to(cr, icon_x + 12, icon_y + 8)
    cairo_stroke(cr)
    cairo_arc(cr, icon_x, icon_y, 3, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_restore(cr)

    local days = math.floor(uptime / 86400)
    local hours = math.floor(uptime / 3600) % 24
    local minutes = math.floor(uptime / 60) % 60
    local uptime_label
    if days > 0 then
        uptime_label = string.format('%d ngày %dh', days, hours)
    elseif hours > 0 then
        uptime_label = string.format('%dh %02dm', hours, minutes)
    else
        uptime_label = string.format('%d phút', minutes)
    end

    text(cr, 32, 37, 'Nhắc nghỉ', 14, C.sys_text, true, 'left', 'SF Pro Display')
    text(cr, 32, 72, uptime_label, 25, accent, true, 'left', 'SF Pro Display')
    text(cr, 32, 91, 'Máy hoạt động', 8.5, C.sys_sub, false)

    local progress
    local status
    local hint
    if on_break then
        local remaining = 3300 - cycle
        progress = (cycle - 3000) / 300 * 100
        status = 'Nghỉ ngắn · còn ' .. clock_text(remaining)
        hint = 'Đi lại nhẹ nhàng, rời màn hình.'
    else
        local remaining = 3000 - cycle
        progress = cycle / 3000 * 100
        status = 'Còn ' .. clock_text(remaining) .. ' đến giờ nghỉ'
        hint = cycle >= 2700 and 'Sắp đến lúc đứng dậy, vươn vai.'
            or 'Đổi tư thế, chớp mắt và nhìn xa.'
    end
    bar(cr, 32, 104, width - 64, 7, progress, accent)
    text(cr, 32, 128, status, 9.2, C.sys_text, true)
    text(cr, 32, 147, hint, 8.5, C.sys_sub, false)
end

local function draw_clock(cr)
    local hours = os.date('%H')
    local minutes = os.date('%M')
    local size = 220
    local x = 8
    local hours_width = text_width(hours, size, false)
    local colon_width = size * 0.30
    glass_text(cr, x, 238, hours, size, 'SF Pro Rounded')

    -- Hai chấm tròn sáng nhịp nhẹ theo từng giây.
    local colon_x = x + hours_width + colon_width / 2
    local seconds = tonumber(os.date('%S')) or 0
    local colon_alpha = seconds % 2 == 0 and 0.96 or 0.58
    cairo_set_source_rgba(cr, 0.96, 0.99, 1.00, colon_alpha)
    cairo_arc(cr, colon_x, 148, 9, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_arc(cr, colon_x, 198, 9, 0, 2 * math.pi)
    cairo_fill(cr)

    glass_text(cr, x + hours_width + colon_width, 238, minutes, size, 'SF Pro Rounded')
end

local function begin_draw()
    if conky_window == nil then return nil, nil end
    local surface = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(surface)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, 0, 0, 0, 0)
    cairo_paint(cr)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    return cr, surface
end

local function end_draw(cr, surface)
    if cr then cairo_destroy(cr) end
    if surface then cairo_surface_destroy(surface) end
end

function conky_weather()
    local cr, surface = begin_draw()
    if cr == nil then return end
    draw_weather(cr, conky_window.width, conky_window.height)
    end_draw(cr, surface)
end

function conky_system()
    local cr, surface = begin_draw()
    if cr == nil then return end
    draw_system(cr, conky_window.width, conky_window.height)
    end_draw(cr, surface)
end

function conky_lunar()
    local cr, surface = begin_draw()
    if cr == nil then return end
    draw_lunar(cr, conky_window.width, conky_window.height)
    end_draw(cr, surface)
end

function conky_rest()
    local cr, surface = begin_draw()
    if cr == nil then return end
    draw_rest(cr, conky_window.width, conky_window.height)
    end_draw(cr, surface)
end

function conky_clock()
    local cr, surface = begin_draw()
    if cr == nil then return end
    draw_clock(cr)
    end_draw(cr, surface)
end
