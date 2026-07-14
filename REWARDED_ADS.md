# Rewarded Ads — architecture & contract

Production-shaped rewarded-ad layer. **No ad SDK is integrated yet** — the whole
thing runs on a fake provider that simulates real AdMob failure modes. The
swap to real ads is a **single-line change** (see the bottom section); nothing
in the game, UI, manager, limits, or reward logic changes.

## Layers (dependency direction: presentation → application → domain ← data)

| Concern | File |
|---|---|
| Interface (pure Dart) | `lib/domain/services/rewarded_ad_provider.dart` |
| Limits / caps (ONE file) | `lib/domain/services/rewarded_ad_limits.dart` |
| Persisted limit state + tamper math | `lib/domain/models/rewarded_ad_meta.dart` |
| Persistence interface | `lib/domain/repositories/rewarded_ad_repository.dart` |
| Prefs persistence | `lib/data/local/prefs_repositories.dart` (`PrefsRewardedAdRepository`) |
| Fake provider (simulates AdMob) | `lib/data/services/fake_rewarded_ad_provider.dart` |
| Fake simulation knobs | `lib/data/services/fake_rewarded_ad_config.dart` |
| **The manager (all policy)** | `lib/application/rewarded_ad_manager.dart` |
| **The single swap line** | `lib/application/providers.dart` → `rewardedAdProviderProvider` |
| Death/revive UI | `lib/presentation/widgets/continue_round_sheet.dart` |
| Home-screen UI | `lib/presentation/screens/home_screen.dart` |
| Engine pause + lifecycle | `lib/presentation/screens/game_screen.dart`, `lib/game/bubble_splash_game.dart` |

## Interface contract (`RewardedAdProvider`)

Pure Dart, no Flutter imports — the game, UI, and manager depend only on this.

- `bool get isReady` — true only after a successful `load()`, before `show()` consumes it.
- `Future<RewardedAdLoadResult> load()` — preloads ONE ad. Idempotent while loading/ready. Never throws. Returns `ready | noFill | failed`.
- `Future<RewardedAdShowResult> show()` — presents the ad. **Single-use**: consumes it, `isReady` → false until the next `load()`. Returns `notReady` immediately if `!isReady`. Never throws.
- `void dispose()`.

`show()` distinguishes four outcomes — never collapsed to a bool:

| Result | Reward? | Meaning |
|---|---|---|
| `rewardEarned` | **YES** | watched to the end |
| `dismissedWithoutReward` | no | skipped / closed early |
| `failedToShow` | no | failed to present after passing readiness |
| `notReady` | no | no ad was loaded |

## Where the reward is granted (Step 3 — critical)

**One choke point: `RewardedAdManager._grantReward()`.** It is called from
exactly two places (`watchForRevive`, `watchForHomeLife`) and **only** when
`show()` resolves `rewardEarned`. Never on button tap, never on dismiss, never
optimistically.

Idempotent by construction:
- The provider is **single-use** — a repeat `show()` without a fresh `load()` returns `notReady`, so it cannot grant twice.
- A `_busy` re-entrancy guard blocks overlapping intents.
- `LivesController.addLife()` no-ops at the bank cap, so a stray reward can't overfill.

→ one completed view = one life, always.

## Caps, cooldowns, limits (all in `rewarded_ad_limits.dart`)

| Limit | Value | Enforced by |
|---|---|---|
| Revives per death event | `maxRevivesPerDeath = 3` | `revivesThisDeath` (runtime; reset by `beginDeathEvent`) |
| Home button cooldown | `homeCooldown = 30 min` | `RewardedAdMeta.homeLastWatchMs` (persisted) |
| Global daily view cap | `dailyViewCap = 20` | `RewardedAdMeta.dailyCount` (persisted) |
| Daily window | `dailyWindow = 24h`, **rolling** | `RewardedAdMeta.dailyWindowStartMs` |
| No-fill backoff | 1s → 2s → 4s → 8s … cap 60s | `RewardedAdLimits.backoffFor(n)` |

**Daily cap counts only completed views** (`rewardEarned`) — a skip or fail is
not a monetizable view and is not counted.

**Rolling 24h, not local midnight** — chosen to avoid timezone/DST edges and to
resist clock-nudging. The window anchor advances **forward only**.

### Two intended behaviours (asked in review)

- **The 3-ad cap is per death event and resets each death.** `game_screen`
  calls `beginDeathEvent()` (→ `revivesThisDeath = 0`) every time the continue
  prompt opens. So: watch ad → revive → play → die again = a **new** death event
  → a fresh 3. This is by design; the **20 completed views/day** cap is the
  global backstop that bounds the total across all deaths.
- **Skipping an ad does NOT decrement anything.** `revivesThisDeath` and the
  daily count are incremented **only** inside the `rewardEarned` branch of
  `watchForRevive` / `watchForHomeLife`. A skip (`dismissedWithoutReward`) or a
  `failedToShow` grants no life and burns no revive slot and no daily budget —
  the counter stays put and the player can retry. This matches real AdMob (no
  completion = no reward, no charge), so there's no abuse: skipping does nothing.

## Button state machine (Step 6)

Driven entirely by manager state — the widgets read a `RewardedAdButtonPhase`,
never a local bool. Exactly one applies:

