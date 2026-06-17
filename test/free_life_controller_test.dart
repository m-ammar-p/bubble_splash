import 'package:bubble_splash/application/free_life_controller.dart';
import 'package:bubble_splash/application/lives_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/domain/models/free_life_state.dart';
import 'package:bubble_splash/domain/models/lives_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 6, 17, 9);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(container.dispose);
  });

  FreeLifeController freeLife() =>
      container.read(freeLifeControllerProvider.notifier);
  LivesController livesN() =>
      container.read(livesControllerProvider.notifier);
  int lives() => container.read(livesControllerProvider).count;

  test('claimable from the start', () {
    expect(freeLife().canClaim, isTrue);
  });

  test('claim grants one life and starts the cooldown', () {
    livesN().spendLife(); // make room under the cap
    final before = lives();
    expect(freeLife().claim(), isTrue);
    expect(lives(), before + 1);
    expect(freeLife().canClaim, isFalse);
  });

  test('cannot claim again until the cooldown elapses', () {
    livesN().spendLife();
    freeLife().claim();
    expect(freeLife().canClaim, isFalse);

    now = now.add(FreeLifeState.cooldown + const Duration(minutes: 1));
    livesN().spendLife(); // keep under the cap
    expect(freeLife().canClaim, isTrue);
  });

  test('claim is blocked (and cooldown untouched) when lives are full', () {
    final n = livesN();
    while (container.read(livesControllerProvider).count <
        LivesState.maxLives) {
      n.addLife();
    }
    expect(freeLife().claim(), isFalse);
    expect(freeLife().canClaim, isTrue); // not consumed → still available
  });
}
