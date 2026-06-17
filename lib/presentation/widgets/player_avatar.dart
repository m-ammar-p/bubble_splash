import 'package:flutter/material.dart';

/// Avatar choices, keyed by a stable string stored on the profile. We render a
/// Material **icon** (not an emoji) so avatars display reliably on every device
/// — older Androids often lack a color-emoji font and show blank "tofu" boxes.
const Map<String, IconData> kAvatarIcons = {
  'bubble': Icons.bubble_chart,
  'rocket': Icons.rocket_launch,
  'star': Icons.star_rounded,
  'bolt': Icons.bolt,
  'heart': Icons.favorite,
  'snow': Icons.ac_unit,
  'game': Icons.sports_esports,
  'pet': Icons.pets,
  'flutter': Icons.flutter_dash,
  'shield': Icons.shield_moon,
};

/// The avatar keys in display order (used by the profile picker).
const List<String> kAvatarKeys = [
  'bubble', 'rocket', 'star', 'bolt', 'heart',
  'snow', 'game', 'pet', 'flutter', 'shield',
];

/// Resolves an avatar key to an icon, falling back to the bubble for unknown
/// keys (e.g. legacy profiles that stored an emoji string).
IconData avatarIconFor(String key) => kAvatarIcons[key] ?? Icons.bubble_chart;

/// A circular avatar: a colored disc with a Material icon centered on it.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 48,
  });

  /// Avatar key (see [kAvatarIcons]).
  final String iconKey;
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
      child: Icon(avatarIconFor(iconKey), color: Color(color), size: size * 0.55),
    );
  }
}
