import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../app/candy.dart';

/// The Candy Cosmos nebula painted INSIDE the game canvas, as one cached
/// full-screen image blitted per frame. Replaces the separate
/// `CandyNebulaBackground` widget layer under the (transparent) `GameWidget` —
/// compositing two full-screen layers per frame doubled the fill cost on
/// fill-rate-bound low-end GPUs. Gradient specs must stay in sync with
/// [CandyNebulaBackground] (single source of visual truth for the stage).
class NebulaBackdrop extends PositionComponent {
  NebulaBackdrop() : super(priority: -1000);

  ui.Image? _img;
  Vector2 _builtFor = Vector2.zero();

  /// Current screen size (kept even when the image can't be built, so the
  /// headless fallback still covers the stage).
  Vector2 _screen = Vector2.zero();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _screen = size.clone();
    if (_builtFor == size) return;
    _img?.dispose();
    _img = _build(size);
    if (_img != null) _builtFor = size.clone();
  }

  ui.Image? _build(Vector2 size) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // linear-gradient(160deg, #2C1256, #170B38 55%, #100728)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.5, -1.0),
          end: Alignment(0.5, 1.0),
          colors: [Candy.bgTop, Candy.bgMid, Candy.bgBottom],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // Pink nebula glow at 18% 2%.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.64, -0.96),
          radius: 1.1,
          colors: [Color(0x4DFF6B8B), Color(0x00FF6B8B)],
          stops: [0.0, 0.55],
        ).createShader(rect),
    );
    // Orange nebula glow at 92% 16%.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.84, -0.68),
          radius: 1.2,
          colors: [Color(0x3DFF9D3D), Color(0x00FF9D3D)],
          stops: [0.0, 0.55],
        ).createShader(rect),
    );
    final picture = recorder.endRecording();
    try {
      return picture.toImageSync(size.x.ceil(), size.y.ceil());
    } catch (_) {
      return null; // headless: render() falls back to a flat fill
    } finally {
      picture.dispose();
    }
  }

  @override
  void render(Canvas canvas) {
    final img = _img;
    if (img == null) {
      // No rasterizer (headless) or not built yet: flat stage color.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _screen.x, _screen.y),
        Paint()..color = Candy.bgBottom,
      );
      return;
    }
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, 0, _screen.x, _screen.y),
      Paint(),
    );
  }

  @override
  void onRemove() {
    _img?.dispose();
    _img = null;
    super.onRemove();
  }
}
