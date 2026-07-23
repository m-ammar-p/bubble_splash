import 'dart:convert';

/// A signed-in identity. Comes from Supabase email/password auth; `id` is the
/// Supabase user uuid. Pure Dart.
class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.displayName,
    required this.email,
    this.country = '',
  });

  /// Stable provider-side account id (Supabase user uuid) — namespaces
  /// per-account storage (`profile_<id>`), so it must never change.
  final String id;
  final String displayName;
  final String email;

  /// ISO-3166 alpha-2 country code chosen at sign up (e.g. "PK", "US"),
  /// used to bucket the local leaderboard. Empty when unknown.
  final String country;

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'country': country,
      };

  factory AuthAccount.fromMap(Map<String, dynamic> map) => AuthAccount(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        email: map['email'] as String,
        country: map['country'] as String? ?? '',
      );
}

/// The player's identity: guest (no [account]) or signed in (with an
/// [account]). There is no login gate — a fresh install is a guest, and an
/// account is adopted on demand from the shop/profile.
class AuthState {
  const AuthState({this.account});

  /// The signed-in account, or null when playing as a guest.
  final AuthAccount? account;

  const AuthState.guest() : account = null;
  const AuthState.signedIn(AuthAccount this.account);

  bool get isSignedIn => account != null;
  bool get isGuest => account == null;

  Map<String, dynamic> toMap() => {
        'account': account?.toMap(),
      };

  factory AuthState.fromMap(Map<String, dynamic> map) => AuthState(
        account: map['account'] == null
            ? null
            : AuthAccount.fromMap(map['account'] as Map<String, dynamic>),
      );

  String toJson() => jsonEncode(toMap());
  factory AuthState.fromJson(String source) =>
      AuthState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
