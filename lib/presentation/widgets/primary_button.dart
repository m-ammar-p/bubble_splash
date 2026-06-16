import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The app's main call-to-action: a glossy liquid-glass pill with a vivid accent
/// gradient, a top sheen, and an accent glow. Disables and dims when
/// [onPressed] is null.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final r = BorderRadius.circular(30);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: r,
                onTap: onPressed,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accent2],
                    ),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Stack(
                    children: [
                      // Top sheen.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        child: Row(
                          mainAxisSize:
                              expand ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: Colors.white),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
