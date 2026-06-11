/// A single recorded local change, journaled for later push.
class SyncLogEntry {
  final String id;
  final String entity;
  final String entityId;
  final SyncOp op;
  final String payloadJson;
  final DateTime createdAt;

  const SyncLogEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payloadJson,
    required this.createdAt,
  });
}

enum SyncOp { insert, update, delete }

/// A change fetched from the remote during pull.
class RemoteChange {
  final String entity;
  final String entityId;
  final SyncOp op;
  final String payloadJson;
  final DateTime occurredAt;

  const RemoteChange({
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payloadJson,
    required this.occurredAt,
  });
}

enum SyncHealth { ok, unreachable, authFailed, notConfigured }

/// Optional cloud sync. The local SQLite database is always the source
/// of truth; sync is strictly additive and the app must be fully
/// functional with [SyncHealth.notConfigured] forever
/// (see docs/PRINCIPLES.md — no required subscription).
///
/// Planned implementations:
///  - NoopSyncBackend     (default — does nothing, reports notConfigured)
///  - SupabaseSyncBackend (restaurant's own Supabase project; user supplies
///    URL + anon key in settings)
abstract interface class SyncBackend {
  Future<void> push(List<SyncLogEntry> changes);

  Future<List<RemoteChange>> pull({required DateTime since});

  Future<SyncHealth> healthCheck();
}
