import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/models/auth_state.dart';
import '../../domain/services/auth_service.dart';

/// Real [AuthService] backed by Supabase email/password auth.
///
/// Sign up stores the chosen display name + country in the user's metadata, so
/// a later sign-in (even on another device) restores both. The Supabase user
/// uuid becomes [AuthAccount.id] — the per-account storage key. Supabase
/// `AuthException`s are mapped to the domain [AuthFailure] so nothing above the
/// data layer sees the SDK.
class SupabaseAuthService implements AuthService {
  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  @override
  Future<AuthAccount> signUp({
    required String email,
    required String password,
    required String name,
    required String country,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'country': country},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Could not create the account. Try again.');
      }
      // With email confirmation enabled, no session is returned until the
      // player clicks the emailed link. Tell them, rather than silently
      // "succeeding" into a screen they aren't actually authed for.
      if (res.session == null) {
        throw const AuthFailure(
            'Check your email to confirm your account, then sign in.');
      }
      return _toAccount(user, fallbackName: name, fallbackCountry: country);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Something went wrong. Check your connection.');
    }
  }

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Wrong email or password.');
      }
      return _toAccount(user);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Something went wrong. Check your connection.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AuthAccount _toAccount(
    sb.User user, {
    String? fallbackName,
    String? fallbackCountry,
  }) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '';
    final rawName =
        (meta['name'] ?? meta['full_name']) as String? ?? fallbackName;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : (email.contains('@') ? email.split('@').first : 'Player');
    final country =
        (meta['country'] as String?) ?? fallbackCountry ?? '';
    return AuthAccount(
      id: user.id,
      displayName: name,
      email: email,
      country: country,
    );
  }
}
