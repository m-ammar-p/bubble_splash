import 'package:flutter/foundation.dart';

/// All AdMob identifiers live here — the single place to update ad IDs.
///
/// **App IDs** (the `~` ids) are declared in native config, not read from Dart:
/// `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
/// and `ios/Runner/Info.plist` (`GADApplicationIdentifier`). They are duplicated
/// here only as documentation — keep the three in sync.
///
/// **Ad-unit IDs** (the `/` ids) are read at runtime by
/// `AdMobRewardedAdProvider`. In [kDebugMode] — or any build passing
/// `--dart-define=USE_TEST_ADS=true` — we serve Google's public **test** unit;
/// clicking a live ad on your own device can get the AdMob account flagged.
/// Plain release builds serve the real unit. Platform is chosen with
/// [defaultTargetPlatform] (no `dart:io`, keeping the file plugin-free-ish and
/// test-safe).
///
/// Sideloading a release APK to test on real hardware would otherwise hit LIVE
/// ads (debug mode is off), so build those with:
/// `flutter build apk --release --dart-define=USE_TEST_ADS=true`.
/// The store build stays `flutter build apk --release` (flag absent → real ads).
/// This replaces per-device AdMob test-device registration — no hashed device
/// IDs to collect or keep in sync.
class AdConfig {
  AdConfig._();

  // ── App IDs (mirror of native config — see class doc) ────────────────────
  static const String androidAppId = 'ca-app-pub-9874648020868564~8829603439';
  // TODO: replace with the real iOS App ID once the iOS AdMob app exists.
  static const String iosAppId = _testIosAppId;

  // ── Real rewarded ad-unit IDs (used in release) ──────────────────────────
  static const String _androidRewardedReal =
      'ca-app-pub-9874648020868564/1000617240';
  // TODO: replace with the real iOS rewarded unit once the iOS app exists.
  static const String _iosRewardedReal = _testIosRewarded;

  // ── Google's public test IDs (used in debug) ─────────────────────────────
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testAndroidRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosRewarded =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Opt-in override so a **release/profile** build can still serve test ads on
  /// real hardware: `--dart-define=USE_TEST_ADS=true`. Compile-time constant, so
  /// a store build (flag absent) tree-shakes straight to the real unit.
  static const bool _forceTestAds =
      bool.fromEnvironment('USE_TEST_ADS', defaultValue: false);

  /// True when this build must serve Google's test unit instead of the real one.
  static bool get usingTestAds => kDebugMode || _forceTestAds;

  /// The rewarded ad-unit id for the current platform + build mode.
  static String get rewardedUnitId {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (usingTestAds) {
      return isIos ? _testIosRewarded : _testAndroidRewarded;
    }
    return isIos ? _iosRewardedReal : _androidRewardedReal;
  }
}
