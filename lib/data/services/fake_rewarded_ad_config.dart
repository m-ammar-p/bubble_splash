/// Simulation knobs for [FakeRewardedAdProvider]. All the levers to reproduce
/// real ad failure modes in dev live here — flip a field and hot-reload to force
/// a state. Not used by the real AdMob provider.
///
/// [FakeRewardedAdConfig.debug] is a mutable singleton so you can force
/// scenarios from a debug menu or by editing the defaults:
/// ```dart
/// FakeRewardedAdConfig.debug.forceNoFill = true;    // every load → NO_FILL
/// FakeRewardedAdConfig.debug.forceFailToShow = true; // every show → failedToShow
/// ```
class FakeRewardedAdConfig {
  FakeRewardedAdConfig({
    this.minLoadDelay = const Duration(milliseconds: 500),
    this.maxLoadDelay = const Duration(milliseconds: 1500),
    this.noFillRate = 0.10,
    this.failToShowRate = 0.02,
    this.adDuration = const Duration(seconds: 5),
    this.forceNoFill = false,
    this.forceFailToShow = false,
    this.instant = false,
  });

  /// Randomised load delay range, simulating a network fetch.
  Duration minLoadDelay;
  Duration maxLoadDelay;

  /// Probability [load] returns NO_FILL (0..1). Default 10%.
  double noFillRate;

  /// Probability [show] fails to present after a good load (0..1). Default 2%.
  double failToShowRate;

  /// Fake ad playback length (the overlay countdown).
  Duration adDuration;

  /// Force every load to NO_FILL (drives backoff + the NO_FILL button state).
  bool forceNoFill;

  /// Force every show to failedToShow.
  bool forceFailToShow;

  /// Skip all delays (used by tests so they don't wait on real timers).
  bool instant;

  /// The mutable singleton the provider reads. Override for the whole app.
  static final FakeRewardedAdConfig debug = FakeRewardedAdConfig();
}
