import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../app/routes.dart';
import '../../application/auth_controller.dart';

/// First-launch gate: pick "Continue with Google" (progression saves to that
/// account) or "Play as Guest" (device-local progress). Shown while
/// [AuthState.decided] is false; both choices land on Home.
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
        const SnackBar(content: Text('Sign-in cancelled — you can also play as a guest.')),
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
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Glossy candy-bubble logo, same recipe as the avatars.
                  Container(
                    width: 96 * s,
                    height: 96 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: candyBubbleGradient(0xFF3DB6FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3DB6FF).withValues(alpha: 0.5),
                          blurRadius: 30 * s,
                          offset: Offset(0, 12 * s),
                        ),
                      ],
                    ),
                    child: Icon(Icons.bubble_chart,
                        size: 44 * s, color: Colors.white),
                  ),
                  SizedBox(height: 18 * s),
                  Text('Bubble Splash',
                      style: Candy.display(size: 32 * s, height: 1)),
                  SizedBox(height: 8 * s),
                  Text(
                    'Pop bubbles, level up, climb the ranks',
                    textAlign: TextAlign.center,
                    style: Candy.ui(
                      size: 14 * s,
                      color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                    ),
                  ),
                  const Spacer(flex: 4),
                  _GoogleButton(onPressed: _busy ? null : _signInWithGoogle),
                  SizedBox(height: 8 * s),
                  Text(
                    'Your levels & records save to your account',
                    style: Candy.ui(
                      size: 11.5 * s,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  CandyGlass(
                    radius: 18 * s,
                    height: 50 * s,
                    alignment: Alignment.center,
                    onTap: _busy ? null : _continueAsGuest,
                    child: Text(
                      'Play as Guest',
                      style: Candy.ui(
                          size: 15.5 * s,
                          weight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                  SizedBox(height: 28 * s),
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

/// White "Continue with Google" pill per Google's sign-in branding (white
/// surface, multicolor G, dark label) — deliberately not Candy-orange so it
/// reads as Google.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 54 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24 * s,
                offset: Offset(0, 10 * s),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GoogleG(size: 22 * s),
              SizedBox(width: 10 * s),
              Text(
                'Continue with Google',
                style: Candy.ui(
                    size: 15.5 * s,
                    weight: FontWeight.w800,
                    color: const Color(0xFF1F1F1F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A drawn multicolor "G" (no asset, no emoji — same tofu-safety rule as
/// avatars/bombs).
class _GoogleG extends StatelessWidget {
  const _GoogleG({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.20;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const deg = 3.14159265 / 180.0;
    // Four brand-colored arcs approximating the G ring.
    paint.color = const Color(0xFF4285F4); // blue: right side
    canvas.drawArc(rect, -45 * deg, 75 * deg, false, paint);
    paint.color = const Color(0xFF34A853); // green: bottom
    canvas.drawArc(rect, 45 * deg, 100 * deg, false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow: bottom-left
    canvas.drawArc(rect, 145 * deg, 65 * deg, false, paint);
    paint.color = const Color(0xFFEA4335); // red: top
    canvas.drawArc(rect, 210 * deg, 105 * deg, false, paint);

    // The G's horizontal bar.
    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(size.width / 2 + stroke * 0.2, size.height / 2),
      Offset(size.width - stroke / 2, size.height / 2),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
