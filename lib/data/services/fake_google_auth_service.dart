import 'package:flutter/material.dart';

import '../../domain/models/auth_state.dart';
import '../../domain/services/auth_service.dart';

/// The demo accounts the fake chooser offers. Ids are stable so per-account
/// profile storage (`profile_<id>`) survives sign-out/sign-in round trips.
const _fakeAccounts = [
  AuthAccount(
    id: 'google_demo_1',
    displayName: 'Bubble Player',
    email: 'bubble.player@gmail.com',
  ),
  AuthAccount(
    id: 'google_demo_2',
    displayName: 'Splash Master',
    email: 'splash.master@gmail.com',
  ),
];

/// Simulates Google Sign-In with an account-chooser dialog (mirrors the real
/// plugin's UX: pick an account or dismiss to cancel). Uses the shared
/// [navigatorKey] so it satisfies the Flutter-free [AuthService] contract —
/// same pattern as the fake ad/purchase services.
class FakeGoogleAuthService implements AuthService {
  FakeGoogleAuthService(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<AuthAccount?> signInWithGoogle() async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    final account = await showDialog<AuthAccount>(
      context: context,
      builder: (_) => const _FakeAccountChooserDialog(),
    );
    if (account == null) return null; // dismissed = cancelled sign-in

    // Simulate the token exchange round trip.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return account;
  }

  @override
  Future<void> signOut() async {
    // Nothing provider-side to clear in the fake.
  }
}

/// A stripped-down clone of Google's account chooser sheet.
class _FakeAccountChooserDialog extends StatelessWidget {
  const _FakeAccountChooserDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose an account',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Text(
              'to continue to Bubble Splash',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            for (final account in _fakeAccounts)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4285F4),
                  child: Text(
                    account.displayName[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  account.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                subtitle: Text(
                  account.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () => Navigator.of(context).pop(account),
              ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
