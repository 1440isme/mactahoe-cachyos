// Vietnamese Lunar Calendar based on Ho Ngoc Duc algorithm (UTC+7)
const TIMEZONE = 7.0;
const SYNODIC_MONTH = 29.530588853;

const CAN = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];
const CHI = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];
const WEEKDAYS = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

function rad(deg) {
    return (deg * Math.PI) / 180.0;
}

function jdFromDate(day, month, year) {
    const a = Math.floor((14 - month) / 12);
    const y = year + 4800 - a;
    const m = month + 12 * a - 3;
    return (
        day +
        Math.floor((153 * m + 2) / 5) +
        365 * y +
        Math.floor(y / 4) -
        Math.floor(y / 100) +
        Math.floor(y / 400) -
        32045
    );
}

function dateFromJd(jd) {
    const a = jd + 32044;
    const b = Math.floor((4 * a + 3) / 146097);
    const c = a - Math.floor((146097 * b) / 4);
    const d = Math.floor((4 * c + 3) / 1461);
    const e = c - Math.floor((1461 * d) / 4);
    const m = Math.floor((5 * e + 2) / 153);
    const day = e - Math.floor((153 * m + 2) / 5) + 1;
    const month = m + 3 - 12 * Math.floor(m / 10);
    const year = 100 * b + d - 4800 + Math.floor(m / 10);
    return { year, month, day };
}

function newMoon(k) {
    const t = k / 1236.85;
    let jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t * t;
    jd1 -= 0.000000155 * t * t * t;
    jd1 += 0.00033 * Math.sin(rad(166.56 + 132.87 * t - 0.009173 * t * t));

    const m = 359.2242 + 29.10535608 * k - 0.0000333 * t * t - 0.00000347 * t * t * t;
    const mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t * t + 0.00001236 * t * t * t;
    const f = 21.2964 + 390.67050646 * k - 0.0016528 * t * t - 0.00000239 * t * t * t;

    let c1 = (0.1734 - 0.000393 * t) * Math.sin(rad(m));
    c1 += 0.0021 * Math.sin(rad(2 * m));
    c1 -= 0.4068 * Math.sin(rad(mpr));
    c1 += 0.0161 * Math.sin(rad(2 * mpr));
    c1 -= 0.0004 * Math.sin(rad(3 * mpr));
    c1 += 0.0104 * Math.sin(rad(2 * f));
    c1 -= 0.0051 * Math.sin(rad(m + mpr));
    c1 -= 0.0074 * Math.sin(rad(m - mpr));
    c1 += 0.0004 * Math.sin(rad(2 * f + m));
    c1 -= 0.0004 * Math.sin(rad(2 * f - m));
    c1 -= 0.0006 * Math.sin(rad(2 * f + mpr));
    c1 += 0.0010 * Math.sin(rad(2 * f - mpr));
    c1 += 0.0005 * Math.sin(rad(m + 2 * mpr));

    let deltat;
    if (t < -11) {
        deltat = 0.001 + 0.000839 * t + 0.0002261 * t * t;
        deltat -= 0.00000845 * t * t * t - 0.000000081 * t * t * t * t;
    } else {
        deltat = -0.000278 + 0.000265 * t + 0.000262 * t * t;
    }

    return jd1 + c1 - deltat;
}

function sunLongitudeDegrees(jd) {
    const t = (jd - 2451545.0) / 36525.0;
    const m = 357.52910 + 35999.05030 * t - 0.0001559 * t * t - 0.00000048 * t * t * t;
    const l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t * t;
    let dl = (1.914600 - 0.004817 * t - 0.000014 * t * t) * Math.sin(rad(m));
    dl += (0.019993 - 0.000101 * t) * Math.sin(rad(2 * m));
    dl += 0.000290 * Math.sin(rad(3 * m));
    let l = l0 + dl;
    l -= 360.0 * Math.floor(l / 360.0);
    return l;
}

function newMoonDay(k, timezone = TIMEZONE) {
    return Math.floor(newMoon(k) + 0.5 + timezone / 24.0);
}

