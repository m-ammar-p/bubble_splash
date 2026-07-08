import 'package:bubble_splash/application/auth_controller.dart';
import 'package:bubble_splash/application/profile_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/auth_state.dart';
import 'package:bubble_splash/domain/models/game_result.dart';
import 'package:bubble_splash/domain/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Headless stand-in for the email/password service: returns [next] on the
/// next sign in/up, or throws [failure] when set.
class _StubAuthService implements AuthService {
  AuthAccount? next;
  AuthFailure? failure;

  Future<AuthAccount> _resolve() async {
    if (failure != null) throw failure!;
    return next!;
  }

  @override
  Future<AuthAccount> signUp({
    required String email,
    required String password,
    required String name,
    required String country,
  }) =>
      _resolve();

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) =>
      _resolve();

  @override
  Future<void> signOut() async {}
}

const _acc1 = AuthAccount(
    id: 'g1',
    displayName: 'Bubble Player',
    email: 'bubble@gmail.com',
    country: 'PK');
const _acc2 = AuthAccount(
    id: 'g2', displayName: 'Splash Master', email: 's@gmail.com', country: 'US');

void main() {
  late SharedPreferences prefs;
  late _StubAuthService service;
  late ProviderContainer container;

  ProviderContainer newContainer() {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = _StubAuthService();
    container = newContainer();
  });

  AuthController auth() => container.read(authControllerProvider.notifier);
  AuthState state() => container.read(authControllerProvider);

  Future<String?> signIn() =>
      auth().signIn(email: 'bubble@gmail.com', password: 'secret1');

  test('fresh install is undecided (login screen shown)', () {
    expect(state().decided, isFalse);
    expect(state().isGuest, isFalse);
    expect(state().isSignedIn, isFalse);
  });

  test('continue as guest persists across launches', () {
    auth().continueAsGuest();
    expect(state().isGuest, isTrue);

    final relaunch = newContainer();
    expect(relaunch.read(authControllerProvider).isGuest, isTrue);
  });

  test('sign in stores the account and persists it', () async {
    service.next = _acc1;
    expect(await signIn(), isNull); // null = success
    expect(state().isSignedIn, isTrue);
    expect(state().account!.email, 'bubble@gmail.com');
    expect(state().account!.country, 'PK');

    final relaunch = newContainer();
    expect(relaunch.read(authControllerProvider).account!.id, 'g1');
  });

  test('sign up stores the account', () async {
    service.next = _acc1;
    final error = await auth().signUp(
        email: 'bubble@gmail.com',
        password: 'secret1',
        name: 'Bubble Player',
        country: 'PK');
    expect(error, isNull);
    expect(state().isSignedIn, isTrue);
  });

  test('failed sign-in returns the message and changes nothing', () async {
    service.failure = const AuthFailure('Wrong email or password.');
    expect(await signIn(), 'Wrong email or password.');
    expect(state().decided, isFalse);
  });

  test('sign out returns to undecided (login screen)', () async {
    service.next = _acc1;
    await signIn();
    await auth().signOut();
    expect(state().decided, isFalse);
    expect(state().account, isNull);
  });

  group('per-account profiles', () {
    test('fresh signed-in profile is the account first name + #tag', () async {
      service.next = _acc1;
      await signIn();
      final profile = container.read(profileControllerProvider);
      expect(profile.name, matches(RegExp(r'^Bubble#\d{4}$')));
    });

    test('fresh guest profile is Guest + #tag', () {
      auth().continueAsGuest();
      expect(container.read(profileControllerProvider).name,
          matches(RegExp(r'^Guest#\d{4}$')));
    });

    test('guests cannot rename; signed-in players can (tag kept)', () async {
      auth().continueAsGuest();
      final profiles = container.read(profileControllerProvider.notifier);
      final guestName = container.read(profileControllerProvider).name;
      expect(profiles.canRename, isFalse);
      profiles.rename('Ace');
      expect(container.read(profileControllerProvider).name, guestName);

      service.next = _acc1;
      await signIn();
      expect(profiles.canRename, isTrue);
      profiles.rename('Ace');
      expect(container.read(profileControllerProvider).name,
          matches(RegExp(r'^Ace#\d{4}$')));
    });

    test('progress follows the account across sign-out/sign-in', () async {
      service.next = _acc1;
      await signIn();
      container.read(profileControllerProvider.notifier).recordGameResult(
            const GameResult(
                score: 500, bubblesPopped: 40, maxCombo: 5, goldenPopped: 2),
          );
      expect(container.read(profileControllerProvider).highScore, 500);

      await auth().signOut();
      await signIn();
      expect(container.read(profileControllerProvider).highScore, 500);
    });

    test('guest and account keep separate records', () async {
      // Guest plays first.
      auth().continueAsGuest();
      container.read(profileControllerProvider.notifier).recordGameResult(
            const GameResult(
                score: 300, bubblesPopped: 25, maxCombo: 3, goldenPopped: 1),
          );
      expect(container.read(profileControllerProvider).highScore, 300);

      // Signing in switches to the account's own (fresh) profile.
      service.next = _acc1;
      await signIn();
      expect(container.read(profileControllerProvider).highScore, 0);

      // A second account gets its own slot too.
      service.next = _acc2;
      await auth().signIn(email: 's@gmail.com', password: 'secret2');
      expect(container.read(profileControllerProvider).name,
          startsWith('Splash#'));

      // Back to guest: the guest record is untouched.
      auth().continueAsGuest();
      expect(container.read(profileControllerProvider).highScore, 300);
    });
  });
}
