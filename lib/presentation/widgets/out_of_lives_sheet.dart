import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/providers.dart';
import '../../app/theme.dart';
import 'glass.dart';
import 'primary_button.dart';
import 'status_badges.dart';

/// Shown when the player tries to play with no lives left. Offers to wait for
/// the regen countdown or watch a (fake) rewarded ad for an instant life.
Future<void> showOutOfLivesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OutOfLivesSheet(),
  );
}

class _OutOfLivesSheet extends ConsumerWidget {
  const _OutOfLivesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    ref.watch(livesTickerProvider); // tick the countdown
    final until = ref.read(livesControllerProvider.notifier).untilNextLife();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassPanel(
        radius: 28,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.heart_broken, color: AppColors.heart, size: 48),
          const SizedBox(height: 12),
          Text(
            lives.count > 0 ? 'Ready to play!' : 'Out of lives',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            until == null
                ? 'Your lives are full.'
                : 'Next life in ${LivesBadge.formatDuration(until)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Watch ad for a life',
            icon: Icons.ondemand_video,
            onPressed: lives.isFull
                ? null
                : () async {
                    final earned = await ref
                        .read(rewardedAdServiceProvider)
                        .showRewardedAd();
                    if (earned) {
                      ref.read(livesControllerProvider.notifier).addLife();
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later',
                style: TextStyle(color: Colors.white54)),
          ),
          ],
        ),
      ),
    );
  }
}
