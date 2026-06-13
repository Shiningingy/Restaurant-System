import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';
import 'sync_codec.dart';

/// Records every local write to a synced entity in the [SyncLog] table,
/// in the same transaction as the write, so the change feed can never
/// miss a mutation. Always on — when no cloud is configured the journal
/// simply accumulates and is never pushed (and can be pruned).
///
/// Repositories call [recordUpsert]/[recordDelete]; the wire payload
/// comes from [SyncCodec] so journaling and pull-apply share one format.
class SyncJournal {
  final AppDatabase db;
  final SyncCodec codec;
  final DateTime Function() _clock;

  /// Per-device monotonic guard: two writes in the same millisecond still
  /// get strictly increasing [SyncLogRow.occurredAt], so the feed has a
  /// total order on this device and last-write-wins is deterministic.
  DateTime? _last;

  SyncJournal(this.db, {DateTime Function()? clock})
    : codec = SyncCodec(db),
      _clock = clock ?? DateTime.now;

  DateTime _now() {
    var now = _clock();
    if (_last != null && !now.isAfter(_last!)) {
      now = _last!.add(const Duration(milliseconds: 1));
    }
    _last = now;
    return now;
  }

  Future<void> recordUpsert(String entity, String id) async {
    final payload = await codec.encode(entity, id);
    if (payload == null) return; // row vanished; nothing to journal
    await _insert(entity, id, domain.SyncOp.update, jsonEncode(payload));
  }

  Future<void> recordDelete(String entity, String id) =>
      _insert(entity, id, domain.SyncOp.delete, null);

  Future<void> _insert(
    String entity,
    String id,
    domain.SyncOp op,
    String? payload,
  ) {
    return db
        .into(db.syncLog)
        .insert(
          SyncLogCompanion.insert(
            id: domain.newId(),
            entity: entity,
            entityId: id,
            op: op,
            payload: Value(payload),
            occurredAtUs: _now().microsecondsSinceEpoch,
          ),
        );
  }

  /// Changes not yet pushed to the cloud, oldest first.
  Future<List<SyncLogRow>> unsynced() {
    return (db.select(db.syncLog)
          ..where((t) => t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAtUs)]))
        .get();
  }

  Future<void> markSynced(List<String> ids, DateTime at) async {
    if (ids.isEmpty) return;
    await (db.update(db.syncLog)..where((t) => t.id.isIn(ids))).write(
      SyncLogCompanion(syncedAt: Value(at)),
    );
  }

  /// Newest local change time for an entity row that hasn't been pushed
  /// yet — used to avoid clobbering an unsynced local edit with an older
  /// incoming remote one (last-write-wins).
  Future<DateTime?> latestUnsyncedFor(String entity, String entityId) async {
    final row =
        await (db.select(db.syncLog)
              ..where(
                (t) =>
                    t.entity.equals(entity) &
                    t.entityId.equals(entityId) &
                    t.syncedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAtUs)])
              ..limit(1))
            .getSingleOrNull();
    return row == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(row.occurredAtUs);
  }
}
