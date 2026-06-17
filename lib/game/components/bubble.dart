import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../bubble_splash_game.dart';
import 'pop_effect.dart';
import 'score_popup.dart';

/// The kind of a bubble, which determines its reward and risk.
enum BubbleKind {
  /// Standard bubble — pop for points, miss to lose HP.
  normal,

  /// Worth bonus points + coins.
  golden,

  /// Popping it ends the round; letting it escape is harmless.
  bomb,
}

/// A floating bubble rendered as a translucent "liquid glass" sphere: a glassy
/// radial body, a bright rim light, a blurred specular hotspot and a sharp
/// glint, plus a soft colored refraction low on the orb. Behavior on tap/miss
/// depends on [kind]; the game decides the consequences.
class Bubble extends CircleComponent
    with TapCallbacks, HasGameReference<BubbleSplashGame> {
  Bubble({
    required this.kind,
    required double radius,
    required Vector2 position,
    required this.speed,
    required Color color,
  }) : super(
          radius: radius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = color,
        );

  final BubbleKind kind;

  /// Upward speed in logical pixels per second.
  final double speed;

  bool _resolved = false;

  @override
  Future<void> onLoad() async {
    if (kind == BubbleKind.bomb) {
      add(
        TextComponent(
          text: '💣',
          anchor: Anchor.center,
          position: Vector2(radius, radius),
          textRenderer: TextPaint(style: TextStyle(fontSize: radius)),
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final color = paint.color;

    // Outer glow halo (subtle, additive) so the orb feels lit.
    canvas.drawCircle(
      center,
      radius * 1.04,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
    );

    // Glass body: translucent in the middle, denser toward the rim.
    final bodyRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.62),
          ],
          stops: const [0.0, 0.68, 1.0],
        ).createShader(bodyRect),
    );

    // Bright rim light.
    canvas.drawCircle(
      center,
      radius - radius * 0.03,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Soft colored refraction, low-right.
    canvas.drawCircle(
      Offset(center.dx + radius * 0.26, center.dy + radius * 0.30),
      radius * 0.26,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.22),
    );

    // Blurred specular highlight, top-left.
    canvas.drawCircle(
      Offset(center.dx - radius * 0.30, center.dy - radius * 0.36),
      radius * 0.20,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.14),
    );

    // Sharp glint.
    canvas.drawCircle(
      Offset(center.dx - radius * 0.30, center.dy - radius * 0.40),
      radius * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;

    if (!_resolved && position.y + radius < 0) {
      _resolved = true;
      removeFromParent();
      game.onBubbleMissed(kind);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_resolved) return;
    _resolved = true;
    event.handled = true;
    game.add(PopEffect(position.clone(), paint.color));
    game.onBubblePopped(kind);
    // After scoring, surface the live multiplier as a floating "xN" label.
    if (kind != BubbleKind.bomb && game.multiplier >= 2) {
      game.add(ScorePopup(
        position: position.clone(),
        label: '${game.multiplier}X',
        color: const Color(0xFFFFD166),
      ));
    }
    removeFromParent();
  }
}
