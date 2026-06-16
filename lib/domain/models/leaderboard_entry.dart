/// Which leaderboard pool to view. The fake backend seeds different score
/// scales per scope; a real backend would query by region.
enum LeaderboardScope { national, global }

/// A single ranked row. [rank] and [isCurrentPlayer] are assigned by the
/// controller after merging the player's own score into the seeded list.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    required this.score,
    this.rank = 0,
    this.isCurrentPlayer = false,
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final int avatarColor;
  final int score;
  final int rank;
  final bool isCurrentPlayer;

  LeaderboardEntry copyWith({int? rank, bool? isCurrentPlayer}) =>
      LeaderboardEntry(
        id: id,
        name: name,
        avatarEmoji: avatarEmoji,
        avatarColor: avatarColor,
        score: score,
        rank: rank ?? this.rank,
        isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      );
}
