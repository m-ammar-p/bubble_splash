import '../../domain/services/rewarded_ad_gate.dart';

/// No-op [RewardedAdGate] for guests / offline (Supabase not configured) and
/// tests: always returns null, so the manager uses the local `RewardedAdMeta`
/// cap check + grant exactly as before server enforcement existed.
class NoopRewardedAdGate implements RewardedAdGate {
  @override
  Future<AdLimitState?> fetchState(String accountId) async => null;

  @override
  Future<AdLimitState?> claimView(String accountId, RewardedAdKind kind) async =>
      null;
}
