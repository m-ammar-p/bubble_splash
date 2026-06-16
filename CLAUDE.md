# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Bubble Splash is a Flutter game with a Flame-powered core and a full meta-game around it: a core loop (pop → score → coins/XP → progression), Home/Profile/Leaderboard/Shop/Results screens, and retention hooks (regenerating lives, watch-ad-for-life, daily rewards, achievements, leaderboard). Built with `flame` 1.37 + `flutter_riverpod` 3. Enabled platforms: Android, Windows, web.

## Commands

```bash
flutter pub get                 # fetch dependencies
flutter run -d emulator-5554    # run on Android emulator (or -d chrome / -d windows)
flutter analyze                 # static analysis (lints from analysis_options.yaml)
flutter test                    # run all tests
flutter test --plain-name "popping a bubble increases the score"   # run a single test by name
dart run tool/gen_audio.dart    # regenerate assets/audio/*.wav sound effects
```

After changing pure Dart/Flutter code, hot reload (`r` in the `flutter run` session) is enough. Adding a **dependency or asset** requires a full restart (`flutter run` again), not hot reload.

## Architecture

Layered, with strict dependency direction `presentation → application → domain ← data`, plus an isolated `game/`. Each layer maps to a folder under `lib/`:

- **`domain/`** — pure Dart, no Flutter/plugin imports. Models (`PlayerProfile`, `LivesState`, `GameResult`/`RewardSummary`, `LeaderboardEntry`, `DailyRewardState`, `BubbleSkin`, `Achievement`), repository/service **interfaces**, and catalogs. Achievement unlock conditions and the level/reward math live here as pure functions, so they're trivially unit-testable. Colors are stored as ARGB `int` to keep Flutter out.
- **`data/`** — implements the domain interfaces: `local/` prefs-backed repos (sync), `fake/` simulated-remote leaderboard (seeded, async with latency), `services/` fake rewarded-ad + no-op notification scheduler.
- **`application/`** — Riverpod controllers own all meta-state: `ProfileController`, `LivesController`, `DailyRewardController`, `leaderboardProvider`, `GameSessionController`. **`providers.dart` is the single swap point** — the only place concrete `data/` implementations are named. Swapping the mocks for Firebase/AdMob means editing only that file.
- **`presentation/`** — `ConsumerWidget` screens (`home`, `game`, `profile`, `leaderboard`, `shop`) and widgets. No widget reads a repository directly; everything goes through controllers.
- **`game/`** — the Flame engine, kept **Riverpod-free**. `GameScreen` injects an `onGameOver(GameResult)` callback and the equipped skin's palette; the game reports the result up and the screen feeds it to `GameSessionController`. In-round state (`score`, `hp`, `combo`, `soundOn`) stays as `ValueNotifier`s consumed by `GameHud`/`ResultsOverlay`.

Key flows:
- **Sync vs async repositories:** profile/lives/daily repos are **synchronous** (prefs is warmed in `main()` and injected via `sharedPreferencesProvider.overrideWithValue`), so meta screens never flash a loading state and Riverpod `Notifier.build()` can read them directly. Only the leaderboard repo is async (it models the network) and is consumed via `FutureProvider` with `.when(...)`.
- **Lives regen is timestamp-based** (`LivesState.lastRegenAtMs`): `LivesController` recomputes earned lives from elapsed time on load and on a 1-second timer, so regen is correct while the app is closed. A separate `livesTickerProvider` drives the per-second countdown UI without churning the controller's state each tick. `clockProvider` injects the clock so time logic is deterministically testable.
- **Bubble kinds:** `Bubble` carries a `BubbleKind` (normal/golden/bomb). Golden = bonus points+coins; popping a bomb ends the round; letting a bomb escape is harmless. Combo multiplier rises with consecutive pops within `comboWindow`.

- **Coordinate space gotcha:** bubbles and pop effects are added directly to the game root (`game.add(...)`), **not** to `game.world`. They're positioned in screen coordinates using `size`. Adding a visual to `game.world` would put it in camera/world space and render in the wrong place — keep new gameplay visuals on the game root.

