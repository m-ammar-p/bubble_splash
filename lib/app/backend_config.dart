/// Supabase credentials for email/password auth. Both values are **public
/// client identifiers** — the anon/publishable key is meant to ship in the app;
/// row-level security (RLS) protects data, not secrecy of this string. Safe to
/// commit.
///
/// While the placeholders are unchanged, [isConfigured] is false and the app
/// uses the in-memory fake auth service, so guest play + local sign-up still
/// work offline. Paste real values and the login screen talks to Supabase.
class BackendConfig {
  BackendConfig._();

  /// Project URL — Supabase dashboard → Project Settings → API → "Project URL".
  static const String supabaseUrl = 'https://crtjsgkzaijjcqplenfp.supabase.co';

  /// Publishable (client) key — same page, "API keys" → the `Publishable key`
  /// (`sb_publishable_...`; older projects: legacy `anon` `public` JWT).
  static const String supabasePublishableKey =
      'sb_publishable_C5jhF-HILgIGt7gC9TYTXg_UHKDZFqb';

  /// True once real credentials are pasted in. Gates Supabase init + whether
  /// the real auth service (vs. the fake) is used.
  static bool get isConfigured =>
      !supabaseUrl.startsWith('YOUR_') &&
      !supabasePublishableKey.startsWith('YOUR_');
}
