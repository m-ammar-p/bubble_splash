import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/profile_controller.dart';
import '../../app/theme.dart';
import '../../domain/models/lives_state.dart';
import 'glass.dart';

/// Coin balance pill.
class CoinBadge extends ConsumerWidget {
  const CoinBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.coins));
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Level pill.
class LevelBadge extends ConsumerWidget {
  const LevelBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(profileControllerProvider.select((p) => p.level));
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          Text('Lv $level',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Lives pill: hearts plus a live countdown to the next regenerated life.
class LivesBadge extends ConsumerWidget {
  const LivesBadge({super.key});

  static String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    // Rebuild every second so the countdown ticks.
    ref.watch(livesTickerProvider);
    final until = ref.read(livesControllerProvider.notifier).untilNextLife();

    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: AppColors.heart, size: 18),
          const SizedBox(width: 6),
          Text('${lives.count}/${LivesState.maxLives}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          if (until != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.schedule, color: Colors.white54, size: 14),
            const SizedBox(width: 3),
            Text(formatDuration(until),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
