# Candy Cosmos handoff — pixel spec (source of truth)

Redesign of Bubble Splash, screens **01 Home · 02 Gameplay · 03 Get Ready · 04 Keep Going? · 05 Round Over**. Look: deep cosmic-violet bg + pink/orange nebula, glossy candy bubbles, glowing title. HTML in the bundle (`Bubble Splash Home.dc.html`) is a **visual reference only** — recreate natively, match values here.

**Reference frame: 322 × 690 px.** All px below are in this space — scale proportionally to device (`candyScale(context) = screenWidth / 322`). Bezel is mock chrome, don't build it.

---

## Shared tokens

### Background (back→front)
- Base: `linear-gradient(160deg, #2C1256, #170B38 55%, #100728)`
- Pink nebula: `radial-gradient(90% 60% at 18% 2%, rgba(255,107,139,.30), transparent 55%)`
- Orange nebula: `radial-gradient(110% 75% at 92% 16%, rgba(255,157,61,.24), transparent 55%)`

### Colors
```
Title text          #FFE9C9      Subtitle       rgba(255,225,210,.60)
Nav label           rgba(255,255,255,.65)
Glass surface       rgba(255,255,255,.08–.10)   Glass border  rgba(255,255,255,.14–.16)
Orange (primary)    #FFC24D → #FF8F1F ; text #4A2400
Pink                #FF6B8B (light #FFC2CF, dark #C22A52)
Mint                #4BE0A5 (light #C8FFE6, dark #12946A)
Yellow              #FFD93D (light #FFF3B0, dark #C79600)
Violet              #8A5BFF (level chip / profile)
Red/heart           #FF5B6E      Timer highlight  #FFC07A
```

### Typography
```
Display/title/PLAY : Baloo 2 w800   (fallback Fredoka 700 / Nunito 900)
UI/labels          : Nunito w700–800
Title 46px/lh.9/ls1   PLAY 26px/ls3   Stat/timer 14–15px   Subtitle 15px   Nav label 12.5px
```
Google Fonts: `Baloo 2` (600,700,800), `Nunito` (600,700,800,900).

### Spacing / radius
```
Screen padding 15/16/20   Section gaps 10–14 (footer min 24)
Pill 999px   Card 18px   Button 20px   Nav tile 16px/50px   Stat chip 26px   Free-life icon 38px
```

### Glossy bubble recipe (reused everywhere)
`radial-gradient(circle at 34% 26%, #FFFFFF, <light> 20%, <mid> 54%, <dark>)` + `box-shadow: 0 <n>px <blur>px <glow>, inset -6px -8px 16px <innerDark>, inset 5px 5px 12px rgba(255,255,255,.42)`. White offset = specular highlight, keep it.

---

## 01 Home
Layout (top→bottom), padding 15/16/20: status bar (OS) · header stats row (space-between: Coins+Level left, Lives right) · bubble cluster (184px tall) · title · subtitle · flex spacer (min 24px) · free-life card · PLAY · bottom nav.

**Stat pills:** flex gap7, padding `4px 13px 4px 4px`, radius 999, bg `rgba(255,255,255,.10)`, border `rgba(255,255,255,.16)`. Icon = 26px radial-gradient chip; label white Nunito 800 14px.
- Coins — chip `radial-gradient(circle at 34% 28%, #FFE38A, #FFC23D 60%, #C88A00)`, "$" glyph `#7A4D00` 900 14px. Label `0`
- Level — chip `#C8A6FF → #8A5BFF 60% → #5A2FC2`, white bolt. Label `Lv 2`
- Lives — chip `#FFB0B0 → #FF5B6E 60% → #C22A3A`, white heart. Label `6/10`

**Bubble cluster:** 4 glossy circles absolutely positioned in 184px box (`margin-top:10px`):

| Bubble | Size | left,top | light→mid→dark | Glow |
|---|---|---|---|---|
| Pink | 78 | 10,70 | #FFC2CF→#FF6B8B→#C22A52 | rgba(255,107,139,.5) |
| Mint | 66 | right8,top86 | #C8FFE6→#4BE0A5→#12946A | rgba(75,224,165,.5) |
| Orange(main) | 132 | 87,26 | #FFD69E→#FF9D3D→#C25E00 | rgba(255,157,61,.55) |
| Yellow | 46 | 152,150 | #FFF3B0→#FFD93D→#C79600 | rgba(255,217,61,.5) |

