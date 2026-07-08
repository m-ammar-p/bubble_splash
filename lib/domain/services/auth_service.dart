import '../models/auth_state.dart';

/// A sign-in / sign-up failure with a player-facing [message] (e.g. "Wrong
/// email or password"). Data-layer implementations map provider errors
/// (Supabase `AuthException`, network failures) onto this so the domain +
/// presentation layers never import a backend SDK.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// Identity provider abstraction (email/password). The Supabase implementation
/// is swapped in via `providers.dart`; the fake one keeps the app running with
/// no backend for offline dev + headless tests.
///
/// Both [signUp] and [signIn] return the resulting [AuthAccount] on success and
/// throw [AuthFailure] on any expected failure (bad credentials, email taken,
/// unconfirmed account, offline). Callers surface `AuthFailure.message`.
abstract class AuthService {
  /// Creates an account and signs in. [name] seeds the display name; [country]
  /// is the ISO-3166 alpha-2 code for the local leaderboard.
  Future<AuthAccount> signUp({
    required String email,
    required String password,
    required String name,
    required String country,
  });

  /// Signs in an existing account.
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  });

  /// Clears the provider-side session. Local state cleanup is the
  /// controller's job.
  Future<void> signOut();
}
