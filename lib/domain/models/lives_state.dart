import 'dart:convert';

/// The lives bank. Lives are NOT a play-gate anymore — a player can always
/// start a round for free. Instead a life is an in-round *continue*: when round
/// HP is depleted, spending one life revives the run. Lives are earned passively
/// (one per [regenInterval], timestamp-based so it works while the app is
/// closed) and via the "Free Life" rewarded-ad claim, banking up to [maxLives].
class LivesState {
  const LivesState({
    required this.count,
    required this.lastRegenAtMs,
  });

  final int count;

  /// Epoch millis marking the start of the interval currently regenerating.
  final int lastRegenAtMs;

  /// Bank cap. Lives accumulate up to here from passive regen + ad claims.
  static const int maxLives = 10;

  /// Lives a brand-new player starts with.
  static const int startingLives = 5;
  static const Duration regenInterval = Duration(minutes: 30);

  factory LivesState.initial(int nowMs) =>
      LivesState(count: startingLives, lastRegenAtMs: nowMs);

  bool get isFull => count >= maxLives;

  LivesState copyWith({int? count, int? lastRegenAtMs}) => LivesState(
        count: count ?? this.count,
        lastRegenAtMs: lastRegenAtMs ?? this.lastRegenAtMs,
      );

  Map<String, dynamic> toMap() => {
        'count': count,
        'lastRegenAtMs': lastRegenAtMs,
      };

  factory LivesState.fromMap(Map<String, dynamic> map) => LivesState(
        count: map['count'] as int,
        lastRegenAtMs: map['lastRegenAtMs'] as int,
      );

  String toJson() => jsonEncode(toMap());
  factory LivesState.fromJson(String source) =>
      LivesState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
