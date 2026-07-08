import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/candy.dart';
import '../../app/countries.dart';
import '../../application/auth_controller.dart';

/// The email/password auth form, Candy Cosmos styled. One widget, two hosts:
/// the Login screen embeds it inline; the "sign in to continue" gate
/// ([showSignInPrompt]) embeds it in a dialog. It owns its own mode (Sign in /
/// Sign up), fields, validation, busy + error state, and calls the
/// [AuthController]. On success it fires [onAuthenticated] — the host decides
/// where to go (Home, or pop the gate).
class AuthPanel extends ConsumerStatefulWidget {
  const AuthPanel({
    super.key,
    required this.onAuthenticated,
    this.initialSignUp = false,
  });

  final VoidCallback onAuthenticated;
  final bool initialSignUp;

  @override
  ConsumerState<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends ConsumerState<AuthPanel> {
  late bool _signUp = widget.initialSignUp;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late Country _country = defaultCountry();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(bool signUp) {
    if (_signUp == signUp) return;
    setState(() {
      _signUp = signUp;
      _error = null;
    });
  }

  String? _validate() {
    final email = _email.text.trim();
    if (_signUp && _name.text.trim().isEmpty) return 'Enter a display name.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email.';
    }
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final invalid = _validate();
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(authControllerProvider.notifier);
    final error = _signUp
        ? await controller.signUp(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            country: _country.code,
          )
        : await controller.signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
    if (!mounted) return;
    if (error == null) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeToggle(signUp: _signUp, onChanged: _busy ? null : _setMode),
        SizedBox(height: 16 * s),
        if (_signUp) ...[
          _CandyField(
            controller: _name,
            hint: 'Display name',
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 10 * s),
        ],
        _CandyField(
          controller: _email,
          hint: 'Email',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 10 * s),
        _CandyField(
          controller: _password,
          hint: 'Password',
          icon: Icons.lock_rounded,
          obscure: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          trailing: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 18 * s,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (_signUp) ...[
          SizedBox(height: 10 * s),
          _CountrySelector(
            country: _country,
            onTap: _busy
                ? null
                : () async {
                    final picked = await showCountryPicker(context);
                    if (picked != null) setState(() => _country = picked);
                  },
          ),
        ],
        if (_error != null) ...[
          SizedBox(height: 12 * s),
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 15 * s, color: Candy.heartLight),
              SizedBox(width: 6 * s),
              Expanded(
                child: Text(_error!,
                    style: Candy.ui(size: 12.5 * s, color: Candy.heartLight)),
              ),
            ],
          ),
        ],
        SizedBox(height: 16 * s),
        CandyCtaButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? SizedBox(
                  width: 22 * s,
                  height: 22 * s,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5 * s, color: Candy.ctaInk),
                )
              : Text(
                  _signUp ? 'Create account' : 'Sign in',
                  style: Candy.ui(
                      color: Candy.ctaInk,
                      size: 16.5 * s,
                      weight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}

/// Two-segment Sign in / Sign up switch inside a glass track.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.signUp, required this.onChanged});
  final bool signUp;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 14 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.all(4 * s),
      child: Row(
        children: [
          _segment(context, 'Sign in', !signUp, () => onChanged?.call(false)),
          _segment(context, 'Sign up', signUp, () => onChanged?.call(true)),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final s = candyScale(context);
    return Expanded(
      child: GestureDetector(
        onTap: onChanged == null ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10 * s),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Candy.orangeCtaTop, Candy.orangeCtaBottom],
                  )
                : null,
          ),
          child: Text(
            label,
            style: Candy.ui(
              size: 14 * s,
              weight: FontWeight.w800,
              color: active
                  ? Candy.ctaInk
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass-wrapped text field: leading icon, muted hint, white text.
class _CandyField extends StatelessWidget {
  const _CandyField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 14 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.symmetric(horizontal: 13 * s),
      child: Row(
        children: [
          Icon(icon, size: 18 * s, color: Colors.white.withValues(alpha: 0.5)),
          SizedBox(width: 10 * s),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              cursorColor: Candy.orange,
              style: Candy.ui(size: 15 * s, weight: FontWeight.w700),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15 * s),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: Candy.ui(
                    size: 15 * s,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8 * s), trailing!],
        ],
      ),
    );
  }
}

/// Sign-up country row: globe chip, selected name, chevron → [showCountryPicker].
class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.country, required this.onTap});
  final Country country;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      onTap: onTap,
      radius: 14 * s,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 14 * s),
      child: Row(
        children: [
          Icon(Icons.public_rounded,
              size: 18 * s, color: Colors.white.withValues(alpha: 0.5)),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(country.name,
                style: Candy.ui(size: 15 * s, weight: FontWeight.w700)),
          ),
          Text(country.code,
              style: Candy.ui(
                  size: 12.5 * s,
                  weight: FontWeight.w800,
                  color: Candy.timer)),
          SizedBox(width: 4 * s),
          Icon(Icons.expand_more_rounded,
              size: 20 * s, color: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

/// Searchable Candy country picker. Returns the chosen [Country] or null.
Future<Country?> showCountryPicker(BuildContext context) {
  return showDialog<Country>(
    context: context,
    barrierColor: const Color(0xFF0A0514).withValues(alpha: 0.6),
    builder: (ctx) {
      final s = candyScale(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 60 * s),
        child: CandySheet(
          padding: EdgeInsets.fromLTRB(16 * s, 18 * s, 16 * s, 12 * s),
          child: const _CountryPickerBody(),
        ),
      );
    },
  );
}

class _CountryPickerBody extends StatefulWidget {
  const _CountryPickerBody();

  @override
  State<_CountryPickerBody> createState() => _CountryPickerBodyState();
}

class _CountryPickerBodyState extends State<_CountryPickerBody> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? kCountries
        : kCountries
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.code.toLowerCase().contains(q))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Your country',
            style: Candy.display(size: 20 * s, height: 1)),
        SizedBox(height: 12 * s),
        _CandyField(
          controller: _search,
          hint: 'Search',
          icon: Icons.search_rounded,
          onChanged: (v) => setState(() => _query = v),
        ),
        SizedBox(height: 10 * s),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (_, i) {
              final c = results[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(c),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 11 * s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.name,
                            style:
                                Candy.ui(size: 14.5 * s, weight: FontWeight.w700)),
                      ),
                      Text(c.code,
                          style: Candy.ui(
                              size: 12 * s,
                              weight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.45))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Candy "sign in to continue" gate: shown at the moment of intent (a guest
/// taps a coin pack, or the name field). Embeds the full [AuthPanel] so the
/// player can sign in *or* create an account without leaving the flow. Returns
/// true only after a successful auth; "Not now" / dismiss returns false.
Future<bool> showSignInPrompt(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final done = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF0A0514).withValues(alpha: 0.6),
    builder: (ctx) {
      final s = candyScale(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24 * s),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            child: CandySheet(
              padding: EdgeInsets.fromLTRB(20 * s, 22 * s, 20 * s, 16 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: Candy.display(size: 22 * s, height: 1.1)),
                  SizedBox(height: 8 * s),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Candy.ui(
                      color: const Color(0xFFFFE1D2).withValues(alpha: 0.60),
                      size: 13.5 * s,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 18 * s),
                  AuthPanel(
                    onAuthenticated: () => Navigator.of(ctx).pop(true),
                  ),
                  SizedBox(height: 12 * s),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Text('Not now',
                        style: Candy.ui(
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 13.5 * s)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return done ?? false;
}
