import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../app/theme.dart';
import 'glass.dart';

/// Coin balance pill (Shop app bar). The Home header uses the Candy Cosmos
/// stat pills instead — this is the last of the old-style badges.
class CoinBadge extends ConsumerWidget {
  const CoinBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.coins));
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
