import 'dart:convert';

import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/sync/sync_codec.dart';
import '../../../core/sync/sync_journal.dart';
import '../data/sync_settings.dart';

/// Result of a sync cycle, for the Settings UI.
class SyncOutcome {
  final bool ok;
  final int pulled;
  final int pushed;
  final String? error;

  const SyncOutcome({
    required this.ok,
    this.pulled = 0,
    this.pushed = 0,
    this.error,
  });

  const SyncOutcome.notConfigured()
    : ok = false,
      pulled = 0,
      pushed = 0,
      error = 'Cloud sync is not set up.';
}

/// Drives optional cloud sync against the restaurant's own Supabase.
///
/// The local SQLite database is always the source of truth. Sync is a
/// pull-then-push cycle over an append-only change feed:
///  - pull applies remote changes as upserts/deletes via [SyncCodec]
///    (never re-journaled, so they don't echo back to the feed),
///  - push sends locally-journaled changes the cloud hasn't seen.
/// Conflicts resolve last-write-wins by timestamp; a remote change is
/// skipped if this device has a newer un-pushed change for the same row.
class SyncService {
  final SyncJournal journal;
  final SyncCodec codec;
  final SyncSettings settings;

  /// Built per cycle so credential changes apply immediately; returns a
  /// NoopSyncBackend when the cloud isn't configured.
  final domain.SyncBackend Function() buildBackend;

  final DateTime Function() _clock;

  SyncService({
    required this.journal,
    required this.codec,
    required this.settings,
    required this.buildBackend,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  Future<domain.SyncHealth> health() => buildBackend().healthCheck();

  /// Pull then push. Pull first so a newer local edit re-pushes and wins.
  Future<SyncOutcome> syncNow() async {
    if (!settings.config.isConfigured) return const SyncOutcome.notConfigured();
    try {
      final backend = buildBackend();
      final pulled = await _pull(backend);
      final pushed = await _push(backend);
      await settings.setLastSyncedAt(_clock());
      return SyncOutcome(ok: true, pulled: pulled, pushed: pushed);
    } on Object catch (e) {
      return SyncOutcome(ok: false, error: '$e');
    }
  }

  /// Rebuilds this (wiped/new) tablet from the whole remote feed — the
  /// Phase 5 exit criterion. Resets the cursor, then pulls everything.
  Future<SyncOutcome> restoreFromCloud() async {
    if (!settings.config.isConfigured) return const SyncOutcome.notConfigured();
    try {
      await settings.resetCursor();
      final pulled = await _pull(buildBackend());
      await settings.setLastSyncedAt(_clock());
      return SyncOutcome(ok: true, pulled: pulled);
    } on Object catch (e) {
      return SyncOutcome(ok: false, error: '$e');
    }
  }

  // --- Internals ---

  Future<int> _push(domain.SyncBackend backend) async {
    final rows = await journal.unsynced();
    if (rows.isEmpty) return 0;
    await backend.push([
      for (final r in rows)
        domain.SyncLogEntry(
          id: r.id,
          entity: r.entity,
          entityId: r.entityId,
          op: r.op,
          payloadJson: r.payload ?? '',
          createdAt: DateTime.fromMicrosecondsSinceEpoch(r.occurredAtUs),
        ),
    ]);
    await journal.markSynced(rows.map((r) => r.id).toList(), _clock());
    return rows.length;
  }

  Future<int> _pull(domain.SyncBackend backend) async {
    final changes = await backend.pull(since: settings.cursor);
    if (changes.isEmpty) return 0;
    var applied = 0;
    DateTime? maxSeen;
    for (final c in changes) {
      maxSeen = (maxSeen == null || c.occurredAt.isAfter(maxSeen))
          ? c.occurredAt
          : maxSeen;
      // Last-write-wins: keep a newer un-pushed local edit to this row.
      final localUnsynced = await journal.latestUnsyncedFor(
        c.entity,
        c.entityId,
      );
      if (localUnsynced != null && localUnsynced.isAfter(c.occurredAt)) {
        continue;
      }
      if (c.op == domain.SyncOp.delete) {
        await codec.applyDelete(c.entity, c.entityId);
      } else {
        await codec.applyUpsert(
          c.entity,
          jsonDecode(c.payloadJson) as Map<String, dynamic>,
        );
      }
      applied++;
    }
    if (maxSeen != null) await settings.setCursor(maxSeen);
    return applied;
  }
}
