import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../app/theme.dart';
import '../../game/bubble_splash_game.dart';
import 'glass.dart';

/// In-round heads-up display, stacked over the Flame [GameWidget]. Reads the
/// game's [ValueNotifier]s directly so it rebuilds only the affected pieces.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game, required this.onQuit});

  final BubbleSplashGame game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassCircleButton(
                  icon: Icons.close_rounded,
                  onTap: onQuit,
                ),
                const SizedBox(width: 8),
                const _LivesIndicator(),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, _) => _ScoreDisplay(score: score),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.hp,
                  builder: (_, hp, _) =>
                      _HpDisplay(hp: hp, maxHp: BubbleSplashGame.maxHp),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ComboDisplay(comboNotifier: game.combo),
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

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 22,
      blur: 16,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          shadows: [
            Shadow(color: AppColors.accent, blurRadius: 20),
            Shadow(color: AppColors.accent, blurRadius: 8),
          ],
        ),
      ),
    );
  }
}

class _HpDisplay extends StatelessWidget {
  const _HpDisplay({required this.hp, required this.maxHp});
  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < hp ? Icons.favorite : Icons.favorite_border,
              color: i < hp
                  ? (hp == 1
                      ? AppColors.heart
                      : AppColors.heart.withValues(alpha: 0.85))
                  : Colors.white24,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComboDisplay extends StatelessWidget {
  const _ComboDisplay({required this.comboNotifier});
  final ValueNotifier<int> comboNotifier;

  static const _colors = [
    AppColors.gold,
    Color(0xFFFF8C00), // orange
    Color(0xFFFF4444), // hot red
    AppColors.heart,   // neon pink
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: comboNotifier,
      builder: (_, combo, _) {
        if (combo < 2) return const SizedBox.shrink();
        final level = (combo ~/ 5).clamp(0, 3);
        final color = _colors[level];

        // Static pill — no per-frame scale/shake animation (it caused jank).
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: color.withValues(alpha: 0.12),
            border:
                Border.all(color: color.withValues(alpha: 0.50), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COMBO',
                style: TextStyle(
                  color: color.withValues(alpha: 0.70),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${1 + level}×',
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·$combo',
                style: TextStyle(
                  color: color.withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Banked lives (continues) available to revive a depleted round. Shown in the
/// game area so the player knows they can keep going.
class _LivesIndicator extends ConsumerWidget {
  const _LivesIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(livesControllerProvider.select((s) => s.count));
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count > 0 ? Icons.favorite : Icons.favorite_border,
            color: count > 0 ? AppColors.heart : Colors.white30,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: on ? Colors.white70 : Colors.white30,
          size: 20,
        ),
      ),
    );
  }
}
