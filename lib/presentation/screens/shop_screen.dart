import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../app/theme.dart';
import '../../domain/models/bubble_skin.dart';
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
