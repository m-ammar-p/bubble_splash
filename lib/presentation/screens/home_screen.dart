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
        SnackBar(content: Text('Daily reward: +$reward coins!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const _FloatingBubble(),
              const SizedBox(height: 12),
              // Gradient shimmer title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF90F0FF),
                    AppColors.accent,
                    AppColors.neonPurple,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'Bubble Splash',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pop the bubbles. Beat your best.',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const Spacer(),
              _DailyRewardCard(
                canClaim: canClaimDaily,
                onClaim: () => _claimDaily(context, ref),
              ),
              const SizedBox(height: 20),
              _PulsingPlayButton(
                onPressed: () => _play(context, ref),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    route: Routes.profile,
                  ),
                  _NavButton(
                    icon: Icons.leaderboard_rounded,
                    label: 'Ranks',
                    route: Routes.leaderboard,
                  ),
                  _NavButton(
                    icon: Icons.storefront_rounded,
                    label: 'Shop',
                    route: Routes.shop,
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bubble emoji that gently floats up and down.
class _FloatingBubble extends StatefulWidget {
  const _FloatingBubble();

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _float = Tween(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: const Text('🫧', style: TextStyle(fontSize: 82)),
    );
  }
}

/// Play button that scales and glows in a repeating pulse to draw the eye.
class _PulsingPlayButton extends StatefulWidget {
  const _PulsingPlayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.055).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween(begin: 18.0, end: 42.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.55),
                blurRadius: _glow.value,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.neonPurple.withValues(alpha: 0.28),
                blurRadius: _glow.value * 0.65,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: PrimaryButton(
        label: 'Play',
        icon: Icons.play_arrow_rounded,
        onPressed: widget.onPressed,
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
      borderColor: canClaim ? AppColors.gold.withValues(alpha: 0.60) : null,
      onTap: canClaim ? onClaim : null,
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded,
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
          if (canClaim)
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
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
        const SizedBox(height: 7),
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
