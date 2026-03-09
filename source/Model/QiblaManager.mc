import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// ============================================================
// QiblaManager — вычисляет направление на Каабу
// ============================================================
module QiblaManager {

    const KAABA_LAT = 0.37396d;
    const KAABA_LON = 0.69474d;

    var _lat           as Double? = null;
    var _lon           as Double? = null;
    var _heading       as Float?  = null;  // сырой heading (рад)
    var _headingSmooth as Float?  = null;  // сглаженный heading (рад)
    var _gpsAccuracy   as Number  = -1;

    // ---- GPS ------------------------------------------------

    public function updateLocation(lat as Double, lon as Double, accuracy as Number) as Void {
        _lat = lat;
        _lon = lon;
        _gpsAccuracy = accuracy;
    }

    public function clearLocation(accuracy as Number) as Void {
        _lat = null;
        _lon = null;
        _gpsAccuracy = accuracy;
    }

    // ---- Компас с EMA-сглаживанием -------------------------
    // α=0.25: плавно, но без большой задержки

    public function updateHeading(heading as Float) as Void {
        _heading = heading;
        if (_headingSmooth == null) {
            _headingSmooth = heading;
            return;
        }
        var h    = _headingSmooth as Float;
        var diff = heading - h;
        // Кратчайший путь через 0/2π
        var twoPi = (2.0 * Math.PI).toFloat();
        while (diff >  Math.PI.toFloat()) { diff -= twoPi; }
        while (diff < -Math.PI.toFloat()) { diff += twoPi; }
        h += diff * 0.3f;
        while (h <  0.0f)   { h += twoPi; }
        while (h >= twoPi)  { h -= twoPi; }
        _headingSmooth = h;
    }

    // ---- Угол иконки на экране (градусы, 0=верх, по часовой) ----

    public function getScreenAngle() as Float? {
        if (_lat == null || _lon == null || _headingSmooth == null) {
            return null;
        }
        var bearing    = computeBearing(_lat as Double, _lon as Double);
        var headingDeg = (_headingSmooth as Float) * 180.0 / Math.PI;
        var angle      = (bearing - headingDeg).toFloat();
        while (angle <  0.0f)   { angle += 360.0f; }
        while (angle >= 360.0f) { angle -= 360.0f; }
        return angle;
    }

    // ---- Абсолютный bearing до Каабы (градусы) ---------------

    public function getBearingDegrees() as Float? {
        if (_lat == null || _lon == null) { return null; }
        return computeBearing(_lat as Double, _lon as Double).toFloat();
    }

    // ---- Метка компасного направления (N, NE, E … NW) --------

    public function getBearingLabel() as String {
        var b = getBearingDegrees();
        if (b == null) { return ""; }
        var dirs = ["N","NE","E","SE","S","SW","W","NW"];
        var idx  = (((b as Float) + 22.5f) / 45.0f).toNumber() % 8;
        return dirs[idx];
    }

    // ---- Great Circle bearing (градусы) ----------------------

    public function computeBearing(lat1 as Double, lon1 as Double) as Double {
        var dLon = KAABA_LON - lon1;
        var x    = Math.sin(dLon) * Math.cos(KAABA_LAT);
        var y    = Math.cos(lat1) * Math.sin(KAABA_LAT)
                   - Math.sin(lat1) * Math.cos(KAABA_LAT) * Math.cos(dLon);
        var b    = Math.atan2(x, y) * 180.0 / Math.PI;
        if (b < 0.0d) { b += 360.0d; }
        return b;
    }

}
