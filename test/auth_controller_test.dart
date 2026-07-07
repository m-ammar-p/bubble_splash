import 'package:bubble_splash/application/auth_controller.dart';
import 'package:bubble_splash/application/profile_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/auth_state.dart';
import 'package:bubble_splash/domain/models/game_result.dart';
import 'package:bubble_splash/domain/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Headless stand-in for the interactive Google flow: returns [account]
/// (null = the player cancelled).
class _StubAuthService implements AuthService {
  AuthAccount? account;

  @override
  Future<AuthAccount?> signInWithGoogle() async => account;

  @override
  Future<void> signOut() async {}
}

const _acc1 = AuthAccount(
    id: 'g1', displayName: 'Bubble Player', email: 'bubble@gmail.com');
const _acc2 =
    AuthAccount(id: 'g2', displayName: 'Splash Master', email: 's@gmail.com');

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

  test('Google sign-in stores the account and persists it', () async {
    service.account = _acc1;
    expect(await auth().signInWithGoogle(), isTrue);
    expect(state().isSignedIn, isTrue);
    expect(state().account!.email, 'bubble@gmail.com');

    final relaunch = newContainer();
    expect(relaunch.read(authControllerProvider).account!.id, 'g1');
  });

  test('cancelled sign-in changes nothing', () async {
    service.account = null;
    expect(await auth().signInWithGoogle(), isFalse);
    expect(state().decided, isFalse);
  });

  test('sign out returns to undecided (login screen)', () async {
    service.account = _acc1;
    await auth().signInWithGoogle();
    await auth().signOut();
    expect(state().decided, isFalse);
    expect(state().account, isNull);
  });

  group('per-account profiles', () {
    test('fresh signed-in profile takes the Google display name (tagged)',
        () async {
      service.account = _acc1;
      await auth().signInWithGoogle();
      final profile = container.read(profileControllerProvider);
      expect(profile.name, startsWith('Bubble Player#'));
    });

    test('progress follows the account across sign-out/sign-in', () async {
      service.account = _acc1;
      await auth().signInWithGoogle();
      container.read(profileControllerProvider.notifier).recordGameResult(
            const GameResult(
                score: 500, bubblesPopped: 40, maxCombo: 5, goldenPopped: 2),
          );
      expect(container.read(profileControllerProvider).highScore, 500);

      await auth().signOut();
      await auth().signInWithGoogle();
      expect(container.read(profileControllerProvider).highScore, 500);
    });

    test('guest and Google accounts keep separate records', () async {
      // Guest plays first.
      auth().continueAsGuest();
      container.read(profileControllerProvider.notifier).recordGameResult(
            const GameResult(
                score: 300, bubblesPopped: 25, maxCombo: 3, goldenPopped: 1),
          );
      expect(container.read(profileControllerProvider).highScore, 300);

      // Signing in switches to the account's own (fresh) profile.
      service.account = _acc1;
      await auth().signInWithGoogle();
      expect(container.read(profileControllerProvider).highScore, 0);

      // A second account gets its own slot too.
      service.account = _acc2;
      await auth().signInWithGoogle();
      expect(
          container.read(profileControllerProvider).name,
          startsWith('Splash Master#'));

      // Back to guest: the guest record is untouched.
      auth().continueAsGuest();
      expect(container.read(profileControllerProvider).highScore, 300);
    });
  });
}
