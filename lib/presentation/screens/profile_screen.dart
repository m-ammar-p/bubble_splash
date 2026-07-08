import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../app/routes.dart';
import '../../application/auth_controller.dart';
import '../../application/profile_controller.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/player_profile.dart';
import '../widgets/auth_panel.dart';
import '../widgets/player_avatar.dart';

/// Maps an achievement's domain [Achievement.iconKey] to a Material icon.
const Map<String, IconData> _achievementIcons = {
  'play': Icons.play_arrow_rounded,
  'star': Icons.star_rounded,
  'bubble': Icons.bubble_chart,
  'level': Icons.military_tech,
  'calendar': Icons.calendar_month,
  'palette': Icons.palette,
};

/// The avatar color swatches (spec screen 07). Each stores the mid color on
/// the profile; gloss shades come from [candyBubbleShades] in candy.dart.
const _swatchColors = [
  0xFF3DB6FF, // blue
  0xFF8A5BFF, // violet
  0xFFFF9D3D, // orange
  0xFF4BE0A5, // mint
  0xFFFFD93D, // yellow
  0xFFFF6B8B, // pink
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final s = candyScale(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 0),
              child: Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(top: 10 * s, bottom: 20 * s),
                      children: [
                        _AvatarBlock(profile: profile),
                        SizedBox(height: 12 * s),
                        _XpCard(profile: profile),
                        SizedBox(height: 13 * s),
                        const CandySectionLabel('STATS'),
                        SizedBox(height: 8 * s),
                        _StatsGrid(profile: profile),
                        SizedBox(height: 13 * s),
                        const CandySectionLabel('ACHIEVEMENTS'),
                        SizedBox(height: 8 * s),
                        for (final a in kAchievements)
                          Padding(
                            padding: EdgeInsets.only(bottom: 8 * s),
                            child: _AchievementRow(
                              achievement: a,
                              unlocked: profile.unlockedAchievementIds
                                  .contains(a.id),
                            ),
                          ),
                        SizedBox(height: 5 * s),
                        const CandySectionLabel('ACCOUNT'),
                        SizedBox(height: 8 * s),
                        const _AccountCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass back circle · "Profile" title · width-matched spacer.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CandyBackCircle(),
        Text('Profile', style: Candy.display(size: 20 * s)),
        SizedBox(width: kCandyBackCircleSize * s),
      ],
    );
  }
}

/// 90px glossy bubble avatar (player's color) with the orange pencil badge
/// (→ avatar picker) and the tappable name (→ rename dialog).
class _AvatarBlock extends ConsumerWidget {
  const _AvatarBlock({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = candyScale(context);
    final mid = Color(profile.avatarColor);
    return Column(
      children: [
        GestureDetector(
          onTap: () => showAvatarPicker(context, ref),
          child: SizedBox(
            width: 96 * s,
            height: 94 * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 90 * s,
                  height: 90 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: candyBubbleGradient(profile.avatarColor),
                    boxShadow: [
                      // 0 12px 30px <color .5>
                      BoxShadow(
                          color: mid.withValues(alpha: 0.5),
                          blurRadius: 30 * s,
                          offset: Offset(0, 12 * s)),
                      // inset 5px 5px 12px rgba(255,255,255,.45) — soft sheen.
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.20),
                          blurRadius: 6 * s,
                          spreadRadius: -2 * s,
                          offset: Offset(-3 * s, -3 * s)),
                    ],
                  ),
                  child: Icon(avatarIconFor(profile.avatarEmoji),
                      size: 40 * s, color: Colors.white),
                ),
                // Orange pencil badge, bottom-right, ringed in the bg violet.
                Positioned(
                  right: 3 * s,
                  bottom: 1 * s,
                  child: Container(
                    width: 30 * s,
                    height: 30 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Candy.orangeCtaTop, Candy.orangeCtaBottom],
                      ),
                      border: Border.all(color: Candy.bgMid, width: 2.5 * s),
                    ),
                    child:
                        Icon(Icons.edit, size: 13 * s, color: Candy.ctaInk),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 9 * s),
        GestureDetector(
          onTap: () => _editName(context, ref),
          child: Text(
            profile.name,
            style: Candy.display(size: 23 * s, color: Colors.white, height: 1),
          ),
        ),
      ],
    );
  }

  /// Custom names are an account perk: guests get the sign-in prompt instead
  /// of the name dialog, and land straight in it after signing in.
  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    if (!ref.read(authControllerProvider).isSignedIn) {
      final signedIn = await showSignInPrompt(
        context,
        title: 'Sign in to set your name',
        body: 'Guests play as ${ref.read(profileControllerProvider).name}. '
            'Create an account to pick your own name and keep your progress.',
      );
      if (!signedIn || !context.mounted) return;
    }
    await showNameDialog(context, ref);
  }
}

