import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/ad_config.dart';
import '../../domain/services/rewarded_ad_provider.dart';

/// Real AdMob implementation of [RewardedAdProvider]. Wraps a single
/// `RewardedAd` at a time: [load] preloads one, [show] presents and consumes it.
///
/// This is the ONLY file that touches `google_mobile_ads` for rewarded ads. The
/// manager, UI, limits, and reward logic depend solely on [RewardedAdProvider],
/// so if you find yourself editing them to make ads work, the abstraction leaked
/// — fix it here instead (see REWARDED_ADS.md).
///
/// Contract obligations preserved:
/// - never throws — every failure maps to an enum;
/// - single-use — [show] nulls the ad, so [isReady] is false until the next
///   [load]; a repeat [show] returns [RewardedAdShowResult.notReady];
/// - reward only on the `onUserEarnedReward` callback → [RewardedAdShowResult.rewardEarned].
class AdMobRewardedAdProvider implements RewardedAdProvider {
  RewardedAd? _ad;
  bool _loading = false;

  /// A load must never wedge the provider: if AdMob invokes neither callback,
  /// `_loading` would stay true forever and every later load would short-circuit
  /// to `failed` — a permanently dead ad button with no way back.
  static const Duration _loadTimeout = Duration(seconds: 30);

  /// The SDK-initialisation future, shared by every load.
  ///
  /// `main()` kicks `MobileAds.initialize()` off unawaited so startup isn't
  /// blocked, but **a `RewardedAd.load` issued before init completes fails**.
  /// Release builds start fast enough that the first preload (Home's post-frame
  /// callback) reliably lost that race, which is why ads worked under `flutter
  /// run` (slower startup, init won) but not in a release APK — on either the
  /// emulator or a physical device. Awaiting here removes the race entirely;
  /// `initialize()` is idempotent, so this reuses main's in-flight call.
  static Future<InitializationStatus>? _initFuture;

  static Future<void> _ensureInitialized() async {
    try {
      _initFuture ??= MobileAds.instance.initialize();
      await _initFuture;
    } catch (e) {
      _initFuture = null; // let the next load retry initialisation
      debugPrint('[ads] SDK init failed: $e');
    }
  }

  @override
  bool get isReady => _ad != null;

  @override
  Future<RewardedAdLoadResult> load() async {
    if (_ad != null) return RewardedAdLoadResult.ready;
    if (_loading) return RewardedAdLoadResult.failed; // one in flight already
    _loading = true;

    await _ensureInitialized();

    final completer = Completer<RewardedAdLoadResult>();
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          debugPrint('[ads] loaded unit=${AdConfig.rewardedUnitId}');
          if (!completer.isCompleted) {
            completer.complete(RewardedAdLoadResult.ready);
          }
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          // Logged in every build mode (including release sideloads): the UI
          // collapses every failure into one "No ad available" label, so
          // without this the code (no-fill vs misconfigured unit vs network) is
          // unrecoverable on real hardware. Load failures are rare — no spam.
          debugPrint(
            '[ads] load failed code=${error.code} domain=${error.domain} '
            'msg=${error.message} unit=${AdConfig.rewardedUnitId}',
          );
          // AdMob no-fill == code 3 (NO_FILL). Anything else is a transient
          // load error the manager retries with the same backoff.
          final result = error.code == 3
              ? RewardedAdLoadResult.noFill
              : RewardedAdLoadResult.failed;
          if (!completer.isCompleted) completer.complete(result);
        },
      ),
    );
    // A silent AdMob callback must not wedge the provider (see [_loadTimeout]);
    // report `failed` so the manager's backoff owns the retry. A late
    // `onAdLoaded` still fills `_ad`, so the next load returns `ready`.
    return completer.future.timeout(
      _loadTimeout,
      onTimeout: () {
        _loading = false;
        debugPrint('[ads] load timed out after ${_loadTimeout.inSeconds}s');
        return RewardedAdLoadResult.failed;
      },
    );
  }

  @override
  Future<RewardedAdShowResult> show() async {
    final ad = _ad;
    if (ad == null) return RewardedAdShowResult.notReady;
    _ad = null; // single-use: consumed the moment we attempt to show

    final completer = Completer<RewardedAdShowResult>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earned
                ? RewardedAdShowResult.rewardEarned
                : RewardedAdShowResult.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdShowResult.failedToShow);
        }
      },
    );

    ad.show(
      onUserEarnedReward: (_, _) => earned = true,
    );

    return completer.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
