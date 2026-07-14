import 'dart:convert';

import '../services/rewarded_ad_limits.dart';

/// Persisted limit/cooldown state for rewarded ads. Timestamp-based so the home
/// cooldown and daily cap are correct across app restarts (like lives regen).
/// Pure Dart with all the tamper/reset math as static functions, so it is
/// trivially unit-testable without Riverpod or a clock.
///
/// Persistence is [SharedPreferences] (see `PrefsRewardedAdRepository`). **This
/// is spoofable** — a determined user can clear prefs or edit the timestamps to
/// reset cooldowns and the daily cap. Before monetized launch, move these
/// counters to secure storage or (better) enforce the daily cap server-side.
class RewardedAdMeta {
  const RewardedAdMeta({
    required this.dailyCount,
    required this.dailyWindowStartMs,
    required this.homeLastWatchMs,
  });

  /// Completed rewarded views inside the current [RewardedAdLimits.dailyWindow].
  final int dailyCount;

  /// Epoch millis the current daily window opened. Advances forward only.
  final int dailyWindowStartMs;

  /// Epoch millis of the last home-screen claim (0 = never → claimable).
  final int homeLastWatchMs;

  factory RewardedAdMeta.initial() => const RewardedAdMeta(
        dailyCount: 0,
        dailyWindowStartMs: 0,
        homeLastWatchMs: 0,
      );

  // ---- Daily cap (rolling 24h) -------------------------------------------

  /// Normalizes the window against [nowMs]. Opens/rolls a fresh window (count 0)
  /// only when a *full* [RewardedAdLimits.dailyWindow] has elapsed **forward**.
  ///
  /// Clock-tamper guard: if `nowMs` is before the window start (clock jumped
  /// backwards, or a future anchor from a previous forward-set clock), the
  /// window is NOT reset and the count is preserved — the cap stays active. A
  /// zero anchor (fresh install) is seeded to `nowMs` without resetting count.
  RewardedAdMeta normalizedDaily(int nowMs) {
    if (dailyWindowStartMs == 0) {
      return copyWith(dailyWindowStartMs: nowMs);
    }
    final elapsed = nowMs - dailyWindowStartMs;
    if (elapsed < 0) {
      // Clock moved backwards / anchor is in the future → keep the window.
      return this;
    }
    if (elapsed >= RewardedAdLimits.dailyWindow.inMilliseconds) {
      return RewardedAdMeta(
        dailyCount: 0,
        dailyWindowStartMs: nowMs,
        homeLastWatchMs: homeLastWatchMs,
      );
    }
    return this;
  }

  /// True when the daily view cap is reached for the current window.
  bool dailyCapReached(int nowMs) =>
      normalizedDaily(nowMs).dailyCount >= RewardedAdLimits.dailyViewCap;

  /// Records one completed view: normalizes the window, then increments.
  RewardedAdMeta recordView(int nowMs) {
    final n = normalizedDaily(nowMs);
    return n.copyWith(dailyCount: n.dailyCount + 1);
  }

  // ---- Home cooldown ------------------------------------------------------

  /// Time until the home button is claimable again (zero when ready).
  ///
  /// Clock-tamper guard: if `nowMs` is before [homeLastWatchMs] (clock moved
  /// back, or a future anchor), the FULL cooldown is treated as remaining — a
  /// backwards clock can never unlock the button early.
  Duration homeCooldownRemaining(int nowMs) {
    final cd = RewardedAdLimits.homeCooldown.inMilliseconds;
    if (homeLastWatchMs == 0) return Duration.zero;
    final elapsed = nowMs - homeLastWatchMs;
    if (elapsed < 0) return RewardedAdLimits.homeCooldown; // tamper → still active
    final remaining = cd - elapsed;
    return Duration(milliseconds: remaining.clamp(0, cd));
  }

  bool homeReady(int nowMs) => homeCooldownRemaining(nowMs) == Duration.zero;

  /// Anchors the home cooldown at [nowMs].
  RewardedAdMeta withHomeWatch(int nowMs) => copyWith(homeLastWatchMs: nowMs);

  // ---- boilerplate --------------------------------------------------------

  RewardedAdMeta copyWith({
    int? dailyCount,
    int? dailyWindowStartMs,
    int? homeLastWatchMs,
  }) =>
      RewardedAdMeta(
        dailyCount: dailyCount ?? this.dailyCount,
        dailyWindowStartMs: dailyWindowStartMs ?? this.dailyWindowStartMs,
        homeLastWatchMs: homeLastWatchMs ?? this.homeLastWatchMs,
      );

  Map<String, dynamic> toMap() => {
        'dailyCount': dailyCount,
        'dailyWindowStartMs': dailyWindowStartMs,
        'homeLastWatchMs': homeLastWatchMs,
      };

  factory RewardedAdMeta.fromMap(Map<String, dynamic> map) => RewardedAdMeta(
        dailyCount: (map['dailyCount'] ?? 0) as int,
        dailyWindowStartMs: (map['dailyWindowStartMs'] ?? 0) as int,
        homeLastWatchMs: (map['homeLastWatchMs'] ?? 0) as int,
      );

  String toJson() => jsonEncode(toMap());
  factory RewardedAdMeta.fromJson(String source) =>
      RewardedAdMeta.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
