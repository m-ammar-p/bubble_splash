/// Schedules local re-engagement notifications (lives refilled, daily reward
/// ready). The current implementation is a no-op; a real one would wrap
/// flutter_local_notifications. Kept as an interface so the integration points
/// exist now and only the implementation changes later.
abstract interface class NotificationScheduler {
  Future<void> scheduleLivesFull(DateTime at);
  Future<void> scheduleDailyRewardReady(DateTime at);
  Future<void> cancelAll();
}
