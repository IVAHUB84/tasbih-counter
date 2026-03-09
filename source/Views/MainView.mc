import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ============================================================
// MainView — View layer for the main counter screen
//
// Layout top → bottom:
//   y=5    progress text  "current / goal"
//   y=35   horizontal progress bar (8 px tall)
//   y=½h   counter (FONT_NUMBER_HOT, full-centre)
//   y=h-25 icons: reset (left)   settings (right)
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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawProgressText(dc, count, goal, w);
        drawProgressBar(dc, count, goal, w);
        drawCounter(dc, count, w, h);
        drawBottomIcons(dc, w, h);
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

    // ─────────────────────────────────────────────────────────
    // drawBottomIcons
    //   Reset    icon — lower-left,  x=30,   y=h-25
    //   Settings icon — lower-right, x=w-30, y=h-25
    //
    // Touch zones in MainDelegate use the same centre coords.
    // ─────────────────────────────────────────────────────────
    private function drawBottomIcons(dc as Dc, w as Number, h as Number) as Void {
        var iconY = h - 25;
        var bgR   = 15;

        // ── Shared background circles ──────────────────────────
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(30, iconY, bgR);
        dc.fillCircle(w - 30, iconY, bgR);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // ── Reset icon: circular arrow ─────────────────────────
        // Arc ~300°, gap at top-right; arrowhead closes the gap
        var arcR = 7;
        var cx   = 30;
        // Arc from 70° to 330° counter-clockwise leaves gap at ~350–70° (top-right)
        dc.drawArc(cx, iconY, arcR, Graphics.ARC_COUNTER_CLOCKWISE, 70, 330);

        // Arrowhead at 70°: point = cx + arcR*cos70, cy - arcR*sin70
        // cos70≈0.342 → +2, sin70≈0.940 → -7  (screen: y down)
        var ax = cx + 2;
        var ay = iconY - 7;
        // Two short lines forming the arrow tip
        dc.drawLine(ax, ay, ax - 4, ay - 1);
        dc.drawLine(ax, ay, ax - 1, ay + 4);

        // ── Settings icon: gear ────────────────────────────────
        // Centre hub + outer ring + 6 teeth (every 60°)
        // Pre-computed cos/sin * gearR for 0,60,120,180,240,300° (×10 → /10)
        // cos: 10, 5,-5,-10,-5, 5   sin: 0, 9, 9, 0,-9,-9  (×10, rounded)
        var gx        = w - 30;
        var innerR    = 3;
        var outerR    = 8;
        var teethOutR = 11;

        dc.fillCircle(gx, iconY, innerR);
        dc.drawCircle(gx, iconY, outerR);

        // cosX10 and sinX10 for angles 0,60,120,180,240,300 degrees
        var cosX10 = [10,  5, -5, -10, -5,  5];
        var sinX10 = [ 0,  9,  9,   0, -9, -9];

        for (var i = 0; i < 6; i++) {
            // Inner tooth root on the outer ring
            var x1 = gx + (cosX10[i] * outerR  / 10);
            var y1 = iconY + (sinX10[i] * outerR  / 10);
            // Outer tooth tip
            var x2 = gx + (cosX10[i] * teethOutR / 10);
            var y2 = iconY + (sinX10[i] * teethOutR / 10);
            dc.drawLine(x1, y1, x2, y2);
        }
    }

}
