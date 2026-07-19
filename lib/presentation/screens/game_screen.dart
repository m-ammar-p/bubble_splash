import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_session_controller.dart';
import '../../application/profile_controller.dart';
import '../../application/rewarded_ad_manager.dart';
import '../../app/candy.dart';
import '../../domain/models/bubble_skin.dart';
import '../../domain/models/game_result.dart';
import '../../game/bubble_splash_game.dart';
import '../widgets/continue_round_sheet.dart';
import '../widgets/game_hud.dart';
import '../widgets/results_overlay.dart';

/// Hosts the Flame [BubbleSplashGame] and bridges its outcome into the meta
/// layer. Play is always free; lives are spent only to *continue* a depleted
/// round. The game stays Riverpod-free and reports back via callbacks.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  BubbleSplashGame? _game;
  RewardSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer to after the first frame (avoid building the game during initState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRound();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flame auto-resumes the engine when the app is foregrounded. If the
    // continue prompt / ad overlay is up, the loop must stay paused — re-pause
    // it here so backgrounding mid-ad can never leave the game running behind
    // the sheet or double-resume it.
    if (state == AppLifecycleState.resumed) {
      final game = _game;
      if (game != null && game.isAwaitingDecision) game.pauseEngine();
    }
  }

  void _startRound() {
    final skin = skinById(ref.read(profileControllerProvider).equippedSkinId);
    // Warm the first rewarded ad proactively at run start (never at death).
    ref.read(rewardedAdManagerProvider.notifier).preload();
    setState(() {
      _summary = null;
      _game = BubbleSplashGame(
        palette: [for (final c in skin.colors) Color(c)],
        onGameOver: _handleGameOver,
        onContinueOffer: _handleContinueOffer,
      );
    });
  }

  /// Round HP depleted: offer a continue. Deferred to after the frame because
  /// the game fires this from inside its update loop.
  void _handleContinueOffer() {
    final game = _game;
    if (game == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fresh death event: reset the per-death revive counter + warm an ad.
      ref.read(rewardedAdManagerProvider.notifier).beginDeathEvent();
      showContinueRoundSheet(context, game);
    });
  }

  void _handleGameOver(GameResult result) {
    final summary = ref.read(gameSessionControllerProvider).applyResult(result);
    setState(() => _summary = summary);
  }

  void _playAgain() => _startRound();

  void _goHome() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      body: Stack(
        children: [
          // The nebula stage is painted INSIDE the game canvas (NebulaBackdrop
          // component) — one full-screen layer instead of two. Until the game
          // is created the scaffold's Candy-colored background covers the gap.
          if (game != null) GameWidget<BubbleSplashGame>(game: game),
          // Own layers: a score/combo repaint must not re-raster siblings
          // (the game canvas repaints every frame regardless).
          if (game != null && _summary == null)
            RepaintBoundary(child: GameHud(game: game, onQuit: _goHome)),
          if (game != null && _summary == null)
            RepaintBoundary(child: _HeadStartOverlay(headStart: game.headStart)),
          if (_summary != null)
            ResultsOverlay(
              summary: _summary!,
              onPlayAgain: _playAgain,
              onHome: _goHome,
            ),
        ],
      ),
    );
  }
}

/// Full-screen "get ready" countdown shown during the post-continue head-start.
/// Reads the game's [headStart] notifier; the per-second `TweenAnimationBuilder`
/// keys on the value so it animates once per number (not every frame).
class _HeadStartOverlay extends StatelessWidget {
  const _HeadStartOverlay({required this.headStart});
  final ValueNotifier<int> headStart;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: headStart,
        builder: (_, secs, _) {
          if (secs <= 0) return const SizedBox.shrink();
          return Container(
            // rgba(10,5,20,.45) dim over the game.
            color: const Color(0xFF0A0514).withValues(alpha: 0.45),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GET READY',
                  style: Candy.ui(
                    color: const Color(0xFFFFE1D2).withValues(alpha: 0.75),
                    size: 19 * s,
                    weight: FontWeight.w800,
                    letterSpacing: 7 * s,
                  ),
                ),
                SizedBox(height: 22 * s),
                // One pulse per digit (the value ticks every second, so keying
                // the tween on it yields the spec's 1s pulse rhythm).
                TweenAnimationBuilder<double>(
                  key: ValueKey(secs),
                  tween: Tween(begin: 1.18, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Text(
                    '$secs',
                    style: Candy.display(
                      color: Colors.white,
                      size: 120 * s,
                      height: 1.0,
                      shadows: [
                        Shadow(
                            color: Candy.orange.withValues(alpha: 0.75),
                            blurRadius: 30 * s),
                        Shadow(
                            color: Candy.pink.withValues(alpha: 0.40),
                            blurRadius: 70 * s),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
