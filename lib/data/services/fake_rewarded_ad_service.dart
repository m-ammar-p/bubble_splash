import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/services/rewarded_ad_service.dart';

/// Simulates a rewarded ad with a short, non-dismissible dialog. Resolves to
/// `true` once the fake ad "finishes" (the reward is earned). Uses a shared
/// [navigatorKey] so it satisfies the Flutter-free [RewardedAdService] contract.
class FakeRewardedAdService implements RewardedAdService {
  FakeRewardedAdService(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<bool> showRewardedAd() async {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    final earned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FakeAdDialog(),
    );
    return earned ?? false;
  }
}

class _FakeAdDialog extends StatefulWidget {
  const _FakeAdDialog();

  @override
  State<_FakeAdDialog> createState() => _FakeAdDialogState();
}

class _FakeAdDialogState extends State<_FakeAdDialog> {
  static const _duration = Duration(seconds: 3);
  late final Timer _timer;
  int _secondsLeft = _duration.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0E3A55),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ondemand_video, color: Colors.cyanAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Advertisement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reward in $_secondsLeft…',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }
}
