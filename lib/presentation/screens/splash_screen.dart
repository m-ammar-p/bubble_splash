import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/candy.dart';
import '../../app/routes.dart';

/// Animated launch screen (Candy Cosmos "Splash / launch" handoff).
///
/// Shown right after the OS cold-start frame for ~2.3s, then replaces itself
/// with Home. Everything is drawn with gradients — no bitmap bubbles — so it
/// stays crisp at every resolution. All spec px values come from the handoff's
/// 322px-wide reference frame and are multiplied by [candyScale].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// How long the splash lingers before routing to Home. `main()` has already
  /// warmed prefs / Supabase before the first frame, so this is a brand moment,
  /// not a real load wait.
  static const _holdDuration = Duration(milliseconds: 2300);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Pop-in of hero cluster + wordmark (once). 820ms so the wordmark's 0.12s
  // delay still fits its own ~0.7s pop inside a single controller.
  late final AnimationController _entrance;
  // Shard burst (once), staggered per-shard via Intervals.
  late final AnimationController _shards;
  // Loops.
  late final AnimationController _drift; // hero ±10px vertical, 5.6s
  late final AnimationController _glow; // glow disc opacity, 2.4s
  late final AnimationController _dots; // loader dots, 1.4s

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
    _shards = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Shards fire just after the pop starts; drift kicks in once the cluster
    // has settled (spec: center drift begins at 0.7s), so the entrance never
    // fights the float.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _shards.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _drift.repeat(reverse: true);
    });

    Future.delayed(SplashScreen._holdDuration, _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shards.dispose();
    _drift.dispose();
    _glow.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      // Tapping the screen skips straight to Home (impatient players).
      body: GestureDetector(
        onTap: _goHome,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            const _SplashBackground(),

            // Ambient bubbles (behind the lockup). Positioned by screen edge +
            // height fraction so they sit sensibly on any aspect ratio.
            Positioned(
              left: -24 * s,
              top: size.height * (120 / 690),
              child: const _AmbientBubble(
                diameter: 90,
                light: Candy.violetLight,
                mid: Candy.violet,
                dark: Candy.violetDark,
                opacity: 0.5,
                blur: 2,
                travel: -6,
                durationMs: 6000,
              ),
            ),
            Positioned(
              right: -18 * s,
              top: size.height * (1 - 150 / 690) - 70 * s,
              child: const _AmbientBubble(
                diameter: 70,
                light: Candy.mintLight,
                mid: Candy.mint,
                dark: Candy.mintDark,
                opacity: 0.55,
                blur: 1,
                travel: 9,
                durationMs: 5400,
              ),
            ),
            Positioned(
              right: 44 * s,
              top: size.height * (96 / 690),
              child: const _AmbientBubble(
                diameter: 34,
                light: Candy.yellowLight,
                mid: Candy.yellow,
                dark: Candy.yellowDark,
                opacity: 0.6,
                blur: 0,
                travel: -6,
                durationMs: 4600,
              ),
            ),

            // Center lockup: popping hero + shards, then the wordmark.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHero(s),
                  SizedBox(height: 20 * s),
                  _buildWordmark(s),
                ],
              ),
            ),

            // Loader dots ~96px from bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 96 * s,
              child: _LoaderDots(controller: _dots),
            ),

            // Footer ~30px from bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 30 * s,
              child: Text(
                'v1.0 · made with 🫧',
                textAlign: TextAlign.center,
                style: Candy.ui(
                  size: 12 * s,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The 180px hero box: pop-in scale/fade (once) + gentle vertical drift
  /// (loop), holding the glow disc, orange hero bubble, two small bubbles and
  /// the bursting shards.
  Widget _buildHero(double s) {
    final box = 180.0 * s;
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _drift, _glow, _shards]),
      builder: (context, _) {
        final e = _popValue(_entrance.value, delay: 0.0);
        final driftY = _drift.isAnimating || _drift.value > 0
            ? -10 * s * Curves.easeInOut.transform(_drift.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(0, driftY),
          child: Opacity(
            opacity: e.opacity,
            child: Transform.scale(
              scale: e.scale,
              child: SizedBox(
                width: box,
                height: box,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Pulsing warm glow disc (inset 14%).
                    Positioned(
                      left: box * 0.14,
                      top: box * 0.14,
                      right: box * 0.14,
                      bottom: box * 0.14,
                      child: Opacity(
                        opacity: 0.55 + 0.35 * _glow.value,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0x8CFFE6B4), // rgba(255,230,180,.55)
                                Color(0x47FF9D3D), // rgba(255,157,61,.28)
                                Color(0x00FF9D3D),
                              ],
                              stops: [0.0, 0.42, 0.72],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Orange hero bubble — 56% of box, centred-low.
                    Positioned(
                      left: box * 0.24,
                      top: box * 0.20,
                      width: box * 0.56,
                      height: box * 0.56,
                      child: _GlossyBubble(
                        light: Candy.orangeLight,
                        mid: Candy.orange,
                        dark: Candy.orangeDark,
                        glow: const Color(0xFFFF8F1F).withValues(alpha: 0.5),
                        glowBlur: box * 0.22,
                      ),
                    ),
                    // Small mint bubble, upper-left (26%).
                    Positioned(
                      left: box * 0.08,
                      top: box * 0.06,
                      width: box * 0.26,
                      height: box * 0.26,
                      child: _GlossyBubble(
                        light: Candy.mintLight,
                        mid: Candy.mint,
                        dark: Candy.mintDark,
                        glow: Candy.mint.withValues(alpha: 0.4),
                        glowBlur: box * 0.09,
                      ),
                    ),
                    // Small yellow bubble, upper-right (20%).
                    Positioned(
                      left: box * 0.62,
                      top: box * 0.02,
                      width: box * 0.20,
                      height: box * 0.20,
                      child: const _GlossyBubble(
                        light: Candy.yellowLight,
                        mid: Candy.yellow,
                        dark: Candy.yellowDark,
                      ),
                    ),
                    // Four white shards + one cream dot bursting outward.
                    _Shard(
                      box: box,
                      leftFrac: 0.80,
                      topFrac: 0.44,
                      sizeFrac: 0.09,
                      rotationDeg: 0,
                      to: Offset(20 * s, -6 * s),
                      start: 0.30,
                      controller: _shards,
                    ),
                    _Shard(
                      box: box,
                      leftFrac: 0.74,
                      topFrac: 0.70,
                      sizeFrac: 0.07,
                      rotationDeg: 130,
                      to: Offset(16 * s, 14 * s),
                      start: 0.38,
                      controller: _shards,
                    ),
                    _Shard(
                      box: box,
                      leftFrac: 0.16,
                      topFrac: 0.74,
                      sizeFrac: 0.08,
                      rotationDeg: -130,
                      to: Offset(-16 * s, 14 * s),
                      start: 0.34,
                      controller: _shards,
                    ),
                    _Shard(
                      box: box,
                      leftFrac: 0.06,
                      topFrac: 0.40,
                      sizeFrac: 0.06,
                      rotationDeg: -90,
                      to: Offset(-20 * s, -2 * s),
                      start: 0.42,
                      controller: _shards,
                    ),
                    _Shard(
                      box: box,
                      leftFrac: 0.50,
                      topFrac: 0.88,
                      sizeFrac: 0.05,
                      rotationDeg: 0,
                      to: Offset(0, 20 * s),
                      start: 0.46,
                      controller: _shards,
                      isDot: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Wordmark "BUBBLE / SPLASH" — reuses the shared glowing title, pop-in
  /// delayed ~0.12 of the entrance timeline.
  Widget _buildWordmark(double s) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final e = _popValue(_entrance.value, delay: 0.146);
        return Opacity(
          opacity: e.opacity,
          child: Transform.scale(scale: e.scale, child: child),
        );
      },
      child: const CandyGameTitle(size: 52),
    );
  }
}

/// A gentle "settle-in" sample: scale `0.94 → 1.0` with a soft fade, no
/// overshoot. Deliberately understated so the animated screen reads as a
/// *continuation* of the OS cold-start icon splash (which already showed the
/// cluster), not a fresh re-pop. [delay] shifts the start within the shared
/// entrance timeline (0..1).
({double scale, double opacity}) _popValue(double t, {required double delay}) {
  const span = 0.8; // fraction of the timeline the settle occupies
  final local = ((t - delay) / span).clamp(0.0, 1.0);
  final eased = Curves.easeOut.transform(local);
  final scale = 0.94 + 0.06 * eased;
  final opacity = (local / 0.5).clamp(0.0, 1.0);
  return (scale: scale, opacity: opacity);
}

/// The splash background: base cosmos gradient + warm orange centre glow + pink
/// corner glow. Static → rasterized once into its own layer.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        children: [
          // linear-gradient(160deg,#241046,#120830 55%,#0b0520)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.4, -1.0),
                  end: Alignment(0.4, 1.0),
                  colors: [Color(0xFF241046), Color(0xFF120830), Color(0xFF0B0520)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Warm orange glow ~50% 40%, fading by ~60%.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 0.9,
                  colors: [Color(0x33FF9D3D), Color(0x00FF9D3D)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),
          // Pink glow ~92% 12%.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.84, -0.76),
                  radius: 1.1,
                  colors: [Color(0x33FF6B8B), Color(0x00FF6B8B)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glossy candy bubble: white specular highlight → light → mid → dark, with an
/// optional soft coloured glow underneath. Drawn purely with a radial gradient
/// (README: never bitmap the bubbles).
class _GlossyBubble extends StatelessWidget {
  const _GlossyBubble({
    required this.light,
    required this.mid,
    required this.dark,
    this.glow,
    this.glowBlur = 0,
  });

  final Color light;
  final Color mid;
  final Color dark;
  final Color? glow;
  final double glowBlur;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.36, -0.56), // ~32% 22% highlight
          radius: 1.0,
          colors: [Colors.white, light, mid, dark],
          stops: const [0.0, 0.16, 0.5, 1.0],
        ),
        boxShadow: glow != null && glowBlur > 0
            ? [
                BoxShadow(
                  color: glow!,
                  blurRadius: glowBlur,
                  offset: Offset(0, glowBlur * 0.35),
                ),
              ]
            : null,
      ),
    );
  }
}

