import '../models/auth_state.dart';

/// Persists the player's login choice (guest / account) across
/// launches. Synchronous like the other meta-state repos — prefs is warmed in
/// `main()`, so `Notifier.build()` can read it directly.
abstract class AuthRepository {
  /// The saved auth state, or null on a fresh install (login screen shown).
  AuthState? load();

  void save(AuthState state);
}
