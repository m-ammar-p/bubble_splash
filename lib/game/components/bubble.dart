import 'dart:math';
import 'dart:ui' as ui;

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

/// A floating bubble rendered as a glossy "Candy Cosmos" sphere (spec screen
/// 02): white specular at 34%/26% → light → mid → dark radial body, an outer
/// accent glow, and soft inner shading. Bombs are a translucent glass ball
/// with a cartoon bomb drawn inside (never an emoji — old Androids render
/// tofu). Behavior on tap/miss depends on [kind]; the game decides the
/// consequences.
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

  /// Minimum tappable radius in logical px. Small bubbles render below the 44px
  /// touch-target floor and the finger covers them, so the hit zone is expanded
  /// to at least this (visual size is unchanged).
  static const double _minHitRadius = 34;

  /// Reaction-lag compensation: the bubble rises while the fingertip lags
  /// ~100 ms behind, so taps on fast bubbles land *below* where the bubble now
  /// is. The hit zone is stretched downward by this many seconds of travel.
  static const double _lagCompSeconds = 0.10;

  /// Expand the tap zone beyond the visual radius for small bubbles. Without
  /// this, a radius-22 bubble has a 44px target the fingertip fully occludes.
  /// The zone is also a downward capsule ([_lagCompSeconds]) so aiming at
  /// where a fast bubble *was* still pops it.
  @override
  bool containsLocalPoint(Vector2 point) {
    final hit = max(radius, _minHitRadius);
    final dx = point.x - radius;
    var dy = point.y - radius;
    if (dy > 0) dy = max(0.0, dy - speed * _lagCompSeconds);
    return dx * dx + dy * dy <= hit * hit;
  }

  /// The orb's appearance depends only on (kind, color, radius), never on the
  /// frame, so it is painted once into an offscreen image (blurs and all) and
  /// blitted each frame. This removes the per-frame MaskFilter.blur ×3 and
  /// RadialGradient.createShader allocation that tanked the frame rate.
  ///
  /// Identical bubbles share one cached image: re-rasterizing + GPU-uploading a
  /// fresh image on *every spawn* (up to ~3/s) caused micro-jank. Radius is
  /// bucketed to 4px steps and the blit rect scales the ≲2px difference away.
  /// The cache lives on the game instance (see `BubbleSplashGame.spriteCache`)
  /// so overlapping game instances during a screen transition can't dispose
  /// each other's images; the game disposes its own cache when it detaches.
  ui.Image? _sprite;
  double _pad = 0;

  @override
  void onLoad() {
    _pad = radius * 0.4;
    final bucket = max(1, (radius / 4).round());
    final key = Object.hash(kind, paint.color.toARGB32(), bucket);
    var sprite = game.spriteCache[key];
    if (sprite == null) {
      sprite = _buildSprite(bucket * 4.0);
      if (sprite == null) return; // headless: keep cheap fallback in render()
      game.spriteCache[key] = sprite;
    }
    _sprite = sprite;
  }

  /// Paint the orb once at the bucketed radius [r] into a GPU-resident image.
  /// The glow halo bleeds past the circle, so the image is padded (same 0.4·r
  /// ratio as the blit rect, so scaling stays uniform). Returns null where no
  /// rasterizer exists (headless tests).
  ui.Image? _buildSprite(double r) {
    final pad = r * 0.4;
    final dim = (r * 2 + pad * 2).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(r + pad, r + pad);
    if (kind == BubbleKind.bomb) {
      _paintBomb(canvas, center, r);
    } else {
      _paintCandy(canvas, center, r);
    }
    final picture = recorder.endRecording();
    try {
      return picture.toImageSync(dim, dim);
    } catch (_) {
      return null;
    } finally {
      picture.dispose();
    }
  }

  /// Candy gloss recipe from the handoff:
  /// `radial-gradient(circle at 34% 26%, #FFF, light 20%, mid 54%, dark)` +
  /// outer accent glow + dark bottom-right / white top-left inner shading.
  /// Light/dark are derived from the palette color. Run once into the cache,
  /// at the bucketed radius [r].
  void _paintCandy(Canvas canvas, Offset center, double r) {
    final mid = paint.color;
    final hsl = HSLColor.fromColor(mid);
    final light =
        hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.24).clamp(0.0, 1.0)).toColor();

    // Outer accent glow (box-shadow 0 12px 34px accent .5).
    canvas.drawCircle(
      center.translate(0, r * 0.10),
      r,
      Paint()
        ..color = mid.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.28),
    );

    final bodyRect = Rect.fromCircle(center: center, radius: r);
    // Glossy body with the white specular baked into the gradient.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.48),
          radius: 1.0,
          colors: [Colors.white, light, mid, dark],
          stops: const [0.0, 0.20, 0.54, 1.0],
        ).createShader(bodyRect),
    );

    // Inner shading, clipped to the body.
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    // inset -6px -8px 16px dark — depth along the bottom-right rim.
    canvas.drawCircle(
      center.translate(-r * 0.10, -r * 0.14),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.30
        ..color = dark.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );
    // inset 5px 5px 12px white .42 — sheen along the top-left rim.
    canvas.drawCircle(
      center.translate(r * 0.08, r * 0.08),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..color = Colors.white.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.14),
    );
    canvas.restore();
  }

  /// Bomb: translucent glass ball with a cartoon bomb (dark body, highlight,
  /// fuse, orange spark) drawn inside. Run once into the cache, at the
  /// bucketed radius [rad].
  void _paintBomb(Canvas canvas, Offset center, double rad) {
    final bodyRect = Rect.fromCircle(center: center, radius: rad);

    // Glass ball: rgba(255,255,255,.35) → .10 30% → slate .10 60% → dark .20.
    canvas.drawCircle(
      center,
      rad,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.48),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.10),
            const Color(0xFF787896).withValues(alpha: 0.10),
            const Color(0xFF141024).withValues(alpha: 0.20),
          ],
          stops: const [0.0, 0.30, 0.60, 1.0],
        ).createShader(bodyRect),
    );
    // 1.5px rgba(255,255,255,.4) border.
    canvas.drawCircle(
      center,
      rad - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.40),
    );

    // Cartoon bomb body.
    final r = rad * 0.42;
    final bodyC = center.translate(0, rad * 0.12);
    canvas.drawCircle(bodyC, r, Paint()..color = const Color(0xFF33333D));
    // Specular highlight on the body.
    canvas.drawCircle(
      bodyC.translate(-r * 0.35, -r * 0.40),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    // Neck at the top of the body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: bodyC.translate(0, -r * 1.05),
          width: r * 0.55,
          height: r * 0.35,
        ),
        Radius.circular(r * 0.1),
      ),
      Paint()..color = const Color(0xFF33333D),
    );
    // Fuse: short curve up-right from the neck.
    final fuseStart = bodyC.translate(0, -r * 1.2);
    final fuseEnd = fuseStart.translate(r * 0.65, -r * 0.55);
    canvas.drawPath(
      Path()
        ..moveTo(fuseStart.dx, fuseStart.dy)
        ..quadraticBezierTo(
            fuseStart.dx + r * 0.55, fuseStart.dy, fuseEnd.dx, fuseEnd.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = rad * 0.07
        ..color = const Color(0xFF8A7A66),
    );
    // Orange spark at the fuse tip (soft glow + core).
    canvas.drawCircle(
      fuseEnd,
      rad * 0.16,
      Paint()
        ..color = const Color(0xFFFFB13D).withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.10),
    );
    canvas.drawCircle(
        fuseEnd, rad * 0.09, Paint()..color = const Color(0xFFFFB13D));
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite != null) {
      final dim = radius * 2 + _pad * 2;
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromLTWH(-_pad, -_pad, dim, dim),
        Paint()..filterQuality = FilterQuality.low,
      );
      return;
    }
    // Until the cached image is ready (~1 frame), draw a cheap flat orb — no
    // blur, no per-frame shader churn.
    final center = Offset(radius, radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = paint.color.withValues(alpha: 0.5),
    );
  }

  // No onRemove image dispose: _sprite is shared via the game's spriteCache,
  // which the game disposes wholesale in its own onRemove.

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
