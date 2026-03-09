import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Time;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// TasbihApp — main application entry point
// "entry" in manifest.xml must match this class name exactly
// ============================================================
class TasbihApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    // Called when the app is launched
    public function onStart(state as Dictionary?) as Void {
        checkDailyReset();

        // GPS → bearing до Каабы
        Position.enableLocationEvents(
            Position.LOCATION_CONTINUOUS,
            method(:onPosition)
        );

        // Компас → heading
        Sensor.enableSensorEvents(method(:onSensor));

        System.println("TasbihApp: started");
    }

    // Called when the app is closing
    public function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Sensor.enableSensorEvents(null);
        System.println("TasbihApp: stopped");
    }

    // Return the root view + delegate pair
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var view     = new $.MainView();
        var delegate = new $.MainDelegate(view);
        return [view, delegate];
    }

    // ---- GPS callback ---------------------------------------
    // Обновляем координаты только при хорошем качестве сигнала

    public function onPosition(info as Position.Info) as Void {
        if (info.accuracy >= Position.QUALITY_GOOD) {
            var coords = info.position.toRadians();
            QiblaManager.updateLocation(coords[0] as Double, coords[1] as Double);
        } else {
            QiblaManager.clearLocation();
        }
        WatchUi.requestUpdate();
    }

    // ---- Sensor callback ------------------------------------
    // Обновляем heading компаса

    public function onSensor(sensorInfo as Sensor.Info) as Void {
        var heading = sensorInfo.heading;
        if (heading != null) {
            QiblaManager.updateHeading(heading as Float);
            WatchUi.requestUpdate();
        }
    }

    // ----------------------------------------------------------
    // checkDailyReset — auto-reset counter at midnight.
    // Also initialises Storage keys on very first launch.
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

        // First-run defaults
        if (Application.Storage.getValue("dailyGoal") == null) {
            Application.Storage.setValue("dailyGoal", 33);
        }
        if (Application.Storage.getValue("vibrationEnabled") == null) {
            Application.Storage.setValue("vibrationEnabled", true);
        }
    }

}
