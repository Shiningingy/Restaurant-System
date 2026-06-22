import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../../core/settings/brand_logo_store.dart';
import '../../../core/settings/brand_logo_sync.dart';
import '../../../core/settings/providers.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/supabase_auth.dart';
import '../../../core/sync/providers.dart';
import '../../customer_display/application/customer_display.dart';
import '../../customer_display/application/promo_sync.dart';
import '../../customer_display/data/promo_image_store.dart';
import '../data/sync_settings.dart';
import '../drivers/noop_object_store.dart';
import '../drivers/noop_sync_backend.dart';
import '../drivers/supabase_object_store.dart';
import '../drivers/supabase_sync_backend.dart';
import 'sync_service.dart';

final syncSettingsProvider = Provider<SyncSettings>(
  (ref) => SyncSettings(
    ref.watch(sharedPreferencesProvider),
    ref.watch(secureStoreProvider),
  ),
);

/// The restaurant's Supabase login. Cloud features (sync, online orders)
/// send this user's token so RLS grants the restaurant full access; the
/// customer-facing anon key cannot reach private data
/// (docs/CLOUD_SECURITY.md). Null when not configured/signed in.
final supabaseAuthProvider = Provider<SupabaseAuth?>((ref) {
  final settings = ref.watch(syncSettingsProvider);
  final config = settings.config;
  if (!config.isConfigured) return null;
  final auth = SupabaseAuth(
    url: config.url!,
    anonKey: config.anonKey!,
    // Supabase rotates the refresh token on every refresh; persist the new one
    // so the stored token never goes stale (which would 400 the next launch).
    onSession: (session) =>
        settings.updateRestaurantRefreshToken(session.refreshToken),
  );
  final refresh = settings.restaurantRefreshToken;
  if (refresh != null) {
    auth.restore(
      SupabaseSession(
        accessToken: '',
        refreshToken: refresh,
        userId: '',
        isAnonymous: false,
        expiresAt: DateTime(2000), // forces a refresh on first use
      ),
    );
  }
  return auth;
});

/// Token callback for the cloud drivers (null when signed out → drivers
/// fall back to the anon key, which RLS will rightly restrict).
Future<String?> Function()? _bearer(SupabaseAuth? auth) => auth?.accessToken;

/// Remote blob storage (the restaurant's own Supabase Storage bucket) for
/// binary assets the row feed can't carry. NoopObjectStore when not configured.
final objectStoreProvider = Provider<domain.ObjectStore>((ref) {
  final config = ref.watch(syncSettingsProvider).config;
  if (!config.isConfigured) return const NoopObjectStore();
  return SupabaseObjectStore(
    url: config.url!,
    anonKey: config.anonKey!,
    accessToken: _bearer(ref.read(supabaseAuthProvider)),
  );
});

/// Syncs customer-display promo photos via Storage (bytes) + a manifest (set).
/// `publish()` after the owner edits the photos; `pull()` on each sync cycle.
final promoSyncProvider = Provider<PromoSyncService>((ref) {
  return PromoSyncService(
    store: ref.watch(objectStoreProvider),
    images: PromoImageStore(),
    readPaths: () => ref.read(settingsRepositoryProvider).displayPromoImages,
    writePaths: (paths) =>
        ref.read(displayPromoImagesProvider.notifier).applyFromCloud(paths),
    readLines: () => ref.read(settingsRepositoryProvider).displayPromoLines,
    writeLines: (lines) =>
        ref.read(displayPromoProvider.notifier).applyFromCloud(lines),
  );
});

/// Syncs one brand-logo slot via Storage — same mechanism, one image per slot.
final brandLogoSyncProvider =
    Provider.family<BrandLogoSyncService, BrandLogoSlot>((ref, slot) {
      return BrandLogoSyncService(
        store: ref.watch(objectStoreProvider),
        logo: BrandLogoStore(slot: slot.name),
        slot: slot.name,
        readPath: () =>
            ref.read(settingsRepositoryProvider).brandLogoPath(slot),
        writePath: (path) =>
            ref.read(brandLogosProvider.notifier).applyFromCloud(slot, path),
      );
    });

final syncServiceProvider = Provider<SyncService>((ref) {
  final settings = ref.watch(syncSettingsProvider);
  return SyncService(
    journal: ref.watch(syncJournalProvider),
    codec: ref.watch(syncCodecProvider),
    settings: settings,
    // Read credentials per cycle so a settings change applies immediately.
    buildBackend: () {
      final config = settings.config;
      if (!config.isConfigured) return const NoopSyncBackend();
      return SupabaseSyncBackend(
        url: config.url!,
        anonKey: config.anonKey!,
        deviceId: settings.deviceId,
        accessToken: _bearer(ref.read(supabaseAuthProvider)),
      );
    },
    // Best-effort: download promo photos + the brand logo published by another
    // device, and (if the set changed) refresh an open display live.
    reconcileAssets: () async {
      final applied = await ref.read(promoSyncProvider).pull();
      if (applied != null) {
        await ref.read(customerDisplayProvider).pushCurrentPromo();
      }
      var brandChanged = false;
      for (final slot in BrandLogoSlot.values) {
        if (await ref.read(brandLogoSyncProvider(slot)).pull()) {
          brandChanged = true;
        }
      }
      if (brandChanged) {
        await ref.read(customerDisplayProvider).pushCurrentBrand();
      }
    },
  );
});

/// Current cloud reachability, for the Settings status line.
final syncHealthProvider = FutureProvider.autoDispose<domain.SyncHealth>(
  (ref) => ref.watch(syncServiceProvider).health(),
);
