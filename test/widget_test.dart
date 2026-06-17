// Smoke test for the Flame game's in-round scoring and continue flow.

import 'package:bubble_splash/domain/models/game_result.dart';
import 'package:bubble_splash/game/bubble_splash_game.dart';
import 'package:bubble_splash/game/components/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BubbleSplashGame newGame({
    void Function(GameResult)? onOver,
    VoidCallback? onContinue,
  }) =>
      BubbleSplashGame(
        palette: const [Colors.blue],
        onGameOver: onOver ?? (_) {},
        onContinueOffer: onContinue ?? () {},
      );

  void depleteHp(BubbleSplashGame game) {
    for (var i = 0; i < BubbleSplashGame.maxHp; i++) {
      game.onBubbleMissed(BubbleKind.normal);
    }
  }

  test('popping normal bubbles increases score and combo', () {
    final game = newGame();
    game.onBubblePopped(BubbleKind.normal);
    expect(game.score.value, greaterThan(0));
    expect(game.combo.value, 1);
  });

  test('depleting HP offers a continue instead of ending the round', () {
    var offered = false;
    final game = newGame(onContinue: () => offered = true);
    depleteHp(game);
    expect(offered, isTrue);
    expect(game.isGameOver, isFalse);
  });

  test('continuing restores HP and keeps the round alive', () {
    final game = newGame();
    depleteHp(game);
    game.continueRound();
    expect(game.hp.value, BubbleSplashGame.maxHp);
    expect(game.isGameOver, isFalse);
  });

  test('ending the run after depletion emits the result', () {
    GameResult? result;
    final game = newGame(onOver: (r) => result = r);
    depleteHp(game);
    game.finishRound();
    expect(game.isGameOver, isTrue);
    expect(result, isNotNull);
  });

  test('popping a bomb offers a continue', () {
    var offered = false;
    final game = newGame(onContinue: () => offered = true);
    game.onBubblePopped(BubbleKind.bomb);
    expect(offered, isTrue);
  });
}
