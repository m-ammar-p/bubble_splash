import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../app/routes.dart';
import '../../application/auth_controller.dart';
import '../widgets/google_sign_in_button.dart';

/// First-launch gate: pick "Continue with Google" (progression saves to that
/// account) or "Play as Guest" (device-local progress). Shown while
/// [AuthState.decided] is false; both choices land on Home.
///
/// Mirrors the Home hero — same [CandyBubbleCluster] logo and glowing
/// [CandyGameTitle] — so the first screen a player sees is already the game.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Sign-in cancelled — you can also play as a guest.')),
      );
    }
  }

  void _continueAsGuest() {
    ref.read(authControllerProvider.notifier).continueAsGuest();
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20 * s, 15 * s, 20 * s, 24 * s),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Same hero as Home: floating bubble-cluster logo + glowing
                  // BUBBLE / SPLASH title.
                  const CandyBubbleCluster(),
                  SizedBox(height: 14 * s),
                  const CandyGameTitle(),
                  SizedBox(height: 12 * s),
                  Text(
                    'Pop the bubbles. Beat your best.',
                    textAlign: TextAlign.center,
                    style: Candy.ui(
                      color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                      size: 15 * s,
                    ),
                  ),
                  const Spacer(flex: 3),
                  GoogleSignInButton(
                      onPressed: _busy ? null : _signInWithGoogle),
                  SizedBox(height: 10 * s),
                  Text(
                    'Your levels & records save to your account',
                    style: Candy.ui(
                      size: 11.5 * s,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  _GuestButton(onPressed: _busy ? null : _continueAsGuest),
                ],
              ),
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x550A0514),
                child: Center(
                  child: CircularProgressIndicator(color: Candy.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Play as Guest" glass row styled like Home's Free Life card: mint gradient
/// chip with a controller icon, bold label + subline, chevron affordance.
class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: CandyGlass(
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
            Icon(Icons.chevron_right_rounded,
                color: Candy.timer, size: 24 * s),
          ],
        ),
      ),
    );
  }
}

