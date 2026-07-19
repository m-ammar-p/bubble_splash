import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/rewarded_ad_meta.dart';
import '../domain/services/rewarded_ad_gate.dart';
import '../domain/services/rewarded_ad_limits.dart';
import '../domain/services/rewarded_ad_provider.dart';
import 'auth_controller.dart';
import 'lives_controller.dart';
import 'providers.dart';

/// Where the ad unit is in its load lifecycle (drives the button state machine).
enum RewardedAdLoadPhase { idle, loading, ready, noFill }

/// The single visual state a rewarded-ad button may be in. Exactly one applies;
/// the widget renders from this and nothing else — never a local bool.
enum RewardedAdButtonPhase { ready, loading, cooldown, noFill, capReached, consumed }

/// Runtime state exposed to the UI. Persisted limits live in [meta]; [loadPhase]
/// and [revivesThisDeath] are ephemeral (not persisted).
class RewardedAdManagerState {
  const RewardedAdManagerState({
    required this.meta,
    required this.loadPhase,
    required this.revivesThisDeath,
  });

  final RewardedAdMeta meta;
  final RewardedAdLoadPhase loadPhase;
  final int revivesThisDeath;

  RewardedAdManagerState copyWith({
    RewardedAdMeta? meta,
    RewardedAdLoadPhase? loadPhase,
    int? revivesThisDeath,
  }) =>
      RewardedAdManagerState(
        meta: meta ?? this.meta,
        loadPhase: loadPhase ?? this.loadPhase,
        revivesThisDeath: revivesThisDeath ?? this.revivesThisDeath,
      );
}

/// **The one service that owns all rewarded-ad policy.** Limits, cooldowns,
/// daily cap, the load/backoff lifecycle, and the single reward-granting choke
/// point all live here — the UI and the game only send intents and read state.
///
/// It talks to ads exclusively through [RewardedAdProvider], so **this class does
/// not change when AdMob replaces the fake** — only the provider binding in
/// `providers.dart` does.
///
/// Reward rule (Step 3): a life is granted ONLY from [_grantReward], which is
/// called ONLY on [RewardedAdShowResult.rewardEarned]. Never on tap, never on
/// dismiss. Idempotent: the provider is single-use (a second show returns
/// `notReady`) and a `_busy` guard blocks re-entry, so one earned view = one life.
class RewardedAdManager extends Notifier<RewardedAdManagerState> {
  Timer? _backoffTimer;
  int _consecutiveNoFills = 0;
  bool _busy = false;

  RewardedAdProvider get _provider => ref.read(rewardedAdProviderProvider);
  RewardedAdGate get _gate => ref.read(rewardedAdGateProvider);
  int _nowMs() => ref.read(clockProvider)().millisecondsSinceEpoch;

  /// The signed-in account id, or null for a guest. Server enforcement (anti-
  /// spoof) applies only to signed-in accounts; guests use the local cap path.
  String? get _accountId => ref.read(authControllerProvider).account?.id;

  @override
  RewardedAdManagerState build() {
    // Rebuild (and re-hydrate from the server) when the account changes.
    final account = ref.watch(authControllerProvider).account;
    final repo = ref.read(rewardedAdRepositoryProvider);
    final loaded = (repo.load() ?? RewardedAdMeta.initial()).normalizedDaily(_nowMs());
    // Persist any window roll performed on load.
    repo.save(loaded);
    // Capture the provider now — ref.read is illegal inside onDispose.
    final provider = _provider;
    ref.onDispose(() {
      _backoffTimer?.cancel();
      provider.dispose();
    });
    // Overwrite local counters with server truth for signed-in users (a local
    // prefs edit can't survive this) — after build, so state exists.
    if (account != null) {
      Future.microtask(_hydrateFromServer);
    }
    return RewardedAdManagerState(
      meta: loaded,
      loadPhase: RewardedAdLoadPhase.idle,
      revivesThisDeath: 0,
    );
  }

  /// Pulls the server-authoritative daily count + home cooldown and overwrites
  /// the local meta. No-op (soft-fail) for guests / offline — local stands.
  Future<void> _hydrateFromServer() async {
    final id = _accountId;
    if (id == null) return;
    final s = await _gate.fetchState(id);
    if (s == null) return;
    _commitMeta(state.meta.copyWith(
      dailyCount: s.dailyCount,
      dailyWindowStartMs: s.dailyWindowStartMs,
      homeLastWatchMs: s.homeLastClaimMs,
    ));
  }

