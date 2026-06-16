/// Shows a rewarded ad and reports whether the reward was earned (i.e. the ad
/// was watched to completion). The interface takes no BuildContext so it stays
/// Flutter-free; implementations that need UI use a shared navigator key.
///
/// The fake implementation simulates an ad with a dialog. Swap in an AdMob-backed
/// implementation later without touching any caller.
abstract interface class RewardedAdService {
  Future<bool> showRewardedAd();
}
