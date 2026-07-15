import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fake/fake_leaderboard_repository.dart';
import '../data/local/prefs_repositories.dart';
import '../app/backend_config.dart';
import '../data/services/fake_auth_service.dart';
import '../data/services/admob_rewarded_ad_provider.dart';
import '../data/services/fake_purchase_service.dart';
import '../data/services/noop_notification_scheduler.dart';
import '../data/services/noop_remote_sync_service.dart';
import '../data/services/noop_rewarded_ad_gate.dart';
import '../data/services/supabase_rewarded_ad_gate.dart';
import '../data/services/supabase_auth_service.dart';
import '../data/services/supabase_remote_sync_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/leaderboard_repository.dart';
import '../domain/repositories/lives_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/rewarded_ad_repository.dart';
import '../domain/services/auth_service.dart';
import '../domain/services/notification_scheduler.dart';
import '../domain/services/purchase_service.dart';
import '../domain/services/remote_sync_service.dart';
import '../domain/services/rewarded_ad_gate.dart';
import '../domain/services/rewarded_ad_provider.dart';

/// Infrastructure providers. This file is the single place concrete
/// implementations are named — swapping the mock data/services for a real
/// backend (Firebase/Supabase/AdMob) means changing only the providers here.

/// Overridden in `main()` with the warmed instance, and in tests with a mock.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Injectable clock so time-based logic (lives regen, daily streak) is testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Shared navigator key — lets services (e.g. the fake ad) show UI without a
/// BuildContext, and gives screens a context-free way to navigate.
final navigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>((ref) => GlobalKey<NavigatorState>());

// ---- Repositories -------------------------------------------------------

/// Keyed by the signed-in account id (null = guest, which keeps the
/// legacy bare `profile` slot). `ProfileController` picks the key from
/// `authControllerProvider`, so each account carries its own progression.
final profileRepositoryProvider =
    Provider.family<ProfileRepository, String?>(
  (ref, accountId) => PrefsProfileRepository(
    ref.watch(sharedPreferencesProvider),
    accountId: accountId,
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => PrefsAuthRepository(ref.watch(sharedPreferencesProvider)),
);

final livesRepositoryProvider = Provider<LivesRepository>(
  (ref) => PrefsLivesRepository(ref.watch(sharedPreferencesProvider)),
);

final rewardedAdRepositoryProvider = Provider<RewardedAdRepository>(
  (ref) => PrefsRewardedAdRepository(ref.watch(sharedPreferencesProvider)),
);

final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) => FakeLeaderboardRepository());

// ---- Services -----------------------------------------------------------

/// ───────────────────────────────────────────────────────────────────────────
/// THE SINGLE AD-SWAP LINE. To ship real ads, change ONLY this binding to
/// `AdMobRewardedAdProvider()` (add its file under data/services/). The manager,
/// game, UI, limits, and reward logic all depend on the [RewardedAdProvider]
/// interface and require NO changes. See REWARDED_ADS.md → "TO DO WHEN ADDING
/// ADMOB".
/// ───────────────────────────────────────────────────────────────────────────
final rewardedAdProviderProvider = Provider<RewardedAdProvider>(
  (ref) => AdMobRewardedAdProvider(),
);

final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => FakePurchaseService(ref.watch(navigatorKeyProvider)),
);

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) => NoopNotificationScheduler());

final authServiceProvider = Provider<AuthService>(
  (ref) =>
      BackendConfig.isConfigured ? SupabaseAuthService() : FakeAuthService(),
);

/// Mirrors the signed-in account's profile + rounds to Supabase (best-effort).
/// No-op when Supabase isn't configured, so guests / offline / tests never
/// touch the network.
final remoteSyncServiceProvider = Provider<RemoteSyncService>(
  (ref) => BackendConfig.isConfigured
      ? SupabaseRemoteSyncService()
      : NoopRemoteSyncService(),
);

/// Server-side rewarded-ad cap enforcer (anti-spoof, Piece 1). Real Supabase
/// gate when configured, else a no-op that makes the manager fall back to the
/// local `RewardedAdMeta` cap check. Only ever consulted for signed-in accounts.
final rewardedAdGateProvider = Provider<RewardedAdGate>(
  (ref) => BackendConfig.isConfigured
      ? SupabaseRewardedAdGate()
      : NoopRewardedAdGate(),
);
