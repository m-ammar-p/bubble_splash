import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../app/candy.dart';
import '../../game/bubble_splash_game.dart';

/// In-round heads-up display, stacked over the Flame [GameWidget]. Candy Cosmos
/// style (spec screen 02): glass close circle + banked-lives pill on the left,
/// glowing score pill in the center, three round hearts on the right, a live
/// combo pill below, and a sound pill bottom-right. Reads the game's
/// [ValueNotifier]s directly so it rebuilds only the affected pieces. All
/// surfaces are plain translucent fills (no BackdropFilter) — cheap to cache.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game, required this.onQuit});

  final BubbleSplashGame game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 20 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CloseButton(onTap: onQuit),
                SizedBox(width: 7 * s),
                const _LivesPill(),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, _) => _ScorePill(score: score),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.hp,
                  builder: (_, hp, _) =>
                      _RoundHearts(hp: hp, maxHp: BubbleSplashGame.maxHp),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            _ComboBar(game: game),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ValueListenableBuilder<bool>(
                valueListenable: game.soundOn,
                builder: (_, on, _) => _SoundToggle(on: on, onTap: game.toggleSound),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 34×34 glass circle with a white × — pause/quit (matches the meta headers'
/// [kCandyBackCircleSize]).
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: kCandyBackCircleSize * s,
        height: kCandyBackCircleSize * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Candy.glass(),
          border: Border.all(color: Candy.glassBorder()),
        ),
        child: Icon(Icons.close_rounded, color: Colors.white, size: 15 * s),
      ),
    );
  }
}

/// Center score: glass pill, Baloo 2 with a warm orange glow. Live value.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 15 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 5 * s),
      child: Text(
        '$score',
        style: Candy.display(
          size: 25 * s,
          height: 1.0,
          shadows: [
            Shadow(
                color: Candy.orange.withValues(alpha: 0.7),
                blurRadius: 16 * s),
          ],
        ),
      ),
    );
  }
}

