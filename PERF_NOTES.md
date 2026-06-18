# Game smoothness + touch pass (resumable progress)

Goal: small bubbles tappable on every device; remove gameplay lag. Each step = own commit so a token reset can resume from git log.

Root causes found:
- **Touch:** `Bubble` is a `CircleComponent`; hit test = exact visual radius. Min radius 22 (44px) is below the 44px tap-target floor and the finger covers it. No hit padding.
- **Lag:** `Bubble.render()` ran 3× `MaskFilter.blur` + a `RadialGradient.createShader` allocation **every frame, per bubble** (15–45 gaussian blurs/frame). `PopEffect` added 18 per-particle blurs per pop. These dominated frame time.

## Steps
- [x] 1. Bubble hit area — override `containsLocalPoint` with a min tap radius (~34px).
- [x] 2. Cache bubble visual to a `ui.Image` once in `onLoad`; `render` blits it. No per-frame blur/shader alloc.
- [x] 3. PopEffect — drop per-particle `MaskFilter.blur`, cut count 18→12.
- [x] 4. HUD/background blur cost during play (BackdropFilter over animating bg) — reduce if still janky.
- [ ] 5. Verify: `flutter analyze`, `flutter test`, profile-mode `app_time_stats` ~16ms budget; update CLAUDE.md.

Mark a step done by checking it + committing.
