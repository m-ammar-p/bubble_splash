import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/daily_reward_controller.dart';
import '../../application/lives_controller.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../widgets/glass.dart';
import '../widgets/out_of_lives_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badges.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _play(BuildContext context, WidgetRef ref) {
    if (ref.read(livesControllerProvider.notifier).canPlay) {
      Navigator.of(context).pushNamed(Routes.game);
    } else {
      showOutOfLivesSheet(context);
    }
  }

  void _claimDaily(BuildContext context, WidgetRef ref) {
    final reward = ref.read(dailyRewardControllerProvider.notifier).claim();
    if (reward != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily reward: +$reward coins 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when the daily state changes (e.g. after claiming).
    ref.watch(dailyRewardControllerProvider);
    final canClaimDaily =
        ref.read(dailyRewardControllerProvider.notifier).canClaimToday;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Row(
                children: [
                  CoinBadge(),
                  SizedBox(width: 8),
                  LevelBadge(),
                  Spacer(),
                  LivesBadge(),
                ],
              ),
              const Spacer(),
              const Text('🫧', style: TextStyle(fontSize: 76)),
              const Text(
                'Bubble Splash',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: AppColors.accent, blurRadius: 24),
                    Shadow(color: Color(0x66EC407A), blurRadius: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pop the bubbles. Beat your best.',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const Spacer(),
              _DailyRewardCard(
                canClaim: canClaimDaily,
                onClaim: () => _claimDaily(context, ref),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Play',
                icon: Icons.play_arrow,
                onPressed: () => _play(context, ref),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.person,
                    label: 'Profile',
                    route: Routes.profile,
                  ),
                  _NavButton(
                    icon: Icons.leaderboard,
                    label: 'Ranks',
                    route: Routes.leaderboard,
                  ),
                  _NavButton(
                    icon: Icons.storefront,
                    label: 'Shop',
                    route: Routes.shop,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.canClaim, required this.onClaim});

  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tint: canClaim ? AppColors.gold : Colors.white,
      borderColor: canClaim ? AppColors.gold.withValues(alpha: 0.55) : null,
      onTap: canClaim ? onClaim : null,
      child: Row(
        children: [
          Icon(Icons.card_giftcard,
              color: canClaim ? AppColors.gold : Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canClaim ? 'Claim your daily reward!' : 'Daily reward claimed',
              style: TextStyle(
                color: canClaim ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canClaim) const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassCircleButton(
          icon: icon,
          onTap: () => Navigator.of(context).pushNamed(route),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ],
    );
  }
}
