import 'package:bubble_splash/application/lives_controller.dart';
import 'package:bubble_splash/application/providers.dart';
import 'package:bubble_splash/application/rewarded_ad_manager.dart';
import 'package:bubble_splash/domain/models/auth_state.dart';
import 'package:bubble_splash/domain/models/rewarded_ad_meta.dart';
import 'package:bubble_splash/domain/services/rewarded_ad_gate.dart';
import 'package:bubble_splash/domain/services/rewarded_ad_limits.dart';
import 'package:bubble_splash/domain/services/rewarded_ad_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scriptable [RewardedAdGate] — stands in for the Supabase server enforcer.
/// [claim] is the verdict returned by `claimView` (null = soft-fail/offline);
/// [serverState] is what `fetchState` returns for the load-time hydration.
class _FakeGate implements RewardedAdGate {
  _FakeGate({this.claim, this.serverState});
  AdLimitState? claim;
  AdLimitState? serverState;
  int claims = 0;
  RewardedAdKind? lastKind;

  @override
  Future<AdLimitState?> fetchState(String accountId) async => serverState;

  @override
  Future<AdLimitState?> claimView(String accountId, RewardedAdKind kind) async {
    claims++;
    lastKind = kind;
    return claim;
  }
}

/// Headless scriptable ad provider — no UI. Queue [showResults]; each `show()`
/// consumes the next (single-use, mirroring the real provider).
class _ScriptProvider implements RewardedAdProvider {
  RewardedAdLoadResult loadResult = RewardedAdLoadResult.ready;
  final List<RewardedAdShowResult> showResults = [];
  bool _ready = false;
  int showCount = 0;

  @override
  bool get isReady => _ready;

  @override
  Future<RewardedAdLoadResult> load() async {
    if (loadResult == RewardedAdLoadResult.ready) _ready = true;
    return loadResult;
  }

  @override
  Future<RewardedAdShowResult> show() async {
    if (!_ready) return RewardedAdShowResult.notReady;
    _ready = false; // consumed
    showCount++;
    return showResults.isEmpty
        ? RewardedAdShowResult.dismissedWithoutReward
        : showResults.removeAt(0);
  }

  @override
  void dispose() {}
}

