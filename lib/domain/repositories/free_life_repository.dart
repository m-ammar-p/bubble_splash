import '../models/free_life_state.dart';

/// Persists the Free Life claim cooldown.
abstract interface class FreeLifeRepository {
  FreeLifeState? load();
  void save(FreeLifeState state);
}
