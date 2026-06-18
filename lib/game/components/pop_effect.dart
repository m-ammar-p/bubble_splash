import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

final _rng = Random();

/// The "liquid glass shatter" shown when a bubble pops: a bright color flash, an
/// expanding shockwave ring, and a burst of glowing glass droplets that fly out
/// and fall under gravity. Removes itself once everything has faded.
class PopEffect extends PositionComponent {
  PopEffect(Vector2 position, this.color) {
    this.position = position;
  }

  final Color color;

  @override
  Future<void> onLoad() async {
    add(_Flash(color));
    add(_Shockwave(color));
    const count = 12;
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.62,
          generator: (i) {
            final angle = (i / count) * 2 * pi + _rng.nextDouble() * 0.4;
            final speed = 90 + _rng.nextDouble() * 150;
            final dropRadius = 2.0 + _rng.nextDouble() * 3.0;
            return AcceleratedParticle(
              acceleration: Vector2(0, 360), // gravity
              speed: Vector2(cos(angle), sin(angle)) * speed,
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final p = particle.progress;
                  final fade = (1 - p).clamp(0.0, 1.0);
                  // Colored additive glow — plain circle, no per-frame blur
                  // (gaussian blur here stacked badly during combos).
                  canvas.drawCircle(
                    Offset.zero,
                    dropRadius * 1.9,
                    Paint()
                      ..color = color.withValues(alpha: fade * 0.4)
                      ..blendMode = BlendMode.plus,
                  );
                  // Bright glassy core.
                  canvas.drawCircle(
                    Offset.zero,
                    dropRadius * (1 - p * 0.5),
                    Paint()
                      ..color = Color.lerp(Colors.white, color, 0.35)!
                          .withValues(alpha: fade),
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    // Clean up the container once all effects have run.
    add(RemoveEffect(delay: 0.7));
  }
}

/// A quick bright flash at the pop point.
class _Flash extends PositionComponent {
  _Flash(this.color);
  final Color color;
  static const _dur = 0.18;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _dur).clamp(0.0, 1.0);
    final r = 14 * (1 + p);
    // Additive flash, no gaussian blur — soft edge comes from a radial fade.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(Colors.white, color, p)!
                .withValues(alpha: (1 - p) * 0.85),
            Color.lerp(Colors.white, color, p)!.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
        ..blendMode = BlendMode.plus,
    );
  }
}

/// An expanding ring that fades as it grows.
class _Shockwave extends PositionComponent {
  _Shockwave(this.color);
  final Color color;
  static const _dur = 0.42;
  static const _maxR = 78.0;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _dur).clamp(0.0, 1.0);
    final r = _maxR * Curves.easeOut.transform(p);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - p) + 0.5
        ..color = color.withValues(alpha: (1 - p) * 0.6)
        ..blendMode = BlendMode.plus,
    );
  }
}
