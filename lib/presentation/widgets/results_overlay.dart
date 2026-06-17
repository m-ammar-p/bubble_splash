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

/// The end-of-round results panel, shown over the game. Slides up and fades in
/// on entry. Score animates from 0 to the final value. New-high-score runs a
/// gold shimmer header.
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

class _ResultsOverlayState extends ConsumerState<ResultsOverlay>
    with SingleTickerProviderStateMixin {
  bool _doubled = false;
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _slide = Tween(begin: const Offset(0, 0.22), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final highScore =
        ref.watch(profileControllerProvider.select((p) => p.highScore));
    final unlocked = [
      for (final id in s.unlockedAchievementIds)
        kAchievements.firstWhere((a) => a.id == id),
    ];

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.58),
        alignment: Alignment.center,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassPanel(
              radius: 32,
              blur: 28,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold shimmer "NEW BEST" label
                  if (s.isNewHighScore) ...[
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.gold,
                          Color(0xFFFFF9AA),
                          AppColors.gold,
                        ],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        '✦  NEW BEST  ✦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    s.isNewHighScore ? 'New Record!' : 'Round Over',
                    style: TextStyle(
                      color: s.isNewHighScore ? AppColors.gold : Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Score counts up from 0 to the final value
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: s.result.score),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOut,
                    builder: (_, value, _) => Text(
                      '$value',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        shadows: [
                          Shadow(color: AppColors.accent, blurRadius: 24),
                          Shadow(color: AppColors.accent, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'Best $highScore',
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  const SizedBox(height: 20),
                  _RewardRow(
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.gold,
                    label: 'Coins',
                    value: '+${_doubled ? s.coinsEarned * 2 : s.coinsEarned}',
                  ),
                  const SizedBox(height: 8),
                  _RewardRow(
                    icon: Icons.bolt_rounded,
                    color: AppColors.accent,
                    label: 'XP',
                    value: '+${s.xpEarned}',
                  ),
                  if (s.leveledUp) ...[
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.military_tech_rounded,
                      color: Colors.amberAccent,
                      label: 'Level up!',
                      value: 'Lv ${s.newLevel}',
                    ),
                  ],
                  for (final a in unlocked) ...[
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.gold,
                      label: 'Unlocked',
                      value: a.title,
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (!_doubled && s.coinsEarned > 0)
                    PrimaryButton(
                      label: 'Double coins (watch ad)',
                      icon: Icons.ondemand_video_rounded,
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
                    icon: Icons.refresh_rounded,
                    onPressed: widget.onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onHome,
                    child: const Text(
                      'Home',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
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
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(width: 12),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
