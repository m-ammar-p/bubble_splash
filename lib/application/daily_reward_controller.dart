import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/daily_reward_state.dart';
import 'profile_controller.dart';
import 'providers.dart';

/// Owns the daily login-reward streak. A claim is allowed once per calendar day;
/// claiming on consecutive days grows the streak, a gap resets it to 1.
class DailyRewardController extends Notifier<DailyRewardState> {
  @override
  DailyRewardState build() {
    final repo = ref.read(dailyRewardRepositoryProvider);
    return repo.load() ?? DailyRewardState.initial();
  }

  DateTime get _now => ref.read(clockProvider)();

  bool get canClaimToday =>
      state.lastClaimYmd != DailyRewardState.ymdOf(_now);

  /// Claims today's reward. Returns the coins granted, or null if already
  /// claimed today. Grants coins and records the streak on the profile.
  int? claim() {
    final now = _now;
    final todayYmd = DailyRewardState.ymdOf(now);
    if (state.lastClaimYmd == todayYmd) return null;

    final yesterdayYmd =
        DailyRewardState.ymdOf(now.subtract(const Duration(days: 1)));
    final newStreak = state.lastClaimYmd == yesterdayYmd ? state.streak + 1 : 1;
    final reward = DailyRewardState.rewardForStreak(newStreak);

    final next = DailyRewardState(streak: newStreak, lastClaimYmd: todayYmd);
    state = next;
    ref.read(dailyRewardRepositoryProvider).save(next);

    final profile = ref.read(profileControllerProvider.notifier);
    profile.grantCoins(reward);
    profile.registerStreak(newStreak);
    return reward;
  }
}

final dailyRewardControllerProvider =
    NotifierProvider<DailyRewardController, DailyRewardState>(
  DailyRewardController.new,
);
