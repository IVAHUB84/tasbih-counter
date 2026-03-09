import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// ============================================================
// MainView — View layer for the main counter screen
//
// Layout:
//   y=5        progress text  "current / goal"
//   y=35       horizontal progress bar (8 px tall)
//   y=½h       counter (FONT_NUMBER_HOT, full-centre)
//   bottom     total count
//   edge       Qibla icon (moves along circle edge)
//   left~y=½h  "Reset" hint opposite UP button
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
        drawQiblaIcon(dc, w, h);
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

    // Horizontal progress bar  x=20, y=35, height=8
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

    // Giant counter centred on screen
    private function drawCounter(dc as Dc, count as Number,
                                  w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_HOT,
                    count.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Total accumulated count at bottom centre
    private function drawTotal(dc as Dc, total as Number,
                                w as Number, h as Number) as Void {
        if (total <= 0) { return; }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 18, Graphics.FONT_SMALL,
                    total.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ----------------------------------------------------------
    // Qibla icon — движется по краю циферблата
    // Рисуем программно: чёрный прямоугольник с золотой рамкой
    // ----------------------------------------------------------
    private function drawQiblaIcon(dc as Dc, w as Number, h as Number) as Void {
        var angle = QiblaManager.getScreenAngle();
        if (angle == null) { return; }

        // Радиус окружности (край экрана минус отступ)
        var r = (w < h ? w : h) / 2 - 12;

        // Центр экрана
        var cx = w / 2;
        var cy = h / 2;

        // Угол в радианы (0=верх, по часовой стрелке)
        var rad = (angle as Float) * Math.PI / 180.0;

        // Позиция центра иконки
        var ix = cx + (r * Math.sin(rad)).toNumber();
        var iy = cy - (r * Math.cos(rad)).toNumber();

        // Размер иконки
        var iw = 14;
        var ih = 10;

        // Золотая рамка (COLOR_YELLOW)
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(ix - iw / 2 - 1, iy - ih / 2 - 1, iw + 2, ih + 2);

        // Чёрное тело Каабы
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(ix - iw / 2, iy - ih / 2, iw, ih);

        // Белая полоса (пояс кисва)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(ix - iw / 2, iy - 1, iw, 2);
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
