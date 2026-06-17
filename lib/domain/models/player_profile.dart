import 'dart:convert';

/// The player's persistent meta-game state. Pure Dart (no Flutter imports) so it
/// stays trivially testable and backend-agnostic.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    required this.coins,
    required this.xp,
    required this.highScore,
    required this.gamesPlayed,
    required this.totalBubblesPopped,
    required this.bestStreak,
    required this.equippedSkinId,
    required this.ownedSkinIds,
    required this.unlockedAchievementIds,
  });

  final String id;
  final String name;
  final String avatarEmoji;

  /// ARGB int (kept as int to avoid importing Flutter's Color into the domain).
  final int avatarColor;

  final int coins;
  final int xp;
  final int highScore;
  final int gamesPlayed;
  final int totalBubblesPopped;
  final int bestStreak;
  final String equippedSkinId;
  final Set<String> ownedSkinIds;
  final Set<String> unlockedAchievementIds;

  /// A fresh profile for a brand new player.
  factory PlayerProfile.initial({required String id}) => PlayerProfile(
        id: id,
        name: 'Player',
        avatarEmoji: 'bubble',
        avatarColor: 0xFF4FC3F7,
        coins: 0,
        xp: 0,
        highScore: 0,
        gamesPlayed: 0,
        totalBubblesPopped: 0,
        bestStreak: 0,
        equippedSkinId: 'classic',
        ownedSkinIds: const {'classic'},
        unlockedAchievementIds: const {},
      );

  // ---- Level system -------------------------------------------------------
  // Cumulative XP to *reach* a level: 50 * (l-1) * l  →  L1:0 L2:100 L3:300 ...
  // The span of a single level L is therefore 100 * L.
  static int cumulativeXpForLevel(int level) => 50 * (level - 1) * level;

  static int levelForXp(int xp) {
    var level = 1;
    while (cumulativeXpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  int get level => levelForXp(xp);
  int get xpIntoLevel => xp - cumulativeXpForLevel(level);
  int get xpForLevelSpan => 100 * level;
  double get levelProgress =>
      xpForLevelSpan == 0 ? 0 : (xpIntoLevel / xpForLevelSpan).clamp(0.0, 1.0);

  PlayerProfile copyWith({
    String? name,
    String? avatarEmoji,
    int? avatarColor,
    int? coins,
    int? xp,
    int? highScore,
    int? gamesPlayed,
    int? totalBubblesPopped,
    int? bestStreak,
    String? equippedSkinId,
    Set<String>? ownedSkinIds,
    Set<String>? unlockedAchievementIds,
  }) {
    return PlayerProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColor: avatarColor ?? this.avatarColor,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      highScore: highScore ?? this.highScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalBubblesPopped: totalBubblesPopped ?? this.totalBubblesPopped,
      bestStreak: bestStreak ?? this.bestStreak,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'avatarColor': avatarColor,
        'coins': coins,
        'xp': xp,
        'highScore': highScore,
        'gamesPlayed': gamesPlayed,
        'totalBubblesPopped': totalBubblesPopped,
        'bestStreak': bestStreak,
        'equippedSkinId': equippedSkinId,
        'ownedSkinIds': ownedSkinIds.toList(),
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
      };

  factory PlayerProfile.fromMap(Map<String, dynamic> map) => PlayerProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarEmoji: map['avatarEmoji'] as String,
        avatarColor: map['avatarColor'] as int,
        coins: map['coins'] as int,
        xp: map['xp'] as int,
        highScore: map['highScore'] as int,
        gamesPlayed: map['gamesPlayed'] as int,
        totalBubblesPopped: map['totalBubblesPopped'] as int,
        bestStreak: (map['bestStreak'] ?? 0) as int,
        equippedSkinId: map['equippedSkinId'] as String,
        ownedSkinIds: (map['ownedSkinIds'] as List).cast<String>().toSet(),
        unlockedAchievementIds:
            (map['unlockedAchievementIds'] as List).cast<String>().toSet(),
      );

  String toJson() => jsonEncode(toMap());
  factory PlayerProfile.fromJson(String source) =>
      PlayerProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
