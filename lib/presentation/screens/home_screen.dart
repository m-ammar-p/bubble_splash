import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/free_life_controller.dart';
import '../../application/lives_controller.dart';
import '../../application/profile_controller.dart';
import '../../application/providers.dart';
import '../../domain/models/lives_state.dart';
import '../../app/candy.dart';
import '../../app/routes.dart';

/// Home / Main Menu — "Candy Cosmos" theme, rebuilt to the design handoff
/// (`docs/design/candy_cosmos_handoff.md`). Deep cosmic-violet stage with pink +
/// orange nebula glows, four glossy floating bubbles, a glowing Baloo 2 title,
/// and a warm orange PLAY. All spec px values are from the 322×690 reference
/// frame and scaled proportionally via [candyScale].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _play(BuildContext context) => Navigator.of(context).pushNamed(Routes.game);

  Future<void> _claimFreeLife(BuildContext context, WidgetRef ref) async {
    final earned = await ref.read(rewardedAdServiceProvider).showRewardedAd();
    if (!earned) return;
    final ok = ref.read(freeLifeControllerProvider.notifier).claim();
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free life claimed! +1 life')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(freeLifeControllerProvider);
    final lives = ref.watch(livesControllerProvider);
    ref.watch(livesTickerProvider);
    final freeLife = ref.read(freeLifeControllerProvider.notifier);
    final canClaimFreeLife =
        freeLife.canClaim && lives.count < LivesState.maxLives;
    final freeLifeUntil = freeLife.untilClaimable();

    final s = candyScale(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 15 * s, 16 * s, 20 * s),
              child: Column(
                children: [
                  const _HeaderStats(),
                  SizedBox(height: 10 * s),
                  const _BubbleCluster(),
                  SizedBox(height: 14 * s),
                  const _Title(),
                  SizedBox(height: 12 * s),
                  Text(
                    'Pop the bubbles. Beat your best.',
                    textAlign: TextAlign.center,
                    style: Candy.ui(
                      color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                      size: 15 * s,
                    ),
                  ),
                  const Spacer(),
                  _FreeLifeCard(
                    canClaim: canClaimFreeLife,
                    livesFull: lives.count >= LivesState.maxLives,
                    until: freeLifeUntil,
                    onClaim: () => _claimFreeLife(context, ref),
                  ),
                  SizedBox(height: 14 * s),
                  _PlayButton(onPressed: () => _play(context)),
                  SizedBox(height: 18 * s),
                  const _BottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header: [Coins][Level] on the left, [Lives] on the right.
class _HeaderStats extends ConsumerWidget {
  const _HeaderStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.coins));
    final level = ref.watch(profileControllerProvider.select((p) => p.level));
    final count = ref.watch(livesControllerProvider.select((s) => s.count));
    final s = candyScale(context);

    return Row(
      children: [
        CandyStatPill(
          chipColors: Candy.coinsChip,
          glyph: Text('\$',
              style: GoogleFonts.nunito(
                  color: const Color(0xFF7A4D00),
                  fontSize: 14 * s,
                  fontWeight: FontWeight.w900)),
          label: '$coins',
        ),
        SizedBox(width: 8 * s),
        CandyStatPill(
          chipColors: Candy.levelChip,
          glyph: Icon(Icons.bolt, color: Colors.white, size: 16 * s),
          label: 'Lv $level',
        ),
        const Spacer(),
        CandyStatPill(
          chipColors: Candy.livesChip,
          glyph: Icon(Icons.favorite, color: Colors.white, size: 14 * s),
          // Always against the absolute bank cap, matching the Shop's
          // "N/100 banked" counter — one max everywhere, no 10-vs-100 confusion.
          label: '$count/${LivesState.maxLives}',
        ),
      ],
    );
  }
}

/// Four glossy bubbles floating in a 184px-tall zone, each bobbing on its own
/// duration so the cluster never visibly repeats.
class _BubbleCluster extends StatelessWidget {
  const _BubbleCluster();

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return SizedBox(
      height: 184 * s,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Orange main (center) — 132px @ (87,26), ±10px / 5.6s.
          Positioned(
            left: 87 * s,
            top: 26 * s,
            child: _FloatBubble(
              size: 132 * s,
              travel: -10 * s,
              durationMs: 5600,
              light: Candy.orangeLight,
              mid: Candy.orange,
              dark: Candy.orangeDark,
              glow: Candy.orange.withValues(alpha: 0.55),
            ),
          ),
          // Pink (left) — 78px @ (10,70), +9px / 4.6s.
          Positioned(
            left: 10 * s,
            top: 70 * s,
            child: _FloatBubble(
              size: 78 * s,
              travel: 9 * s,
              durationMs: 4600,
              light: Candy.pinkLight,
              mid: Candy.pink,
              dark: Candy.pinkDark,
              glow: Candy.pink.withValues(alpha: 0.50),
            ),
          ),
          // Mint (right) — 66px @ (right 8, top 86), −6px / 5.2s.
          Positioned(
            right: 8 * s,
            top: 86 * s,
            child: _FloatBubble(
              size: 66 * s,
              travel: -6 * s,
              durationMs: 5200,
              light: Candy.mintLight,
              mid: Candy.mint,
              dark: Candy.mintDark,
              glow: Candy.mint.withValues(alpha: 0.50),
            ),
          ),
          // Yellow (small) — 46px @ (152,150), +7px / 4.2s.
          Positioned(
            left: 152 * s,
            top: 150 * s,
            child: _FloatBubble(
              size: 46 * s,
              travel: 7 * s,
              durationMs: 4200,
              light: Candy.yellowLight,
              mid: Candy.yellow,
              dark: Candy.yellowDark,
              glow: Candy.yellow.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

/// A glossy bubble that bobs vertically forever (ping-pong, ease-in-out) to
/// [travel] at the midpoint of [durationMs].
class _FloatBubble extends StatefulWidget {
  const _FloatBubble({
    required this.size,
    required this.travel,
    required this.durationMs,
    required this.light,
    required this.mid,
    required this.dark,
    required this.glow,
  });

  final double size;
  final double travel;
  final int durationMs;
  final Color light;
  final Color mid;
  final Color dark;
  final Color glow;

  @override
  State<_FloatBubble> createState() => _FloatBubbleState();
}

class _FloatBubbleState extends State<_FloatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);
    _y = Tween(begin: 0.0, end: widget.travel).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _y,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _y.value), child: child),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // radial-gradient(circle at 34% 26%, #FFF, light 20%, mid 54%, dark)
          gradient: RadialGradient(
            center: const Alignment(-0.32, -0.48),
            radius: 1.0,
            colors: [Colors.white, widget.light, widget.mid, widget.dark],
            stops: const [0.0, 0.20, 0.54, 1.0],
          ),
          boxShadow: [
            // Outer accent glow.
            BoxShadow(
                color: widget.glow,
                blurRadius: widget.size * 0.30,
                spreadRadius: -widget.size * 0.05,
                offset: Offset(0, widget.size * 0.08)),
            // inset 5px 5px 12px rgba(255,255,255,.42) — soft top-left sheen.
            BoxShadow(
                color: Colors.white.withValues(alpha: 0.20),
                blurRadius: 6,
                spreadRadius: -2,
                offset: const Offset(-3, -3)),
          ],
        ),
      ),
    );
  }
}

