import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_session_controller.dart';
import '../../application/profile_controller.dart';
import '../../application/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/game_result.dart';
import 'glass.dart';
import 'primary_button.dart';

/// The end-of-round results panel, shown over the game. Surfaces the score vs
/// best, coins/XP earned, level-ups and unlocked achievements, plus retention
/// hooks: watch-ad-to-double-coins and play-again.
class ResultsOverlay extends ConsumerStatefulWidget {
  const ResultsOverlay({
    super.key,
    required this.summary,
    required this.onPlayAgain,
    required this.onHome,
  });

  final RewardSummary summary;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  @override
  ConsumerState<ResultsOverlay> createState() => _ResultsOverlayState();
}

class _ResultsOverlayState extends ConsumerState<ResultsOverlay> {
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final highScore =
        ref.watch(profileControllerProvider.select((p) => p.highScore));
    final unlocked = [
      for (final id in s.unlockedAchievementIds)
        kAchievements.firstWhere((a) => a.id == id),
    ];

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          radius: 28,
          blur: 24,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              s.isNewHighScore ? '🎉 New Best!' : 'Round Over',
              style: TextStyle(
                color: s.isNewHighScore ? AppColors.gold : Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('${s.result.score}',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 56,
                    fontWeight: FontWeight.bold)),
            Text('Best $highScore',
                style: const TextStyle(color: Colors.white60, fontSize: 16)),
            const SizedBox(height: 20),
            _RewardRow(
              icon: Icons.monetization_on,
              color: AppColors.gold,
              label: 'Coins',
              value: '+${_doubled ? s.coinsEarned * 2 : s.coinsEarned}',
            ),
            const SizedBox(height: 8),
            _RewardRow(
              icon: Icons.bolt,
              color: AppColors.accent,
              label: 'XP',
              value: '+${s.xpEarned}',
            ),
            if (s.leveledUp) ...[
              const SizedBox(height: 8),
              _RewardRow(
                icon: Icons.military_tech,
                color: Colors.amberAccent,
                label: 'Level up!',
                value: 'Lv ${s.newLevel}',
              ),
            ],
            for (final a in unlocked) ...[
              const SizedBox(height: 8),
              _RewardRow(
                icon: Icons.emoji_events,
                color: AppColors.gold,
                label: 'Unlocked',
                value: a.title,
              ),
            ],
            const SizedBox(height: 24),
            if (!_doubled && s.coinsEarned > 0)
              PrimaryButton(
                label: 'Double coins (watch ad)',
                icon: Icons.ondemand_video,
                onPressed: () async {
                  final earned = await ref
                      .read(rewardedAdServiceProvider)
                      .showRewardedAd();
                  if (!earned) return;
                  ref
                      .read(gameSessionControllerProvider)
                      .doubleCoins(s);
                  if (mounted) setState(() => _doubled = true);
                },
              ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Play Again',
              icon: Icons.refresh,
              onPressed: widget.onPlayAgain,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onHome,
              child: const Text('Home',
                  style: TextStyle(color: Colors.white60, fontSize: 16)),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(width: 12),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