  void _commitMeta(RewardedAdMeta meta) {
    state = state.copyWith(meta: meta);
    ref.read(rewardedAdRepositoryProvider).save(meta);
  }

  // ---- Preload lifecycle --------------------------------------------------

  /// Proactively loads the next ad. Call at run start and on low health — never
  /// at the moment of death (a load delay must not stall the continue prompt).
  /// Idempotent; drives NO_FILL exponential backoff internally.
  ///
  /// **Only acts from [RewardedAdLoadPhase.idle].** `ready`/`loading` need
  /// nothing, and `noFill` already has a backoff retry armed — re-entering
  /// there would cancel the timer and fire a fresh request. Home rebuilds once
  /// a second (lives ticker) and preloads post-frame, so without this guard a
  /// no-fill turned into one AdMob request per second (backoff defeated) and the
  /// button flipped "Loading ad…" ↔ "No ad available — retrying" forever.
  Future<void> preload() async {
    if (state.loadPhase != RewardedAdLoadPhase.idle) return;
    await _requestLoad();
  }

  /// Issues the actual load. Bypasses the [preload] phase guard so the backoff
  /// timer can retry from `noFill`.
  Future<void> _requestLoad() async {
    _backoffTimer?.cancel();
    // Retrying after a no-fill keeps showing NO_FILL rather than bouncing back
    // to LOADING — the label must stay stable across the whole backoff cycle.
    final retrying = state.loadPhase == RewardedAdLoadPhase.noFill;
    if (!retrying) {
      state = state.copyWith(loadPhase: RewardedAdLoadPhase.loading);
    }
    final result = await _provider.load();
    switch (result) {
      case RewardedAdLoadResult.ready:
        _consecutiveNoFills = 0;
        state = state.copyWith(loadPhase: RewardedAdLoadPhase.ready);
      case RewardedAdLoadResult.noFill:
      case RewardedAdLoadResult.failed:
        state = state.copyWith(loadPhase: RewardedAdLoadPhase.noFill);
        _scheduleBackoffRetry();
    }
  }

  void _scheduleBackoffRetry() {
    final delay = RewardedAdLimits.backoffFor(_consecutiveNoFills);
    _consecutiveNoFills++;
    _backoffTimer?.cancel();
    _backoffTimer = Timer(delay, () {
      // Only retry if still not ready (a manual preload may have succeeded).
      if (state.loadPhase == RewardedAdLoadPhase.noFill) _requestLoad();
    });
  }

  // ---- Death-event revives ------------------------------------------------

  /// Resets the per-death revive counter and warms an ad. Call when the continue
  /// prompt opens for a fresh death event.
  void beginDeathEvent() {
    state = state.copyWith(revivesThisDeath: 0);
    preload();
  }

  RewardedAdButtonPhase reviveButtonPhase() {
    final now = _nowMs();
    if (state.revivesThisDeath >= RewardedAdLimits.maxRevivesPerDeath) {
      return RewardedAdButtonPhase.consumed;
    }
    if (state.meta.dailyCapReached(now)) return RewardedAdButtonPhase.capReached;
    return _loadDrivenPhase();
  }

  int get revivesLeft =>
      (RewardedAdLimits.maxRevivesPerDeath - state.revivesThisDeath)
          .clamp(0, RewardedAdLimits.maxRevivesPerDeath);

  /// Intent: "watch an ad to revive". Grants exactly one life on a completed
  /// view. Returns the raw result so the caller can react (e.g. keep the sheet
  /// open on a skip). Enforces the per-death and daily caps.
  Future<RewardedAdShowResult> watchForRevive() async {
    final now = _nowMs();
    if (_busy) return RewardedAdShowResult.notReady;
    if (state.revivesThisDeath >= RewardedAdLimits.maxRevivesPerDeath) {
      return RewardedAdShowResult.notReady;
    }
    if (state.meta.dailyCapReached(now)) return RewardedAdShowResult.notReady;

    final result = await _showGuarded();
    if (result == RewardedAdShowResult.rewardEarned) {
      return _resolveEarnedView(RewardedAdKind.revive);
    }
    return result;
  }

  // ---- Home-screen life ---------------------------------------------------

