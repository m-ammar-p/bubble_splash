import '../models/auth_state.dart';

/// Identity provider abstraction. The fake implementation simulates the
/// Google account chooser; swapping in real Google Sign-In / Play Games
/// Services later means implementing this and editing only `providers.dart`.
abstract class AuthService {
  /// Runs the provider's interactive sign-in flow. Returns the chosen
  /// account, or null when the player cancels or the flow fails — callers
  /// must treat null as "nothing changed".
  Future<AuthAccount?> signInWithGoogle();

  /// Clears the provider-side session. Local state cleanup is the
  /// controller's job, not the service's.
  Future<void> signOut();
}
