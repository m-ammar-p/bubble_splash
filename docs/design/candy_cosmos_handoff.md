# Handoff: Bubble Splash — "Candy Cosmos" redesign (Screens 01–05)

## Overview
This is a redesign of the **Bubble Splash** mobile game covering five screens:
**01 Home**, **02 Gameplay**, **03 Get Ready**, **04 Keep Going? (out-of-lives popup)**,
**05 Round Over**. Screen 01 (Home) is specified first; screens 02–05 follow after it.
The Home section also began as a redesign of the game's home/menu screen. It keeps the
original layout and elements (currency / level / lives header, floating bubble logo,
game title, free-life countdown, PLAY button, bottom nav) but replaces the flat purple
palette with a warmer, more polished "Candy Cosmos" look: a deep cosmic-violet background
with pink/orange nebula glow, juicy glossy bubbles, and a glowing gaming title.

## About the Design Files
The file in this bundle — `Bubble Splash Home.dc.html` — is a **design reference created in
HTML/CSS**. It is a visual prototype showing the intended look, spacing, colors, and
animation — **not production code to ship as-is.** The task is to **recreate this screen in
your game's existing environment** (Unity UI, Flutter, React Native, SwiftUI, native
Android, etc.) using that platform's normal layout and animation systems. Match the values
in this README precisely; use the HTML only as a visual reference.

> Note: the HTML uses a small streaming-preview wrapper (`<x-dc>` / `support.js`). Ignore
> that wrapper — only the markup and styles inside it are the design.

## Fidelity
**High-fidelity (hifi).** Final colors, typography, spacing, and animation are all specified
below and should be reproduced pixel-for-pixel (scaled to your device resolution).

## Reference frame
Designed inside a **322 × 690 px** phone screen (the outer rounded black bezel is just mockup
chrome — do not build it). Treat 322 × 690 as the safe content area and scale proportionally
to the real device. All px values below are in this 322-wide space.

---

## Screen: Home / Main Menu

### Layout (top → bottom)
Vertical flex column, screen padding **15px top / 16px sides / 20px bottom**.
1. **Status bar** (device — reuse the OS one in-app; shown here only for the mock)
2. **Header stats row** — space-between: left group (Coins + Level pills), right (Lives pill)
3. **Bubble cluster** (logo) — 184px tall zone
4. **Title** "BUBBLE / SPLASH"
5. **Subtitle** "Pop the bubbles. Beat your best."
6. *(flex spacer — pushes the block below to the bottom, min 24px gap)*
7. **Free-life countdown card**
8. **PLAY button**
9. **Bottom nav** — Profile · Ranks · Shop

### Background
Layered, back-to-front:
- Base gradient: `linear-gradient(160deg, #2C1256, #170B38 55%, #100728)`
- Pink nebula glow: `radial-gradient(90% 60% at 18% 2%, rgba(255,107,139,.30), transparent 55%)`
- Orange nebula glow: `radial-gradient(110% 75% at 92% 16%, rgba(255,157,61,.24), transparent 55%)`

### Header stat pills
Each pill: horizontal flex, `gap 7px`, padding `4px 13px 4px 4px`, `border-radius 999px`,
background `rgba(255,255,255,.10)`, border `1px solid rgba(255,255,255,.16)`.
Icon chip inside each = 26×26 circle with a radial-gradient fill; label is white,
Nunito 800, 14px.

- **Coins** — chip fill `radial-gradient(circle at 34% 28%, #FFE38A, #FFC23D 60%, #C88A00)`,
  "$" glyph in `#7A4D00` (900, 14px). Label: `0`
- **Level** — chip fill `radial-gradient(circle at 34% 28%, #C8A6FF, #8A5BFF 60%, #5A2FC2)`,
  white lightning-bolt icon. Label: `Lv 2`
- **Lives** — chip fill `radial-gradient(circle at 34% 28%, #FFB0B0, #FF5B6E 60%, #C22A3A)`,
  white heart icon. Label: `6/10`

