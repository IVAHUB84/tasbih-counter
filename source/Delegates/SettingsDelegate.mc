import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// SettingsDelegate — Menu2InputDelegate for the Settings menu
//
// Items:
//   :setGoal   → push GoalPickerView
//   :vibration → ToggleMenuItem; saves state on each toggle
//   :resetNow  → push reset confirmation dialog
// ============================================================
class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();

        if (id == :setGoal) {
            var pickerView = new $.GoalPickerView();
            WatchUi.pushView(pickerView, new $.GoalPickerDelegate(pickerView), WatchUi.SLIDE_UP);

        } else if (id == :vibration) {
            // ToggleMenuItem already flipped its own visual state on tap;
            // persist the new value from the item itself.
            var toggle = item as ToggleMenuItem;
            GoalManager.setVibrationEnabled(toggle.isEnabled());
            System.println("SettingsDelegate: vibration → " + toggle.isEnabled().toString());

        } else if (id == :resetNow) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Reset counter?"),
                new $.ResetConfirmDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    // Back button closes the settings menu
    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

}

// ============================================================
// GoalPickerDelegate — BehaviorDelegate for GoalPickerView
// ============================================================
class GoalPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as GoalPickerView;

    public function initialize(view as GoalPickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP → increase
    public function onPreviousPage() as Boolean {
        _view.increment();
        return true;
    }

    // DOWN → decrease
    public function onNextPage() as Boolean {
        _view.decrement();
        return true;
    }

    // START → save and close
    public function onSelect() as Boolean {
        var newGoal = _view.getSelectedGoal();
        GoalManager.setGoal(newGoal);
        System.println("GoalPickerDelegate: saved goal = " + newGoal.toString());
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // BACK → cancel without saving
    public function onBack() as Boolean {
        System.println("GoalPickerDelegate: cancelled");
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

}
