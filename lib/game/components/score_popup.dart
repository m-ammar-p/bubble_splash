import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A short-lived multiplier label (e.g. "2X") that floats up and fades out after
/// a pop. Deliberately cheap: no blur, no shake — just a rising, fading glyph,
/// rendered on the game root in screen coordinates like [PopEffect].
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
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: 30,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: alpha * 0.5), blurRadius: 4),
        ],
      ),
    ).render(canvas, label, Vector2.zero(), anchor: Anchor.center);
  }
}
