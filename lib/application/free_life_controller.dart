import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/free_life_state.dart';
import 'lives_controller.dart';
import 'providers.dart';

/// Owns the **Free Life** reward cooldown. Every [FreeLifeState.cooldown] the
/// player may claim one extra life (gated behind a rewarded ad in the UI).
/// Claiming banks a life via [LivesController] and restarts the cooldown.
class FreeLifeController extends Notifier<FreeLifeState> {
  @override
  FreeLifeState build() {
    final repo = ref.read(freeLifeRepositoryProvider);
    return repo.load() ?? FreeLifeState.initial();
  }

  int _nowMs() => ref.read(clockProvider)().millisecondsSinceEpoch;

  bool get canClaim => state.canClaimAt(_nowMs());

  Duration untilClaimable() => state.untilClaimable(_nowMs());

  /// Grants one life and restarts the cooldown. Returns false if still on
  /// cooldown or the lives bank is already full (cooldown is not consumed then,
  /// so the claim stays available once a life is spent).
  bool claim() {
    if (!canClaim) return false;
    if (ref.read(livesControllerProvider).isFull) return false;
    ref.read(livesControllerProvider.notifier).addLife();
    final next = FreeLifeState(lastClaimMs: _nowMs());
    state = next;
    ref.read(freeLifeRepositoryProvider).save(next);
    return true;
  }
}

final freeLifeControllerProvider =
    NotifierProvider<FreeLifeController, FreeLifeState>(
  FreeLifeController.new,
);
