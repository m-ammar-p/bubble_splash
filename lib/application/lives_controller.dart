import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/lives_state.dart';
import 'providers.dart';

/// Owns the lives/energy economy. Regeneration is timestamp-based so it is
/// correct across app restarts: [build] normalizes on load, and a periodic
/// timer re-normalizes while the app runs (granting a life when an interval
/// elapses). Per-second countdown rebuilds are driven separately by
/// [livesTickerProvider] to avoid churning this notifier's state every tick.
class LivesController extends Notifier<LivesState> {
  Timer? _timer;

  @override
  LivesState build() {
    final repo = ref.read(livesRepositoryProvider);
    final now = _nowMs();
    final loaded = repo.load() ?? LivesState.initial(now);
    final normalized = _normalize(loaded, now);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(() => _timer?.cancel());

    if (normalized.count != loaded.count ||
        normalized.lastRegenAtMs != loaded.lastRegenAtMs) {
      repo.save(normalized);
    }
    return normalized;
  }

  int _nowMs() => ref.read(clockProvider)().millisecondsSinceEpoch;

  void _commit(LivesState next) {
    state = next;
    ref.read(livesRepositoryProvider).save(next);
  }

  void _tick() {
    final next = _normalize(state, _nowMs());
    if (next.count != state.count ||
        next.lastRegenAtMs != state.lastRegenAtMs) {
      _commit(next);
    }
  }

  /// Recomputes regeneration immediately. Useful to call on app resume (so the
  /// player sees lives earned while away without waiting for the next tick).
  void refresh() => _tick();

  /// Advances regeneration: grants any whole intervals' worth of lives elapsed
  /// since [LivesState.lastRegenAtMs], capped at [LivesState.maxLives].
  static LivesState _normalize(LivesState s, int nowMs) {
    if (s.count >= LivesState.maxLives) return s;
    final interval = LivesState.regenInterval.inMilliseconds;
    final elapsed = nowMs - s.lastRegenAtMs;
    if (elapsed < interval) return s;
    final gained = elapsed ~/ interval;
    final newCount = min(LivesState.maxLives, s.count + gained);
    final newAnchor = newCount >= LivesState.maxLives
        ? nowMs
        : s.lastRegenAtMs + gained * interval;
    return LivesState(count: newCount, lastRegenAtMs: newAnchor);
  }

  bool get canPlay => state.count > 0;

  /// Consumes one life to start a round. Returns false if none are available.
  bool spendLife() {
    if (state.count <= 0) return false;
    // At the cap the anchor is stale (regen is paused), so re-anchor when
    // spending down from full — regeneration must start from this spend, not
    // instantly refill from an old timestamp.
    final wasFull = state.isFull;
    _commit(state.copyWith(
      count: state.count - 1,
      lastRegenAtMs: wasFull ? _nowMs() : state.lastRegenAtMs,
    ));
    return true;
  }

  /// Grants one life (rewarded ad / Free Life claim), capped at the max.
  void addLife() {
    if (state.isFull) return;
    _commit(state.copyWith(count: min(LivesState.maxLives, state.count + 1)));
  }

  /// Banks [amount] purchased lives (Shop). Refuses (returns false, grants
  /// nothing) unless the whole pack fits under [LivesState.maxLives] — never
  /// charge a player full price for a clamped partial grant.
  bool addLives(int amount) {
    if (state.count + amount > LivesState.maxLives) return false;
    _commit(state.copyWith(count: state.count + amount));
    return true;
  }

  /// Time until the next life regenerates, or null when full.
  Duration? untilNextLife() {
    if (state.isFull) return null;
    final interval = LivesState.regenInterval.inMilliseconds;
    final remaining = state.lastRegenAtMs + interval - _nowMs();
    return Duration(milliseconds: remaining.clamp(0, interval));
  }
}

final livesControllerProvider =
    NotifierProvider<LivesController, LivesState>(LivesController.new);

/// Emits every second so widgets showing the regen countdown can rebuild
/// without the controller mutating its state each tick.
final livesTickerProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (i) => i),
);
