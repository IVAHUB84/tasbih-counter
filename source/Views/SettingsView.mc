import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// GoalPickerView — custom number-picker for the daily goal
//
// Controls:
//   UP    → +1     DOWN → -1
//   START → save   BACK → cancel
// ============================================================
class GoalPickerView extends WatchUi.View {

    private var _goal as Number;

    public function initialize() {
        View.initialize();
        _goal = GoalManager.getGoal();
        System.println("GoalPickerView: goal = " + _goal.toString());
    }

    public function onLayout(dc as Dc) as Void {}

    public function onShow() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 10, Graphics.FONT_SMALL, "Daily Goal",
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Large number in centre
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_HOT, _goal.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hint at bottom
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 18, Graphics.FONT_TINY, "UP+ DOWN-  START=Save",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    public function onHide() as Void {}

    public function increment() as Void {
        if (_goal < GoalManager.MAX_GOAL) { _goal++; WatchUi.requestUpdate(); }
    }

    public function decrement() as Void {
        if (_goal > GoalManager.MIN_GOAL) { _goal--; WatchUi.requestUpdate(); }
    }

    public function getSelectedGoal() as Number {
        return _goal;
    }

}
