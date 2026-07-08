import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/backend_config.dart';
import 'application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
