# 🫧 Bubble Splash

A small demo arcade game built with [Flutter](https://flutter.dev) and the
[Flame](https://flame-engine.org) game engine.

Bubbles rise from the bottom of the screen — **tap them to pop them and score**.
Let one drift off the top and you lose a life. The game speeds up as your score
climbs. Run out of lives and it's game over (tap **Play Again** to restart).

## Tech stack

- **Flutter** 3.44+ / Dart 3.12+
- **Flame** 1.37 (`flame` package)

## Project structure

```
lib/
├── main.dart                     # App entry point + GameWidget wiring
├── game/
│   └── bubble_splash_game.dart   # FlameGame: spawning, scoring, lives, restart
├── components/
│   └── bubble.dart               # Tappable, rising bubble component
└── ui/
    ├── hud_overlay.dart          # Score + lives HUD (Flutter overlay)
    └── game_over_overlay.dart    # Game-over screen with restart button
test/
└── widget_test.dart              # Unit tests for the core game logic
```

The game state (`score`, `lives`) is exposed as `ValueNotifier`s so the Flutter
UI overlays rebuild reactively without coupling to the render loop.

## Running

```bash
flutter pub get

# Pick a target:
flutter run -d chrome     # web
flutter run -d windows    # Windows desktop
flutter run -d <device>   # an attached Android device/emulator
```

## Testing

```bash
flutter test
flutter analyze
```

## How it works

- `BubbleSplashGame.update()` accumulates time and spawns a `Bubble` every
  `_spawnInterval` seconds. The interval shrinks and bubble speed grows with the
  score to ramp up difficulty.
- Each `Bubble` is a `CircleComponent` with `TapCallbacks`. Tapping pops it
  (`onBubblePopped`); drifting off the top removes it and costs a life
  (`onBubbleMissed`).
- Overlays are plain Flutter widgets registered in `GameWidget.overlayBuilderMap`
  and toggled from the game via `overlays.add/remove`.
