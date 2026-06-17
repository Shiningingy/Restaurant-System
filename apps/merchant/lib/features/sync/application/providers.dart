import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../../../core/supabase_auth.dart';
import '../../../core/sync/providers.dart';
import '../data/sync_settings.dart';
import '../drivers/noop_sync_backend.dart';
import '../drivers/supabase_sync_backend.dart';
import 'sync_service.dart';

final syncSettingsProvider = Provider<SyncSettings>(
  (ref) => SyncSettings(ref.watch(sharedPreferencesProvider)),
);

/// The restaurant's Supabase login. Cloud features (sync, online orders)
/// send this user's token so RLS grants the restaurant full access; the
/// customer-facing anon key cannot reach private data
/// (docs/CLOUD_SECURITY.md). Null when not configured/signed in.
final supabaseAuthProvider = Provider<SupabaseAuth?>((ref) {
  final settings = ref.watch(syncSettingsProvider);
  final config = settings.config;
  if (!config.isConfigured) return null;
  final auth = SupabaseAuth(url: config.url!, anonKey: config.anonKey!);
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
  );
});

/// Current cloud reachability, for the Settings status line.
final syncHealthProvider = FutureProvider.autoDispose<domain.SyncHealth>(
  (ref) => ref.watch(syncServiceProvider).health(),
);
