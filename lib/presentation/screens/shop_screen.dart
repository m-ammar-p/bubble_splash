import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/profile_controller.dart';
import '../../application/providers.dart';
import '../../app/candy.dart';
import '../../app/theme.dart';
import '../../domain/models/life_pack.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/services/purchase_service.dart';
import '../widgets/glass.dart';
import '../widgets/status_badges.dart';

/// The Shop sells lives (the continue currency) for coins, and coins for real
/// money (fake IAP for now). Bubble skins are no longer sold here — the skin
/// system still exists in code (the game reads the equipped palette) but the
/// shop's job is the lives economy.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.coins));
    final lives = ref.watch(livesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: Center(child: CoinBadge())),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Get Coins',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Buy coins to stock up on lives below.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          // Fixed row — all packs fit on screen, no horizontal sliding.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < kCoinPacks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _CoinPackCard(
                      pack: kCoinPacks[i],
                      onBuy: () => _buyCoins(context, ref, kCoinPacks[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Lives',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${lives.count}/${LivesState.maxLives} banked',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Lives revive a run when you go down mid-round.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < kLifePacks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _LifePackCard(
                      pack: kLifePacks[i],
                      // Buyable only if affordable AND the whole pack fits —
                      // partial fills are never sold (see _buyLives).
                      affordable: coins >= kLifePacks[i].priceCoins &&
                          lives.count + kLifePacks[i].lives <=
                              LivesState.maxLives,
                      onBuy: () => _buyLives(context, ref, kLifePacks[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyLives(
      BuildContext context, WidgetRef ref, LifePack pack) async {
    final lives = ref.read(livesControllerProvider);
    // Whole pack must fit — never charge full price for a clamped grant
    // (e.g. 97 + 5 must not cost 250 coins for 3 lives).
    final String? blocked;
    if (lives.count + pack.lives > LivesState.maxLives) {
      final room = LivesState.maxLives - lives.count;
      blocked = room <= 0
          ? 'Lives bank is full (${LivesState.maxLives}).'
          : 'Only room for $room more lives — pick a smaller pack.';
    } else if (ref.read(profileControllerProvider).coins < pack.priceCoins) {
      blocked = 'Not enough coins — grab a coin pack above.';
    } else {
      blocked = null;
    }
    if (blocked != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }

    final ok = await showCandyConfirmDialog(
      context,
      chipColors: Candy.livesChip,
      icon: Icons.favorite,
      title: '+${pack.lives} lives',
      body: '${pack.priceCoins} coins',
      confirmLabel: 'Buy',
    );
    if (!ok || !context.mounted) return;

    final String message;
    if (!ref
        .read(profileControllerProvider.notifier)
        .spendCoins(pack.priceCoins)) {
      message = 'Not enough coins — grab a coin pack above.';
    } else if (ref.read(livesControllerProvider.notifier).addLives(pack.lives)) {
      message = '+${pack.lives} lives banked!';
    } else {
      // Bank filled between confirm and grant — refund rather than eat coins.
      ref.read(profileControllerProvider.notifier).grantCoins(pack.priceCoins);
      message = 'Lives bank is full (${LivesState.maxLives}).';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buyCoins(
      BuildContext context, WidgetRef ref, CoinPack pack) async {
    // Exactly ONE popup per purchase: this Candy dialog. The fake service
    // shows no UI (a real store adds its own platform sheet later).
    final ok = await showCandyConfirmDialog(
      context,
      chipColors: Candy.coinsChip,
      icon: Icons.monetization_on,
      title: '${pack.coins} coins',
      body: pack.priceLabel,
      confirmLabel: 'Buy',
    );
    if (!ok || !context.mounted) return;

    final purchased =
        await ref.read(purchaseServiceProvider).buyCoins(pack);
    if (purchased == null || !context.mounted) return;
    ref.read(profileControllerProvider.notifier).grantCoins(purchased.coins);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('+${purchased.coins} coins added!')),
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({required this.pack, required this.onBuy});

  final CoinPack pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${pack.coins}',
                maxLines: 1,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const Text('coins',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBuy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(pack.priceLabel,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifePackCard extends StatelessWidget {
  const _LifePackCard({
    required this.pack,
    required this.affordable,
    required this.onBuy,
  });

  final LifePack pack;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFFF5B79), size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('+${pack.lives}',
                maxLines: 1,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const Text('lives',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: affordable ? onBuy : null,
              icon: const Icon(Icons.monetization_on, size: 16),
              style: FilledButton.styleFrom(
                backgroundColor: affordable ? AppColors.gold : Colors.white12,
                foregroundColor: affordable ? Colors.black : Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${pack.priceCoins}',
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
