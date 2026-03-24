using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.Sensor;
using Toybox.Math;
using Toybox.Lang;
using Toybox.System;

//! Main view that renders animated color patterns reactive to motion/vibrations.
class DiscoTechView extends WatchUi.View {

    // Animation timer
    private var _timer as Timer.Timer?;

    // Frame counter for animation
    private var _frame as Number = 0;

    // Current pattern index
    private var _patternIndex as Number = 0;

    // Total number of available patterns
    private const PATTERN_COUNT = 10;

    // Pattern names for on-screen display
    private var _patternNames as Array<String> = [
        "Rainbow Pulse",
        "Spiral Galaxy",
        "Concentric Rings",
        "Starburst",
        "Color Wave",
        "Diamond Twist",
        "Radar Sweep",
        "Plasma Field",
        "Disco Ball",
        "Fireworks"
    ];

    // Accelerometer-derived "energy" level (0.0 - 1.0)
    private var _energy as Float = 0.0;

    // Smoothed energy for visual transitions
    private var _smoothEnergy as Float = 0.0;

    // Peak energy for flash effects
    private var _peakEnergy as Float = 0.0;

    // Beat detection threshold
    private var _beatThreshold as Float = 0.4;

    // Is a beat currently detected
    private var _beatActive as Boolean = false;

    // Auto-cycle through patterns
    private var _autoCycle as Boolean = false;
    private var _autoCycleCounter as Number = 0;
    private const AUTO_CYCLE_FRAMES = 300; // ~10 seconds at 30fps

    // Manual beat trigger (from tap)
    private var _manualBeat as Number = 0;

    // Screen dimensions (set in onLayout)
    private var _width as Number = 260;
    private var _height as Number = 260;
    private var _centerX as Number = 130;
    private var _centerY as Number = 130;
    private var _radius as Number = 130;

    // Rainbow color palette (pre-computed)
    private var _rainbow as Array<Number> = [];

    // Show pattern name overlay countdown
    private var _showName as Number = 0;

    function initialize() {
        View.initialize();
        _buildRainbow();
    }

    //! Build a 256-entry rainbow lookup table.
    private function _buildRainbow() as Void {
        _rainbow = new Array<Number>[256];
        for (var i = 0; i < 256; i++) {
            _rainbow[i] = _hsvToRgb(i * 360 / 256, 255, 255);
        }
    }

    //! Convert HSV (h=0..359, s=0..255, v=0..255) to 0xRRGGBB.
    private function _hsvToRgb(h as Number, s as Number, v as Number) as Number {
        if (s == 0) {
            return (v << 16) | (v << 8) | v;
        }
        var region = h / 60;
        var remainder = (h - (region * 60)) * 255 / 60;
        var p = (v * (255 - s)) / 255;
        var q = (v * (255 - (s * remainder) / 255)) / 255;
        var t = (v * (255 - (s * (255 - remainder)) / 255)) / 255;

        var r, g, b;
        switch (region) {
            case 0:  r = v; g = t; b = p; break;
            case 1:  r = q; g = v; b = p; break;
            case 2:  r = p; g = v; b = t; break;
            case 3:  r = p; g = q; b = v; break;
            case 4:  r = t; g = p; b = v; break;
            default: r = v; g = p; b = q; break;
        }
        return (r << 16) | (g << 8) | b;
    }

    function onLayout(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _centerX = _width / 2;
        _centerY = _height / 2;
        _radius = (_width < _height ? _width : _height) / 2;
    }

