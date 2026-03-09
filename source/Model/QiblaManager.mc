import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// ============================================================
// QiblaManager — вычисляет направление на Каабу
//
// Алгоритм:
//   1. GPS даёт координаты пользователя (радианы)
//   2. Компас даёт heading (радианы, 0=север, по часовой)
//   3. bearing = Great Circle от пользователя до Каабы (градусы)
//   4. screenAngle = bearing - headingDeg → угол иконки на экране
//      (0=верх, по часовой стрелке)
// ============================================================
module QiblaManager {

    // Координаты Каабы в радианах
    // 21.4225°N → 0.37396 rad,  39.8262°E → 0.69474 rad
    const KAABA_LAT = 0.37396d;
    const KAABA_LON = 0.69474d;

    // Текущие данные (null = недоступно)
    var _lat     as Double? = null;
    var _lon     as Double? = null;
    var _heading as Float?  = null;  // радианы, 0=север

    // ---- Обновление от GPS ----------------------------------

    public function updateLocation(lat as Double, lon as Double) as Void {
        _lat = lat;
        _lon = lon;
        System.println("QiblaManager: GPS " + lat.toString() + ", " + lon.toString());
    }

    public function clearLocation() as Void {
        _lat = null;
        _lon = null;
    }

    // ---- Обновление от компаса ------------------------------

    public function updateHeading(heading as Float) as Void {
        _heading = heading;
    }

    // ---- Основной метод: угол иконки на экране (градусы) ----
    // Возвращает null если GPS или heading недоступны

    public function getScreenAngle() as Float? {
        if (_lat == null || _lon == null || _heading == null) {
            return null;
        }

        var bearing    = computeBearing(_lat as Double, _lon as Double);
        var headingDeg = (_heading as Float) * 180.0 / Math.PI;
        var angle      = (bearing - headingDeg).toFloat();

        // Нормализуем в 0..360
        while (angle < 0.0f)   { angle += 360.0f; }
        while (angle >= 360.0f) { angle -= 360.0f; }

        return angle;
    }

    // ---- Great Circle bearing (градусы, 0=север, по часовой) ----

    public function computeBearing(lat1 as Double, lon1 as Double) as Double {
        var lat2 = KAABA_LAT;
        var lon2 = KAABA_LON;
        var dLon = lon2 - lon1;

        var x = Math.sin(dLon) * Math.cos(lat2);
        var y = Math.cos(lat1) * Math.sin(lat2)
                - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);

        var bearing = Math.atan2(x, y) * 180.0 / Math.PI;
        if (bearing < 0.0d) { bearing += 360.0d; }
        return bearing;
    }

}
