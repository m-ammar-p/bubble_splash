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
            _ComboPill(comboNotifier: game.combo),
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

/// 38×38 glass circle with a white × — pause/quit.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38 * s,
        height: 38 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Candy.glass(),
          border: Border.all(color: Candy.glassBorder()),
        ),
        child: Icon(Icons.close_rounded, color: Colors.white, size: 17 * s),
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
      radius: 16 * s,
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
      child: Text(
        '$score',
        style: Candy.display(
          size: 28 * s,
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
                    size: 21 * s,
                    shadows: [
                      Shadow(
                          color: Candy.heart.withValues(alpha: 0.6),
                          blurRadius: 5 * s),
                    ],
                  )
                : Icon(
                    Icons.favorite_border,
                    color: Colors.white.withValues(alpha: 0.30),
                    size: 21 * s,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Live combo pill — "COMBO 3× ·12": multiplier (1 + combo ~/ 5) and chain
/// count straight from game state. Visible only while a combo is running.
class _ComboPill extends StatelessWidget {
  const _ComboPill({required this.comboNotifier});
  final ValueNotifier<int> comboNotifier;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return ValueListenableBuilder<int>(
      valueListenable: comboNotifier,
      builder: (_, combo, _) {
        if (combo < 2) return const SizedBox.shrink();
        final multiplier = 1 + combo ~/ 5;

        // Static pill — no per-frame scale/shake animation (it caused jank).
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Candy.heart.withValues(alpha: 0.10),
            border: Border.all(
                color: Candy.pink.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Candy.pink.withValues(alpha: 0.25),
                  blurRadius: 18 * s),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'COMBO',
                style: Candy.ui(
                  color: Candy.comboLabel,
                  size: 12 * s,
                  weight: FontWeight.w800,
                  letterSpacing: 3 * s,
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                '$multiplier×',
                style: Candy.display(
                  color: Candy.heart,
                  size: 26 * s,
                  height: 1.0,
                  shadows: [
                    Shadow(
                        color: Candy.heart.withValues(alpha: 0.6),
                        blurRadius: 14 * s),
                  ],
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                '·$combo',
                style: Candy.ui(
                  color: const Color(0xFFFF8296).withValues(alpha: 0.75),
                  size: 15 * s,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
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
      padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 11 * s, 4 * s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CandyChip(
            colors: Candy.livesChip,
            size: 24 * s,
            child: Icon(Icons.favorite, color: Colors.white, size: 13 * s),
          ),
          SizedBox(width: 7 * s),
          Text('$count',
              style: Candy.ui(size: 13 * s, weight: FontWeight.w800)),
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
