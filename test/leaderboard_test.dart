import 'package:bubble_splash/application/leaderboard_controller.dart';
import 'package:bubble_splash/application/profile_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/game_result.dart';
import 'package:bubble_splash/domain/models/leaderboard_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
  });

  const scoreView =
      (scope: LeaderboardScope.local, metric: LeaderboardMetric.highScore);
  const popsView =
      (scope: LeaderboardScope.local, metric: LeaderboardMetric.totalPops);

  test('merges the player, sorts by score, and assigns sequential ranks',
      () async {
    final list = await container.read(leaderboardProvider(scoreView).future);

    expect(list, isNotEmpty);
    // Exactly one entry is the current player.
    expect(list.where((e) => e.isCurrentPlayer).length, 1);
    // Sorted descending by score.
    for (var i = 1; i < list.length; i++) {
      expect(list[i - 1].score, greaterThanOrEqualTo(list[i].score));
    }
    // Ranks are 1..n in order.
    for (var i = 0; i < list.length; i++) {
      expect(list[i].rank, i + 1);
    }
  });

  test('the total-pops board sorts by bubblesPopped, not score', () async {
    final list = await container.read(leaderboardProvider(popsView).future);

    expect(list.where((e) => e.isCurrentPlayer).length, 1);
    for (var i = 1; i < list.length; i++) {
      expect(list[i - 1].bubblesPopped,
          greaterThanOrEqualTo(list[i].bubblesPopped));
    }
    for (var i = 0; i < list.length; i++) {
      expect(list[i].rank, i + 1);
    }
  });

  test('a higher player score climbs the ranking', () async {
    final before = await container.read(leaderboardProvider(scoreView).future);
    final myRankBefore = before.firstWhere((e) => e.isCurrentPlayer).rank;

    container.read(profileControllerProvider.notifier).recordGameResult(
          const GameResult(
              score: 100000, bubblesPopped: 10, maxCombo: 1, goldenPopped: 0),
        );

    final after = await container.read(leaderboardProvider(scoreView).future);
    final myEntryAfter = after.firstWhere((e) => e.isCurrentPlayer);
    expect(myEntryAfter.rank, 1);
    expect(myEntryAfter.rank, lessThanOrEqualTo(myRankBefore));
  });

  test('popping many bubbles climbs the total-pops board', () async {
    final before = await container.read(leaderboardProvider(popsView).future);
    final myRankBefore = before.firstWhere((e) => e.isCurrentPlayer).rank;

    container.read(profileControllerProvider.notifier).recordGameResult(
          const GameResult(
              score: 10, bubblesPopped: 1000000, maxCombo: 1, goldenPopped: 0),
        );

    final after = await container.read(leaderboardProvider(popsView).future);
    final myEntryAfter = after.firstWhere((e) => e.isCurrentPlayer);
    expect(myEntryAfter.rank, 1);
    expect(myEntryAfter.rank, lessThanOrEqualTo(myRankBefore));
  });
}
