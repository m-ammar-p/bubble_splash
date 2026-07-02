# Candy Cosmos migration — progress tracker

Purpose: reskin screens 01–05 to the "Candy Cosmos" design handoff. If you are a fresh
agent picking this up, read this file first, then the spec, then continue from the first
unchecked phase.

- **Spec (source of truth):** [docs/design/candy_cosmos_handoff.md](design/candy_cosmos_handoff.md)
  (copied from `C:\Users\M A\Downloads\design_handoff_bubble_splash_home\README.md`; the
  bundled `Bubble Splash Home.dc.html` there is a visual reference only — do not copy its code).
- **Scope:** visual reskin + one new feature (live combo pill on Gameplay). All game logic,
  state, and navigation stay intact. Real state everywhere (score, best, lives, timers, XP,
  "N left" counts) — no placeholder copy.
- **Scale rule:** every px in the spec is in a 322px-wide reference frame. Multiply by
  `candyScale(context)` (`lib/app/candy.dart`) — same idea as Home's `_s`.

## Screen → file map

| Screen | Files |
|---|---|
| 01 Home | `lib/presentation/screens/home_screen.dart` (already Candy Cosmos before this migration) |
| 02 Gameplay | `lib/presentation/widgets/game_hud.dart` (HUD, combo pill, sound toggle), `lib/presentation/screens/game_screen.dart` (nebula background), `lib/game/components/bubble.dart` (candy gloss recipe, drawn bomb) |
| 03 Get Ready | `_HeadStartOverlay` in `lib/presentation/screens/game_screen.dart` |
| 04 Keep Going? | `lib/presentation/widgets/continue_round_sheet.dart` |
| 05 Round Over | `lib/presentation/widgets/results_overlay.dart` |
| Shared tokens/widgets | `lib/app/candy.dart` (new) |

## Phases

- [x] **Phase 0 — scaffolding.** Copy spec into repo (done: `docs/design/candy_cosmos_handoff.md`).
      Create `lib/app/candy.dart`: `Candy` color tokens, `candyScale(context)`,
      `CandyNebulaBackground`, `CandyGlass` (pill/tile surface), `CandyChip` (26px radial-gradient
      icon chip), `CandyCtaButton` (orange gradient, press-lift), `CandySheet` (violet gradient
      panel for 04/05).
- [x] **Phase 1 — Screen 01 Home.** Refactor `home_screen.dart` to import shared tokens from
      `candy.dart` instead of its private `_Candy` / `_NebulaBackground` (visual no-op; Home
      already matches the spec). Verify vs spec.
- [x] **Phase 2 — Screen 02 Gameplay.**
      (a) `game_screen.dart`: put `CandyNebulaBackground` behind the `GameWidget` (game paints
      transparent bg; today the old `LiquidBackground` shows through — nebula must cover it).
      (b) `game_hud.dart`: restyle to spec — 38px glass close circle, lives pill w/ 24px heart
      chip, center score pill (Baloo 2 800 28 `#FFE9C9`, orange glow), right 3×21px round hearts
      (filled `#FF5B6E` glow / empty stroke), bottom-right 52×38 sound pill. Replace
      `GlassPanel`/`GlassPill` (BackdropFilter) with plain translucent containers per spec —
      also a perf win.
      (c) Combo pill: pink spec style ("COMBO" 12 ls3 `#FF8296` · multiplier Baloo 2 26 `#FF5B6E`
      · chain "·N" 15 rgba(255,130,150,.75)); wired live to `game.combo` (chain) and
      `1 + combo ~/ 5` (multiplier); visible only while combo active (≥2), hidden otherwise.
      (d) `bubble.dart`: swap `_paintGlass` liquid-glass recipe for the candy gloss recipe
      (white specular at 34%/26% → light 20% → mid 54% → dark; light/dark derived from the
      palette color) — KEEP the rasterize-once-to-`ui.Image` caching. Bomb: replace 💣 emoji
      `TextComponent` with a drawn cartoon bomb (glass ball, body `#33333D`, fuse, spark
      `#FFB13D`) painted into the same cached sprite (also fixes the no-emoji tofu rule).
- [x] **Phase 3 — Screen 03 Get Ready.** Restyle `_HeadStartOverlay`: dim `rgba(10,5,20,.45)`,
      "GET READY" Nunito 800 19 ls7 `rgba(255,225,210,.75)`, digit Baloo 2 800 120px white with
      orange/pink glow, 1s pulse per digit.
