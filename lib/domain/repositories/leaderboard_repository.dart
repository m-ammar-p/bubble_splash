import '../models/leaderboard_entry.dart';

/// Supplies competitor scores. Asynchronous on purpose: leaderboards are
/// inherently a network concern, so this is the one repository that models
/// latency and lets the UI show loading/error states. The fake implementation
/// returns deterministic seeded users after a short simulated delay; a real
/// backend (Firebase/Supabase) implements the same contract.
abstract interface class LeaderboardRepository {
  /// Returns competitor entries for [scope] (excluding the current player, who
  /// is merged in by the controller), highest score first.
  Future<List<LeaderboardEntry>> fetchTop(
    LeaderboardScope scope, {
    int limit = 50,
  });
}
