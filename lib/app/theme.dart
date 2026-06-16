import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shared visual language — an Apple "Liquid Glass" palette: deep translucent
/// backdrops, vibrant accents, and frosted surfaces.
abstract final class AppColors {
  static const bgTop = Color(0xFF0B2A47);
  static const bgBottom = Color(0xFF050E18);
  static const accent = Color(0xFF5AC8FA); // iOS cyan
  static const accent2 = Color(0xFF2D8CF0);
  static const gold = Color(0xFFFFD66B);
  static const heart = Color(0xFFFF6B81);
  static const surface = Color(0xFF0E3A55);

  /// Orb colors that glow behind the frosted glass to give it vibrancy.
  static const orbBlue = Color(0xFF1E88E5);
  static const orbPurple = Color(0xFF8E24AA);
  static const orbCyan = Color(0xFF00BCD4);
  static const orbPink = Color(0xFFEC407A);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Full-screen liquid backdrop: a deep gradient with soft, blurred color orbs
/// drifting behind everything. The orbs are what make frosted glass surfaces
/// (which blur whatever is behind them) read as vibrant "liquid glass".
class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bgTop, AppColors.bgBottom],
              ),
            ),
          ),
        ),
        const _Orb(color: AppColors.orbBlue, top: -70, left: -50, size: 260),
        const _Orb(color: AppColors.orbPurple, top: 120, right: -70, size: 230),
        const _Orb(color: AppColors.orbCyan, bottom: -50, left: -40, size: 280),
        const _Orb(color: AppColors.orbPink, bottom: 140, right: -60, size: 190),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double? top, left, right, bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
