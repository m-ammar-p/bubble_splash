/// Which leaderboard pool to view. The fake backend seeds different score
/// scales per scope; a real backend would query by region.
enum LeaderboardScope { local, global }

/// Which stat the board ranks by. High score rewards a peak run (skill); total
/// pops rewards lifetime grind (engagement). The two boards are ranked
/// independently so a grinder and an ace each top a different list.
enum LeaderboardMetric { highScore, totalPops }

/// A single ranked row. [rank] and [isCurrentPlayer] are assigned by the
/// controller after merging the player's own stats into the seeded list.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    required this.score,
    required this.bubblesPopped,
    required this.level,
    this.rank = 0,
    this.isCurrentPlayer = false,
  });

  final String id;
  final String name;

  /// Avatar key (see `kAvatarIcons`).
  final String avatarEmoji;
  final int avatarColor;

  /// Peak single-round score (the [LeaderboardMetric.highScore] board).
  final int score;

  /// Lifetime bubbles popped (the [LeaderboardMetric.totalPops] board).
  final int bubblesPopped;
  final int level;
  final int rank;
  final bool isCurrentPlayer;

  /// The value this entry is ranked by for [metric].
  int valueFor(LeaderboardMetric metric) => switch (metric) {
        LeaderboardMetric.highScore => score,
        LeaderboardMetric.totalPops => bubblesPopped,
      };

  LeaderboardEntry copyWith({int? rank, bool? isCurrentPlayer}) =>
      LeaderboardEntry(
        id: id,
        name: name,
        avatarEmoji: avatarEmoji,
        avatarColor: avatarColor,
        score: score,
        bubblesPopped: bubblesPopped,
        level: level,
        rank: rank ?? this.rank,
        isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      );
}