/// Glass card: "Level N" + "X / Y XP" + orange gradient progress bar w/ glow.
class _XpCard extends StatelessWidget {
  const _XpCard({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 18 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.fromLTRB(14 * s, 11 * s, 14 * s, 13 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Level ${profile.level}',
                  style: Candy.display(size: 15 * s, color: Colors.white)),
              Text('${profile.xpIntoLevel} / ${profile.xpForLevelSpan} XP',
                  style: Candy.ui(
                      size: 12 * s,
                      weight: FontWeight.w800,
                      color: const Color(0x99FFE1D2))),
            ],
          ),
          SizedBox(height: 8 * s),
          // Track (empty area) with the orange fill left-aligned on top. The
          // fill fills the full 10px height (heightFactor:1) and its glow is
          // intentionally not clipped, matching the spec's box-shadow.
          Container(
            height: 10 * s,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: profile.levelProgress.clamp(0.0, 1.0),
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [
                      Candy.orangeCtaTop,
                      Candy.orangeCtaBottom,
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Candy.orangeCtaBottom.withValues(alpha: 0.7),
                          blurRadius: 12 * s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2×2 stat cards: 32px gradient chip + Baloo value + Nunito label.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    Widget row(Widget a, Widget b) => Row(children: [
          Expanded(child: a),
          SizedBox(width: 8 * s),
          Expanded(child: b),
        ]);
    return Column(
      children: [
        row(
          _StatCard(
              chip: Candy.yellowChip,
              icon: Icons.star_rounded,
              iconColor: const Color(0xFF7A5300),
              value: '${profile.highScore}',
              label: 'High Score'),
          _StatCard(
              chip: Candy.levelChip,
              icon: Icons.sports_esports,
              iconColor: Colors.white,
              value: '${profile.gamesPlayed}',
              label: 'Games'),
        ),
        SizedBox(height: 8 * s),
        row(
          _StatCard(
              chip: Candy.pinkChip,
              icon: Icons.bubble_chart,
              iconColor: Colors.white,
              value: '${profile.totalBubblesPopped}',
              label: 'Bubbles'),
          _StatCard(
              chip: Candy.mintChip,
              icon: Icons.bolt,
              iconColor: Colors.white,
              value: '${profile.level}',
              label: 'Level'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.chip,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final List<Color> chip;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 16 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.symmetric(horizontal: 11 * s, vertical: 10 * s),
      child: Row(
        children: [
          CandyChip(
            colors: chip,
            size: 32 * s,
            child: Icon(icon, size: 16 * s, color: iconColor),
          ),
          SizedBox(width: 9 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: Candy.display(
                          size: 19 * s, color: Colors.white, height: 1)),
                ),
                SizedBox(height: 1 * s),
                Text(label,
                    style: Candy.ui(
                        size: 11 * s,
                        color: Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievement row: amber-tinted with orange chip + gold check when unlocked,
/// dim glass with a lock chip when locked.
class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.unlocked});
  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0x1FFFC24D) // rgba(255,194,77,.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: unlocked
              ? const Color(0x80FFC24D) // rgba(255,194,77,.5)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                    color: Candy.orange.withValues(alpha: 0.15),
                    blurRadius: 16 * s),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (unlocked)
            CandyChip(
              colors: Candy.orangeChip,
              size: 34 * s,
              child: Icon(
                  _achievementIcons[achievement.iconKey] ?? Icons.emoji_events,
                  size: 17 * s,
                  color: Candy.ctaInk),
            )
          else
            Container(
              width: 34 * s,
              height: 34 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: Icon(Icons.lock,
                  size: 15 * s, color: Colors.white.withValues(alpha: 0.5)),
            ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: Candy.ui(
                        size: 14 * s,
                        weight: FontWeight.w800,
                        color: unlocked
                            ? Candy.titleText
                            : Colors.white.withValues(alpha: 0.75))),
                SizedBox(height: 1 * s),
                Text(achievement.description,
                    style: Candy.ui(
                        size: 11.5 * s,
                        color: unlocked
                            ? const Color(0x99FFE1D2)
                            : Colors.white.withValues(alpha: 0.42))),
              ],
            ),
          ),
          if (unlocked) ...[
            SizedBox(width: 10 * s),
            Container(
              width: 22 * s,
              height: 22 * s,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Candy.orangeCtaTop, Candy.orangeCtaBottom],
                ),
              ),
              child: Icon(Icons.check, size: 14 * s, color: Candy.ctaInk),
            ),
          ],
        ],
      ),
    );
  }
}

