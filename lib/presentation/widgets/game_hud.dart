import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/bubble_splash_game.dart';
import 'glass.dart';

/// In-round heads-up display, stacked over the Flame [GameWidget]. Reads the
/// game's [ValueNotifier]s directly so it rebuilds only the affected pieces.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game, required this.onQuit});

  final BubbleSplashGame game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onQuit,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  tooltip: 'Quit',
                ),
                const Spacer(),
                GlassPill(
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.score,
                    builder: (_, score, _) => Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: game.hp,
                  builder: (_, hp, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      BubbleSplashGame.maxHp,
                      (i) => Icon(
                        i < hp ? Icons.favorite : Icons.favorite_border,
                        color: i < hp ? AppColors.heart : Colors.white30,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ValueListenableBuilder<int>(
              valueListenable: game.combo,
              builder: (_, combo, _) => AnimatedOpacity(
                opacity: combo >= 2 ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  'COMBO x${1 + combo ~/ 5}  ·  $combo',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ValueListenableBuilder<bool>(
                valueListenable: game.soundOn,
                builder: (_, on, _) => IconButton(
                  onPressed: game.toggleSound,
                  icon: Icon(on ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white60),
                  tooltip: on ? 'Mute' : 'Unmute',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
