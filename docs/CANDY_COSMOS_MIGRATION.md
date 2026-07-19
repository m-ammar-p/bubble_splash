# Candy Cosmos migration — log (COMPLETE)

Reskin of every screen to the [Candy Cosmos spec](design/candy_cosmos_handoff.md) (source of truth). **All phases done, every screen is Candy Cosmos.** This file is now history + the screen→file map. Scale rule: every spec px is in a 322-wide frame — multiply by `candyScale(context)` (`lib/app/candy.dart`).

## Screen → file map
| Screen | Files |
|---|---|
| 01 Home | `home_screen.dart` |
| 02 Gameplay | `game_hud.dart` (HUD, combo pill, sound), `game_screen.dart` (nebula bg), `bubble.dart` (candy gloss `_paintCandy`, drawn bomb `_paintBomb`) |
| 03 Get Ready | `_HeadStartOverlay` in `game_screen.dart` |
| 04 Keep Going? | `continue_round_sheet.dart` |
| 05 Round Over | `results_overlay.dart` |
| 06 Profile / 07 Pick Avatar / 08 Edit Name | `profile_screen.dart` (`_AvatarPickerDialog`, `_NameDialog`) |
| Shop | `shop_screen.dart` |
| Ranks | `leaderboard_screen.dart` |
| Shared tokens/widgets | `lib/app/candy.dart` |

`candy.dart` owns: `Candy` colors, `candyScale`, text styles, `CandyNebulaBackground`, `CandyGlass`, `CandyChip`, `CandyCtaButton`, `CandySheet`, `CandySectionLabel`, `CandyStatPill`, `CandyBackCircle`, `CandyBubbleCluster`/`CandyFloatBubble`, `CandyGameTitle`, `candyBubbleGradient`/`candyBubbleShades` (glossy avatar, used by `PlayerAvatar`), `showCandyConfirmDialog`, chip colors incl. `pinkChip`/`mintChip`. Spec surfaces are plain translucent fills — **no `BackdropFilter`**.

## Perf rules that bit us (from CLAUDE.md — don't violate)
- No per-frame `MaskFilter.blur`/`ImageFilter.blur`. Bubble gloss rasterized once in `onLoad` (`PictureRecorder`→`ui.Image`), blitted per frame, `dispose()` in `onRemove`, cheap no-blur first-frame fallback.
- Keep `BackdropFilter` count low; use plain translucent fills.
- Never mutate a Riverpod provider in widget life-cycles — defer with `addPostFrameCallback`.
- `game.add(...)` for gameplay visuals, never `game.world`.
- Audio guards (`isMounted` + try/catch) must survive edits or headless tests crash.
- Judge perf only in `flutter run --profile`, watch `app_time_stats` (~16ms).

## History (all 2026-07)
- **Phases 0–6:** built `candy.dart`; reskinned Home, Gameplay (HUD + live combo pill, BackdropFilters removed), Get Ready, Keep Going, Round Over; bubble candy gloss + drawn bomb (sprite cache preserved). Profile-mode avg 12–14ms.
- **Phase 7:** Profile / Avatar picker / Name dialog reskinned; picker now previews live, persists on Done. Added `pinkChip`/`mintChip`.
- **Gameplay tuning + economy rework:** difficulty plateaus (asymptotic curves, +240px/s cap, 0.38s spawn floor, max 6 on screen, post-continue 50% relief over 45s — `difficulty_test.dart`); lag-compensated hit zones; shared bubble sprite cache. Shop sells life packs (coins), single 100 lives cap (two-cap reverted), packs refused un-charged if they don't fit, `showCandyConfirmDialog` = one popup/purchase.
- **Shop + Ranks reskinned;** extracted `CandySectionLabel`/`CandyStatPill`/`CandyBackCircle`, moved `candyBubbleGradient`/`candyBubbleShades` into `candy.dart`. **Dead code purged:** `glass.dart`, `status_badges.dart`, `theme.dart` (`LiquidBackground` orb was invisible under nebula = wasted GPU) all deleted; minimal Material theme moved into `app.dart`; `cupertino_icons` dropped. Skin/palette system kept (test-covered, no Shop UI).
- **Login + auth:** Login shares Home hero (`CandyBubbleCluster`/`CandyGameTitle`). Google sign-in built then **dropped entirely** for Supabase email/password (no Google Cloud dep). `auth_panel.dart` = `AuthPanel` (sign in/up toggle, name/email/password, country picker, orange CTA) + `showSignInPrompt` (Shop/Profile gates). Guest gates: coin packs prompt sign-in at tap; guest name tap opens sign-in (`rename` guards via `canRename`). `AuthService` = `signUp`/`signIn`(→`AuthAccount`, throw `AuthFailure`)+`signOut`; `SupabaseAuthService` / `FakeAuthService`. Country via `lib/app/countries.dart`. Supabase gated on `BackendConfig.isConfigured`; needs "Confirm email" off.
- **Header size pass:** `CandyBackCircle` 38→34, `CandyStatPill` chip 26→23/label 14→12.5; HUD close 38→34, lives chip 24→22, score 28→25, round hearts 21→19.
