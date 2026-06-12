import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/db/database.dart';

/// Persisted print queue. Jobs are never lost on restart: queued jobs
/// resume, failed jobs wait in Settings for a manual retry.
class PrintJobRepository {
  final AppDatabase db;

  PrintJobRepository(this.db);

  Future<String> enqueue({
    required domain.PrintJobKind kind,
    required List<int> payload,
    String? orderId,
  }) async {
    final id = domain.newId();
    final now = DateTime.now();
    await db
        .into(db.printJobs)
        .insert(
          PrintJobsCompanion.insert(
            id: id,
            kind: kind,
            status: domain.PrintJobStatus.queued,
            orderId: Value(orderId),
            payload: Uint8List.fromList(payload),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Oldest queued job, or null when the queue is drained.
  Future<PrintJobRow?> nextQueued() {
    final q = db.select(db.printJobs)
      ..where((t) => t.status.equalsValue(domain.PrintJobStatus.queued))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  Stream<List<PrintJobRow>> watchRecent({int limit = 20}) {
    final q = db.select(db.printJobs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return q.watch();
  }

  Future<void> markPrinting(String id) => _update(
    id,
    const PrintJobsCompanion(status: Value(domain.PrintJobStatus.printing)),
  );

  Future<void> markDone(String id) => _update(
    id,
    const PrintJobsCompanion(
      status: Value(domain.PrintJobStatus.done),
      lastError: Value(null),
    ),
  );

  Future<void> markFailed(String id, String error) => _update(
    id,
    PrintJobsCompanion(
      status: const Value(domain.PrintJobStatus.failed),
      lastError: Value(error),
    ),
  );

  /// Failed attempt that will be retried: back to queued with the error
  /// recorded and the attempt counted.
  Future<void> recordAttempt(String id, String error) async {
    final job = await (db.select(
      db.printJobs,
    )..where((t) => t.id.equals(id))).getSingle();
    await _update(
      id,
      PrintJobsCompanion(
        status: const Value(domain.PrintJobStatus.queued),
        attempts: Value(job.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Manual retry from the UI: fresh attempt budget.
  Future<void> retry(String id) => _update(
    id,
    const PrintJobsCompanion(
      status: Value(domain.PrintJobStatus.queued),
      attempts: Value(0),
    ),
  );

  /// Jobs stuck in `printing` after a crash/kill go back to the queue.
  Future<void> recoverInterrupted() {
    return (db.update(db.printJobs)
          ..where((t) => t.status.equalsValue(domain.PrintJobStatus.printing)))
        .write(
          PrintJobsCompanion(
            status: const Value(domain.PrintJobStatus.queued),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteJob(String id) =>
      (db.delete(db.printJobs)..where((t) => t.id.equals(id))).go();

  Future<void> _update(String id, PrintJobsCompanion changes) {
    return (db.update(db.printJobs)..where((t) => t.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
  }
}