void main() {
  late DateTime now;
  late ProviderContainer container;
  late _ScriptProvider provider;

  setUp(() async {
    now = DateTime(2026, 7, 14, 9);
    provider = _ScriptProvider();
  });

  Future<ProviderContainer> make({
    RewardedAdMeta? seedMeta,
    RewardedAdGate? gate,
    bool signedIn = false,
  }) async {
    final initial = <String, Object>{};
    if (seedMeta != null) initial['rewarded_ad'] = seedMeta.toJson();
    if (signedIn) {
      initial['auth'] = const AuthState.signedIn(
        AuthAccount(id: 'acc-1', displayName: 'Tester', email: 't@e.com'),
      ).toJson();
    }
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
      rewardedAdProviderProvider.overrideWithValue(provider),
      if (gate != null) rewardedAdGateProvider.overrideWithValue(gate),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  RewardedAdManager mgr() =>
      container.read(rewardedAdManagerProvider.notifier);
  int lives() => container.read(livesControllerProvider).count;
  LivesController livesN() =>
      container.read(livesControllerProvider.notifier);

  group('reward granting', () {
    test('life granted ONLY on rewardEarned', () async {
      container = await make();
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload();
      livesN().spendLife();
      final before = lives();
      final res = await mgr().watchForRevive();
      expect(res, RewardedAdShowResult.rewardEarned);
      expect(lives(), before + 1);
    });

    test('no life on dismissedWithoutReward', () async {
      container = await make();
      provider.showResults.add(RewardedAdShowResult.dismissedWithoutReward);
      await mgr().preload();
      final before = lives();
      final res = await mgr().watchForRevive();
      expect(res, RewardedAdShowResult.dismissedWithoutReward);
      expect(lives(), before);
    });

    test('no life on failedToShow', () async {
      container = await make();
      provider.showResults.add(RewardedAdShowResult.failedToShow);
      await mgr().preload();
      final before = lives();
      await mgr().watchForRevive();
      expect(lives(), before);
    });

    test('single-use: second show without reload is notReady, no double grant',
        () async {
      container = await make();
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload(); // one ad ready
      // Make the post-show reload fail, so the ad stays consumed (single-use).
      provider.loadResult = RewardedAdLoadResult.noFill;
      livesN().spendLife();
      final before = lives();
      await mgr().watchForRevive(); // consumes the one ad, grants once
      final res = await mgr().watchForRevive(); // nothing reloaded
      expect(res, RewardedAdShowResult.notReady);
      expect(lives(), before + 1); // only one grant
    });
  });

  group('per-death cap', () {
    test('at most 3 revives, then CONSUMED', () async {
      container = await make();
      mgr().beginDeathEvent();
      for (var i = 0; i < RewardedAdLimits.maxRevivesPerDeath; i++) {
        provider.loadResult = RewardedAdLoadResult.ready;
        await mgr().preload();
        provider.showResults.add(RewardedAdShowResult.rewardEarned);
        livesN().spendLife();
        final res = await mgr().watchForRevive();
        expect(res, RewardedAdShowResult.rewardEarned);
      }
      expect(mgr().reviveButtonPhase(), RewardedAdButtonPhase.consumed);
      final res = await mgr().watchForRevive();
      expect(res, RewardedAdShowResult.notReady);
    });

    test('beginDeathEvent resets the counter', () async {
      container = await make();
      mgr().beginDeathEvent();
      for (var i = 0; i < RewardedAdLimits.maxRevivesPerDeath; i++) {
        await mgr().preload();
        provider.showResults.add(RewardedAdShowResult.rewardEarned);
        livesN().spendLife();
        await mgr().watchForRevive();
      }
      expect(mgr().reviveButtonPhase(), RewardedAdButtonPhase.consumed);
      mgr().beginDeathEvent();
      await mgr().preload();
      expect(mgr().reviveButtonPhase(), RewardedAdButtonPhase.ready);
    });
  });

  group('daily cap (rolling 24h)', () {
    test('capReached blocks and refuses a view', () async {
      final capped = RewardedAdMeta(
        dailyCount: RewardedAdLimits.dailyViewCap,
        dailyWindowStartMs: now.millisecondsSinceEpoch,
        homeLastWatchMs: 0,
      );
      container = await make(seedMeta: capped);
      await mgr().preload();
      expect(mgr().homeButtonPhase(), RewardedAdButtonPhase.capReached);
      final res = await mgr().watchForHomeLife();
      expect(res, RewardedAdShowResult.notReady);
    });

    test('window rolls after 24h forward', () async {
      final capped = RewardedAdMeta(
        dailyCount: RewardedAdLimits.dailyViewCap,
        dailyWindowStartMs: now.millisecondsSinceEpoch,
        homeLastWatchMs: 0,
      );
      final rolled = capped
          .normalizedDaily(now.millisecondsSinceEpoch +
              RewardedAdLimits.dailyWindow.inMilliseconds +
              1);
      expect(rolled.dailyCount, 0);
    });
  });

  group('home cooldown', () {
    test('cooldown after a home claim, ready again after 30min', () async {
      container = await make();
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload();
      livesN().spendLife();
      await mgr().watchForHomeLife();
      expect(mgr().homeButtonPhase(), RewardedAdButtonPhase.cooldown);

      now = now.add(RewardedAdLimits.homeCooldown + const Duration(minutes: 1));
      provider.loadResult = RewardedAdLoadResult.ready;
      await mgr().preload();
      expect(mgr().homeButtonPhase(), RewardedAdButtonPhase.ready);
    });
  });

  group('server-side enforcement (signed-in, anti-spoof)', () {
    AdLimitState verdict(bool granted, int count) => AdLimitState(
          granted: granted,
          dailyCount: count,
          dailyWindowStartMs: now.millisecondsSinceEpoch,
          homeLastClaimMs: 0,
        );

    test('server grant → life granted, revive counter advances', () async {
      final gate = _FakeGate(claim: verdict(true, 1));
      container = await make(gate: gate, signedIn: true);
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload();
      livesN().spendLife();
      final before = lives();
      final res = await mgr().watchForRevive();
      expect(res, RewardedAdShowResult.rewardEarned);
      expect(lives(), before + 1);
      expect(gate.claims, 1);
      expect(gate.lastKind, RewardedAdKind.revive);
    });

    test('server deny → ad watched but NO life granted', () async {
      final gate = _FakeGate(claim: verdict(false, RewardedAdLimits.dailyViewCap));
      container = await make(gate: gate, signedIn: true);
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload();
      livesN().spendLife();
      final before = lives();
      final res = await mgr().watchForRevive();
      // Ad played, server declined → reported as no-reward, no life.
      expect(res, RewardedAdShowResult.dismissedWithoutReward);
      expect(lives(), before);
    });

    test('gate soft-fail (offline, null) → local fallback still grants',
        () async {
      final gate = _FakeGate(claim: null);
      container = await make(gate: gate, signedIn: true);
      provider.showResults.add(RewardedAdShowResult.rewardEarned);
      await mgr().preload();
      livesN().spendLife();
      final before = lives();
      final res = await mgr().watchForRevive();
      expect(res, RewardedAdShowResult.rewardEarned);
      expect(lives(), before + 1);
    });

    test('load-time hydration overwrites a spoofed local count with server truth',
        () async {
      // Local prefs claims a fresh window (spoofed reset), but the server says
      // the daily cap is reached — hydration must win.
      final gate = _FakeGate(
        serverState: verdict(false, RewardedAdLimits.dailyViewCap),
      );
      container = await make(
        gate: gate,
        signedIn: true,
        seedMeta: RewardedAdMeta.initial(),
      );
      await mgr().preload();
      // Let the post-build hydration microtask apply the server state.
      await Future<void>.delayed(Duration.zero);
      expect(mgr().homeButtonPhase(), RewardedAdButtonPhase.capReached);
    });
  });

  group('clock-tamper guards (pure meta)', () {
    test('future home anchor keeps full cooldown (still active)', () {
      final nowMs = now.millisecondsSinceEpoch;
      final future = RewardedAdMeta(
        dailyCount: 0,
        dailyWindowStartMs: nowMs,
        homeLastWatchMs: nowMs + const Duration(hours: 5).inMilliseconds,
      );
      expect(future.homeCooldownRemaining(nowMs),
          RewardedAdLimits.homeCooldown);
      expect(future.homeReady(nowMs), isFalse);
    });

    test('backwards clock does not reset the daily window', () {
      final nowMs = now.millisecondsSinceEpoch;
      final meta = RewardedAdMeta(
        dailyCount: RewardedAdLimits.dailyViewCap,
        dailyWindowStartMs: nowMs,
        homeLastWatchMs: 0,
      );
      // Clock jumps back an hour → window unchanged, cap still reached.
      final back = meta.normalizedDaily(nowMs - 3600 * 1000);
      expect(back.dailyCount, RewardedAdLimits.dailyViewCap);
      expect(back.dailyCapReached(nowMs - 3600 * 1000), isTrue);
    });
  });
}
