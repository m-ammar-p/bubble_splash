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
    required this.onContinueOffer,
    bool soundOn = true,
  }) : soundOn = ValueNotifier(soundOn);

  /// Bubble colors, supplied by the equipped skin.
  final List<Color> palette;

  /// Called once when the round ends for good, with the round's outcome.
  final void Function(GameResult result) onGameOver;

  /// Called when round HP is depleted, before the round ends. The screen offers
  /// the player a *continue* (spend a banked life / watch an ad). The game is
  /// paused meanwhile; the screen then calls [continueRound] or [finishRound].
  final void Function() onContinueOffer;

  /// True while the continue prompt is up: the loop is paused and taps/misses
  /// are ignored until the player decides.
  bool _awaitingDecision = false;

  final Random _rng = Random();

  double _spawnTimer = 0;
  double get _spawnInterval => max(0.32, 0.85 - score.value * 0.01);

  /// Head-start breather after a continue: the screen is cleared and no bubbles
  /// spawn for this long, but difficulty (spawn speed, derived from score) is
  /// unchanged. Counts down in [update].
  static const double headStartSeconds = 3;
  double _grace = 0;

  /// Round HP: missing this many bubbles (or popping a bomb) ends the round.
  static const int maxHp = 3;

  /// Consecutive pops within this window keep the combo alive.
  static const double comboWindow = 1.4;
  double _comboTimer = 0;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> hp = ValueNotifier<int>(maxHp);
  final ValueNotifier<int> combo = ValueNotifier<int>(0);
  final ValueNotifier<bool> soundOn;

  /// Seconds left in the post-continue head-start (0 when not counting down).
  /// Drives the on-screen "3·2·1" overlay so the player knows when play resumes.
  final ValueNotifier<int> headStart = ValueNotifier<int>(0);

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
    if (isGameOver || _awaitingDecision) return;

    if (_grace > 0) {
      _grace -= dt; // head-start: hold spawns briefly after a continue
      final secs = _grace > 0 ? _grace.ceil() : 0;
      if (headStart.value != secs) headStart.value = secs;
    } else {
      if (headStart.value != 0) headStart.value = 0;
      _spawnTimer += dt;
      if (_spawnTimer >= _spawnInterval) {
        _spawnTimer = 0;
        _spawnBubble();
      }
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
    if (isGameOver || _awaitingDecision) return;

    if (kind == BubbleKind.bomb) {
      // Popping a bomb is a mistake — it depletes the round (continue offered).
      _play('game_over.wav');
      _offerContinue();
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
    if (isGameOver || _awaitingDecision || kind == BubbleKind.bomb) return;
    combo.value = 0;
    hp.value--;
    if (hp.value <= 0) _offerContinue();
  }

  void toggleSound() => soundOn.value = !soundOn.value;

  /// Round HP depleted: pause the loop and ask the screen for a continue.
  void _offerContinue() {
    if (isGameOver || _awaitingDecision) return;
    _awaitingDecision = true;
    if (isMounted) pauseEngine(); // guard: no game loop in headless tests
    onContinueOffer();
  }

  /// Player spent a life / watched an ad to revive: restore HP, clear the
  /// screen, and grant a brief head-start before bubbles return. Difficulty
  /// (spawn speed) is preserved — only the screen is reset.
  void continueRound() {
    if (isGameOver || !_awaitingDecision) return;
    _awaitingDecision = false;
    hp.value = maxHp;
    combo.value = 0;
    for (final bubble in children.whereType<Bubble>().toList()) {
      bubble.removeFromParent();
    }
    _spawnTimer = 0;
    _grace = headStartSeconds;
    headStart.value = headStartSeconds.ceil();
    if (isMounted) resumeEngine();
  }

  /// Player declined to continue: finalize the round (emits the result).
  void finishRound() {
    if (isGameOver) return;
    _awaitingDecision = false;
    _endRound();
  }

  late final AudioPool _popPool;
  bool _poolsLoaded = false;

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
    if (!isMounted || !soundOn.value || !_poolsLoaded) return;
    try {
      if (file == 'pop.wav') {
        _popPool.start();
      } else {
        FlameAudio.play(file);
      }
    } catch (_) {/* ignore audio failures (e.g. headless) */}
  }

  @override
  Future<void> onLoad() async {
    try {
      await FlameAudio.audioCache.loadAll(['pop.wav', 'game_over.wav']);
      _popPool = await FlameAudio.createPool('pop.wav', minPlayers: 1, maxPlayers: 5);
      _poolsLoaded = true;
    } catch (_) {/* no audio backend */}
  }
}
