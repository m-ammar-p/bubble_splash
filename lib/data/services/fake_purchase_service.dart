import 'package:flutter/material.dart';

import '../../domain/services/purchase_service.dart';

/// Simulates an in-app purchase with a confirmation dialog. Resolves to the
/// purchased [CoinPack] when confirmed, or null if cancelled. Uses a shared
/// [navigatorKey] so it satisfies the Flutter-free [PurchaseService] contract.
/// Replace with a RevenueCat-backed implementation later — callers don't change.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<CoinPack?> buyCoins(CoinPack pack) async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E3A55),
        title: const Text('Confirm purchase',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Buy ${pack.coins} coins for ${pack.priceLabel}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(pack.priceLabel),
          ),
        ],
      ),
    );

    return (confirmed ?? false) ? pack : null;
  }
}
