import 'package:flutter/material.dart';

import '../../app/candy.dart';

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

/// A circular avatar: a glossy candy bubble in the player's color with a
/// Material icon centered on it (same gloss recipe as the Profile avatar).
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
        shape: BoxShape.circle,
        gradient: candyBubbleGradient(color),
      ),
      child: Icon(avatarIconFor(iconKey),
          color: Colors.white, size: size * 0.5),
    );
  }
}
