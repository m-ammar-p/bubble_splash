# Bubble Splash

An arcade bubble-popping game built with [Flutter](https://flutter.dev) and the
[Flame](https://flame-engine.org) game engine, wrapped in a full meta-game:
XP/level progression, achievements, two-metric leaderboards, a skin shop, and a
lives-as-continues economy. UI is skinned to the **"Candy Cosmos"** design
(cosmic-violet nebula stage, glossy candy bubbles, Baloo 2 / Nunito type) —
spec in [docs/design/candy_cosmos_handoff.md](docs/design/candy_cosmos_handoff.md).

## Gameplay

Bubbles rise from the bottom — **tap to pop and score**. Consecutive pops build
a combo multiplier. Golden bubbles pay bonus points; popping a bomb (or missing
3 bubbles) depletes the round. When that happens you can **continue**: spend a
banked life or watch a rewarded ad, get a 3-second head-start, keep your
difficulty and score. Rounds grant XP toward levels and achievements.

**Economy:** play is always free — lives are never needed to start. Lives are
in-round continues, earned passively (1 per 30 min) and via the Free Life ad
claim, banked up to 10. Coins are a purchasable currency spent only on skins.

## Tech stack

- **Flutter** 3.44+ / Dart 3.12+
- **Flame** 1.37 · **flutter_riverpod** 3 · **google_fonts** (Baloo 2 / Nunito)
- Platforms: Android + iOS (iOS builds require macOS/Xcode)

## Architecture

Layered, strict dependency direction `presentation → application → domain ← data`,
plus a Riverpod-free `game/`:

```
lib/
├── main.dart               # warms SharedPreferences, injects it, runs the app
├── app/                    # MaterialApp, routes, legacy theme, candy.dart (Candy Cosmos tokens/widgets)
├── domain/                 # pure Dart: models, repo/service interfaces, level math, achievements
├── data/                   # prefs-backed repos, fake leaderboard/ads/IAP (swap point for Firebase/AdMob/RevenueCat)
├── application/            # Riverpod controllers: profile, lives, free life, session, leaderboard
├── presentation/           # screens (home/game/profile/leaderboard/shop) + widgets (HUD, sheets, overlays)
└── game/                   # Flame engine: BubbleSplashGame + bubble/pop/score components
```

In-round state (`score`, `hp`, `combo`) is exposed as `ValueNotifier`s so the
HUD rebuilds reactively without touching the render loop; the game reports
outcomes up via callbacks and stays Riverpod-free.

See [CLAUDE.md](CLAUDE.md) for the full architecture notes, gotchas, and
performance rules, and [docs/CANDY_COSMOS_MIGRATION.md](docs/CANDY_COSMOS_MIGRATION.md)
for the UI-migration log.

## Running

```bash
flutter pub get
flutter run -d emulator-5554            # Android emulator
flutter run --profile -d emulator-5554  # profile mode — the only valid way to judge fps
```

## Testing

```bash
flutter test
flutter analyze
```

Audio is generated, not hand-committed: `dart run tool/gen_audio.dart`
resynthesizes `assets/audio/*.wav` from pure math.
