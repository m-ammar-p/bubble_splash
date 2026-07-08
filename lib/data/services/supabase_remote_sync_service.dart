import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/models/game_result.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/services/remote_sync_service.dart';

/// Supabase-backed profile + round-history mirror. Maps between [PlayerProfile]
/// and the `profiles` table, and appends rounds to `game_rounds`. Every call is
/// wrapped so a missing/uninitialized client or a network error degrades to a
/// no-op (null on read) — gameplay never blocks on the network.
class SupabaseRemoteSyncService implements RemoteSyncService {
  /// Null when Supabase isn't initialized (offline dev / headless tests), so
  /// callers no-op instead of throwing.
  sb.SupabaseClient? get _client {
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PlayerProfile?> fetchProfile(String accountId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', accountId)
          .maybeSingle();
      if (row == null) return null;
      return PlayerProfile(
        // Use the account uuid as the profile id so the derived #tag is stable
        // across devices for the same account.
        id: accountId,
        name: row['name'] as String? ?? 'Player',
        avatarEmoji: row['avatar_emoji'] as String? ?? 'bubble',
        avatarColor: (row['avatar_color'] as num?)?.toInt() ?? 0xFF4FC3F7,
        coins: (row['coins'] as num?)?.toInt() ?? 0,
        xp: (row['xp'] as num?)?.toInt() ?? 0,
        highScore: (row['high_score'] as num?)?.toInt() ?? 0,
        gamesPlayed: (row['games_played'] as num?)?.toInt() ?? 0,
        totalBubblesPopped: (row['total_bubbles_popped'] as num?)?.toInt() ?? 0,
        bestStreak: (row['best_streak'] as num?)?.toInt() ?? 0,
        // Skins aren't account state — always local 'classic' defaults.
        equippedSkinId: 'classic',
        ownedSkinIds: const {'classic'},
        unlockedAchievementIds:
            ((row['unlocked_achievement_ids'] as List?) ?? const [])
                .cast<String>()
                .toSet(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void pushProfile(String accountId, PlayerProfile profile) {
    final client = _client;
    if (client == null) return;
    // `country` is intentionally omitted — it's set once from signup metadata
    // and must not be nulled by a profile push.
    final payload = <String, dynamic>{
      'id': accountId,
      'name': profile.name,
      'avatar_emoji': profile.avatarEmoji,
      'avatar_color': profile.avatarColor,
      'coins': profile.coins,
      'xp': profile.xp,
      'high_score': profile.highScore,
      'games_played': profile.gamesPlayed,
      'total_bubbles_popped': profile.totalBubblesPopped,
      'best_streak': profile.bestStreak,
      'unlocked_achievement_ids': profile.unlockedAchievementIds.toList(),
    };
    unawaited(_fireAndForget(
      client.from('profiles').upsert(payload, onConflict: 'id'),
    ));
  }

  @override
  void logRound(String accountId, GameResult result) {
    final client = _client;
    if (client == null) return;
    unawaited(_fireAndForget(
      client.from('game_rounds').insert({
        'user_id': accountId,
        'score': result.score,
        'bubbles_popped': result.bubblesPopped,
        'max_combo': result.maxCombo,
        'golden_popped': result.goldenPopped,
      }),
    ));
  }

  Future<void> _fireAndForget(Future<dynamic> op) async {
    try {
      await op;
    } catch (_) {
      // Best-effort mirror: swallow network/RLS errors, local state stands.
    }
  }
}