/// Round HP as three hearts: filled (glowing red) or stroke-only when spent.
class _RoundHearts extends StatelessWidget {
  const _RoundHearts({required this.hp, required this.maxHp});
  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(hp),
      tween: Tween(begin: 1.35, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          maxHp,
          (i) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * s),
            child: i < hp
                ? Icon(
                    Icons.favorite,
                    color: Candy.heart,
                    size: 19 * s,
                    shadows: [
                      Shadow(
                          color: Candy.heart.withValues(alpha: 0.6),
                          blurRadius: 5 * s),
                    ],
                  )
                : Icon(
                    Icons.favorite_border,
                    color: Colors.white.withValues(alpha: 0.30),
                    size: 19 * s,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Live combo bar — the score multiplier is earned by popping the rare combo
/// power-up bubble (random ×2/×4/×6) and runs on a strict [comboDurationSeconds]
/// countdown. The draining meter reads like a game timer: it visibly shrinks,
/// **shifts to red as it empties** (clear "running out" cue) and **blinks** in
/// the last stretch; the instant it ends the pill **fades out with a poof** so
/// the player sees the combo finish. A fixed row height means nothing jumps.
class _ComboBar extends StatefulWidget {
  const _ComboBar({required this.game});
  final BubbleSplashGame game;

  @override
  State<_ComboBar> createState() => _ComboBarState();
}

class _ComboBarState extends State<_ComboBar>
    with TickerProviderStateMixin {
  /// Fires once when a combo ends, driving the fade-out "poof".
  late final AnimationController _endCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Clock for the low-fuel blink. Only ticks while a combo is active (gated in
  /// [_onTier]) — never a 24/7 ticker behind normal gameplay.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  int _lastTier = 0; // last live tier (tracks transitions)
  int _ghostTier = 1; // tier to show in the end poof

  /// Below this fuel fraction the bar goes red + blinks — "about to end".
  static const double _warnAt = 0.30;

  @override
  void initState() {
    super.initState();
    widget.game.comboTier.addListener(_onTier);
  }

  void _onTier() {
    final t = widget.game.comboTier.value;
    if (t > 0) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      _blink.stop();
      if (_lastTier > 0) {
        _ghostTier = _lastTier;
        _endCtrl.forward(from: 0);
      }
    }
    _lastTier = t;
  }

  @override
  void dispose() {
    widget.game.comboTier.removeListener(_onTier);
    _endCtrl.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// Tier tint: 2× pink, 4× violet, 6× hot orange — escalating "heat".
  static Color _tierColor(int tier) => switch (tier) {
        1 => Candy.pink,
        2 => Candy.violet,
        _ => Candy.orange,
      };

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return SizedBox(
      height: 42 * s, // reserved — active pill and empty state are the same size
      child: ValueListenableBuilder<int>(
        valueListenable: widget.game.comboTier,
        builder: (_, tier, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (tier > 0)
                ValueListenableBuilder<double>(
                  valueListenable: widget.game.comboFuel,
                  builder: (_, fuel, _) => _pill(s, tier, fuel),
                ),
              // End poof: the just-ended pill fades + scales up so the finish
              // is visible, not a silent disappearance.
              if (tier == 0)
                AnimatedBuilder(
                  animation: _endCtrl,
                  builder: (_, _) {
                    final v = _endCtrl.value;
                    if (v <= 0 || v >= 1) return const SizedBox.shrink();
                    return Opacity(
                      opacity: 1 - v,
                      child: Transform.scale(
                        scale: 1 + 0.2 * v,
                        child: _pill(s, _ghostTier, 0),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  /// The pill body for a given [tier] + [fuel] (0..1). Reused by the live bar
  /// and the end poof.
  Widget _pill(double s, int tier, double fuel) {
    final tierColor = _tierColor(tier);
    final low = fuel > 0 && fuel <= _warnAt;
    // Universal countdown color: green (full) → yellow → red (empty) via hue,
    // so the depleting line reads instantly as "time running out".
    final timerColor =
        HSVColor.fromAHSV(1, 120 * fuel.clamp(0.0, 1.0), 0.85, 1.0).toColor();
    // Blink the low-fuel bar between full and dim so it clearly pulses.
    final blinkAlpha = low ? (0.45 + 0.55 * _blink.value) : 1.0;

    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 5 * s, 14 * s, 5 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tierColor.withValues(alpha: 0.12),
        border: Border.all(color: tierColor.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: tierColor.withValues(alpha: 0.28), blurRadius: 18 * s),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CandyChip(
            colors: [
              Colors.white,
              tierColor,
              HSLColor.fromColor(tierColor)
                  .withLightness((HSLColor.fromColor(tierColor).lightness - 0.22)
                      .clamp(0.0, 1.0))
                  .toColor(),
            ],
            size: 26 * s,
            child: Icon(Icons.star_rounded, color: Colors.white, size: 17 * s),
          ),
          SizedBox(width: 8 * s),
          Text(
            '×${tier * 2}',
            style: Candy.display(
              color: Colors.white,
              size: 24 * s,
              height: 1.0,
              shadows: [
                Shadow(color: tierColor.withValues(alpha: 0.8), blurRadius: 14 * s),
              ],
            ),
          ),
          SizedBox(width: 10 * s),
          // Draining timer meter — a bright fill on a dark track that visibly
          // shrinks from full to empty (100→0), so the player sees the combo
          // about to end. Dark track = high contrast so the fill always reads.
          SizedBox(
            width: 128 * s,
            height: 14 * s,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  // Dark track.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1),
                      ),
                    ),
                  ),
                  // Bright depleting fill.
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fuel.clamp(0.0, 1.0),
                    child: Container(
                      margin: EdgeInsets.all(2 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: timerColor.withValues(alpha: blinkAlpha),
                        boxShadow: [
                          BoxShadow(
                              color: timerColor.withValues(alpha: 0.7 * blinkAlpha),
                              blurRadius: 10 * s),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banked lives (continues) available to revive a depleted round: glass pill
/// with a 24px heart chip. Shown so the player knows they can keep going.
class _LivesPill extends ConsumerWidget {
  const _LivesPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(livesControllerProvider.select((s) => s.count));
    final s = candyScale(context);
    return CandyGlass(
      padding: EdgeInsets.fromLTRB(3.5 * s, 3.5 * s, 10 * s, 3.5 * s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CandyChip(
            colors: Candy.livesChip,
            size: 22 * s,
            child: Icon(Icons.favorite, color: Colors.white, size: 12 * s),
          ),
          SizedBox(width: 6 * s),
          Text('$count',
              style: Candy.ui(size: 12 * s, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// 52×38 glass pill with a speaker icon, bottom-right.
class _SoundToggle extends StatelessWidget {
  const _SoundToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      onTap: onTap,
      radius: 999,
      width: 52 * s,
      height: 38 * s,
      alignment: Alignment.center,
      child: Icon(
        on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: on ? Colors.white : Colors.white38,
        size: 18 * s,
      ),
    );
  }
}
