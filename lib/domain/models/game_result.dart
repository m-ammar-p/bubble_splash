/// The outcome of a single round, reported by the Flame game up to the meta
/// layer. Pure data — carries no reward logic itself.
class GameResult {
  const GameResult({
    required this.score,
    required this.bubblesPopped,
    required this.maxCombo,
    required this.goldenPopped,
  });

  final int score;
  final int bubblesPopped;
  final int maxCombo;
  final int goldenPopped;

  static const GameResult empty =
      GameResult(score: 0, bubblesPopped: 0, maxCombo: 0, goldenPopped: 0);
}

/// Summary of everything the player earned from a round, produced by the game
/// session controller and shown on the results screen.
class RewardSummary {
  const RewardSummary({
    required this.result,
    required this.xpEarned,
    required this.isNewHighScore,
    required this.leveledUp,
    required this.newLevel,
    required this.unlockedAchievementIds,
  });

  final GameResult result;
  final int xpEarned;
  final bool isNewHighScore;
  final bool leveledUp;
  final int newLevel;
  final List<String> unlockedAchievementIds;
}
