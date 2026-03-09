import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// ============================================================
// GoalManager — Model layer (MVC)
// All Application.Storage reads/writes go through here.
// ============================================================
module GoalManager {

    const DEFAULT_GOAL = 33;
    const DEFAULT_COUNT = 0;
    const MIN_GOAL = 1;
    const MAX_GOAL = 999;

    // ---- Counter ------------------------------------------------

    public function getCount() as Number {
        var v = Application.Storage.getValue("currentCount");
        if (v == null) { return DEFAULT_COUNT; }
        return v as Number;
    }

    public function incrementCount() as Number {
        var count = getCount() + 1;
        Application.Storage.setValue("currentCount", count);
        System.println("GoalManager: count → " + count.toString());
        return count;
    }

    // Decrement with floor of 0; returns new value
    public function decrementCount() as Number {
        var count = getCount();
        if (count > 0) {
            count = count - 1;
            Application.Storage.setValue("currentCount", count);
            System.println("GoalManager: count → " + count.toString());
        }
        return count;
    }

    public function resetCount() as Void {
        Application.Storage.setValue("currentCount", 0);
        Application.Storage.setValue("goalAchieved", false);
        Application.Storage.setValue("totalCount", 0);
        System.println("GoalManager: counter reset");
    }

    // ---- Total (accumulated across cycles) ----------------------

    public function getTotalCount() as Number {
        var v = Application.Storage.getValue("totalCount");
        if (v == null) { return 0; }
        return v as Number;
    }

    public function addToTotal(n as Number) as Void {
        var total = getTotalCount() + n;
        Application.Storage.setValue("totalCount", total);
        System.println("GoalManager: total → " + total.toString());
    }

    // ---- Goal ---------------------------------------------------

    // Never returns 0 — treat 0 as default
    public function getGoal() as Number {
        var v = Application.Storage.getValue("dailyGoal");
        if (v == null) { return DEFAULT_GOAL; }
        var goal = v as Number;
        if (goal == 0) { return DEFAULT_GOAL; }
        return goal;
    }

    public function setGoal(goal as Number) as Void {
        if (goal < MIN_GOAL) { goal = MIN_GOAL; }
        if (goal > MAX_GOAL) { goal = MAX_GOAL; }
        Application.Storage.setValue("dailyGoal", goal);
        System.println("GoalManager: goal → " + goal.toString());
    }

    // ---- Achievement --------------------------------------------

    public function isGoalAchieved() as Boolean {
        var v = Application.Storage.getValue("goalAchieved");
        if (v == null) { return false; }
        return v as Boolean;
    }

    public function setGoalAchieved(achieved as Boolean) as Void {
        Application.Storage.setValue("goalAchieved", achieved);
    }

    // ---- Vibration ----------------------------------------------

    public function isVibrationEnabled() as Boolean {
        var v = Application.Storage.getValue("vibrationEnabled");
        if (v == null) { return true; }
        return v as Boolean;
    }

    public function setVibrationEnabled(enabled as Boolean) as Void {
        Application.Storage.setValue("vibrationEnabled", enabled);
        System.println("GoalManager: vibration " + (enabled ? "on" : "off"));
    }

    public function toggleVibration() as Boolean {
        var next = !isVibrationEnabled();
        setVibrationEnabled(next);
        return next;
    }

}
