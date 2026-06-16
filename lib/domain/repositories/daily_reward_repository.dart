import '../models/daily_reward_state.dart';

/// Persists the daily-reward streak.
abstract interface class DailyRewardRepository {
  DailyRewardState? load();
  void save(DailyRewardState state);
}