### Headless-test safety

Tests drive controllers and the Flame game directly without a widget tree, so anything needing platform plugins must be guarded:

- Controller/repository tests use a `ProviderContainer` with `sharedPreferencesProvider.overrideWithValue(...)` (`SharedPreferences.setMockInitialValues({})`) and `clockProvider.overrideWithValue(() => now)` for deterministic time. See `test/lives_controller_test.dart` for the pattern.
- The game's audio (`FlameAudio`) is guarded by `isMounted` + `try/catch` so it no-ops headlessly. **Preserve these guards** when adding sound, or `test/widget_test.dart` will crash on missing plugins.

### Audio assets

Sound effects are generated, not committed by hand: [tool/gen_audio.dart](tool/gen_audio.dart) synthesizes `assets/audio/pop.wav` and `game_over.wav` from pure math using only the Dart SDK. Edit the synthesis functions there and rerun `dart run tool/gen_audio.dart` to change the sounds. `assets/audio/` is registered in `pubspec.yaml`; `FlameAudio`'s default prefix is `assets/audio/`.

## Gotchas & lessons learned

Hard-won rules from building this — follow them when adding features to avoid repeating the same bugs:

- **Never mutate a Riverpod provider inside a widget life-cycle** (`initState`, `build`, `didChangeDependencies`, `dispose`). Doing so throws *"Tried to modify a provider while the widget tree was building."* This bit us when `GameScreen.initState` called `livesController.spendLife()` (which sets state). Fix pattern used in [game_screen.dart](lib/presentation/screens/game_screen.dart): defer the mutation with `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) ... })`, or do it in a callback (e.g. a button's `onPressed`). **Reading** a provider in `build` (`ref.watch`/`ref.read`) is fine — only *mutation* is forbidden.
- **Don't make the sync repos async to "be safe."** `Notifier.build()` is synchronous and reads profile/lives/daily repos directly. Making those repos return `Future` reintroduces loading states and breaks `build()`. Keep them sync (cache-over-prefs); only genuinely-remote concerns (leaderboard) are async via `FutureProvider`.
- **Keep new gameplay/visuals on the game root**, not `game.world` (see coordinate-space gotcha above) — silent mis-rendering otherwise.
- **Adding a dependency or asset needs a full restart** (`flutter run` again), not hot reload. Hot reload silently won't pick up `pubspec.yaml` changes or new asset registrations.
- **`flutter create` overwrites `lib/main.dart`, `test/widget_test.dart`, `README.md`** with templates — re-read before editing, and expect to replace the generated `MyApp` smoke test.
- **Builder params:** use Dart's wildcard `_` for unused `ValueListenableBuilder`/builder args (`(_, value, _)`), not `__` — the analyzer flags repeated-underscore names.

### Environment: Windows Application Control can block Dart

Mid-session, `flutter analyze`/`run` started failing with `ProcessStarter::StartForExec failed: An Application Control policy has blocked this file` — a Windows security policy (Smart App Control / WDAC / AV) blocking the Dart runtime from spawning helper processes. This is **environmental, not a code error**. Remedy: allow-list `C:\flutter` (and `…\AppData\Local\Pub\Cache`, the project dir, `…\AppData\Local\Temp`, `C:\Android\Sdk`, `…\.gradle`) in Defender exclusions, or turn off Smart App Control; then restart the terminal. Don't chase it as a build/code bug.

## Windows build gotcha

`android/gradle.properties` sets `kotlin.incremental=false`. This is required, not optional: the project lives on `D:\` while the Flutter Pub cache is on `C:\`, and any Flutter plugin shipping Kotlin sources (e.g. `audioplayers_android`, `shared_preferences_android`) otherwise fails the Android build with `Could not close incremental caches ... different roots` — Kotlin can't compute relative paths across Windows drive roots. If a Gradle build fails with that error, confirm the flag is present, then `flutter clean` and rebuild. Web/Windows targets are unaffected.
