import 'player_profile.dart';

/// A milestone the player can unlock. [isUnlocked] is a pure predicate over the
/// profile, so the catalog doubles as the unlock-evaluation logic. [iconKey] is
/// mapped to an actual icon in the presentation layer (domain stays Flutter-free).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool Function(PlayerProfile profile) isUnlocked;
}

/// The full achievement catalog. Conditions read only from [PlayerProfile]
/// (note: [PlayerProfile.bestStreak] is maintained by the daily-reward flow).
const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_pop',
    title: 'First Splash',
    description: 'Play your first game',
    iconKey: 'play',
    isUnlocked: _firstPop,
  ),
  Achievement(
    id: 'score_1000',
    title: 'Sharpshooter',
    description: 'Reach a high score of 1,000',
    iconKey: 'star',
    isUnlocked: _score1000,
  ),
  Achievement(
    id: 'pop_1000',
    title: 'Bubble Hunter',
    description: 'Pop 1,000 bubbles in total',
    iconKey: 'bubble',
    isUnlocked: _pop1000,
  ),
  Achievement(
    id: 'level_5',
    title: 'Rising Star',
    description: 'Reach level 5',
    iconKey: 'level',
    isUnlocked: _level5,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Dedicated',
    description: 'Claim a 7-day reward streak',
    iconKey: 'calendar',
    isUnlocked: _streak7,
  ),
  Achievement(
    id: 'collector',
    title: 'Collector',
    description: 'Own 3 bubble skins',
    iconKey: 'palette',
    isUnlocked: _collector,
  ),
];

bool _firstPop(PlayerProfile p) => p.gamesPlayed >= 1;
bool _score1000(PlayerProfile p) => p.highScore >= 1000;
bool _pop1000(PlayerProfile p) => p.totalBubblesPopped >= 1000;
bool _level5(PlayerProfile p) => p.level >= 5;
bool _streak7(PlayerProfile p) => p.bestStreak >= 7;
bool _collector(PlayerProfile p) => p.ownedSkinIds.length >= 3;
