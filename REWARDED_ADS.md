# Rewarded Ads — architecture & contract

Production rewarded-ad layer. **AdMob is live** (`google_mobile_ads` 9.0.0); `FakeRewardedAdProvider` is kept only for offline failure-mode testing. `RewardedAdManager` owns all policy and talks to ads only through the `RewardedAdProvider` interface. Reward is **lives** (no real money). Dependency direction: presentation → application → domain ← data.

## Files
| Concern | File |
|---|---|
| Provider interface (pure Dart) | `domain/services/rewarded_ad_provider.dart` |
| Limits/caps (ONE file) | `domain/services/rewarded_ad_limits.dart` |
| Persisted limit state + tamper math | `domain/models/rewarded_ad_meta.dart` |
| Prefs persistence | `data/local/prefs_repositories.dart` (`PrefsRewardedAdRepository`) |
| Live provider | `data/services/admob_rewarded_ad_provider.dart` |
| Fake provider + knobs | `data/services/fake_rewarded_ad_provider.dart`, `fake_rewarded_ad_config.dart` |
| **Manager (all policy)** | `application/rewarded_ad_manager.dart` |
| Swap line | `application/providers.dart` → `rewardedAdProviderProvider` |
| Anti-spoof gate | `rewardedAdGateProvider` → `SupabaseRewardedAdGate` / `NoopRewardedAdGate` |
| Ad-unit IDs | `lib/app/ad_config.dart` (App IDs in `AndroidManifest.xml` + `Info.plist`) |
| UI | `continue_round_sheet.dart`, `home_screen.dart`, `game_screen.dart` + `bubble_splash_game.dart` |

## Interface (`RewardedAdProvider`) — pure Dart, no Flutter
- `bool get isReady` — true after a successful `load()`, until `show()` consumes it.
- `Future<RewardedAdLoadResult> load()` — preloads ONE ad, idempotent, never throws → `ready | noFill | failed`.
- `Future<RewardedAdShowResult> show()` — **single-use** (consumes it, `isReady`→false), `notReady` if not ready, never throws.
- `void dispose()`.

`show()` outcomes (never a bool): `rewardEarned` (**YES** reward — watched to end) · `dismissedWithoutReward` (skipped) · `failedToShow` · `notReady`.

## Reward choke point (critical)
**One place grants: `RewardedAdManager._grantReward()`**, called from `watchForRevive` / `watchForHomeLife` and **only** in the `rewardEarned` branch. Never on tap/dismiss/optimistically. Idempotent: provider single-use (repeat `show()`→`notReady`), `_busy` re-entrancy guard, `addLife()` no-ops at cap → one completed view = one life.

## Caps / limits (all in `rewarded_ad_limits.dart`)
| Limit | Value | Enforced by |
|---|---|---|
| Revives per death | `maxRevivesPerDeath = 3` | `revivesThisDeath` (runtime, reset by `beginDeathEvent`) |
| Home cooldown | `homeCooldown = 30 min` | `RewardedAdMeta.homeLastWatchMs` (persisted) |
| Daily view cap | `dailyViewCap = 20` | `RewardedAdMeta.dailyCount` |
| Daily window | 24h **rolling** (forward-only anchor) | `dailyWindowStartMs` |
| No-fill backoff | 1→2→4→8…cap 60s | `backoffFor(n)` |

Daily cap counts **only completed views** (`rewardEarned`). Rolling 24h (not local midnight) resists clock-nudging.

**Two intended behaviours:** (1) 3-ad cap resets each death — `beginDeathEvent()` zeroes `revivesThisDeath` every time the prompt opens; the 20/day is the global backstop. (2) Skipping burns nothing — counters increment only in the `rewardEarned` branch, so a skip/fail grants no life and costs no slot (matches AdMob: no completion, no charge).

## Button state machine
Widgets read a `RewardedAdButtonPhase` (never a local bool). Exactly one:
```
READY       → enabled "Watch ad …"
LOADING     → disabled "Loading ad…"
COOLDOWN    → disabled live MM:SS      (home only)
NO_FILL     → disabled "No ad — retrying"
CAP_REACHED → disabled "Daily limit"
CONSUMED    → hidden                    (revive only, 3/3)
```
`reviveButtonPhase()` adds CONSUMED; `homeButtonPhase()` adds COOLDOWN. Bank-full = UI override on both (can't bank → don't offer). Tappable only in READY — no dead buttons.

## Preload + pause
Preloaded proactively (run start, continue prompt open via `beginDeathEvent`, home visible), never at death. On `noFill`/`failed` → NO_FILL + exponential backoff retry until ready; reload after every `show()`.

**`preload()` acts ONLY from `idle`** — `ready`/`loading` need nothing and `noFill` already has a backoff timer armed. Callers preload from `build`, and Home rebuilds ~1/s (`livesTickerProvider` cooldown countdown), so a `noFill`-permissive `preload()` cancelled the timer and re-requested every second: backoff fully defeated, one live AdMob request/sec, and the button visibly flip-flopped "Loading ad…" ↔ "No ad available — retrying". The backoff timer retries via `_requestLoad()` (bypasses the guard) and **keeps the phase at `noFill` while retrying**, so the label stays stable across the whole cycle instead of bouncing through LOADING. Pinned by `rewarded_ad_manager_test.dart` → "repeat preload during NO_FILL does not re-request or flip the label". General rule: a state machine whose retry is timer-owned must reject re-entry from the retrying state, or any per-frame/per-second caller becomes the retry loop.
Continue flow owns pause: HP depletes → `_offerContinue()` → `pauseEngine()`; ad nests in the paused window; **both** `continueRound()` and `finishRound()` call `resumeEngine()` exactly once. Backgrounding mid-ad: `game_screen.didChangeAppLifecycleState` re-pauses while `game.isAwaitingDecision`, so the loop can't run behind the sheet or double-resume. Flame components never call the provider — the game emits `onContinueOffer`, `game_screen` bridges to the manager (game stays Riverpod-free).