### Bubble cluster (logo)
Four glossy circles, absolutely positioned inside a `184px` tall, full-width box
(`margin-top:10px`). Each bubble uses the same gloss recipe:
`background: radial-gradient(circle at 34% 26%, #FFFFFF, <light> 20%, <mid> 54%, <dark>)`
plus `box-shadow: 0 <n>px <blur>px <glow>, inset -6px -8px 16px <innerDark>, inset 5px 5px 12px rgba(255,255,255,.42)`.

| Bubble | Size | Position (left, top) | light → mid → dark | Glow color |
|---|---|---|---|---|
| Pink (left) | 78px | 10, 70 | #FFC2CF → #FF6B8B → #C22A52 | rgba(255,107,139,.5) |
| Mint (right)| 66px | right 8, top 86 | #C8FFE6 → #4BE0A5 → #12946A | rgba(75,224,165,.5) |
| Orange (main, center) | 132px | 87, 26 | #FFD69E → #FF9D3D → #C25E00 | rgba(255,157,61,.55) |
| Yellow (small) | 46px | 152, 150 | #FFF3B0 → #FFD93D → #C79600 | rgba(255,217,61,.5) |

The white top-left offset in each radial gradient is the specular highlight — keep it.

### Title
Two lines, centered, `margin-top:14px`:
```
BUBBLE
SPLASH
```
- Font: **Baloo 2, weight 800** (rounded chunky gaming face). Substitute: Fredoka 700 / Nunito 900 if Baloo 2 unavailable.
- Size 46px, line-height 0.9, letter-spacing 1px
- Color `#FFE9C9`
- Glow: `text-shadow: 0 0 22px rgba(255,157,61,.55), 0 0 46px rgba(255,107,139,.30), 0 3px 0 rgba(120,40,0,.40)`
  (the last one is a subtle dark bottom bevel)

### Subtitle
"Pop the bubbles. Beat your best." — centered, `margin-top:12px`, Nunito 700, 15px,
color `rgba(255,225,210,.60)`.

### Free-life card
Row, `gap 13px`, padding `12px 14px`, `border-radius 18px`, background `rgba(255,255,255,.08)`,
border `1px solid rgba(255,255,255,.14)`.
- Leading icon: 38×38 circle, background `rgba(255,91,110,.18)`, heart in `#FF7D90`
- Text: "Free life in " white 800 15px + the timer `22:11` in `#FFC07A`

### PLAY button
Full-width, height 60px, `border-radius 20px`, centered play-triangle icon + "PLAY".
- Background: `linear-gradient(180deg, #FFC24D, #FF8F1F)`
- Shadow: `0 12px 34px rgba(255,143,31,.5), inset 0 2px 0 rgba(255,255,255,.55), inset 0 -3px 0 rgba(150,70,0,.30)`
- Label: Baloo 2 800, 26px, letter-spacing 3px, color `#4A2400` (dark brown), icon same color
- **Hover/press state:** `transform: translateY(-2px)` and shadow grows to
  `0 18px 44px rgba(255,143,31,.66), inset 0 2px 0 rgba(255,255,255,.55)`; transition
  `transform .15s, box-shadow .15s`. On touch, use this as the pressed feedback.

### Bottom nav (Profile · Ranks · Shop)
Row, space-around. Each item = a 50×50 rounded-square tile (`border-radius 16px`,
background `rgba(255,255,255,.08)`, border `1px solid rgba(255,255,255,.14)`) with a colored
icon, and a label below (Nunito 700, 12.5px, `rgba(255,255,255,.65)`), `gap 7px`.
- Profile — person icon, `#B48BFF`
- Ranks — bar-chart icon, `#FFCE4D`
- Shop — storefront icon, `#FF7D90`

---

## Animations & Interactions

### Bubble float (idle logo animation)
Each bubble bobs vertically forever with a smooth ease-in-out sine motion, offset so they
don't move in sync. Reproduce with your platform's tween/animator (loop, ping-pong, ease-in-out):

| Bubble | Vertical travel | Duration |
|---|---|---|
| Orange (main) | ±10px (−10 at midpoint) | 5.6s |
| Pink | ±9px (+9 at midpoint) | 4.6s |
| Mint | ±6px (−6 at midpoint) | 5.2s |
| Yellow | ±7px (+7 at midpoint) | 4.2s |

