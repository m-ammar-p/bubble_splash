import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_session_controller.dart';
import '../../application/lives_controller.dart';
import '../../application/profile_controller.dart';
import '../../domain/models/bubble_skin.dart';
import '../../domain/models/game_result.dart';
import '../../game/bubble_splash_game.dart';
import '../widgets/game_hud.dart';
import '../widgets/out_of_lives_sheet.dart';
import '../widgets/results_overlay.dart';

/// Hosts the Flame [BubbleSplashGame] and bridges its outcome into the meta
/// layer. A life is consumed when a round starts; the game stays Riverpod-free
/// and only reports a [GameResult] back via its callback.
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
    // Defer to after the first frame: starting a round spends a life, and
    // Riverpod forbids mutating providers during a widget life-cycle (initState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRound();
    });
  }

  void _startRound() {
    final lives = ref.read(livesControllerProvider.notifier);
    if (!lives.canPlay) {
      _handleNoLives();
      return;
    }
    lives.spendLife();

    final skin = skinById(ref.read(profileControllerProvider).equippedSkinId);
    setState(() {
      _summary = null;
      _game = BubbleSplashGame(
        palette: [for (final c in skin.colors) Color(c)],
        onGameOver: _handleGameOver,
      );
    });
  }

  /// Offers the out-of-lives sheet. If a life is earned (e.g. via the ad), the
  /// round starts; otherwise we leave the screen only if no round is in progress.
  Future<void> _handleNoLives() async {
    await showOutOfLivesSheet(context);
    if (!mounted) return;
    if (ref.read(livesControllerProvider.notifier).canPlay) {
      _startRound();
    } else if (_game == null) {
      Navigator.of(context).pop();
    }
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
