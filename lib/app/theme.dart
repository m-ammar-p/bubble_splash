import 'package:flutter/material.dart';

abstract final class AppColors {
  // Deeper, more dramatic dark background
  static const bgTop = Color(0xFF06101F);
  static const bgBottom = Color(0xFF020408);

  // Vivid gaming accents
  static const accent = Color(0xFF38D4F5);      // electric cyan
  static const accent2 = Color(0xFF1870C8);     // deep blue
  static const gold = Color(0xFFFFD166);
  static const heart = Color(0xFFFF5572);
  static const surface = Color(0xFF0C3350);

  // Gaming-specific neon colors
  static const neon = Color(0xFF00FFC8);         // emerald neon — combos
  static const neonPurple = Color(0xFFBF5FFF);   // violet neon — special effects

  // Orb palette (more saturated)
  static const orbBlue    = Color(0xFF1565C0);
  static const orbPurple  = Color(0xFF7B1FA2);
  static const orbCyan    = Color(0xFF00838F);
  static const orbPink    = Color(0xFFAD1457);
  static const orbEmerald = Color(0xFF1B5E20);
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

/// While > 0, the animated background freezes its controller. An animating
/// backdrop forces every `BackdropFilter` on top (the in-game HUD glass) to
/// re-blur every frame because its cache is invalidated — the main HUD cost
/// during gameplay. [GameScreen] bumps this for the life of a round so those
/// blurs can cache; the orbs simply hold still (look preserved).
final ValueNotifier<int> activeGameplayCount = ValueNotifier<int>(0);

/// Full-screen liquid backdrop with animated, slowly pulsing color orbs.
/// The animation breathes the orb sizes and intensities over an 8-second cycle,
/// giving a living, atmospheric feel behind the glass surfaces.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key, required this.child});
  final Widget child;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    activeGameplayCount.addListener(_syncAnimation);
    _syncAnimation();
  }

  /// Freeze the pulse while a round is on screen so HUD BackdropFilters cache.
  void _syncAnimation() {
    if (activeGameplayCount.value > 0) {
      if (_ctrl.isAnimating) _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    activeGameplayCount.removeListener(_syncAnimation);
    _ctrl.dispose();
    super.dispose();
  }

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
        // Soft color orbs. These use a RadialGradient (color → transparent)
        // rather than an ImageFilter.blur: a gradient fill is GPU-cheap and can
        // animate every frame, whereas a large-sigma gaussian blur recomputed
        // per frame tanks the frame rate (and also defeats caching of any
        // BackdropFilter glass rendered on top — e.g. the in-game HUD).
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final t = _ctrl.value;
              return Stack(
                children: [
                  _Orb(color: AppColors.orbBlue,    top: -120 + t * 20,    left: -120,          size: 520 + t * 60, alpha: 0.55 + t * 0.10),
                  _Orb(color: AppColors.orbPurple,  top: 80 - t * 20,      right: -140,         size: 460 + t * 50, alpha: 0.50 + t * 0.10),
                  _Orb(color: AppColors.orbCyan,    bottom: -120 + t * 20, left: -110,          size: 540 + t * 60, alpha: 0.48 + t * 0.08),
                  _Orb(color: AppColors.orbPink,    bottom: 100 - t * 25,  right: -130,         size: 400 + t * 45, alpha: 0.50 + t * 0.08),
                  _Orb(color: AppColors.orbEmerald, top: 180 + t * 30,     left: -20 + t * 20,  size: 340 + t * 35, alpha: 0.34 + t * 0.08),
                ],
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    required this.alpha,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double alpha;
  final double? top, left, right, bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