CSS reference:
```css
@keyframes floatA { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-10px)} } /* orange 5.6s */
@keyframes floatB { 0%,100%{transform:translateY(0)} 50%{transform:translateY(9px)} }   /* pink 4.6s */
@keyframes floatC { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-6px)} }  /* mint 5.2s */
@keyframes floatD { 0%,100%{transform:translateY(0)} 50%{transform:translateY(7px)} }    /* yellow 4.2s */
/* animation: <name> <dur> ease-in-out infinite; */
```
Because durations are all different and irrational-ish, the cluster drifts organically and
never visibly repeats — that's the intended feel.

### PLAY button
See "PLAY button" above — lift + glow on hover/press, 0.15s ease.

### Free-life timer
`22:11` is placeholder copy. Drive it from your real regeneration countdown, formatted `MM:SS`.

### Navigation
- PLAY → start game
- Profile / Ranks / Shop tiles → their respective screens

---

## Design Tokens (quick reference)

### Colors
```
Background base       #2C1256 → #170B38 → #100728 (160deg linear)
Nebula pink glow      rgba(255,107,139,.30)
Nebula orange glow    rgba(255,157,61,.24)
Title text            #FFE9C9
Subtitle text         rgba(255,225,210,.60)
Nav label text        rgba(255,255,255,.65)
Glass surface         rgba(255,255,255,.08–.10)
Glass border          rgba(255,255,255,.14–.16)

Accent — Orange (primary/PLAY)  #FFC24D → #FF8F1F ; text #4A2400
Accent — Pink       #FF6B8B (light #FFC2CF, dark #C22A52)
Accent — Mint       #4BE0A5 (light #C8FFE6, dark #12946A)
Accent — Yellow     #FFD93D (light #FFF3B0, dark #C79600)
Accent — Violet     #8A5BFF (level chip / profile)
Accent — Red/heart  #FF5B6E (lives / free-life icon)
Timer highlight     #FFC07A
```

### Typography
```
Display / title / PLAY : Baloo 2, weight 800  (fallback Fredoka 700 / Nunito 900)
UI text / labels       : Nunito, weight 700–800
Title      46px / lh .9  / ls 1px
PLAY       26px         / ls 3px
Stat/timer 14–15px
Subtitle   15px
Nav label  12.5px
```
Google Fonts: `Baloo 2` (600,700,800), `Nunito` (600,700,800,900).

### Spacing / radius
```
Screen padding      15 / 16 / 20
Section gaps        10–14px, footer min gap 24px
Pill radius         999px      Card radius 18px
Button radius       20px       Nav tile radius 16px
Icon chip (stat)    26px       Nav tile 50px      Free-life icon 38px
```

### Shadows / glow
```
Bubble glow    0 <10–16>px <28–40>px <accent .5–.55>, inset -6px -8px 16px <dark .5>, inset 5px 5px 12px rgba(255,255,255,.42)
PLAY           0 12px 34px rgba(255,143,31,.5), inset 0 2px 0 rgba(255,255,255,.55), inset 0 -3px 0 rgba(150,70,0,.3)
Title glow     text-shadow 0 0 22px rgba(255,157,61,.55), 0 0 46px rgba(255,107,139,.3), 0 3px 0 rgba(120,40,0,.4)
```

---

## Screen 02: Gameplay

Same background gradient + nebula glows as Home. Screen padding 15/16/20, vertical flex.

### HUD row (top, `margin-top:12px`, space-between)
- **Left group** (`gap 7px`):
  - **Close button** — 38×38 circle, background `rgba(255,255,255,.10)`, border `1px solid rgba(255,255,255,.16)`, white × icon 15px. Tap → pause/quit.
  - **Lives-remaining pill** — same glass pill recipe as Home stat pills (padding `4px 11px 4px 4px`, radius 999px); 24×24 heart chip `radial-gradient(circle at 34% 28%, #FFB0B0, #FF5B6E 60%, #C22A3A)`, label = remaining continues, Nunito 800 13px white.
