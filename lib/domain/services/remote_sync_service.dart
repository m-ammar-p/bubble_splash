import '../models/game_result.dart';
import '../models/player_profile.dart';

/// Mirrors the signed-in account's profile + round history to a remote backend
/// (Supabase). Local prefs stay the source of truth; this is a best-effort
/// mirror, so every method must fail soft: reads return null, writes are
/// fire-and-forget and never throw into the caller. Guests / offline use the
/// no-op implementation.
abstract class RemoteSyncService {
  /// The account's remote profile, or null if absent / unreachable.
  Future<PlayerProfile?> fetchProfile(String accountId);

  /// Upserts the account's profile row. Fire-and-forget.
  void pushProfile(String accountId, PlayerProfile profile);

  /// Appends a finished round to the account's history. Fire-and-forget.
  void logRound(String accountId, GameResult result);
}
