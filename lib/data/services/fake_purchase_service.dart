import 'package:flutter/material.dart';

import '../../domain/services/purchase_service.dart';

/// Simulates an in-app purchase: a short "store round-trip" delay, then
/// success. The user-facing confirmation lives in the Shop's Candy dialog —
/// this service deliberately shows NO UI of its own, so there's exactly one
/// popup per purchase. A RevenueCat-backed implementation will replace the
/// delay with the platform's own purchase sheet.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService(this.navigatorKey);

  /// Kept for signature parity with the future store-backed implementation
  /// (platform sheets need a context); unused by the fake.
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<CoinPack?> buyCoins(CoinPack pack) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return pack;
  }
}
