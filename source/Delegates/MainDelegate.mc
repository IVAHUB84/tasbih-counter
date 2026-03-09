import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// MainDelegate — Controller layer for the main counter screen
//
// Buttons:  START → increment   DOWN → decrement   BACK → exit
// Touch:    tap R icon → reset dialog
//           tap S icon → settings
//           tap anywhere else → increment
// ============================================================
class MainDelegate extends WatchUi.BehaviorDelegate {

    public function initialize(view as MainView) {
        BehaviorDelegate.initialize();
    }

    // START / SELECT → increment
    public function onSelect() as Boolean {
        incrementCounter();
        return true;
    }

    // DOWN → decrement
    public function onNextPage() as Boolean {
        decrementCounter();
        return true;
    }

    // BACK → let the system exit the app (don't override)
    public function onBack() as Boolean {
        return false;
    }

    // Touch tap — route by coordinates
    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0] as Number;
        var y = coords[1] as Number;

        var device = System.getDeviceSettings();
        var sw     = device.screenWidth  as Number;
        var sh     = device.screenHeight as Number;

        var iconY  = sh - 32;
        var hitR   = 22;    // enlarged touch zone

        // Reset icon (lower-left of centre, x=sw/2-45)
        var dxR = x - (sw / 2 - 45);
        var dyR = y - iconY;
        if ((dxR * dxR + dyR * dyR) <= (hitR * hitR)) {
            showResetDialog();
            return true;
        }

        // Settings icon (lower-right of centre, x=sw/2+45)
        var dxS = x - (sw / 2 + 45);
        var dyS = y - iconY;
        if ((dxS * dxS + dyS * dyS) <= (hitR * hitR)) {
            openSettings();
            return true;
        }

        // Main area → increment
        incrementCounter();
        return true;
    }

    // ----------------------------------------------------------
    // incrementCounter — adds 1, fires vibration on first goal hit
    // ----------------------------------------------------------
    public function incrementCounter() as Void {
        var count      = GoalManager.incrementCount();
        var goal       = GoalManager.getGoal();
        var wasAchieved = GoalManager.isGoalAchieved();

        if (count >= goal && !wasAchieved) {
            GoalManager.setGoalAchieved(true);
            triggerGoalVibration();
            System.println("Goal reached: " + count.toString() + "/" + goal.toString());
        }
        WatchUi.requestUpdate();
    }

    // ----------------------------------------------------------
    // decrementCounter — subtracts 1, clears achieved if below goal
    // ----------------------------------------------------------
    public function decrementCounter() as Void {
        var count = GoalManager.decrementCount();
        var goal  = GoalManager.getGoal();

        if (count < goal && GoalManager.isGoalAchieved()) {
            GoalManager.setGoalAchieved(false);
            System.println("Goal-achieved flag cleared");
        }
        WatchUi.requestUpdate();
    }

    // Open Settings via Menu2 with a ToggleMenuItem for vibration
    public function openSettings() as Void {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        menu.addItem(new WatchUi.MenuItem(
            "Set daily goal", null, :setGoal, null));
        menu.addItem(new WatchUi.ToggleMenuItem(
            "Vibration",
            {:enabled => "On", :disabled => "Off"},
            :vibration,
            GoalManager.isVibrationEnabled(),
            null));
        menu.addItem(new WatchUi.MenuItem(
            "Reset now", null, :resetNow, null));
        WatchUi.pushView(menu, new $.SettingsDelegate(), WatchUi.SLIDE_UP);
    }

    // Show Yes/No reset confirmation dialog
    public function showResetDialog() as Void {
        WatchUi.pushView(
            new WatchUi.Confirmation("Reset counter?"),
            new $.ResetConfirmDelegate(),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    // Three strong vibration pulses when goal is first reached
    private function triggerGoalVibration() as Void {
        if (!GoalManager.isVibrationEnabled()) { return; }
        if (!(Attention has :vibrate))          { return; }

        Attention.vibrate([
            new Attention.VibeProfile(100, 200),
            new Attention.VibeProfile(0,   150),
            new Attention.VibeProfile(100, 200),
            new Attention.VibeProfile(0,   150),
            new Attention.VibeProfile(100, 200)
        ]);
    }

}

// ============================================================
// ResetConfirmDelegate — handles the Yes/No confirmation
// ============================================================
class ResetConfirmDelegate extends WatchUi.ConfirmationDelegate {

    public function initialize() {
        ConfirmationDelegate.initialize();
    }

    public function onResponse(value as Confirm) as Boolean {
        if (value == WatchUi.CONFIRM_YES) {
            GoalManager.resetCount();
            System.println("Counter reset confirmed");
            WatchUi.requestUpdate();
        }
        return true;
    }

}