- **Center — score**: glass pill, padding `6px 16px`, radius 16px, background `rgba(255,255,255,.10)`, border `rgba(255,255,255,.16)`. Text: Baloo 2 800, 28px, `#FFE9C9`, glow `text-shadow: 0 0 16px rgba(255,157,61,.7)`. Live score value.
- **Right — round hearts**: three 21px hearts, `gap 4px`. Filled = `#FF5B6E` + `drop-shadow(0 0 5px rgba(255,91,110,.6))`; empty = stroke-only heart `rgba(255,255,255,.30)`, stroke 1.8.

### Combo pill (shows while a combo is active)
Centered, `margin-top:12px` below the HUD. Horizontal flex, baseline-aligned, `gap 8px`,
padding `8px 22px`, radius 999px.
- Background `rgba(255,91,110,.10)`; border `1.5px solid rgba(255,107,139,.55)`
- Glow: `box-shadow: 0 0 18px rgba(255,107,139,.25), inset 0 0 12px rgba(255,107,139,.12)`
- "COMBO" — Nunito 800, 12px, letter-spacing 3px, `#FF8296`
- Multiplier "3×" — Baloo 2 800, 26px, `#FF5B6E`, `text-shadow: 0 0 14px rgba(255,91,110,.6)`
- Chain count "·12" — Nunito 800, 15px, `rgba(255,130,150,.75)`
Drive multiplier + chain count from game state; hide (or fade out) when the combo breaks.

### Play area (flex:1)
Glossy bubbles, same gloss recipe as the Home logo bubbles
(`radial-gradient(circle at 34% 26%, #FFF, <light> 20%, <mid> 54%, <dark>)` + glow/inset
shadows), sizes 44–108px, colors from the accent set (orange, violet, pink, yellow, mint).
Each floats with the float keyframes (4.2–5.9s, ease-in-out, infinite). In the real game
bubble positions/sizes/colors come from gameplay logic — this mock only fixes the *look*.

**Bomb bubble** (special): translucent glass ball —
background `radial-gradient(circle at 34% 26%, rgba(255,255,255,.35), rgba(255,255,255,.10) 30%, rgba(120,120,150,.10) 60%, rgba(20,16,36,.20))`,
border `1.5px solid rgba(255,255,255,.4)` — with a dark cartoon bomb (body `#33333D`,
highlight, fuse, orange spark `#FFB13D`) drawn inside.

### Sound toggle (bottom-right)
52×38 pill, glass recipe (`rgba(255,255,255,.10)` bg / `.16` border), white speaker icon 18px.

---

## Screen 03: Get Ready (countdown)

Gameplay screen dimmed by an overlay `rgba(10,5,20,.45)` covering the whole screen; the HUD
row shows at `opacity .55` (non-interactive). Round hearts all filled `#FF5B6E` (no glow).

Centered column (`gap 22px`):
- "GET READY" — Nunito 800, 19px, letter-spacing 7px, `rgba(255,225,210,.75)`
- Countdown digit — Baloo 2 800, **120px**, white, glow
  `text-shadow: 0 0 30px rgba(255,157,61,.75), 0 0 70px rgba(255,107,139,.4)`
- Digit pulses: `@keyframes pulseGlow`, 1s ease-in-out infinite (subtle scale/glow pulse);
  counts 3 → 2 → 1 then round starts.

---

## Screen 04: Keep Going? (out-of-lives popup)

Background: game screen with 3 decorative blurred-out bubbles (40–45% opacity), dimmed by
`rgba(10,5,20,.55)`. HUD at `opacity .5`; all three round hearts empty (stroke style).

### Bottom sheet (anchored to bottom)
Radius 26px, padding `24px 20px 22px`,
background `linear-gradient(180deg, rgba(72,38,110,.92), rgba(34,16,60,.96))`,
border `1px solid rgba(255,255,255,.18)`, shadow `0 -18px 50px rgba(0,0,0,.5)`. Centered column:
- **Icon** — 56×56 circle, `radial-gradient(circle at 34% 28%, #FFD69E, #FF9D3D 60%, #C25E00)`,
  dark-brown restart-arrow glyph, glow `0 8px 24px rgba(255,157,61,.5)`
