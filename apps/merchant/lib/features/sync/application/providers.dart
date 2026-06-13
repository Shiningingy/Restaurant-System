import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/providers.dart';
import '../data/sync_codec.dart';
import '../data/sync_journal.dart';
import '../data/sync_settings.dart';
import '../drivers/noop_sync_backend.dart';
import '../drivers/supabase_sync_backend.dart';
import 'sync_service.dart';

final syncSettingsProvider = Provider<SyncSettings>(
  (ref) => SyncSettings(ref.watch(sharedPreferencesProvider)),
);

/// One shared journal for the whole app, so its monotonic change clock is
/// global — every repository writes through this instance.
final syncJournalProvider = Provider<SyncJournal>(
  (ref) => SyncJournal(ref.watch(databaseProvider)),
);

final syncCodecProvider = Provider<SyncCodec>(
  (ref) => SyncCodec(ref.watch(databaseProvider)),
);

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
      );
    },
  );
});

/// Current cloud reachability, for the Settings status line.
final syncHealthProvider = FutureProvider.autoDispose<domain.SyncHealth>(
  (ref) => ref.watch(syncServiceProvider).health(),
);
