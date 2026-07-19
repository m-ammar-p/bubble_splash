import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../domain/models/game_result.dart';
import 'components/bubble.dart';
import 'components/nebula_backdrop.dart';

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

  /// Exposed so the host screen can re-pause the engine if the app is
  /// foregrounded mid-prompt (Flame auto-resumes on foreground; without this the
  /// loop would run behind the continue sheet / ad overlay).
  bool get isAwaitingDecision => _awaitingDecision;

  final Random _rng = Random();

  double _spawnTimer = 0;
  double get _spawnInterval => spawnIntervalFor(score.value);

  // Difficulty ramps toward a plateau instead of growing forever. Both curves
  // use `1 - exp(-score/k)`, which matches the old linear ramp's initial slope
  // (the early game feels identical) but flattens out at a fixed ceiling —
  // long runs stay playable instead of becoming impossible (retention).
  static const double _baseSpeed = 70;
  static const double _speedJitter = 110;
  /// Speed bonus ceiling: score never adds more than this many px/s.
  static const double _speedRampMax = 240;
  /// Initial slope `_speedRampMax / _speedRampK` = 1.5 px/s per point (as before).
  static const double _speedRampK = 160;
  /// Spawn interval floor — never spawns faster than this.
  static const double _minSpawnInterval = 0.38;

  /// Extra upward speed earned from [score]; asymptotically approaches
  /// [_speedRampMax]. Pure function so the cap is unit-testable.
  static double rampSpeedBonus(int score) =>
      _speedRampMax * (1 - exp(-score / _speedRampK));

  /// Seconds between spawns at [score]; eases from 0.85 down to
  /// [_minSpawnInterval] (initial slope 0.01 s/point, as before).
  static double spawnIntervalFor(int score) =>
      _minSpawnInterval + (0.85 - _minSpawnInterval) * exp(-score / 47.0);

  /// Max bubbles on screen at once. One finger can't clear an avalanche: past
  /// this the spawner waits for pops/escapes, so density stays humanly
  /// clearable even at the spawn-rate floor (retention, not mercy).
  static const int _maxOnScreen = 6;

  /// Post-continue mercy: speed multiplier applied to spawned bubbles. Set to
  /// [reliefFactor] (50% slower) by [continueRound] — the player just died at
  /// full speed, so restarting there means an instant second death — then
  /// recovers linearly back to 1.0 over [reliefRecoverySeconds] of play.
  double _speedRelief = 1.0;
  static const double reliefFactor = 0.5;
  static const double reliefRecoverySeconds = 45;

  /// Current mercy multiplier (1.0 = full speed). Exposed for tests.
  @visibleForTesting
  double get speedRelief => _speedRelief;

  /// One recovery step: relief climbs linearly from [reliefFactor] back to
  /// 1.0 over [reliefRecoverySeconds] of play. Pure so it's unit-testable.
  static double recoverRelief(double relief, double dt) =>
      min(1.0, relief + dt * (1.0 - reliefFactor) / reliefRecoverySeconds);

  /// Head-start breather after a continue: the screen is cleared and no bubbles
  /// spawn for this long, but difficulty (spawn speed, derived from score) is
  /// unchanged. Counts down in [update].
  static const double headStartSeconds = 3;
  double _grace = 0;

  /// Round HP: missing this many bubbles (or popping a bomb) ends the round.
  static const int maxHp = 3;

  /// Consecutive pops within this window keep the streak alive. The streak is a
  /// *stat only* (feeds [GameResult.maxCombo]); it no longer drives scoring —
  /// the score multiplier now comes solely from the combo power-up bubble.
  static const double comboWindow = 1.4;
  double _comboTimer = 0;

  // ── Combo power-up (the score multiplier) ──────────────────────────────────
  // The multiplier is NOT earned by chaining pops. A rare "combo bubble" spawns
  // on a timed cadence; popping it sets a RANDOM tier (×2/×4/×6) and refills a
  // fuel bar that then drains on a strict countdown — scoring pops do NOT extend
  // it. When the bar empties, the multiplier resets to 1×.

  /// Multiplier tiers: tier t → t*2 ×. Capped at 3 (×6).
  static const int maxComboTier = 3;

  /// Seconds the combo lasts. A strict countdown from the last combo-bubble
  /// pop — scoring pops do NOT extend it (time-pressure window, competitive).
  static const double comboDurationSeconds = 5.0;

  /// Min/max seconds between combo-bubble spawns — rare, one at a time, a treat.
  static const double comboBubbleMinGap = 25;
  static const double comboBubbleMaxGap = 35;

  double _comboBubbleTimer = 0;
  late double _nextComboBubbleAt = _rollComboGap();
  double _rollComboGap() =>
      comboBubbleMinGap +
      _rng.nextDouble() * (comboBubbleMaxGap - comboBubbleMinGap);

  /// Current multiplier tier (0 = inactive, else 1–[maxComboTier]).
  final ValueNotifier<int> comboTier = ValueNotifier<int>(0);

  /// Combo bar fill, 0..1. Drives the draining meter in the HUD. Published in
  /// coarse [_fuelSteps] increments (the meter is ~128px wide, so steps stay
  /// visually smooth) — a raw per-frame publish rebuilt the HUD pill 60×/s
  /// for the whole combo window.
  final ValueNotifier<double> comboFuel = ValueNotifier<double>(0);

  /// Frame-accurate fuel; [comboFuel] is its quantized public mirror.
  double _comboFuelRaw = 0;
  static const int _fuelSteps = 64;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> hp = ValueNotifier<int>(maxHp);

  /// Consecutive-pop streak — a round stat (max feeds [GameResult.maxCombo]),
  /// surfaced live nowhere now that the multiplier is combo-bubble driven.
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

  /// Active score multiplier: 1× normally, else the combo tier ×2 (2/4/6).
  int get multiplier => comboTier.value > 0 ? comboTier.value * 2 : 1;

  // The nebula stage is painted inside the canvas (see [NebulaBackdrop]), so
  // one full-screen layer covers background + gameplay — a transparent canvas
  // over a separate background widget cost a second full-screen blend every
  // frame on fill-rate-bound low-end GPUs.
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
      // Post-continue mercy fades back to full speed while actually playing.
      if (_speedRelief < 1.0) {
        _speedRelief = recoverRelief(_speedRelief, dt);
      }
      _spawnTimer += dt;
      if (_spawnTimer >= _spawnInterval) {
        _spawnTimer = 0;
        // Density cap: past _maxOnScreen bubbles, wait for pops/escapes
        // instead of stacking an unclearable avalanche.
        if (children.whereType<Bubble>().length < _maxOnScreen) {
          _spawnBubble();
        }
      }

      // Combo bubble: rare, timed, one at a time (doesn't count toward the
      // density cap so the reward is never starved out by a crowded screen).
      _comboBubbleTimer += dt;
      if (_comboBubbleTimer >= _nextComboBubbleAt &&
          !children.whereType<Bubble>().any((b) => b.kind == BubbleKind.combo)) {
        _comboBubbleTimer = 0;
        _nextComboBubbleAt = _rollComboGap();
        _spawnComboBubble();
      }
    }

    // Streak (stat only) times out; multiplier is combo-bubble driven.
    if (combo.value > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) combo.value = 0;
    }

    // Combo bar drains while active; empty → multiplier back to 1×. The raw
    // value drains frame-accurately; the notifier only publishes 1/64 steps
    // (ceil, so it reaches 0 exactly when the raw fuel does).
    if (comboTier.value > 0) {
      _comboFuelRaw =
          (_comboFuelRaw - dt / comboDurationSeconds).clamp(0.0, 1.0);
      final quantized = (_comboFuelRaw * _fuelSteps).ceilToDouble() / _fuelSteps;
      if (quantized != comboFuel.value) comboFuel.value = quantized;
      if (_comboFuelRaw <= 0) comboTier.value = 0;
    }
  }

  void _spawnBubble() {
    final radius = 22 + _rng.nextDouble() * 26;
    final x = radius + _rng.nextDouble() * (size.x - 2 * radius);
    final speed = (_baseSpeed +
            _rng.nextDouble() * _speedJitter +
            rampSpeedBonus(score.value)) *
        _speedRelief;

    final roll = _rng.nextDouble();
    final kind = roll < 0.08
        ? BubbleKind.bomb
        : roll < 0.20
            ? BubbleKind.golden
            : BubbleKind.normal;
    final color = switch (kind) {
      BubbleKind.golden => const Color(0xFFFFD700),
      BubbleKind.bomb => const Color(0xFF37474F),
      BubbleKind.combo => const Color(0xFFFF6B8B), // unreached here
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

  /// Spawn the rare combo power-up: large (easy to see + tap) and slower than a
  /// normal bubble (relief-scaled, no score ramp) so the player has time to
  /// reach the treat before it escapes.
  void _spawnComboBubble() {
    const radius = 42.0;
    final x = radius + _rng.nextDouble() * (size.x - 2 * radius);
    final speed = (_baseSpeed + 20) * 0.7 * _speedRelief;
    add(
      Bubble(
        kind: BubbleKind.combo,
        radius: radius,
        position: Vector2(x, size.y + radius),
        speed: speed,
        color: const Color(0xFFFF3D8B), // hot pink core; sprite adds the glow
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

    if (kind == BubbleKind.combo) {
      // Combo power-up: roll a RANDOM tier (×2/×4/×6) and refill the bar — each
      // combo bubble is its own gamble, not a fixed 2→4→6 ladder. Doesn't touch
      // the streak or count as a scoring pop — it's the reward itself.
      comboTier.value = 1 + _rng.nextInt(maxComboTier);
      _comboFuelRaw = 1.0;
      comboFuel.value = 1.0;
      _play('pop.wav');
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
    // No top-up: the combo is a strict [comboDurationSeconds] countdown. Only
    // popping another combo bubble refreshes it (and bumps the tier), so the
    // multiplier is a real time-pressure window, not a self-sustaining state.
    _play('pop.wav');
  }

  /// Called by a [Bubble] when it floats off the top unpopped. Bombs and combo
  /// power-ups are safe to let escape; only missed scoring bubbles cost HP.
  void onBubbleMissed(BubbleKind kind) {
    if (isGameOver ||
        _awaitingDecision ||
        kind == BubbleKind.bomb ||
        kind == BubbleKind.combo) {
      return;
    }
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
  /// screen, and grant a brief head-start before bubbles return. Bubbles
  /// resume at [reliefFactor] (50%) of the score-derived speed — the player
  /// just died at full speed — then recover to full over
  /// [reliefRecoverySeconds]; score/progression are untouched.
  void continueRound() {
    if (isGameOver || !_awaitingDecision) return;
    _awaitingDecision = false;
    hp.value = maxHp;
    combo.value = 0;
    comboTier.value = 0;
    _comboFuelRaw = 0;
    comboFuel.value = 0;
    _comboBubbleTimer = 0;
    _nextComboBubbleAt = _rollComboGap();
    _speedRelief = reliefFactor;
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
    add(NebulaBackdrop());
    _warmSpriteCache();
    try {
      await FlameAudio.audioCache.loadAll(['pop.wav', 'game_over.wav']);
      _popPool = await FlameAudio.createPool('pop.wav', minPlayers: 1, maxPlayers: 5);
      _poolsLoaded = true;
    } catch (_) {/* no audio backend */}
  }

  /// Rasterize every reachable bubble sprite up front (~50 small images, one
  /// pass at round start) so a first spawn of a new (kind, color, size) combo
  /// never hitches mid-play on `toImageSync` + first-use GPU upload. No-ops
  /// headlessly (buildSprite returns null without a rasterizer).
  void _warmSpriteCache() {
    // Spawn radii are 22–48 (normal/golden/bomb) → buckets 6..12; combo is 42.
    const minBucket = 6, maxBucket = 12;
    final variants = <(BubbleKind, Color)>[
      for (final c in palette) (BubbleKind.normal, c),
      (BubbleKind.golden, const Color(0xFFFFD700)),
      (BubbleKind.bomb, const Color(0xFF37474F)),
    ];
    for (final (kind, color) in variants) {
      for (var bucket = minBucket; bucket <= maxBucket; bucket++) {
        final key = Bubble.spriteKey(kind, color, bucket);
        if (spriteCache.containsKey(key)) continue;
        final img = Bubble.buildSprite(kind, color, bucket * 4.0);
        if (img == null) return; // headless — nothing to warm
        spriteCache[key] = img;
      }
    }
    const comboColor = Color(0xFFFF3D8B);
    final comboBucket = Bubble.bucketFor(42);
    final comboKey = Bubble.spriteKey(BubbleKind.combo, comboColor, comboBucket);
    if (!spriteCache.containsKey(comboKey)) {
      final img = Bubble.buildSprite(BubbleKind.combo, comboColor, comboBucket * 4.0);
      if (img != null) spriteCache[comboKey] = img;
    }
  }

  /// Rasterized bubble sprites shared across [Bubble]s, keyed on
  /// (kind, color, radius bucket). Instance-scoped (not static) so overlapping
  /// game instances during a screen transition can't dispose each other's
  /// images. Populated lazily by `Bubble.onLoad`, freed in [onRemove].
  final Map<int, ui.Image> spriteCache = {};

  @override
  void onRemove() {
    for (final image in spriteCache.values) {
      image.dispose();
    }
    spriteCache.clear();
    super.onRemove();
  }
}