- **Title** "Keep going?" — Baloo 2 800, 27px, `#FFE9C9` (`margin-top:14px`)
- **Body** "Continue with a life, or stock up by watching ads." — Nunito 700, 13.5px,
  lh 1.5, `rgba(255,225,210,.6)`
- **Primary button** — "Continue · 1 life (2 left)": full-width, 54px, radius 18px, orange
  PLAY gradient + shadows (see Home PLAY button), text `#4A2400` Nunito 800 16.5px, heart
  icon. The "(N left)" count at `opacity .7`. Press: `translateY(-1px)`.
- **Secondary button** — "Watch ad · +1 life (3 left)": same size, glass style
  (`rgba(255,255,255,.10)` bg, `1px solid rgba(255,255,255,.22)` border), white text,
  video icon; hover/press bg `rgba(255,255,255,.16)`.
- **Tertiary link** — "End run": Nunito 700 13.5px `rgba(255,255,255,.5)`,
  hover `rgba(255,255,255,.8)` (`margin-top:15px`).
Buttons stack vertically, `gap 10px`, `margin-top:18px`.
Counts ("2 left", "3 left") come from real continue/ad inventory.

---

## Screen 05: Round Over (score & rewards)

Background: 3 decorative dim bubbles (mint/orange/pink, 35–40% opacity) under an overlay
`rgba(10,5,20,.55)`. Status bar only — no HUD.

### Result card (vertically centered, full width)
Radius 26px, padding `26px 22px 24px`, same violet sheet gradient + border + shadow
(`0 24px 60px rgba(0,0,0,.5)`) as the Keep Going sheet. Centered column:
- **Title** "Round Over" — Baloo 2 800, 27px, `#FFE9C9`
- **Score** — Baloo 2 800, **74px**, `#FFC24D`,
  glow `text-shadow: 0 0 26px rgba(255,157,61,.65), 0 0 60px rgba(255,107,139,.3)` (`margin-top:10px`)
- **Best** "Best 66" — Nunito 700, 14px, `rgba(255,225,210,.55)` (`margin-top:6px`)
- **Divider** — full-width 1px `rgba(255,255,255,.14)`, `margin 18px 0`
- **Rewards** (column, `gap 10px`, centered): each row = 26px gradient icon chip + Nunito 800 15px `rgba(255,255,255,.85)` text with a colored value:
  - XP — violet chip (`#C8A6FF → #8A5BFF → #5A2FC2`) with lightning bolt; "XP **+33**" (value `#C8A6FF`)
  - Level up — yellow chip (`#FFF3B0 → #FFD93D → #C79600`, glyph `#7A5300`) with star; "Level up! **Lv 2**" (value `#FFCE4D`). Only shown when a level-up happened.
- **PLAY AGAIN button** — full-width, 54px, radius 18px, orange gradient + shadows (as PLAY),
  Baloo 2 800 20px ls 1px `#4A2400`, circular replay-arrow icon (stroked arc + solid arrowhead). `margin-top:20px`.
- **Home link** — Nunito 700 13.5px `rgba(255,255,255,.5)`, hover `.8` (`margin-top:15px`).

XP/level values come from the real reward calculation; score/best from the run.

### Navigation
- Gameplay ×/close → pause or Home; PLAY AGAIN → new round (via Get Ready); Keep Going buttons → continue / rewarded ad / end run (→ Round Over); Round Over Home → Home screen.

---

## Assets
All icons in the mock are simple inline SVGs (coin "$", lightning bolt, heart, play triangle,
person, bar chart, storefront, wifi, battery). Replace with your game's own icon set — they
carry no brand meaning, only shape. The bubbles and all glows are pure CSS gradients/shadows,
no image files. No external image assets are required.

## Files
- `Bubble Splash Home.dc.html` — the high-fidelity HTML reference containing all five screens (01 Home, 02 Gameplay, 03 Get Ready, 04 Keep Going?, 05 Round Over), laid out side by side.
