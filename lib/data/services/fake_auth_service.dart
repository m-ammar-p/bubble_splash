import '../../domain/models/auth_state.dart';
import '../../domain/services/auth_service.dart';

/// In-memory [AuthService] used when no Supabase credentials are configured
/// (offline dev). Accounts live only for the app session — enough to exercise
/// the full sign-up → sign-in → per-account-profile flow without a backend.
/// Mirrors the real service's failure surface via [AuthFailure].
class FakeAuthService implements AuthService {
  final Map<String, _FakeUser> _users = {};

  String _key(String email) => email.trim().toLowerCase();

  @override
  Future<AuthAccount> signUp({
    required String email,
    required String password,
    required String name,
    required String country,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = _key(email);
    if (_users.containsKey(key)) {
      throw const AuthFailure('That email is already registered. Sign in.');
    }
    final user = _FakeUser(
      id: 'fake_${key.hashCode.toUnsigned(32)}',
      password: password,
      name: name,
      email: email.trim(),
      country: country,
    );
    _users[key] = user;
    return user.account;
  }

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _users[_key(email)];
    if (user == null || user.password != password) {
      throw const AuthFailure('Wrong email or password.');
    }
    return user.account;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUser {
  _FakeUser({
    required this.id,
    required this.password,
    required this.name,
    required this.email,
    required this.country,
  });

  final String id;
  final String password;
  final String name;
  final String email;
  final String country;

  AuthAccount get account =>
      AuthAccount(id: id, displayName: name, email: email, country: country);
}
