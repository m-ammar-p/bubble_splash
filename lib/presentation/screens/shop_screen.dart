import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../application/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/bubble_skin.dart';
import '../../domain/services/purchase_service.dart';
import '../widgets/glass.dart';
import '../widgets/status_badges.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

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
          const Text('Buy coins to unlock bubble themes below.',
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
          const Text('Bubble Themes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final skin in kBubbleSkins)
            _SkinCard(
              skin: skin,
              owned: profile.ownedSkinIds.contains(skin.id),
              equipped: profile.equippedSkinId == skin.id,
              affordable: profile.coins >= skin.price,
              onBuy: () => _buy(context, ref, skin),
              onEquip: () =>
                  ref.read(profileControllerProvider.notifier).equipSkin(skin.id),
            ),
        ],
      ),
    );
  }

  void _buy(BuildContext context, WidgetRef ref, BubbleSkin skin) {
    final ok = ref.read(profileControllerProvider.notifier).buySkin(skin.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '${skin.name} unlocked & equipped!'
            : 'Not enough coins for ${skin.name}'),
      ),
    );
  }

  Future<void> _buyCoins(
      BuildContext context, WidgetRef ref, CoinPack pack) async {
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

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.onBuy,
    required this.onEquip,
  });

  final BubbleSkin skin;
  final bool owned;
  final bool equipped;
  final bool affordable;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        radius: 16,
        tint: equipped ? AppColors.accent : Colors.white,
        borderColor: equipped ? AppColors.accent : null,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skin.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final c in skin.colors.take(6))
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(c).withValues(alpha: 0.4),
                              Color(c),
                            ],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _action(),
          ],
        ),
      ),
    );
  }

  Widget _action() {
    if (equipped) {
      return const Chip(
        backgroundColor: AppColors.accent,
        label: Text('Equipped', style: TextStyle(color: Colors.white)),
      );
    }
    if (owned) {
      return OutlinedButton(onPressed: onEquip, child: const Text('Equip'));
    }
    return FilledButton.icon(
      onPressed: affordable ? onBuy : null,
      icon: const Icon(Icons.monetization_on, size: 18),
      label: Text('${skin.price}'),
      style: FilledButton.styleFrom(
        backgroundColor: affordable ? AppColors.gold : Colors.white12,
        foregroundColor: affordable ? Colors.black : Colors.white38,
      ),
    );
  }
}
