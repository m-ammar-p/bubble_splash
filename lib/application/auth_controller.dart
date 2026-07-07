import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/auth_state.dart';
import 'providers.dart';

/// Owns the player's login choice (guest / Google) and persists it. The
/// login screen is shown while [AuthState.decided] is false; every choice
/// here lands in prefs so the app boots straight to Home afterwards.
///
/// Per-account progression hangs off this state: `profileControllerProvider`
/// watches the signed-in account id and loads that account's profile (guests
/// use the legacy shared slot). Lives/free-life stay device-global — they're
/// device retention mechanics, not account records.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() =>
      ref.read(authRepositoryProvider).load() ?? AuthState.undecided;

  void _commit(AuthState next) {
    state = next;
    ref.read(authRepositoryProvider).save(next);
  }

  void continueAsGuest() => _commit(const AuthState.guest());

  /// Runs the provider sign-in flow. Returns true when an account was chosen;
  /// false (player cancelled / flow failed) leaves the state untouched.
  Future<bool> signInWithGoogle() async {
    final account = await ref.read(authServiceProvider).signInWithGoogle();
    if (account == null) return false;
    _commit(AuthState.signedIn(account));
    return true;
  }

  /// Signs out and returns to the undecided state (login screen).
  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    _commit(AuthState.undecided);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
