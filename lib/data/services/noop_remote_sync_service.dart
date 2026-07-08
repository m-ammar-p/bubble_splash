import '../../domain/models/game_result.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/services/remote_sync_service.dart';

/// No-op sync for guests / offline (Supabase not configured) and tests.
class NoopRemoteSyncService implements RemoteSyncService {
  @override
  Future<PlayerProfile?> fetchProfile(String accountId) async => null;

  @override
  void pushProfile(String accountId, PlayerProfile profile) {}

  @override
  void logRound(String accountId, GameResult result) {}
}
