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

  test('starts with the starting lives', () {
    expect(state().count, LivesState.startingLives);
    expect(notifier().canPlay, isTrue);
  });

  test('spending lives reduces the count to zero', () {
    for (var i = 0; i < LivesState.startingLives; i++) {
      expect(notifier().spendLife(), isTrue);
    }
    expect(state().count, 0);
    expect(notifier().spendLife(), isFalse);
    expect(notifier().canPlay, isFalse);
  });

  test('regenerates one life after the interval elapses', () {
    final n = notifier();
    for (var i = 0; i < LivesState.startingLives; i++) {
      n.spendLife();
    }
    expect(state().count, 0);

    now = now.add(LivesState.regenInterval + const Duration(minutes: 1));
    n.refresh();
    expect(state().count, 1);
  });

  test('catches up multiple lives offline but caps at max', () {
    final n = notifier();
    for (var i = 0; i < LivesState.startingLives; i++) {
      n.spendLife();
    }
    // 10h = 20 intervals → 20 lives regenerated, still under the cap.
    now = now.add(const Duration(hours: 10));
    n.refresh();
    expect(state().count, 20);
    expect(notifier().untilNextLife(), isNotNull);

    // Far enough in the future → refills to the cap, not past it.
    now = now.add(const Duration(days: 3));
    n.refresh();
    expect(state().count, LivesState.maxLives);
    expect(notifier().untilNextLife(), isNull);
  });

  test('addLife banks above the starting count up to the cap', () {
    final n = notifier();
    for (var i = LivesState.startingLives; i < LivesState.maxLives; i++) {
      n.addLife();
    }
    expect(state().count, LivesState.maxLives);
    n.addLife(); // already full → no overflow
    expect(state().count, LivesState.maxLives);
  });

  test('purchased lives stack past the free ceiling up to maxLives', () {
    final n = notifier();
    expect(n.addLives(30), isTrue);
    expect(state().count, LivesState.startingLives + 30);

    // A pack that would overflow the cap is refused outright — never grant a
    // clamped partial fill for full price (97 + 5 must not become 100).
    expect(n.addLives(LivesState.maxLives), isFalse);
    expect(state().count, LivesState.startingLives + 30);

    // Exactly filling the bank is fine.
    final room = LivesState.maxLives - state().count;
    expect(n.addLives(room), isTrue);
    expect(state().count, LivesState.maxLives);

    // At max → any further purchase refused.
    expect(n.addLives(5), isFalse);
    expect(state().count, LivesState.maxLives);
  });

  test('regen keeps filling on top of purchased lives', () {
    final n = notifier();
    n.addLives(50); // 5 + 50 = 55
    now = now.add(const Duration(hours: 10)); // 20 intervals
    n.refresh();
    expect(state().count, 75);
  });

  test('spending down from a full bank re-anchors the regen clock', () {
    final n = notifier();
    n.addLives(LivesState.maxLives - state().count); // fill to the cap
    now = now.add(const Duration(days: 30)); // anchor goes stale while full
    n.spendLife();
    n.refresh();
    // Must NOT instantly refill from the 30-day-old anchor.
    expect(state().count, LivesState.maxLives - 1);
    expect(n.untilNextLife(), isNotNull);
  });

  test('countdown shrinks toward the next life', () {
    final n = notifier();
    n.spendLife(); // anchor = now
    final initial = n.untilNextLife()!;
    now = now.add(const Duration(minutes: 10));
    final later = n.untilNextLife()!;
    expect(later, lessThan(initial));
  });
}
