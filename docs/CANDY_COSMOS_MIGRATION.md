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
| 06 Profile | `lib/presentation/screens/profile_screen.dart` |
| 07 Pick Avatar | `_AvatarPickerDialog` in `profile_screen.dart` |
| 08 Edit Name | `_NameDialog` in `profile_screen.dart` |
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
- [x] **Phase 7 — Screens 06–08 (Profile / Pick Avatar / Edit Name).** Specs live only in
      the handoff **HTML** (`Bubble Splash Home.dc.html`, screens 06–08) — the handoff README
      still documents 01–05 only. Full rewrite of `profile_screen.dart`:
      (06) glass 38px back circle + "Profile" Baloo 2 800 20; 90px glossy bubble avatar in
      the player's `avatarColor` (white→light→mid→dark radial; exact spec trios for the six
      swatch colors, HSL +0.20/−0.24 fallback for legacy colors) w/ 30px orange pencil badge
      (→ 07); tappable name Baloo 2 800 23 (→ 08); XP glass card w/ 10px orange gradient bar
      + glow; STATS 2×2 glass cards (32px chips: yellow star High Score, violet gamepad
      Games, pink bubbles Bubbles, mint bolt Level); ACHIEVEMENTS — unlocked amber-tinted
      (rgba(255,194,77,.12) bg / .5 border, orange chip, gold check circle), locked dim glass
      + lock chip; all rows from `kAchievements` + `unlockedAchievementIds`.
      (07) `_AvatarPickerDialog` over rgba(10,5,20,.6) barrier: violet `.96→.98` sheet
      (`_DialogSheet`), 5-col grid of 46px tiles (glass unselected / glossy colored bubble +
      white border + glow selected), six 34px glossy swatches (white ring + glow selected),
      48px orange Done. Selection previews live in dialog state; `setAvatar` fires only on
      Done. (08) `_NameDialog` at `Alignment(0,-0.5)` so the keyboard never covers it: glass
      input w/ 2.5px `#FF9D3D` bottom underline, Nunito 800 16, `#FFC24D` caret, live "N/16"
      counter (max 16), 46px orange Save → `rename()` (unique #tag re-append preserved).
      Native system keyboard — the mock's drawn keyboard was intentionally not built.
      `candy.dart` gained `pinkChip`/`mintChip`. Logic/navigation unchanged (`Routes.profile`,
      `rename`, `setAvatar`).

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
- 2026-07-02: **Phase 7 complete — screens 06–08 reskinned** (`profile_screen.dart` rewrite,
  `candy.dart` +`pinkChip`/`mintChip`). `flutter analyze` clean, all 40 tests pass. Old
  AlertDialog pickers replaced by Candy dialogs; avatar picker now previews live and persists
  on Done (was: persisted per tap). `profile_screen.dart` no longer uses `glass.dart`/
  `theme.dart` — remaining legacy screens: leaderboard, shop. **Pending:** manual visual pass
  of 06–08 on-device.
- 2026-07-02: **Profile XP bar fix.** Empty track wasn't rendering — the fill
  `FractionallySizedBox` had no `heightFactor` (collapsed to 0) and `ClipRRect` clipped the
  glow. Now an explicit 10px white-.14 track Container with a left-aligned `heightFactor:1`
  orange fill and un-clipped glow (matches spec box-shadow). `flutter analyze` clean.
- 2026-07-06: **Gameplay tuning + perf + lives-economy rework.** Difficulty now plateaus
  (asymptotic speed/spawn curves, +240px/s cap, 0.38s spawn floor, max 6 bubbles on screen,
  post-continue 50%-speed relief recovering over 45s — `test/difficulty_test.dart` pins it);
  bubble hit zones lag-compensate downward ~100ms of travel. Perf: bubble sprites shared via
  a per-game cache + `toImageSync` (no per-spawn raster), `ScorePopup` rasterized once
  (was: full text layout every frame). Shop reworked: sells **life packs** (+5/+15/+30 for
  coins), coin packs 500/1500/3000 — skins no longer sold (system stays in code). Lives:
  single 100 cap for every source (a 10/100 two-cap split was tried and reverted — confusing);
  packs that don't fit are refused un-charged; ad offers disabled at full bank. New shared
  `showCandyConfirmDialog` in `candy.dart` (violet sheet, icon chip, orange CTA) — exactly one
  popup per purchase; `FakePurchaseService` no longer shows its own dialog. `flutter analyze`
  clean, all 36 tests pass; verified live on emulator-5554 in profile mode (avg 3–6ms/frame).
- 2026-07-07: **Shop reskinned to Candy Cosmos** (`shop_screen.dart` rewrite: nebula bg,
  glass header + coin pill, GET COINS / LIVES sections, glass pack cards w/ gradient chips +
  orange CTA buys; purchase logic untouched). Dedupe pass extracted `CandySectionLabel`,
  `CandyStatPill`, `CandyBackCircle` into `candy.dart` (shop/profile/home now share them).
  Verified on emulator (layout, confirm dialog, disabled packs).
- 2026-07-07: **Ranks (leaderboard) reskinned to Candy Cosmos** in two phases.
  Phase 1 chrome: nebula bg, shared header, `_CandyTabs` glass segmented control (one
  generic widget for metric + scope, replaces both Material SegmentedButtons). Phase 2 rows:
  glass cards, gold Baloo rank for top 3, amber "unlocked"-style tint on the player's row,
  Baloo values + Nunito labels; `candyBubbleGradient`/`candyBubbleShades` moved from
  `profile_screen.dart` into `candy.dart` and `PlayerAvatar` now renders the glossy candy
  bubble. Dead legacy files deleted: `glass.dart`, `status_badges.dart` (zero refs — Shop
  reskin removed the last `CoinBadge` use). **Every screen is now Candy Cosmos**.
- 2026-07-07: **post-migration dead-code purge.** `theme.dart` deleted — the `LiquidBackground`
  orb backdrop was invisible under the screens' opaque `CandyNebulaBackground`s (wasted GPU),
  taking `AppColors`, `_Orb` and the `activeGameplayCount` gameplay-freeze machinery with it;
  the minimal Material theme (Candy-seeded, violet snackbars) moved into `app.dart`. Unused
  template dep `cupertino_icons` dropped from pubspec. Skin/palette system deliberately kept
  (game reads the equipped skin; `buySkin`/`equipSkin` are test-covered, just no Shop UI).
