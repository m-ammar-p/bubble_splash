import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Candy Cosmos" design tokens + shared widgets, from the design handoff
/// (`docs/design/candy_cosmos_handoff.md`). All spec px values live in a
/// 322px-wide reference frame; multiply them by [candyScale].
abstract final class Candy {
  // Background
  static const bgTop = Color(0xFF2C1256);
  static const bgMid = Color(0xFF170B38);
  static const bgBottom = Color(0xFF100728);

  // Accents
  static const orange = Color(0xFFFF9D3D);
  static const orangeLight = Color(0xFFFFD69E);
  static const orangeDark = Color(0xFFC25E00);
  static const orangeCtaTop = Color(0xFFFFC24D);
  static const orangeCtaBottom = Color(0xFFFF8F1F);
  static const ctaInk = Color(0xFF4A2400); // dark brown text on orange CTA

  static const pink = Color(0xFFFF6B8B);
  static const pinkLight = Color(0xFFFFC2CF);
  static const pinkDark = Color(0xFFC22A52);

  static const mint = Color(0xFF4BE0A5);
  static const mintLight = Color(0xFFC8FFE6);
  static const mintDark = Color(0xFF12946A);

  static const yellow = Color(0xFFFFD93D);
  static const yellowLight = Color(0xFFFFF3B0);
  static const yellowDark = Color(0xFFC79600);

  static const violet = Color(0xFF8A5BFF);
  static const violetLight = Color(0xFFC8A6FF);
  static const violetDark = Color(0xFF5A2FC2);

  static const heart = Color(0xFFFF5B6E);
  static const heartLight = Color(0xFFFFB0B0);
  static const heartDark = Color(0xFFC22A3A);

  // Text
  static const titleText = Color(0xFFFFE9C9);
  static const timer = Color(0xFFFFC07A);
  static const comboLabel = Color(0xFFFF8296);

  // Chip gradients (26px stat icon chips)
  static const coinsChip = [Color(0xFFFFE38A), Color(0xFFFFC23D), Color(0xFFC88A00)];
  static const levelChip = [violetLight, violet, violetDark];
  static const livesChip = [heartLight, heart, heartDark];
  static const orangeChip = [orangeLight, orange, orangeDark];
  static const yellowChip = [yellowLight, yellow, yellowDark];

  /// Glass surface / border for pills, tiles, cards.
  static Color glass([double alpha = 0.10]) => Colors.white.withValues(alpha: alpha);
  static Color glassBorder([double alpha = 0.16]) =>
      Colors.white.withValues(alpha: alpha);

  // Fonts
  static TextStyle display({
    required double size,
    Color color = titleText,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) =>
      GoogleFonts.baloo2(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );

  static TextStyle ui({
    required double size,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.nunito(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );
}

/// Proportional scale from the 322px-wide design frame to the real screen.
double candyScale(BuildContext context) => MediaQuery.sizeOf(context).width / 322.0;

/// Layered nebula background: base violet gradient + pink glow (top-left) +
/// orange glow (top-right). Static (GPU-cheap, never invalidates glass caches).
class CandyNebulaBackground extends StatelessWidget {
  const CandyNebulaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // linear-gradient(160deg, #2C1256, #170B38 55%, #100728)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1.0),
                end: Alignment(0.5, 1.0),
                colors: [Candy.bgTop, Candy.bgMid, Candy.bgBottom],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Pink nebula glow at 18% 2%.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.64, -0.96),
                radius: 1.1,
                colors: [Color(0x4DFF6B8B), Color(0x00FF6B8B)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
        ),
        // Orange nebula glow at 92% 16%.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.84, -0.68),
                radius: 1.2,
                colors: [Color(0x3DFF9D3D), Color(0x00FF9D3D)],
                stops: [0.0, 0.55],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plain translucent "glass" surface per the spec (no backdrop blur — cheap and
/// exactly matches `rgba(255,255,255,.08–.10)` + 1px border).
class CandyGlass extends StatelessWidget {
  const CandyGlass({
    super.key,
    required this.child,
    this.radius = 999,
    this.padding = EdgeInsets.zero,
    this.surfaceAlpha = 0.10,
    this.borderAlpha = 0.16,
    this.onTap,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double surfaceAlpha;
  final double borderAlpha;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: Candy.glass(surfaceAlpha),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Candy.glassBorder(borderAlpha)),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

/// Radial-gradient icon chip (the 24–56px circles inside pills/cards).
class CandyChip extends StatelessWidget {
  const CandyChip({
    super.key,
    required this.colors,
    required this.size,
    required this.child,
  });

  final List<Color> colors;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.32, -0.44),
          radius: 0.9,
          colors: colors,
          stops: const [0.0, 0.60, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// The warm orange 3D call-to-action (PLAY / Continue / PLAY AGAIN): orange
/// gradient, lift + glow on press (0.15s ease). Disabled = dimmed, no press.
class CandyCtaButton extends StatefulWidget {
  const CandyCtaButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 54,
    this.radius = 18,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double radius;

  @override
  State<CandyCtaButton> createState() => _CandyCtaButtonState();
}

class _CandyCtaButtonState extends State<CandyCtaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final enabled = widget.onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _down ? -2 * s : 0, 0),
          height: widget.height * s,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius * s),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Candy.orangeCtaTop, Candy.orangeCtaBottom],
            ),
            boxShadow: [
              BoxShadow(
                color: Candy.orangeCtaBottom
                    .withValues(alpha: _down ? 0.66 : 0.50),
                blurRadius: (_down ? 44 : 34) * s,
                offset: Offset(0, (_down ? 18 : 12) * s),
              ),
            ],
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55), width: 2 * s),
            ),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// The violet bottom-sheet / result-card surface (screens 04 & 05):
/// radius 26, `rgba(72,38,110,.92) → rgba(34,16,60,.96)` gradient, light border.
class CandySheet extends StatelessWidget {
  const CandySheet({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEB48266E), Color(0xF522103C)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          shadow ??
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 50 * s,
                offset: Offset(0, -18 * s),
              ),
        ],
      ),
      child: child,
    );
  }
}
