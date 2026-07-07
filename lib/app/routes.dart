import 'package:flutter/material.dart';

import '../presentation/screens/game_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/leaderboard_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/shop_screen.dart';

/// Named routes. Kept centralized so navigation targets are discoverable and a
/// future migration to go_router touches one file.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const game = '/game';
  static const profile = '/profile';
  static const leaderboard = '/leaderboard';
  static const shop = '/shop';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      home => (_) => const HomeScreen(),
      login => (_) => const LoginScreen(),
      game => (_) => const GameScreen(),
      profile => (_) => const ProfileScreen(),
      leaderboard => (_) => const LeaderboardScreen(),
      shop => (_) => const ShopScreen(),
      _ => (_) => const HomeScreen(),
    };
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
