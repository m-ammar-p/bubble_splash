import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'candy.dart';
import 'routes.dart';

class BubbleSplashApp extends ConsumerWidget {
  const BubbleSplashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No first-launch login gate: everyone boots to Home (fresh installs as a
    // guest, returning accounts restored from prefs). Signing in happens on
    // demand from the shop/profile.
    return MaterialApp(
      title: 'Bubble Splash',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      navigatorKey: ref.watch(navigatorKeyProvider),
      initialRoute: Routes.home,
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}

/// Minimal Material theme under the Candy Cosmos skin: every screen paints its
/// own [CandyNebulaBackground], so the scaffold just needs a matching solid
/// fallback (covers route transitions); snackbars get the violet sheet look.
ThemeData _buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Candy.violet,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Candy.bgBottom,
  );
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Candy.bgMid.withValues(alpha: 0.97),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
