import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/game_result.dart';
import 'profile_controller.dart';

/// Thin application service that turns a finished round into rewards. Kept as a
/// distinct seam (rather than calling the profile controller directly from the
/// UI) so future cross-cutting concerns — leaderboard submission, analytics,
/// re-engagement notifications — have one place to live.
class GameSessionController {
  GameSessionController(this._ref);
  final Ref _ref;

  RewardSummary applyResult(GameResult result) =>
      _ref.read(profileControllerProvider.notifier).recordGameResult(result);

  /// Doubles a round's coin reward (the watch-ad bonus on the results screen).
  void doubleCoins(RewardSummary summary) =>
      _ref.read(profileControllerProvider.notifier).grantCoins(summary.coinsEarned);
}

final gameSessionControllerProvider =
    Provider<GameSessionController>((ref) => GameSessionController(ref));
