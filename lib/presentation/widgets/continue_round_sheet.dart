import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/providers.dart';
import '../../app/candy.dart';
import '../../domain/models/lives_state.dart';
import '../../game/bubble_splash_game.dart';

/// Shown when round HP is depleted. The player can spend a banked life to
/// continue, or watch a rewarded ad (each ad banks +1 life) up to a 3-ad cap,
/// then continue. Ending the run finalizes the result. The game is paused while
/// this is up; every continue path calls [BubbleSplashGame.continueRound],
/// which clears the screen and grants a 3s head-start.
///
/// Candy Cosmos style (spec screen 04): violet bottom sheet, warm orange icon
/// circle (positive cue — never red, players read red as an error), orange CTA
/// + glass ad button + "End run" link. Counts come from real inventory.
Future<void> showContinueRoundSheet(
  BuildContext context,
  BubbleSplashGame game,
) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0A0514).withValues(alpha: 0.55),
    builder: (_) => _ContinueRoundSheet(game: game),
  );
}

class _ContinueRoundSheet extends ConsumerStatefulWidget {
  const _ContinueRoundSheet({required this.game});
  final BubbleSplashGame game;

  @override
  ConsumerState<_ContinueRoundSheet> createState() =>
      _ContinueRoundSheetState();
}

class _ContinueRoundSheetState extends ConsumerState<_ContinueRoundSheet> {
  static const int _maxAds = 3;
  int _adsWatched = 0;
  bool _busy = false;

  void _continue() {
    ref.read(livesControllerProvider.notifier).spendLife();
    widget.game.continueRound();
    Navigator.of(context).pop();
  }

  void _end() {
    widget.game.finishRound();
    Navigator.of(context).pop();
  }

  Future<void> _watchAd() async {
    if (_busy || _adsWatched >= _maxAds) return;
    setState(() => _busy = true);
    final earned = await ref.read(rewardedAdServiceProvider).showRewardedAd();
    if (!mounted) return;
    if (earned) {
      ref.read(livesControllerProvider.notifier).addLife();
      _adsWatched++;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lives = ref.watch(livesControllerProvider);
    final hasLife = lives.count > 0;
    final adsLeft = _maxAds - _adsWatched;
    // A full bank can't hold an ad life — offering an ad that grants nothing
    // would rob the player, so the option is disabled at the cap.
    final bankFull = lives.isFull;
    final s = candyScale(context);

    return CandySheet(
      padding: EdgeInsets.fromLTRB(20 * s, 24 * s, 20 * s, 22 * s),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 56px orange radial icon circle with a restart glyph.
            Container(
              width: 56 * s,
              height: 56 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.32, -0.44),
                  radius: 0.9,
                  colors: Candy.orangeChip,
                  stops: [0.0, 0.60, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Candy.orange.withValues(alpha: 0.5),
                    blurRadius: 24 * s,
                    offset: Offset(0, 8 * s),
                  ),
                ],
              ),
              child: Icon(Icons.refresh_rounded,
                  color: Candy.ctaInk, size: 30 * s),
            ),
            SizedBox(height: 14 * s),
            Text('Keep going?',
                style: Candy.display(size: 27 * s, height: 1.0)),
            SizedBox(height: 8 * s),
            Text(
              hasLife
                  ? 'Continue with a life, or stock up by watching ads.'
                  : 'Watch an ad to get a life and keep going.',
              textAlign: TextAlign.center,
              style: Candy.ui(
                color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                size: 13.5 * s,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18 * s),
            CandyCtaButton(
              onPressed: hasLife && !_busy ? _continue : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Candy.ctaInk, size: 18 * s),
                  SizedBox(width: 8 * s),
                  Text.rich(
                    TextSpan(
                      style: Candy.ui(
                          color: Candy.ctaInk,
                          size: 16.5 * s,
                          weight: FontWeight.w800),
                      children: [
                        TextSpan(
                            text: hasLife
                                ? 'Continue · 1 life '
                                : 'Continue (need a life)'),
                        if (hasLife)
                          TextSpan(
                            text: '(${lives.count} left)',
                            style: TextStyle(
                                color:
                                    Candy.ctaInk.withValues(alpha: 0.7)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10 * s),
            _GlassButton(
              onPressed: adsLeft > 0 && !bankFull && !_busy ? _watchAd : null,
              icon: Icons.ondemand_video_rounded,
              label: bankFull
                  ? 'Lives full (${LivesState.maxLives})'
                  : adsLeft > 0
                      ? 'Watch ad · +1 life ($adsLeft left)'
                      : 'Ad limit reached',
            ),
            SizedBox(height: 15 * s),
            GestureDetector(
              onTap: _busy ? null : _end,
              child: Text(
                'End run',
                style: Candy.ui(
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 13.5 * s,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary 54px glass button (white text, subtle border).
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: CandyGlass(
        onTap: onPressed,
        radius: 18 * s,
        borderAlpha: 0.22,
        height: 54 * s,
        width: double.infinity,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18 * s),
            SizedBox(width: 8 * s),
            Text(label,
                style: Candy.ui(size: 16.5 * s, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
