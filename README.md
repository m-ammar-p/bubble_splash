# Bubble Splash

Arcade bubble-popper built with [Flutter](https://flutter.dev) + the [Flame](https://flame-engine.org) engine, wrapped in a full meta-game: XP/level progression, achievements, two-metric leaderboards, a lives shop, and a lives-as-continues economy. UI is skinned to **"Candy Cosmos"** (cosmic-violet nebula, glossy candy bubbles, Baloo 2 / Nunito type) — spec in [docs/design/candy_cosmos_handoff.md](docs/design/candy_cosmos_handoff.md).

## Gameplay
Bubbles rise — **tap to pop and score**. A rare combo bubble grants a random ×2/×4/×6 timed multiplier. Golden bubbles pay bonus; popping a bomb depletes the round. On depletion you **continue**: spend a banked life or watch a rewarded ad → 3s head-start + temporary 50%-speed breather, score kept. Difficulty ramps asymptotically and plateaus (speed cap, spawn floor, max 6 on screen). Rounds grant XP toward levels/achievements.

**Economy:** play is always free — lives never gate starting. Lives are in-round continues, earned passively (1/30 min), via the Free Life ad claim, or bought in the Shop with coins — all banked to a single cap of 100. Coins are a purchasable IAP currency spent on life packs; every purchase goes through one confirm dialog.

## Tech stack
- **Flutter** 3.44+ / Dart 3.12+ · **Flame** 1.37 · **flutter_riverpod** 3 · **google_fonts** · **google_mobile_ads** · **Supabase** (email/password auth + best-effort profile mirror)
- Platforms: **Android** (active shipping target). iOS parked (scaffold committed, builds need macOS/Xcode). Windows is not a target.

## Architecture
Layered, strict `presentation → application → domain ← data`, plus a Riverpod-free `game/`:
```
lib/
├── main.dart          # warms SharedPreferences, injects it, runs the app
├── app/               # MaterialApp, routes, candy.dart (Candy Cosmos tokens/widgets), ad/backend config
├── domain/            # pure Dart: models, repo/service interfaces, level math, achievements
├── data/              # prefs repos, fake+live services (AdMob, Supabase, IAP) — swap point in providers.dart
├── application/       # Riverpod controllers: profile, lives, ad manager, session, leaderboard
├── presentation/      # screens (home/game/profile/leaderboard/shop) + widgets (HUD, sheets, overlays)
└── game/              # Flame engine: BubbleSplashGame + bubble/pop/score components
```
In-round state (`score`/`hp`/`combo`) is exposed as `ValueNotifier`s so the HUD rebuilds without touching the render loop; the game reports outcomes up via callbacks, stays Riverpod-free.

Full architecture, gotchas, and perf rules: [CLAUDE.md](CLAUDE.md). UI-migration log: [docs/CANDY_COSMOS_MIGRATION.md](docs/CANDY_COSMOS_MIGRATION.md). Ads spec: [REWARDED_ADS.md](REWARDED_ADS.md).

## App icon
Launcher icon generated with [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) from `assets/icon/` (config in `pubspec.yaml`; regenerate with `dart run flutter_launcher_icons`). Android uses an adaptive icon — `adaptive_icon_foreground_inset` **10%** is tuned (default 16% left a dark margin ring, 0% clipped the orange bubble). Play Store 512 icon uploaded manually at publish.

## Running
```bash
flutter pub get
flutter run -d emulator-5554            # Android emulator
flutter run --profile -d emulator-5554  # profile mode — the only valid way to judge fps
flutter test && flutter analyze
dart run tool/gen_audio.dart            # regenerate assets/audio/*.wav from pure math
```
