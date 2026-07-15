import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/services/rewarded_ad_gate.dart';

/// Supabase-backed [RewardedAdGate]. Calls the `ad_limit_state` /
/// `claim_ad_view` RPCs (migration 0003), which enforce the daily cap + home
/// cooldown against the **server clock**. The RPCs derive the user from
/// `auth.uid()` (the current session), so [accountId] is used only to decide
/// whether to call at all — a mismatch never grants another user's reward.
///
/// Fails soft: a missing/uninitialized client or any error returns null, and the
/// manager falls back to the local `RewardedAdMeta` path.
class SupabaseRewardedAdGate implements RewardedAdGate {
  sb.SupabaseClient? get _client {
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AdLimitState?> fetchState(String accountId) => _call('ad_limit_state');

  @override
  Future<AdLimitState?> claimView(String accountId, RewardedAdKind kind) =>
      _call('claim_ad_view', params: {
        'p_kind': kind == RewardedAdKind.home ? 'home' : 'revive',
      });

  Future<AdLimitState?> _call(String fn, {Map<String, dynamic>? params}) async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return null;
    try {
      final res = await client.rpc(fn, params: params);
      if (res is Map) {
        return AdLimitState.fromRpc(Map<String, dynamic>.from(res));
      }
      return null;
    } catch (_) {
      return null; // best-effort: offline / RLS / RPC error → local fallback
    }
  }
}
