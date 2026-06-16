import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../domain/models/game_result.dart';
import 'components/bubble.dart';

/// The Flame engine for a single round. Deliberately Riverpod-free: it owns only
/// in-round state and reports the outcome via [onGameOver]. The meta layer
/// (rewards, high score, persistence, navigation) lives outside the game.
class BubbleSplashGame extends FlameGame {
  BubbleSplashGame({
    required this.palette,
    required this.onGameOver,
    bool soundOn = true,
  }) : soundOn = ValueNotifier(soundOn);

  /// Bubble colors, supplied by the equipped skin.
  final List<Color> palette;

  /// Called once when the round ends, with the round's outcome.
  final void Function(GameResult result) onGameOver;

  final Random _rng = Random();

  double _spawnTimer = 0;
  double get _spawnInterval => max(0.32, 0.85 - score.value * 0.01);

  /// Round HP: missing this many bubbles (or popping a bomb) ends the round.
  static const int maxHp = 3;

  /// Consecutive pops within this window keep the combo alive.
  static const double comboWindow = 1.4;
  double _comboTimer = 0;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> hp = ValueNotifier<int>(maxHp);
  final ValueNotifier<int> combo = ValueNotifier<int>(0);
  final ValueNotifier<bool> soundOn;

  bool isGameOver = false;

  // Round tallies reported in the GameResult.
  int _bubblesPopped = 0;
  int _goldenPopped = 0;
  int _maxCombo = 0;

  /// Score multiplier from the current combo (1x, 2x at 5, 3x at 10, …).
  int get multiplier => 1 + combo.value ~/ 5;

  // Transparent so the shared LiquidBackground (and its glowing orbs) shows
  // through behind the glass bubbles for a cohesive look.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnBubble();
    }

    if (combo.value > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) combo.value = 0;
    }
  }

  void _spawnBubble() {
    final radius = 22 + _rng.nextDouble() * 26;
    final x = radius + _rng.nextDouble() * (size.x - 2 * radius);
    final speed = 70 + _rng.nextDouble() * 110 + score.value * 1.5;

    final roll = _rng.nextDouble();
    final kind = roll < 0.08
        ? BubbleKind.bomb
        : roll < 0.20
            ? BubbleKind.golden
            : BubbleKind.normal;
    final color = switch (kind) {
      BubbleKind.golden => const Color(0xFFFFD700),
      BubbleKind.bomb => const Color(0xFF37474F),
      BubbleKind.normal => palette[_rng.nextInt(palette.length)],
    };

    add(
      Bubble(
        kind: kind,
        radius: radius,
        position: Vector2(x, size.y + radius),
        speed: speed,
        color: color,
      ),
    );
  }

  /// Called by a [Bubble] when the player taps it.
  void onBubblePopped(BubbleKind kind) {
    if (isGameOver) return;

    if (kind == BubbleKind.bomb) {
      // Popping a bomb is a mistake — it ends the round immediately.
      _play('game_over.wav');
      _endRound();
      return;
    }

    combo.value++;
    _comboTimer = comboWindow;
    _maxCombo = max(_maxCombo, combo.value);
    _bubblesPopped++;

    var gained = multiplier;
    if (kind == BubbleKind.golden) {
      _goldenPopped++;
      gained += 5; // golden bonus
    }
    score.value += gained;
    _play('pop.wav');
  }

  /// Called by a [Bubble] when it floats off the top unpopped. Bombs are safe
  /// to let escape; only missed scoring bubbles cost HP.
  void onBubbleMissed(BubbleKind kind) {
    if (isGameOver || kind == BubbleKind.bomb) return;
    combo.value = 0;
    hp.value--;
    if (hp.value <= 0) _endRound();
  }

  void toggleSound() => soundOn.value = !soundOn.value;

  void _endRound() {
    if (isGameOver) return;
    isGameOver = true;
    onGameOver(
      GameResult(
        score: score.value,
        bubblesPopped: _bubblesPopped,
        maxCombo: _maxCombo,
        goldenPopped: _goldenPopped,
      ),
    );
  }

  void _play(String file) {
    if (!isMounted || !soundOn.value) return;
    try {
      FlameAudio.play(file);
    } catch (_) {/* ignore audio failures (e.g. headless) */}
  }

  @override
  Future<void> onLoad() async {
    try {
      await FlameAudio.audioCache.loadAll(['pop.wav', 'game_over.wav']);
    } catch (_) {/* no audio backend */}
  }
}
