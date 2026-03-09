import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Time;
import Toybox.Timer;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// TasbihApp — main application entry point
// ============================================================
class TasbihApp extends Application.AppBase {

    private var _sensorTimer as Timer.Timer?;

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
        checkDailyReset();

        // GPS → координаты для расчёта bearing до Каабы
        Position.enableLocationEvents(
            Position.LOCATION_CONTINUOUS,
            method(:onPosition)
        );

        // Компас — опрашиваем каждые 500 мс напрямую через Sensor.getInfo()
        _sensorTimer = new Timer.Timer();
        _sensorTimer.start(method(:onSensorTimer), 100, true);

        System.println("TasbihApp: started");
    }

    public function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        if (_sensorTimer != null) {
            (_sensorTimer as Timer.Timer).stop();
            _sensorTimer = null;
        }
        System.println("TasbihApp: stopped");
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var view     = new $.MainView();
        var delegate = new $.MainDelegate(view);
        return [view, delegate];
    }

    // ---- GPS callback ---------------------------------------

    public function onPosition(info as Position.Info) as Void {
        var acc = info.accuracy;
        if (acc >= Position.QUALITY_LAST_KNOWN) {
            var coords = info.position.toRadians();
            QiblaManager.updateLocation(coords[0] as Double, coords[1] as Double, acc);
        } else {
            QiblaManager.clearLocation(acc);
        }
        WatchUi.requestUpdate();
    }

    // ---- Sensor timer ---------------------------------------
    // Каждые 500мс: читаем heading и пробуем получить GPS

    public function onSensorTimer() as Void {
        // Компас
        var sInfo = Sensor.getInfo();
        if (sInfo.heading != null) {
            QiblaManager.updateHeading(sInfo.heading as Float);
        }

        // GPS — читаем последнюю известную позицию
        var pInfo = Position.getInfo();
        if (pInfo != null) {
            var acc = pInfo.accuracy;
            QiblaManager._gpsAccuracy = acc;
            if (acc >= Position.QUALITY_LAST_KNOWN) {
                var coords = pInfo.position.toRadians();
                QiblaManager.updateLocation(coords[0] as Double, coords[1] as Double, acc);
            } else {
                QiblaManager.clearLocation(acc);
            }
        }

        WatchUi.requestUpdate();
    }

    // ----------------------------------------------------------
    private function checkDailyReset() as Void {
        var today     = Time.today().value();
        var lastReset = Application.Storage.getValue("lastResetDate") as Number?;

        if (lastReset == null || lastReset != today) {
            Application.Storage.setValue("currentCount",  0);
            Application.Storage.setValue("lastResetDate", today);
            Application.Storage.setValue("goalAchieved",  false);
            Application.Storage.setValue("totalCount",    0);
            System.println("TasbihApp: daily auto-reset for " + today.toString());
        }

        if (Application.Storage.getValue("dailyGoal") == null) {
            Application.Storage.setValue("dailyGoal", 33);
        }
        if (Application.Storage.getValue("vibrationEnabled") == null) {
            Application.Storage.setValue("vibrationEnabled", true);
        }
    }

}
