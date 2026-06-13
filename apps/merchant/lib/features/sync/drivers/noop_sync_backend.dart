import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// The default [domain.SyncBackend]: does nothing and reports the cloud
/// as not configured. Selected whenever the restaurant hasn't entered
/// Supabase credentials — the POS runs fully offline forever.
class NoopSyncBackend implements domain.SyncBackend {
  const NoopSyncBackend();

  @override
  Future<void> push(List<domain.SyncLogEntry> changes) async {}

  @override
  Future<List<domain.RemoteChange>> pull({required DateTime since}) async => [];

  @override
  Future<domain.SyncHealth> healthCheck() async =>
      domain.SyncHealth.notConfigured;
}