## Anti-spoof: server-authoritative caps (Piece 1 — DONE, signed-in users)
Prefs is spoofable, so daily cap + home cooldown are enforced **server-side for signed-in accounts** on the Supabase server clock. Local `RewardedAdMeta` stays source of truth for guests/offline.
- **DB** (`supabase/migrations/0003_ad_limits.sql`): `profiles` gains `ad_daily_count` + `ad_daily_window_start_ms` (home cooldown reuses `free_life_last_claim_ms`). Two SECURITY-INVOKER RPCs: `ad_limit_state()` (authoritative counters for load-time hydration, rolls 24h window forward) and `claim_ad_view(p_kind)` (`home|revive` — atomically re-checks cap/cooldown, records one view, returns `{granted, daily_count, …}`).
- **Gate** (`RewardedAdGate`): every call **fails soft** (null → local fallback) — offline/guests unaffected.
- **Manager:** hydrates local counters from server on build (a prefs edit is overwritten); at the choke point a signed-in view is authorized by `claim_ad_view`, life granted **only on `granted:true`**; a server deny reports `dismissedWithoutReward`. The per-death revive cap (3) stays a never-persisted runtime value (nothing to spoof).

Apply before live: `npx supabase db push`.
**Accepted ceiling:** guests are local-only, and a signed-in user offline falls back to local. Reward is lives (no money) → accepted, not a hole. Full lock-down (anonymous auth + AdMob SSV) deferred until real-money rewards.

### Lessons learned (read before touching the RPCs)
Verified end-to-end on-device (signed-in → `claim_ad_view` → `ad_daily_count` +1, cooldown stamped, +1 life).
1. **`SECURITY INVOKER` runs as the caller — every helper it calls must be executable by that role.** `0003` made the RPCs invoker-security (correct — RLS applies as the user) but revoked execute on helper `_ad_normalize_window` → every call failed `42501 permission denied for function _ad_normalize_window`. Fixed in `0004` (granted back; RLS still scopes each user to their own row). Want a helper private? Make it `SECURITY DEFINER` and do uid-scoping yourself.
2. **Fail-soft hides server errors** — the `42501` surfaced only as "the DB column silently stays 0 while local count ticks up", no crash/log. Debug a fail-soft path by calling the RPC directly with a real user JWT (`curl .../rpc/<fn>` + `Authorization: Bearer <token>` from the device's `sb-<ref>-auth-token` pref).
3. **Unit tests can't catch it** — fake gate + guest never hit the RPC. Green `flutter test` proves Dart wiring, not SQL. Server-authoritative work needs real-backend + real-auth verification.
4. **Reward = `granted:true` only.** Server (not the SDK) is final authority for signed-in users; never grant before the RPC returns.
5. **Reset is lazy + server-clock.** `ad_daily_count`→0 only when a later RPC sees `now() - window_start >= 24h`. No cron. Device clock can't force it — only `postgres`/service role rewrites the anchor.

## Live AdMob wiring
- Dep `google_mobile_ads: ^9.0.0` (needs full restart). SDK init: `main()` → `unawaited(MobileAds.instance.initialize())`.
- IDs in `ad_config.dart`: `AdConfig.usingTestAds` (`kDebugMode` **or** `--dart-define=USE_TEST_ADS=true`) → Google **test** unit, else real unit; platform via `defaultTargetPlatform` (no `dart:io`, test-safe). Sideload onto your own hardware with `flutter build apk --release --dart-define=USE_TEST_ADS=true` — a plain release APK serves LIVE ads and one self-click risks the account. Chosen over AdMob per-device test-ID registration (no hashed IDs to collect/maintain; emulators are auto-registered by the SDK anyway). App IDs (`~`) in `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`) + `Info.plist` (`GADApplicationIdentifier`).
- `AdMobRewardedAdProvider`: `load()` maps loaded→ready, code-3→`noFill`, else `failed`; `show()` grants `rewardEarned` only on `onUserEarnedReward`; single-use. Manager/limits/state-machine/choke point needed no edits — if a future ad change forces edits there, fix the provider instead.

### Before monetized launch
1. **iOS IDs** are test placeholders (no iOS AdMob app) — create it, drop real IDs into `AdConfig` + `Info.plist`. (iOS is parked — low priority.)
2. Real Android App ID is live; real Android rewarded unit `AdConfig._androidRewardedReal` (release only).
3. **AdMob SSV** (Google signed-callback proof of a genuine watch) NOT wired — add only if reward becomes real-money.
4. Register your dev device as an AdMob test device — never click live ads on your own account.

## Simulating failure modes (dev)
Swap `rewardedAdProviderProvider` back to `FakeRewardedAdProvider`; drive `FakeRewardedAdConfig.debug`:
```dart
FakeRewardedAdConfig.debug.forceNoFill = true;      // every load → NO_FILL + backoff
FakeRewardedAdConfig.debug.forceFailToShow = true;  // every show → failedToShow
FakeRewardedAdConfig.debug.noFillRate = 0.10;       // default 10%
FakeRewardedAdConfig.debug.failToShowRate = 0.02;   // default 2%
// load delay 500–1500ms; ad length 5s
```
Fake overlay: 5s countdown, X(skip)→`dismissedWithoutReward`, "Close & claim reward" after countdown→`rewardEarned`.
