import 'dart:math';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// A simulated remote leaderboard. Generates a deterministic set of competitor
/// entries (seeded RNG) so the list is stable across launches, with a short
/// artificial delay to mimic a network round-trip. Global scores skew higher
/// than national to make the two tabs feel distinct.
class FakeLeaderboardRepository implements LeaderboardRepository {
  static const _firstNames = [
    'Aria', 'Liam', 'Noah', 'Mia', 'Zoe', 'Kai', 'Luca', 'Ivy', 'Eli', 'Nova',
    'Remy', 'Sage', 'Theo', 'Wren', 'Juno', 'Otto', 'Cleo', 'Iris', 'Finn',
    'Maya', 'Rex', 'Lux', 'Ada', 'Bo', 'Cy', 'Dex', 'Eve', 'Fox', 'Gia', 'Hugo',
  ];
  static const _emojis = [
    '🦊', '🐼', '🐯', '🦁', '🐨', '🐸', '🐙', '🦄', '🐲', '🦖',
    '🐺', '🦅', '🐝', '🦋', '🐬', '🦈', '🐢', '🦔', '🐱', '🐶',
  ];
  static const _colors = [
    0xFF4FC3F7, 0xFFBA68C8, 0xFFFF8A65, 0xFF81C784,
    0xFFFFD54F, 0xFFF06292, 0xFF9575CD, 0xFF4DB6AC,
  ];

  @override
  Future<List<LeaderboardEntry>> fetchTop(
    LeaderboardScope scope, {
    int limit = 50,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    // Distinct deterministic seed per scope → stable but different lists.
    final rng = Random(scope == LeaderboardScope.global ? 9001 : 4242);
    final topScore = scope == LeaderboardScope.global ? 9800 : 4200;

    final entries = <LeaderboardEntry>[];
    var score = topScore;
    for (var i = 0; i < limit; i++) {
      // Monotonically decreasing scores with some jitter.
      score -= 40 + rng.nextInt(120);
      if (score < 50) score = 50 + rng.nextInt(50);
      final name =
          '${_firstNames[rng.nextInt(_firstNames.length)]}_${rng.nextInt(99)}';
      entries.add(
        LeaderboardEntry(
          id: 'bot_${scope.name}_$i',
          name: name,
          avatarEmoji: _emojis[rng.nextInt(_emojis.length)],
          avatarColor: _colors[rng.nextInt(_colors.length)],
          score: score,
        ),
      );
    }
    return entries;
  }
}