/// One burst particle: a white triangular shard (or a cream dot) that flies
/// outward from the hero — translate `0 → to`, scale `0.3 → 1`, fade in — over
/// the shared [controller], gated to start at [start] (0..1) of its timeline.
class _Shard extends StatelessWidget {
  const _Shard({
    required this.box,
    required this.leftFrac,
    required this.topFrac,
    required this.sizeFrac,
    required this.rotationDeg,
    required this.to,
    required this.start,
    required this.controller,
    this.isDot = false,
  });

  final double box;
  final double leftFrac;
  final double topFrac;
  final double sizeFrac;
  final double rotationDeg;
  final Offset to;
  final double start;
  final AnimationController controller;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    final side = box * sizeFrac;
    // shardOut runs over the remaining timeline after `start`.
    final local = ((controller.value - start) / (1 - start)).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(local);
    final scale = 0.3 + 0.7 * eased;
    final opacity = local < 0.4 ? (local / 0.4) * 0.9 : 0.9;
    final child = SizedBox(
      width: side,
      height: side,
      child: isDot
          ? const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE9C9),
              ),
            )
          : CustomPaint(painter: const _TrianglePainter()),
    );
    return Positioned(
      left: box * leftFrac,
      top: box * topFrac,
      child: Transform.translate(
        offset: Offset(to.dx * eased, to.dy * eased),
        child: Transform.rotate(
          angle: rotationDeg * math.pi / 180,
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      ),
    );
  }
}

