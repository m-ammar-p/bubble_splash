import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/leaderboard_entry.dart';
import 'profile_controller.dart';
import 'providers.dart';

/// Fetches competitor entries for a scope, merges in the current player's high
/// score, sorts, and assigns ranks. Re-runs when the player's profile changes
/// (e.g. a new high score) because it watches [profileControllerProvider].
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, LeaderboardScope>((ref, scope) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final profile = ref.watch(profileControllerProvider);

  final bots = await repo.fetchTop(scope);

  final player = LeaderboardEntry(
    id: 'me',
    name: profile.name,
    avatarEmoji: profile.avatarEmoji,
    avatarColor: profile.avatarColor,
    score: profile.highScore,
    isCurrentPlayer: true,
  );

  final merged = [...bots, player]
    ..sort((a, b) => b.score.compareTo(a.score));

  return [
    for (var i = 0; i < merged.length; i++) merged[i].copyWith(rank: i + 1),
  ];
});
