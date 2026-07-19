// The combo power-up: the score multiplier is earned by popping the rare combo
// bubble (2×→4×→6×) and drains from a fuel bar — it is NOT chained from
// consecutive pops. These pin that policy.

import 'package:bubble_splash/game/bubble_splash_game.dart';
import 'package:bubble_splash/game/components/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BubbleSplashGame newGame() => BubbleSplashGame(
        palette: const [Colors.blue],
        onGameOver: (_) {},
        onContinueOffer: () {},
      );

  test('a normal pop does NOT raise the multiplier (no auto-combo)', () {
    final game = newGame();
    for (var i = 0; i < 10; i++) {
      game.onBubblePopped(BubbleKind.normal);
    }
    expect(game.comboTier.value, 0);
    expect(game.multiplier, 1);
  });

  test('popping a combo bubble activates a random tier and fills the bar', () {
    // Randomized: each combo bubble rolls ×2/×4/×6. Over many rolls the tier is
    // always in range, the bar always fills, and every value shows up.
    final seen = <int>{};
    for (var i = 0; i < 200; i++) {
      final game = newGame();
      game.onBubblePopped(BubbleKind.combo);
      expect(game.comboTier.value,
          inInclusiveRange(1, BubbleSplashGame.maxComboTier));
      expect(game.multiplier, isIn(const [2, 4, 6]));
      expect(game.comboFuel.value, 1.0);
      seen.add(game.multiplier);
    }
    expect(seen, containsAll(const [2, 4, 6])); // all three tiers reachable
  });

  test('the active multiplier applies to scoring pops', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.combo);
    final mult = game.multiplier; // whatever tier rolled
    final before = game.score.value;
    game.onBubblePopped(BubbleKind.normal);
    expect(game.score.value - before, mult); // 1 point × multiplier
  });

  test('a scoring pop does NOT extend the combo (strict countdown)', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.combo);
    game.comboFuel.value = 0.5;
    game.onBubblePopped(BubbleKind.normal);
    expect(game.comboFuel.value, 0.5); // unchanged — only time (or a combo pop) moves it
  });

  test('popping another combo bubble refreshes the timer to full', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.combo);
    game.comboFuel.value = 0.2; // nearly expired
    game.onBubblePopped(BubbleKind.combo); // re-roll + refill
    expect(game.comboFuel.value, 1.0);
    expect(game.comboTier.value,
        inInclusiveRange(1, BubbleSplashGame.maxComboTier));
  });

  test('letting a combo bubble escape is harmless (no HP lost)', () {
    final game = newGame();
    final hp = game.hp.value;
    game.onBubbleMissed(BubbleKind.combo);
    expect(game.hp.value, hp);
  });

  test('a combo pop does not count toward the streak stat', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.combo);
    expect(game.combo.value, 0); // streak untouched by the power-up
  });
}
