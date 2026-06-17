import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_session_controller.dart';
import '../../application/profile_controller.dart';
import '../../app/theme.dart';
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

class _GameScreenState extends ConsumerState<GameScreen> {
  BubbleSplashGame? _game;
  RewardSummary? _summary;

  @override
  void initState() {
    super.initState();
    // Defer to after the first frame (avoid building the game during initState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRound();
    });
  }

  void _startRound() {
    final skin = skinById(ref.read(profileControllerProvider).equippedSkinId);
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
      if (mounted) showContinueRoundSheet(context, game);
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
          if (game != null) GameWidget<BubbleSplashGame>(game: game),
          if (game != null && _summary == null)
            GameHud(game: game, onQuit: _goHome),
          if (game != null && _summary == null)
            _HeadStartOverlay(headStart: game.headStart),
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
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: headStart,
        builder: (_, secs, _) {
          if (secs <= 0) return const SizedBox.shrink();
          return Container(
            color: Colors.black.withValues(alpha: 0.35),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GET READY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  key: ValueKey(secs),
                  tween: Tween(begin: 1.4, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Text(
                    '$secs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: AppColors.accent, blurRadius: 24)],
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
