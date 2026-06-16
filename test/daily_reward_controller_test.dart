import 'package:bubble_splash/application/daily_reward_controller.dart';
import 'package:bubble_splash/application/profile_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/daily_reward_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 6, 17, 9);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(container.dispose);
  });

  DailyRewardController daily() =>
      container.read(dailyRewardControllerProvider.notifier);
  int coins() => container.read(profileControllerProvider).coins;

  test('first claim grants the day-1 reward and credits coins', () {
    expect(daily().canClaimToday, isTrue);
    final reward = daily().claim();
    expect(reward, DailyRewardState.rewardForStreak(1));
    expect(coins(), reward);
    expect(container.read(dailyRewardControllerProvider).streak, 1);
  });

  test('cannot claim twice in the same day', () {
    daily().claim();
    expect(daily().canClaimToday, isFalse);
    expect(daily().claim(), isNull);
  });

  test('consecutive days grow the streak', () {
    daily().claim(); // streak 1
    now = now.add(const Duration(days: 1));
    final reward = daily().claim();
    expect(container.read(dailyRewardControllerProvider).streak, 2);
    expect(reward, DailyRewardState.rewardForStreak(2));
  });

  test('a missed day resets the streak to 1', () {
    daily().claim(); // streak 1
    now = now.add(const Duration(days: 2)); // skipped a day
    daily().claim();
    expect(container.read(dailyRewardControllerProvider).streak, 1);
  });

  test('claiming records the best streak on the profile', () {
    daily().claim();
    now = now.add(const Duration(days: 1));
    daily().claim();
    expect(container.read(profileControllerProvider).bestStreak, 2);
  });
}