/// White isoceles triangle: `polygon(50% 0, 85% 100%, 15% 100%)`.
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}

/// A blurred, translucent ambient bubble that floats gently forever.
class _AmbientBubble extends StatefulWidget {
  const _AmbientBubble({
    required this.diameter,
    required this.light,
    required this.mid,
    required this.dark,
    required this.opacity,
    required this.blur,
    required this.travel,
    required this.durationMs,
  });

  final double diameter;
  final Color light;
  final Color mid;
  final Color dark;
  final double opacity;
  final double blur;
  final double travel;
  final int durationMs;

  @override
  State<_AmbientBubble> createState() => _AmbientBubbleState();
}

class _AmbientBubbleState extends State<_AmbientBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);
    _y = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final d = widget.diameter * s;
    Widget orb = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.32, -0.48),
          radius: 1.0,
          colors: [Colors.white, widget.light, widget.mid, widget.dark],
          stops: const [0.0, 0.20, 0.56, 1.0],
        ),
      ),
    );
    if (widget.blur > 0) {
      // Cheap "soft" look without a per-frame ImageFilter: a translucent glow
      // ring instead of a live gaussian blur (PERF_NOTES rule).
      orb = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.mid.withValues(alpha: 0.35 * widget.opacity),
              blurRadius: widget.blur * 4 * s,
            ),
          ],
        ),
        child: orb,
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _y,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.travel * s * _y.value),
          child: child,
        ),
        child: Opacity(opacity: widget.opacity, child: orb),
      ),
    );
  }
}

/// Three loader dots pulsing in sequence (`dotPulse`, 1.4s, staggered 0.2s).
class _LoaderDots extends StatelessWidget {
  const _LoaderDots({required this.controller});

  final AnimationController controller;

  static const _colors = [Color(0xFFFF9D3D), Color(0xFFFF6B8B), Color(0xFF4BE0A5)];

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final d = 13.0 * s;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: 12 * s),
              _dot(i, d),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(int i, double d) {
    // dotPulse: scale .6/opacity .35 baseline, peaking to 1/1 at 40% of cycle,
    // each dot phase-shifted 0.2s within the 1.4s loop.
    final t = (controller.value + i * (0.2 / 1.4)) % 1.0;
    final double p; // 0..1 pulse amount
    if (t < 0.4) {
      p = t / 0.4;
    } else if (t < 0.8) {
      p = 1 - (t - 0.4) / 0.4;
    } else {
      p = 0;
    }
    final scale = 0.6 + 0.4 * p;
    final opacity = 0.35 + 0.65 * p;
    final color = _colors[i];
    return Transform.scale(
      scale: scale,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.7 * opacity),
              blurRadius: 10 * (d / 13),
            ),
          ],
        ),
      ),
    );
  }
}
