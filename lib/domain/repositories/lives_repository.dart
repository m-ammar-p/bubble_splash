import '../models/lives_state.dart';

/// Persists the lives/energy economy. Synchronous for the same reason as
/// [ProfileRepository].
abstract interface class LivesRepository {
  LivesState? load();
  void save(LivesState state);
}
