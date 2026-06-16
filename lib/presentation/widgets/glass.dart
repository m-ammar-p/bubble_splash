import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A frosted "liquid glass" surface: blurs whatever is behind it, fills with a
/// translucent gradient, adds a bright top specular highlight, a light rim
/// border, and a soft drop shadow for depth. The building block for the UI.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.blur = 18,
    this.tint,
    this.borderColor,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? tint;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final base = tint ?? Colors.white;

    Widget content = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: 0.22),
                base.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Top specular sheen.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: radius * 1.6,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(radius)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
              if (onTap != null)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(borderRadius: r, onTap: onTap),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (shadow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: content,
      );
    }
    return content;
  }
}

/// A compact pill-shaped glass chip (badges, tags).
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 22,
      blur: 12,
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: child,
    );
  }
}

/// A circular glass button (icon-only), used for navigation.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.24),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
