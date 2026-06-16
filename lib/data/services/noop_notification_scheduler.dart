import '../../domain/services/notification_scheduler.dart';

/// Placeholder scheduler. Real re-engagement notifications would be wired here
/// via flutter_local_notifications; for now the calls are recorded as no-ops so
/// the rest of the app can integrate against the interface today.
class NoopNotificationScheduler implements NotificationScheduler {
  @override
  Future<void> scheduleLivesFull(DateTime at) async {}

  @override
  Future<void> scheduleDailyRewardReady(DateTime at) async {}

  @override
  Future<void> cancelAll() async {}
}
