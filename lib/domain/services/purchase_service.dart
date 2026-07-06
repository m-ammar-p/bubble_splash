/// A purchasable coin pack. Coins are the in-game currency used to buy bubble
/// skins; they are acquired with real money via in-app purchase, not earned by
/// playing. The fake implementation simulates a store flow; swap in a
/// RevenueCat-backed implementation later without touching any caller.
class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.priceLabel,
  });

  /// Store product id (maps to a RevenueCat / store SKU later).
  final String id;
  final int coins;

  /// Localized price shown in the UI (a real store would supply this).
  final String priceLabel;
}

/// Coin packs offered in the shop.
const List<CoinPack> kCoinPacks = [
  CoinPack(id: 'coins_small', coins: 500, priceLabel: r'$0.99'),
  CoinPack(id: 'coins_medium', coins: 1500, priceLabel: r'$2.99'),
  CoinPack(id: 'coins_large', coins: 3000, priceLabel: r'$4.99'),
];

/// Initiates an in-app purchase for a coin pack. Returns the purchased pack on
/// success, or null if the purchase was cancelled or failed.
abstract interface class PurchaseService {
  Future<CoinPack?> buyCoins(CoinPack pack);
}
