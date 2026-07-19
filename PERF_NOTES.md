# Game smoothness + touch pass (DONE)

Goal was: small bubbles tappable on every device; remove gameplay lag. All steps shipped; the rules live in CLAUDE.md's gotchas.

Root causes:
- **Touch:** `Bubble` (a `CircleComponent`) hit-tested at exact visual radius; min radius 22 (44px) sat at the tap-target floor and the finger covered it.
- **Lag:** `Bubble.render()` ran 3× `MaskFilter.blur` + a shader alloc **every frame per bubble** (15–45 gaussian blurs/frame); `PopEffect` added 18 per-particle blurs per pop — dominated frame time.

Fixes (all done):
1. `containsLocalPoint` override → ~34px min hit radius.
2. Bubble visual rasterized once to `ui.Image` in `onLoad`, blitted in `render` (no per-frame blur/shader).
3. `PopEffect` dropped per-particle blur, count 18→12.
4. HUD/background `BackdropFilter` cost cut (plain translucent fills).
5. Verified in profile mode — `app_time_stats` within ~16ms budget.

# Low-end raster pass (DONE, round 2)

Measured with `installFrameStats()` (`lib/app/frame_stats.dart`, profile-only, called from `main()`): logs `FRAMESTATS f=<frames> jank=<over-budget> ui avg/max raster avg/max` per second to logcat — grep `FRAMESTATS`. Diagnosis: **UI thread ~1ms; raster thread 15–22ms every frame** (fill-rate/repaint-bound), Home idle worst.

Root causes + fixes (all shipped):
1. **Repaint isolation was missing.** The 4 `CandyFloatBubble`s animate forever; each bob re-painted the whole route (3 full-screen gradients, glow title, cards) at 60fps. Fix: **outer** `RepaintBoundary` around each bubble's `AnimatedBuilder` + inner one around the orb. Placement rule: the boundary must wrap the *animating Transform*, not sit under it — a boundary **inside** the transform still lets the repaint dirty the route layer. `CandyNebulaBackground` also wraps itself in a `RepaintBoundary`; `GameHud`/`_HeadStartOverlay` are boundary-wrapped in `game_screen.dart` so a score pop repaints only the HUD layer. Emulator: Home idle raster 20.5→15.6ms (the residual is the emulator's full-screen present floor, see below).
2. **Combo bar rebuilt 60×/s.** `comboFuel` now drains in a private raw field and publishes ceil-quantized 1/64 steps (`_fuelSteps`) — HUD pill rebuilds ~13×/s, meter still visually smooth (128px track), reaches exactly 0.
3. **Mid-play sprite rasterization hitches.** First spawn of each new (kind, color, radius-bucket) ran `toImageSync` + GPU upload mid-round. `_warmSpriteCache()` in `BubbleSplashGame.onLoad` pre-builds all ~50 variants (palette×buckets 6–12 + golden/bomb/combo) before the first frame. `Bubble.buildSprite`/`spriteKey`/`bucketFor` are static for this.
4. **Two full-screen layers during gameplay.** Transparent game canvas composited over a separate `CandyNebulaBackground` widget = 2 full-screen blends/frame. The stage is now painted **inside** the canvas by `NebulaBackdrop` (`game/components/nebula_backdrop.dart`, priority −1000): gradients rasterized once per size into a `ui.Image`, blitted per frame; headless fallback = flat `Candy.bgBottom` fill. `game_screen.dart` no longer stacks the background widget. Gradient specs must stay in sync with `CandyNebulaBackground`.

Measurement gotchas (hard-won):
- **Emulator raster floor ≈ 15.5ms** at 1440×3120 (guest→host copy of every dirty full-screen frame). Any frame where a full-screen surface changes pays it — code-level wins below that floor are invisible on the emulator; paused-game windows (raster ~4ms) show the true non-game cost. Judge low-end gains on real hardware.
- `EGL_emulation app_time_stats` in logcat mixes **all processes and surfaces** (filter by app pid; a second surface = Android hwui, e.g. the AdMob WebView). FRAMESTATS is per-Flutter-frame and unambiguous — prefer it.
- **NEVER blind-tap-spam gameplay on the emulator**: ads are LIVE in profile/release; the continue sheet's "Watch ad" sits in the lower half, and tap spam has clicked a real rewarded ad through to the advertiser (policy risk). Keep scripted taps at y ≤ 1600 (screen 1440×3120); sheet buttons start ≈ y 2200. Screenshot before/after tap batches.
