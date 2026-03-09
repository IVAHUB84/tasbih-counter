import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// ============================================================
// MainView — View layer for the main counter screen
// ============================================================
class MainView extends WatchUi.View {

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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawProgressText(dc, count, goal, w);
        drawProgressBar(dc, count, goal, w);
        drawCounter(dc, count, w, h);
        drawTotal(dc, total, w, h);
        drawQiblaArrow(dc, w, h);
        drawQiblaInfo(dc, w, h);
        drawButtonHints(dc, w, h);
    }

    public function onHide() as Void {}

    // "33/100" above the bar
    private function drawProgressText(dc as Dc, count as Number,
                                       goal as Number, w as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 5, Graphics.FONT_SMALL,
                    count.toString() + "/" + goal.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Horizontal progress bar
    private function drawProgressBar(dc as Dc, count as Number,
                                      goal as Number, w as Number) as Void {
        var barX    = 20;
        var barY    = 35;
        var barH    = 8;
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
            dc.setColor(
                count >= goal ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_BLUE,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRectangle(barX, barY, barW, barH);
        }
    }

    // Giant counter — сдвинут чуть выше центра чтобы освободить место для total
    private function drawCounter(dc as Dc, count as Number,
                                  w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_HOT,
                    count.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Total accumulated count at bottom centre — крупнее
    private function drawTotal(dc as Dc, total as Number,
                                w as Number, h as Number) as Void {
        if (total <= 0) { return; }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 24, Graphics.FONT_MEDIUM,
                    total.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ----------------------------------------------------------
    // Qibla arrow — красная стрелка, или иконка мечети если лицом к Мекке
    // ----------------------------------------------------------
    private function drawQiblaArrow(dc as Dc, w as Number, h as Number) as Void {
        var angle = QiblaManager.getScreenAngle();
        if (angle == null) { return; }

        // ±20° — считаем что лицом к Мекке
        var a = angle as Float;
        var aligned = (a <= 20.0f || a >= 340.0f);

        if (aligned) {
            drawMeccaIcon(dc, w, h);
            return;
        }

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

        // Левый минарет
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 26, iy - 18, 6, 26);
        dc.fillRectangle(cx - 28, iy - 24, 10, 7);

        // Правый минарет
        dc.fillRectangle(cx + 20, iy - 18, 6, 26);
        dc.fillRectangle(cx + 18, iy - 24, 10, 7);

        // Тело + купол мечети (один полигон)
        var pts = [
            [cx - 18, iy + 8],
            [cx - 18, iy - 8],
            [cx - 14, iy - 20],
            [cx,      iy - 30],
            [cx + 14, iy - 20],
            [cx + 18, iy - 8],
            [cx + 18, iy + 8]
        ] as Array<[Number, Number]>;
        dc.fillPolygon(pts);

        // Надпись
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, iy + 14, Graphics.FONT_SMALL, "Mecca",
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ----------------------------------------------------------
    // Qibla info — "Kaaba 195° (SW)" по центру на y=50
    // ----------------------------------------------------------
    private function drawQiblaInfo(dc as Dc, w as Number, h as Number) as Void {
        var b = QiblaManager.getBearingDegrees();
        if (b == null) { return; }
        var label = QiblaManager.getBearingLabel();
        var text  = "Kaaba " + (b as Float).format("%.0f") + "\u00B0 (" + label + ")";
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 50, Graphics.FONT_XTINY, text,
                    Graphics.TEXT_JUSTIFY_CENTER);
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