**Float (idle):** vertical sine bob, ping-pong ease-in-out infinite, offset so out of sync:
Orange ±10px 5.6s · Pink +9px 4.6s · Mint −6px 5.2s · Yellow +7px 4.2s. Irrational durations → never visibly repeats.

**Title:** two lines `BUBBLE / SPLASH`, centered `margin-top:14px`, Baloo 2 800, 46px/lh.9/ls1, `#FFE9C9`, glow `0 0 22px rgba(255,157,61,.55), 0 0 46px rgba(255,107,139,.30), 0 3px 0 rgba(120,40,0,.40)`.
**Subtitle:** "Pop the bubbles. Beat your best." centered `mt12`, Nunito 700 15px `rgba(255,225,210,.60)`.

**Free-life card:** row gap13, padding `12px 14px`, radius 18, bg `rgba(255,255,255,.08)`, border `.14`. Leading 38px circle bg `rgba(255,91,110,.18)` heart `#FF7D90`; text "Free life in " white 800 15px + timer `MM:SS` `#FFC07A` (drive from real regen countdown).

**PLAY:** full-width h60, radius20, play-triangle + "PLAY". Bg `linear-gradient(180deg, #FFC24D, #FF8F1F)`, shadow `0 12px 34px rgba(255,143,31,.5), inset 0 2px 0 rgba(255,255,255,.55), inset 0 -3px 0 rgba(150,70,0,.30)`, label Baloo 2 800 26px ls3 `#4A2400`. Press: `translateY(-2px)`, shadow → `0 18px 44px rgba(255,143,31,.66), inset 0 2px 0 rgba(255,255,255,.55)`, transition .15s.

**Bottom nav (space-around):** each = 50px tile radius16 bg `.08`/border `.14` + colored icon + label below (Nunito 700 12.5px `rgba(255,255,255,.65)`), gap7. Profile person `#B48BFF` · Ranks bar-chart `#FFCE4D` · Shop storefront `#FF7D90`.

---

## 02 Gameplay
Same bg. Padding 15/16/20.

**HUD row** (top `mt12`, space-between):
- Left gap7: Close 38px circle bg `.10`/border `.16`, white × 15px (tap→pause/quit) · Lives pill (Home recipe, padding `4px 11px 4px 4px`) 24px heart chip `#FFB0B0→#FF5B6E→#C22A3A`, label = continues Nunito 800 13px white.
- Center score: glass pill padding `6px 16px` radius16 bg `.10`/border `.16`, Baloo 2 800 28px `#FFE9C9` glow `0 0 16px rgba(255,157,61,.7)`. Live value.
- Right round hearts: three 21px, gap4. Filled `#FF5B6E` + `drop-shadow(0 0 5px rgba(255,91,110,.6))`; empty stroke-only `rgba(255,255,255,.30)` w1.8.

**Combo pill** (while active), centered `mt12`, flex baseline gap8, padding `8px 22px` radius999. Bg `rgba(255,91,110,.10)`, border `1.5px rgba(255,107,139,.55)`, glow `0 0 18px rgba(255,107,139,.25), inset 0 0 12px rgba(255,107,139,.12)`. "COMBO" Nunito 800 12px ls3 `#FF8296` · mult "3×" Baloo 2 800 26px `#FF5B6E` glow `0 0 14px rgba(255,91,110,.6)` · chain "·12" Nunito 800 15px `rgba(255,130,150,.75)`. Drive from game state; hide when combo breaks.

**Play area:** glossy bubbles (recipe above) 44–108px, accent colors, float 4.2–5.9s. Positions/sizes/colors from gameplay logic.
**Bomb:** translucent glass ball `radial-gradient(circle at 34% 26%, rgba(255,255,255,.35), rgba(255,255,255,.10) 30%, rgba(120,120,150,.10) 60%, rgba(20,16,36,.20))`, border `1.5px rgba(255,255,255,.4)`, drawn cartoon bomb inside (body `#33333D`, highlight, fuse, spark `#FFB13D`).
**Sound toggle** (bottom-right): 52×38 pill glass `.10`/`.16`, white speaker 18px.

