import 'package:bubble_splash/game/bubble_splash_game.dart';
import 'package:bubble_splash/game/components/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The difficulty ramp is deliberately asymptotic: the early game matches the
// old linear ramp, but speed and spawn rate plateau so long runs stay
// playable (retention). These tests pin the plateau so a future tweak can't
// silently reintroduce the unbounded ramp.
void main() {
  group('speed ramp', () {
    test('matches the old linear slope early (≈1.5 px/s per point)', () {
      // Old ramp: score * 1.5. At score 10 the curves should be within ~5%.
      expect(BubbleSplashGame.rampSpeedBonus(10), closeTo(15, 1.0));
    });

    test('is monotonically increasing', () {
      var prev = BubbleSplashGame.rampSpeedBonus(0);
      for (var score = 25; score <= 2000; score += 25) {
        final next = BubbleSplashGame.rampSpeedBonus(score);
        expect(next, greaterThan(prev));
        prev = next;
      }
    });

    test('plateaus: never exceeds the +240 px/s ceiling', () {
      expect(BubbleSplashGame.rampSpeedBonus(0), 0);
      expect(BubbleSplashGame.rampSpeedBonus(1000000), lessThanOrEqualTo(240));
      // Effectively at the ceiling for very long runs.
      expect(BubbleSplashGame.rampSpeedBonus(5000), closeTo(240, 0.1));
    });
  });

  group('spawn interval', () {
    test('starts at 0.85s and matches the old slope early', () {
      expect(BubbleSplashGame.spawnIntervalFor(0), closeTo(0.85, 1e-9));
      // Old ramp: 0.85 - score * 0.01. At score 5 within ~5%.
      expect(BubbleSplashGame.spawnIntervalFor(5), closeTo(0.80, 0.005));
    });

    test('is monotonically decreasing', () {
      var prev = BubbleSplashGame.spawnIntervalFor(0);
      for (var score = 10; score <= 1000; score += 10) {
        final next = BubbleSplashGame.spawnIntervalFor(score);
        expect(next, lessThan(prev));
        prev = next;
      }
    });

    test('never drops below the 0.38s floor', () {
      expect(
        BubbleSplashGame.spawnIntervalFor(1000000),
        greaterThanOrEqualTo(0.38),
      );
      expect(BubbleSplashGame.spawnIntervalFor(1000), closeTo(0.38, 0.001));
    });
  });

  group('post-continue speed relief', () {
    BubbleSplashGame newGame() => BubbleSplashGame(
          palette: const [Colors.blue],
          onGameOver: (_) {},
          onContinueOffer: () {},
        );

    void depleteHp(BubbleSplashGame game) {
      for (var i = 0; i < BubbleSplashGame.maxHp; i++) {
        game.onBubbleMissed(BubbleKind.normal);
      }
    }

    test('continuing halves the speed (50% relief)', () {
      final game = newGame();
      expect(game.speedRelief, 1.0);
      depleteHp(game);
      game.continueRound();
      expect(game.speedRelief, BubbleSplashGame.reliefFactor);
    });

    test('relief recovers linearly and clamps at full speed', () {
      const half = BubbleSplashGame.reliefRecoverySeconds / 2;
      // Halfway through recovery → halfway back to 1.0.
      expect(
        BubbleSplashGame.recoverRelief(BubbleSplashGame.reliefFactor, half),
        closeTo(0.75, 0.001),
      );
      // Fully recovered, and clamped at 1.0 thereafter.
      expect(
        BubbleSplashGame.recoverRelief(
          BubbleSplashGame.reliefFactor,
          BubbleSplashGame.reliefRecoverySeconds * 2,
        ),
        1.0,
      );
    });
  });
}
