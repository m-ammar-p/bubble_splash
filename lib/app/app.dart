import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'routes.dart';
import 'theme.dart';

class BubbleSplashApp extends ConsumerWidget {
  const BubbleSplashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Bubble Splash',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      navigatorKey: ref.watch(navigatorKeyProvider),
      initialRoute: Routes.home,
      onGenerateRoute: Routes.onGenerateRoute,
      builder: (context, child) =>
          LiquidBackground(child: child ?? const SizedBox()),
    );
  }
}
