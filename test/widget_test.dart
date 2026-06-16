// Smoke test for the Flame game's in-round scoring.

import 'package:bubble_splash/domain/models/game_result.dart';
import 'package:bubble_splash/game/bubble_splash_game.dart';
import 'package:bubble_splash/game/components/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BubbleSplashGame newGame() => BubbleSplashGame(
        palette: const [Colors.blue],
        onGameOver: (_) {},
      );

  test('popping normal bubbles increases score and combo', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.normal);
    expect(game.score.value, greaterThan(0));
    expect(game.combo.value, 1);
  });

  test('missing scoring bubbles drains HP and ends the round', () {
    GameResult? result;
    final game = BubbleSplashGame(
      palette: const [Colors.blue],
      onGameOver: (r) => result = r,
    );
    for (var i = 0; i < BubbleSplashGame.maxHp; i++) {
      game.onBubbleMissed(BubbleKind.normal);
    }
    expect(game.isGameOver, isTrue);
    expect(result, isNotNull);
  });

  test('popping a bomb ends the round immediately', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.bomb);
    expect(game.isGameOver, isTrue);
  });
}
