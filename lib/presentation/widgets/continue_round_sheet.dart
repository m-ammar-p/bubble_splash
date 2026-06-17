import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/providers.dart';
import '../../app/theme.dart';
import '../../game/bubble_splash_game.dart';
import 'glass.dart';
import 'primary_button.dart';

/// Shown when round HP is depleted. The player can spend a banked life to
/// continue, or watch a rewarded ad (each ad banks +1 life) up to a 3-ad cap,
/// then continue. Ending the run finalizes the result. The game is paused while
/// this is up; every continue path calls [BubbleSplashGame.continueRound],
/// which clears the screen and grants a 3s head-start.
Future<void> showContinueRoundSheet(
  BuildContext context,
  BubbleSplashGame game,
) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassPanel(
        radius: 28,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.replay_circle_filled_rounded,
                color: AppColors.neon, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Keep going?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasLife
                  ? 'Continue with a life, or stock up by watching ads.'
                  : 'Watch an ad to get a life and keep going.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: hasLife
                  ? 'Continue · 1 life (${lives.count} left)'
                  : 'Continue (need a life)',
              icon: Icons.favorite,
              onPressed: hasLife && !_busy ? _continue : null,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: adsLeft > 0
                  ? 'Watch ad · +1 life ($adsLeft left)'
                  : 'Ad limit reached',
              icon: Icons.ondemand_video,
              onPressed: adsLeft > 0 && !_busy ? _watchAd : null,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _end,
              child: const Text('End run',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
