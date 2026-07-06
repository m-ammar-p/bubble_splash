/// A bundle of lives sold in the Shop for coins (the purchasable currency).
/// Buying is a two-step economy: real money → coins (IAP), coins → lives.
class LifePack {
  const LifePack({
    required this.id,
    required this.lives,
    required this.priceCoins,
  });

  final String id;

  /// Lives granted, banked up to `LivesState.maxLives`.
  final int lives;

  /// Cost in coins.
  final int priceCoins;
}

/// Life packs offered in the shop. Bigger packs are better value per life
/// (50 → 40 → 33 coins/life) to reward the larger spend.
const List<LifePack> kLifePacks = [
  LifePack(id: 'lives_small', lives: 5, priceCoins: 250),
  LifePack(id: 'lives_medium', lives: 15, priceCoins: 600),
  LifePack(id: 'lives_large', lives: 30, priceCoins: 1000),
];
