import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auth_state.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/models/rewarded_ad_meta.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/lives_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/rewarded_ad_repository.dart';

/// Local, synchronous implementations of the meta-state repositories backed by
/// [SharedPreferences] (already initialized at app bootstrap, so reads/writes
/// are synchronous JSON round-trips).

class PrefsProfileRepository implements ProfileRepository {
  /// Profile storage is namespaced per signed-in account: guests keep the
  /// legacy bare `profile` key (pre-login installs keep their progress),
  /// Google accounts get `profile_<accountId>` so each account carries its
  /// own levels/records on this device.
  PrefsProfileRepository(this._prefs, {String? accountId})
      : _key = accountId == null ? 'profile' : 'profile_$accountId';

  final SharedPreferences _prefs;
  final String _key;

  @override
  PlayerProfile? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : PlayerProfile.fromJson(raw);
  }

  @override
  void save(PlayerProfile profile) => _prefs.setString(_key, profile.toJson());
}

class PrefsAuthRepository implements AuthRepository {
  PrefsAuthRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'auth';

  @override
  AuthState? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : AuthState.fromJson(raw);
  }

  @override
  void save(AuthState state) => _prefs.setString(_key, state.toJson());
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

class PrefsRewardedAdRepository implements RewardedAdRepository {
  PrefsRewardedAdRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'rewarded_ad';

  @override
  RewardedAdMeta? load() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : RewardedAdMeta.fromJson(raw);
  }

  @override
  void save(RewardedAdMeta meta) => _prefs.setString(_key, meta.toJson());
}
