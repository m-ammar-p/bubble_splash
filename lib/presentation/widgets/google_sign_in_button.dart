import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../application/auth_controller.dart';

/// White "Continue with Google" pill per Google's sign-in branding (white
/// surface, multicolor G, dark label) — deliberately not Candy-orange so it
/// reads as Google. Presses down like [CandyCtaButton]. Shared by the Login
/// screen and the sign-in prompt dialog.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final enabled = widget.onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _down ? -2 * s : 0, 0),
          height: 54 * s,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _down ? 0.45 : 0.35),
                blurRadius: (_down ? 30 : 24) * s,
                offset: Offset(0, (_down ? 14 : 10) * s),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoogleG(size: 22 * s),
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

/// The official multicolor Google "G", drawn from the brand's exact vector
/// paths (24×24 grid) — no asset, no emoji (same tofu-safety rule as
/// avatars/bombs).
class GoogleG extends StatelessWidget {
  const GoogleG({super.key, required this.size});
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
    canvas.scale(size.width / 24.0, size.height / 24.0);
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue: the right side + horizontal bar.
    paint.color = const Color(0xFF4285F4);
    final blue = Path()
      ..moveTo(22.56, 12.25)
      ..relativeCubicTo(0, -0.78, -0.07, -1.53, -0.2, -2.25)
      ..lineTo(12, 10)
      ..relativeLineTo(0, 4.26)
      ..relativeLineTo(5.92, 0)
      ..relativeCubicTo(-0.26, 1.37, -1.04, 2.53, -2.21, 3.31)
      ..relativeLineTo(0, 2.77)
      ..relativeLineTo(3.57, 0)
      ..relativeCubicTo(2.08, -1.92, 3.28, -4.74, 3.28, -8.09)
      ..close();
    canvas.drawPath(blue, paint);

    // Green: the bottom arc.
    paint.color = const Color(0xFF34A853);
    final green = Path()
      ..moveTo(12, 23)
      ..relativeCubicTo(2.97, 0, 5.46, -0.98, 7.28, -2.66)
      ..relativeLineTo(-3.57, -2.77)
      ..relativeCubicTo(-0.98, 0.66, -2.23, 1.06, -3.71, 1.06)
      ..relativeCubicTo(-2.86, 0, -5.29, -1.93, -6.16, -4.53)
      ..lineTo(2.18, 14.1)
      ..relativeLineTo(0, 2.84)
      ..cubicTo(3.99, 20.53, 7.7, 23, 12, 23)
      ..close();
    canvas.drawPath(green, paint);

    // Yellow: the left arc.
    paint.color = const Color(0xFFFBBC05);
    final yellow = Path()
      ..moveTo(5.84, 14.09)
      ..relativeCubicTo(-0.22, -0.66, -0.35, -1.36, -0.35, -2.09)
      ..relativeCubicTo(0, -0.73, 0.13, -1.43, 0.35, -2.09)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
      ..relativeCubicTo(0, 1.78, 0.43, 3.45, 1.18, 4.93)
      ..relativeLineTo(2.85, -2.22)
      ..relativeLineTo(0.81, -0.62)
      ..close();
    canvas.drawPath(yellow, paint);

    // Red: the top arc.
    paint.color = const Color(0xFFEA4335);
    final red = Path()
      ..moveTo(12, 5.38)
      ..relativeCubicTo(1.62, 0, 3.06, 0.56, 4.21, 1.64)
      ..relativeLineTo(3.15, -3.15)
      ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
      ..cubicTo(7.7, 1, 3.99, 3.47, 2.18, 7.07)
      ..relativeLineTo(3.66, 2.84)
      ..relativeCubicTo(0.87, -2.6, 3.3, -4.53, 6.16, -4.53)
      ..close();
    canvas.drawPath(red, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Candy-styled "sign in first" prompt: white G badge, Baloo title, a short
/// pitch for WHY an account is needed, the Google button, and a "Not now"
/// escape. Returns true only after a successful sign-in.
///
/// UX rules: shown at the moment of intent (e.g. a guest taps a coin pack),
/// never as a nag; warm/positive framing (an upsell, not an error); "Not now"
/// always available so guests never feel locked in.
Future<bool> showGoogleSignInDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final signedIn = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF0A0514).withValues(alpha: 0.55),
    builder: (ctx) {
      final s = candyScale(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28 * s),
        child: CandySheet(
          padding: EdgeInsets.fromLTRB(20 * s, 24 * s, 20 * s, 18 * s),
          child: _SignInDialogBody(title: title, body: body),
        ),
      );
    },
  );
  return signedIn ?? false;
}

class _SignInDialogBody extends ConsumerStatefulWidget {
  const _SignInDialogBody({required this.title, required this.body});
  final String title;
  final String body;

  @override
  ConsumerState<_SignInDialogBody> createState() => _SignInDialogBodyState();
}

class _SignInDialogBodyState extends ConsumerState<_SignInDialogBody> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
    // Cancelled: stay on the dialog so the player can retry or bail.
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // White badge with the drawn G — the "who" of this dialog.
        Container(
          width: 56 * s,
          height: 56 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24 * s,
                offset: Offset(0, 8 * s),
              ),
            ],
          ),
          child: GoogleG(size: 28 * s),
        ),
        SizedBox(height: 14 * s),
        Text(widget.title,
            textAlign: TextAlign.center,
            style: Candy.display(size: 24 * s, height: 1.1)),
        SizedBox(height: 8 * s),
        Text(
          widget.body,
          textAlign: TextAlign.center,
          style: Candy.ui(
            color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
            size: 13.5 * s,
            height: 1.5,
          ),
        ),
        SizedBox(height: 18 * s),
        _busy
            ? SizedBox(
                height: 54 * s,
                child: const Center(
                    child: CircularProgressIndicator(color: Candy.orange)),
              )
            : GoogleSignInButton(onPressed: _signIn),
        SizedBox(height: 13 * s),
        GestureDetector(
          onTap: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Not now',
            style: Candy.ui(
              color: Colors.white.withValues(alpha: 0.5),
              size: 13.5 * s,
            ),
          ),
        ),
      ],
    );
  }
}
