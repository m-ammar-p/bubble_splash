import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A short-lived multiplier label (e.g. "2X") that floats up and fades out after
/// a pop. Deliberately cheap: no blur, no shake — just a rising, fading glyph,
/// rendered on the game root in screen coordinates like [PopEffect].
///
/// The glyph is laid out and rasterized ONCE in [onLoad] and blitted with a
/// per-frame alpha; the previous version rebuilt a `TextPaint` (a full text
/// layout) every frame per popup, which stacked into jank during combos.
class ScorePopup extends PositionComponent {
  ScorePopup({
    required Vector2 position,
    required this.label,
    required this.color,
  }) : super(position: position, anchor: Anchor.center, priority: 100);

  final String label;
  final Color color;

  static const double _life = 0.7;
  double _t = 0;

  ui.Image? _img;

  @override
  void onLoad() {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = 6.0; // room for the shadow blur to bleed
    final dimW = (painter.width + pad * 2).ceil();
    final dimH = (painter.height + pad * 2).ceil();
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Offset(pad, pad));
    painter.dispose();
    final picture = recorder.endRecording();
    try {
      _img = picture.toImageSync(dimW, dimH);
    } catch (_) {/* headless: render() falls back to per-frame text */} finally {
      picture.dispose();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 70 * dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _t / _life).clamp(0.0, 1.0);
    final img = _img;
    if (img != null) {
      final w = img.width.toDouble();
      final h = img.height.toDouble();
      // paint.color's alpha modulates the image — fade without re-layout.
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, w, h),
        Rect.fromLTWH(-w / 2, -h / 2, w, h),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
      return;
    }
    // Headless fallback (no rasterizer): the old per-frame path.
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
    ).render(canvas, label, Vector2.zero(), anchor: Anchor.center);
  }

  @override
  void onRemove() {
    _img?.dispose();
    _img = null;
    super.onRemove();
  }
}
