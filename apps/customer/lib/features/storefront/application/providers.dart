import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/storefront_config.dart';
import '../drivers/supabase_auth.dart';
import '../drivers/supabase_storefront.dart';

final storefrontConfigRepositoryProvider = Provider<StorefrontConfigRepository>(
  (ref) => StorefrontConfigRepository(ref.watch(sharedPreferencesProvider)),
);

/// The chosen UI language. `null` means follow the system locale; the
/// customer overrides it from the app-bar language menu.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(storefrontConfigRepositoryProvider).appLocaleCode;
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    await ref
        .read(storefrontConfigRepositoryProvider)
        .setAppLocaleCode(locale?.languageCode);
    state = locale;
  }
}

final localePreferenceProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// The connected storefront config. Refresh with `ref.invalidate` after
/// connecting/disconnecting.
class StorefrontConfigNotifier extends Notifier<StorefrontConfig> {
  @override
  StorefrontConfig build() =>
      ref.watch(storefrontConfigRepositoryProvider).config;

  /// Saves the storefront and signs in **anonymously** so this device has
  /// a stable identity (its preorders are scoped to it by RLS — see
  /// docs/CLOUD_SECURITY.md). Throws if sign-in fails, so "connected"
  /// always implies a usable session.
  Future<void> connect({required String url, required String anonKey}) async {
    final repo = ref.read(storefrontConfigRepositoryProvider);
    final auth = SupabaseAuth(url: url, anonKey: anonKey);
    final session = await auth.signInAnonymously();
    await repo.connect(url: url, anonKey: anonKey);
    await repo.saveSession(
      refreshToken: session.refreshToken,
      uid: session.userId,
    );
    state = repo.config;
  }

  Future<void> disconnect() async {
    await ref.read(storefrontConfigRepositoryProvider).disconnect();
    state = ref.read(storefrontConfigRepositoryProvider).config;
  }
}

final storefrontConfigProvider =
    NotifierProvider<StorefrontConfigNotifier, StorefrontConfig>(
      StorefrontConfigNotifier.new,
    );

/// The HTTP client for the connected storefront (carrying the device's
/// anonymous session), or null when not connected.
final storefrontProvider = Provider<SupabaseStorefront?>((ref) {
  final config = ref.watch(storefrontConfigProvider);
  if (!config.isConnected) return null;
  final auth = SupabaseAuth(url: config.url!, anonKey: config.anonKey!);
  final refresh = config.sessionRefreshToken;
  if (refresh != null) {
    // Restore with a past expiry so the first request refreshes the token.
    auth.restore(
      SupabaseSession(
        accessToken: '',
        refreshToken: refresh,
        userId: config.customerUid ?? '',
        expiresAt: DateTime(2000),
      ),
    );
  }
  return SupabaseStorefront(
    url: config.url!,
    anonKey: config.anonKey!,
    accessToken: auth.accessToken,
  );
});

/// The published menu being browsed.
final menuProvider = FutureProvider<domain.PublishedMenu?>((ref) {
  final storefront = ref.watch(storefrontProvider);
  if (storefront == null) return Future.value(null);
  return storefront.fetchMenu();
});
