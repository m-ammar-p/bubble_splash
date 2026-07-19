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
