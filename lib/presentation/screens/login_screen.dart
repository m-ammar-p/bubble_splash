import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../app/routes.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_panel.dart';

/// First-launch gate: create an account / sign in (progress saves to that
/// account, across devices) or "Play as Guest" (device-local progress). Shown
/// while [AuthState.decided] is false; every choice lands on Home.
///
/// Candy Cosmos throughout — the glowing [CandyGameTitle] hero over the email
/// [AuthPanel], matching the rest of the game.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  void _continueAsGuest() {
    ref.read(authControllerProvider.notifier).continueAsGuest();
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * s, 8 * s, 24 * s, 24 * s),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 12 * s),
                      const CandyGameTitle(size: 40),
                      SizedBox(height: 12 * s),
                      Text(
                        'Pop the bubbles. Beat your best.',
                        textAlign: TextAlign.center,
                        style: Candy.ui(
                          color:
                              const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                          size: 14 * s,
                        ),
                      ),
                      SizedBox(height: 26 * s),
                      AuthPanel(onAuthenticated: _goHome),
                      SizedBox(height: 20 * s),
                      _OrDivider(),
                      SizedBox(height: 16 * s),
                      _GuestButton(onPressed: _continueAsGuest),
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

/// "— or —" hairline divider between the account form and the guest option.
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final line = Expanded(
      child: Container(
          height: 1, color: Colors.white.withValues(alpha: 0.12)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          child: Text('or',
              style: Candy.ui(
                  size: 12.5 * s,
                  color: Colors.white.withValues(alpha: 0.45))),
        ),
        line,
      ],
    );
  }
}

/// "Play as Guest" glass row: mint gradient chip, bold label + subline, chevron.
class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      onTap: onPressed,
      radius: 18 * s,
      surfaceAlpha: 0.10,
      borderAlpha: 0.18,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      child: Row(
        children: [
          CandyChip(
            colors: Candy.mintChip,
            size: 38 * s,
            child: Icon(Icons.sports_esports_rounded,
                color: Colors.white, size: 20 * s),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Play as Guest',
                    style: Candy.ui(size: 15.5 * s, weight: FontWeight.w800)),
                SizedBox(height: 1 * s),
                Text(
                  'Progress stays on this device',
                  style: Candy.ui(
                    size: 11.5 * s,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Candy.timer, size: 24 * s),
        ],
      ),
    );
  }
}
