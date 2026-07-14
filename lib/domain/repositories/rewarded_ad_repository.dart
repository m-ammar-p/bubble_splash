import '../models/rewarded_ad_meta.dart';

/// Persists rewarded-ad limit state (daily cap window + home cooldown).
/// Synchronous, like the other prefs-backed meta repositories.
abstract interface class RewardedAdRepository {
  RewardedAdMeta? load();
  void save(RewardedAdMeta meta);
}
