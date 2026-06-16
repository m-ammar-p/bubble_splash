import 'package:flutter/material.dart';

/// A circular avatar: a colored disc with an emoji centered on it.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 48,
  });

  final String emoji;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(color).withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Color(color), width: 2),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
