import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/auth_state.dart';
import '../domain/services/auth_service.dart';
import 'providers.dart';

/// Owns the player's identity (guest / account) and persists it. There is no
/// first-launch login gate: a fresh install boots straight to Home as a guest,
/// and signing in happens on demand (shop coin gate, profile name edit, the
/// profile ACCOUNT card). A returning signed-in player is restored from prefs.
///
/// Per-account progression hangs off this state: `profileControllerProvider`
/// watches the signed-in account id and loads that account's profile (guests
/// use the legacy shared slot). Lives/free-life stay device-global — they're
/// device retention mechanics, not account records.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() =>
      ref.read(authRepositoryProvider).load() ?? const AuthState.guest();

  void _commit(AuthState next) {
    state = next;
    ref.read(authRepositoryProvider).save(next);
  }

  void continueAsGuest() => _commit(const AuthState.guest());

  /// Creates an account and signs in. Returns null on success, or a
  /// player-facing error message on failure (state untouched on failure).
  ///
  /// The DB profile row is created at defaults by the `handle_new_user`
  /// trigger; `ProfileController.build` mirrors its fresh (tagged-name) profile
  /// up when it first loads for the new account.
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String country,
  }) async {
    try {
      final account = await ref.read(authServiceProvider).signUp(
            email: email,
            password: password,
            name: name,
            country: country,
          );
      _commit(AuthState.signedIn(account));
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Signs in an existing account. Returns null on success, else an error
  /// message. On success the account's remote profile is pulled into local
  /// storage first, so `profileControllerProvider` rebuilds against it.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final account = await ref
          .read(authServiceProvider)
          .signIn(email: email, password: password);
      final remote =
          await ref.read(remoteSyncServiceProvider).fetchProfile(account.id);
      if (remote != null) {
        ref.read(profileRepositoryProvider(account.id)).save(remote);
      }
      _commit(AuthState.signedIn(account));
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Signs out and drops back to guest (progression follows the guest slot).
  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    _commit(const AuthState.guest());
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
