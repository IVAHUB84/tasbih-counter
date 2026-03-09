import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// MainDelegate — Controller layer for the main counter screen
//
// Buttons:  START → increment   UP → reset dialog
//           DOWN  → decrement   BACK → exit
// Touch:    tap anywhere → increment
// ============================================================
class MainDelegate extends WatchUi.BehaviorDelegate {

    public function initialize(view as MainView) {
        BehaviorDelegate.initialize();
    }

    // START / SELECT → immediate reset
    public function onSelect() as Boolean {
        GoalManager.resetCount();
        WatchUi.requestUpdate();
        return true;
    }

    // UP → reset dialog (Fenix / watches with UP button)
    public function onPreviousPage() as Boolean {
        showResetDialog();
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

    // Touch tap → increment
    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        incrementCounter();
        return true;
    }

    // ----------------------------------------------------------
    // incrementCounter — adds 1; auto-cycles when goal already met
    // ----------------------------------------------------------
    public function incrementCounter() as Void {
        var goal = GoalManager.getGoal();

        // If previous cycle was completed, start a new one
        if (GoalManager.isGoalAchieved()) {
            GoalManager.addToTotal(goal);
            Application.Storage.setValue("currentCount", 0);
            GoalManager.setGoalAchieved(false);
        }

        var count = GoalManager.incrementCount();

        if (count >= goal) {
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

    // Show custom reset confirmation screen
    public function showResetDialog() as Void {
        WatchUi.pushView(
            new $.ResetConfirmView(),
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
// ResetConfirmView — custom "Сбросить?" screen
//
//   centre      — "Сбросить?"
//   right ~y=h/3  — "Да"       opposite START button
//   right ~y=2h/3 — "Отмена"   opposite BACK button
// ============================================================
class ResetConfirmView extends WatchUi.View {

    public function initialize() {
        View.initialize();
    }

    public function onLayout(dc as Dc) as Void {}

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Question in the centre
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_MEDIUM,
                    "Reset?",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // "Yes" — opposite START button (top-right)
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 12, h / 3, Graphics.FONT_SMALL,
                    "Yes",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // "Cancel" — opposite BACK button (bottom-right)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 12, 2 * h / 3, Graphics.FONT_SMALL,
                    "Cancel",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}

// ============================================================
// ResetConfirmDelegate — START = confirm, BACK = cancel
// ============================================================
class ResetConfirmDelegate extends WatchUi.BehaviorDelegate {

    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onSelect() as Boolean {
        GoalManager.resetCount();
        System.println("Counter reset confirmed");
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.requestUpdate();
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

}
