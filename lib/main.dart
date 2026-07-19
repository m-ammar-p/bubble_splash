import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/backend_config.dart';
import 'app/frame_stats.dart';
import 'application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installFrameStats(); // profile-only frame telemetry (no-op in debug/release)

  // Lock to portrait — the game is designed for a vertical frame only; rotating
  // to landscape scrambles the fixed-scale Candy Cosmos layout.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Bring up Supabase only once real credentials are pasted into
  // BackendConfig; until then the app runs on the fake auth service so guest
  // play and the demo chooser keep working. The SDK restores any saved session
  // here, so a signed-in player boots straight back in.
  if (BackendConfig.isConfigured) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
  }

  // Initialise the AdMob SDK so the first rewarded ad can preload without delay.
  // Fire-and-forget: gameplay never blocks on the ad SDK, and the manager
  // preloads proactively once this resolves.
  unawaited(MobileAds.instance.initialize());

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the warmed key-value store so meta-state repositories can read
        // synchronously (no loading flicker for profile/lives/daily state).
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BubbleSplashApp(),
    ),
  );
}
