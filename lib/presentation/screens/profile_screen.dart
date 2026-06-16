import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../app/theme.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/player_profile.dart';
import '../widgets/glass.dart';
import '../widgets/player_avatar.dart';

/// Maps an achievement's domain [Achievement.iconKey] to a Material icon.
const Map<String, IconData> _achievementIcons = {
  'play': Icons.play_circle,
  'star': Icons.star,
  'bubble': Icons.bubble_chart,
  'level': Icons.military_tech,
  'calendar': Icons.calendar_month,
  'palette': Icons.palette,
};

const _avatarEmojis = ['🫧', '🦊', '🐼', '🐯', '🦄', '🐲', '🐙', '🦅', '🐸', '🐱'];
const _avatarColors = [
  0xFF4FC3F7, 0xFFBA68C8, 0xFFFF8A65, 0xFF81C784, 0xFFFFD54F, 0xFFF06292
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _editAvatar(context, ref, profile),
              child: PlayerAvatar(
                emoji: profile.avatarEmoji,
                color: profile.avatarColor,
                size: 96,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _rename(context, ref, profile),
              icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
              label: Text(
                profile.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _LevelBar(profile: profile),
          const SizedBox(height: 24),
          const Text('Stats',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _StatTile(
                  icon: Icons.star,
                  label: 'High Score',
                  value: '${profile.highScore}'),
              _StatTile(
                  icon: Icons.sports_esports,
                  label: 'Games',
                  value: '${profile.gamesPlayed}'),
              _StatTile(
                  icon: Icons.bubble_chart,
                  label: 'Bubbles',
                  value: '${profile.totalBubblesPopped}'),
              _StatTile(
                  icon: Icons.local_fire_department,
                  label: 'Best Streak',
                  value: '${profile.bestStreak}'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Achievements',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...kAchievements.map((a) {
            final unlocked = profile.unlockedAchievementIds.contains(a.id);
            return _AchievementTile(achievement: a, unlocked: unlocked);
          }),
        ],
      ),
    );
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, PlayerProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Your name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLength: 16,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null) ref.read(profileControllerProvider.notifier).rename(name);
  }

  Future<void> _editAvatar(
      BuildContext context, WidgetRef ref, PlayerProfile profile) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick an avatar',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final e in _avatarEmojis)
                  GestureDetector(
                    onTap: () => ref
                        .read(profileControllerProvider.notifier)
                        .setAvatar(emoji: e),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _avatarColors)
                  GestureDetector(
                    onTap: () => ref
                        .read(profileControllerProvider.notifier)
                        .setAvatar(color: c),
                    child: CircleAvatar(backgroundColor: Color(c), radius: 16),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level ${profile.level}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${profile.xpIntoLevel} / ${profile.xpForLevelSpan} XP',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: profile.levelProgress,
            minHeight: 10,
            backgroundColor: Colors.white12,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 14,
      blur: 14,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile(
      {required this.achievement, required this.unlocked});
  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        radius: 14,
        blur: 14,
        shadow: false,
        tint: unlocked ? AppColors.gold : Colors.white,
        borderColor:
            unlocked ? AppColors.gold.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              unlocked
                  ? (_achievementIcons[achievement.iconKey] ??
                      Icons.emoji_events)
                  : Icons.lock,
              color: unlocked ? AppColors.gold : Colors.white38,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold)),
                Text(achievement.description,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
            if (unlocked)
              const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}
