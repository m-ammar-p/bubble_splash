import 'dart:convert';

/// Tracks the daily login-reward streak. [lastClaimYmd] is an integer date key
/// (yyyymmdd) so day comparisons need no DateTime parsing or timezone math.
class DailyRewardState {
  const DailyRewardState({
    required this.streak,
    required this.lastClaimYmd,
  });

  final int streak;
  final int lastClaimYmd;

  factory DailyRewardState.initial() =>
      const DailyRewardState(streak: 0, lastClaimYmd: 0);

  /// Coins granted for claiming on a given streak day (escalating, capped).
  static int rewardForStreak(int streak) => 50 + 25 * (streak.clamp(1, 7) - 1);

  static int ymdOf(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  DailyRewardState copyWith({int? streak, int? lastClaimYmd}) =>
      DailyRewardState(
        streak: streak ?? this.streak,
        lastClaimYmd: lastClaimYmd ?? this.lastClaimYmd,
      );

  Map<String, dynamic> toMap() => {
        'streak': streak,
        'lastClaimYmd': lastClaimYmd,
      };

  factory DailyRewardState.fromMap(Map<String, dynamic> map) =>
      DailyRewardState(
        streak: map['streak'] as int,
        lastClaimYmd: map['lastClaimYmd'] as int,
      );

  String toJson() => jsonEncode(toMap());
  factory DailyRewardState.fromJson(String source) =>
      DailyRewardState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