/// ACCOUNT card: signed-in shows the account identity + Sign out; guest shows
/// a "Sign in" action (progression then follows that account — guest progress
/// stays in the guest slot).
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final ok = await showSignInPrompt(
      context,
      title: 'Sign in',
      body: 'Keep your levels, records and coins on your account — '
          'across every device.',
    );
    if (!ok || !context.mounted) return;
    final account = ref.read(authControllerProvider).account;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed in as ${account?.email}')),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCandyConfirmDialog(
      context,
      chipColors: Candy.levelChip,
      icon: Icons.logout,
      title: 'Sign out?',
      body: 'Your progress stays saved to this account. '
          'You can sign back in anytime.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = candyScale(context);
    final auth = ref.watch(authControllerProvider);
    final account = auth.account;

    return CandyGlass(
      radius: 16 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 11 * s),
      child: Row(
        children: [
          // Gradient chip with a person glyph (drawn icon — no emoji tofu).
          CandyChip(
            colors: account == null ? Candy.mintChip : Candy.levelChip,
            size: 34 * s,
            child: Icon(
              account == null
                  ? Icons.person_outline_rounded
                  : Icons.person_rounded,
              size: 19 * s,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account?.displayName ?? 'Guest player',
                  style: Candy.ui(size: 14 * s, weight: FontWeight.w800),
                ),
                SizedBox(height: 1 * s),
                Text(
                  account?.email ?? 'Progress is saved on this device only',
                  style: Candy.ui(
                      size: 11.5 * s,
                      color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          CandyGlass(
            padding:
                EdgeInsets.symmetric(horizontal: 13 * s, vertical: 8 * s),
            surfaceAlpha: 0.12,
            borderAlpha: 0.20,
            onTap: () => account == null
                ? _signIn(context, ref)
                : _signOut(context, ref),
            child: Text(
              account == null ? 'Sign in' : 'Sign out',
              style: Candy.ui(
                  size: 12.5 * s,
                  weight: FontWeight.w800,
                  color: account == null
                      ? Candy.orangeLight
                      : Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 07 — Pick an avatar (dialog)
// ---------------------------------------------------------------------------

Future<void> showAvatarPicker(BuildContext context, WidgetRef ref) {
  final profile = ref.read(profileControllerProvider);
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x990A0514), // rgba(10,5,20,.6)
    builder: (_) => _AvatarPickerDialog(
      initialKey: profile.avatarEmoji,
      initialColor: profile.avatarColor,
      onDone: (key, color) => ref
          .read(profileControllerProvider.notifier)
          .setAvatar(emoji: key, color: color),
    ),
  );
}

class _AvatarPickerDialog extends StatefulWidget {
  const _AvatarPickerDialog({
    required this.initialKey,
    required this.initialColor,
    required this.onDone,
  });

  final String initialKey;
  final int initialColor;
  final void Function(String key, int color) onDone;

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  late String _key = widget.initialKey;
  late int _color = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 18 * s),
      child: _DialogSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick an avatar', style: Candy.display(size: 22 * s)),
            SizedBox(height: 14 * s),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisExtent: 46 * s,
                crossAxisSpacing: 8 * s,
                mainAxisSpacing: 8 * s,
              ),
              children: [
                for (final key in kAvatarKeys)
                  _AvatarTile(
                    icon: avatarIconFor(key),
                    color: _color,
                    selected: key == _key,
                    onTap: () => setState(() => _key = key),
                  ),
              ],
            ),
            SizedBox(height: 16 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in _swatchColors)
                  _ColorSwatch(
                    color: c,
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
              ],
            ),
            SizedBox(height: 18 * s),
            CandyCtaButton(
              height: 48,
              radius: 16,
              onPressed: () {
                widget.onDone(_key, _color);
                Navigator.pop(context);
              },
              child: Text('Done',
                  style: Candy.display(
                      size: 18 * s, color: Candy.ctaInk, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 46px icon tile: glass when unselected; glossy colored bubble + white border
/// + glow when selected.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14 * s),
                gradient: candyBubbleGradient(color),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5 * s),
                boxShadow: [
                  BoxShadow(
                      color: Color(color).withValues(alpha: 0.5),
                      blurRadius: 16 * s,
                      offset: Offset(0, 6 * s)),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(14 * s),
                color: Candy.glass(0.08),
                border: Border.all(color: Candy.glassBorder(0.14)),
              ),
        child: Icon(icon,
            size: (selected ? 21 : 20) * s,
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}

/// 34px glossy color swatch; selected gets a white ring + glow.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34 * s,
        height: 34 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: candyBubbleGradient(color),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      spreadRadius: 2.5 * s),
                  BoxShadow(
                      color: Color(color).withValues(alpha: 0.6),
                      blurRadius: 14 * s,
                      spreadRadius: 2 * s),
                ]
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 08 — Your name (dialog, native keyboard)
// ---------------------------------------------------------------------------

Future<void> showNameDialog(BuildContext context, WidgetRef ref) {
  final profile = ref.read(profileControllerProvider);
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x990A0514),
    builder: (_) => _NameDialog(
      initialName: profile.name,
      onSave: (name) =>
          ref.read(profileControllerProvider.notifier).rename(name),
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initialName, required this.onSave});

  final String initialName;
  final void Function(String name) onSave;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  static const _maxLength = 16;
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      // Upper-middle so the system keyboard never covers the dialog.
      alignment: const Alignment(0, -0.5),
      insetPadding: EdgeInsets.symmetric(horizontal: 24 * s),
      child: _DialogSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your name', style: Candy.display(size: 22 * s)),
            SizedBox(height: 14 * s),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: Candy.glass(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14 * s),
                  topRight: Radius.circular(14 * s),
                  bottomLeft: Radius.circular(6 * s),
                  bottomRight: Radius.circular(6 * s),
                ),
                border: Border.all(color: Candy.glassBorder(0.16)),
              ),
              // Orange focus underline (2.5px solid #FF9D3D).
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Candy.orange, width: 2.5),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: _maxLength,
                  cursorColor: Candy.orangeCtaTop,
                  cursorWidth: 2 * s,
                  style: Candy.ui(size: 16 * s, weight: FontWeight.w800),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_controller.text.length}/$_maxLength',
                  style: Candy.ui(
                      size: 11 * s,
                      color: Colors.white.withValues(alpha: 0.45))),
            ),
            SizedBox(height: 12 * s),
            CandyCtaButton(
              height: 46,
              radius: 16,
              onPressed: _save,
              child: Text('Save',
                  style: Candy.display(
                      size: 18 * s, color: Candy.ctaInk, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(_controller.text);
    Navigator.pop(context);
  }
}

/// The violet dialog surface shared by screens 07/08 — like [CandySheet] but
/// with the dialog-strength gradient (`.96 → .98`).
class _DialogSheet extends StatelessWidget {
  const _DialogSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Container(
      padding: EdgeInsets.fromLTRB(18 * s, 20 * s, 18 * s, 18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF548266E), Color(0xFA22103C)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 60 * s,
              offset: Offset(0, 24 * s)),
        ],
      ),
      child: child,
    );
  }
}