- [x] **Phase 4 — Screen 04 Keep Going.** Restyle `continue_round_sheet.dart` as bottom sheet:
      radius 26, violet gradient `rgba(72,38,110,.92)→rgba(34,16,60,.96)`, 56px orange radial
      icon circle w/ restart glyph, "Keep going?" Baloo 2 800 27 `#FFE9C9`, body Nunito 700 13.5,
      primary orange CTA "Continue · 1 life (N left)" (54px, radius 18, heart icon, count at
      .7 opacity), secondary glass "Watch ad · +1 life (N left)" w/ video icon, tertiary
      "End run" link. Logic unchanged (spendLife / rewarded ad ×3 cap / finishRound).
- [x] **Phase 5 — Screen 05 Round Over.** Restyle `results_overlay.dart`: centered violet card
      radius 26, "Round Over" Baloo 2 800 27 `#FFE9C9`, score Baloo 2 800 74 `#FFC24D` w/ glow,
      "Best N" Nunito 700 14, 1px divider, reward rows w/ 26px gradient chips (XP violet bolt
      value `#C8A6FF`; Level up yellow star value `#FFCE4D`, only on level-up; keep existing
      achievement rows, gold chip), PLAY AGAIN orange CTA (54px, Baloo 2 800 20 ls1, replay
      icon), "Home" link. Keep NEW BEST shimmer + entry slide/fade animation.
- [x] **Phase 6 — verify + docs.** `flutter analyze`, `flutter test`; update `CLAUDE.md`
      (UI no longer "mid-migration"; candy.dart is the shared theme; bubble render recipe
      changed) and tick phases here.

## Rules that bit us before (from CLAUDE.md — do not violate)

- No per-frame `MaskFilter.blur`/`ImageFilter.blur`. Bubble gloss must stay rasterized once
  in `onLoad` (`PictureRecorder` → `ui.Image`), blitted per frame; `dispose()` in `onRemove`;
  cheap no-blur fallback for the first frame.
- Keep `BackdropFilter` count low in the HUD; spec surfaces are plain translucent fills, use those.
- Never mutate a Riverpod provider in widget life-cycles; defer with `addPostFrameCallback`.
- `game.add(...)` for gameplay visuals, never `game.world`.
- Audio guards (`isMounted` + try/catch) must survive edits or headless tests crash.
- Verify perf in `flutter run --profile`, watch `app_time_stats`.

## Status log

- 2026-07-02: migration started. Spec copied into repo. Phases defined.
- 2026-07-02: **all phases 0–6 complete.** `flutter analyze` clean; all 40 tests pass
  (widget_test, lives, free_life, profile, leaderboard). Files touched:
  `lib/app/candy.dart` (new), `home_screen.dart` (refactor to shared tokens, visual no-op),
  `game_hud.dart` (rewrite: spec HUD + live combo pill, BackdropFilters removed),
  `game_screen.dart` (nebula bg + Get Ready restyle), `bubble.dart` (candy gloss `_paintCandy`
  + drawn bomb `_paintBomb`, sprite cache preserved), `continue_round_sheet.dart` (rewrite,
  logic unchanged), `results_overlay.dart` (rewrite, logic/animations unchanged), `CLAUDE.md`.
  `glass.dart` still used by profile/leaderboard/shop (out of scope).
- 2026-07-02: **profile-mode run on emulator-5554 passed** — `app_time_stats` avg 12–14ms
  (budget ~16ms), no sustained jank; only the usual first-frame skip on launch.
- 2026-07-02: **post-reskin dead-code cleanup.** Deleted `primary_button.dart` (no users);
  `status_badges.dart` trimmed to `CoinBadge` only (Shop app bar — `LevelBadge`/`LivesBadge`
  superseded by Home's Candy stat pills); removed unused `GlassCircleButton` from `glass.dart`;
  removed unused `AppColors.accent2/neon/neonPurple/heart` from `theme.dart` (legacy screens
  keep `accent`/`gold`/`surface` + orb palette). `flutter analyze` clean, all 40 tests pass.
  **Still pending before shipping:** manual visual pass of screens 02–05 against the handoff
  (combo pill, bomb art, sheets) on-device.
