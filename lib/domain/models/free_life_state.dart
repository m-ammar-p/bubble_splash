import 'dart:convert';

/// Cooldown state for the **Free Life** reward. Every [cooldown] the player may
/// watch a rewarded ad to bank one extra life. [lastClaimMs] is epoch millis of
/// the last claim (0 = never claimed → immediately claimable). Timestamp-based
/// so the cooldown is correct across app restarts, like lives regen.
class FreeLifeState {
  const FreeLifeState({required this.lastClaimMs});

  final int lastClaimMs;

  static const Duration cooldown = Duration(minutes: 30);

  factory FreeLifeState.initial() => const FreeLifeState(lastClaimMs: 0);

  bool canClaimAt(int nowMs) =>
      nowMs - lastClaimMs >= cooldown.inMilliseconds;

  /// Time until the next claim is allowed (zero when ready).
  Duration untilClaimable(int nowMs) {
    final remaining = lastClaimMs + cooldown.inMilliseconds - nowMs;
    return Duration(milliseconds: remaining.clamp(0, cooldown.inMilliseconds));
  }

  FreeLifeState copyWith({int? lastClaimMs}) =>
      FreeLifeState(lastClaimMs: lastClaimMs ?? this.lastClaimMs);

  Map<String, dynamic> toMap() => {'lastClaimMs': lastClaimMs};

  factory FreeLifeState.fromMap(Map<String, dynamic> map) =>
      FreeLifeState(lastClaimMs: (map['lastClaimMs'] ?? 0) as int);

  String toJson() => jsonEncode(toMap());
  factory FreeLifeState.fromJson(String source) =>
      FreeLifeState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
