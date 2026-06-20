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

/// The device-local wallet — saved restaurants + the customer profile + which
/// restaurant is open. The single source of truth; [storefrontConfigProvider]
/// derives the active-storefront view from it.
class WalletNotifier extends Notifier<Wallet> {
  @override
  Wallet build() => ref.watch(storefrontConfigRepositoryProvider).wallet;

  StorefrontConfigRepository get _repo =>
      ref.read(storefrontConfigRepositoryProvider);

  /// Saves a restaurant and signs in **anonymously** so this device has a
  /// stable identity on that backend (its preorders are scoped to it by RLS —
  /// see docs/CLOUD_SECURITY.md), then opens it. Throws if sign-in fails, so a
  /// saved+active storefront always implies a usable session.
  Future<void> addAndConnect({
    required String url,
    required String anonKey,
    String? name,
  }) async {
    // Prepend https:// when missing, else Uri.parse yields no host and every
    // request throws "No host specified in URI".
    final normUrl = _normalizeUrl(url);
    final auth = SupabaseAuth(url: normUrl, anonKey: anonKey);
    final session = await auth.signInAnonymously();
    await _repo.addStorefront(
      url: normUrl,
      anonKey: anonKey,
      name: name,
      refreshToken: session.refreshToken,
      uid: session.userId,
    );
    state = _repo.wallet;
  }

  String _normalizeUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return u;
    final lower = u.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return u;
    return 'https://$u';
  }

  /// Opens an already-saved restaurant (no re-auth — its session is stored).
  Future<void> open(String id) async {
    await _repo.setActive(id);
    state = _repo.wallet;
  }

  /// Closes the current restaurant and returns to the wallet, keeping it saved.
  Future<void> leave() async {
    await _repo.setActive(null);
    state = _repo.wallet;
  }

  /// Forgets a saved restaurant entirely.
  Future<void> remove(String id) async {
    await _repo.removeStorefront(id);
    state = _repo.wallet;
  }

  /// Sets (or clears, when blank) the customer's nickname for a restaurant.
  Future<void> rename(String id, String? nickname) async {
    await _repo.renameStorefront(id, nickname);
    state = _repo.wallet;
  }

  /// Fills in the active storefront's merchant name from the published menu
  /// when it wasn't captured at connect (so the wallet shows the restaurant's
  /// name, not the Supabase host). No-op once a name is set.
  Future<void> backfillActiveName(String restaurantName) async {
    final active = state.active;
    if (active == null) return;
    if (active.name != null && active.name!.isNotEmpty) return;
    if (restaurantName.trim().isEmpty) return;
    await _repo.setStorefrontName(active.id, restaurantName);
    state = _repo.wallet;
  }

  Future<void> saveProfile(CustomerProfile profile) async {
    await _repo.saveProfile(profile);
    state = _repo.wallet;
  }

  Future<void> rememberCustomer({required String name, String? phone}) async {
    await _repo.rememberCustomer(name: name, phone: phone);
    state = _repo.wallet;
  }
}

final walletProvider = NotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);

/// The active storefront merged with the customer profile. Derived from
/// [walletProvider] so the existing menu/cart/status flow needs no changes.
final storefrontConfigProvider = Provider<StorefrontConfig>((ref) {
  final wallet = ref.watch(walletProvider);
  final active = wallet.active;
  return StorefrontConfig(
    url: active?.url,
    anonKey: active?.anonKey,
    customerName: wallet.profile.name,
    customerPhone: wallet.profile.phone,
    sessionRefreshToken: active?.sessionRefreshToken,
    customerUid: active?.customerUid,
  );
});

/// The HTTP client for the connected storefront (carrying the device's
/// anonymous session), or null when not connected.
final storefrontProvider = Provider<SupabaseStorefront?>((ref) {
  final config = ref.watch(storefrontConfigProvider);
  if (!config.isConnected) return null;
  final auth = SupabaseAuth(
    url: config.url!,
    anonKey: config.anonKey!,
    // Supabase rotates the refresh token on each refresh. Persist the new one
    // straight to the repository (not the notifier), so it survives a restart
    // without rebuilding this provider mid-refresh (which would loop).
    onSession: (session) => ref
        .read(storefrontConfigRepositoryProvider)
        .saveSession(refreshToken: session.refreshToken, uid: session.userId),
  );
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
