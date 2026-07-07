import 'dart:convert';

/// A signed-in identity. Today this comes from the fake Google service; later
/// it maps 1:1 onto a real `google_sign_in` / Play Games account. Pure Dart.
class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.displayName,
    required this.email,
  });

  /// Stable provider-side account id — used to namespace per-account storage
  /// (see `PrefsProfileRepository`), so it must never change between sign-ins.
  final String id;
  final String displayName;
  final String email;

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
      };

  factory AuthAccount.fromMap(Map<String, dynamic> map) => AuthAccount(
        id: map['id'] as String,
        displayName: map['displayName'] as String,
        email: map['email'] as String,
      );
}

/// Whether the player has passed the login screen, and as whom.
///
/// Three shapes: undecided (fresh install — show the login screen), guest
/// (`decided` with no [account]), or signed in (`decided` with an [account]).
class AuthState {
  const AuthState({required this.decided, this.account});

  /// True once the player has chosen guest or Google on the login screen.
  final bool decided;

  /// The signed-in Google account, or null when playing as a guest.
  final AuthAccount? account;

  static const undecided = AuthState(decided: false);
  const AuthState.guest() : this(decided: true);
  const AuthState.signedIn(AuthAccount this.account) : decided = true;

  bool get isSignedIn => account != null;
  bool get isGuest => decided && account == null;

  Map<String, dynamic> toMap() => {
        'decided': decided,
        'account': account?.toMap(),
      };

  factory AuthState.fromMap(Map<String, dynamic> map) => AuthState(
        decided: map['decided'] as bool,
        account: map['account'] == null
            ? null
            : AuthAccount.fromMap(map['account'] as Map<String, dynamic>),
      );

  String toJson() => jsonEncode(toMap());
  factory AuthState.fromJson(String source) =>
      AuthState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
