var rr = 180 / Math.PI; // degrees in a radian

function gmod(n, m) {

    // generalized modulo function (n mod m) also valid for negative values of n

    return ((n % m) + m) % m;
}

function cosd(x) {

    //  COSD  --  Cosine of an angle in degrees

    return Math.cos(gmod(x, 360) / rr);
}

function sind(x) {

    //  SIND  --  Sine of an angle in degrees

    return Math.sin(gmod(x, 360) / rr);
}

function acosd(x) {

    //  ACOSD  --  Inverse cosine with angle in degrees

    return rr * Math.acos(x);
}

function tjd_now() {

    // Computes the current Julian Day Number

    var today = new Date();
    var year = today.getUTCFullYear();
    var month = today.getUTCMonth();
    var day = today.getUTCDate();
    var hours = today.getUTCHours();
    var minutes = today.getUTCMinutes() + 1; // add 1 minute for an approximate correction to TAI
    var seconds = today.getUTCSeconds();

    m = month + 1;
    y = year;

    if (m < 3) {
        y -= 1;
        m += 12;
    }

    c = Math.floor(y / 100);
    jgc = c - Math.floor(c / 4) - 2;

    cjdn = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day - jgc - 1524;

    return cjdn + ((hours - 12) + (minutes + seconds / 60) / 60) / 24;
}

function moonpos(tjd) {

    // computes the lunar position and distance (including terms up to 0.02 degr)

    var t = (tjd - 2451545) / 36525;

    var lm0 = gmod(218.3164 + 481267.8812 * t, 360); // mean lunar longitude
    var ls0 = gmod(280.4665 + 36000.7698 * t, 360); // mean solar longitude

    var d = gmod(297.8502 + 445267.1114 * t, 360); // mean luni-solar elongation
    var f = gmod(93.2721 + 483202.0175 * t, 360); // argument of lunar latitude
    var ml = gmod(134.9634 + 477198.8675 * t, 360); // mean lunar anomaly
    var nl = gmod(125.0445 - 1934.1363 * t, 360);// lunar node
    var ms = gmod(357.5291 + 35999.0503 * t, 360); // mean solar anomaly

    var bmoon = 5.128 * sind(f) + 0.281 * sind(ml + f) + 0.278 * sind(ml - f) + 0.173 * sind(2 * d - f) + 0.055 * sind(2 * d - ml + f) + 0.046 * sind(2 * d - ml - f) + 0.033 * sind(2 * d + f);
    var lmoon = lm0 + 6.289 * sind(ml) + 1.274 * sind(2 * d - ml) + 0.658 * sind(2 * d) + 0.214 * sind(2 * ml) - 0.185 * sind(ms) - 0.114 * sind(2 * f) + 0.059 * sind(2 * d - 2 * ml)
        + 0.057 * sind(2 * d - ms - ml) + 0.053 * sind(2 * d + ml) + 0.046 * sind(2 * d - ms) - 0.041 * sind(ms - ml) - 0.035 * sind(d) - 0.030 * sind(ms + ml);
    var lsun = ls0 - 0.0057 + 1.915 * sind(ms) + 0.020 * sind(2 * ms) - 0.0048 * sind(nl);

    var rmoon = (385000.6 - 20905.4 * cosd(ml) - 3699.1 * cosd(2 * d - ml) - 2956.0 * cosd(2 * d) - 569.9 * cosd(2 * ml)) / 149597870;
    var rsun = 1.00014 - 0.01671 * cosd(ms) - 0.00014 * cosd(2 * ms);

    return new Array(lmoon, bmoon, rmoon, lsun, rsun);
}

function lunarphase(tjd) {

    var lunpos = new Array;

    lunpos = moonpos(tjd);

    var lmoon = lunpos[0];
    var bmoon = lunpos[1];
    var rmoon = lunpos[2];
    var lsun = lunpos[3];
    var rsun = lunpos[4];

    var elone = gmod(lmoon - lsun, 360); // luni-solar elongation (measured along the ecliptic)

    var xm = rmoon * cosd(bmoon) * cosd(lmoon);
    var ym = rmoon * cosd(bmoon) * sind(lmoon);
    var zm = rmoon * sind(bmoon);

    var xs = rsun * cosd(lsun);
    var ys = rsun * sind(lsun);

    var xms = xm - xs;
    var yms = ym - ys;
    var zms = zm;

    var rms = Math.sqrt(xms * xms + yms * yms + zms * zms);

    var phase = acosd((xm * xms + ym * yms + zm * zms) / (rmoon * rms));

    return new Array(elone, phase);
}

function moon_flum_now() {

    // computes the illuminated fraction of the lunar disk

    var mphase = new Array;

    mphase = lunarphase(tjd_now());

    var k = (1 + cosd(mphase[1])) / 2;

    k = Math.floor(1000 * k + 0.5); // round k to 3 decimal places

    if (k < 10) return "0.00" + k;
    if (k < 100) return "0.0" + k;
    if (k < 1000) return "0." + k;
    if (k = 1000) return "1.000";

}
