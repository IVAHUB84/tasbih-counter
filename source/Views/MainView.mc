import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// MainView — View layer for the main counter screen
// ============================================================
class MainView extends WatchUi.View {

    var qiblaVisible       as Boolean = false;
    private var _wasAligned    as Boolean = false;
    private var _lastVibration as Number  = 0;    // timestamp в секундах

    public function initialize() {
        View.initialize();
    }

    public function onLayout(dc as Dc) as Void {}

    public function onShow() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        var count = GoalManager.getCount();
        var goal  = GoalManager.getGoal();
        var total = GoalManager.getTotalCount();
        var effectiveGoal = (total >= 99) ? 1 : goal;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawProgressText(dc, count, effectiveGoal, w, h);
        drawProgressBar(dc, count, effectiveGoal, w, h);
        // Qibla info replaces phrase label when Qibla is active — same slot, no overlap
        if (qiblaVisible) {
            drawQiblaInfo(dc, w, h);
        } else {
            drawPhraseLabel(dc, total, w, h);
        }
        drawCounter(dc, count, w, h);
        drawTotal(dc, total + count, w, h);
        if (qiblaVisible) {
            var aligned = QiblaManager.isAligned(_wasAligned);
            if (aligned && !_wasAligned) {
                var now = System.getTimer() / 1000;
                if (now - _lastVibration >= 3) {
                    vibrateAligned();
                    _lastVibration = now;
                }
            }
            _wasAligned = aligned;
            drawQiblaArrow(dc, w, h, aligned);
        } else {
            _wasAligned = false;
        }
        drawButtonHints(dc, w, h);
    }

    public function onHide() as Void {}

    // "33/100" above the bar
    private function drawProgressText(dc as Dc, count as Number,
                                       goal as Number, w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 22, Graphics.FONT_SMALL,
                    count.toString() + "/" + goal.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Horizontal progress bar
    private function drawProgressBar(dc as Dc, count as Number,
                                      goal as Number, w as Number, h as Number) as Void {
        var barX    = 20;
        var barY    = h / 6;
        var barH    = 12;
        var barMaxW = w - 40;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barMaxW, barH);

        var barW = 0;
        if (goal > 0) {
            barW = (count.toFloat() / goal.toFloat() * barMaxW.toFloat()).toNumber();
        }
        if (barW > barMaxW) { barW = barMaxW; }
        if (barW < 0)       { barW = 0; }

        if (barW > 0) {
            // Islamic green in progress; bright green when cycle complete
            dc.setColor(
                count >= goal ? Graphics.COLOR_GREEN : 0x00A550,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRectangle(barX, barY, barW, barH);
        }
    }

    // Phrase label — based on cycle (hardcoded 33-count cycles per Islamic tradition)
    // Cycle 0 (total 0-32):  Subhan Allah
    // Cycle 1 (total 33-65): Alhamdulillah
    // Cycle 2 (total 66-98): Allahu Akbar
    // Cycle 3 (total 99):    La ilaha illallah
    private function drawPhraseLabel(dc as Dc, total as Number,
                                      w as Number, h as Number) as Void {
        var phrases = ["Subhan Allah", "Alhamdulillah", "Allahu Akbar", "La ilaha illallah"] as Array<String>;
        var idx = total / 33;
        if (idx < 0 || idx >= phrases.size()) { return; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 4, Graphics.FONT_MEDIUM,
                    phrases[idx],
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Giant counter — сдвинут чуть выше центра чтобы освободить место для total
    private function drawCounter(dc as Dc, count as Number,
                                  w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_HOT,
                    count.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Total accumulated count at bottom centre
    // At 100: green + FONT_LARGE (session complete)
    private function drawTotal(dc as Dc, total as Number,
                                w as Number, h as Number) as Void {
        if (total <= 0) { return; }
        if (total >= 100) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 24, Graphics.FONT_LARGE,
                        total.toString(),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 24, Graphics.FONT_MEDIUM,
                        total.toString(),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ----------------------------------------------------------
    // Qibla arrow — красная стрелка, или иконка мечети если лицом к Мекке
    // ----------------------------------------------------------
    private function drawQiblaArrow(dc as Dc, w as Number, h as Number, aligned as Boolean) as Void {
        if (aligned) {
            drawMeccaIcon(dc, w, h);
            return;
        }

        var angle = QiblaManager.getScreenAngle();
        if (angle == null) { return; }
        var a = angle as Float;

        var r   = (w < h ? w : h) / 2 - 10;
        var cx  = w / 2;
        var cy  = h / 2;
        var rad = a * Math.PI.toFloat() / 180.0f;

        var ax = Math.sin(rad).toFloat();
        var ay = -Math.cos(rad).toFloat();
        var px = Math.cos(rad).toFloat();
        var py = Math.sin(rad).toFloat();

        var pts = [
            [cx + (r * ax).toNumber(),                                    cy + (r * ay).toNumber()],
            [(cx + ((r-14)*ax + 8*px)).toNumber(),  (cy + ((r-14)*ay + 8*py)).toNumber()],
            [(cx + ((r-14)*ax + 4*px)).toNumber(),  (cy + ((r-14)*ay + 4*py)).toNumber()],
            [(cx + ((r-26)*ax + 4*px)).toNumber(),  (cy + ((r-26)*ay + 4*py)).toNumber()],
            [(cx + ((r-26)*ax - 4*px)).toNumber(),  (cy + ((r-26)*ay - 4*py)).toNumber()],
            [(cx + ((r-14)*ax - 4*px)).toNumber(),  (cy + ((r-14)*ay - 4*py)).toNumber()],
            [(cx + ((r-14)*ax - 8*px)).toNumber(),  (cy + ((r-14)*ay - 8*py)).toNumber()]
        ] as Array<[Number, Number]>;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
    }

    // ----------------------------------------------------------
    // Иконка мечети — когда лицом к Мекке (±20°)
    // Позиция: строго по центру между счётчиком и total
    // ----------------------------------------------------------
    private function drawMeccaIcon(dc as Dc, w as Number, h as Number) as Void {
        var cx = w / 2;
        var iy = h * 3 / 4;

        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);

        // Левый минарет: ствол + балкон + острый шпиль
        dc.fillRectangle(cx - 32, iy - 18, 8, 26);
        dc.fillRectangle(cx - 34, iy - 22, 12, 5);
        var lCap = [
            [cx - 28, iy - 34],
            [cx - 34, iy - 22],
            [cx - 22, iy - 22]
        ] as Array<[Number, Number]>;
        dc.fillPolygon(lCap);

        // Правый минарет: ствол + балкон + острый шпиль
        dc.fillRectangle(cx + 24, iy - 18, 8, 26);
        dc.fillRectangle(cx + 22, iy - 22, 12, 5);
        var rCap = [
            [cx + 28, iy - 34],
            [cx + 22, iy - 22],
            [cx + 34, iy - 22]
        ] as Array<[Number, Number]>;
        dc.fillPolygon(rCap);

        // Основное тело
        dc.fillRectangle(cx - 20, iy - 8, 40, 16);

        // Купол — плавная парабола, 9 точек
        var dome = [
            [cx - 20, iy - 8],
            [cx - 20, iy - 16],
            [cx - 15, iy - 26],
            [cx - 7,  iy - 34],
            [cx,      iy - 38],
            [cx + 7,  iy - 34],
            [cx + 15, iy - 26],
            [cx + 20, iy - 16],
            [cx + 20, iy - 8]
        ] as Array<[Number, Number]>;
        dc.fillPolygon(dome);

        // Арочная дверь — чёрная
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var door = [
            [cx - 6,  iy + 8],
            [cx - 6,  iy - 1],
            [cx - 4,  iy - 5],
            [cx,      iy - 7],
            [cx + 4,  iy - 5],
            [cx + 6,  iy - 1],
            [cx + 6,  iy + 8]
        ] as Array<[Number, Number]>;
        dc.fillPolygon(door);
    }

    // ----------------------------------------------------------
    // Qibla info — "Kaaba 195° (SW)" — same slot as phrase label (h/4), no overlap
    // ----------------------------------------------------------
    private function drawQiblaInfo(dc as Dc, w as Number, h as Number) as Void {
        var b = QiblaManager.getBearingDegrees();
        if (b == null) { return; }
        var label = QiblaManager.getBearingLabel();
        var text  = "Kaaba " + (b as Float).format("%.0f") + "\u00B0 (" + label + ")";
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 4, Graphics.FONT_XTINY, text,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Вибрация при совпадении направления с Меккой
    private function vibrateAligned() as Void {
        if (!(Attention has :vibrate)) { return; }
        Attention.vibrate([
            new Attention.VibeProfile(100, 200),
            new Attention.VibeProfile(0,   100),
            new Attention.VibeProfile(100, 200)
        ]);
    }

    // Button hint — "Reset" opposite UP button (left side on Fenix)
    (:fenixBehavior)
    private function drawButtonHints(dc as Dc, w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(8, h / 2, Graphics.FONT_XTINY,
                    "Reset",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Button hint — "Hold: Reset" on right side for Vivoactive 4
    (:vivoactiveBehavior)
    private function drawButtonHints(dc as Dc, w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 8, h / 3, Graphics.FONT_XTINY,
                    "Hold: Reset",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
