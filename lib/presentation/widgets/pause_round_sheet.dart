import 'package:flutter/material.dart';

import '../../app/candy.dart';

/// Result of the pause menu. [resume] unpauses the engine; [quit] ends the
/// round (records the score via the Results overlay).
enum PauseChoice { resume, quit }

/// Manual mid-round pause menu (screen 02 pause). The engine is already paused
/// by the caller; this only collects the choice. Candy Cosmos style: violet
/// sheet, warm orange pause icon (positive cue — never red), orange Resume CTA
/// + glass Quit button. Quitting finalizes the round so the earned score/XP is
/// banked, not discarded.
///
/// Non-dismissible by design (matches the death "Keep going?" sheet): the player
/// paused to step away, so an accidental barrier tap must NOT resume into live
/// play and cost HP — resume is deliberate (the Resume CTA) only.
Future<PauseChoice?> showPauseSheet(BuildContext context) {
  return showModalBottomSheet<PauseChoice>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0A0514).withValues(alpha: 0.55),
    builder: (_) => const _PauseSheet(),
  );
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet();

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandySheet(
      padding: EdgeInsets.fromLTRB(20 * s, 24 * s, 20 * s, 22 * s),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 56px orange radial icon circle with a pause glyph.
            Container(
              width: 56 * s,
              height: 56 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.32, -0.44),
                  radius: 0.9,
                  colors: Candy.orangeChip,
                  stops: [0.0, 0.60, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Candy.orange.withValues(alpha: 0.5),
                    blurRadius: 24 * s,
                    offset: Offset(0, 8 * s),
                  ),
                ],
              ),
              child:
                  Icon(Icons.pause_rounded, color: Candy.ctaInk, size: 30 * s),
            ),
            SizedBox(height: 14 * s),
            Text('Paused', style: Candy.display(size: 27 * s, height: 1.0)),
            SizedBox(height: 8 * s),
            Text(
              'Take a breather. Your progress is safe.',
              textAlign: TextAlign.center,
              style: Candy.ui(
                color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                size: 13.5 * s,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18 * s),
            CandyCtaButton(
              onPressed: () => Navigator.of(context).pop(PauseChoice.resume),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: Candy.ctaInk, size: 20 * s),
                  SizedBox(width: 8 * s),
                  Text(
                    'Resume',
                    style: Candy.ui(
                      color: Candy.ctaInk,
                      size: 16.5 * s,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10 * s),
            // Ends the round: the round result is recorded (Results overlay),
            // so the score/XP earned this run is banked, never discarded.
            _GlassButton(
              onPressed: () => Navigator.of(context).pop(PauseChoice.quit),
              icon: Icons.home_rounded,
              label: 'Quit to home',
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary 54px glass button (white text, subtle border).
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      onTap: onPressed,
      radius: 18 * s,
      borderAlpha: 0.22,
      height: 54 * s,
      width: double.infinity,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18 * s),
          SizedBox(width: 8 * s),
          Text(label, style: Candy.ui(size: 16.5 * s, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
