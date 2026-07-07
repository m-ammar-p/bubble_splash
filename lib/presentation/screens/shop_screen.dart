import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lives_controller.dart';
import '../../application/profile_controller.dart';
import '../../application/providers.dart';
import '../../app/candy.dart';
import '../../domain/models/life_pack.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/services/purchase_service.dart';

/// The Shop sells lives (the continue currency) for coins, and coins for real
/// money (fake IAP for now). Bubble skins are no longer sold here — the skin
/// system still exists in code (the game reads the equipped palette) but the
/// shop's job is the lives economy. Skinned to Candy Cosmos, matching the
/// Profile screen's header/section/card structure.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.coins));
    final lives = ref.watch(livesControllerProvider);
    final s = candyScale(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 0),
              child: Column(
                children: [
                  _Header(coins: coins),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(top: 14 * s, bottom: 20 * s),
                      children: [
                        const _SectionLabel('GET COINS'),
                        SizedBox(height: 4 * s),
                        Text('Buy coins to stock up on lives below.',
                            style: Candy.ui(
                                size: 12 * s,
                                color:
                                    Colors.white.withValues(alpha: 0.55))),
                        SizedBox(height: 10 * s),
                        // Fixed row — all packs fit on screen, no sliding.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < kCoinPacks.length; i++) ...[
                                if (i > 0) SizedBox(width: 8 * s),
                                Expanded(
                                  child: _PackCard(
                                    chip: Candy.coinsChip,
                                    icon: Icons.monetization_on,
                                    iconColor: const Color(0xFF7A5300),
                                    value: '${kCoinPacks[i].coins}',
                                    label: 'coins',
                                    button: Text(kCoinPacks[i].priceLabel,
                                        maxLines: 1,
                                        style: Candy.ui(
                                            size: 12.5 * s,
                                            weight: FontWeight.w800,
                                            color: Candy.ctaInk)),
                                    onBuy: () =>
                                        _buyCoins(context, ref, kCoinPacks[i]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * s),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const _SectionLabel('LIVES'),
                            const Spacer(),
                            Text(
                                '${lives.count}/${LivesState.maxLives} banked',
                                style: Candy.ui(
                                    size: 12 * s,
                                    weight: FontWeight.w800,
                                    color: const Color(0x99FFE1D2))),
                          ],
                        ),
                        SizedBox(height: 4 * s),
                        Text('Lives revive a run when you go down mid-round.',
                            style: Candy.ui(
                                size: 12 * s,
                                color:
                                    Colors.white.withValues(alpha: 0.55))),
                        SizedBox(height: 10 * s),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < kLifePacks.length; i++) ...[
                                if (i > 0) SizedBox(width: 8 * s),
                                Expanded(
                                  child: _PackCard(
                                    chip: Candy.livesChip,
                                    icon: Icons.favorite,
                                    iconColor: Colors.white,
                                    value: '+${kLifePacks[i].lives}',
                                    label: 'lives',
                                    button: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.monetization_on,
                                            size: 13 * s,
                                            color: Candy.ctaInk),
                                        SizedBox(width: 3 * s),
                                        Text('${kLifePacks[i].priceCoins}',
                                            maxLines: 1,
                                            style: Candy.ui(
                                                size: 12.5 * s,
                                                weight: FontWeight.w800,
                                                color: Candy.ctaInk)),
                                      ],
                                    ),
                                    // Buyable only if affordable AND the whole
                                    // pack fits — partial fills are never sold
                                    // (see _buyLives).
                                    enabled: coins >=
                                            kLifePacks[i].priceCoins &&
                                        lives.count + kLifePacks[i].lives <=
                                            LivesState.maxLives,
                                    onBuy: () =>
                                        _buyLives(context, ref, kLifePacks[i]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

/// Glass back circle · centered "Shop" title · coin balance pill (right).
class _Header extends StatelessWidget {
  const _Header({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return SizedBox(
      height: 38 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('Shop', style: Candy.display(size: 20 * s)),
          Align(
            alignment: Alignment.centerLeft,
            child: CandyGlass(
              width: 38 * s,
              height: 38 * s,
              alignment: Alignment.center,
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back,
                  size: 17 * s, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CandyGlass(
              padding: EdgeInsets.fromLTRB(4 * s, 4 * s, 13 * s, 4 * s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CandyChip(
                    colors: Candy.coinsChip,
                    size: 26 * s,
                    child: Icon(Icons.monetization_on,
                        size: 15 * s, color: const Color(0xFF7A5300)),
                  ),
                  SizedBox(width: 7 * s),
                  Text('$coins',
                      style: Candy.ui(size: 14 * s, weight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Text(text,
        style: Candy.ui(
            size: 12 * s,
            weight: FontWeight.w800,
            letterSpacing: 2.5 * s,
            color: const Color(0x8CFFE1D2)));
  }
}

/// Glass pack card: gradient icon chip, Baloo amount, Nunito unit label and an
/// orange CTA (dimmed via [CandyCtaButton]'s disabled state when [enabled] is
/// false). Shared by coin and life packs.
class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.chip,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.button,
    required this.onBuy,
    this.enabled = true,
  });

  final List<Color> chip;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Widget button;
  final VoidCallback onBuy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 16 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.fromLTRB(8 * s, 12 * s, 8 * s, 10 * s),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CandyChip(
            colors: chip,
            size: 34 * s,
            child: Icon(icon, size: 17 * s, color: iconColor),
          ),
          SizedBox(height: 8 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                maxLines: 1,
                style: Candy.display(
                    size: 19 * s, color: Colors.white, height: 1)),
          ),
          SizedBox(height: 1 * s),
          Text(label,
              style: Candy.ui(
                  size: 11 * s, color: Colors.white.withValues(alpha: 0.55))),
          SizedBox(height: 9 * s),
          CandyCtaButton(
            height: 30,
            radius: 11,
            onPressed: enabled ? onBuy : null,
            child: FittedBox(fit: BoxFit.scaleDown, child: button),
          ),
        ],
      ),
    );
  }
}
