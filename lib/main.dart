import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'application/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
