/// Which rewarded-ad flow a view belongs to. `home` also carries the 30-min
/// Free-Life cooldown; `revive` is daily-cap-only (the per-death cap is a
/// runtime client concern, never persisted).
enum RewardedAdKind { home, revive }

/// Server-authoritative rewarded-ad limit state (anti-spoof, Piece 1). Mirrors
/// the fields the app also keeps locally in `RewardedAdMeta`, but sourced from
/// the backend using the **server clock** — so a local prefs edit can't reset
/// the daily cap or the home cooldown for signed-in players.
class AdLimitState {
  const AdLimitState({
    required this.granted,
    required this.dailyCount,
    required this.dailyWindowStartMs,
    required this.homeLastClaimMs,
  });

  /// Whether the server authorized the just-attempted view (only meaningful for
  /// [RewardedAdGate.claimView]; hydration reads report `false`).
  final bool granted;
  final int dailyCount;
  final int dailyWindowStartMs;
  final int homeLastClaimMs;

  factory AdLimitState.fromRpc(Map<String, dynamic> map) => AdLimitState(
        granted: (map['granted'] ?? false) as bool,
        dailyCount: (map['daily_count'] as num?)?.toInt() ?? 0,
        dailyWindowStartMs:
            (map['daily_window_start_ms'] as num?)?.toInt() ?? 0,
        homeLastClaimMs: (map['home_last_claim_ms'] as num?)?.toInt() ?? 0,
      );
}

/// Server-side enforcer for rewarded-ad caps (signed-in users only). The
/// authoritative daily count + home cooldown live in the backend; the manager
/// hydrates local counters from [fetchState] on load and asks [claimView] to
/// authorize each completed view.
///
/// Every method **fails soft**: on a network error, a missing/uninitialized
/// backend, or a guest, it returns null and the caller falls back to the local
/// `RewardedAdMeta` path. Reward = lives only, so a soft-fail (grant locally
/// while offline) is an accepted trade — see REWARDED_ADS.md.
abstract class RewardedAdGate {
  /// The current server-authoritative limit state for hydrating local counters,
  /// or null if unavailable (guest / offline / backend down). Never grants.
  Future<AdLimitState?> fetchState(String accountId);

  /// Authorizes and records one completed view server-side. Returns the verdict
  /// ([AdLimitState.granted]) plus the updated counters, or null on failure
  /// (caller then falls back to the local cap check + grant).
  Future<AdLimitState?> claimView(String accountId, RewardedAdKind kind);
}
