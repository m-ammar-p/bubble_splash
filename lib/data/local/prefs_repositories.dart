import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_reward_state.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/repositories/daily_reward_repository.dart';
import '../../domain/repositories/lives_repository.dart';
import '../../domain/repositories/profile_repository.dart';

/// Local, synchronous implementations of the meta-state repositories backed by
/// [SharedPreferences] (already initialized at app bootstrap, so reads/writes
/// are synchronous JSON round-trips).

class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'profile';

  @override
  PlayerProfile? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : PlayerProfile.fromJson(raw);
  }

  @override
  void save(PlayerProfile profile) => _prefs.setString(_key, profile.toJson());
}

class PrefsLivesRepository implements LivesRepository {
  PrefsLivesRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'lives';

  @override
  LivesState? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : LivesState.fromJson(raw);
  }

  @override
  void save(LivesState state) => _prefs.setString(_key, state.toJson());
}

class PrefsDailyRewardRepository implements DailyRewardRepository {
  PrefsDailyRewardRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'daily_reward';

  @override
  DailyRewardState? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : DailyRewardState.fromJson(raw);
  }

  @override
  void save(DailyRewardState state) => _prefs.setString(_key, state.toJson());
}
