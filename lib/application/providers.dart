import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fake/fake_leaderboard_repository.dart';
import '../data/local/prefs_repositories.dart';
import '../data/services/fake_google_auth_service.dart';
import '../data/services/fake_purchase_service.dart';
import '../data/services/fake_rewarded_ad_service.dart';
import '../data/services/noop_notification_scheduler.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/free_life_repository.dart';
import '../domain/repositories/leaderboard_repository.dart';
import '../domain/repositories/lives_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/services/auth_service.dart';
import '../domain/services/notification_scheduler.dart';
import '../domain/services/purchase_service.dart';
import '../domain/services/rewarded_ad_service.dart';

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

/// Keyed by the signed-in Google account id (null = guest, which keeps the
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

final freeLifeRepositoryProvider = Provider<FreeLifeRepository>(
  (ref) => PrefsFreeLifeRepository(ref.watch(sharedPreferencesProvider)),
);

final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) => FakeLeaderboardRepository());

// ---- Services -----------------------------------------------------------

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => FakeRewardedAdService(ref.watch(navigatorKeyProvider)),
);

final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => FakePurchaseService(ref.watch(navigatorKeyProvider)),
);

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) => NoopNotificationScheduler());

final authServiceProvider = Provider<AuthService>(
  (ref) => FakeGoogleAuthService(ref.watch(navigatorKeyProvider)),
);
