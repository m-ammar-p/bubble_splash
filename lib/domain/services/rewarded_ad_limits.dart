/// **Single source of truth for every rewarded-ad limit.** Change a cap here and
/// it applies to both the death-revive and home-screen flows. The real AdMob
/// swap does not touch this file.
class RewardedAdLimits {
  RewardedAdLimits._();

  /// Max ad revives offered per death event (per continue prompt). After this
  /// the revive button is CONSUMED (hidden). Resets on the next death.
  static const int maxRevivesPerDeath = 3;

  /// Cooldown on the home-screen "watch ad for a life" button.
  static const Duration homeCooldown = Duration(minutes: 30);

  /// Global cap on completed rewarded views per rolling window (see
  /// [dailyWindow]). Counts only [RewardedAdShowResult.rewardEarned] — a
  /// skipped or failed ad is not a monetizable view and is not counted.
  static const int dailyViewCap = 20;

  /// The daily cap uses a **rolling 24h window** (not local-midnight) — no
  /// timezone/DST edges, and it resists clock-nudging better. The window's
  /// anchor advances only forward (see `RewardedAdMeta`).
  static const Duration dailyWindow = Duration(hours: 24);

  /// Exponential backoff schedule after a NO_FILL (or failed load): 1s, 2s, 4s,
  /// 8s, … doubling until [backoffCap]. Index clamps to the last value.
  static const Duration firstBackoff = Duration(seconds: 1);
  static const Duration backoffCap = Duration(seconds: 60);

  /// Backoff delay for the Nth consecutive no-fill (0-based): 1s, 2s, 4s, 8s,
  /// 16s, 32s, 60s (capped).
  static Duration backoffFor(int consecutiveNoFills) {
    if (consecutiveNoFills <= 0) return firstBackoff;
    var ms = firstBackoff.inMilliseconds << consecutiveNoFills; // *2^n
    final cap = backoffCap.inMilliseconds;
    if (ms > cap || ms <= 0) ms = cap; // <=0 guards int overflow on huge n
    return Duration(milliseconds: ms);
  }
}
