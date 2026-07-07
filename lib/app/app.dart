import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../application/providers.dart';
import 'candy.dart';
import 'routes.dart';

class BubbleSplashApp extends ConsumerWidget {
  const BubbleSplashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auth gate: fresh installs land on the login screen, returning players
    // go straight home. Only the first build matters (initialRoute is read
    // once); later auth changes navigate explicitly (login/sign-out flows).
    final decided = ref.watch(authControllerProvider).decided;
    return MaterialApp(
      title: 'Bubble Splash',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      navigatorKey: ref.watch(navigatorKeyProvider),
      initialRoute: decided ? Routes.home : Routes.login,
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
