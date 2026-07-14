/// Contract for a single rewarded-ad unit. Pure Dart — no Flutter imports — so
/// the game, UI, and [RewardedAdManager] depend only on this abstraction and can
/// never tell whether the ad is fake or a real AdMob unit.
///
/// A provider models ONE ad at a time: preload it with [load], present it with
/// [show]. An ad is **single-use** — [show] consumes it, and [isReady] returns
/// to false until the next successful [load]. Neither method throws; every
/// failure is reported through the returned enum.
///
/// Swap the fake for `AdMobRewardedAdProvider` at the single injection line in
/// `application/providers.dart` (`rewardedAdServiceProvider`). Nothing else in
/// the app references a concrete implementation.
abstract interface class RewardedAdProvider {
  /// True only after a successful [load] and before [show] consumes the ad.
  bool get isReady;

  /// Preloads a single ad. Idempotent while already loading or ready. Returns
  /// the outcome so the manager can drive no-fill backoff. Never throws.
  Future<RewardedAdLoadResult> load();

  /// Presents the loaded ad. Returns [RewardedAdShowResult.notReady] immediately
  /// when `!isReady`. Consumes the ad (single-use) — call [load] again after.
  /// Never throws.
  Future<RewardedAdShowResult> show();

  /// Releases any resources (fake: dismisses a lingering overlay). Optional.
  void dispose();
}

/// Result of [RewardedAdProvider.load].
enum RewardedAdLoadResult {
  /// An ad is loaded and [RewardedAdProvider.isReady] is now true.
  ready,

  /// The ad network had no ad to serve. The manager backs off and retries.
  noFill,

  /// A transient load error (network etc.). Retriable, like [noFill].
  failed,
}

/// Result of [RewardedAdProvider.show]. The four cases the reward decision and
/// the button state machine must distinguish — do not collapse to a bool.
enum RewardedAdShowResult {
  /// The user watched to the end. **The only value that grants a reward.**
  rewardEarned,

  /// The user skipped/closed early. No reward.
  dismissedWithoutReward,

  /// The ad failed to present after passing readiness. No reward.
  failedToShow,

  /// No ad was ready to show. No reward.
  notReady,
}
