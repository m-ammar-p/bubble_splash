import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../app/candy.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/game_result.dart';

/// The end-of-round results panel, shown over the game. Slides up and fades in
/// on entry. Candy Cosmos style (spec screen 05): violet result card, glowing
/// Baloo 2 score, gradient-chip reward rows, orange PLAY AGAIN. New-high-score
/// runs a gold shimmer header. (Coins are not earned in-game — they're a
/// purchasable currency — so only score/XP are shown.)
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
    final scale = candyScale(context);
    final highScore =
        ref.watch(profileControllerProvider.select((p) => p.highScore));
    final unlocked = [
      for (final id in s.unlockedAchievementIds)
        kAchievements.firstWhere((a) => a.id == id),
    ];

    return FadeTransition(
      opacity: _fade,
      child: Container(
        // rgba(10,5,20,.55) dim over the game.
        color: const Color(0xFF0A0514).withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16 * scale),
            child: CandySheet(
              padding:
                  EdgeInsets.fromLTRB(22 * scale, 26 * scale, 22 * scale, 24 * scale),
              shadow: BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 60 * scale,
                offset: Offset(0, 24 * scale),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold shimmer "NEW BEST" label
                  if (s.isNewHighScore) ...[
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Candy.yellow,
                          Color(0xFFFFF9AA),
                          Candy.yellow,
                        ],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        '✦  NEW BEST  ✦',
                        style: Candy.ui(
                          size: 13 * scale,
                          weight: FontWeight.w800,
                          letterSpacing: 4 * scale,
                        ),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                  ],
                  Text(
                    s.isNewHighScore ? 'New Record!' : 'Round Over',
                    style: Candy.display(
                      size: 27 * scale,
                      height: 1.0,
                      color:
                          s.isNewHighScore ? Candy.yellow : Candy.titleText,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  // Final score, shown directly (no count-up animation).
                  Text(
                    '${s.result.score}',
                    style: Candy.display(
                      color: Candy.orangeCtaTop,
                      size: 74 * scale,
                      height: 1.0,
                      shadows: [
                        Shadow(
                            color: Candy.orange.withValues(alpha: 0.65),
                            blurRadius: 26 * scale),
                        Shadow(
                            color: Candy.pink.withValues(alpha: 0.30),
                            blurRadius: 60 * scale),
                      ],
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Best $highScore',
                    style: Candy.ui(
                      color:
                          const Color(0xFFFFE1D2).withValues(alpha: 0.55),
                      size: 14 * scale,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 18 * scale),
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  _RewardRow(
                    chipColors: Candy.levelChip,
                    icon: Icons.bolt,
                    label: 'XP',
                    value: '+${s.xpEarned}',
                    valueColor: Candy.violetLight,
                  ),
                  if (s.leveledUp) ...[
                    SizedBox(height: 10 * scale),
                    _RewardRow(
                      chipColors: Candy.yellowChip,
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFF7A5300),
                      label: 'Level up!',
                      value: 'Lv ${s.newLevel}',
                      valueColor: const Color(0xFFFFCE4D),
                    ),
                  ],
                  for (final a in unlocked) ...[
                    SizedBox(height: 10 * scale),
                    _RewardRow(
                      chipColors: Candy.coinsChip,
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFF7A4D00),
                      label: 'Unlocked',
                      value: a.title,
                      valueColor: Candy.yellow,
                    ),
                  ],
                  SizedBox(height: 20 * scale),
                  CandyCtaButton(
                    onPressed: widget.onPlayAgain,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay_rounded,
                            color: Candy.ctaInk, size: 22 * scale),
                        SizedBox(width: 8 * scale),
                        Text(
                          'PLAY AGAIN',
                          style: Candy.display(
                            color: Candy.ctaInk,
                            size: 20 * scale,
                            letterSpacing: 1 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15 * scale),
                  GestureDetector(
                    onTap: widget.onHome,
                    child: Text(
                      'Home',
                      style: Candy.ui(
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 13.5 * scale,
                      ),
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

/// A reward line: 26px radial-gradient icon chip + label + colored value.
class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.chipColors,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.iconColor = Colors.white,
  });

  final List<Color> chipColors;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CandyChip(
          colors: chipColors,
          size: 26 * s,
          child: Icon(icon, color: iconColor, size: 16 * s),
        ),
        SizedBox(width: 10 * s),
        Text(label,
            style: Candy.ui(
              color: Colors.white.withValues(alpha: 0.85),
              size: 15 * s,
              weight: FontWeight.w800,
            )),
        SizedBox(width: 8 * s),
        Text(value,
            style: Candy.ui(
              color: valueColor,
              size: 15 * s,
              weight: FontWeight.w800,
            )),
      ],
    );
  }
}