  RewardedAdButtonPhase homeButtonPhase() {
    final now = _nowMs();
    if (!state.meta.homeReady(now)) return RewardedAdButtonPhase.cooldown;
    if (state.meta.dailyCapReached(now)) return RewardedAdButtonPhase.capReached;
    return _loadDrivenPhase();
  }

  Duration homeCooldownRemaining() =>
      state.meta.homeCooldownRemaining(_nowMs());

  /// Intent: "watch an ad for a free life" from Home. Grants one life on a
  /// completed view and starts the 30-min cooldown. Enforces cooldown + daily cap.
  Future<RewardedAdShowResult> watchForHomeLife() async {
    final now = _nowMs();
    if (_busy) return RewardedAdShowResult.notReady;
    if (!state.meta.homeReady(now)) return RewardedAdShowResult.notReady;
    if (state.meta.dailyCapReached(now)) return RewardedAdShowResult.notReady;

    final result = await _showGuarded();
    if (result == RewardedAdShowResult.rewardEarned) {
      return _resolveEarnedView(RewardedAdKind.home);
    }
    return result;
  }

  // ---- Shared internals ---------------------------------------------------

  /// Resolves a completed view into a reward decision. **Server-authoritative
  /// for signed-in users**: the gate re-checks the daily cap (and, for `home`,
  /// the 30-min cooldown) on the server clock and returns the verdict + updated
  /// counters, which overwrite local meta. Guests / offline / a soft-failed gate
  /// fall back to the local cap-stamp path (unchanged behaviour). Returns
  /// `rewardEarned` iff a life was actually granted.
  Future<RewardedAdShowResult> _resolveEarnedView(RewardedAdKind kind) async {
    final id = _accountId;
    if (id != null) {
      final verdict = await _gate.claimView(id, kind);
      if (verdict != null) {
        _commitMeta(state.meta.copyWith(
          dailyCount: verdict.dailyCount,
          dailyWindowStartMs: verdict.dailyWindowStartMs,
          homeLastWatchMs: verdict.homeLastClaimMs,
        ));
        if (!verdict.granted) {
          // Ad played, but the server declined (cap/cooldown) — no life. Report
          // as "no reward" so the UI doesn't falsely celebrate.
          return RewardedAdShowResult.dismissedWithoutReward;
        }
        _grantReward();
        if (kind == RewardedAdKind.revive) {
          state = state.copyWith(revivesThisDeath: state.revivesThisDeath + 1);
        }
        return RewardedAdShowResult.rewardEarned;
      }
      // Gate soft-failed (offline / backend down) → fall through to local.
    }
    // Local path: guest, offline, or backend not configured.
    _grantReward();
    final now = _nowMs();
    if (kind == RewardedAdKind.home) {
      _commitMeta(state.meta.withHomeWatch(now).recordView(now));
    } else {
      _commitMeta(state.meta.recordView(now));
      state = state.copyWith(revivesThisDeath: state.revivesThisDeath + 1);
    }
    return RewardedAdShowResult.rewardEarned;
  }

  RewardedAdButtonPhase _loadDrivenPhase() {
    switch (state.loadPhase) {
      case RewardedAdLoadPhase.ready:
        return RewardedAdButtonPhase.ready;
      case RewardedAdLoadPhase.noFill:
        return RewardedAdButtonPhase.noFill;
      case RewardedAdLoadPhase.idle:
      case RewardedAdLoadPhase.loading:
        return RewardedAdButtonPhase.loading;
    }
  }

  /// Presents the ad under a re-entrancy guard, then warms the next one (the
  /// shown ad is single-use / consumed). Never grants — the caller decides.
  Future<RewardedAdShowResult> _showGuarded() async {
    _busy = true;
    try {
      state = state.copyWith(loadPhase: RewardedAdLoadPhase.idle);
      return await _provider.show();
    } finally {
      _busy = false;
      // Consumed: reload for the next offer.
      preload();
    }
  }

  /// **The only place a rewarded life is granted.** Called solely on a completed
  /// view. `addLife` no-ops at the bank cap, so a stray reward can't overfill.
  void _grantReward() {
    ref.read(livesControllerProvider.notifier).addLife();
  }
}

final rewardedAdManagerProvider =
    NotifierProvider<RewardedAdManager, RewardedAdManagerState>(
  RewardedAdManager.new,
);
