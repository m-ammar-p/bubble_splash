import '../models/player_profile.dart';

/// Persists the player's profile. Synchronous because the local implementation
/// is backed by an already-warmed key-value store; a remote backend would
/// implement this over a synchronously-readable in-memory cache hydrated at
/// bootstrap (so screens never need loading states for core meta state).
abstract interface class ProfileRepository {
  PlayerProfile? load();
  void save(PlayerProfile profile);
}