    function onShow() as Void {
        // Register accelerometer sensor
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_ACCELEROMETER]);
            Sensor.enableSensorEvents(method(:onSensor));
        } catch (e) {
            // Sensor may not be available; patterns still animate
        }

        // Start animation timer at ~30fps
        _timer = new Timer.Timer();
        _timer.start(method(:onTimer), 33, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        try {
            Sensor.enableSensorEvents(null);
        } catch (e) {
            // Ignore
        }
    }

    //! Accelerometer callback - detect vibrations as proxy for bass.
    function onSensor(info as Sensor.Info) as Void {
        if (info has :accel && info.accel != null) {
            var accel = info.accel;
            // Calculate magnitude of acceleration vector
            var x = accel[0].toFloat();
            var y = accel[1].toFloat();
            var z = accel[2].toFloat();
            var mag = Math.sqrt(x * x + y * y + z * z).toFloat();

            // Normalize: resting gravity ~1000 mG, vibrations add to that
            // Subtract gravity baseline and normalize to 0..1
            var deviation = (mag - 980.0).abs() / 500.0;
            if (deviation > 1.0) {
                deviation = 1.0;
            }
            _energy = deviation;
        }
    }

    //! Animation timer callback
    function onTimer() as Void {
        _frame++;

        // Smooth the energy signal
        _smoothEnergy = _smoothEnergy * 0.7 + _energy * 0.3;

        // Beat detection: energy spike above threshold
        if (_smoothEnergy > _beatThreshold && !_beatActive) {
            _beatActive = true;
            _peakEnergy = 1.0;
        } else if (_smoothEnergy < _beatThreshold * 0.6) {
            _beatActive = false;
        }

        // Manual beat from tap
        if (_manualBeat > 0) {
            _peakEnergy = 1.0;
            _manualBeat--;
        }

        // Decay peak energy
        _peakEnergy = _peakEnergy * 0.85;
        if (_peakEnergy < 0.05) {
            _peakEnergy = 0.0;
        }

        // Auto-cycle patterns
        if (_autoCycle) {
            _autoCycleCounter++;
            if (_autoCycleCounter >= AUTO_CYCLE_FRAMES) {
                _autoCycleCounter = 0;
                _patternIndex = (_patternIndex + 1) % PATTERN_COUNT;
                _showName = 60;
            }
        }

        // Decay name overlay
        if (_showName > 0) {
            _showName--;
        }

        // Request screen update
        WatchUi.requestUpdate();
    }

    //! Main render function
    function onUpdate(dc as Dc) as Void {
        // Clear screen to black
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Combined energy for visual intensity
        var intensity = _smoothEnergy + _peakEnergy * 0.5;
        if (intensity > 1.0) {
            intensity = 1.0;
        }
        // Ensure minimum animation even without motion
        var baseIntensity = 0.3 + intensity * 0.7;

        // Draw the current pattern
        switch (_patternIndex) {
            case 0: _drawRainbowPulse(dc, baseIntensity); break;
            case 1: _drawSpiralGalaxy(dc, baseIntensity); break;
            case 2: _drawConcentricRings(dc, baseIntensity); break;
            case 3: _drawStarburst(dc, baseIntensity); break;
            case 4: _drawColorWave(dc, baseIntensity); break;
            case 5: _drawDiamondTwist(dc, baseIntensity); break;
            case 6: _drawRadarSweep(dc, baseIntensity); break;
            case 7: _drawPlasmaField(dc, baseIntensity); break;
            case 8: _drawDiscoBall(dc, baseIntensity); break;
            case 9: _drawFireworks(dc, baseIntensity); break;
        }

        // Flash overlay on beat
        if (_peakEnergy > 0.3) {
            var alpha = (_peakEnergy * 80).toNumber();
            if (alpha > 80) { alpha = 80; }
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            // Draw semi-transparent flash by drawing white circles at center
            var flashRadius = (_radius * _peakEnergy).toNumber();
            dc.fillCircle(_centerX, _centerY, flashRadius);
        }

        // Show pattern name overlay
        if (_showName > 0) {
            _drawPatternName(dc);
        }
    }

    //! Draw pattern name overlay with fade
    private function _drawPatternName(dc as Dc) as Void {
        var name = _patternNames[_patternIndex];
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX, _centerY + _radius * 2 / 3,
            Graphics.FONT_TINY,
            name,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Auto-cycle indicator
        if (_autoCycle) {
            dc.drawText(
                _centerX, _centerY - _radius * 2 / 3,
                Graphics.FONT_XTINY,
                "AUTO",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    // ========================================================================
    // PATTERN IMPLEMENTATIONS
    // ========================================================================

    //! Pattern 0: Rainbow Pulse - expanding/contracting rainbow rings
    private function _drawRainbowPulse(dc as Dc, intensity as Float) as Void {
        var pulse = Math.sin(_frame * 0.1).toFloat() * intensity;
        var numRings = 12;
        for (var i = numRings; i >= 0; i--) {
            var ringRadius = (_radius * i / numRings).toNumber();
            var colorIdx = ((_frame * 3 + i * 20) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            var scale = (ringRadius + pulse * 15).toNumber();
            if (scale < 0) { scale = 0; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_centerX, _centerY, scale);
        }
    }

    //! Pattern 1: Spiral Galaxy - rotating rainbow spiral arms
    private function _drawSpiralGalaxy(dc as Dc, intensity as Float) as Void {
        var arms = 4;
        var rotation = _frame * 0.05 * intensity;
        var points = 60;
        for (var arm = 0; arm < arms; arm++) {
            var armOffset = arm * 6.2832 / arms;
            for (var i = 0; i < points; i++) {
                var t = i.toFloat() / points;
                var angle = t * 6.2832 * 2.5 + armOffset + rotation;
                var r = t * _radius * 0.95;
                var x = (_centerX + r * Math.cos(angle)).toNumber();
                var y = (_centerY + r * Math.sin(angle)).toNumber();
                var colorIdx = ((i * 4 + arm * 64 + _frame * 2) % 256).toNumber();
                if (colorIdx < 0) { colorIdx += 256; }
                var dotSize = (2 + t * 4 * intensity).toNumber();
                dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotSize);
            }
        }
    }

    //! Pattern 2: Concentric Rings - pulsing colored rings
    private function _drawConcentricRings(dc as Dc, intensity as Float) as Void {
        var numRings = 15;
        var expansion = Math.sin(_frame * 0.08).toFloat() * 10 * intensity;
        for (var i = numRings; i >= 0; i--) {
            var baseR = _radius * i / numRings;
            var ringR = (baseR + expansion).toNumber();
            if (ringR < 0) { ringR = 0; }
            var colorIdx = ((_frame * 4 + i * 17) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_centerX, _centerY, ringR);
        }
    }

    //! Pattern 3: Starburst - radiating lines from center
    private function _drawStarburst(dc as Dc, intensity as Float) as Void {
        var numRays = 24;
        var rotation = _frame * 0.03;
        var pulseLen = 0.5 + intensity * 0.5;
        for (var i = 0; i < numRays; i++) {
            var angle = i * 6.2832 / numRays + rotation;
            var length = _radius * pulseLen;
            // Alternating lengths for star effect
            if (i % 2 == 0) {
                length = length * 0.6;
            }
            var x2 = (_centerX + length * Math.cos(angle)).toNumber();
            var y2 = (_centerY + length * Math.sin(angle)).toNumber();
            var colorIdx = ((_frame * 5 + i * 10) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth((2 + intensity * 4).toNumber());
            dc.drawLine(_centerX, _centerY, x2, y2);
        }
        dc.setPenWidth(1);

        // Central glow
        var glowSize = (8 + intensity * 15).toNumber();
        var colorIdx = ((_frame * 7) % 256).toNumber();
        dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, _centerY, glowSize);
    }

    //! Pattern 4: Color Wave - horizontal sine wave bands
    private function _drawColorWave(dc as Dc, intensity as Float) as Void {
        var step = 6;
        for (var y = 0; y < _height; y += step) {
            var wave = Math.sin((y + _frame * 3) * 0.04).toFloat() * 30 * intensity;
            var colorIdx = ((y + _frame * 2) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            var x1 = (_centerX - _radius + wave).toNumber();
            var x2 = (_centerX + _radius + wave).toNumber();
            dc.fillRectangle(x1, y, x2 - x1, step);
        }
    }

    //! Pattern 5: Diamond Twist - rotating diamond shapes
    private function _drawDiamondTwist(dc as Dc, intensity as Float) as Void {
        var numDiamonds = 8;
        var rotation = _frame * 0.04 * intensity;
        for (var i = numDiamonds; i >= 1; i--) {
            var size = _radius * i / numDiamonds;
            var angle = rotation + i * 0.3;
            var colorIdx = ((_frame * 3 + i * 32) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);

            // Diamond: 4 points rotated
            var cos_a = Math.cos(angle).toFloat();
            var sin_a = Math.sin(angle).toFloat();
            var pts = new Array<Array<Number> >[4];
            // Top, Right, Bottom, Left diamond points
            var dx = [0, size, 0, -size];
            var dy = [-size, 0, size, 0];
            for (var p = 0; p < 4; p++) {
                var rx = (dx[p] * cos_a - dy[p] * sin_a).toNumber() + _centerX;
                var ry = (dx[p] * sin_a + dy[p] * cos_a).toNumber() + _centerY;
                pts[p] = [rx, ry];
            }
            // Draw diamond edges
            dc.setPenWidth((2 + intensity * 2).toNumber());
            for (var p = 0; p < 4; p++) {
                var next = (p + 1) % 4;
                dc.drawLine(pts[p][0], pts[p][1], pts[next][0], pts[next][1]);
            }
        }
        dc.setPenWidth(1);
    }

    //! Pattern 6: Radar Sweep - rotating beam with trail
    private function _drawRadarSweep(dc as Dc, intensity as Float) as Void {
        var sweepAngle = _frame * 0.06 * intensity;
        var trailLength = 30;

        // Draw radar rings
        for (var r = 1; r <= 4; r++) {
            var ringR = _radius * r / 4;
            var colorIdx = ((_frame * 2 + r * 50) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawCircle(_centerX, _centerY, ringR);
        }

        // Draw sweep beam with color trail
        for (var i = 0; i < trailLength; i++) {
            var angle = sweepAngle - i * 0.03;
            var alpha = 1.0 - i.toFloat() / trailLength;
            var colorIdx = ((_frame * 5 + i * 8) % 256).toNumber();
            if (colorIdx < 0) { colorIdx += 256; }
            dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
            var len = _radius * (0.5 + alpha * 0.5);
            var x2 = (_centerX + len * Math.cos(angle)).toNumber();
            var y2 = (_centerY + len * Math.sin(angle)).toNumber();
            dc.setPenWidth((1 + alpha * 3).toNumber());
            dc.drawLine(_centerX, _centerY, x2, y2);
        }
        dc.setPenWidth(1);
    }

    //! Pattern 7: Plasma Field - moving color blobs
    private function _drawPlasmaField(dc as Dc, intensity as Float) as Void {
        var step = 12;
        var t = _frame * 0.05 * intensity;
        for (var gx = 0; gx < _width; gx += step) {
            for (var gy = 0; gy < _height; gy += step) {
                var nx = gx.toFloat() / _width;
                var ny = gy.toFloat() / _height;
                var v1 = Math.sin(nx * 10 + t);
                var v2 = Math.sin(ny * 10 + t * 1.3);
                var v3 = Math.sin((nx + ny) * 8 + t * 0.7);
                var v4 = Math.sin(Math.sqrt(
                    (nx - 0.5) * (nx - 0.5) * 100 +
                    (ny - 0.5) * (ny - 0.5) * 100
                ) + t);
                var val = (v1 + v2 + v3 + v4) / 4.0;
                var colorIdx = ((val * 128 + 128).toNumber()) % 256;
                if (colorIdx < 0) { colorIdx += 256; }
                dc.setColor(_rainbow[colorIdx], Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(gx, gy, step, step);
            }
        }
    }

    //! Pattern 8: Disco Ball - grid of flashing colored squares
    private function _drawDiscoBall(dc as Dc, intensity as Float) as Void {
        var cellSize = 20;
        var cols = _width / cellSize + 1;
        var rows = _height / cellSize + 1;
        for (var col = 0; col < cols; col++) {
            for (var row = 0; row < rows; row++) {
                var x = col * cellSize;
                var y = row * cellSize;
                // Check if inside the circular watch face
                var dx = x - _centerX + cellSize / 2;
                var dy = y - _centerY + cellSize / 2;
                if (dx * dx + dy * dy > _radius * _radius) {
                    continue;
                }
                // Pseudo-random color based on position and time
                var hash = (col * 7 + row * 13 + _frame) % 256;
                // Add sparkle: some cells flash white on beat
                var sparkle = ((col + row + _frame / 3) % 5 == 0) && (_peakEnergy > 0.2);
                if (sparkle) {
                    dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
                } else {
                    var colorIdx = ((hash * 37 + _frame * 3) % 256).toNumber();
                    if (colorIdx < 0) { colorIdx += 256; }
                    // Vary brightness based on a wave pattern
                    var bright = Math.sin((col + row + _frame * 0.1) * 0.5).toFloat();
                    bright = (bright + 1) / 2 * intensity;
                    var baseColor = _rainbow[colorIdx];
                    var r = (((baseColor >> 16) & 0xFF) * bright).toNumber();
                    var g = (((baseColor >> 8) & 0xFF) * bright).toNumber();
                    var b = ((baseColor & 0xFF) * bright).toNumber();
                    dc.setColor((r << 16) | (g << 8) | b, Graphics.COLOR_TRANSPARENT);
                }
                dc.fillRectangle(x + 1, y + 1, cellSize - 2, cellSize - 2);
            }
        }
    }

    //! Pattern 9: Fireworks - bursting particle effects
    private function _drawFireworks(dc as Dc, intensity as Float) as Void {
        // Multiple firework bursts at different phases
        var numBursts = 3;
        for (var b = 0; b < numBursts; b++) {
            var phase = (_frame + b * 40) % 120;
            var life = phase.toFloat() / 120;

            // Burst center position (deterministic "random" based on burst index)
            var burstSeed = (b * 97 + (_frame / 120) * 31) % 100;
            var bx = _centerX + ((burstSeed % 7) - 3) * _radius / 8;
            var by = _centerY + (((burstSeed / 7).toNumber() % 7) - 3) * _radius / 8;

            // Expanding particles
            var numParticles = 16;
            var expansionRadius = life * _radius * 0.8 * intensity;
            for (var p = 0; p < numParticles; p++) {
                var angle = p * 6.2832 / numParticles;
                var r = expansionRadius;
                // Add some variation
                r = r * (0.7 + 0.3 * Math.sin(p * 2.5).toFloat());
                var px = (bx + r * Math.cos(angle)).toNumber();
                var py = (by + r * Math.sin(angle)).toNumber();
                var fade = 1.0 - life;
                var colorIdx = ((b * 85 + p * 16 + _frame) % 256).toNumber();
                if (colorIdx < 0) { colorIdx += 256; }
                var baseColor = _rainbow[colorIdx];
                var cr = (((baseColor >> 16) & 0xFF) * fade).toNumber();
                var cg = (((baseColor >> 8) & 0xFF) * fade).toNumber();
                var cb = ((baseColor & 0xFF) * fade).toNumber();
                dc.setColor((cr << 16) | (cg << 8) | cb, Graphics.COLOR_TRANSPARENT);
                var dotSize = ((1.0 - life) * 5 * intensity).toNumber();
                if (dotSize < 1) { dotSize = 1; }
                dc.fillCircle(px, py, dotSize);
            }
        }
    }

    // ========================================================================
    // PUBLIC API for delegate
    // ========================================================================

    function nextPattern() as Void {
        _patternIndex = (_patternIndex + 1) % PATTERN_COUNT;
        _showName = 90; // Show name for ~3 seconds
    }

    function previousPattern() as Void {
        _patternIndex = _patternIndex - 1;
        if (_patternIndex < 0) {
            _patternIndex = PATTERN_COUNT - 1;
        }
        _showName = 90;
    }

    function toggleAutoCycle() as Void {
        _autoCycle = !_autoCycle;
        _autoCycleCounter = 0;
        _showName = 90;
    }

    function triggerManualBeat() as Void {
        _manualBeat = 5; // Flash for a few frames
    }
}
