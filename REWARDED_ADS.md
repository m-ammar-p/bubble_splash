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

## ADMOB — WIRED (real provider live)

Real AdMob is integrated. `google_mobile_ads` 9.0.0 is the provider;
`rewardedAdProviderProvider` binds `AdMobRewardedAdProvider`. The fake
(`FakeRewardedAdProvider`) is kept for reference/manual failure-mode testing but
is no longer the default.

What was done (files):
- **Dep**: `google_mobile_ads: ^9.0.0` in `pubspec.yaml` (needs a full restart, not hot reload).
- **IDs**: `lib/app/ad_config.dart` — the single source of truth for ad-unit ids.
  `kDebugMode` serves Google's **test** unit; release serves the real unit.
  Platform picked via `defaultTargetPlatform` (no `dart:io`, test-safe).
- **App IDs** (the `~` ids): `AndroidManifest.xml`
  (`com.google.android.gms.ads.APPLICATION_ID`) + `Info.plist`
  (`GADApplicationIdentifier`). Kept in sync with `AdConfig`'s mirror constants.
- **Provider**: `lib/data/services/admob_rewarded_ad_provider.dart` — `load()`
  maps `onAdLoaded`→`ready`, `onAdFailedToLoad` code 3 (NO_FILL)→`noFill`, else
  `failed`; `show()` grants `rewardEarned` only on `onUserEarnedReward`,
  `dismissedWithoutReward` on dismiss-without-earn, `failedToShow` on the fail
  callback; single-use (nulls the ad, disposes on dismiss/fail). No `navigatorKey`
  (real AdMob owns its own activity).
- **Swap line**: `providers.dart` → `AdMobRewardedAdProvider()`.
- **SDK init**: `main()` fires `unawaited(MobileAds.instance.initialize())`.

Untouched (the abstraction held): `RewardedAdManager`, `RewardedAdLimits`, the
button state machine, the UI, and the reward-granting choke point — none needed
edits. If a future change forces edits there to make ads work, the abstraction
leaked; fix the provider instead.

### STILL TO DO before monetized launch

1. **iOS ids**: `AdConfig.iosAppId` / iOS rewarded unit are **test** placeholders
   (no iOS AdMob app yet). Create the iOS app in AdMob, drop the real ids into
   `AdConfig` + `Info.plist`'s `GADApplicationIdentifier`.
2. **Real Android App ID** is live in the manifest; the real Android rewarded unit
   is `AdConfig._androidRewardedReal` (used only in release builds).
3. **AdMob SSV (deferred)**: server-side *verification* of the ad view itself
   (Google's signed callback proving a genuine watch) is NOT wired. Add it if the
   reward ever becomes real-money value; overkill for a lives-only reward. See
   "Anti-spoof" below for what IS done.
4. **Test devices**: register your dev device as an AdMob test device (or keep
   using the debug test unit) — never click live ads on your own account.

## Anti-spoof: server-authoritative caps (Piece 1 — DONE, signed-in users)

The daily cap + home cooldown are enforced **server-side for signed-in accounts**
using the Supabase **server clock**, so editing local prefs can no longer reset
them. Local `RewardedAdMeta` stays the source of truth for **guests / offline**.

- **DB** (`supabase/migrations/0003_ad_limits.sql`): `profiles` gains
  `ad_daily_count` + `ad_daily_window_start_ms` (home cooldown reuses the
  existing `free_life_last_claim_ms`). Two SECURITY-INVOKER RPCs:
  - `ad_limit_state()` — returns the authoritative counters for load-time
    hydration (rolls the 24h window forward on the server clock).
  - `claim_ad_view(p_kind)` — atomically re-checks the daily cap (and, for
    `'home'`, the 30-min cooldown) and records one view; returns
    `{ granted, daily_count, … }`. `p_kind` ∈ `home | revive`.
- **Gate** (`RewardedAdGate` → `SupabaseRewardedAdGate` / `NoopRewardedAdGate`,
  bound at `rewardedAdGateProvider`): every call **fails soft** (null → local
  fallback), so offline play and guests are unaffected.
- **Manager** (`RewardedAdManager`): on build it hydrates local counters from
  the server for signed-in users (a prefs edit is overwritten); at the reward
  choke point, a signed-in user's completed view is authorized by
  `claim_ad_view` — the life is granted only on `granted: true`. A server deny
  (cap/cooldown) reports `dismissedWithoutReward` (ad played, no life). Guests /
  offline / a soft-failed gate keep the original local cap-stamp path.
- **The per-death revive cap (3)** stays a runtime client value — it's never
  persisted, so there's nothing to spoof.

**Apply the migration** before this is live: `npx supabase db push`.

**Known ceiling (accepted):** an anonymous **guest** is still local-only, and a
signed-in user who goes **offline** falls back to local — reward is lives (no
money), so this is an accepted trade, not a hole to plug. Full lock-down would
need anonymous auth for all + AdMob SSV; deferred until real-money rewards.

### Lessons learned (Piece 1 — read before touching the RPCs)

Verified end-to-end on-device (signed-in account, real test ad → `claim_ad_view`
→ `ad_daily_count` +1 in Supabase, cooldown stamped, +1 life). Bugs hit and what
they teach:

1. **`SECURITY INVOKER` functions run as the *caller* — every helper they call
   must be executable by that role.** `0003` made `claim_ad_view` /
   `ad_limit_state` `security invoker` (correct — RLS should apply as the user)
   but then `revoke`d execute on their helper `_ad_normalize_window` from
   `authenticated`. Result: every RPC failed with `42501 permission denied for
   function _ad_normalize_window`. Fixed in `0004` by granting execute back — RLS
   on `profiles` still confines each user to their own row, so it's safe. Rule:
   don't revoke a helper from the role that reaches it through an invoker-security
   parent; if you truly want the helper private, make it `SECURITY DEFINER`
   instead (runs as owner, sidesteps the caller's grants) — but then *you* own the
   row-scoping, so pass and check the uid explicitly.
2. **Fail-soft hides server errors — it made the bug look like "nothing
   happens".** The gate swallows every error and falls back to local
   (`RewardedAdMeta`), so the `42501` surfaced as *the DB column silently staying
   0 while the local count ticked up* — no crash, no log. When debugging a
   fail-soft path, **call the underlying RPC directly with a real user JWT**
   (`curl .../rpc/<fn>` + `Authorization: Bearer <access_token>` pulled from the
   device's `sb-<ref>-auth-token` pref) — that surfaces the real error the app
   ate. Consider a debug-only log on the soft-fail branch next time.
3. **Unit tests passed but couldn't catch it — they use a fake gate + guest, so
   the real RPC never runs.** A green `flutter test` proves the Dart wiring, not
   the SQL. Server-authoritative work needs a **real-backend + real-auth**
   verification pass (device or curl-with-JWT), not just headless tests.
4. **Reward = `granted:true` only, ever.** The server (not the ad SDK) is the
   final authority for signed-in users; a completed ad that the server declines
   (cap/cooldown) grants nothing and reports `dismissedWithoutReward`. Never grant
   optimistically before the RPC returns.
5. **Reset is lazy + server-clock.** `ad_daily_count` rolls to 0 only when a
   later RPC call (`ad_limit_state` on app load, or `claim_ad_view` on a watch)
   sees `now() - ad_daily_window_start_ms >= 24h`. No cron. Rolling 24h from the
   anchor, not local midnight. The device clock can't force it early — only the
   `postgres`/service role can rewrite `ad_daily_window_start_ms`.