function sunLongitudeTerm(day, timezone = TIMEZONE) {
    return Math.floor(sunLongitudeDegrees(day - 0.5 - timezone / 24.0) / 30.0);
}

function lunarMonth11(year, timezone = TIMEZONE) {
    const off = jdFromDate(31, 12, year) - 2415021;
    const k = Math.floor(off / SYNODIC_MONTH);
    let nm = newMoonDay(k, timezone);
    if (sunLongitudeTerm(nm, timezone) >= 9) {
        nm = newMoonDay(k - 1, timezone);
    }
    return nm;
}

function leapMonthOffset(a11, timezone = TIMEZONE) {
    const k = Math.floor((a11 - 2415021.076998695) / SYNODIC_MONTH + 0.5);
    let last = 0;
    let i = 1;
    let arc = sunLongitudeTerm(newMoonDay(k + i, timezone), timezone);
    while (arc !== last && i < 14) {
        last = arc;
        i += 1;
        arc = sunLongitudeTerm(newMoonDay(k + i, timezone), timezone);
    }
    return i - 1;
}

export function convertSolarToLunar(day, month, year, timezone = TIMEZONE) {
    const dayNumber = jdFromDate(day, month, year);
    const k = Math.floor((dayNumber - 2415021.076998695) / SYNODIC_MONTH);
    let monthStart = newMoonDay(k + 1, timezone);
    if (monthStart > dayNumber) {
        monthStart = newMoonDay(k, timezone);
    }

    let a11 = lunarMonth11(year, timezone);
    let b11 = a11;
    let lunarYear;
    if (a11 >= monthStart) {
        lunarYear = year;
        a11 = lunarMonth11(year - 1, timezone);
    } else {
        lunarYear = year + 1;
        b11 = lunarMonth11(year + 1, timezone);
    }

    const lunarDay = dayNumber - monthStart + 1;
    const diff = Math.floor((monthStart - a11) / 29);
    let leap = false;
    let lunarMonth = diff + 11;

    if (b11 - a11 > 365) {
        const leapMonthDiff = leapMonthOffset(a11, timezone);
        if (diff >= leapMonthDiff) {
            lunarMonth = diff + 10;
            if (diff === leapMonthDiff) {
                leap = true;
            }
        }
    }

    if (lunarMonth > 12) {
        lunarMonth -= 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
        lunarYear -= 1;
    }

    return { day: lunarDay, month: lunarMonth, year: lunarYear, leap };
}

export function canChiYear(lunarYear) {
    return CAN[(lunarYear - 4) % 10] + ' ' + CHI[(lunarYear - 4) % 12];
}

export function canChiMonth(lunarYear, lunarMonth) {
    const yearCan = (lunarYear - 4) % 10;
    const monthCan = (yearCan * 2 + lunarMonth + 1) % 10;
    const monthChi = (lunarMonth + 1) % 12;
    return CAN[monthCan] + ' ' + CHI[monthChi];
}

export function canChiDay(day, month, year) {
    const jd = jdFromDate(day, month, year);
    return CAN[(jd + 9) % 10] + ' ' + CHI[(jd + 1) % 12];
}

export function getTodayLunar() {
    const now = new Date();
    const solarDay = now.getDate();
    const solarMonth = now.getMonth() + 1;
    const solarYear = now.getFullYear();
    const weekday = WEEKDAYS[now.getDay()];

    const lunar = convertSolarToLunar(solarDay, solarMonth, solarYear);
    const yearName = canChiYear(lunar.year);
    const monthName = canChiMonth(lunar.year, lunar.month);
    const dayName = canChiDay(solarDay, solarMonth, solarYear);

    return {
        lunarDay: lunar.day,
        lunarMonth: lunar.month,
        lunarYear: lunar.year,
        lunarLeap: lunar.leap,
        yearName,
        monthName,
        dayName,
        solarDay,
        solarMonth,
        solarYear,
        weekday,
    };
}
