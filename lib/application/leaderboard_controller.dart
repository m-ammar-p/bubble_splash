import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/leaderboard_entry.dart';
import 'profile_controller.dart';
import 'providers.dart';

/// A leaderboard view is identified by its pool ([scope]) and the stat it ranks
/// by ([metric]). Used as the [leaderboardProvider] family key.
typedef LeaderboardView = ({LeaderboardScope scope, LeaderboardMetric metric});

/// Fetches competitor entries for a scope, merges in the current player's stats,
/// sorts by the requested [LeaderboardMetric], and assigns ranks. Re-runs when
/// the player's profile changes (new high score / more pops) because it watches
/// [profileControllerProvider].
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, LeaderboardView>((ref, view) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final profile = ref.watch(profileControllerProvider);

  final bots = await repo.fetchTop(view.scope);

  final player = LeaderboardEntry(
    id: 'me',
    name: profile.name,
    avatarEmoji: profile.avatarEmoji,
    avatarColor: profile.avatarColor,
    score: profile.highScore,
    bubblesPopped: profile.totalBubblesPopped,
    level: profile.level,
    isCurrentPlayer: true,
  );

  final merged = [...bots, player]
    ..sort((a, b) => b.valueFor(view.metric).compareTo(a.valueFor(view.metric)));

  return [
    for (var i = 0; i < merged.length; i++) merged[i].copyWith(rank: i + 1),
  ];
});