```
READY        → enabled "Watch ad …"
LOADING      → disabled "Loading ad…"      (an ad is being fetched)
COOLDOWN     → disabled, live MM:SS         (home only)
NO_FILL      → disabled "No ad — retrying"  (backoff running)
CAP_REACHED  → disabled "Daily limit"       (20/day hit)
CONSUMED     → hidden                        (revive only, 3/3 used)
```

- Revive button: `RewardedAdManager.reviveButtonPhase()` (adds CONSUMED at 3/3).
- Home button: `RewardedAdManager.homeButtonPhase()` (adds COOLDOWN).
- Bank-full is a UI override on both (an ad that can't be banked would rob the player).

No dead buttons: a tappable button is only shown in `READY`.

## Load lifecycle & preload (Step 4)

- Preloaded **proactively**, never at the moment of death:
  - run start — `game_screen._startRound()` → `preload()`
  - continue prompt opens — `beginDeathEvent()` → `preload()`
  - home screen visible — post-frame `preload()`
- On `noFill`/`failed`: phase → `NO_FILL`, exponential backoff retry timer
  (`backoffFor`), auto-retries until ready.
- After every `show()` the consumed ad is reloaded for the next offer.

## Flame engine pausing & lifecycle (Step 5)

The continue flow owns pause/resume; the ad nests inside the already-paused window:

- HP depletes → `BubbleSplashGame._offerContinue()` → `pauseEngine()`.
- The continue sheet shows; the ad overlay (if watched) is a full-screen route on top. Engine stays paused throughout.
- **Both** exit paths resume exactly once: `continueRound()` and `finishRound()` each call `resumeEngine()`. The game can never get stuck paused.
- **Backgrounding mid-ad**: Flame auto-resumes the engine on foreground. `game_screen.didChangeAppLifecycleState` re-pauses it while `game.isAwaitingDecision` is true, so the loop never runs behind the sheet/ad and never double-resumes.

## Architecture rules (Step 7)

- Flame components never call the provider. The game emits an **intent**
  (`onContinueOffer`), `game_screen` bridges to the manager, and the UI reads the
  result. The game stays Riverpod-free.
- State management is the project's existing Riverpod — no new mechanism.

## Tamper-resistance strategy

Persistence is `SharedPreferences` (key `rewarded_ad`) — **spoofable**. Guards
implemented in `RewardedAdMeta` (pure, unit-tested):

- **Home cooldown**: if `now < homeLastWatchMs` (clock moved back, or a future
  anchor set by a forward clock), the FULL cooldown is treated as remaining. A
  backwards clock can never unlock the button early.
- **Daily window**: the window resets only when a full 24h has elapsed
  **forward**. If `now` is before the window start, the window and count are
  preserved — the cap stays active.

> ⚠️ **Before monetized launch**, move these counters to secure storage or (better)
> enforce the daily cap **server-side**. Prefs can be cleared/edited to reset
> everything. This is noted in code at `RewardedAdMeta`'s doc comment.

## Simulating failure modes (dev)

`FakeRewardedAdConfig.debug` (mutable singleton) drives the fake provider:

```dart
FakeRewardedAdConfig.debug.forceNoFill = true;      // every load → NO_FILL + backoff
FakeRewardedAdConfig.debug.forceFailToShow = true;  // every show → failedToShow
FakeRewardedAdConfig.debug.noFillRate = 0.10;       // default 10%
FakeRewardedAdConfig.debug.failToShowRate = 0.02;   // default 2%
// load delay: 500–1500ms randomised; ad length: 5s countdown
```

Fake overlay: full-screen, 5s countdown, an **X (skip)** → `dismissedWithoutReward`
(no reward), and a **Close & claim reward** button after the countdown →
`rewardEarned`.

## TO DO WHEN ADDING ADMOB

1. Add the dependency (`google_mobile_ads`) to `pubspec.yaml` and run a **full
   restart** (not hot reload). Add app id + ad-unit ids to `AndroidManifest.xml`
   / `Info.plist`. (These were intentionally left untouched in this phase.)
2. Create `lib/data/services/admob_rewarded_ad_provider.dart` implementing
   `RewardedAdProvider`:
   - `load()` → `RewardedAd.load(...)`; map `onAdLoaded`→`ready`, `onAdFailedToLoad` no-fill code→`noFill`, else `failed`.
   - `show()` → `ad.show(onUserEarnedReward: ...)`; resolve `rewardEarned` on the earn callback, `dismissedWithoutReward` on dismiss-without-earn, `failedToShow` on `onAdFailedToShowFullScreenContent`, `notReady` if none loaded. Set `fullScreenContentCallback` and null out the ad after show (single-use).
3. **Change ONE line** in `lib/application/providers.dart`:
   ```dart
   final rewardedAdProviderProvider = Provider<RewardedAdProvider>(
     (ref) => AdMobRewardedAdProvider(), // was FakeRewardedAdProvider(...)
   );
   ```
4. Initialize the SDK in `main()` (`MobileAds.instance.initialize()`).
5. Do **not** touch `RewardedAdManager`, `RewardedAdLimits`, the UI, or the
   reward-granting logic. If you find yourself editing those, the abstraction
   leaked — stop and fix the provider instead.
6. Move the daily-cap / cooldown persistence to secure storage or a backend
   before going live (see tamper-resistance above).
7. Real AdMob shows its own activity, so it does not need the shared
   `navigatorKey` the fake uses — drop that constructor arg in the real impl.