---

## 03 Get Ready (countdown)
Gameplay dimmed by `rgba(10,5,20,.45)`; HUD at opacity .55 non-interactive; round hearts all filled `#FF5B6E` no glow.
Centered column gap22: "GET READY" Nunito 800 19px ls7 `rgba(255,225,210,.75)` · digit Baloo 2 800 **120px** white glow `0 0 30px rgba(255,157,61,.75), 0 0 70px rgba(255,107,139,.4)`, 1s ease-in-out pulse per digit, counts 3→2→1.

---

## 04 Keep Going? (out-of-lives)
Bg: game screen + 3 blurred bubbles (40–45% opacity), dim `rgba(10,5,20,.55)`, HUD opacity .5, round hearts empty.

**Bottom sheet:** radius26, padding `24px 20px 22px`, bg `linear-gradient(180deg, rgba(72,38,110,.92), rgba(34,16,60,.96))`, border `.18`, shadow `0 -18px 50px rgba(0,0,0,.5)`. Centered column:
- Icon 56px circle `#FFD69E→#FF9D3D→#C25E00`, dark-brown restart glyph, glow `0 8px 24px rgba(255,157,61,.5)`
- Title "Keep going?" Baloo 2 800 27px `#FFE9C9` (`mt14`)
- Body "Continue with a life, or stock up by watching ads." Nunito 700 13.5px lh1.5 `rgba(255,225,210,.6)`
- Primary "Continue · 1 life (N left)": full-width 54px radius18, orange gradient+shadow, text `#4A2400` Nunito 800 16.5px, heart icon, "(N left)" opacity .7. Press `translateY(-1px)`.
- Secondary "Watch ad · +1 life (N left)": same size, glass bg `.10`/border `.22`, white text, video icon, press bg `.16`.
- Tertiary "End run": Nunito 700 13.5px `rgba(255,255,255,.5)`, hover `.8` (`mt15`).
Buttons stack gap10 `mt18`. Counts from real continue/ad inventory.

---

## 05 Round Over
Bg: 3 dim bubbles (35–40% opacity) under `rgba(10,5,20,.55)`. Status bar only, no HUD.

**Result card** (vert-centered, full-width): radius26, padding `26px 22px 24px`, same violet sheet gradient+border+shadow `0 24px 60px rgba(0,0,0,.5)`. Centered column:
- Title "Round Over" Baloo 2 800 27px `#FFE9C9`
- Score Baloo 2 800 **74px** `#FFC24D` glow `0 0 26px rgba(255,157,61,.65), 0 0 60px rgba(255,107,139,.3)` (`mt10`)
- "Best N" Nunito 700 14px `rgba(255,225,210,.55)` (`mt6`)
- Divider full-width 1px `rgba(255,255,255,.14)` margin 18 0
- Rewards (column gap10 centered): row = 26px gradient chip + Nunito 800 15px `rgba(255,255,255,.85)` + colored value:
  - XP — violet chip `#C8A6FF→#8A5BFF→#5A2FC2` bolt; "XP +33" value `#C8A6FF`
  - Level up — yellow chip `#FFF3B0→#FFD93D→#C79600` (glyph `#7A5300`) star; "Level up! Lv 2" value `#FFCE4D` (only on level-up)
- PLAY AGAIN: full-width 54px radius18, orange gradient+shadow, Baloo 2 800 20px ls1 `#4A2400`, replay-arrow icon (`mt20`)
- Home link: Nunito 700 13.5px `rgba(255,255,255,.5)` hover .8 (`mt15`)

XP/level from real reward calc; score/best from run.

**Nav:** ×→pause/Home · PLAY AGAIN→new round (via Get Ready) · Keep Going→continue/ad/end · Round Over Home→Home.

---

Screens 06 Profile / 07 Pick Avatar / 08 Edit Name are in the handoff **HTML only** (`Bubble Splash Home.dc.html`); implementation notes in `docs/CANDY_COSMOS_MIGRATION.md` Phase 7. Icons in the mock are throwaway inline SVGs (replace with own set); all bubbles/glows are pure CSS gradients — no image assets.
