import 'package:bubble_splash/application/lives_controller.dart';
import 'package:bubble_splash/application/providers.dart';
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
    now = DateTime(2026, 6, 17, 12);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(container.dispose);
  });

  LivesController notifier() =>
      container.read(livesControllerProvider.notifier);
  LivesState state() => container.read(livesControllerProvider);

  test('starts full', () {
    expect(state().count, LivesState.maxLives);
    expect(notifier().canPlay, isTrue);
  });

  test('spending lives reduces the count to zero', () {
    for (var i = 0; i < LivesState.maxLives; i++) {
      expect(notifier().spendLife(), isTrue);
    }
    expect(state().count, 0);
    expect(notifier().spendLife(), isFalse);
    expect(notifier().canPlay, isFalse);
  });

  test('regenerates one life after the interval elapses', () {
    final n = notifier();
    for (var i = 0; i < LivesState.maxLives; i++) {
      n.spendLife();
    }
    expect(state().count, 0);

    now = now.add(LivesState.regenInterval + const Duration(minutes: 1));
    n.refresh();
    expect(state().count, 1);
  });

  test('catches up multiple lives offline but caps at max', () {
    final n = notifier();
    for (var i = 0; i < LivesState.maxLives; i++) {
      n.spendLife();
    }
    // Far in the future → should refill to the cap, not overflow.
    now = now.add(const Duration(hours: 10));
    n.refresh();
    expect(state().count, LivesState.maxLives);
    expect(notifier().untilNextLife(), isNull);
  });

  test('countdown shrinks toward the next life', () {
    final n = notifier();
    n.spendLife(); // 5 -> 4, anchor = now
    final initial = n.untilNextLife()!;
    now = now.add(const Duration(minutes: 10));
    final later = n.untilNextLife()!;
    expect(later, lessThan(initial));
  });
}
