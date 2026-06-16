import 'dart:convert';

/// The energy/lives economy that gates how often a player can start a round.
///
/// Regeneration is timestamp-based ([lastRegenAtMs]) so it works correctly while
/// the app is closed — the controller recomputes the granted lives on load
/// rather than relying on a running timer.
class LivesState {
  const LivesState({
    required this.count,
    required this.lastRegenAtMs,
  });

  final int count;

  /// Epoch millis marking the start of the interval currently regenerating.
  final int lastRegenAtMs;

  static const int maxLives = 5;
  static const Duration regenInterval = Duration(minutes: 30);

  factory LivesState.initial(int nowMs) =>
      LivesState(count: maxLives, lastRegenAtMs: nowMs);

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
