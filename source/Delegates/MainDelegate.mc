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

    private var _view as MainView;

    public function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // SELECT / tap screen → increment
    public function onSelect() as Boolean {
        incrementCounter();
        return true;
    }

    // Long hold → immediate reset (Vivoactive 4 only — no dedicated UP button)
    (:vivoactiveBehavior)
    public function onHold(holdEvent as WatchUi.ClickEvent) as Boolean {
        GoalManager.resetCount();
        WatchUi.requestUpdate();
        System.println("Hold reset");
        return true;
    }

    // Long hold → ignored on Fenix/Epix (UP button handles reset)
    (:fenixBehavior)
    public function onHold(holdEvent as WatchUi.ClickEvent) as Boolean {
        return false;
    }

    // UP → reset (Fenix with UP button)
    public function onPreviousPage() as Boolean {
        showResetDialog();
        return true;
    }

    // DOWN → toggle Qibla arrow + info
    public function onNextPage() as Boolean {
        _view.qiblaVisible = !_view.qiblaVisible;
        WatchUi.requestUpdate();
        return true;
    }

    // BACK → let the system exit the app (don't override)
    public function onBack() as Boolean {
        return false;
    }

    // onTap kept for completeness (fires on some devices)
    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        incrementCounter();
        return true;
    }

    // ----------------------------------------------------------
    // incrementCounter — adds 1; auto-cycles when goal already met
    // Cycle 0 (total 0-32):  Subhan Allah    goal = user goal (default 33)
    // Cycle 1 (total 33-65): Alhamdulillah   goal = user goal
    // Cycle 2 (total 66-98): Allahu Akbar    goal = user goal
    // Cycle 3 (total 99):    La ilaha illallah goal = 1
    // Grand total ≥ 100 → auto reset
    // ----------------------------------------------------------
    public function incrementCounter() as Void {
        // 101st tap — session complete flag was set on 100th tap → auto reset
        if (GoalManager.isGoalAchieved() && GoalManager.getTotalCount() >= 99) {
            GoalManager.resetCount();
            WatchUi.requestUpdate();
            return;
        }

        // Normal cycle transition
        if (GoalManager.isGoalAchieved()) {
            GoalManager.addToTotal(GoalManager.getGoal());
            Application.Storage.setValue("currentCount", 0);
            GoalManager.setGoalAchieved(false);
        }

        var total = GoalManager.getTotalCount();
        var goal  = (total >= 99) ? 1 : GoalManager.getGoal();
        var count = GoalManager.incrementCount();

        if (total + count >= 100) {
            // 100th tap — show La ilaha illallah, reset on next tap
            GoalManager.setGoalAchieved(true);
            triggerGoalVibration();
            WatchUi.requestUpdate();
            return;
        }

        if (count >= goal) {
            GoalManager.setGoalAchieved(true);
            triggerGoalVibration();
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

    // Single vibration pulse when cycle is complete
    private function triggerGoalVibration() as Void {
        if (!GoalManager.isVibrationEnabled()) { return; }
        if (!(Attention has :vibrate))          { return; }

        Attention.vibrate([new Attention.VibeProfile(100, 300)]);
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
