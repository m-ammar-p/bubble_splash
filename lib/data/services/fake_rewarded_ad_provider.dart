import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/services/rewarded_ad_provider.dart';
import 'fake_rewarded_ad_config.dart';

/// Fake [RewardedAdProvider] that simulates the real AdMob lifecycle — load
/// delay, no-fill, fail-to-show, watch-vs-skip — so the manager, UI, and reward
/// logic are exercised against production failure modes before AdMob exists.
/// Uses a shared [navigatorKey] to present its overlay without a BuildContext,
/// satisfying the Flutter-free contract at the call sites.
///
/// All behaviour is driven by [FakeRewardedAdConfig] (the `debug` singleton by
/// default) — force NO_FILL / fail-to-show from there.
class FakeRewardedAdProvider implements RewardedAdProvider {
  FakeRewardedAdProvider(this.navigatorKey, {FakeRewardedAdConfig? config})
      : _config = config ?? FakeRewardedAdConfig.debug;

  final GlobalKey<NavigatorState> navigatorKey;
  final FakeRewardedAdConfig _config;
  final Random _rng = Random();

  bool _ready = false;
  bool _loading = false;

  @override
  bool get isReady => _ready;

  @override
  Future<RewardedAdLoadResult> load() async {
    if (_ready) return RewardedAdLoadResult.ready;
    if (_loading) return RewardedAdLoadResult.failed; // a load is already in flight
    _loading = true;
    try {
      if (!_config.instant) {
        final lo = _config.minLoadDelay.inMilliseconds;
        final hi = _config.maxLoadDelay.inMilliseconds;
        final ms = lo + _rng.nextInt((hi - lo).clamp(1, 1 << 30));
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
      if (_config.forceNoFill || _rng.nextDouble() < _config.noFillRate) {
        _ready = false;
        return RewardedAdLoadResult.noFill;
      }
      _ready = true;
      return RewardedAdLoadResult.ready;
    } finally {
      _loading = false;
    }
  }

  @override
  Future<RewardedAdShowResult> show() async {
    if (!_ready) return RewardedAdShowResult.notReady;
    _ready = false; // single-use: consumed the moment we attempt to show

    if (_config.forceFailToShow || _rng.nextDouble() < _config.failToShowRate) {
      return RewardedAdShowResult.failedToShow;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) return RewardedAdShowResult.failedToShow;

    final result = await navigator.push<RewardedAdShowResult>(
      PageRouteBuilder<RewardedAdShowResult>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, _, _) => _FakeAdOverlay(duration: _config.adDuration),
      ),
    );
    return result ?? RewardedAdShowResult.dismissedWithoutReward;
  }

  @override
  void dispose() {
    _ready = false;
  }
}

/// Full-screen placeholder "ad": a countdown, a skip (X) that returns
/// [RewardedAdShowResult.dismissedWithoutReward], and — once the countdown ends
/// — a close button that returns [RewardedAdShowResult.rewardEarned].
class _FakeAdOverlay extends StatefulWidget {
  const _FakeAdOverlay({required this.duration});
  final Duration duration;

  @override
  State<_FakeAdOverlay> createState() => _FakeAdOverlayState();
}

class _FakeAdOverlayState extends State<_FakeAdOverlay> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _finished => _secondsLeft <= 0;

  void _pop(RewardedAdShowResult result) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Block the hardware back button — a real rewarded ad owns the screen; the
    // player must skip (no reward) or finish (reward), never back out ambiguously.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0514),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ondemand_video,
                      color: Colors.cyanAccent, size: 72),
                  const SizedBox(height: 20),
                  const Text('Advertisement',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _finished ? 'Reward ready!' : 'Reward in $_secondsLeft…',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  if (_finished)
                    FilledButton.icon(
                      onPressed: () =>
                          _pop(RewardedAdShowResult.rewardEarned),
                      icon: const Icon(Icons.check),
                      label: const Text('Close & claim reward'),
                    )
                  else
                    const SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(color: Colors.cyanAccent),
                    ),
                ],
              ),
            ),
            // Skip (X) — always present. Skipping before the reward = no reward.
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                iconSize: 30,
                color: Colors.white54,
                icon: const Icon(Icons.close),
                onPressed: () => _pop(
                  _finished
                      ? RewardedAdShowResult.rewardEarned
                      : RewardedAdShowResult.dismissedWithoutReward,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