/// Title: "BUBBLE / SPLASH", Baloo 2 800, warm cream with an orange/pink glow
/// and a subtle dark bottom bevel.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Text(
      'BUBBLE\nSPLASH',
      textAlign: TextAlign.center,
      style: Candy.display(
        size: 46 * s,
        height: 0.9,
        letterSpacing: 1 * s,
        shadows: [
          Shadow(
              color: Candy.orange.withValues(alpha: 0.55), blurRadius: 22 * s),
          Shadow(
              color: Candy.pink.withValues(alpha: 0.30), blurRadius: 46 * s),
          Shadow(
              color: const Color(0xFF782800).withValues(alpha: 0.40),
              offset: Offset(0, 3 * s)),
        ],
      ),
    );
  }
}

/// Free-life card: glass row, heart chip + "Free life in MM:SS".
class _FreeLifeCard extends StatelessWidget {
  const _FreeLifeCard({
    required this.canClaim,
    required this.livesFull,
    required this.until,
    required this.onClaim,
  });

  final bool canClaim;
  final bool livesFull;
  final Duration until;
  final VoidCallback onClaim;

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);

    final Widget text;
    if (livesFull) {
      text = Text('Lives full (${LivesState.maxLives})',
          style: Candy.ui(size: 15 * s, weight: FontWeight.w800));
    } else if (canClaim) {
      text = Text('Watch ad for a free life',
          style: Candy.ui(size: 15 * s, weight: FontWeight.w800));
    } else {
      text = Text.rich(
        TextSpan(
          style: Candy.ui(size: 15 * s, weight: FontWeight.w800),
          children: [
            const TextSpan(text: 'Free life in '),
            TextSpan(
                text: _fmt(until), style: const TextStyle(color: Candy.timer)),
          ],
        ),
      );
    }

    return CandyGlass(
      onTap: canClaim ? onClaim : null,
      radius: 18 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
      child: Row(
        children: [
          Container(
            width: 38 * s,
            height: 38 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Candy.heart.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.favorite,
                color: const Color(0xFFFF7D90), size: 20 * s),
          ),
          SizedBox(width: 13 * s),
          Expanded(child: text),
          if (canClaim)
            const Icon(Icons.chevron_right_rounded, color: Candy.timer),
        ],
      ),
    );
  }
}

/// Full-width PLAY button: warm orange gradient, lifts + glows on press.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyCtaButton(
      onPressed: onPressed,
      height: 60,
      radius: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow_rounded, color: Candy.ctaInk, size: 30 * s),
          SizedBox(width: 8 * s),
          Text(
            'PLAY',
            style: Candy.display(
              color: Candy.ctaInk,
              size: 26 * s,
              letterSpacing: 3 * s,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom nav: Profile · Ranks · Shop — 50px glass tiles with colored icons.
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            tint: Color(0xFFB48BFF),
            route: Routes.profile),
        _NavItem(
            icon: Icons.leaderboard_rounded,
            label: 'Ranks',
            tint: Color(0xFFFFCE4D),
            route: Routes.leaderboard),
        _NavItem(
            icon: Icons.storefront_rounded,
            label: 'Shop',
            tint: Color(0xFFFF7D90),
            route: Routes.shop),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.tint,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final String route;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CandyGlass(
          onTap: () => Navigator.of(context).pushNamed(route),
          radius: 16 * s,
          surfaceAlpha: 0.08,
          borderAlpha: 0.14,
          width: 50 * s,
          height: 50 * s,
          alignment: Alignment.center,
          child: Icon(icon, color: tint, size: 26 * s),
        ),
        SizedBox(height: 7 * s),
        Text(
          label,
          style: Candy.ui(
            color: Colors.white.withValues(alpha: 0.65),
            size: 12.5 * s,
          ),
        ),
      ],
    );
  }
}
