import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/achievement.dart';
import '../domain/models/bubble_skin.dart';
import '../domain/models/game_result.dart';
import '../domain/models/player_profile.dart';
import 'auth_controller.dart';
import 'providers.dart';

/// Owns the player's persistent profile and all mutations to it (coins, XP,
/// stats, skins, achievements). Every mutation persists immediately.
///
/// The profile is per-account: watching the auth state means signing in or
/// out rebuilds this notifier against that account's storage slot, so a
/// Google account's levels/records follow the account while guest progress
/// stays in the guest slot.
class ProfileController extends Notifier<PlayerProfile> {
  @override
  PlayerProfile build() {
    final account = ref.watch(authControllerProvider).account;
    final repo = ref.watch(profileRepositoryProvider(account?.id));
    final loaded = repo.load();
    if (loaded != null) return loaded;
    // Fresh player: give a unique, tagged default name (the Google display
    // name when signed in) and persist it so the id (and thus the tag) is
    // stable across launches.
    final id = _newId();
    final fresh = PlayerProfile.initial(id: id)
        .copyWith(name: _taggedName(account?.displayName ?? 'Player', id));
    repo.save(fresh);
    return fresh;
  }

  /// A stable 4-digit discriminator derived from the profile id, so player
  /// names are always unique even when two players pick the same base name
  /// (Discord-style, e.g. "Ace#0421").
  static String _tagFor(String id) =>
      (id.hashCode & 0x7fffffff).remainder(10000).toString().padLeft(4, '0');

  static String _taggedName(String base, String id) =>
      '$base#${_tagFor(id)}';

  void _commit(PlayerProfile next) {
    state = next;
    final accountId = ref.read(authControllerProvider).account?.id;
    ref.read(profileRepositoryProvider(accountId)).save(next);
  }

  static String _newId() =>
      'p_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';

  // ---- Rewards / game results --------------------------------------------

  /// Converts a finished round into rewards, updates lifetime stats and
  /// achievements, and returns a summary for the results screen.
  RewardSummary recordGameResult(GameResult result) {
    // Coins are no longer earned from play — they're a purchasable currency.
    // A round grants XP/progression only.
    final xp = result.score;
    final oldLevel = state.level;
    final isHigh = result.score > state.highScore;

    var next = state.copyWith(
      xp: state.xp + xp,
      highScore: max(state.highScore, result.score),
      gamesPlayed: state.gamesPlayed + 1,
      totalBubblesPopped: state.totalBubblesPopped + result.bubblesPopped,
    );

    final newlyUnlocked = _evaluateAchievements(next);
    if (newlyUnlocked.isNotEmpty) {
      next = next.copyWith(
        unlockedAchievementIds: {
          ...next.unlockedAchievementIds,
          ...newlyUnlocked,
        },
      );
    }
    _commit(next);

    return RewardSummary(
      result: result,
      xpEarned: xp,
      isNewHighScore: isHigh,
      leveledUp: next.level > oldLevel,
      newLevel: next.level,
      unlockedAchievementIds: newlyUnlocked,
    );
  }

  /// Grants bonus coins (e.g. an IAP purchase or rewarded bonus).
  void grantCoins(int amount) =>
      _commit(state.copyWith(coins: state.coins + amount));

  /// Debits [amount] coins (e.g. buying a life pack). Returns false if the
  /// balance is insufficient — nothing is charged then.
  bool spendCoins(int amount) {
    if (state.coins < amount) return false;
    _commit(state.copyWith(coins: state.coins - amount));
    return true;
  }

  // ---- Shop ---------------------------------------------------------------

  /// Buys a skin if affordable and not owned. Returns false otherwise.
  bool buySkin(String skinId) {
    if (state.ownedSkinIds.contains(skinId)) return false;
    final skin = skinById(skinId);
    if (state.coins < skin.price) return false;

    var next = state.copyWith(
      coins: state.coins - skin.price,
      ownedSkinIds: {...state.ownedSkinIds, skinId},
      equippedSkinId: skinId,
    );
    final newly = _evaluateAchievements(next);
    if (newly.isNotEmpty) {
      next = next.copyWith(
        unlockedAchievementIds: {...next.unlockedAchievementIds, ...newly},
      );
    }
    _commit(next);
    return true;
  }

  void equipSkin(String skinId) {
    if (!state.ownedSkinIds.contains(skinId)) return;
    _commit(state.copyWith(equippedSkinId: skinId));
  }

  // ---- Profile editing ----------------------------------------------------

  void rename(String name) {
    // Drop any existing "#tag" the user typed, then re-append the stable tag so
    // the name stays unique.
    final base = name.trim().split('#').first.trim();
    if (base.isEmpty) return;
    _commit(state.copyWith(name: _taggedName(base, state.id)));
  }

  void setAvatar({String? emoji, int? color}) =>
      _commit(state.copyWith(avatarEmoji: emoji, avatarColor: color));

  List<String> _evaluateAchievements(PlayerProfile profile) => [
        for (final a in kAchievements)
          if (!profile.unlockedAchievementIds.contains(a.id) &&
              a.isUnlocked(profile))
            a.id,
      ];
}

final profileControllerProvider =
    NotifierProvider<ProfileController, PlayerProfile>(ProfileController.new);
