import 'package:bubble_splash/application/profile_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/game_result.dart';
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

  ProfileController profile() =>
      container.read(profileControllerProvider.notifier);

  test('recording a result awards xp and updates stats (no coins from play)',
      () {
    final summary = profile().recordGameResult(
      const GameResult(
          score: 1000, bubblesPopped: 50, maxCombo: 10, goldenPopped: 2),
    );

    expect(summary.xpEarned, 1000);
    expect(summary.isNewHighScore, isTrue);

    final p = container.read(profileControllerProvider);
    expect(p.coins, 0); // coins are purchased, not earned in-game
    expect(p.highScore, 1000);
    expect(p.gamesPlayed, 1);
    expect(p.totalBubblesPopped, 50);
  });

  test('crossing an XP threshold reports a level-up and unlocks achievements',
      () {
    final summary = profile().recordGameResult(
      const GameResult(
          score: 1000, bubblesPopped: 50, maxCombo: 10, goldenPopped: 0),
    );
    expect(summary.leveledUp, isTrue);
    expect(summary.newLevel, greaterThan(1));
    expect(summary.unlockedAchievementIds, contains('first_pop'));
    expect(summary.unlockedAchievementIds, contains('score_1000'));
  });

  test('a lower score does not lower the high score', () {
    profile().recordGameResult(const GameResult(
        score: 500, bubblesPopped: 20, maxCombo: 5, goldenPopped: 0));
    final summary = profile().recordGameResult(const GameResult(
        score: 200, bubblesPopped: 10, maxCombo: 2, goldenPopped: 0));
    expect(summary.isNewHighScore, isFalse);
    expect(container.read(profileControllerProvider).highScore, 500);
  });

  test('buying a skin spends coins, equips it, and is idempotent', () {
    profile().grantCoins(500);
    expect(profile().buySkin('ocean'), isTrue); // ocean costs 300
    final p = container.read(profileControllerProvider);
    expect(p.coins, 200);
    expect(p.ownedSkinIds, contains('ocean'));
    expect(p.equippedSkinId, 'ocean');

    expect(profile().buySkin('ocean'), isFalse); // already owned
    expect(profile().buySkin('neon'), isFalse); // 800 > 200 coins
  });

  test('profile persists across controller rebuilds', () {
    profile().grantCoins(99);
    container.invalidate(profileControllerProvider);
    expect(container.read(profileControllerProvider).coins, 99);
  });
}
